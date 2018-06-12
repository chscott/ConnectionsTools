## getContainerID

The getContainerID tool returns the default container ID for the specified pod name.

### Syntax

```Shell
$ sudo getContainerID.sh POD_NAME
```

### Options

None.

### Example

```Shell
$ pod=$(sudo getPodName.sh orient-web-client)
$ sudo getContainerID.sh $pod
55c4e8a843e01e7958181bfa2eaebd586abf335f9c54e033b68ac33cd8665757
```