## getPodInfo

The getPodInfo tool is a wrapper around kubectl get pod that returns information about all pods or the named pod.

### Syntax

```Bash
$ sudo getPodInfo.sh POD_NAME | --all [--wide | --json]
```

### Options

If no options are provided, you must specify a pod name. That name will usually be a reference to a pod acquired via the
[getPodName](getPodName.md) tool. If you do not specify a particular pod, you must use the **--all** option to get information
about all pods.

You can optionally provide the format specification. The default specification is **--wide**, but you can also specify the
**--json** option to return a JSON object.

### Examples

Get information about an orient-web-client pod.

```Bash
$ pod=$(sudo getPodName.sh orient-web-client)
$ sudo getPodInfo.sh $pod
NAME                                READY     STATUS    RESTARTS   AGE
orient-web-client-701389332-gzkb1   1/1       Running   4          47d
```

Get information about an orient-web-client pod in JSON format.

```Bash
$ pod=$(sudo getPodName.sh orient-web-client)
$ sudo getPodInfo.sh $pod --json
{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": 
        "creationTimestamp": "2018-03-07T21:43:00Z",
        "generateName": "orient-web-client-701389332-",
        "name": "orient-web-client-701389332-gzkb1",
        "namespace": "connections",
    ...
}
```

Get information about all pods.

```Bash
$ sudo getPodInfo.sh --all
NAME                                     READY     STATUS             RESTARTS   AGE
analysisservice-1466752619-5t8gw         1/1       Running            0          47d
analysisservice-1466752619-dq54j         1/1       Running            0          47d
analysisservice-1466752619-k9pcl         1/1       Running            0          47d
appregistry-client-1739368259-569hb      1/1       Running            1          47d
appregistry-client-1739368259-97vd0      1/1       Running            2          47d
appregistry-client-1739368259-q11ch      1/1       Running            0          47d
...
```

Get information about all pods in JSON format.

```Bash
$ sudo getPodInfo.sh --all --json
{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": 
        "creationTimestamp": "2018-03-07T21:43:00Z",
        "generateName": "analysisservice-1466752619-5t8gw-",
        "name": "analysisservice-1466752619-5t8gw",
        "namespace": "connections",
    ...
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": 
        "creationTimestamp": "2018-03-07T21:43:00Z",
        "generateName": "analysisservice-1466752619-dq54j-",
        "name": "analysisservice-1466752619-dq54j",
        "namespace": "connections",
    ...
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": 
        "creationTimestamp": "2018-03-07T21:43:00Z",
        "generateName": "analysisservice-1466752619-k9pcl-",
        "name": "analysisservice-1466752619-k9pcl",
        "namespace": "connections",
}
```