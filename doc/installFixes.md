## installFixes

The installFixes tool makes it easy to apply iFixes to your Connections Blue environment. Download the iFixes to your
Deployment Manager node's fixes directory and specify which you'd like to apply.

### Syntax

#### Linux
```
$ sudo installFixes.sh fix1 [fix2] [fixN] ...
```

#### Windows
```
> installFixes.ps1 fix1 [fix2] [fixN] ...
```

### Options

None.

### Example

This example first uses the [getAvailableFixes](getAvailableFixes.md) tool to identify fixes available to install and then
uses installFixes to perform the installation.

```
$ sudo getAvailableFixes.sh
Getting a list of Connections fixes available to install...
Fixes available to install: LO93624

$ sudo installFixes.sh LO93624
Installing Connections fixes...                              SUCCESS
```