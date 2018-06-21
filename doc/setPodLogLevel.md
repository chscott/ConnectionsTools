## setPodLogLevel

Change the logging level of the indicated pod type (deployment).

When changing the pod logging level, you are actually changing the deployment. When this occurs, pods in the deployment are 
recreated. Using the tool several times in quick succession may result in more pods running that desired by the deployment
configuration. As a best practice, change the log level and monitor the pod status with [getPodInfo](getPodInfo.md). When all
pods are back to the Running status, you can use the tool again to set a new log level.

### Syntax

```Shell
$ sudo setPodLogLevel.sh POD_TYPE LOG_LEVEL
```

Valid log levels in increasing verbosity: fatal, error, warn, info, debug, trace, verbose, silly

### Options

None.

### Example

Change the log level of orient-web-client pods to silly (maximum verbosity):

```Shell
$ sudo setPodLogLevel.sh orient-web-client silly
Log level changed to silly in orient-web-client. The pods will now restart. Use getPodInfo.sh --all to monitor status.
```