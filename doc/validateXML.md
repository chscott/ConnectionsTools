## validateXML

The validateXML tool allows you to validate Connections XML configuration files against their XML Schema Definition (XSD)
files without needing to use wsadmin to check out and check in the file.

### Dependencies

The following dependencies are required for Windows. These executables/libraries must exist on the system path.

- [libxml](ftp://ftp.zlatkovic.com/libxml/64bit/libxml2-2.9.3-win32-x86_64.7z)
- [iconv](ftp://ftp.zlatkovic.com/libxml/64bit/iconv-1.14-win32-x86_64.7z)
- [zlib](ftp://ftp.zlatkovic.com/libxml/64bit/zlib-1.2.8-win32-x86_64.7z)

### Syntax

### Linux

```Shell
$ sudo validateXML.sh xml_file
```

#### Windows

```Shell
> validateXML.ps1 xml_file
```

### Options

None.

### Example 1: A valid Connections XML file

```Shell
$ sudo validateXML.sh LotusConnections-config.xml
LotusConnections-config.xml validates
```

### Example 2: An invalid Connections XML file

```Shell
$ sudo validateXML.sh LotusConnections-config.xml
LotusConnections-config.xml:468: parser error : Opening and ending tag mismatch: properties line 444 and config
</config>
         ^
LotusConnections-config.xml:469: parser error : Premature end of data in tag config line 1
```