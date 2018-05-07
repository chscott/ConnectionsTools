### Overview

ConnectionsTools is a set of administrative scripts designed to make life easier for Connections administrators. The 
scripts contain both user-friendly wrappers around existing administration tools and new tools that don't already exist in 
the product.

Tools exist for both Connections Blue (WebSphere) and Connections Pink (Kubernetes). You can install the full set of tools on
on every Connections node in the environment without worrying about which ones target Blue and Pink. Each tool understands
its dependencies and will report an appropriate error message if you try to run a tool on a system that doesn't host the
target component.

### System requirements

- Linux. This package is developed and tested on Red Hat Enterprise Linux but should run without issue on any Linux     
  distribution.
  
- Bash shell

- root/sudo access

### Basic installation

1. From your Linux system, download the file.

   ```Bash
   $ curl -s -L -o master.zip https://github.com/chscott/ConnectionsTools/archive/master.zip
   ```
   
2. Unzip the file.

   ```Bash
   $ unzip -qq master.zip
   ```
   
3. Update the file ownership and permissions on the ConnectionsTools-master/etc and ConnectionsTools-master/tools/linux 
   directory files. In this example deployment scenario, we want the files owned by root and a group named icadmins, both of 
   which will have full control. Other users will have no access. Your requirements may vary.
   
   ```Bash
   $ sudo chown root.icadmins ConnectionsTools-master/etc/*
   $ sudo chmod 770 ConnectionsTools-master/etc/*
   $ sudo chown -R root.icadmins ConnectionsTools-master/tools/linux*
   $ sudo chmod -R 770 ConnectionsTools-master/tools/linux*
   ```
   
4. Copy ConnectionsTools-master/etc/linux/ictools.conf to /etc/ictools.conf.

   ```Bash
   $ sudo cp -p ConnectionsTools-master/etc/linux/ictools.conf /etc/
   ```
   
5. Copy the ConnectionsTools-master/tools/linux files to a location of your choice. I recommend /usr/local/sbin.

   ```Bash
   $ sudo cp -p -R ConnectionsTools-master/tools/linux* /usr/local/sbin/
   
6. (Optional but recommended) Add the directory you chose in Step 5 to your path. Note that for sudo, you'll need to add the
   directory to the secure_path variable in /etc/sudoers. For example:
   
   ```Bash
   Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin
   ```
   
7. Modify the contents of /etc/ictools.conf to match your environment.

You are now ready to use the tools.

### Advanced installation

The advanced installation involves deploying the tools to one node, as documented in the Basic installation section. Instead 
of copying the tools to a regular directory, however, you copy them to a directory exported via NFS. Then, on each 
Connections node, you mount the NFS directory that contains the tools. This approach makes it much easier to upgrade to new
versions of ConnectionsTools since you only need to upgrade a single node.

### The tools

- [Connections Blue](doc/blue.md)
- [Connections Pink](doc/pink.md)