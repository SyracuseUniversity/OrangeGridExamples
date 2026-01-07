# Julia

This is a simple example of running a basic Julia program under HTCondor. This example uses a
single CPU and can serve as a template for Julia programs that may require additional packages.
For GPU examples using Julia, the setup is similar but requires adding CUDA.jl to your environment.

**Note:** Julia uses just-in-time (JIT) compilation, so the first run of any script will be
slower while packages are compiled. For this simple demo, expect 2-5 minutes of startup time.
For long-running research jobs this overhead is negligible, but it can be surprising for
short scripts. See the Julia-specific considerations section below for more details.


## Installing Conda

For most Julia users we recommend installing Julia through [Miniforge](https://github.com/conda-forge/miniforge)
and using Conda to manage your environment.

Download and run the installer:

```bash
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh -b
```

Then initialize Conda:

```bash
~/miniforge3/bin/conda init
```

After running `conda init`, log out and log back in for the changes to take effect.


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

Julia uses just-in-time (JIT) compilation, so the first run of any script is slower
while packages are compiled. For long-running batch jobs this overhead is negligible.
Subsequent runs are faster if Julia's package cache in `~/.julia` is preserved.

---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).
