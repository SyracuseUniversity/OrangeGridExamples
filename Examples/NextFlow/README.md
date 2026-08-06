# NextFlow

Consists of processes wired together by channels.  Think Unix processes
connected by pipes, in fact that explictly reference the Unix Philosphy 
(https://en.wikipedia.org/wiki/Unix_philosophy)


## Installation

Install Conda, then needs Java


```
eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"
conda create -y -n nextflow
conda activate nextflow
conda install conda-forge::openjdk

curl -s https://get.nextflow.io | bash
```



## Defining a workflow

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

runs but produces nothing


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

ends up in `work/b3/87ec8808079e803aed52bd77d2b229/hello.txt`.

## Chaining processes

```
process sayHello {
    input:
    path hello_path

    output:
    path 'hello.txt'

    script:
    """
    echo -n '${hello_path} says: hello' > hello.txt
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
  def query_ch = channel.fromPath("nextflow")
  sayHello(query_ch)
  addWorld(sayHello.out).view()
}
```

reports the location of the file containing "nextflow says: hello world".


## DSL2

"domain specific languages"

Very nice presentation here
https://icbi-lab.github.io/current-topics-bioinformatics-lecture/07_nextflow_dsl2.html#9



Channels are not just passive pipes


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

Conceptually similar to

```python
sum(map(lambda it: it*it, range(1,5)))
```





## Executing

While a process defines what command or script has to be executed, the executor
determines how that script is run on the target system.
