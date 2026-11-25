#!/usr/bin/env python3

import argparse
import pathlib
import os
import tempfile
import json
import sqlite3
import zipfile
import atexit
import shutil
import subprocess
import sys
import selectors
import logging
import platform

logging.basicConfig(
    level=logging.INFO,
    stream=sys.stdout
)

def find_default_file(source, ext):
    if os.path.isfile(source):
        return source if source.name.endswith(ext) else None
    files = [x for x in os.listdir(source) if x.endswith(ext)]
    if len(files) == 1:
        return os.path.join(source, files[0])
    if len(files) > 1:
        raise Exception(f"More than one {ext} file found, can not continue")
    return None

def get_metadata_value(source_dir):
    file_name = os.path.join(source_dir, 'model', 'metadata.json')
    try:
        with open(file_name) as file_handle:
            return json.loads(file_handle.read())
    except IOError:
        return None

def extract_zip(mda_file):
    temp_dir = tempfile.TemporaryDirectory(prefix='mendix-docker-buildpack')
    with zipfile.ZipFile(mda_file) as zip_file:
        zip_file.extractall(temp_dir.name)
    return temp_dir

BUILDER_PROCESS = None
def stop_processes():
    if BUILDER_PROCESS is not None:
        proc = BUILDER_PROCESS
        proc.terminate()
        proc.communicate()
        proc.wait()

