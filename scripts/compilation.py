#!/usr/bin/env python3
import json
import logging
import os
import runpy
import sys
import shutil
import tarfile

from buildpack.core import runtime
from buildpack.util import get_dependency

logging.basicConfig(
    level=logging.INFO,
    stream=sys.stdout,
    format='%(levelname)s: %(message)s',
)

def export_vcap_services():
    logging.debug("Executing build_vcap_services...")

    vcap_services = dict()
    vcap_services['PostgreSQL'] = [{'credentials': { 'uri': "postgres://mendix:mendix@172.17.0.2:5432/mendix" } }]

    vcap_services_str = json.dumps(vcap_services , sort_keys=True, indent=4,
        separators=(',', ': '))
    logging.debug("Set environment variable VCAP_SERVICES: \n{0}"
        .format(vcap_services_str))

    os.environ['VCAP_SERVICES'] = vcap_services_str
    os.environ["PATH"] += os.pathsep + "/opt/mendix/buildpack"

def replace_cf_dependencies():
    logging.debug("Ensuring CF Buildpack dependencies are available")

    # Only mono 5 is supported by Docker Buildpack
    mono_dependency = get_dependency("mono.5-jammy", "/opt/mendix/buildpack")
    logging.debug("Creating symlink for mono {0}".format(mono_dependency['artifact']))

    os.mkdir('/tmp/buildcache/bust')
    mono_cache_artifact = f"/tmp/buildcache/bust/mono-{mono_dependency['version']}-mx-ubuntu-jammy.tar.gz"
    with tarfile.open(mono_cache_artifact, "w:gz") as tar:
        # Symlinks to use mono from host OS
        symlinks = {'mono/bin':'/usr/bin', 'mono/lib': '/usr/lib64', 'mono/etc': '/etc'}
        for source, destination in symlinks.items():
            symlink = tarfile.TarInfo(source)
            symlink.type = tarfile.SYMTYPE
            symlink.linkname = destination
            tar.addfile(symlink)

    # Only JDK 11 is supported by Docker Buildpack
    jdk_dependency = get_dependency("java.11-jdk", "/opt/mendix/buildpack")
    logging.debug("Creating symlink for jdk {0}".format(jdk_dependency['artifact']))
    jdk_cache_artifact = f"/tmp/buildcache/bust/{jdk_dependency['artifact']}"
    jdk_destination = '/etc/alternatives/java_sdk_11'
    with tarfile.open(jdk_cache_artifact, "w:gz") as tar:
        # Symlinks to use jdk from host OS
        for jdk_dir in os.listdir(jdk_destination):
            symlink = tarfile.TarInfo(f"jdk/{jdk_dir}")
            symlink.type = tarfile.SYMTYPE
            symlink.linkname = f"{jdk_destination}/{jdk_dir}"
            tar.addfile(symlink)

    # Only JRE 11 is supported by Docker Buildpack
    jre_dependency = get_dependency("java.11-jre", "/opt/mendix/buildpack")
    logging.debug("Creating symlink for jre {0}".format(jre_dependency['artifact']))
    jre_cache_artifact = f"/tmp/buildcache/bust/{jre_dependency['artifact']}"
    jre_destination = '/etc/alternatives/jre_11'
    with tarfile.open(jre_cache_artifact, "w:gz") as tar:
        # Symlinks to use jre from host OS
        for jre_dir in os.listdir(jre_destination):
            symlink = tarfile.TarInfo(f"jre/{jre_dir}")
            symlink.type = tarfile.SYMTYPE
            symlink.linkname = f"{jre_destination}/{jre_dir}"
            tar.addfile(symlink)

def call_buildpack_compilation():
    logging.debug("Executing call_buildpack_compilation...")
    return runpy.run_module("buildpack.stage", run_name="__main__")

def fix_logfilter():
    exclude_logfilter = os.getenv("EXCLUDE_LOGFILTER", "true").lower() == "true"
    if exclude_logfilter:
        logging.info("Removing mendix-logfilter executable")
        shutil.rmtree("/opt/mendix/build/.local/mendix-logfilter")
    else:
        os.chmod("/opt/mendix/build/.local/mendix-logfilter/mendix-logfilter", 0o0755)

