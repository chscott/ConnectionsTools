## startAppServers

The startAppServers tool identifies and starts all WAS application servers on the current system. The Deployment Manager and
nodeagents are not affected.

### Syntax

#### Linux

```Shell
$ sudo startAppServers.sh
```

#### Windows

```Shell
> startAppServers.ps1
```

### Options

None.

### Example

```Shell
$ sudo startAppServers.sh
Starting server cognos in profile cognos...                  SUCCESS
Starting server ic1 in profile ic1...                        SUCCESS
Starting server ic2 in profile ic2...                        SUCCESS
```