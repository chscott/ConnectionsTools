## compareApps

The compareApps tool allows you to check the expanded WebSphere application files in two profiles to see if they are the same. This is useful when troubleshooting issues where the process of expanding EAR files may encounter errors that are not 
visible to the administrator.

Note that the profile directories must be accessible from the system on which you run the command. This can be via a remote 
mapping or by copying the necessary profile directory to the system. Since each application is checked for discrepancies, the
tool can take several minutes to complete.

Additionally, there are some applications that will always be out of sync between two profiles. One example is the Help
application. Such applications can be excluded by adding additional entries to the excludeCompareApps variable in
/etc/ictools.conf.

To compare individual EAR files instead of the expanded application files, see [compareEars](compareEars.md).

### Syntax

```
$ sudo compareApps.sh <Profile1> <Profile1> [--details]
```

### Options

When specified, the **--details** option will report on specific files that differ between applications instead of simply
reporting that the applications differ.

### Examples

The first example shows all applications in sync between profiles ic1 and ic2.

```
$ sudo compareApps.sh ic1 ic2 --details
Comparing application files in profiles. This may take several minutes...
No applications are out of sync

```

The second example shows three applications that are out of sync between profiles ic1 and ic2.

```
$ sudo compareApps.sh ic1 ic2
Comparing application files in profiles. This may take several minutes...
The following applications are out of sync:
Common.ear
FileNetEngine.ear
Profiles.ear
```

The third example uses the --details option to itemize the files that are out of sync.

```
$ sudo compareApps.sh ic1 ic2 --details
Comparing application files in profiles. This may take several minutes...
Files /var/IBM/websphere/was/profiles/ic1/installedApps/icCell/Common.ear/connections.web.resources.war/WEB-INF/eclipse/plugins/com.ibm.ic.core.web.resources_5.0.0.20171116-0701.jar and /var/IBM/websphere/was/profiles/ic2/installedApps/icCell/Common.ear/connections.web.resources.war/WEB-INF/eclipse/plugins/com.ibm.ic.core.web.resources_5.0.0.20171116-0701.jar differ
Files /var/IBM/websphere/was/profiles/ic1/installedApps/icCell/FileNetEngine.ear/acce_navigator.war/WEB-INF/classes/ACCEConfiguration.properties and /var/IBM/websphere/was/profiles/ic2/installedApps/icCell/FileNetEngine.ear/acce_navigator.war/WEB-INF/classes/ACCEConfiguration.properties differ
Only in /var/IBM/websphere/was/profiles/ic1/installedApps/icCell/Profiles.ear/lc.profiles.app.war: clear_waltz_caches.jsp
```