def relocate_writable_dirs():
    os.symlink('/opt/mendix/build/.java', '/opt/mendix/.java')
    os.mkdir('/opt/mendix/build/.java')
    relocate_paths = [
        '/opt/mendix/build/data/database',
        '/opt/mendix/build/data/files',
        '/opt/mendix/build/data/model-upload',
        '/opt/mendix/build/data/tmp',
        '/opt/mendix/build/datadog_integrations',
        '/opt/mendix/build/web',
        '/opt/mendix/build/nginx',
        '/opt/mendix/build/log',
        '/opt/mendix/build/.java',
        '/opt/mendix/build/.local',
        '/opt/mendix/build/.m2ee',
        '/opt/datadog-agent'
    ]
    keep_contents_paths = [
        '/opt/mendix/build/.local',
        '/opt/mendix/build/nginx',
        '/opt/mendix/build/web'
    ]
    writable_contents_path = '/opt/mendix/writable_contents'
    writable_root = os.getenv("WRITABLE_ROOT")
    if writable_root:
        os.mkdir(writable_contents_path)
        logging.warning("Relocating all writable directories to {0}".format(writable_root))
        # Pre-create symlinks that would otherwise be created on startup
        runtime_mxclient_dir = os.path.join('/opt/mendix/build/runtimes', str(runtime.get_runtime_version(build_path='/opt/mendix/build')), 'runtime/mxclientsystem')
        os.symlink(runtime_mxclient_dir, '/opt/mendix/build/web/mxclientsystem')
        # Relocate nginx runtime directories to a writable location
        with open('/opt/mendix/build/nginx/conf/nginx.conf.j2', 'r+') as nginx_conf:
            config_lines = nginx_conf.readlines()
            nginx_conf.seek(0)
            for line in config_lines:
                if not line.strip().startswith('error_log'):
                    nginx_conf.write(line)
            nginx_conf.truncate()
            nginx_conf.writelines("\npid /opt/mendix/build/nginx/nginx.pid;\n")
        nginx_tmp = '/opt/mendix/build/nginx/tmp'
        os.makedirs(nginx_tmp)
        with open('/opt/mendix/build/nginx/conf/proxy_params.j2', 'a') as nginx_conf:
            nginx_conf.writelines("\nclient_body_temp_path {0};\n".format(nginx_tmp))
            nginx_conf.writelines("proxy_temp_path {0};\n".format(nginx_tmp))
            nginx_conf.writelines("uwsgi_temp_path {0};\n".format(nginx_tmp))
            nginx_conf.writelines("scgi_temp_path {0};\n".format(nginx_tmp))
            nginx_conf.writelines("fastcgi_temp_path {0};\n".format(nginx_tmp))
        for keep_contents_path in keep_contents_paths:
            relative_path = os.path.relpath(keep_contents_path, '/opt/mendix/build')
            target = os.path.join(writable_contents_path, relative_path)
            logging.debug("Saving contents of {0} into {1}".format(keep_contents_path, target))
            parent_dir = os.path.dirname(target)
            if not os.path.isdir(parent_dir):
                os.makedirs(parent_dir)
            os.rename(keep_contents_path, target)
        for relocate_path in relocate_paths:
            relative_path = os.path.relpath(relocate_path, '/opt')
            target = os.path.join(writable_root, relative_path)
            logging.debug("Redirecting {0} to {1}".format(relocate_path, target))
            if os.path.isfile(relocate_path):
                os.remove(relocate_path)
            elif os.path.isdir(relocate_path):
                os.rmdir(relocate_path)
            elif os.path.islink(relocate_path):
                os.unlink(relocate_path)
            os.symlink(target, relocate_path)

if __name__ == '__main__':
    logging.info("Mendix project compilation phase...")

    export_vcap_services()
    replace_cf_dependencies()
    compilation_globals = call_buildpack_compilation()
    fix_logfilter()
    relocate_writable_dirs()
