## syncNodes

The syncNodes tool performs a WebSphere sync of nodes on the system or nodes in the cell, depending on the option provided.
If no options are provided, an online sync is performed.

### Syntax

#### Linux

```Shell
$ sudo syncNodes.sh [--offline]
```

#### Windows

```Shell
> syncNodes.ps1 [--offline]
```

### Options

When run with no options, syncNodes performs an online sync of all active nodes in the cell. When run with the **--offline**
option, syncNodes performs an offline sync of all nodes on the current system. 

Note that an offline sync requires the nodeagents on the system to be stopped. If they are not stopped, an error is reported. 
You can use the [stopNodeagents](stopNodeagents.md) tool to stop any active nodeagents prior to running an offline sync.

### Examples

Run an online sync of all active nodes in the cell.

```Shell
$ sudo syncNodes.sh
Synchronizing active nodes...
cognosNode                                                   SUCCESS
ic1Node                                                      SUCCESS
ic2Node                                                      SUCCESS
```

Run an offline sync of all nodes on the current system. In this case, all nodeagents are stopped.

```Shell
$ sudo syncNodes.sh --offline
Synchronizing servers in cognos profile...                   SUCCESS
Synchronizing servers in ic1 profile...                      SUCCESS
Synchronizing servers in ic2 profile...                      SUCCESS
```

Run an offline sync of all nodes on the current system. In this case, all nodeagents are running.

```Shell
$ sudo syncNodes.sh --offline
Synchronizing servers in cognos profile...                   FAILURE (At least one server is still running)
Synchronizing servers in ic1 profile...                      FAILURE (At least one server is still running)
Synchronizing servers in ic2 profile...                      FAILURE (At least one server is still running)
```