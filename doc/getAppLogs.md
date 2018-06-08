## getAppLogs

The getAppLogs tool facilitates pulling relevant portions of an HPEL-enabled WebSphere application server log. Log excerpts 
can be defined by application and time to minimize the amount of logging retrieved, reducing the amount of time needed for
problem determination.

### Syntax

#### Linux
```shell
$ sudo getAppLogs.sh --profile PROFILE [--app APP] [--duration DURATION]
```

#### Windows
```PowerShell
> getAppLogs.ps1 --profile PROFILE [--app APP] [--duration DURATION]
```

### Options

The only required option is **--profile**, which specifies the WAS profile name from which to collect logs. If you have a 
profile located at /var/profiles/profile1, you specify _profile1_ as the name of the profile.

The **--app** option limits the log excerpt to the lines logged by the specified application. Only a single application can 
be specified, and its name must match the name that appears in the admin console. For example, _Profiles_. Omitting this 
option results in the log excerpt containing the lines logged by all applications.

The **--duration** option limits the log excerpt to lines logged within the specified time period. In general, this option
takes an integer argument specifying the number of minutes of logging to collect. Additionally, three keywords are 
recognized:

- _today_: Collects log entries since midnight.

- _lastHour_: Synonym for 60 minutes.

- _monitor_: Streams logs to the console as they occur (similar to tail -f).

### Examples

All examples assume a WAS profile named profile1.

Get all available log entries. This is equivalent to generating a full SystemOut.log or trace.log.

```Bash
$ sudo getAppLogs.sh --profile profile1
```

Get all logs from today (i.e. since midnight of the current day).

```Bash
$ sudo getAppLogs.sh --profile profile1 --duration today
```

Get logs for the News application from the last hour.

```Bash
$ sudo getAppLogs.sh --profile profile1 --app News --duration lastHour
```

Get logs for the News application from the last five minutes.

```Bash
$ sudo getAppLogs.sh --profile profile1 --app News --duration 5
```

Stream logs for the News application in real time.

```Bash
$ sudo getAppLogs.sh --profile profile1 --app News --duration monitor