## getPodShell

The getPodShell tool connects to a shell in the default container of the named pod.

### Syntax

```Bash
$ sudo getPodShell.sh POD_NAME
```

### Options

None.

### Example

Connect to the shell of an orient-web-client pod.

```Bash
$ pod=$(sudo getPodName.sh orient-web-client)
$ sudo getPodShell.sh $pod
~/app $
```