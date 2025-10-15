# Llama/Ollama

This is a simple example of running a basic LLM under HTCondor with Singularity.  This 
demonstrates a non-interactive use, a single prompt is given which generates a response,
the process then exits.  If your research requires interactive use of an LLM please contact 
researchcomputing@syr.edu and we'll be happy to discuss the options.


## Installing Ollama

For most users the easiest option will be to use a
[Singularity](https://docs.sylabs.io/guides/3.5/user-guide/introduction.html)
container.  It's worth reading through the documentation to better understand
what containers are and how they work, but in summary a container encapuslates
an entire working environment into a single file.  There's a large library of
containers available for Docker containers on
[Dockerhub](https://hub.docker.com/), and while we don't support Docker
directly the containers are largely compatible.

To download the Ollama container the command is

```bash
singularity pull docker://ollama/ollama
```

This command will only need to be run once.

## Running the sample program

This directory contains a sample program `ollama_app.sh` which starts an ollama
server and then runs a single query "What is HTCondor?" taken from
`input/prompt.txt`.  To submit this to the cluster the command is

```bash
condor_submit ollama_sub.sh
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
cat output/ollama_app.out
```

---
Please email any questions or comments about this document to [Research Computing](mailto:researchcomputing@syr.edu).

