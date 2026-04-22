# JSON and general objects

Some data isn't as free form as text files but have more complex structure than
arrays of floats (as in [HDF5](hdf5.md)) or even the tables covered in the
[sqlite introduction](sqlite.md).  Such data can often be represented as
[json](https://en.wikipedia.org/wiki/JSON), although other representations are also 
used.

As an example, the history of jobs run from an HTCondor submit node can be retrieved
with the `condor_history` command which takes an optional `--json` argument which formats the 
results in json.  A greatly stripped-down result might look like this

```json
[
{
  "User": "jdoe@its-condor-submit.syr.edu",
  "ToE": {
    "ExitCode": 1,
    "When": 1771426163,
  },
  "AllocatedCPUs": [0,1,4,5], 
  "QDate": 1771011291
}
,
{
  "User": "jsmith@its-condor-submit.syr.edu",
  "ToE": {
    "ExitCode": 4,
    "When": 1771426379,
  },
  "AllocatedCPUs": [15,22], 
  "QDate": 1771010021
}
]
```


QDate is the time that the job was submitted, represented as seconds since
January 1, 1970 12:00:00 AM (also called the [epoch
time](https://www.epochconverter.com/).  ToE is Time of Exit, the When field
is that time in the same format and ExitCode 4 indicates success.  AllocatedCPUs isn't 
a real field, but is included here as an example of array data.


## Working with JSON data in files

The obvious solution is to store one json document per file, and in some cases
that may be the right approach, but it can quickly run into the usual problems
with number of files or size of storage.  This can be alleviated by storing the
json documents within [zip files](zipfiles.md).

The catch here is that working with these files is likely to be slow due to
lack of indices, as discussed in the [sqlite](sqlite.md) page.  For example, to
find all jobs run by jdoe code would need to scan through the zip file, opening
and parsing each json file, to see which ones meet the requirements.  It is
certainly possible for users to create their own indices stored in separate
files, although this is likely to take some effort.  One possibility for this
case is to use [dbm files](https://en.wikipedia.org/wiki/DBM_(computing)), a file
format that efficiently stores key/value pairs, to hold each index.  With this
approach adding a new entry to a json archive would look like:

```python
import json
import dbm
import sys

zipName = sys.argv[1]
newFile = sys.argv[2]

with open(newFile,'w') as json_file:
    json_text = ''.join([line for line in json_file])
    json_data = json.load(json_text)
    user      = json_data['User']

with ZipFile('all_results.zip','a') as myzip:
    myzip.write(newFile,json_text)
    
    with myzip.open('user_index.dbm','a') as dbmfile:
        if user not in dbmfile:
            dbmfile[user] = ''
        dbmfile[user] = ','.join(dbmfile[user].split(',') + [newFile])
```

## Working with JSON data as sqlite columns

sqlite can store text data of arbitrary length which certainly includes json
formatted text.  However sqlite can go even further, parsing the json data in
select statements.  If a table has been created as

```sql
CREATE TABLE json_data(contents TEXT);
```

and the above data has been loaded into this table than data can be
selected with expressions like

```sql
SELECT json_extract(contents, '$.User') FROM json_data;

SELECT json_extract(contents, '$.ToE.When') FROM json_data;

SELECT json_extract(contents, '$.AssignedCPUs[2]') FROM json_data;

SELECT json_extract(contents, '$.User') FROM json_data;
  WHERE json_extract(contents, '$.QDate') > 1771426163;
```


## Working with JSON data as sqlite tables

Finally, the most efficient way of using json data is to map the structure of the
documents to sqlite tables.  For the current examples these tables would look like

```sql
CREATE TABLE dot (
  dotId           INTEGER,
  User            VARCHAR(100),
  ToEId           INTEGER,
  AllocatedCPUsID INTEGER,
  QDate           INTEGER
)

CREATE TABLE ToE (
  ToEId    INTEGER,
  ExitCode INTEGER,
  When     INTEGER
)

CREATE TABLE AllocatedCPUs (
  AllocatedCPUsId INTEGER,
  arrayIndex      INTEGER,
  value           INTEGER
)
```

The dot table would contain

```
1,"jdoe@its-condor-submit.syr.edu",1,1,1771011291
1,"jsmith@its-condor-submit.syr.edu",2,2,1771426379
```

the ToE table
```
1,4,1771426163
2,4,1771010021
```
the AllocatedCPUs table

```
1,1,0
1,2,1
1,3,4
1,4,5
2,1,15
2,2,22
```

This allows for efficient searching, especially if indices are used, but at the cost 
of needing potentially complex queries and the need to write code that converts between
the json and table representations.


