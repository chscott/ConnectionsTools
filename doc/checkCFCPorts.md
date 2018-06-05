## checkCFCPorts

The checkCFCPorts tool allows you to check to see if any CFC ports are in use before attempting to install CFC. The tool
checks all required ports and port ranges and reports if any ports are in use. Using this tool before installing CFC gives
you an opportunity to fix any issues before they cause errors during installation.

### Syntax

```Bash
$ sudo checkCFCPorts.sh [--v1 | --v2]
```

### Options

When specified, the **--v1** and **--v2** options check the indicated versions of CFC, which have differing port 
requirements. The default is --v1, which is the same as specifying no options.

### Examples

Get a list of all CFC v1 ports that are currently in use:

```Bash
$ sudo checkCFCPorts.sh
The following ports must be available but are already in use:
80
179
443
...
```

Get a list of all CFC v2 ports that are currently in use:

```Bash
$ sudo checkCFCPorts.sh --v2
The following ports must be available but are already in use:
80
179
443
...
```