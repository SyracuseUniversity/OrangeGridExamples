# Tensorflow

Tensorflow is a large, complex toolkit with a lot of dependancies.  We therefore recommend 
installing with [Conda](https://docs.conda.io/en/latest/).


# Installing with Conda

To install Conda:

```bash
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh

bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3
eval "$(${HOME}/miniconda3/bin/conda shell.bash hook)"
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


## Installing tensorflow and other packages

Once Conda has been set up install tensorflow with

```bash
eval "$(${HOME}/miniconda3/bin/conda shell.bash hook)"
conda create -n tfgpu python=3.11.11
conda activate tfgpu
conda install -y pip
pip install --upgrade pip
python3 -m pip install 'tensorflow[and-cuda]'
```

After activating the `tfgpu`  environment you can install any additional packages you
may need, for example

```bash
conda install scipy 
```

It's worth reading through the
[Conda users guide](https://docs.conda.io/projects/conda/en/latest/user-guide/index.html).  Some useful commands are

  * `conda list` lists all installed packages
  * `conda search` finds available packages that match the provided name, for
    example `conda search torch` will find all avaialable versions of `torch`,
    `pytorch` etc
  * `conda update` updates packages


## Running the tensorflow example

This directory contains a simple example `tensorflow.py` that reports on the available devices
and performs a simple tensor calculation.  To run it on a GPU on the cluster


```bash
condor_submit tensorflow_demo.sub
```

Note that this submit file includes

```
Requirements = CUDADriverVersion >= 12.0
```

OrangeGrid includes many different kinds of GPUs, rather than specifying a 
specific model number it is better to specify the minimum parameters that 
the job needs in order to run.  In this case, recent versions of Tensorflow
require a recent version of CUDA.

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
cat output/tensorflow_demo.out
```

## The wrapper script

Note that `tensorflow_demo.sub` does not call `tensorflow_demo.py` directly.
This is because the job needs to be set up so that it will run inside the Conda
environment, which is not enabled by default.  The submit files therefor calls
a wrapper script, which sets up the environment and then runs the tensorflow
code.  For most simple applications you should be able to modify
`tensorflow_wrapper.sh` without modifying the submit file.  Note also that the 
submit file requires


