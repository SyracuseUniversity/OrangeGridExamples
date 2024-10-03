# Octave

This is a simple example of running a basic Octave program under HTCondor.  This example uses a
single CPU and can serve as a template for Octave programs that may require some specialized 
packages but does not need a GPU.  For GPU examples, please see the tensorflow and PyTorch
directories.


## Installing Conda

For most Octave users we recommend installing [Miniforge](https://github.com/conda-forge/miniforge) and 
using that to manage your environment.  To install Miniforge:

```bash
wget https://github.com/conda-forge/miniforge/releases/download/24.7.1-0/Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh

bash Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh  -b -p $HOME/miniforge3
eval "$(${HOME}/miniforge3/bin/conda shell.bash hook)"
conda init
```

In order to be make Conda available automatically when you log into the cluster
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


## Install additional packages

You can now use the `conda` command to install additional packages you'll need.
To install create an environment containing octave

```bash
conda create -n octave conda-forge::octave
conda activate octave
```

It's worth reading through the
[Conda users guide](https://docs.conda.io/projects/conda/en/latest/user-guide/index.html).  Some useful commands are

  * `conda list` lists all installed packages
  * `conda search` finds available packages that match the provided name, for
    example `conda search torch` will find all avaialable versions of `torch`,
    `pytorch` etc
  * `conda update` updates packages


## Running the sample program

This directory contains a sample program `octave_demo.oct` which simply adds the
numbers from 1 to 100 and prints the result.  To submit this to the cluster the command is

```bash
condor_submit octave_demo.sub
```

After submitting you can check on the progress with

```bash
condor_q netid
```

or monitor it with

```bash
watch -n 5 condor_q netid
```

In both cases replace `netid` with your SU Net ID.

When it completes you can check the output with

```bash
cat output/octave_demo.out
```

## The wrapper script

Note that `octave_demo.sub` does not call `octave_demo.py` directly.  This is because the job needs to be
set up so that it will run inside th Conda environment, which is not enabled by default.  The submit
files therefor calls a wrapper script, which sets up the environment and then runs the octave code.  For most
simple Octave applications you should be able to modify `conda_wrapper.sh` without modifying the submit
file.



 


