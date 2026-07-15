# CUDA 1.3

Increasingly packages and libraries are written against the latest CUDA version,
[CUDA 13](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html).
However, CUDA 1.3 requires a recent version of the NVIDIA kernel drivers, which
are not yet available on OrangeGrid.

Until the drivers can be upgraded there is a [compatibility
library](https://docs.nvidia.com/deploy/cuda-compatibility/latest/) that will
allow code needing CUDA 1.3 to run, however only on "Tesla" models GPUs or
later, which as of time of writing means the following GPUs in OrangeGrid:

  * NVIDIA A100 80GB PCIe
  * NVIDIA A40
  * NVIDIA L40S


## Installing the library

It is first necessary to have a Conda environment set up, see the
[Python](../python) documentation for information on how to install Conda.

Once Conda is installed, create a environment for CUDA 1.3 and the compat library:

```bash
eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"

conda create -n cuda31
conda activate cuda31
conda install cuda
conda install cuda-compat
```

You will also need to set an environment variable to ensure that the
compatibility layer is found:

```
export LD_LIBRARY_PATH=/home/$(whoami)/miniconda3/envs/cuda31/cuda-compat
```

After that it should be possible to run packages needing CUDA 1.3 as well as
compile them using `nvcc`.


## Running on the cluster

Adding the following line to submit files will ensure that code is run on a
compatible GPU:

```
requirements = CUDACapability >= 8.0
```


---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).
