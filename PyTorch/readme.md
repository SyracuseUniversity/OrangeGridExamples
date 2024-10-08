# PyTorch

PyTorch is a large, complex toolkit with a lot of dependancies.  We therefore recommend using
[Conda](https://github.com/conda-forge/miniforge) to install it.


## Installing Conda

To install Conda:

```bash
wget https://github.com/conda-forge/miniforge/releases/download/24.7.1-0/Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh

bash Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh  -b -p $HOME/miniconda3
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


## Installing PyTorch  and other packages

Once Conda has been set up install tensorflow with

```bash
conda create -n pytorch
conda activate pytorch
conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia
```

After activating the pytorch environment you can install any additional packages you
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


## Running the PyTorch example

This directory contains a simple example `pytorch_demo.py` that reports on the available devices
and performs a simple calculation.  To run it on a GPU on the cluster


```bash
condor_submit pytorch_demo.sub
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
cat output/pytorch_demo.out
```

## The wrapper script

Note that `pytorch_demo.sub` does not call `pytorch_demo.py` directly.
This is because the job needs to be set up so that it will run inside the Conda
environment, which is not enabled by default.  The submit files therefor calls
a wrapper script, which sets up the environment and then runs the pytorch
code.  For most simple applications you should be able to modify
`pytorch_wrapper.sh` without modifying the submit file.


## Submit requirements

PyTorch requires a relatively recent GPU but OrangeGrid contains a mix of older
and newer hardware.  In order to ensure that the job is scheduled on a node
where it can it's necessary to set the requirements line in the submit file to

```
Requirements = CUDADriverVersion >= 12.0
```


