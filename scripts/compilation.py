#!/usr/bin/env python3
import json
import logging
import os
import runpy
import sys
import shutil
import tarfile

from buildpack import util
from buildpack.core import java, runtime
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
    # If additional versions are required in the future, install them into separate locations with rpm install --prefix
    mono_version = get_dependency("mono.5-jammy", "/opt/mendix/buildpack")["version"]
    logging.debug("Creating symlink for mono {0}".format(mono_version))

    util.mkdir_p("/tmp/buildcache/bust")
    mono_cache_artifact = f"/tmp/buildcache/bust/mono-{mono_version}-mx-ubuntu-jammy.tar.gz"
    with tarfile.open(mono_cache_artifact, "w:gz") as tar:
        # Symlinks to use mono from host OS
        symlinks = {'mono/bin':'/usr/bin', 'mono/lib': '/usr/lib64', 'mono/etc': '/etc'}
        for source, destination in symlinks.items():
            symlink = tarfile.TarInfo(source)
            symlink.type = tarfile.SYMTYPE
            symlink.linkname = destination
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

def make_dependencies_reusable(compilation_globals):
    logging.info("Making dependencies reusable...")
    dot_local_location = compilation_globals["DOT_LOCAL_LOCATION"]
    build_path = compilation_globals["BUILD_DIR"]
    shutil.move("/opt/mendix/build/runtimes", "/var/mendix/build/")
    shutil.move("/opt/mendix/build/.local/usr", "/var/mendix/build/.local/")
    # separate cacerts from reusable jre components
    jre = java._get_java_dependency(java.get_java_major_version(runtime.get_runtime_version(build_path)), 'jre')
    jvm_location_reusable = os.path.join("/var/mendix/build/.local/", java._compose_jvm_target_dir(jre))
    jvm_location_customized = os.path.join(dot_local_location, java._compose_jvm_target_dir(jre))
    cacerts_file_source = os.path.join(jvm_location_reusable, "lib", "security", "cacerts")
    cacerts_file_target = os.path.join(jvm_location_customized, "lib", "security", "cacerts")
    util.mkdir_p(os.path.dirname(cacerts_file_target))
    os.rename(cacerts_file_source, cacerts_file_target)

if __name__ == '__main__':
    logging.info("Mendix project compilation phase...")

    export_vcap_services()
    replace_cf_dependencies()
    compilation_globals = call_buildpack_compilation()
    fix_logfilter()
    make_dependencies_reusable(compilation_globals)
