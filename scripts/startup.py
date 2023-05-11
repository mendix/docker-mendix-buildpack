#!/usr/bin/env python3
import json
import logging
import os
import re
import runpy
import sys
import base64

logging.basicConfig(
    level=logging.INFO,
    stream=sys.stdout,
    format='%(levelname)s: %(message)s',
)

def export_db_endpoint():
    if 'DATABASE_ENDPOINT' in os.environ:
        os.environ['DATABASE_URL'] = os.environ['DATABASE_ENDPOINT']
    else:
        if 'DATABASE_URL' not in os.environ:
            logging.warning(
            'DATABASE_ENDPOINT environment variable not found.'
            'Fallback to custom runtime variables https://github.com/mendix/cf-mendix-buildpack/#configuring-custom-runtime-settings')
            

def export_vcap_variables():
    logging.debug("Executing build_vcap_variables...")

    vcap_application = create_vcap_application()
    logging.debug("Set environment variable VCAP_APPLICATION: \n {0}"
        .format(vcap_application))
    os.environ['VCAP_APPLICATION'] = vcap_application

def create_vcap_application():
    logging.debug("Executing create_vcap_application...")
    vcap_application_data = open("vcap_application.json").read()
    return vcap_application_data

def export_industrial_edge_config_variable():
    logging.info("Executing export_industrial_edge_config_variable...")

    if 'IEM_CONFIG_PATH' in os.environ:
            config_path = os.environ.get('IEM_CONFIG_PATH')
            if not config_path.endswith("/"):
                config_path = "%s/" % (config_path)
            logging.info("IEM Config path set to: %s" % (config_path))
            for file in os.listdir(config_path):
                if file.endswith(".env"):
                    logging.info("IEM ENV Config file found : %s" % (file))
                    with open("%s%s" % (config_path, file)) as config_file:
                        for line in config_file:
                            name, var = line.partition("=")[::2]
                            logging.info("Adding Env-variable : %s=%s" % (name.strip(), var.strip()))
                            os.environ[name.strip()] = var.strip()
                    
    
def export_k8s_instance():
    logging.debug("Checking Kubernetes environment...")
    kubernetes_host = os.environ.get('KUBERNETES_SERVICE_HOST')
    instance_index = os.environ.get('CF_INSTANCE_INDEX')
    if kubernetes_host is not None and instance_index is None:
        hostname = os.environ.get('HOSTNAME')
        instance_match = re.search('(?<=-)[0-9]+$', hostname)
        if instance_match is not None:
            instance_number = instance_match.group(0)
            logging.info("Setting CF_INSTANCE_INDEX to {0} based on hostname {1}"
                .format(instance_number, hostname))
            os.environ['CF_INSTANCE_INDEX'] = instance_number
            
def export_encoded_cacertificates():
    logging.debug("Checking for encoded CA certificates...")
    certificate_authorities_base64 = os.environ.get('CERTIFICATE_AUTHORITIES_BASE64')
    if certificate_authorities_base64 is not None:
        logging.info("Decoding encoded CA certificates into CERTIFICATE_AUTHORITIES environment variable")
        certificate_authorities = base64.b64decode(certificate_authorities_base64)
        os.environ['CERTIFICATE_AUTHORITIES'] = str(certificate_authorities,'utf-8')

def check_logfilter():
    log_ratelimit_enabled = os.getenv('LOG_RATELIMIT', None) is not None
    logfilter_path = '.local/mendix-logfilter/mendix-logfilter'
    if log_ratelimit_enabled and not os.path.exists(logfilter_path):
        logging.warn("LOG_RATELIMIT is set, but the mendix-logfilter binary is missing. Rebuild Docker image with EXCLUDE_LOGFILTER=false to enable log filtering")
        del os.environ['LOG_RATELIMIT']

def call_buildpack_startup():
    logging.debug("Executing call_buildpack_startup...")

    os.chdir('/opt/mendix/build')
    runpy.run_module("buildpack.start", run_name="__main__")

def get_welcome_header():
    welcome_ascii_header = '''
                              ##        .
                         ## ## ##       ==
                       ## ## ## ##      ===
                   /""""""""""""""""\___/ ===
              ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
                   \______ o          __/
                     \    \        __/
                      \____\______/

     __  __        _  _     _____             _
    |  \/  |      | || |   |  __ \           | |
    | \  / |_  __ | || |_  | |  | | ___   ___| | _____ _ __
    | |\/| \ \/ / |__   _| | |  | |/ _ \ / __| |/ / _ \ '__|
    | |  | |>  <     | |   | |__| | (_) | (__|   <  __/ |
    |_|  |_/_/\_\    |_|   |_____/ \___/ \___|_|\_\___|_|

                                digitalecosystems@mendix.com

    For a Kubernetes native solution to run Mendix apps,
    see Mendix for Private Cloud.

    '''
    return welcome_ascii_header


if __name__ == '__main__':
    logging.info(get_welcome_header())
    export_db_endpoint()
    export_vcap_variables()
    export_industrial_edge_config_variable()
    export_k8s_instance()
    check_logfilter()
    
    export_encoded_cacertificates()
    call_buildpack_startup()
