## stopAll

Stops all server components on the current system. Server components include the following:

- WebSphere servers (Deployment Manager, Nodeagents, Application Servers)
- IBM HTTP Server
- Solr server
- IBM DB2 server

### Syntax

#### Linux
```
$ sudo stopAll.sh
```

#### Windows
```
> stopAll.ps1
```

### Options

None.

### Example

```
$ sudo stopAll.sh
Stopping server cognos in profile cognos...                  SUCCESS
Stopping server ic1 in profile ic1...                        SUCCESS
Stopping server ic2 in profile ic2...                        SUCCESS
Stopping server nodeagent in profile cognos...               SUCCESS
Stopping server nodeagent in profile ic1...                  SUCCESS
Stopping server nodeagent in profile ic2...                  SUCCESS
Stopping server dmgr in profile dmgr...                      SUCCESS
Stopping IHS server...                                       SUCCESS
Stopping Solr server...                                      SUCCESS
Stopping DB2...                                              SUCCESS
```