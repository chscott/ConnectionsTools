## getAvailableFixes

The getAvailableFixes tool returns a list of iFixes available to install in your Connections Blue environment.
Available fixes are fixes you have downloaded to the Deployment Manager's fixes directory but have not yet applied to the
environment.

### Syntax

#### Linux
```
$ sudo getAvailableFixes.sh
```

#### Windows
```
> getAvailableFixes.ps1
```

### Options

None.

### Example

```
$ sudo getAvailableFixes.sh
Getting a list of Connections fixes available to install...
Fixes available to install: LO93624
```