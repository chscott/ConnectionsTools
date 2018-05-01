### Overview

ConnectionsAdminTools is a set of administrative scripts designed to make life easier for Connections administrators. The 
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
   $ curl -s -L -o master.zip https://github.com/chscott/ConnectionsAdminTools/archive/master.zip
   ```
   
2. Unzip the file.

   ```Bash
   $ unzip -qq master.zip
   ```
   
3. Update the file ownership and permissions on the ConnectionsAdminTools-master/etc and ConnectionsAdminTools-master/tools 
   directory files. In this example deployment scenario, we want the files owned by root and a group named icadmins, both of 
   which will have full control. Other users will have no access. Your requirements may vary.
   
   ```Bash
   $ sudo chown root.icadmins ConnectionsAdminTools-master/etc/*
   $ sudo chmod 770 ConnectionsAdminTools-master/etc/*
   $ sudo chown -R root.icadmins ConnectionsAdminTools-master/tools/*
   $ sudo chmod -R 770 ConnectionsAdminTools-master/tools/*
   ```
   
4. Copy ConnectionsAdminTools-master/etc/ictools.conf to /etc/ictools.conf.

   ```Bash
   $ sudo cp -p ConnectionsAdminTools-master/etc/ictools.conf /etc/
   ```
   
5. Copy the ConnectionsAdminTools-master/tools files to a location of your choice. I recommend /usr/local/sbin.

   ```Bash
   $ sudo cp -p -R ConnectionsAdminTools-master/tools/* /usr/local/sbin/
   
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
versions of ConnectionsAdminTools since you only need to upgrade a single node.

### The tools

- [compareApps](doc/compareApps.md)
- [compareEars](doc/compareEars.md)
- [connectToMongo](doc/connectToMongo.md)
- [connectToRedis](doc/connectToRedis.md)
- [getAllWikis](doc/getAllWikis.md)
- [getAppLogs](doc/getAppLogs.md)
- [getAppRoles](doc/getAppRoles.md)
- [getAvailableFixes](doc/getAvailableFixes.md)
- [getBuildLevels](doc/getBuildLevels.md)
- [getCommSize](doc/getCommSize.md)
- [getContainerID](doc/getContainerID.md)
- [getInstalledFixes](doc/getInstalledFixes.md)
- [getPodInfo](doc/getPodInfo.md)
- [getPodLogs](doc/getPodLogs.md)
- [getPodName](doc/getPodName.md)
- [getPodShell](doc/getPodShell.md)
- [installFixes](doc/installFixes.md)
- [jarscan](doc/jarscan.md)
- [startAll](doc/startAll.md)
- [startAppServers](doc/startAppServers.md)
- [startDB2](doc/startDB2.md)
- [startDmgr](doc/startDmgr.md)
- [startIHS](doc/startIHS.md)
- [startNodeagents](doc/startNodeagents.md)
- [startSolr](doc/startSolr.md)
- [startWASServer](doc/startWASServer.md)
- [stopAll](doc/stopAll.md)
- [stopAppServers](doc/stopAppServers.md)
- [stopDB2](doc/stopDB2.md)
- [stopDmgr](doc/stopDmgr.md)
- [stopIHS](doc/stopIHS.md)
- [stopNodeagents](doc/stopNodeagents.md)
- [stopSolr](doc/stopSolr.md)
- [stopWASServer](doc/stopWASServer.md)
- [syncNodes](doc/syncNodes.md)
- [syncUsers](doc/syncUsers.md)
- [systemStatus](doc/systemStatus.md)
- [uninstallFixes](doc/uninstallFixes.md)
- [validateXML](doc/validateXML.md)
- [wsadmin](doc/wsadmin.md)