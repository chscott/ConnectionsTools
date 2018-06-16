import sys

# The first argument is the required community name
try:
    community = sys.argv[0]
except (IndexError):
    print 'Usage:'
    print 'wsadmin -f getCommSize.py <community name>'
    sys.exit(1)

# Enable batch mode so there will be no prompt to connect to a particular service
batchMode = 1

# Exec the prereq files
execfile('communitiesAdmin.py')
execfile('filesAdmin.py')
execfile('wikisAdmin.py')

print 'Community Name:\t' + community

# Get the community UUID
commUuid = None
try:
    commUuid = CommunitiesService.fetchCommByName(community)[0]['uuid']
except:
    print 'ERROR: Unable to retrieve community. Exiting.' 
    sys.exit(1)
else:
    print 'Community UUID:\t' + commUuid

# Get the Files library size
filesLibId = None
filesLibSize = None
try:
    filesLibId = FilesLibraryService.getByExternalContainerId(commUuid)['id']
    filesLibSize = FilesLibraryService.getById(filesLibId)['size']
except:
    print 'WARNING: Unable to retrieve Files library information. Community may not have the Files app installed.'

# Get the Wikis library size
wikisLibId = None
wikisLibSize = None
try:
    wikisLibId = WikisLibraryService.getByExternalContainerId(commUuid)['id']
    wikisLibSize = WikisLibraryService.getById(wikisLibId)['size']
except:
    print 'WARNING: Unable to retrieve Wikis library information. Community may not have the Wikis app installed.'

if filesLibSize is not None:
    print 'Files size:\t' + str(filesLibSize) + ' bytes'
else:
    print 'Files size:\t' + 'Not detected'
if wikisLibSize is not None:
    print 'Wikis size:\t' + str(wikisLibSize) + ' bytes'
else:
    print 'Wikis size:\t' + 'Not detected'
if filesLibSize is not None and wikisLibSize is not None:
    print 'Total size:\t' + str((filesLibSize + wikisLibSize) / 1024 / 1024) + ' MB'
elif filesLibSize is not None:
    print 'Total size:\t' + str(filesLibSize / 1024 / 1024) + ' MB'
elif wikissLibSize is not None:
    print 'Total size:\t' + str(wikisLibSize / 1024 / 1024) + ' MB'
