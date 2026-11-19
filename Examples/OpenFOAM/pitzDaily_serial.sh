#!/bin/bash
# Runs inside the OpenFOAM container.  Copies the pitzDaily case into
# output/, builds its mesh and runs the solver on one core.

set -e

rm -rf output/pitzDaily
cp -r pitzDaily output/pitzDaily
cd output/pitzDaily

# Build the mesh described in system/blockMeshDict
blockMesh > log.blockMesh 2>&1

# Run the steady state solver until it converges or reaches endTime
simpleFoam > log.simpleFoam 2>&1

echo "Finished pitzDaily on $(hostname)"
tail -n 20 log.simpleFoam
