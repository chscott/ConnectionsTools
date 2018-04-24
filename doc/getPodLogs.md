## getPodLogs

The getPodLogs tool retrieves or streams the logs for the named pod, depending on the options provided. Additionally, the tool
provides the location of rotated logs when run on the system hosting the pod.

### Syntax

```Bash
$ sudo getPodLogs.sh POD_NAME [--monitor | --print]
```

### Options

When run with the **--print** option or no options, getPodLogs writes the current logs to the console. When the **--monitor**
option is used, logs are streamed from the pod (similar to tail -f).

### Examples

Print the logs for the first orient-web-client pod. Note that the command is run on a Connections Pink node that is not the
one hosting the pod. Notice that no rotated logs are listed.

```Bash
$ pod=$(sudo getPodName.sh orient-web-client 1)
$ sudo getPodLogs.sh $pod 
2018-04-24T20:55:05.146Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
Current logs are printed above. No output means the logs have been rotated.
This pod's container exists on another node. Be sure to run this command there to check for rotated logs.
```

This is the same example as above except that the command is run on the Connections Pink node hosting the pod. Notice that
the location of rotated logs is provided.

```Bash
$ pod=$(sudo getPodName.sh orient-web-client 1)
$ sudo getPodLogs.sh $pod 
2018-04-24T20:59:35.145Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
Current logs are printed above. No output means the logs have been rotated.
The following rotated logs are available in /var/lib/docker/containers/55c4e8a843e01e7958181bfa2eaebd586abf335f9c54e033b68ac33cd8665757:
55c4e8a843e01e7958181bfa2eaebd586abf335f9c54e033b68ac33cd8665757-json.log
55c4e8a843e01e7958181bfa2eaebd586abf335f9c54e033b68ac33cd8665757-json.log.2
55c4e8a843e01e7958181bfa2eaebd586abf335f9c54e033b68ac33cd8665757-json.log.1
```

In this example, the logs of the first orient-web-client are followed in real time.

```Bash
$ pod=$(sudo getPodName.sh orient-web-client 1)
$ sudo getPodLogs.sh $pod --monitor
2018-04-24T21:00:45.146Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
2018-04-24T21:00:55.143Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
2018-04-24T21:01:05.144Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token

```