def container_call(args):
    build_executables = ['podman', 'docker']
    build_executable = None
    logger_stdout = None
    logger_stderr = None
    for builder in build_executables:
        build_executable = shutil.which(builder)
        if build_executable is not None:
            logger_stderr = logging.getLogger(builder + '-stderr')
            logger_stdout = logging.getLogger(builder + '-stdout')
            break
    if build_executable is None:
        raise Exception('Cannot find Podman or Docker executable')
    proc = subprocess.Popen([build_executable] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    BUILDER_PROCESS = proc

    sel = selectors.DefaultSelector()
    sel.register(proc.stdout, selectors.EVENT_READ)
    sel.register(proc.stderr, selectors.EVENT_READ)

    last_line_stdout = None
    last_line_stderr = None
    stdout_open, stderr_open = True, True
    while stdout_open or stderr_open:
        for key, _ in sel.select():
            data = key.fileobj.readline()
            if data == '':
                if key.fileobj is proc.stdout:
                    stdout_open = False
                elif key.fileobj is proc.stderr:
                    stderr_open = False
                continue
            data = data.rstrip()
            if key.fileobj is proc.stdout:
                last_line_stdout = data
                logger_stdout.info(data)
            elif key.fileobj is proc.stderr:
                last_line_stderr = data
                # stderr is mostly used for progress notifications, not errors
                logger_stderr.info(data)

    sel.close()
    BUILDER_PROCESS = None
    if proc.wait() != 0:
        raise Exception(f"Builder returned with error: {last_line_stderr}")
    return last_line_stdout

def pull_image(image_url):
    try:
        container_call(['image', 'pull', image_url])
        return image_url
    except:
        return None

def delete_container(container_id):
    try:
        container_call(['container', 'rm', '--force', container_id])
    except Exception as e:
        logging.warning('Failed to delete container {}: {}'.format(container_id, e))

def build_mpr_builder(mx_version, dotnet, artifacts_repository=None):
    builder_image_tag = f"mxbuild-{mx_version}-{dotnet}-{platform.machine()}"
    builder_image_url = None
    if artifacts_repository is not None:
        builder_image_url = f"{artifacts_repository}:{builder_image_tag}"
        image_url = pull_image(builder_image_url)
        if image_url is not None:
            return image_url
    else:
        builder_image_url = f"mendix-buildpack:{builder_image_tag}"

    prefix = ''
    if platform.machine() == 'arm64' and dotnet == 'dotnet':
        prefix = 'arm64-'

    mxbuild_filename = f"{prefix}mxbuild-{mx_version}.tar.gz"
    mxbuild_url = f"https://download.mendix.com/runtimes/{mxbuild_filename}"

    build_args = ['--build-arg', f"MXBUILD_DOWNLOAD_URL={mxbuild_url}",
                  '--file', os.path.join('mxbuild', f"{dotnet}.dockerfile"),
                  '--tag', builder_image_url]

    container_call(['image', 'build'] + build_args + ['mxbuild'])
    if artifacts_repository is not None:
        try:
            container_call(['image', 'push', builder_image_url])
        except Exception as e:
            logging.warning('Failed to push mxbuild into artifacts repository: {}; continuing with the build'.format(e))
    return builder_image_url

def get_git_commit(source_dir):
    git_head = os.path.join(source_dir, '.git', 'HEAD')
    if not os.path.isfile(git_head):
        raise Exception('Project source doesn\'t contain git metadata')
    with open(git_head) as git_head:
        git_head_line = git_head.readline().split()
        if len(git_head_line) == 1:
            # Detached commit
            return git_head_line[0]
        if len(git_head_line) > 2:
            raise Exception(f"Unsupported Git HEAD format {git_head_line}")
        git_branch = git_head_line[1].split('/')
        git_branch_file = os.path.join(*([source_dir, '.git'] + git_branch))
        if not os.path.isfile(git_branch_file):
            raise Exception('Git branch file doesn\'t exist')
        with open(git_branch_file) as git_branch_file:
            return git_branch_file.readline()


def build_mpr(source_dir, mpr_file, destination, artifacts_repository=None):
    cursor = sqlite3.connect(mpr_file).cursor()
    cursor.execute("SELECT _ProductVersion FROM _MetaData LIMIT 1")
    mx_version = cursor.fetchone()[0]
    mx_version_value = parse_version(mx_version)
    logging.debug('Detected Mendix version {}'.format('.'.join(map(str,mx_version_value))))
    dotnet = 'dotnet' if mx_version_value >= (9, 22, 0, 0) else 'mono'
    builder_image = build_mpr_builder(mx_version, dotnet, artifacts_repository)
    model_version = None
    try:
        model_version = os.environ['MENDIX_MODEL_VERSION'] if 'MENDIX_MODEL_VERSION' in os.environ else get_git_commit(source_dir)
    except Exception as e:
        model_version = 'unversioned'
        logging.warning('Cannot determine git commit ({}), will set model version to unversioned'.format(e))
    container_id = container_call(['container', 'create', builder_image, os.path.basename(mpr_file), model_version])
    atexit.register(delete_container, container_id)
    container_call(['container', 'cp', os.path.abspath(source_dir)+'/.', f"{container_id}:/workdir/project"])
    build_result = container_call(['start', '--attach', '--interactive', container_id])

    temp_dir = tempfile.TemporaryDirectory(prefix='mendix-docker-buildpack')
    container_call(['container', 'cp', f"{container_id}:/workdir/output.mda", temp_dir.name])
    with zipfile.ZipFile(os.path.join(temp_dir.name, 'output.mda')) as zip_file:
        zip_file.extractall(destination)

def parse_version(version):
    return tuple([ int(n) for n in version.split('.') ])

def prepare_destination(destination_path):
    if os.path.exists(destination_path):
        with os.scandir(destination_path) as entries:
            for entry in entries:
                if entry.is_dir() and not entry.is_symlink():
                    shutil.rmtree(entry.path)
                else:
                    os.remove(entry.path)
    else:
        os.makedirs(destination_path, 0o755)
    project_path = os.path.join(destination_path, 'project')
    os.mkdir(project_path, 0o755)
    shutil.copytree('scripts', os.path.join(destination_path, 'scripts'))
    shutil.copyfile('Dockerfile', os.path.join(destination_path, 'Dockerfile'))
    return project_path

def prepare_mda(source_path, destination_path, artifacts_repository=None):
    destination_path = prepare_destination(destination_path)
    mpk_file = find_default_file(source_path, '.mpk')
    extracted_dir = None
    if mpk_file is not None:
        extracted_dir = extract_zip(mpk_file)
        source_path = extracted_dir.name
    mpr_file = find_default_file(source_path, '.mpr')
    if mpr_file is not None:
        source_path = os.path.abspath(os.path.join(mpr_file, os.pardir))
        return build_mpr(source_path, mpr_file, destination_path, artifacts_repository)
    mda_file = find_default_file(source_path, '.mda')
    if mda_file is not None:
        with zipfile.ZipFile(mda_file) as zip_file:
            zip_file.extractall(destination_path)
    elif os.path.isdir(source_path):
        shutil.copytree(source_path, destination_path, dirs_exist_ok=True)
    extracted_mda_file = get_metadata_value(destination_path)
    if extracted_mda_file is not None:
        return destination_path
    else:
        raise Exception('No supported files found in source path')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Build a Mendix app')
    parser.add_argument('--source', metavar='source', required=True, nargs='?', type=pathlib.Path, help='Path to source Mendix app (MDA file, MPK file, MPR directory or extracted MDA directory)')
    parser.add_argument('--destination', metavar='destination', required=True, nargs='?', type=pathlib.Path, help='Destination for MDA')
    parser.add_argument('--artifacts-repository', required=False, nargs='?', metavar='artifacts_repository', type=str, help='Repository to use for caching build images')
    parser.add_argument('action', metavar='action', choices=['build-mda-dir'], help='Action to perform')

    args = parser.parse_args()

    atexit.register(stop_processes)
    try:
        prepare_mda(args.source, args.destination, args.artifacts_repository)
    except KeyboardInterrupt:
        stop_processes()
        raise
