#!/bin/bash
set -eux
make get-sample
make build-image
tests/test-generic.sh tests/docker-compose-postgres.yml
tests/test-generic.sh tests/docker-compose-sqlserver.yml
tests/test-generic.sh tests/docker-compose-azuresql.yml
#build alternative build directory only for PostgreSQL
make get-sample-alt
make build-image-alt
tests/test-generic.sh tests/docker-compose-postgres-alt.yml
