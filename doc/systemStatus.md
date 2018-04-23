## systemStatus

The systemStatus tool gives you an overview of the state of a particular Connections node. Service states are clearly 
identified, allowing you to quickly determine what actions need to be taken.

### Syntax

```Bash
$ sudo systemStatus.sh
```

### Options

None.

### Examples

In this example, all systems are running, indicating a healthy node.

```Bash
$ sudo systemStatus.sh
Server: DB2                                                  STARTED
Server: IHS                                                  STARTED
Server: Solr                                                 STARTED
Server: cognos      Profile: cognos                          STARTED
Server: nodeagent   Profile: cognos                          STARTED
Server: dmgr        Profile: dmgr                            STARTED
Server: ic1         Profile: ic1                             STARTED
Server: nodeagent   Profile: ic1                             STARTED
Server: ic2         Profile: ic2                             STARTED
Server: nodeagent   Profile: ic2                             STARTED
```

In this example, the Solr component is not running, indicating action must be taken by the administrator.

```Bash
$ sudo systemStatus.sh
Server: DB2                                                  STARTED
Server: IHS                                                  STARTED
Server: Solr                                                 STOPPED
Server: cognos      Profile: cognos                          STARTED
Server: nodeagent   Profile: cognos                          STARTED
Server: dmgr        Profile: dmgr                            STARTED
Server: ic1         Profile: ic1                             STARTED
Server: nodeagent   Profile: ic1                             STARTED
Server: ic2         Profile: ic2                             STARTED
Server: nodeagent   Profile: ic2                             STARTED
```