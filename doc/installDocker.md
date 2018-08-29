## installDocker

The installDocker tool installs Docker CE 17.03 to support Component Pack 6.0.0.6 on the following platforms:

* CentOS 7

* RHEL 7

* Fedora 25

* Debian 9

* Ubuntu 16.04

Note that while installDocker supports RHEL 7, Docker CE does not officially support RHEL.

The tool allows you to install four possible storage drivers, depending on the system configuration. Those drivers are, in 
order of selection preference:

* overlay2

* aufs

* devicemapper-direct

* devicemapper-loop

Note that devicemapper-loop is strongly discouraged for production use. However, it may be suitable for a development or
proof-of-concept deployment.

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
    
* --registry-node

    Deploys a local Docker registry on the node. A Docker registry is needed to store Component Pack images on one node in
    the deployment.

### Examples

Check to see if the current system meets the requirements to install Component Pack 6.0.0.6. This example includes the 
--direct-lvm-device option so the specified device can be scanned to see if it meets minimum requirements.

```Shell
$ sudo installDocker.sh --check --direct-lvm-device /dev/sdb

Component Pack 6.0.0.6 requirements:

Requirement             Found                   Requires
-----------             -----                   --------
Distro:                 centos                  centos, rhel*, fedora, debian or ubuntu
Version:                7.3                     7.x
Machine architecture:   x86_64                  x86_64
Logical cores:          2                       At least 2
Available memory:       2875500                 At least 2097152
Total swap:             0                       Must be 0

Supported for Component Pack: Yes

Storage driver          Available
--------------          ---------
overlay2                Yes
aufs                    No
devicemapper-direct     Yes
devicemapper-loop       Yes
```

Install Docker with the most preferred storage driver available on the current system.

```Shell
$ sudo installDocker.sh
```

Install Docker with the devicemapper-direct storage driver. Note that the specified device must be an unusued block device.
If you are installing on a virtual machine, this is as simple as adding a new hard disk to the VM configuration. You can also
use an empty partition.

```Shell
$ sudo installDocker.sh --force-devicemapper --direct-lvm-device /dev/sdb
```

Install Docker and deploy a local image registry.

Install Docker with the most preferred storage driver available on the current system.

```Shell
$ sudo installDocker.sh --registry-node
```