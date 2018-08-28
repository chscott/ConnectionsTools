## uninstallKubernetes

The uninstallKubernetes tool uninstalls Kubernetes packages and (optionally) the configuration and data directories.

### Syntax

```Shell
$ sudo uninstallKubernetes.sh [OPTIONS]
```

### Options

* --clean

    In addition to uninstalling Kubernets packages, delete the Kubernetes configuration and data directories. Use this option 
    with care, as data will be permanently deleted.
    
### Examples

Uninstall Kubernetes packages but leave the configuration and data directories.

```Shell
$ sudo uninstallKubernetes.sh
```

Uninstall Kubernetes packages and delete the configuration and data directories.

```Shell
$ sudo uninstallKubernetes.sh --clean

WARNING! The --clean option will remove all Kubernetes directories.
All configuration and data will be deleted!

If you are certain you want to do this, enter 'yes' and press Enter:

```