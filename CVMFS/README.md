# CVMFS

The [CERN virtual filesystem](https://cvmfs.readthedocs.io/en/stable/) is a
method for distributing software and data to research institutions.  It's
notable for its multi-tier caching.  When a user access a file through CVMFS
the file is not typically pulled from the source, which prevents the source
from being overwhelmed.  Instead the local institution will probably store it
in a cache on first use and serve it from there.  Each individual machine where 
the file is accessed may also have a small local cache, which initially pulls
the institution's copy.  This architecture make CVMFS an excellent fit for 
cluster computing, where potentially hundreds of jobs will all need the same 
code or data.

In most cases anyone working on a project that utilizes CVMFS will already know 
what it is and how to use it.  Likewise, the files available through CVMFS
tend to be those used by large scientific collaborations and may not be 
useful to researchers in other areas.  However, the files are there for anyone
to use and there may be uses for some of them.


## Exploring CVMFS

Another of CVMFS's strengths is that to the end user it looks just like a regular
filesystem.  This means the contents can be explored easily:

```bash
$ ls /cvmfs
```

Most of the time this will appear to be empty, which just indicates that no data has yet been pulled 
to the local machine.  If you know the name of a particular repository, looking into
that repository will load the files

```bash
$ ls /cvmfs/atlas.cern.ch
repo  test1
```

The first time running this command it may be slow, after that the results will be cached and
the command will run much faster.  In the same way it's possible to explore deeper into the directory 
tree.  `/cvmfs/atlas.cern.ch/repo/containers/images/singularity/` holds a number of Apptainer
images, spanning different distributions and hardware.  Please see the [Apptainer](../Apptainer) 
example for more on containers, Singularity is Apptainer's previous name.

These containers can be used just like any other container

```bash
$ apptainer exec /cvmfs/atlas.cern.ch/repo/containers/images/singularity/x86_64-almalinux9.img python3 -V
Python 3.9.21
```

Note that this is a different version than is available on the OrangeGrid head nodes by default

```bash
$ python3 -V
Python 3.8.10
```

## Using CVMFS from HTCondor

Since CVMFS contents behave just like regular files there isn't much that needs to be done
in order for jobs to use it.  As of this writing it is necessary to request a node
that has CVMFS available with

```
requirements = hasCVMFS
```

but in the future all nodes will have it installed so this won't be necessary.

This directory nonetheless contains a simple example, which can be run with

```bash
$ condor_submit cvmfs_demo.sub
```

---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).


 



In most cases any software that would be needed on OrangeGrid can be intalled
directly in users' home directory through tools like [Conda](../python) or 
[uv](../uv).  However, sometimes software needs libraries that can only be installed 
through system management tools like apt on Debian-based Linux distros.  In such cases
effectively what is needed is an entire computer that the user has complete control over, 
a requirement which appears to be fundamentally at odds with the cluster as a shared 
resource.

This is where *containers* come in.  Containers are a technology that allow an
entire working environment to be packed into a single file, "going into" a
container is effectively like ssh-ing into another computer, with its own set of
software.  A container can even have a different operating system than the 
computer where the container is installed, a RedHat container can exist inside an Ubuntu 
system.

In addition to the flexibility, containers can be a very convinient way to install 
large, complex programs even other installation options are available.

Possibly the best known container system is [Docker](https://www.docker.com/),
which is not available on OrangeGrid.  However,
[Apptainer](https://apptainer.org/) is an alternate technology that is available,
and is largely compatible with Docker.

## Getting a container

Apptainer containers can be built from scratch, however this requires system priviledges 
that users don't have.  If you think you need a custom container, please email 
[researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).  In many cases however
a suitable Docker container will already exist and can be imported.

As an example, here's how to download a container with the
[Haskell](https://www.haskell.org/) programming language

```bash
apptainer pull docker://haskell
```

After pulling it, verify that the Haskell compiler is not available on the host 
system

```
$ ghc

Command 'ghc' not found, but can be installed with:

sudo apt install ghc
```

Then go into the the container with

```bash
apptainer shell haskell_latest.sif
```

The prompt will change and ghc will be available

```bash
$ apptainer shell haskell_latest.sif
Apptainer> ghc
ghc-9.14.1: no input files
```

It's also possible to run a command that exists inside the container from outside it

```bash
$ apptainer exec haskell_latest.sif ghc
ghc-9.14.1: no input files
```


## Using Apptainer on OrangeGrid

The `exec` command form is the key to using Apptainer on the cluster, since it
can be embedded directly into a shell script.  The example in this directory
uses ghc to compile the [Sieve of
Eratosthenes](https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes), a method of
finding prime numbers.  A version of the algorithm can be expressed very
elegantly in Haskell as

```haskell
sieve (x:xs) = x:(sieve $ filter (\a -> a `mod` x /= 0) xs)
ans = takeWhile (<200) (sieve [2..])
```

For details on what this is doing, and how to make it more effecient, 
see [this paper](https://www.cs.hmc.edu/~oneill/papers/Sieve-JFP.pdf).

To try the example run 

```bash
condor_submit apptainer_demo.sub
```

After submitting you can check on the progress with

```bash
condor_q <netid>
```

or monitor it with

```bash
watch -n 5 condor_q <netid>
```

In both cases replace `<netid>` with your SU Net ID.

When it completes you can check the output with

```bash
cat output/apptainer_demo.out
```

---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).


