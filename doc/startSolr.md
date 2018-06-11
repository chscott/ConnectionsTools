## startSolr

The startSolr tool starts the Solr search engine on the current system.

Note that this tool waits a configurable amount of time after issuing the start command to determine if the server was 
successfully started. If you see the tool report a failure but later determine the server actually did start, you may need to
adjust the serviceDelaySeconds variable in /etc/ictools.conf to add more time.

### Syntax

```
$ sudo startSolr.sh
```

### Options

None.

### Example

```
$ sudo startSolr.sh
Starting Solr server...                                      SUCCESS
```