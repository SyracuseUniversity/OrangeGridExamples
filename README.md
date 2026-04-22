# OrangeGrid Examples
<img width="100" height="100" src="https://researchcomputing.syr.edu/wp-content/uploads/orange-grid-440x440.png"/>

This repository provides code examples for commonly used applications within the OrangeGrid cluster.
In addition to exploring these examples on the web you can use [git](https://www.w3schools.com/git/git_intro.asp?remote=github)
to download them into your home directory on the cluster which will allow you to run them directly.  The command is

```
git clone http://github.com/SyracuseUniversity/OrangeGridExamples
```

## Start here

* [hostname](Examples/hostname): A simple example of submitting a job to the cluster, monitoring it, and checking its output

## Getting the most out of OrangeGrid

These examples discuss general techniques for optimizing performance and throughput

* [Checkpointing](Examples/Checkpointing): Learn how to save work that your jobs are doing, so if they exit for any reason HTCondor can restart them where they left off.
* [Parallelism](Examples/Parallelism): Learn how to divide a task into lots of smaller tasks that can run independently so they can spread out over the cluster.
* [File management](Examples/FileManagement): Learn how to arrange your data into chunks that are both more efficient for later analyses and perform better on the cluster.

## Using particular languages and libraries



## Need Help? 

Additional how-to documentation, such as connecting to clusters and running jobs, is [available in Answers](https://su-jsm.atlassian.net/l/cp/LQV915Gs). 

If you would like to contact us directly for assistance or requesting access, email [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu). 
