## stopSolr

The stopSolr tool stops the Solr search engine on the current system.

Note that this tool waits a configurable amount of time after issuing the stop command to determine if the server was 
successfully stopped. If you see the tool report a failure but later determine the server actually did stop, you may need to
adjust the serviceDelaySeconds variable in /etc/ictools.conf to add more time.

### Syntax

```
$ sudo stopSolr.sh
```

### Options

None.

### Example

```
$ sudo stopSolr.sh
Stopping Solr server...                                      SUCCESS
```