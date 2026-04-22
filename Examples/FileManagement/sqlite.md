# SQLite

Research data often fits into a pattern that might broadly be called "records".  For
example, someone studying trends in publishing might have records for each published 
author giving their first and last names and date of birth, the name of the journal,
and the year and month of publication.

Such data very naturally lends itself to storage in a [relational
database](https://en.wikipedia.org/wiki/Relational_database).  Traditionally
database run as separate processes and any program that needs to read or write
data connects to it over the network.  [SQLite](https://sqlite.org/) provides
all the power and flexibility of a database via a library that can be embedded
directly into programs, with the database itself stored as a local file.  SQLite 
is available for many languages:

  * [Python](https://docs.python.org/3/library/sqlite3.html), where it is built
    into the language.
  * [R](https://cran.r-project.org/web/packages/RSQLite/vignettes/RSQLite.html)
  * [Julia](https://juliadatabases.org/SQLite.jl/stable/)
  * [Octave](https://gnu-octave.github.io/octave-sqlite/manual/)

and even

  * [Haskell](https://hackage.haskell.org/package/sqlite-simple)

## Using SQLite from the command line

SQLite comes with a command line utility for interacting with databases.  On
many systems this will be installed by default and can be accessed with the
`sqlite3` command.  If it is not installed users can install it in their home 
directories through conda.  See the documentation for [using Python on OrangeGrid](../python)
for notes on installing conda, then sqlite can be installed with

```bash
conda install conda-forge::sqlite
```

Once installed it can be used to create databases, create *tables* which are
the structures that store records, and issue *queries* in [SQL (structured
query language)](https://en.wikipedia.org/wiki/SQL) to retrieve data. 

Designing a database and using SQL (which, as the name implies, is an entire
programming language in itself!) are complex topics about which entire books 
have been written.  This document can only begin to scratch the surface, but it 
should be enough to get started.

To get started, the `sqlite` command can create a database or access an existing 
one by specifying the file where the database is stored.

```bash
sqlite3 publications.db
```

The prompt then changes to `sqlite>` and commands an be entered interactively.  To create
a table for the publication data:

```sql`
CREATE TABLE publications (
  first_name   TEXT,
  last_name    TEXT,
  birth_year   INT,
  journal_name TEXT,
  pub_month    INT,
  pub_year     INT);
```

It is traditional, though not required, that SQL keywords are in upper case.
Commands can span several lines and must end with a semicolon.  In most
relational databases the types (INT, FLOAT, etc) are mandatory and it's
important to use the right ones, however SQLite is [dynamically
typed](https://www.sqlite.org/datatype3.html) so these can be omitted entirely,
but it's a good idea to use them to provide some contextual information to
anyone who may be using the database in the future.

Once created data can be put into the database with the `INSERT` statement

```sql
INSERT INTO publications VALUES('Jane','Doe',1990,'Phys. Rev. D',12,2023);
```

Data is retrieved with the `SELECT` statement which can take several forms

```sql
sqlite> select * from publications;
Jane|Doe|1990|Phys. Rev. D|12|2023

sqlite> select pub_year from publications;
2023

sqlite> select first_name, last_name from publications;
Jane|Doe
```

The first form selects every *field* from the table, the next two select only specific fields.

## Database structure

The table as designed will work but it is fairly redundant.  A researcher will have many 
publications, it shouldn't be necessary to repeat their birth year or even their name for 
each one.  Likewise each journal will have publications from many authors, it shouldn't be
necessary to type out the full journal name each time.  Keeping everything in one table not
only makes everything more verbose, but, especially relevant to this document, it makes
the database files unnecessarily large.

To correct this the database can be *rationalized*, split into several tables with unique
IDs to connect them up:

```sql
CREATE TABLE authors (
  author_id    INTEGER PRIMARY KEY,
  first_name   TEXT,
  last_name    TEXT,
  birth_year   INTEGER
);

CREATE TABLE journals (
  journal_id   INTEGER PRIMARY KEY,
  journal_name TEXT
);

CREATE TABLE publications (
  author_id    INTEGER,
  journal_id   INTEGER,
  pub_month    INTEGER,
  pub_year     INTEGER,
  FOREIGN KEY(author_id)  REFERENCES authors(author_id),
  FOREIGN KEY(journal_id) REFERENCES journals(journal_id)
);
```

The `PRIMARY KEY` flag causes SQLite to treat these fields specially.  Users
will not provide data to these fields directly, instead SQLite will
automatically fill in the value, ensuring that each record has a unique value.
This means that in all subsequent operations this id can stand in for the full
record.  The `FOREIGN KEY` flag causes SQLite to ensure that the database has
*referential integrity*, making it impossible to create a publication record
for an author or journal that does not exist.  

Inserting data works similarly to the previous example, except that the
fields must be named so SQLite knows that we're not trying to set the primary 
key values

```
INSERT INTO authors(first_name,last_name,birth_year)
VALUES('Jane','Doe',1995);

INSERT INTO journals(journal_name)
VALUES('Phys. Rev. D');
```

Before adding the publication it's now necessary to check the IDS that SQLite
assigned to the primary keys

```sql
sqlite> SELECT * FROM authors;
1|Jane|Doe|1995

sqlite> SELECT * FROM journals;
1|Phys. Rev. D
```

Unsurprisingly, SQLite used 1 for the first entries in these tables, but that
behavior shouldn't be assumed.  The publication record can now be added

```sql
INSERT INTO publications(author_id, journal_id, pub_month, pub_year)
VALUES(1,1,12,2020);
```

Now to retrieve data we need to construct a query involving all three tables,
indicating the relationships between the various fields:

```sql
SELECT journals.journal_name, authors.last_name, publications.pub_year
  FROM journals, authors, publications
  WHERE publications.author_id  = authors.author_id
   AND publications.journal_id  = journals.journal_id;
```

This is clearly more complex than the simple initial version with a single
table, but the resulting database will be far smaller on disk.  As always, each
researcher needs to choose which trade offs to make for their own workflows.


## Speeding up data access with indices 

Consider a query to find all authors whose last name is Doe:

```sql
SELECT * FROM authors WHERE last_name = "Doe";
```

By default this will need to search through every record in the database and
check the last name field.  Of course any one check will take a fraction of a
second, but as the database grows this can mount up to make queries painfully
slow, and this problem compounds significantly when doing complex queries
across multiple tables with multiple join conditions.

SQL database solve this problem with `indicies`, very efficient data structures
that essentially "pre compute" a search or component of a search.  In sqlite
an index is created as

```sql
CREATE INDEX authors_last_name
ON authors(last_name);
```

It is a convention, although not mandatory, to name the index with the table
name, and underscore, and then the column name.

With this index in place the query now no longer needs to search through 
every row, instead it just looks up "Doe" in the index and can immediately
return all the appropriate rows.

Using indices does make writing new data somewhat slower, as the index data
structures need to be updated.  However in most cases, the benefits gained
when reading data are worth it.


## Calling SQLite from Python

The interface to SQLite is fairly "light" in that the same SQL commands are used.
The typical pattern is that first a connection to the database is opened, then
a *cursor* is allocated that provides the direct interface between SQL commands
and Python.  To create and insert data:


```python
import sqlite3

with connection = sqlite3.connect("publications.db") as conn:
    cursor = conn.cursor()

    cursor.execute("""
CREATE TABLE publications (
  first_name   TEXT,
  last_name    TEXT,
  birth_year   INT,
  journal_name TEXT,
  pub_month    INT,
  pub_year     INT);""")

    cursor.execute("""
INSERT INTO publications VALUES('Jane','Doe',1990,'Phys. Rev. D',12,2023);
""")

```

When retrieving data, after issuing the `SELECT` command the cursor 
contains the results

```python
cursor.execute("SELECT * FROM publications");
rows = cursor.fetchall()

for row in rows:
    print(row)
```

The results are returned as a tuple, so the output would be

```
('Jane','Doe',1990,'Phys. Rev. D',12,2023);
```



