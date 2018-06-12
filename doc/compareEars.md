## compareEars

The compareEars tool allows you to check two WebSphere EAR files to see if they are the same. This is useful when 
troubleshooting issues where EAR files may not be copied correctly during a node synchronization event or you get different
results when accessing one node instead of another.

Note that the EAR files must be accessible from the system on which you run the command. This can be via a remote mapping or
by simply copying the necessary files to the system.

To compare all expanded application files instead of individual EAR files, see [compareApps](compareApps.md).

### Syntax

```Shell
$ sudo compareEars.sh <EAR1> <EAR2> [--details]
```

### Options

When specified, the **--details** option will fully expand each EAR file into temporary directories in /tmp and report all 
embedded files that differ. This option takes quite a bit longer than the brief mode and is recommended only after brief mode 
determines the EAR files differ.

### Examples

The first example shows two EAR files that are the same. There would be no value in running the command again with the 
--details option since we already know there are no differing files.

```Shell
$ sudo compareEars.sh Common1.ear Common2.ear
Common1.ear and Common2.ear are identical
```

The second example shows two EAR files that differ. In this case, we may want to use the --details option to see the embedded
files causing the EARs to be different.

```Shell
$ sudo compareEars.sh Common1.ear Common3.ear
Common1.ear and Common3.ear are different
```

This example shows using the --details option to list the embedded files that differ.

```Shell
$ sudo compareEars.sh ~/ic1/config/cells/icCell/applications/Common.ear/Common.ear ~/dmgr/config/cells/icCell/applications/Common.ear/Common.ear --details
Expanding /tmp/Common1.ear into /tmp/expand_ear1...
Expanding /tmp/Common2.ear into /tmp/expand_ear2...
Generating list of differing files...
Files /tmp/expand_ear1/connections.web.resources.war/WEB-INF/eclipse/plugins/com.ibm.ic.core.web.resources_5.0.0.20171116-0701.jar and /tmp/expand_ear2/connections.web.resources.war/WEB-INF/eclipse/plugins/com.ibm.ic.core.web.resources_5.0.0.20171116-0701.jar differ
/tmp/Common1.ear and /tmp/Common2.ear are different
Deleting /tmp/expand_ear1 and /tmp/expand_ear2...
```