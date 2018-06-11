## wsadmin

The wsadmin tool is a simple wrapper around the WAS wsadmin.sh command.

### Syntax

#### Linux
```
$ sudo wsadmin.sh [SCRIPT] [ARGUMENTS]
```

#### Windows
```
> wsadmin.ps1 [SCRIPT] [ARGUMENTS]
```

### Options

None.

### Examples

Start a wsadmin shell.

```
$ sudo wsadmin.sh
```

Use wsadmin to run a script file.

```
$ sudo wsadmin.sh myScript.py
```

Use wsadmin to run a script file with two arguments.

```
$ sudo wsadmin.sh myScript.py arg1 arg2
```