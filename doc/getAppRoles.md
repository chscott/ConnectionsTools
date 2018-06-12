## getAppRoles

The getAppRoles tool returns all roles and role assignments bound to an application.

### Syntax

#### Linux

```Shell
$ sudo getAppRoles.sh [APPLICATION]
```

#### Windows

```Shell
> getAppRoles.ps1 [APPLICATION]
```

### Options

If no application is provided, getAppRoles returns the roles and role assignments for all installed applications. If an 
application name is provided, only the roles and role assignments for that application are returned.

### Examples

Get the roles and role assignments for all applications.

```Shell
$ sudo getAppRoles.sh
Application: Activities
Role:  person
Role:  everyone
Role:  reader
Role:  metrics-reader
Role:  search-admin
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  widget-admin
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  admin
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  org-admin
Role:  bss-provisioning-admin
================================================================================
Application: Blogs
Role:  person
Role:  everyone
Role:  metrics-reader
Role:  admin
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  org-admin
Role:  global-moderator
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  search-admin
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  widget-admin
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  reader
Role:  bss-provisioning-admin
================================================================================
...
```

Get the roles and role assignments for the Profiles application.

```Shell
$ sudo getAppRoles.sh Profiles
Application: Profiles
Role:  everyone
Role:  reader
Role:  person
Role:  allAuthenticated
Role:  metrics-reader
Role:  admin
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  search-admin
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  dsx-admin
       Mapped users:  wasadmin
       Mapped groups:  IC Admins
       Mapped groups access ids:  group:defaultWIMFileBasedRealm/CN=IC Admins,ou=ic,dc=ad,dc=com
Role:  org-admin
Role:  bss-provisioning-admin
================================================================================
```