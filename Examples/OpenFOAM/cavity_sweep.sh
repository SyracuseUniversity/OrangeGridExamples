#!/bin/bash
# Runs inside the OpenFOAM container.  Copies the cavity case into
# output/cavity_Re<reynolds>, sets its viscosity and runs the solver on one
# core.
#
#   cavity_sweep.sh <reynolds> <viscosity>

set -e

reynolds=$1
viscosity=$2

rm -rf output/cavity_Re$reynolds
cp -r cavity output/cavity_Re$reynolds
cd output/cavity_Re$reynolds

# Replace the viscosity nu in constant/transportProperties.  The lid moves
# at 1 m/s and the cavity is 0.1 m across, so the Reynolds number is
# 0.1 / nu.
foamDictionary constant/transportProperties -entry nu -set "$viscosity" 2>&1

# Build the mesh described in system/blockMeshDict
blockMesh > log.blockMesh 2>&1

# Run the transient laminar solver to endTime in system/controlDict
icoFoam > log.icoFoam 2>&1

echo "Finished cavity_Re$reynolds (nu = $viscosity) on $(hostname)"
tail -n 20 log.icoFoam
