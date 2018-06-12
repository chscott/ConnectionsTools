### System requirements

- Linux. This package is developed and tested on Red Hat Enterprise Linux but should run without issue on any Linux     
  distribution.
  
- Bash shell

- root/sudo access

### Basic installation

1. From your Linux system, download the zip file from GitHub.

   ```Shell
   $ curl -s -L -o master.zip https://github.com/chscott/ConnectionsTools/archive/master.zip
   ```
   
2. Unzip the file to a temporary directory.

   ```Shell
   $ unzip -qq master.zip
   ```
   
3. Update the file ownership and permissions on the ConnectionsTools-master/etc and ConnectionsTools-master/tools/linux 
   directory files. In this example deployment scenario, we want the files owned by root and a group named icadmins, both of 
   which will have full control. Other users will have no access. Your requirements may vary.
   
   ```Shell
   $ sudo chown root.icadmins ConnectionsTools-master/etc/*
   $ sudo chmod 770 ConnectionsTools-master/etc/*
   $ sudo chown -R root.icadmins ConnectionsTools-master/tools/linux*
   $ sudo chmod -R 770 ConnectionsTools-master/tools/linux*
   ```
   
4. Copy ConnectionsTools-master/etc/linux/ictools.conf to /etc/ictools.conf.

   ```Shell
   $ sudo cp -p ConnectionsTools-master/etc/linux/ictools.conf /etc/
   ```
   
5. Copy the ConnectionsTools-master/tools/linux files to a location of your choice. For example, /usr/local/sbin.

   ```Shell
   $ sudo cp -p -R ConnectionsTools-master/tools/linux* /usr/local/sbin/
   
6. (Optional but recommended) Add the directory you chose in Step 5 to your path. This will let you run the commands without
   needing to specify their full path.
   
   Note that for sudo, you'll need to add the directory to the secure_path variable in /etc/sudoers. For example:
   
   ```Shell
   Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin
   ```
   
7. Modify the contents of /etc/ictools.conf to match your environment.

You are now ready to use the tools.

### Advanced installation

The advanced installation involves deploying the tools to one node, as documented in the Basic installation section. Instead 
of copying the tools to a regular directory, however, you copy them to a directory exported via NFS. Then, on each 
Connections node, you mount the NFS directory that contains the tools. This approach makes it much easier to upgrade to new
versions of ConnectionsTools since you only need to upgrade a single node.