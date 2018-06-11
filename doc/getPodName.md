## getPodName

The getPodName tool allows you to retrieve the full pod name using only the friendly portion of the name. Pod names are appended with unique strings to form unique names, but these are cumbersome to work with. By using getPodName, you can
acquire a reference to the full, unique pod name using only the portion that is easy to remember. That reference can then
be used in other pod interactions.

### Syntax

```
$ sudo getPodName.sh POD_TYPE [POD_NUMBER]
```

### Options

You can optionally provide a number after POD_STRING that identifies a specific pod to retrieve. Not specifying any number
is equivalent to specifying the number 1. In many cases you will not care which pod reference you retrieve and can omit the
number. In cases where you may want a reference to all running pods, you can run the command multiple times, specifying a
different number.

### Examples

This example retrieves a reference to the first orient-web-client pod.

```
$ pod=$(sudo getPodName.sh orient-web-client)
$ echo $pod
orient-web-client-701389332-gzkb1
```

The second example illustrates retrieving a reference to each orient-web-client pod.

```
$ pod1=$(sudo getPodName.sh orient-web-client 1)
$ pod2=$(sudo getPodName.sh orient-web-client 2)
$ pod3=$(sudo getPodName.sh orient-web-client 3)
$ echo $pod1 && echo $pod2 && echo $pod3
orient-web-client-701389332-gzkb1
orient-web-client-701389332-q3x2s
orient-web-client-701389332-txzc5
```