# Pegasus

[Pegasus](https://pegasus.isi.edu/) is a workflow management system developed by
the Information Sciences Institute at the University of Southern California.  It
is extremely powerful and flexible and has been used by numerous large
scientific projects, many of which are highlighted on their [showcase
page](https://pegasus.isi.edu/application-showcase/).  Notable features of
Pegasus are it's abilities to pull data and executables from almost anywhere,
and to distribute computation across any resources the user has access to, even
dividing work within a single workflow.  However, as is often the case, this
power and flexibility comes at the cost of a fairly steep learning curve in
order to use the system effectively.  There is extensive documentation on the
site including a full [user
tutorial](https://pegasus.isi.edu/documentation/user-guide/tutorial.html),
interested users are encouraged to peruse this documentation.  Here we only
present a short introduction and steps to get Pegasus working in the OrangeGrid
environment.


# Installation

Pegasus contains components written in both Python and Java, so installation
requires a few steps.  First, install the Miniforge package manager and activate
the base environment:

```bash
wget
"https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash "Miniforge3-$(uname)-$(uname -m).sh" -b -p $HOME/miniconda3

eval "$(/home/$(whoami)/miniconda3/bin/conda shell.bash hook)"
```

Next, create an environment for Pegasus and enable it

```bash
conda create -y -n pegasus
conda activate pegasus
```

Then install Java and GitPython:

```bash
conda install -y conda-forge::openjdk
conda install -y conda-forge::gitpython
```

The Python bindings for Pegasus are installed through pip rather than conda, so
it's first necessary to use conda to install pip:

```bash
conda install pip
pip install pegasus-wms.api
```

That completes the prerequisites, the next step is to install Pegasus itself

```bash
wget https://download.pegasus.isi.edu/pegasus/5.0.8/pegasus-binary-5.0.8-x86_64_ubuntu_20.tar.gz
tar -xf pegasus-binary-5.0.8-x86_64_ubuntu_20.tar.gz
export PATH=${PATH}:/home/$(whoami)/pegasus-5.0.8/bin/
```

## Pegasus configuration files

Pegasus workflows are built in two steps.  First an abstract workflow is
defined, specifying the flow of data and naming the resources to be used.  Then
the workflow is "concretized" by mapping the abstract names for data object and
resources to physical entities.

The abstract workflow is specified by a YAML file.  To start with, here's an
example from the Pegasus git repository which can be obtained with the command

```bash
git clone https://github.com/pegasus-isi/process-workflow.git
```

This example workflow simply runs `ls -l /` and saves the results in a file
named `listing.txt`.

```yaml
x-pegasus:
  apiLang: python
pegasus: 5.0.4
name: process
jobs:
- type: job
  name: ls
  id: ID0000001
  stdout: listing.txt
  arguments:
  - -l
  - /
  uses:
  - lfn: listing.txt
    type: output
    stageOut: true
    registerReplica: true
jobDependencies: []
```

For the most part, apart from the `registerReplica` line, this should be fairly
clear.  A notable feature is that the output file is specified as an `lfn` or
*Logical File Name*.  This itself does not specify where the file lives, it
could be on the local file system, in an S3 bucket, or anywhere else.  Although
it is less obvious the same is true for the name `ls`, this file alone does not
map that name to the `/bin/ls` executable.

The mapping for filenames and other resources is handled by additional files.
The transformation catalogue in `transformations.yml` associates the name `ls`
with the pfn (*Physical File Name*) `/bin/ls` within the context of a particular
site:

```yaml
x-pegasus:
  apiLang: python
  createdOn: 06-23-26T13:31:21Z
pegasus: 5.0.4
transformations:
- name: ls
  sites:
  - name: condorpool
    pfn: /bin/ls
    type: installed
```

Then the site catalogue `sites.yml` concretizes the `condorpool` site named in
the transformation.  This also indicates the location of output directories and
so by default resolves the `listing.txt` lfn


```yaml
x-pegasus:
  apiLang: python
  createdOn: 06-23-26T13:31:21Z
pegasus: 5.0.4
sites:
- name: local
  directories:
  - type: sharedScratch
    path: /home/demo/process-workflow/scratch
    sharedFileSystem: false
    fileServers:
    - url: file:///home/demo/process-workflow/scratch
      operation: all
  - type: localStorage
    path: /home/demo/process-workflow/output
    sharedFileSystem: false
    fileServers:
    - url: file:///home/demo/process-workflow/output
      operation: all
- name: condorpool
  directories: []
  profiles:
    condor:
      universe: vanilla
    pegasus:
      style: condor
      data.configuration: condorio
```

Real workflows on OrangeGrid would want to take advantage of the fact that
users' home directories are available on the nodes by setting

```yaml
sharedFileSystem: true
```

everywhere the option appears.  However, this is how the file appears in the
example.


## Running the example

Although these files are fairly human readable in practice they would never be
written by hand.  Pegasus provides a Python API that should be used to generate
these files, which both isolates users from the details of the low-level
configuration and provides a natural environment in which to define more complex workflows.
The Python file for even this simple workflow is too large to include here, it
can be seen
[here](https://github.com/pegasus-isi/process-workflow/blob/master/workflow_generator.py)
or, better, by checking out the repository from git.

As an example though, the storage is defined starting on line 52 as

```python
        local = Site("local").add_directories(
            Directory(Directory.SHARED_SCRATCH, shared_scratch_dir).add_file_servers(
                FileServer("file://" + shared_scratch_dir, Operation.ALL)
            ),
            Directory(Directory.LOCAL_STORAGE, local_storage_dir).add_file_servers(
                FileServer("file://" + local_storage_dir, Operation.ALL)
            ),
        )
```

In order to enable shared storage for the scratch folder this would become

```python
        scratch = Directory(Directory.SHARED_SCRATCH, shared_scratch_dir)
        scratch.add_file_servers(FileServer("file://" + shared_scratch_dir, Operation.ALL))
        scratch.shared_file_system = True

        local = Site("local").add_directories(
            scratch,
            Directory(Directory.LOCAL_STORAGE, local_storage_dir).add_file_servers(
                FileServer("file://" + local_storage_dir, Operation.ALL)
            ),
        )
		
```

and similarly to also change the local storage.

The command to generate the complete set of YAML files is

```bash
./workflow_generator.py
```

Then to plan the workflow

```bash

pegasus-plan --conf pegasus.properties \
    --dir ${PWD}/submit \
    --sites condorpool \
    --output-site local \
    --cleanup leaf \
    --force \
    workflow.yml
```

although as a convenience the command `./plan.sh workflow.yml` can be used
instead.

The result of running this is a collection of standard HTCondor files, submit
files, one or more dag files, and shell scripts wrapping the actual work to be
done, including the core `ls -l /`.

Although there is a dag file the workflow should not be submitted with the usual
`condor_submit_dag` command, Pegasus itself should manage the workflow and it
provides several tools for doing so.  First, to launch the workflow

```bash
pegasus-run ${PWD}/submit/$(whoami)/pegasus/process/run0001
```

Once the workflow is launched the usual `condor_q` command can be used, but the
Pegasus command

```
pegasus-status -l ${PWD}/submit/$(whoami)/pegasus/process/run0001
```

will provide more information.  One aspect that will immediately be obvious is
that, although this workflow only runs one command, there will be five jobs with
various dependencies between them.  These addition jobs handle moving data and
setting up the workflow in various ways.

After the workflow runs `condor_history $(whoami)` can be used to show what ran,
the output will resemble this (output has been truncated so the full commands
are not shown)

```
/home/demo/pegasus-5.0.8/bin/pegasus-dagman -p 0 -f -l . -Lockfile process-0.dag.lock -AutoRescue 1 -DoRescueFrom
/home/demo/pegasus-5.0.8/bin/../bin/pegasus-kickstart -n pegasus::rc-client -N null -R local -L process -T 2026-06
/home/demo/pegasus-5.0.8/share/pegasus/sh/pegasus-lite-local.sh pegasus-kickstart -n pegasus::cleanup -N null -i -
/home/demo/pegasus-5.0.8/share/pegasus/sh/pegasus-lite-local.sh /home/demo/pegasus-5.0.8/bin/../bin/pegasus-ki
/home/demo/process-workflow/submit/demo/pegasus/process/run0001/00/00/ls_ID0000001.sh
/home/demo/pegasus-5.0.8/share/pegasus/sh/pegasus-lite-local.sh pegasus-kickstart -n pegasus::dirmanager -N null -
```

None of these are the `ls` command, the second to last command is a script that
wraps the `ls` but also manages a lot of setting to ensure the job communicates
with Pegasus properly.

For a simple example such as this all this overhead may seem excessive, but keep
in mind that in a full workflow of the kind Pegasus is designed to handle the
files may live almost anywhere on the internet and jobs may run across widely
distributed clusters on different networks at different institutions.  The true
power and utility of Pegasus only becomes apparent when managing very large and
complex workflows.  Interested users should follow up by reading the Pegasus
documentation and trying the additional examples.  On useful next step would be
to checkout a slightly more [complex
workflow](https://github.com/pegasus-isi/pipeline-workflow) from the Pegasus
documentation, which includes two steps, a call to `curl` to download a web page
and save it to a file, and a call to `wc` to count how many lines are in that
file.
