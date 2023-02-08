#!/bin/bash

echo "Running Mendix Runtime shutdown scripts"
for script in ${BUILDPACK_INIT}/init.d/K*.sh
do
    $script
done
