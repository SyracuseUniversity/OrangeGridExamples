# Checkpointing

It is a regrettable but unavoidable fact that sometimes computers stop working 
and this is no less true of the computers that make up the OrangeGrid pool.  Any 
node might stop working at any time due to a hardware or power issue, or become 
disconnected from OrangeGrid due to a network issue, or it may need to be 
rebooted in order to update it.

When this happens HTCondor will notice and automatically restart any jobs that 
were running on that node.  This will be reported in the user's log file as

```
Job disconnected, attempting to reconnect 
Socket between submit and execute hosts closed unexpectedly 
```

but will otherwise be transparent to the user.  If the job was going to run for 
15 minutes and was interrupted after 10 this doesn't represent a serious 
problem.  However the situation is much worse if the job was going to run for 10 
days and was interrupted after 9.  Sometimes this is called "badput" to 
distinguish it from "throughput" and the goal is to minimize it.  This is where 
checkpointing comes in.

Broadly speaking, checkpointing is a design where a program occasionally dumps 
it's entire state to disk, and on startup checks to see if a saved state exists 
and if so loads it.  Consider this very simple (and highly artificial!) example 
of a program that adds all the numbers from 1 to 100.

```python

#!/usr/bin/env python

total = 0

for i in range(1,101):
    total += i

print(total)

```

In order to make this robust against the node going down we'll first have it 
dump its state every 10 steps:

```python
#!/usr/bin/env python

total = 0

for i in range(1,101):
    total += i

    if i % 10 == 0:
        with open('checkpoint.dat','w') as checkpoint:
            checkpoint.write(f"{i} {total}")

print(total)

```

To complete the process the program needs to look for a checkpoint and load it 
if there is one.


```python

#!/usr/bin/env python

from pathlib import Path

checkpoint = Path("checkpoint")
if checkpoint.is_file():
    with checkpoint.open() as f_in:
        line = f_in.readline()
        start_in, total_in = line.split()
        start = int(start_in)
        total = int(total_in)
else:
    start = 1
    total = 0

for i in range(start,101):
    total += i

    if i % 10 == 0:
        with open('checkpoint.dat','w') as checkpoint:
            checkpoint.write(f"{i} {total}")

print(total)

```


## How often to checkpoint

The above example demonstrates an important consideration in checkpointing, the 
*granularity*.  It would be possible to dump the state after every iteration, 
but then the program would be spending a lot of time opening files and writing 
to them, which tend to be extremely slow operations relative to performing 
computations.  A program that saves its state after ever step will have no 
badput, but could run 10 or 20 times slower.  On the other hand, saving too 
infrequently means that if the node goes down more work will be lost.  
Unfortunately there is no hard and fast rule regarding how often to checkpoint, 
it comes down to deciding what the right balance is between the overhead of 
checkpointing and the risk of badput for each application.


## When to checkpoint

If a program iterates over some set then a natural approach is to checkpoint 
after some fraction of the iterations have been completed, as in the example.

Similarly, if a program is iterating until some condition is met then one 
possible approach is to add a counter and checkpoint based on that.  For example 
if there is a top-level `while` loop

```python

while not analysis_finished:
    ...
```

then checkpointing could be added as

```python

count = 0

while not analysis_finished:
    count += 1
    
    if count % 100 == 0:
	# do checkpointing here
```

These approaches work well if each iteration takes about the same amount of 
time, checkpointing will then happen at regular intervals.  If some iterations 
may take much longer than others, or more generally if losing computational time 
is more of a concern than losing a number of iterations, then checkpointing can 
be time based.  For example, to checkpoint every 100 seconds 

```python

import time
start_time = int(time.time())

...

current_time = int(time.time())

if (current_time - start_time) % 100 == 0:
    # Checkpoint

```

None of these solutions is inherently better or worse than the others, choosing 
a method is in part a decision based on the nature of the program and in part 
personal preference.


## What counts as program "state"?

As a general rule programs will need preserve all information that they require 
to resume, as in the sum example which had to save both the counter and the 
total so far.  Often this will mean the value of all variables and data 
structures.  When there are many of these saving them all individually may be 
inconvenient, and writing them all out as strings may require additional 
formatting and parsing code.

Much of this can be simplified using the Python 
[Pickle](https://docs.python.org/3/library/pickle.html) library, which can dump 
most Python data types to a file.  In combination with a custom class this can 
greatly simplify checkpointing.


```python
#!/usr/bin/env python

import pickle
from pathlib import Path

class State:
    def __init__(self):
        self.counter = 0
        self.total   = 0
	
	# Other state variables...

checkpoint = Path("checkpoint")
if checkpoint.is_file():
    with checkpoint.open('rb') as f_in:
        state = pickle.load(f_in)
else:
    state = State()

# start doing work...
# ...
# Save a new checkpoint

checkpoint = Path("checkpoint")
with checkpoint.open('wb') as f_out:
    pickle.dump(state, f_out)

```

## Additional considerations for multi-threaded applications

Using multiple threads or processes can greatly speed up programs by 
distributing the work over multiple CPUs, and the Python 
[Mulitiprocessing](https://docs.python.org/3/library/multiprocessing.html) and 
[Threading](https://docs.python.org/3/library/threading.html) libraries make it 
easy to utilize this kind of parallelism.  However, some care must be taken to 
ensure that checkpoints are *consistent*, meaning they must represent a program 
state that "makes sense" in the context of what the program is doing.  If one 
thread is creating a checkpoint while another thread is changing data that is 
being written then the resulting checkpoint may be broken.  Returning to the sum 
example, it's conceivable that the checkpoint might save the state while `i=20` 
but `total` has already been modified to include terms up to `i=25`.

This is an example of a much more general problem of keeping shared data 
consistent across multiple threads, which in general can be very difficult and 
is beyond the scope of this document.  For now just note that this is something 
to be aware of.


## Checkpointing in large applications

So far this document has focused on modifying code developed at SU, however 
OrangeGrid is also used to run large, sophisticated open source programs 
developed elsewhere.  In general applications that are meant to be run on a 
cluster will be able to do some form of checkpointing, this should appear in the 
application's documentation.  As two examples:

  * [Checkpointing in Gromacs](https://manual.gromacs.org/current/user-guide/managing-simulations.html)
  * [Checkpointing in LAMMPS](https://docs.lammps.org/restart.html) with the "restart" command


## The best way to do checkpointing...

... is not to need it!  Recall that this discussion started with the observation 
that checkpointing probably isn't needed if a program is only going to run for 
15 minutes or so.  If a program is going to run for 10 hours it is better, when 
possible, to split it into 60 programs that each run for 10 minutes.  Not only 
does this eliminate the need for checkpointing, but obviously the total time to 
run is much less.  This also plays to the core strength of HTCondor and "high 
throughput" computing in general.

Look for an additional document in the this repository describing techniques for 
taking advantage of this kind of parallelism, to be added shortly.

---
Please email any questions or comments about this document to Research Computing at [researchcomputing@syr.edu](mailto:researchcomputing@syr.edu).

