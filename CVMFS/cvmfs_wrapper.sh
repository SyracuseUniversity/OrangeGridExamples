#!/usr/bin/env bash

ls -ltr /cvmfs/atlas.cern.ch/repo/containers/images/singularity/x86_64-almalinux9.img 

apptainer exec /cvmfs/atlas.cern.ch/repo/containers/images/singularity/x86_64-almalinux9.img python3 -V

