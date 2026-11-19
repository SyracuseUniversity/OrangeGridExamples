#!/bin/bash
# Runs inside the OpenFOAM container.  Copies the pitzDaily case into
# output/, builds its mesh, splits it into 4 pieces and runs the solver on
# 4 cores with MPI.

set -e

rm -rf output/pitzDaily_parallel
cp -r pitzDaily output/pitzDaily_parallel
cd output/pitzDaily_parallel

# Build the mesh described in system/blockMeshDict
blockMesh > log.blockMesh 2>&1

# Split the mesh into processor0 ... processor3 as set in
# system/decomposeParDict
decomposePar > log.decomposePar 2>&1

# Run the solver on 4 cores.  -np must match numberOfSubdomains in
# system/decomposeParDict and request_cpus in the submit file.
mpirun -np 4 simpleFoam -parallel > log.simpleFoam 2>&1

# Join the pieces back into one result and remove them
reconstructPar > log.reconstructPar 2>&1
rm -rf processor*

echo "Finished pitzDaily_parallel on $(hostname)"
tail -n 20 log.simpleFoam
