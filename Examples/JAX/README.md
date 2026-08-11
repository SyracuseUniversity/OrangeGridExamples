# JAX

JAX is a Python library providing optimized mathematical operations for both CPUs
and GPUs.  Of particular note, it provides "just in time compilation" of math
routines, enabling dynamic optimization beyond the static optimizations in other
numeric libraries such as numpy.  Specifically, this approach allows for a
couple of very powerful optimizations:

  * The compiler knows the exact size of the arrays being operated on, this
    eliminates the need for size checks and allows code to be more specific.
  * Several operations can be chained together.  Move data between main memory
    and GPU memory is very slow and can often be a performance bottleneck.  JAX
    can optimize code such that data stays on the GPU between operations, rather
    than needing to be moved back and forth.

In addition JAX provides sophisticated memory management tools for moving data
bewteen host memory and GPU memory, as well as tools to distribute computation
across multiple devices.

## Installing JAX

Jax is a standard Python library and can be installed using pip.  This does
require an additional step when using Conda however.  Assuming Conda has been
installed as in the [Python](../Python) example, the first step is to create a
new environment:


```bash
eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"
conda create -y -n jax
conda activate jax
```

then use Conda to install pip

```bash
conda install pip
```

then use pip to install JAX.  While JAX does have a version compatible with CUDA
12 it may be preferable to use the version targetting CUDA 13 to get the latest
features.

```bash
pip install -U "jax[cuda13]"
```

As of the time of writing, on OrangeGrid it will also be necessary to instal the
[CUDA 13 compatibility library](../CUDA13) to enable CUDA 13 to work with the
older NVIDIA drivers currently in use on the cluster.  For the purpose of
comparison we'll also install numpy here.

```bash
conda install cuda-compat
conda install numpy
```

Finally, in order to pick up the compatibility library it's necessary to set the
`LD_LIBRARY_PATH` to point to its location

```bash
export LD_LIBRARY_PATH=/home/$(whoami)/miniconda3/envs/cuda13/cuda-compat:${LD_LIBRARY_PATH}
```

## Using JAX

As a first example consider the problem of multiplying two matrices and then
finding the eigenvalues of the result.  With numpy this would be done as:

```python
#!/usr/bin/env python

import numpy as np
import time

def mult_and_eigen(A,B):
    C = np.matmul(A,B)
    return np.linalg.eig(C)

start_time = time.time()

for _ in range(1000):
    A = np.random.random((100, 100))
    B = np.random.random((100, 100))

    Z = mult_and_eigen(A,B)[0]

end_time   = time.time()

print(end_time - start_time)
```

When run this prints about 9.7 seconds.

To use JAX it is only necessary to import the library and change some of the
numpy calls to use it

```python
import jax.numpy as jnp

def mult_and_eigen(A,B):
    C = jnp.matmul(A,B)
    return jnp.linalg.eig(C)
```

This illustrates an important feature of JAX, it can largely be used as a
drop-in replacement for numpy.

Even on a CPU this provides a minor performance boost, the code now takes about
8.9 seconds.  This same code run on a GPU (an NVIDIA A100) takes 25.6 seconds.


The final stepis to enable compilation

```python
compiled = jax.jit(mult_and_eigen)

start_time = time.time()

for i in range(1000):
    A = np.random.random((100, 100))
    B = np.random.random((100, 100))

    Z = compiled(A,B)[0]
```

The code now takes 22.8 seconds.


## What's going on

Against expectations JAX on a GPU is performing much worse than numpy even on a
CPU.  However this is a consequence of the artificial nature of this example.
As noted in the [JAX
FAQ](https://docs.jax.dev/en/latest/faq.html#is-jax-faster-than-numpy)


> Keeping all that in mind, in summary: if you’re doing microbenchmarks of
> individual array operations on CPU, you can generally expect NumPy to
> outperform JAX due to its lower per-operation dispatch overhead. If you’re
> running your code on GPU or TPU, or are benchmarking more complicated
> JIT-compiled sequences of operations on CPU, you can generally expect JAX to
> outperform NumPy.

As code complexity grows JAX's advantages will become more apparent.  As always, 
see the project's own [documentation](https://docs.jax.dev/en/latest/index.html)
for more advanced use.


## Memory management

JAX allows data stuctures to be distributed across mutiple devices, this allows
structures to be trasparently larger than could fit on a single GPU, while still
often getting performance boosts from that portion that can be stored on the
device.  Full details are in the [host
offloading](https://docs.jax.dev/en/latest/notebooks/host-offloading.html)
section of the manual but here are some example to get a taste of how it works.

First, consider a situation where there are two GPUs available (on OrangeGrid
this would be done by adding `+request_gpus=2` to the submit file).  This code
witll create a *Mesh* named `x` containing both devices.

```python
from jax.sharding import Mesh, PartitionSpec as P, NamedSharding
import jax.numpy as jnp
import jax

devices = jax.local_devices()[:2]
x_mesh  = Mesh(devices, ('x',))
```

The next step is to tell JAX how to split data across the two devices by
specifying the *sharding*.  Here the data will be split along the first axis

```python
sharding = NamedSharding(mesh, P('x', None))
```

Next, create some data in a standard host memory array, and use `device_put` to
move it to the GPUs

```python
cpu_array  = jnp.arange(8, dtype=jnp.float32)
gpus_array = jax.device_put(cpu_array, sharding)
```

This will put the portion of the array containing `[0,1,2,3]` on device 1 and
`[4,5,6,7]` on device 2, but all subsequent operations on this array will work
as if it were all on one device, up to issues of performance.

It is also possible to distribute data between host and GPU memory.  First find
the local CPU and GPU in the list of devices, and construct an array containing
them

```python
cpu_device = [d for d in jax.devices() if d.platform == 'cpu'][0]
gpu_device = [d for d in jax.devices() if d.platform == 'gpu'][0]
devices    = jnp.array([cpu_device, gpu_device])
```

The rest of the code is unchanged and, again, all operations on this data will
work without the programmer needing to keep track of the underlying storage.

## Distributed computing

The previous section hints at the power of sharding over a mesh of devices, but
JAX can go further and work accross devices distributed accross different nodes.
The details are beyond the scope of this tutorial, please see the official
documentation for 

(Introduction to multi-controller
JAX)[https://docs.jax.dev/en/latest/multi_process.html] and a more complete
example in (The Training
Cookbook)[https://docs.jax.dev/en/latest/the-training-cookbook.html].


