#!/bin/bash
# Runs on the execute node.  Starts the OpenFOAM container and runs the
# script named in the submit file's arguments inside it, with the OpenFOAM
# commands available.
#
#   openfoam_wrapper.sh <script> [script arguments]

# Some OrangeGrid machines provide the container program under its newer
# name, apptainer, and some under its older name, singularity.  Both run
# the same container.
if command -v apptainer > /dev/null; then
    container=apptainer
else
    container=singularity
fi

$container exec openfoam.sif openfoam2512 "$@"
