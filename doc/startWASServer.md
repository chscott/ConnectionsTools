## startWASServer

Starts the named WAS server in the provided profile.

### Syntax

#### Linux

```Shell
$ sudo startWASServer.sh --profile <PROFILE> --server <SERVER>
```

#### Windows

```Shell
> startWASServer.ps1 --profile <PROFILE> --server <SERVER>
```

### Options

The startWASServer tool has two required options. The **--profile** option specifies the name of the profile containing the
server to start. The **--server** option specifies the name of the server to start. Servers of all types (deployment manager,
nodeagent, application server) can be specified. Note that attempting to start an application server will also start the
corresponding nodeagent.

### Examples

Stop the nodeagent in the profile named profile1.

```Shell
$ sudo startWASServer.sh --profile profile1 --server nodeagent
Starting server nodeagent in profile profile1...             SUCCESS
```

Start the application server named server1 in the profile named profile1.

```Shell
$ sudo stopWASServer.sh --profile profile1 --server server1
Starting server nodeagent in profile profile1...             SUCCESS
Starting server server1 in profile profile1...               SUCCESS
```