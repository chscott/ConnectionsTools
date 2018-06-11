## stopIHS

The stopIHS tool stops the IBM HTTP Server on the current system.

Note that this tool waits a configurable amount of time after issuing the stop command to determine if the server was 
successfully stopped. If you see the tool report a failure but later determine the server actually did stop, you may need to
adjust the serviceDelaySeconds variable in /etc/ictools.conf to add more time.

### Syntax

#### Linux
```
$ sudo stopIHS.sh
```

#### Windows
```
> stopIHS.ps1
```

### Options

None.

### Example

```
$ sudo stopIHS.sh
Stopping IHS server...                                       SUCCESS
```