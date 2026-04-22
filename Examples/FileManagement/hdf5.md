# HDF5

The [Hierarchical Data Format](https://www.hdfgroup.org/solutions/hdf5/) is a
well established tool for storing large quantities of potentially complex
data in a single file.  As the name "hierarchical" might imply, data is structured
in ways that closely resemble the hierarchy of directories in a file system,
with paths of the form `/a/b/c` referring uniquely to a chunk of data.

The examples that follow will concentrate on Python, both because it is
widely used and because (we hope!) the syntax is simple enough that 
even those who use other languages will be able to understand the meaning.
HDF5 is available for most other common languages too, including
  * [R](https://github.com/hhoeflin/hdf5r)
  * [Julia](https://github.com/JuliaIO/HDF5.jl)
  * [C](https://support.hdfgroup.org/documentation/hdf5/latest/_l_b_a_p_i.html)

and even some uncommon ones
  * [Haskell](https://hackage.haskell.org/package/hdf5)


To start, we'll use the [uv]() package manager to set up a development 
environment containing h5py and numpy (see the documentation for 
[uv on OrangeGrid](../uv) for more details).


```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
uv init hdf5examples
cd hdf5examples
uv add h5py
uv add numpy
```

Creating a new HDF5 file is as simple as creating a regular file.  In this example
we create a new file and then store an array 

```python
import h5py
import numpy as np

with h5py.File("mytestfile.hdf5", "w") as f:
    dset    = f.create_dataset("/demo/examples/example01", (10,), dtype='i')
    dset[0] = 5
```

The first argument specifies the path, notice that all the components of the
path (here "/demo" and "/demo/examples") will be created automatically.  The
second argument, `(10,)` indicates the "shape" of the data to create, following
the numpy conventions.  Specifically this indicates a one dimensional array
with ten elements, a two dimensional with 10 rows of 10 columns would be
`(10,10)`.  Finally the `dtype` argument indicates that the values will be
integers.  As with numpy, values are initially set to 0.  The following line
makes the array available through a variable and the next one sets element 0
to 5.  This could also have been accomplished by first retrieving the array
from the file

```python
dset2    = f['/demo/examples/example01']
dset2[0] = 5
```

Reading data is even more straightforward

```python
import h5py

with h5py.File("mytestfile.hdf5", "r") as f:
    print(f['/demo/examples/example01'][0])
```

Once a file has been opened for either reading or writing the file 
object also acts as a python dictionary at every level

```
for name in f.keys():
    print(name)

for name in f['demo'].keys():
    print(name)
```

In addition to the data itself HDF5 supports *attributes* which are arbitrary values
attached to data.  This makes it easy to add information about the data such as when
it was created and the code versions used.  One very useful attribute is the git version
of the code, which enables anyone with access to the repo to run the exact same version
for testing or validation.  The use of git for all code is highly recommended, but is
beyond the scope of this document.  Git information can be obtained though Python
with the [GitPython](https://gitpython.readthedocs.io/en/stable/tutorial.html) library.

As an example, to add gitpython to the project

```
uv add gitpython
```

then to create data with annotations for the time at which the code was run and the
git branch and hash used

```python
import h5py
import git
import datetime

with h5py.File("mytestfile.hdf5", "w") as f:
    dset      = f.create_dataset("/demo/examples/example01", (10,), dtype='i')
    values    = dset['/demo/examples/example01']
    values[0] = 5

    now = datetime.datetime.now()
    values.attrs['run_at'] = str(now)

    repo   = git.Repo('.')
    values.attrs['gitsha'] = repo.head.object.hexsha
    values.attrs['branch'] = repo.active_branch.name
```


## Strategies for arranging data

There is no one right way to store data in HDF5, but there are a few general
ways of thinking that might inform how to deal with any particular research
project.  To start with, consider a typical problem, iterating some computation
over multiple parameters with an initial version that writes a new file for each 
value, with the inputs in the filename:


```python
import numpy as np

for x in np.arange(0.0,1.0,0.1):
    for y in np.arange(0,11,1):
        for z in np.arange(20,21,1):
            value    = some_calculation(x,y,z) 
            filename = f"{x:.3f}_{y:03d}_{z:03d}.dat"
            with open(filename,"w") as f_out:
                print(value,file=f_out)
```

This will produce a lot of files, but the advantage is that it's easy to find a
particular result just by searching for the filename.

This structure can be replicated in HDF5

```python
import numpy as np
import h5py

with h5py.File("mytestfile.hdf5", "w") as f:
    dset    = f.create_dataset("/demo/examples/example01", (10,), dtype='i')
    dset[0] = 5

    for x in np.arange(0.0,1.0,0.1):
        for y in np.arange(0,11,1):
            for z in np.arange(20,21,1):
                value    = some_calculation(x,y,z) 
                storage  = f.create_dataset(f"{x:.3f}/{y:03d}/{z:03d}", (1,) dtype='f')
                storage[0] = value
```

This creates an single-value array for each `x/y/z` set of parameters.  Again, it is easy
to locate any particular result but at the cost of making it difficult to do post processing
on the full set of results, for example finding their average.

An alternate approach would be to have separate arrays for the x, y, and z
values along with the results.


```python
import numpy as np
import h5py

xyz_values = [(x,y,z) for x in np.arange(0.0,1.0,0.1)
                      for y in np.arange(0,11,1)
                      for z in np.arange(20,21,1)]

xs         = [v[0] for v in xyz_values]
ys         = [v[1] for v in xyz_values]
zs         = [v[2] for v in xyz_values]
values     = [some_calculation(*v) for v in xyz_values]


with h5py.File("mytestfile.hdf5", "w") as f:
    x_data       = f.create_dataset("/data/x", (10,10,10) dtype='f')
    y_data       = f.create_dataset("/data/y", (10,10,10) dtype='f')
    z_data       = f.create_dataset("/data/z", (10,10,10) dtype='f')
    results_data = f.create_dataset("/data/results", (10,10,10) dtype='f')

    x_data       = np.array(xs).reshape( (10,10,10) )
    y_data       = np.array(ys).reshape( (10,10,10) )
    z_data       = np.array(zs).reshape( (10,10,10) )
    results_data = np.array(results).reshape( (10,10,10) )

```

When reading this data subsequently the value at, say, `[2,3,4]` and its
corresponding parameters would be retrieved as

```python
value = f["/data/results"][2,3,4]
x     = f["/data/x"][2,3,4]
y     = f["/data/y"][2,3,4]
z     = f["/data/z"][2,3,4]
```

It is somewhat more cumbersome to pull out a particular value, but computing
the sum of all results is as easy as

```python
np.sum(f["/data/results"])
```

## Combining the output from several jobs into one HDF5 file

Thus far these examples have only considered a single process producing a fixed
amount of data, but in realistic situations the size of data to be generated
may not be known in advance, and when possible it will always be more efficient on
HTCondor to split tasks into multiple independent processes (see the document
on [parallelization](../parallelization) for more on this).

The naive approach to combining results would be for every job to write its data
to the same file, perhaps in a different dataset in an attempt to avoid conflicts:

```python
my_id = sys.argv[1]

with h5py.File("mytestfile.hdf5", "a") as f:
    results_data = f.create_dataset(f"/{my_id}/results", (10,) dtype='f')
    ...
```

However this won't work.  It is possible, with some care, to have one process
writing to an HDF5 file while other processes read from it, but even when
writing to different datasets HDF5 does not support multiple simultaneous 
writers.  For more on this see

  * This [Reddit post](https://stackoverflow.com/questions/34906652/does-hdf5-support-concurrent-reads-or-writes-to-different-files)
  * HDF5's documentation on [single writer, multiple readers](https://support.hdfgroup.org/documentation/hdf5/latest/_s_w_m_r_t_n.html)
  * This [example](https://github.com/h5py/h5py/blob/master/examples/multiprocessing_example.py) of using HDF5 with multiprocessing

Instead, a useful pattern is to have each job write its own file as usual, but
then have a concatenation and cleanup job that combines the results into a single
HDF5 file and deletes the original files.  For example, consider the example with the
nested loops from above, rewritten so that each iteration is run as its own job.

```python
x,y,z = [float(v) for v in sys.argv[1:]]

value    = some_calculation(x,y,z) 
filename = f"{x:.3f}_{y:03d}_{z:03d}.dat"
with open(filename,"w") as f_out:
    print(value,file=f_out)
```

The cleanup process would then look something like this:

```python
import sys
import os
import h5py

base_directory = sys.argv[1]
dir_list       = [f for f in os.listdir(base_directory) if f.endswith('.dat')]

with h5py.File("mytestfile.hdf5", "a") as f_out:
    x_values = f_out.create_dataset("unlimited", f"/data/x", (10,) dtype='f')
    y_values = f_out.create_dataset("unlimited", f"/data/y", (10,) dtype='f')
    z_values = f_out.create_dataset("unlimited", f"/data/z", (10,) dtype='f')
    results  = f_out.create_dataset("unlimited", f"/data/results", (10,) dtype='f')

    count  = 0

    for f in dir_list:
        x,y,z  = [float(v) for v in f[:-4].split('_')]
        result = float(open(f).readline().strip())

        x_values[count] = x
        y_values[count] = y
        z_values[count] = z
        result_values[count] = result

        count += 1

        try:
            os.remove(f)
        except:
            print("Unable to delete file", f)
```

Here the data sets are created with the `"unlimited"`  keyword, allowing them to grow
up to the maximum size allowed by HDF5, 2^64 elements per axis.  It is also possible 
to manually specify a smaller maximum using the `"resizable"` keyword, for more see the
[resizeable datasets](https://docs.h5py.org/en/stable/high/dataset.html#resizable-datasets)
section of the documentation.

This process could be run manually once a batch of jobs has completed but an even better
approach would be to use DAGMan to automatically run the cleanup job after all other
jobs have completed.  See the [parallelization](../parallelization) document for more
information on DAGMan.


## Compression

A single [IEEE floting point value](https://www.geeksforgeeks.org/computer-organization-architecture/ieee-standard-754-floating-point-numbers/)
takes 4 bytes, it's representation as text may take many more.  Python adds some overhead to every object but this
difference in size is still quite pronounced:


```python

>>> import sys
>>> a = 1.23456789123456891234567891234
>>> a
1.234567891234569
>>> sys.getsizeof(a)
24
>>> sys.getsizeof(str(a))
58
```

This means that simply moving data from a text file into HDF5, which stores number in their
native format, will lead to considerable space savings.  As an example, the following program 
generates 10,000 random numbers and stores then as both text and HDF5.

```python

#!/usr/bin/env python

import h5py
import numpy as np

values = np.random.rand(10000)

with open('size_test.txt','w') as f_out:
    for v in values:
        print(v,file=f_out)

with h5py.File("size_test.hdf5", "w") as f_out:
    f_out.create_dataset('/dataset', data=values)
```

Running this and looking at the sizes:

```bash
$ ls -sh size_test.*
196K size_test.txt
 88K size_test.hdf5
```

The HDF5 file is half the size of the text file!  However, in some cases it may
be possible to do even better by running a compression algorithm on the data.
This can be enabled with the `compression` keyword:


```python
    f_out.create_dataset('/dataset', data=values, compression="gzip")
```

There are other algorithms available and users can add new ones suited to their
particular data.  There are some performance impacts of enabling this, as data 
must be compressed when written and uncompressed when read.  As always, 
consult [the documentation](https://docs.h5py.org/en/stable/high/dataset.html) for
details.

Simply enabling this option and rerunning the example results in two new files

```bash
$ ls -sh size_test.*
196K size_test.txt   
 84K size_test.hdf5   
```

A savings of 4% may not seem like much, but random values typically don't compress
well due to their high [entropy](https://gwlucastrig.github.io/GridfourDocs/notes/EntropyMetricForDataCompression.html).
On the other extreme, repeated occurrences of the same value compresses very well,
changing the array to

```
values = np.full(10000, 1.234567891234567)
```

Produces files with dramatically different sizes


```bash
$ ls -sh size_test.*
180K size_test.txt
4.0K size_test.hdf5  
```

Data from real research will fall in between these extremes and consequently so
will the effectiveness of compression.  Unless access speed is the highest 
concern enabling compression should only help and is recommended.

