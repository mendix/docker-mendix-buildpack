#!/usr/bin/env python
import json
import logging
import os
import subprocess
import sys

# DATABASE_ENDPOINT = sys.argv[1]

logging.basicConfig(
    level=logging.INFO,
    stream=sys.stdout,
    format='%(levelname)s: %(message)s',
)

def build_vcap_services():
    logging.debug("Executing build_vcap_services...")

    vcap_services_data = open("vcap_services.json").read()

    logging.debug("Set environment variable VCAP_SERVICES: \n {0}".format(vcap_services_data))

    export_vcap_services = "VCAP_SERVICES_TEST=88"
    os.environ['VCAP_SERVICES'] = vcap_services_data

def build_vcap_application():
    logging.debug("Executing build_vcap_application...")

    vcap_application_data = open("vcap_application.json").read()

    logging.debug("Set environment variable VCAP_APPLICATION: \n {0}".format(vcap_application_data))
    os.environ['VCAP_APPLICATION'] = vcap_application_data

if __name__ == '__main__':

    if os.getenv('DATABASE_ENDPOINT') is None:
        logging.error(
            'VCAP_SERVICES environment variable not found.'
        )
    build_vcap_services()
    build_vcap_application()
    os.system('bash')
