# getAppRoles.py: Get the roles and mapped entities for specified application or all applications
#                 if no application is specified.

# Get the application name if one was specified
try:
    scope = sys.argv[1]
except (IndexError):
    scope = "ALL_INSTALLED"

if scope is "ALL_INSTALLED":
    # Get all installed applications
    apps = AdminApp.list().splitlines()
    # Print the role mappings
    for app in apps:
        print "Application: " + app
        print AdminApp.view(app, ['-MapRolesToUsers'])
        print "================================================================================"
else:
    print "Application: " + scope
    print AdminApp.view(scope, ['-MapRolesToUsers'])
    print "================================================================================"
