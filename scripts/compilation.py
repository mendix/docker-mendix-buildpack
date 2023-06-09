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
    mono_dependency = get_dependency("mono.5-jammy", "/opt/mendix/buildpack")
    logging.debug("Creating symlink for mono {0}".format(mono_dependency['artifact']))

    util.mkdir_p("/tmp/buildcache/bust")
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

if __name__ == '__main__':
    logging.info("Mendix project compilation phase...")

    export_vcap_services()
    replace_cf_dependencies()
    compilation_globals = call_buildpack_compilation()
    fix_logfilter()
