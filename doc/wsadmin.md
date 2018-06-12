## wsadmin

The wsadmin tool is a simple wrapper around the WAS wsadmin.sh command.

### Syntax

#### Linux

```Shell
$ sudo wsadmin.sh [SCRIPT] [ARGUMENTS]
```

#### Windows

```Shell
> wsadmin.ps1 [SCRIPT] [ARGUMENTS]
```

### Options

None.

### Examples

Start a wsadmin shell.

```Shell
$ sudo wsadmin.sh
```

Use wsadmin to run a script file.

```Shell
$ sudo wsadmin.sh myScript.py
```

Use wsadmin to run a script file with two arguments.

```Shell
$ sudo wsadmin.sh myScript.py arg1 arg2
```