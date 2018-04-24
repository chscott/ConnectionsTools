## jarscan

The jarscan tool searches JAR files for the supplied text. This is helpful when you want to locate the JAR files that use a
particular string.

### Syntax

```Bash
$ sudo jarscan.sh STRING
```

### Options

None.

### Example

In the first example, a simple, one-word search term is used. We can see that the string 'CLFRW1124I' appears only once, in
a file named search.common.jar inside the Search application.

```Bash
$ sudo jarscan.sh CLFRW1124I
Searching JARs in /var/IBM/websphere/was/profiles/ic1 for 'CLFRW1124I'...
./installedApps/icCell/Search.ear/search.common.jar
```

In the second example, a phrase is used. Note that this must be enclosed in quotation marks to preserve the entire string to
search.

```Bash
$ sudo jarscan.sh "Search is starting to build the index"
Searching JARs in /var/IBM/websphere/was/profiles/ic1 for 'Search is starting to build the index'...
./installedApps/icCell/Search.ear/search.common.jar
```