## stopIHSAdmin

The stopIHSAdmin tool stops the IBM HTTP Administration Server on the current system.

Note that this tool waits a configurable amount of time after issuing the stop command to determine if the server was 
successfully stopped. If you see the tool report a failure but later determine the server actually did stop, you may need to
adjust the serviceDelaySeconds variable in /etc/ictools.conf to add more time.

### Syntax

#### Linux

```Shell
$ sudo stopIHSAdmin.sh
```

#### Windows

```Shell
> stopIHSAdmin.ps1
```

### Options

None.

### Example

```Shell
$ sudo stopIHSAdmin.sh
Stopping IHS Admin server...                                 SUCCESS
```