# OpenFOAM

[OpenFOAM](https://www.openfoam.com/) is a free and open source toolkit for
computational fluid dynamics (CFD).  It covers much of the same ground as
commercial CFD packages such as Ansys Fluent, including meshing, laminar and
turbulent flow, heat transfer, multiphase flow and more.

Because OpenFOAM needs no license, every job you run on OrangeGrid can use it
at the same time.  This makes it a good fit when you need to scale up, for
example running the same simulation over dozens or hundreds of different
geometries, boundary conditions or fluid properties.  With a commercial package
the number of simultaneous runs is usually limited by the number of licenses
available, not by the size of the cluster.

This example uses the OpenFOAM container published by OpenCFD, so nothing
needs to be compiled or installed.  If you haven't used containers before, the
[Apptainer](../Apptainer) example explains the basics.

## Getting the container

From this directory on an OrangeGrid login node run

```bash
apptainer pull openfoam.sif docker://opencfd/openfoam-default:2512
```

This takes a few minutes and creates a file called `openfoam.sif` of roughly
460 MB.  You only need to do this once.  Jobs read the container straight from
your home directory, so it does not need to be copied anywhere.

To check that it works, open a shell inside the container with the OpenFOAM
environment loaded

```bash
apptainer exec openfoam.sif openfoam2512
```

The prompt will change, and OpenFOAM commands such as `blockMesh` and
`simpleFoam -help` will be available.  Type `exit` to leave.

## The files in this example

  * `pitzDaily` and `cavity` are two OpenFOAM cases, taken from the tutorials
    that come with OpenFOAM.  Each has the usual `0`, `constant` and `system`
    directories.  Your own cases will look the same.
  * Each job has a submit file and a matching script that lists the OpenFOAM
    commands it runs, one per step.
    * `pitzDaily_serial.sub` and `pitzDaily_serial.sh` run one case on one
      core.
    * `pitzDaily_parallel.sub` and `pitzDaily_parallel.sh` run the same case
      on 4 cores.
    * `cavity_sweep.sub`, `cavity_sweep.sh` and `sweep.dat` run one case many
      times with different settings.
  * `openfoam_wrapper.sh` is the program HTCondor actually starts.  It opens
    the container and runs the script named in the submit file inside it.
    Some OrangeGrid machines call the container program `apptainer` and some
    use its older name `singularity`, so the wrapper uses whichever one the
    machine has.

Each script copies its case into `output` before running, so the original
case is never changed and you can run the example as many times as you like.

## A single run

The first example simulates turbulent air flow over a backward facing step
(the `pitzDaily` case) on one core.  Submit it with

```bash
condor_submit pitzDaily_serial.sub
```

and check on it with

```bash
condor_q <netid>
```

replacing `<netid>` with your SU Net ID.  It takes under a minute once it
starts.  `pitzDaily_serial.sh` runs two OpenFOAM commands, `blockMesh` to
build the mesh and `simpleFoam` to solve the flow.  When the job completes,
`output/pitzDaily_serial.out` shows the end of the solver log, and the full
case including results is in `output/pitzDaily`.  Each command also leaves a
log there, `log.blockMesh` and `log.simpleFoam`.

## Using several cores

OpenFOAM can split a case into pieces and run them on several cores at once
using MPI.  The second example runs the same case on 4 cores

```bash
condor_submit pitzDaily_parallel.sub
```

`pitzDaily_parallel.sh` adds three steps to the single run

  * `decomposePar` splits the mesh into 4 pieces, as set by
    `numberOfSubdomains` in `pitzDaily/system/decomposeParDict`.
  * `mpirun -np 4 simpleFoam -parallel` runs the solver on all 4 pieces at
    once.
  * `reconstructPar` joins the pieces back into one result.

The number 4 appears in three places, `request_cpus` in the submit file,
`numberOfSubdomains` in `decomposeParDict` and `-np` in the script, and all
three must match.  The results are in `output/pitzDaily_parallel`, and
`log.simpleFoam` there reports `nProcs : 4`.

All the cores of a job are on the same machine, so this works well up to the
number of cores in one node.  Small cases like this one do not get much faster
with more cores, since the pieces spend most of their time talking to each
other.  Larger meshes benefit more.

## Running many simulations at once

The real strength of OrangeGrid is running many independent jobs at the same
time.  The third example runs the lid driven `cavity` case four times, each
with a different viscosity and so a different
[Reynolds number](https://en.wikipedia.org/wiki/Reynolds_number).  The values
are listed in `sweep.dat`, one run per line

```
10, 0.01
20, 0.005
50, 0.002
100, 0.001
```

The first column is the Reynolds number, used to name the output, and the
second is the viscosity.  `cavity_sweep.sub` passes both to
`cavity_sweep.sh`, which writes the viscosity into
`constant/transportProperties` with `foamDictionary` before running
`blockMesh` and `icoFoam`.  Submit all four with

```bash
condor_submit cavity_sweep.sub
```

Each run gets its own directory, `output/cavity_Re10`, `output/cavity_Re20`
and so on.  To run a hundred variations instead of four, add lines to
`sweep.dat`; nothing else needs to change.  See
[multipleJobs](../multipleJobs) for more ways to submit many jobs from one
file.

## Looking at the results

The simplest way to view results is with [ParaView](https://www.paraview.org/)
on your own computer.  Copy a case directory from `output` to your computer,
create an empty file called `case.foam` inside it, and open that file in
ParaView.

## Using your own case

To run your own simulation, copy your case directory (the one containing `0`,
`constant` and `system`) into this directory.  Then copy the script and
submit file closest to what you need, and change the case name in both.  If
your case is meshed with `snappyHexMesh` or another tool, or needs other
preparation steps, add those commands to the script in place of
`blockMesh`.  Many OpenFOAM tutorials include an `Allrun` script that shows
the steps a case needs.

A few things to keep in mind

  * Set `request_memory` close to what your case actually uses.  The
    value reported by `condor_history <netid> -af MemoryUsage` after a test
    run is a good guide (it is in MB).
  * Results are written straight to your home directory.  Large cases can
    produce many gigabytes, so set `writeInterval` in `system/controlDict` to
    save only the time steps you need.
  * OrangeGrid jobs can be stopped and restarted on another machine.  For
    long runs, see [Checkpointing](../Checkpointing); OpenFOAM can restart
    from its latest saved time step with `startFrom latestTime;` in
    `system/controlDict`.  Note that the scripts here start each case from a
    fresh copy, so a restartable job should skip the copy and meshing steps
    when the case directory already exists.

The `pitzDaily` and `cavity` cases come from the OpenFOAM tutorials and are
distributed under the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.html),
like the rest of OpenFOAM.

---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).
