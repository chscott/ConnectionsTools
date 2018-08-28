## installDocker

The installDocker tool installs Docker CE 17.03 to support Component Pack 6.0.0.6.

### Syntax

```Shell
$ sudo installDocker.sh [OPTIONS]
```

### Options

* --check

    Checks the system to see if meets the requirement to install Component Pack components.
    
* --force-rhel-install

    RHEL is not officially supported with Docker CE. Use this option to install anyway.
    
* --force-aufs

    Overrides the check for best storage driver and forces the use of aufs.
    
* --force-devicemapper

    Overrides the check for best storage driver and forces the use of devicemapper.
    
* --direct-lvm-device <block device>

    Provides a block device to use for configuring devicemapper in direct-lvm mode.
    Include with --check to see if the system supports devicemapper with direct-lvm.

### Examples

Get a list of all CFC v1 ports that are currently in use:

```Shell
$ sudo checkCFCPorts.sh
The following ports must be available but are already in use:
80
179
443
...
```

Get a list of all CFC v2 ports that are currently in use:

```Shell
$ sudo checkCFCPorts.sh --v2
The following ports must be available but are already in use:
80
179
443
...
```