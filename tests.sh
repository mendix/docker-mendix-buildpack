#!/bin/bash

set -u

make get-sample
make build-image
cd tests
test-generic.sh docker-compose-postgres.yml
test-generic.sh docker-compose-azuresql.yml
