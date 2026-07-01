# Snakemake

[Snakemake](https://snakemake.readthedocs.io/en/stable/) specifies the
dependency relationships between files, and by implication the processes that
produce them, in a manner very similiar to the way the Unix utility
[make](https://en.wikipedia.org/wiki/Make_(software)) works.  Snakemake
configuration files consist of a set of rules for how to produce files, when a
user asks Snakemake to generate a file it first check to see if that file
already exists, if not it consults its rules for how to make it.  The process of
making the file will typically depend on the existence of other files, it sees
if those exist and if not looks for rules to make them, and so on recursively.
This may be a shift in mindset to how workflows are usually envisioned, as a
sequence of processes to run, but it can be a powerful model.

## Installing Snakemake

Snakemake is easiest to install through Conda.  If you don't already have a
Conda installation the steps are

```bash
wget https://github.com/conda-forge/miniforge/releases/download/24.7.1-0/Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh

bash Miniforge-pypy3-24.7.1-0-Linux-x86_64.sh  -b -p $HOME/miniconda3
```

Then to install Snakemake into a fresh environment

```bash
eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"
conda create -c conda-forge -c bioconda -c nodefaults -n snakemake snakemake
conda activate snakemake
```

## Using Snakemake

The rules to construct files are specified in a `Snakefile`.  The simplest
example produces one file and doesn't require any inputs:

```python
rule hello:
    output:
        "hello.txt"
    shell:
        "echo -n 'Hello ' > {output}"
```

The command to run this is

```bash
snakemake --cores 1 hello.txt
```

The `cores` parameter tells Snakemake how many CPUs to run on, this is useful
for parallelizing workflows.  At the moment through there's just one task, so
nothing to parallelize.  When run, Snakemake will display a lot of information
about how it is resolving the dependancies, and after it completes the file
`hello.txt` will be available.

Attempting to run a second time will report

```
Nothing to be done (all requested files are present and up to date).
```

In practice Snakefiles will specify multiple dependent rules.  The mechanism to
indicate that one rule relies on another one is the `input` tag.

```python
rule hello:
    output:
        "hello.txt"
    shell:
        "echo -n 'Hello ' > {output}"

rule world:
    output:
        "world.txt"
    shell:
        "echo 'world!' > {output}"

rule hello_world:
    input:
        "hello.txt",
        "world.txt"
    output:
        "hello_world.txt"
    shell:
        "cat hello.txt world.txt > {output}"
```

Here when Snakemake is asked for `hello_world.txt` it determines that it first
needs to generate `hello.txt` and `world.txt` (although if `hello.txt` is still
present from the previous run it will not be regenerated).

Next, note that `hello.txt` and `world.txt`do not depend on each other, so they
could be built simultaneously.  To see this in action, first add a delay to the
rules:

```python
rule hello:
    output:
        "hello.txt"
    shell:
        "sleep 30 && echo -n 'Hello ' > {output}"

rule world:
    output:
        "world.txt"
    shell:
        "sleep 30 && echo 'world!' > {output}"
```

Then in a second window run

```bash
top -u $(whoami)
```

Then in the first window remove the previously generated files and rerun with
two cores

```bash
rm hello.txt world.txt hello_world.txt
snakemake --cores 2 hello_world.txt
```

and watch the second window.  Two `sleep` jobs will be visible, indicating that
the first two rules are running simultaneously.


## Using Snakemake with HTCodor

Snakemake doesn't support HTCondor natively, but it does have a plugin systems
and one such plugins supports HTCondor.  A few additional packages are needed to
use it.

```bash
conda install -c conda-forge -c bioconda python-htcondor snakemake-executor-plugin-htcondor
```

In addition another utility is needed to generate the configuration files

```bash
conda install cookiecutter
```

To generate the configuration run

```
cookiecutter --output-dir ~/.config/snakemake gh:Snakemake-Profiles/htcondor
```

This will ask a few questions, the only requirement is that files are placed
somewhere in your home directory.

Now remove the `sleep 30 &` portion of the rules, delete the generated files and
resubmit using HTCondor:

```bash
rm hello.txt world.txt hello_world.txt
snakemake --profile htcondor hello_world.txt
```

In another window run

```
watch condor_q $(whoami)
```

and you should see two jobs start up, one for each of the parallelizable files.

However, even as the HTCondor jobs are running the Snakemake command will still
be active.  Since Snakemake is not inherently designed as a distributed system
it runs cluster jobs the same way it runs local processes, it starts a command
and waits for it to finish.  This is OK for short workflows, but is a problem
for longer ones that may run several days.

There are a few solutions to this, but the best one is to run the Snakemake
process itself as an HTCodor job.  However there is a subtelty here, Snakemake
has to be able to launch new jobs, but jobs can only be launched from the head
node, not the workers.  The solution is to run the Snakemake job in the *local
universe*.  This is a special universe that runs jobs directly on the head node
rather than farming them out to to the worker pool.  Apart from this change the 
submit file is standard:

```
universe = local

executable = run_snakemake.sh

output = snakemake.out
error  = snakemake.err
log    = snakemake.log

queue
```

The shell file just sets up the environment and runs Snakemake

```bash
#!/bin/bash

eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"
conda activate snakemake

snakemake --profile htcondor hello_world.txt
```


## A more complex example

Here's a somewhat more elaborate Snakefile that utilizes some additional
features to compute the squares of the first five positive integers, then adds
them together.


```
rule square:
    output:
        "squares/square_{i}.txt"
    run:
        i = int(wildcards.i)

        result = i ** 2

        with open(output[0], "w") as f:
            f.write(str(result))

rule sum:
    input:
        expand("squares/square_{i}.txt", i=range(1, 6))
    output:
        "sum_of_squares.txt"
    run:
        total = 0

        for file in input:
            with open(file, "r") as f:
                total += int(f.read().strip())

        with open(output[0], "w") as f:
            f.write(f"{total_sum}\n")
```

The most immediate thing to notice is that the rules have `run:` sections rather
than `shell:`.  This demonstrates one of the key features of Snakemake, the
ability to embed Python code directly.  In fact Snakemake describes Snakefiles
as a Python-based language.

Next, notice the use of the `expand` function.  As might be expected, this is a
compact way of specifying that the input files are `square_1.txt` through
`square_5.txt`.

Finally, `wildcards` is a special *namespace*, within this namespace `i` is
bound by matching the pattern of the output file with the name requested by the
input file of the `sum` rule.  For more on wildcards, see [this book
draft](https://farm.cse.ucdavis.edu/~ctbrown/2023-snakemake-book-draft/beginner+/wildcards.html#the-wildcard-namespace-is-implicitly-available-in-input-and-output-blocks-but-not-in-other-blocks).

Just as with the previous example, this can run directly with

```bash
snakemake --cores 5 sum_of_squares.txt
```

Or it can be distributed to the cluster with

```bash
snakemake --profile htcondor sum_of_squares.txt
```

or by submitting this command to the local universe.


## An issue and a workaround

Regrettably, the HTCondor examples do not work reliably on OrangeGrid.  In a
test of the sum of squares example, the jobs handling 1,2,3 and 5 worked, but
the job for 4 repeatedly failed with unhelpful error reporting.  At least one
researcher who had been using Snakemake on the cluster reported similar issues.
We can therefore not recommend using Snakemake on the cluster in this model.

However, there is an alternate approach to using Snakemake that retains a number
of the features.  Although Snakemake processes that use HTCondor can not
themselves be run on the worker nodes, Snakemake processes that do regular file
operations can.

Consider a workflow consisting of several steps, where some steps need to launch
up to 20 processes in parallel.  The command to do this efficiently would be

```bash
snakemake --cores 20 file_to_generate
```

and this command *can* run on a worker node.  The submit file would be


```
executable = run_snakemake.sh

output = snakemake.out
error  = snakemake.err
log    = snakemake.log

request_cpus = 20

queue
```

The shell file just sets up the environment and runs Snakemake

```bash
#!/bin/bash

eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"
conda activate snakemake

snakemake --cores $OMP_NUM_THREADS file_to_generate
```

The `OMP_NUM_THREADS` environment variable is set by HTCondor based on the
number of CPUs that have been requested, this ensures that Snakemake uses
exactly the number of cores that the submit file requested.

This provides almost the same level of parallelism that distributing the jobs
across the cluster would provide, but with a few caveats:

  * This assumes each job run by Snakemake uses only one CPU.  There is no
    provision for some jobs in the workflow using 1 and others using, say, 4.
	
  * Some parts of the workflow may not use all 20 cores, notably there might be
    a final combination step where the results are merged, this likely would use
    only a single core, leaving 19 cores idle that in principle another
    researcher could be using.
	
  * There is a limit to how far this scales, if a workflow has 400 jobs that
    could be paralellized they will only get run 20 at a time.  In part this can
    be addressed by requesting more CPUs, but OrangeGrid has no nodes with 400
    CPUs, and in general that more that are requested the longer it will take
    for the process to start.

Still, for small to medium sized workflows that are driven primarily by
relationships between files Snakemake run in this mode may be good option.


