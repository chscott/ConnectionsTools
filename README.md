## Overview

ConnectionsAdminTools is a set of administrative scripts designed to make life easier for Connections administrators. The scripts contain both user-friendly wrappers around existing administration tools and new tools that don't already exist in the product.

## System requirements

- Linux. This package is developed and tested on Red Hat Enterprise Linux but should run without issue on any Linux     
  distribution.
  
- Bash shell

- root/sudo access

## Installation

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
   $ sudo chown root.icadmins ConnectionsAdminTools-master/tools/*
   $ sudo chmod 770 ConnectionsAdminTools-master/tools/*
   ```
   
4. Copy ConnectionsAdminTools-master/etc/ictools.conf to /etc/ictools.conf.

   ```Bash
   $ sudo cp -p ConnectionsAdminTools-master/etc/ictools.conf /etc/
   ```
   
5. Copy the ConnectionsAdminTools-master/tools files to a location of your choice. I recommend /usr/local/sbin.

   ```Bash
   $ sudo cp -p ConnectionsAdminTools-master/tools/* /usr/local/sbin/
   
6. (Optional but recommended) Add the directory you chose in Step 5 to your path. Note that for sudo, you'll need to add the
   directory to the secure_path variable in /etc/sudoers. For example:
   
   ```Bash
   Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin
   ```
   
7. Modify the contents of /etc/ictools.conf to match your environment.