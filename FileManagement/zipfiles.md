# Zip Files


Sometimes data doesn't fit into any particular structure.  For example, if research involves
using [Ollama](../Ollama/) to compare different models or the results of different prompts each
instance may be a separate job that results in a separate text file.  It may still be useful to 
combine the full result set into a single file and compress it for ease of cataloging, transfer, etc.

[Zip files](https://en.wikipedia.org/wiki/ZIP_(file_format)) are a long established method 
of batching several files together, and most likely everyone reading this has encountered them
at some point.  Combining and compressing all the files from a `data` directory into a file named
`results.dat` is done with:

```bash
zip -r results.zip data
```

If `results.zip` already exists then this command will add or replace the contents 
of the `data` directory.  This suggests a workflow where each run is identified by 
a date, and at the end of each run the results are added to a cumulative zip file,
then deleted.

```bash
# On Jan 1, 2026
condor_submit experiments.sub
# After jobs run
zip -r all_results.zip results20260101 
rm -r results20260101 

# On Jan 2, 2026
condor_submit experiments.sub
# After jobs run
zip -r all_results.zip results20260102 
rm -r results20260102
```

For providence information it's possible to include files describing each directory,
or even the entire codebase used for that day's experiments.

The catch with storing potentially large amounts of data in a single file is
that unzipping the whole file may result in significant disk use as well as a
huge number of files, both of which can cause problems for the file system.

It's possible to use `unzip` to extract just a single file

```bash
unzip all_results.zip results20260102/test5.txt 
```

but this can be unwieldy when statistics covering the whole result set
are needed.


## Programmatically accessing zip files

Python has a built-in library,
[zipfile](https://docs.python.org/3/library/zipfile.html), for accessing the
data in zip files without uncompressing them to disk.  Unfortunately this
capability does not seem to be available in every other language:

  * [R](https://www.rdocumentation.org/packages/zip/versions/2.3.3) and [Octave](https://octave.sourceforge.io/octave/function/zip.html)
    have libraries for working with zip files, but they only allow extraction to disk.
  * [Julia](https://github.com/JuliaIO/ZipArchives.jl) has a library with full functionality.

For Python, reading the contents of a file within a zip archive looks very much
like reading any other file, except the operations take place in the context of
the zip file:

```python
with ZipFile('all_results.zip') as myzip:
    with myzip.open('results20260102/test5.txt') as myfile:
        print(myfile.read())
```

The following example walks through every file in the archive and counts the total
number of words:

```python
total = 0 
with ZipFile('all_results.zip') as myzip:
  for name in myzip.namelist():
    with myzip.open(name) as myfile:
      for line in myfile:
        total += len([word for word in line.split(' ')])

print(total)
```


    

the output
of an LLM at different stages of training or from different prompts.  

  See the documentation
    for the Python interface [here](https://docs.python.org/3/library/zipfile.html).
