## connectToMongo

The connectToMongo tool connects you to the Mongo CLI of the master Mongo replica pod. A cheatsheet of common Mongo commands 
is provided as a header to the shell.

### Syntax

```Bash
$ sudo connectToMongo.sh
```

### Options

None.

### Example

```Bash
$ sudo connectToMongo.sh
mongo-0 is not the master Mongo replica. Trying another...
Common Mongo commands:
        show dbs: List available databases
        use <database>: Connect to a database
        show collections: List available document collections (views)
        db.<collection>.find(): Print the documents in a collection
        db.<collection>.find({<key>:<value>}): Print the documents in a collection that have <key> matching <value>
MongoDB shell version v3.4.4
connecting to: mongodb://mongo-1.mongo.connections.svc.cluster.local:27017/
MongoDB server version: 3.4.4
rs0:PRIMARY>
```