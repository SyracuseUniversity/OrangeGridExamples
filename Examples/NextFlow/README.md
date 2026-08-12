# NextFlow

[NextFlow](https://www.nextflow.io/) is framework for creating scientific
workflows with an emphasis on how data moves between various stages of
processing.  It is inspired in part by the [Unix Philosphy]
(https://en.wikipedia.org/wiki/Unix_philosophy), encapsulated in the way data
flows between processes connected by pipes, for example to sum the cummulative
number of lines in all text files within a directory and its subdirectories.

```bash
find . | grep txt | xargs cat | wc -l 
```

NextFlow is also based on the idea of [dataflow
programming](https://en.wikipedia.org/wiki/Dataflow_programming), a model with
some similarities to functional programing as discussed in the documentation on 
[parallel programming](../Parallelism).  There is also a paper on [Programming
Languages for Distributed Computing
Systems](https://ranger.uta.edu/~weems/NOTES6350/p261-bal.pdf) that is cited in
the NextFlow documentation that may be helpful in understanding its underlying
model.


## Installation

NextFlow itself is written in Java, although it can run workflows in any
language.  The first step in installation is therefore to install Java, which
can most easily be done through Conda.  First, set up a Conda installation
according the instructions in the [Python](../Python) documentation, then create
an environment and install Java


```bash
eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"
conda create -y -n nextflow
conda activate nextflow
conda install conda-forge::openjdk
```

Once that's done, install NextFlow from the installer on the site

```bash
curl -s https://get.nextflow.io | bash
```

This will place the `nextflow` executable in your home directory, you can then
move it to some location in your `$PATH` if you want.


## Defining a workflow

In the simplest use NextFlow resembles many other programming languages,
processes are defined like functions, and then called by the workflow.


```
process sayHello {
    script:
    """
    echo 'Hello'
    """
}

workflow {
    sayHello()
}
```

If this code is placed in a file called `workflow.nf` then it can be run with
the command

```bash
nextflow workflow.nf
```

Various diagnostic information will be printed, but the message itself won't be.
In order to capture the output it must be sent to a file, and the file should be
listed as an output of the process:


```
process sayHello {
    output:
        path "hello.txt" 
  
    script:
    """
    echo 'Hello' > hello.txt
    """
}

workflow {
    sayHello()
}
```

If a full path is not specified then the file will end up somewhere under the
`work` directory that NextFlow creates to manage data.  For example in one test
run the file ended up as `work/b3/87ec8808079e803aed52bd77d2b229/hello.txt`.


## Chaining processes

Of course worfklows are not restricted to a single process.  Mutiple processes
can be defined and the workflow can  wire them together, this wiring occurs
through a
[channel](https://training.nextflow.io/latest/hello_nextflow/02_hello_channels/).
Channels are in many ways the core of NextFlow, as the documentation states they
are 

> queues designed to handle inputs efficiently and shuttle them from one step to
> another in multi-step workflows, while providing built-in parallelism and many
> additional benefits.

Here is an example that creates a file containing "hello" and then a second file
that appends "world":

```
process sayHello {
    input:
    val greeter

    output:
    path 'hello.txt'

    script:
    """
    echo -n '${greeter} says: hello' > hello.txt
    """
}

process addWorld {
    input:
    path input_file

    output:
    path 'helloworld.txt'

    script:
    """
    cat ${input_file} > helloworld.txt
    echo -n ' world' >> helloworld.txt
    """
}


workflow {
  def query_ch = channel.of('nextflow')
  sayHello(query_ch)
  addWorld(sayHello.out).view()
}
```

This reports the location of the file containing "nextflow says hello world".

With this in place the power of channels begins to become apparent.  To
parallelize this example over several values it is just necessary to add the new
values to the channel

```
  def query_ch = channel.of('nextflow', 'OrangeGrid')
```

When run this now produces two files at different locations in the `work`
directory, one with "NextFlow says hellow world" and the other with "OrangeGrid
says hello world."


## Channels are more than pipes

By enabling `DSL2` (Domain-specific language) channels gain even more power,
supporting an entire programming language.  In addition to the official NextFlow
documentation there is a nice presentation on this
[here](https://icbi-lab.github.io/current-topics-bioinformatics-lecture/07_nextflow_dsl2.html).
As an example, this workflow sums the squares of the integers from 1 to 5.

```
nextflow.enable.dsl=2

workflow {
    Channel
        .of(1..5)
        .map { it * it }
        .sum()
        .view { result -> "\sum_{i=1 \to 5} i^2 = $result" }
}
```

This is conceptually very similar to the Python code

```python
sum(map(lambda it: it*it, range(1,5)))
```


## Running on OrangeGrid

NextFlow processes are run by an
[executor](https://docs.seqera.io/nextflow/executor), which so far has been
hidden but which can be configured to run on a wide variety of systems.  The
good news is that it is very simple to configure the executor to use HTCondor,
just add a line to the NextFlow configuration file:

```bash
echo "process.executor = 'condor'" >> ~/nextflow.config
```

After doing this rerunning the "hello world" workflow will run "NextFlow" and
"OrangeGrid" processes as Condor jobs, in parallel.

Alternately, if only some processes should be handed over to HTCondor the
executor can be specified for each process

```
process run_on_condor {
    executor = 'condor'
    ...
```

If any additional properties are needed by the processes they can be specified
as `clusterOptions`. For example if a process needs to run on a GPU:


```
process run_on_gpu {
    clusterOptions 'requirements = CUDADeviceName =!= undefined', '+requestGPUs	= 1'
	
...
```
