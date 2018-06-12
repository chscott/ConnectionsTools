## startAll

Starts all server components on the current system. Server components include the following:

- WebSphere servers (Deployment Manager, Nodeagents, Application Servers)
- IBM HTTP Server
- Solr server
- IBM DB2 server

### Syntax

#### Linux

```Shell
$ sudo startAll.sh
```

#### Windows

```Shell
> startAll.ps1
```

### Options

None.

### Example

```Shell
$ sudo startAll.sh
Starting DB2...                                              SUCCESS
Starting Solr server...                                      SUCCESS
Starting IHS server...                                       SUCCESS
Starting server dmgr in profile dmgr...                      SUCCESS
Starting server nodeagent in profile cognos...               SUCCESS
Starting server nodeagent in profile ic1...                  SUCCESS
Starting server nodeagent in profile ic2...                  SUCCESS
Starting server cognos in profile cognos...                  SUCCESS
Starting server ic1 in profile ic1...                        SUCCESS
Starting server ic2 in profile ic2...                        SUCCESS
```