## jarscan

The jarscan tool searches JAR files for the supplied text. This is helpful when you want to locate the JAR files that use a
particular string.

### Dependencies

The following dependencies are required for Windows. These executables/libraries must exist on the system path.

- <http://gnuwin32.sourceforge.net/packages/unzip.htm>

### Syntax

#### Linux

```Shell
$ sudo jarscan.sh [DIRECTORY] STRING
```

#### Windows

```Shell
> jarscan.ps1 [DIRECTORY] STRING
```

### Options

If provided, the DIRECTORY option specifies the directory from which the search for JARs begins. If not specified, the
current directory is used.

### Example

In the first example, a simple, one-word search term is used. We can see that the string 'CLFRW1124I' appears only once, in
a file named search.common.jar inside the Search application.

```Shell
$ sudo jarscan.sh CLFRW1124I
Searching JARs in /var/IBM/websphere/was/profiles/ic1 for 'CLFRW1124I'...
./installedApps/icCell/Search.ear/search.common.jar
```

In the second example, a phrase is used. Note that this must be enclosed in quotation marks to preserve the entire string to
search.

```Shell
$ sudo jarscan.sh "Search is starting to build the index"
Searching JARs in /var/IBM/websphere/was/profiles/ic1 for 'Search is starting to build the index'...
./installedApps/icCell/Search.ear/search.common.jar
```