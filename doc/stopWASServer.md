## stopWASServer

Stops the named WAS server in the provided profile.

### Syntax

#### Linux
```
$ sudo stopWASServer.sh --profile <PROFILE> --server <SERVER>
```

#### Windows
```
> stopWASServer.ps1 --profile <PROFILE> --server <SERVER>
```

### Options

The stopWASServer tool has two required options. The **--profile** option specifies the name of the profile containing the
server to stop. The **--server** option specifies the name of the server to stop. Servers of all types (Deployment Manager,
Nodeagent, Application Server) can be specified.

### Examples

Stop the application server named server1 in the profile named profile1.

```
$ sudo stopWASServer.sh --profile profile1 --server server1
Stopping server server1 in profile profile1...               SUCCESS
```

Stop the nodeagent in the profile named profile1.

```
$ sudo stopWASServer.sh --profile profile1 --server nodeagent
Stopping server nodeagent in profile profile1...             SUCCESS
```