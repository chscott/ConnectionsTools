## uninstallFixes

The uninstallFixes tool makes it easy to uninstall iFixes in your Connections Blue environment. Simply list which 
installed fixes you'd like to remove.

### Syntax

#### Linux

```Shell
$ sudo uninstallFixes.sh fix1 [fix2] [fixN] ...
```

#### Windows

```Shell
> uninstallFixes.ps1 fix1 [fix2] [fixN] ...
```

### Options

None.

### Example

```Shell
$ sudo getInstalledFixes.sh
Installed Connections fixes:
================================================================================
Fix ID:      LO93624
Description: Common: Add missing nls files
Version:     20180207.1553
Date:        02/07/2018
================================================================================

$ sudo uninstallFixes.sh LO93624
Uninstalling Connections fixes...                            SUCCESS
```