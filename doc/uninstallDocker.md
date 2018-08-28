## uninstallDocker

The uninstallDocker tool uninstalls all Docker packages found on the system. This includes obsolete Docker packages and
(optionally) Docker configuration and data.

### Syntax

```Shell
$ sudo uninstallDocker.sh [OPTIONS]
```

### Options

* --clean

    In addition to uninstalling Docker packages, delete the Docker configuration and data directories. Use this option with
    care, as data will be permanently deleted.
    
### Examples

Uninstall Docker packages but leave the configuration and data directories.

```Shell
$ sudo uninstallDocker.sh
```

Uninstall Docker packages and delete the configuration and data directories.

```Shell
$ sudo uninstallDocker.sh --clean

WARNING! The --clean option will remove all Docker directories.
All configuration, images and containers will be deleted!

If you are certain you want to do this, enter 'yes' and press Enter:
```