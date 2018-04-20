## installFixes

The installFixes tool makes it easy to apply iFixes to your Connections Blue environment. Simply download the iFixes on your
Deployment Manager node's fixes directory and specify which fixes you'd like to apply.

### Syntax

```Bash
$ sudo installFixes.sh fix1 [fix2] [fixN]
```

### Options

None.

### Example

```Bash
$ sudo getAvailableFixes.sh
Getting a list of Connections fixes available to install...
Fixes available to install: LO93624

$ sudo installFixes.sh LO93624
Installing Connections fixes...                              SUCCESS
```