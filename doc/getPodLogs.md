## getPodLogs

The getPodLogs tool retrieves or streams the logs for the named pod or all pods of a given type, depending on the options 
provided. Additionally, the tool provides the location of rotated logs when run on the system hosting the pod(s).

### Syntax

```Shell
$ sudo getPodLogs.sh [POD_NAME | POD_TYPE] [--print | --printAll | --monitor | --monitorAll]
```

### Options

The **--print** (default) and **--monitor** options work with a named pod. For example, orient-web-client-701389332-gzkb1.
When run in these modes, getPodLogs will either print or stream (similar to tail -f) the logs for that individual pod.

When run with the **--printAll** or **--monitorAll** options, getPodLogs expects a pod type. For example, orient-web-client. 
When run in these modes, getPodLogs will either print or stream the logs for all pods of that type.

### Examples

Print the logs for the first orient-web-client pod. Note that the command is run on a Connections Pink node that is not the
one hosting the pod. Notice that no rotated logs are listed.

```Shell
$ pod=$(sudo getPodName.sh orient-web-client 1)
$ sudo getPodLogs.sh $pod 
2018-04-24T20:55:05.146Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
Current logs are printed above. No output means the logs have been rotated.
This pod's container exists on another node. Be sure to run this command there to check for rotated logs.
```

This is the same example as above except that the command is run on the Connections Pink node hosting the pod. Notice that
the location of rotated logs is provided.

```Shell
$ pod=$(sudo getPodName.sh orient-web-client 1)
$ sudo getPodLogs.sh $pod 
2018-04-24T20:59:35.145Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
Current logs are printed above. No output means the logs have been rotated.
The following rotated logs are available in /var/lib/docker/containers/55c4e8a843e01e7958181bfa2eaebd586abf335f9c54e033b68ac33cd8665757:
55c4e8a843e01e7958181bfa2eaebd586abf335f9c54e033b68ac33cd8665757-json.log
55c4e8a843e01e7958181bfa2eaebd586abf335f9c54e033b68ac33cd8665757-json.log.2
55c4e8a843e01e7958181bfa2eaebd586abf335f9c54e033b68ac33cd8665757-json.log.1
```

Print the logs for all orient-web-client pods. The output for the individual pods is marked.

```Shell
$ sudo getPodLogs.sh middleware-graphql --printAll
Printing logs in pod middleware-graphql-3459494-1328w...
Current logs are printed above. No output means the logs have been rotated.
The following rotated logs are available in /var/lib/docker/containers/081caeb88e3c9d75dc348e5211ad3d49bc821d34c8aa75782c0c6aa28094d84a:
081caeb88e3c9d75dc348e5211ad3d49bc821d34c8aa75782c0c6aa28094d84a-json.log
081caeb88e3c9d75dc348e5211ad3d49bc821d34c8aa75782c0c6aa28094d84a-json.log.1
Printing logs in pod middleware-graphql-3459494-6nztf...
Current logs are printed above. No output means the logs have been rotated.
The following rotated logs are available in /var/lib/docker/containers/d1555fa7ca9f46250cb79aa28807e4746ef5e2715fa1c8064198689b883e1e58:
d1555fa7ca9f46250cb79aa28807e4746ef5e2715fa1c8064198689b883e1e58-json.log
d1555fa7ca9f46250cb79aa28807e4746ef5e2715fa1c8064198689b883e1e58-json.log.1
d1555fa7ca9f46250cb79aa28807e4746ef5e2715fa1c8064198689b883e1e58-json.log.2
Printing logs in pod middleware-graphql-3459494-bvf36...
Current logs are printed above. No output means the logs have been rotated.
The following rotated logs are available in /var/lib/docker/containers/9a4695384e16dc4f2dddc054756e157a2000fe7fd165d80b675d3f09b3dbd916:
9a4695384e16dc4f2dddc054756e157a2000fe7fd165d80b675d3f09b3dbd916-json.log
9a4695384e16dc4f2dddc054756e157a2000fe7fd165d80b675d3f09b3dbd916-json.log.2
9a4695384e16dc4f2dddc054756e157a2000fe7fd165d80b675d3f09b3dbd916-json.log.1
```

In this example, the logs of the first orient-web-client are followed in real time.

```Shell
$ pod=$(sudo getPodName.sh orient-web-client 1)
$ sudo getPodLogs.sh $pod --monitor
2018-04-24T21:00:45.146Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
2018-04-24T21:00:55.143Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
2018-04-24T21:01:05.144Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
```

Monitor the logs for all orient-web-client pods in real time. Note that output lines for individual pods are not marked in
this mode.

```Shell
$ sudo getPodLogs.sh orient-web-client --monitorAll | more
Monitoring logs in pod orient-web-client-701389332-gzkb1...
Monitoring logs in pod orient-web-client-701389332-q3x2s...
Monitoring logs in pod orient-web-client-701389332-txzc5...
2018-06-11T18:07:03.497Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
2018-06-11T18:07:13.494Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
2018-06-11T18:07:23.496Z - error: [auth-service] setJWT failed with err: [no_auth_token]: no_auth_token
```