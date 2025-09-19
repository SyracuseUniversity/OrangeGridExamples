# Utilizing parallelism on OrangeGrid

HTcondor is a "high throughput" scheduler, meaning its strength is in running 
lots of relatively small jobs simultaneously, in parallel.  Sometimes research 
naturally fits into this pattern, such as a study that explores 100 different 
sets of parameters and can run each set independently.  In other cases the 
problem may not divide up as simply, but even then there are general techniques 
that can be used to split a single large or slow program into smaller parts.

A common issue that arises when considering how to split up such a program is 
how data should be managed.  If a program utilizes global data structures that 
can change during the program's run then data management becomes much more 
difficult since different parts or steps of the code must be aware of each other 
and somehow coordinate their access to these structures.  This document 
therefore focuses on techniques adapted from
[functional programming](https://en.wikipedia.org/wiki/Functional_programming) 

While a full discussion of this topic is outside the current scope, readers may 
wish to familiarize themselves with some of the ideas for application in their 
own work, even when not using a purely functional language or style.  Here we 
will focus on two very general and powerful techniques *map* and *reduce*.


## Map: changing data

To start, consider the simple problem of squaring every value in an array of 
integers.  In Python this might naively be done as

```python

initial_array = [1,2,6,12,18]
new_array = []

for value in initial_array:
    new_array.append(value * value)
```

This represents a standard programming construct, iterating over some collection 
of values and doing something with each.  This can be written more compactly and 
more in keeping with the "Python style" by using a *list comprehension*.

```python

initial_array = [1,2,6,12,18]
new_array = [v * v for v in initial_array]
```

In this case the list comprehension is equivalent to using Python's 
[map](https://docs.python.org/3.13/library/functions.html#map) function.  Map 
applies a function to every element of an array.  In order to do that the first 
argument to map is itself a function.  For some readers the idea of passing a 
function to another function may seem weird, but in Python a function is just a 
"thing" like any other "thing" such as an integer or string.  A function can 
take a function as an argument or return a new function, just as a function can 
take a string as an argument or return a new string.  This ability to treat 
functions as *first-class objects* is a key insight from functional programming.  
The code written using map looks like this:

```python

def square(v):
    return v*v
    
initial_array = [1,2,6,12,18]
new_array = map(square, initial_array)
```

There is still one difference between functions and other types here.  Generally 
it is not necessary to give something a variable name before using it.  The 
first array could be totally eliminated by writing it as

```python

def square(v):
    return v*v
    
new_array = map(square, [1,2,6,12,18])
```

So if functions are treated the same as anything else it should be possible to 
create one without giving it a name.  This is done through the *lambda* keyword
(the name comes from [lambda 
calculus](https://en.wikipedia.org/wiki/Lambda_calculus) , a mathematical 
formulation of functional programming.

```python
    
new_array = map(lambda v: v*v, [1,2,6,12,18])
```

This is about as far as we'll go into functional programming!

The key thing to notice here is that every element of `new_array` is calculated 
independently.  So rather than doing the first, then the second, and so on why 
not do them all at once, in parallel.  Even before bringing in HTCondor the work 
can be split among several CPUs.  In Python the built-in 
[multiprocessing](https://docs.python.org/3.13/library/multiprocessing.html#module-multiprocessing) 
module makes this easy.

```python
from multiprocessing import Pool

number_of_cpus = 5

with Pool(number_of_cpus) as p:
     new_array = p.map(lambda v: v*v, [1,2,6,12,18])
```

Just replace `map` with `Pool.map`.  In a situation where the function is very 
slow this can enable the program to run in almost one fifth of the time!  

To run a program like this under HTCondor it is also necessary to tell the 
system how many CPUs the program will need.  This is done with the 
`request_cpus` option in the submit file.

```
executable = squares.py

request_cpus = 5

queue
```


### Multiple arguments

In this example the square function only needs one value, but what if the 
problem requires multiplying the values in two arrays?

```python

array1 = [2,3,4,5]
array2 = [5,6,7,8]
result = []

for i in range(len(array1)):
    result.append(array1[i] * array2[i])
```

As the saying goes, when all you have is a hammer everything looks like a nail.  
If all you have is a way of dealing with functions that take only one argument, 
then make all your data look like a single value!  In this case two lists can be 
transformed into one list of two values with the zip function

```python

print(list(zip(array1, array2)))

[(2,5), (3,6), (4,7), (5,8)]
```

This can now be used in `map`:


```python

from multiprocessing import Pool

def multiply(values):
    v1, v2 = values
    return v1*v2

array1 = [2,3,4,5]
array2 = [5,6,7,8]

number_of_cpus = 5

with Pool(number_of_cpus) as p:
     result = p.map(multiply, list(zip(array1, array2)))
```

Or more compactly using a lambda expression

```
     result = p.map(lambda v: v[0]*v[1], list(zip(array1, array2)))
```


### Mapping over values with HTCondor

Although HTCondor doesn't exactly have a map function it does provide some 
powerful mechanisms in the `queue` command which can be thought of as doing the 
same thing.  To start with, in moving from a single program to an HTCondor batch 
of programs, functions get replaced by programs.  Arguments to the function 
become command-line arguments, and instead of returning a value the result is 
printed.

```python

def multiply(values):
    v1, v2 = values
    return v1*v2

```

Becomes

```python

# multiply.py
import sys

v1 = int(sys.argv[1])
v2 = int(sys.argv[2])

print(v1 * v2)
```


The set of arguments gets stored in an auxiliary file, in this case called 
`values.dat` containing the zipped pairs

```
2 5
3 6
4 7
5 8
```

Then the submit file ties everything together and does the mapping

```
executable = multiply.py
arguments  = $(arg1) $(arg2)

output     = result_$(Process).dat
error      = multiply_$(Process).err
log        = multiply_$(Process).log

queue arg1, arg2 from values.dat
```

The `Process` variable is handled by HTCondor, it is automatically set to 0 for 
the first job, 1 for the second and so on.  Note that here the `request_cpus` 
line isn't necessary.  Each instance of `multiply.py` uses only one CPU, the 
parallelisation is managed by HTCondor running one of these instances for each 
line in `values.dat`.  When the batch completes the results will be scattered 
across files called `result_1.dat`, `result_2.dat` etc.  It is possible to have 
HTCondor combine all the results into one file after all the jobs have run, that 
will be discussed in a section below on HTCondor *Dagman*.


# Reduce: Combining a set of values into one result

Coming soon!


