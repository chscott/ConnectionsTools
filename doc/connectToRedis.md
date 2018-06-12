## connectToRedis

The connectToRedis tool connects you to the Redis CLI of a Redis pod. A cheatsheet of common Redis commands is
provided as a header to the shell.

### Syntax

```Shell
$ sudo connectToRedis.sh
```

### Options

None.

### Example

```Shell
$ sudo connectToRedis.sh
Connecting to redis-server-0...
Common Redis commands:
        client list: List client connections
        info: Print server information
        keys <pattern>: List all keys matching the pattern
        monitor: Stream all requests received by the server
        pubsub channels: List active channels
        subscribe <channel>: Stream messages published to the given channel
        quit: Close the connection
127.0.0.1:6379>
```