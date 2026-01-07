# Julia

This is a simple example of running a basic Julia program under HTCondor. This example uses a
single CPU and can serve as a template for Julia programs that may require additional packages.
For GPU examples using Julia, the setup is similar but requires adding CUDA.jl to your environment.


## Installing Conda

For most Julia users we recommend installing Julia through [Conda](https://github.com/conda-forge/miniforge) and
using that to manage your environment. To install Conda:

```bash
wget https://github.com/conda-forge/miniforge/releases/download/24.7.1-0/Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh

bash Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh  -b -p $HOME/miniforge3
eval "$(${HOME}/miniforge3/bin/conda shell.bash hook)"
conda init
```

In order to make Conda available automatically when you log into the cluster
you will also need to add the following to your `~/.bash_profile`

```bash
if [ -e ${HOME}/.bashrc ]
then
    source ${HOME}/.bashrc
fi
```

Here is some information on
[the difference between bashrc and bash_profile](https://linuxize.com/post/bashrc-vs-bash-profile/)

After making these changes log out and log back in.


## Installing Julia and additional packages

Once Conda is set up, create an environment with Julia:

```bash
conda create -n julia conda-forge::julia
conda activate julia
```

Julia has its own package manager for Julia-specific packages. To add packages,
start Julia interactively and use the Pkg module:

```bash
julia
```

Then at the Julia prompt:

```julia
using Pkg
Pkg.add("LinearAlgebra")
Pkg.add("Statistics")
```

Press Ctrl-D to exit Julia.

For GPU support, you would add the CUDA package:

```julia
Pkg.add("CUDA")
```


## Running the sample program

This directory contains a sample program `julia_demo.jl` which performs some
basic array operations and prints the results. To submit this to the cluster:

```bash
condor_submit julia_demo.sub
```

After submitting you can check on the progress with

```bash
condor_q $USER
```

or monitor it with

```bash
watch -n 5 condor_q $USER
```


When it completes you can check the output with

```bash
cat output/julia_demo.out
```


## The wrapper script

Note that `julia_demo.sub` does not call `julia_demo.jl` directly. This is because the
job needs to be set up so that it will run inside the Conda environment, which is not
enabled by default. The submit file therefore calls a wrapper script, which sets up the
environment and then runs the Julia code. For most simple Julia applications you should
be able to modify `conda_wrapper.sh` without modifying the submit file.


## Julia-specific considerations

Julia has a notable "time to first plot" issue where the first run of code is slower
due to just-in-time compilation. For long-running batch jobs this is usually not a concern,
but for short jobs you may want to consider using PackageCompiler.jl to create a custom
system image with your dependencies precompiled.

---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).
