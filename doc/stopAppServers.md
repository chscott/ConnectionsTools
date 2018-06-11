## stopAppServers

The stopAppServers tool identifies and stops all WAS application servers on the current system. The Deployment Manager and
nodeagents are not affected.

### Syntax

#### Linux
```
$ sudo stopAppServers.sh
```

#### Windows
```
> stopAppServers.ps1
```

### Options

None.

### Example

```
$ sudo stopAppServers.sh
Stopping server cognos in profile cognos...                  SUCCESS
Stopping server ic1 in profile ic1...                        SUCCESS
Stopping server ic2 in profile ic2...                        SUCCESS
```