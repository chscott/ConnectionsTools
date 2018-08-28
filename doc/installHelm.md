## installHelm

The installHelm tool installs Helm 2.9.1 to support Component Pack 6.0.0.6. Both the Helm client and server (aka tiller) are
installed.

### Syntax

```Shell
$ sudo installHelm.sh [OPTIONS]
```

### Options

* --check

    Checks the system to see if meets the requirement to install Component Pack components.

### Examples

Check to see if the current system meets the requirements to install Component Pack 6.0.0.6.

```Shell
$ sudo installHelm.sh --check

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
```

Install the Helm client and server components.

```Shell
$ sudo installHelm.sh
```