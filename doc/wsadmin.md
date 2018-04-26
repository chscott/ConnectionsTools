## wsadmin

The wsadmin tool is a simple wrapper around the WAS wsadmin.sh command.

### Syntax

```Bash
$ sudo wsadmin.sh [SCRIPT] [ARGUMENTS]
```

### Options

None.

### Examples

Start a wsadmin shell.

```Bash
$ sudo wsadmin.sh
```

Use wsadmin to run a script file.

```Bash
$ sudo wsadmin.sh myScript.py
```

Use wsadmin to run a script file with two arguments.

```Bash
$ sudo wsadmin.sh myScript.py arg1 arg2
```