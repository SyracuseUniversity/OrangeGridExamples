# HTCondor Diagnostics

This diretcory contains programs that are useful for getting a picture of the cluster.


## freeResources

A basic Python program (no extra packages needed) that ingests information from `condor_status` and
summarizes the number of free cores and nodes.  To use it, construct a query, output as json and pipe it
as input.  For example, this reports on all nodes available for local research work, omitting nodes currently
used for OSG

```bash
condor_status -const 'regexp("slot1@",name) && !regexp("OSG",name)' -long -json | python3 freeResources.py

Resource                Total   Available
CPUs                    59784   9570
NVIDIA A100 80GB PCIe   16      1
NVIDIA A40              24      17
Quadro RTX 6000         96      84
Quadro RTX 5000         4       1

Largest free block of CPUs: 112, on a node with 128 CPUs
```

This reports on the subset of these nodes that supports the avx2 instruction set

```bash
condor_status -const 'regexp("slot1@",name) && !regexp("OSG",name) && has_avx2' -long -json | python3 freeResources.py

Resource                Total   Available
CPUs                    49229   8298

Largest free block of CPUs: 112, on a node with 128 CPUs
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

---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).

