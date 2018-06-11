## validateXML

The validateXML tool allows you to validate Connections XML configuration files against their XML Schema Definition (XSD)
files without needing to use wsadmin to check out and check in the file.

### Syntax

### Linux
```
$ sudo validateXML.sh xml_file
```

#### Windows
```
> validateXML.ps1 xml_file
```

### Options

None.

### Example 1: A valid Connections XML file

```
$ sudo validateXML.sh LotusConnections-config.xml
LotusConnections-config.xml validates
```

### Example 2: An invalid Connections XML file

```
$ sudo validateXML.sh LotusConnections-config.xml
LotusConnections-config.xml:468: parser error : Opening and ending tag mismatch: properties line 444 and config
</config>
         ^
LotusConnections-config.xml:469: parser error : Premature end of data in tag config line 1
```