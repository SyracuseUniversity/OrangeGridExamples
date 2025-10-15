# Hostname

This is a very simple HTCondor example that simply runs a command somewhere
in the pool of resources.  The command is `hostname` which, as the name implies,
returns the name of the computer.  You can try it manually from the command line

```bash
hostname
```

which will print something like

```
its-og-login3.ad.syr.edu
```

although the name may be different.

Next, to run the command though HTCondor

```bash
condor_submit hostname.sub
```

You can then check the status of your job with

```bash
condor_q netid
```

(replace "netid" with your SU netID).  The job should move from the Idle state to Run and then complete,
although this may happen too fast to notice.  If `condor_q` reports "0 jobs" then it has completed.  Check
the output with

```bash
cat output/hostname.out
```

It will contain the name of the node where HTCondor placed the job.

---
Please email any questions or comments about this document to [Research Computing](mailto:researchcomputing@syr.edu).

