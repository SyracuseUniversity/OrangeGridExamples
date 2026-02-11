# Introduction

At the risk of stating the obvious, in order for an HTCondor job to be useful
its output must be saved somewhere.  There are many possible options for how
this output gets saved, it could be emailed, it could be written to a AWS
bucket, it could be sent to an external website.  By far the most common option
though, of course, is is to save it to one or more files.  In fact every job
produces standard output and error, both of which would be written to the
screen if run interactively, and HTCondor expects these will be written to
files

```
output = my_job.out
error  = my_job.err
```

Jobs may also write any number of additional files, the names of which might be
hardcoded in the program or provided as a command line argument.

```python
import sys

print("This will be written to standard out")
print("This will be written to standard error", file=sys.stderr)

outname = len(sys.argv) > 1 and sys.argv[1] or "default.out"

with open(outname,"w") as f_out:
    print("This will be written to the named file",file=f_out)
```

None of this is inherently a problem.  However, files don't exist in a vacuum.
Files are managed by a [file system](https://en.wikipedia.org/wiki/File_system)
which manages permissions, grouping files into directories, and other
attributes.  Like everything in computing, file systems have various
limitations.  Space is the most obvious one, probably most people have had the
experience of filling up a disk on their personal computers or a directory on
the cluster.  However there are other finite resources that users are typically
unaware of that can be depleted.  In addition even before a resource has been
exhausted large numbers of files can cause issues.  It will be essentially
impossible to search through or even run `ls` on a directory with millions of
files.

It is therefore a good idea for researchers to have a data management plan.
For many that plan will continue to be simple files stored in their home
directories, and that will be perfectly OK.  However, for anyone whose work may
entail thousands of files, or more, some other technique may be better suited.  This 
document will present a few such options but of course can not cover every possible 
use case.  We are always available to assist in crafting a data management plan 
suited for particular workflows, just email [Research Computing](mailto:researchcomputing@syr.edu)
to set up a meeting.

As a broad outline data may fall into any of four categories and each has 
a container format that is well suited to it:

  * For data consisting of large arrays, possibly multi-dimensional, where every
    entry is the same type (int, float, double etc) use [HDF5](hdf5.md)

  * For data consisting of multiple copies of some kind of "records" where a record
    may contain mixed types of data (for example a person's name, year of birth, height 
    represented as a tuple of (string, int, float)) usea [SQLite](sqlite.md).

  * For data that is uniform but may be more complex and nested (sturctures that could be
    represented as JSON) either use multiple tables in SQLite or an object store, options
    are discussed [here](objects.md). 

  * Finally, for results that consist of multiple free-form documents such as a
    collection of LLM outputs with different models or prompts, use [zip
    files](zipfiles.md).  Although many people are used to thinking of zip
    files as just a way of moving multiple files from one place to another,
    they can also be used programatically without much more overhead than
    working directly with the filesystem, and compression and coherence of a
    whole dataset comes for free.


One last side note, even for projects that will produce a relatively small
number of files one of these other approaches may be worth considering.  In
addition to reducing the burden on the file system keeping all output data in a
single container makes it easier to archive and distribute results and add
providence information describing how the data was generated.  In addition some
of these tools, sqlite especially, provides very sophisticated tools for doing
post-processing and analysis of data, essentially for free.

