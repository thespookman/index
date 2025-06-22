# NAME

index --- creates an index of keys and tokens, storing for each
key/token pair the number of times that token is associated with the
key. Keys may be searched by providing a list of tokens, to determine
the most closely matching key.

# SYNOPSIS

**index** ( **-h**\

\| **-f**\<file\> \[ **-v** \] **-c**\

\| **-f**\<file\> \[( **-v** \| **-w**\<num\> \| **-W**\<num\> )\...\]\

( **-k**\<key\> \| **-K**\<file\> ) (( **-t**\<file\> \| **-T**\<file\>
)\...) **-i**\

\| **-f**\<file\> \[( **-v** \| **-w**\<num\> \| **-W**\<num\> )\...\]
**-l**\

\| **-f**\<file\> \[( **-v** \| **-w**\<num\> \| **-W**\<num\> )\...\]
**-m**\

\| **-f**\<file\> \[( **-v** \| **-w**\<num\> \| **-W**\<num\> )\...\]\

( **-k**\<key\> \| **-K**\<file\> ) **-r**\

\| **-f**\<file\> \[( **-C**\<num\> \| **-v** \| **-w**\<num\> \|
**-W**\<num\> )\...\]\

(( **-t**\<file\> \| **-T**\<file\> )\...) **-s**\

) \...

# OPTIONS

**index**\'s options are either operations (See **OPERATIONS**) or
modifiers. The synopsis above shows which modifiers are used by each
operation, as well as whether they are mandatory.

Multiple operations may be specified in the same command, in which case
they are ran sequentially. If a modifier is required for a given
operation, it may occur anywhere in the command before the operation in
question, even if another operation occurs in between.

Modifiers that are ignored by the operation listed have been ommitted
from the synopsis for brevity, but will not cause an error, and may be
read by subsequent operations.

In any case where a file is required, the filepath may be subtituted
by - to read from stdin.

## OPERATIONS

**-c**

:   Create. Creates an index file.

**-h**

:   Help. Displays usage information.

**-i**

:   Index. Stores the count of each provided token against the provided
    key in the provided index file.

**-l**

:   List. Write every key contained in the index file to stdout,
    separated by new lines.

**-m**

:   reMake. Read the index file and remake it, possibly improving
    compression and query speed.

**-r**

:   Remove. Deletes all information pertaining to the provided key from
    the provided index file.

**-s**

:   Search. Returns the key for which the product of the counts of all
    tokens provided is the highest from the provided index file.

## MODIFIERS

**-f**\<file\>

:   set the index file to be operated on by subsequent operations.

**-k**\<key\>

:   sets the key to be operated on by subsequent operations.

**-K**\<file\>

:   read the key to be operated on by subsequent operations from file.
    N.B. this allows keys containing newlines etc., however such keys
    may cause confusing output from the list and search operations.

**-t**\<file\>

:   read tokens for the next operation from file, one token per line.

**-T**\<file\>

:   read a single token for the next operation from file, the whole file
    is one token.

**-v**

:   Toggle verbose mode (initially off)

**-w**\<num\>

:   sets the interval in seconds at which to recheck the lock, if an
    operation is blocked by a lockfile (default 0.1)

**-W**\<num\>

:   sets the maximum time in seconds to wait if an operation is blocked
    by a lockfile (default 2)

# DESCRIPTION

**index** creates an index of keys and tokens, storing for each
key/token pair the number of times that token is associated with the
key. Keys may be searched by providing a list of tokens, **index** will
return the most relevant key.

Some operations will create a lock file to prevent other instances of
**index** from reading from or writing to the file. These other
instances will retry at an interval, up to a maximum length of time,
controlled by the **-w** and **-W** options.

## INDEX FILE STRUCTURE

The file maintained by **index** begins with the plaintext version
number of **index** used to create the file.

The remainder of the file is gzipped, with each line as follows:

> *token_hash count encoded_key*

where *token_hash* is the md5 hash of a token, *encoded_key* is a base64
encoded key, and *count* is the number of times that token is associated
with the key.

The version number is stored as a precaution, giving later versions of
**index** the option to modify the index file structure, while
maintaining compatibility with previous versions.

## CONSUMPTION OF MODIFIERS

Most modifiers are not \"consumed\" by operations. Even after being used
by one operation, they remain in place for subsequent operations in the
same command.

The exceptions are the **-t** and **-T** modifiers, that provide tokens.
Any tokens will persist through operations, such as create or list, that
do not use tokens, but are \"consumed\" as soon as they are used. In
this way, one command can perform multiple index operations, by updating
the key to be indexed with **-k** or **-K** each time, and providing new
files of tokens for each operation.

# OPERATIONS

The available operations are detailed here, with the exception of Help (
**-h**).

## CREATE

Creates the index, containing no information bar the version number of
**index** used (see **INDEX FILE STRUCTURE**).

## INDEX

Appends the index with one key and associated token counts. All tokens
in the token files provided with the **-t** and **-T** options are
counted and associated with the key (provided by the **-k** or **-K**
options).

The index operation may be used multiple times with the same key, in
which case the new token data will be appended to the token data already
associated with the key (as opposed to overwriting data for the key).
This comes with the following caveats

-   The new data is compressed separately to the rest of the index file.
    This means that the file will likely be bigger than necessary, which
    may negatively affect the speed of the search operation ( **-s**).

-   If any tokens are included in the new data that already existed in
    the old, the token counts will not be summed. Instead, they will be
    recorded as a new token. This will result in the search operation
    being biased towards this key when that token is included in the
    search query.

These issues can be resolved by rebuilding the index with the remake
operation (see **REMAKE**).

## LIST

Lists all unique keys contained within the index, separated by newlines.

## REMAKE

Reads the index file and remakes it. This may improve compression
rations and query speed, if the index operation has been used multiple
times for some keys (see **INDEX**). Remake will also update the version
number included at the top of the index to the current version of
**index** being used. If the new version contains any differences to the
index file structure, the index file will be remade in the new
structure.

The remake operation locks the index file (see **DESCRIPTION).**

## REMOVE

Removes all data pertaining to the provided key from the index file.

The remove operation locks the index file (see **DESCRIPTION).**

## SEARCH

Returns the most closely matching keys to the provided tokens, in
reverse order of closeness. Results are returned separated by newlines.
The number of keys returned is controlled by the **-C** option.

Closeness of match is determined by giving each key in the index a
score, with the higher score being the closer match. Scores are
calculated as follows:

> (*token1_count* + 1) \* (*token2_count* + 1) \* (\...

where *tokenN_count* is the count associated with the pair of the key
and a given token from the search query in the index file.

Thus a key that matches 2 tokens once each has a score of 4, while a key
that matches the same token twice has a score of 3, so the match prefers
keys that match multiple tokens.

# RETURN CODES

**1**

:   Failure due to user\'s invocation of **index.**

**2**

:   Failure due to incorrect file state - files may not exist, be not
    readable or not writable.

**3**

:   Failure due to the index file being locked.

# SEE ALSO

**base64**(1), **gzip**(1), **md5sum**(1)
