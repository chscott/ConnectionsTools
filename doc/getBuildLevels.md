## getBuildLevels

The getBuildLevels tool prints module build levels from the MANIFEST.MF file of installed web modules.

Note that build levels for non-Connections or otherwise uninteresting applications can be added to the excludes array in the
script. A default set of non-Connenctions applications is preconfigured. No reporting is provided for these applications.

### Syntax

#### Linux

```Shell
$ sudo getBuildLevels.sh
```

#### Windows

```Shell
> getBuildLevels.ps1
```

### Options

None.

### Example

```Shell
$ sudo getBuildLevels.sh
...
================================================================================
EAR:       Profiles.ear

Module:    lc.profiles.ext.war
Title:     profiles.web/ext.shell
Version:   [IC6.0_CR_Integration] 20171116-0701

Module:    lc.profiles.seedlist.war
Title:     profiles.seedlist/retriever
Version:   [IC6.0_CR_Integration] 20171116-0701

Module:    lc.profiles.app.war
Title:     profiles.web/app
Version:   [IC6.0_CR_Integration] 20171116-0701

Module:    Profiles.ear
Title:     profiles.ear
Version:   [IC6.0_CR_Integration] 20171116-0701

Module:    lc.events.publish.jar
Title:     lc.events.30/publish
Version:   [IC6.0_CR_Integration] 20171116-0701

Module:    lconn.scheduler.ejb.jar
Title:     lc.sched.v2/ejb
Version:   [IC6.0_CR_Integration] 20171116-0701
================================================================================
...
```