# Multiple Jobs

The HTCondor `queue` command has a lot of options.  The full documentation is
[here](https://htcondor.readthedocs.io/en/latest/users-manual/submitting-a-job.html)
but this iexample llustrates one powerful technique, reading a set of arguments
from a file.

## Running the sample program

This directory contains a sample program `demo.sh` which simply echos the first
two arguments passed to it.  The submit file, `demo.sub` calls it five times
with arguments taken from `demo.dat`, with the output files numbered with the
`$(Process)` variable which HTCondor sets automatically from 1 to 5.  One key
point to note is that all five are run simultaneously, with each running as a
separate job.

To submit this to the cluster the command is

```bash
condor_submit demo.sub
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

When it completes you can check the outputs with

```bash
cat output/demo_*.out
```

---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).

