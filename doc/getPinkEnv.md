## getPinkEnv

The getPinkEnv tool is a wrapper around kubectl get configmaps that returns the connections-env configmap describing the 
Connections Pink configuration.

### Syntax

```
$ sudo getPinkEnv.sh
```

### Options

None.

### Example

```
$ sudo getPinkEnv.sh $pod
apiVersion: v1
data:
  cnx-interservice-opengraph-port: "80"
  communties-db-host: localhost
  communties-db-name: SNCOMM
  communties-db-port: "50000"
...