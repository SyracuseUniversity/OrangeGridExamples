# HTCondor Diagnostics

This diretcory contains programs that are useful for getting a picture of the cluster.


## freeCores

A basic Python program (no extra packages needed) that ingests information from `condor_status` and
summarizes the number of free cores and nodes.  To use it, construct a query, output as json and pipe it
as input.  For example, this reports on all nodes available for local research work, omitting nodes currently
used for OSG

```bash
condor_status -const 'regexp("slot1@",name) && !regexp("OSG",name)' -long -json | python3 freeCores.py

Total CPUs 46360
Free CPUs 13378
Largest free CPUs on a single node 127

Total GPUs 140
Free GPUs 125
Largest free GPUs on a single node 4
```

This reports on the subset of these nodes that supports the avx2 instruction set

```bash
condor_status -const 'regexp("slot1@",name) && !regexp("OSG",name) && has_avx2' -long -json | python3 freeCores.py

Total CPUs 37606
Free CPUs 11728
Largest free CPUs on a single node 127
```


## Other recipes

This is a collection of HTCondor commands that don't require any additional programs.

List GPUs in use, by whom, and the time the job started:

```bash
condor_status -claimed -constraint 'vm_name == "its-u18-nfs-20191029_gpu"' -autoformat name RemoteOwner "formatTime(time() - TotalJobRunTime)"
```

List jobs waiting for a GPU and for how long.

```bash
condor_q -all -global -idle -constraint 'request_gpus' -autoformat:j owner "formatTime(EnteredCurrentStatus)" 2>/dev/null
```
