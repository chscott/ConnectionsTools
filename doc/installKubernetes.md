## installKubernetes

The installKubernetes tool installs Kubernetes 1.11 to support Component Pack 6.0.0.6. The tool allows you to install
the first master node or a worker node. Note that installing a master node will always create a new cluster. Installing
additional master nodes into an existing cluster is not currently supported.

### Syntax

```Shell
$ sudo installKubernetes.sh [OPTIONS]
```

### Options

* --check

    Checks the system to see if meets the requirement to install Component Pack components.
    
* --master-node

    Designates the new node as the master node for a new Kubernetes cluster.

### Examples

Check to see if the current system meets the requirements to install Component Pack 6.0.0.6.

```Shell
$ sudo installKubernetes.sh --check

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

Install the master node for a new Kubernetes cluster.

```Shell
$ sudo installKubernetes.sh --master-node
```

Install a worker node to join to an existing Kubernetes cluster.

```Shell
$ sudo installKubernetes.sh
```