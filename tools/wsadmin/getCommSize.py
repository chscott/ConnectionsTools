import sys

# The first argument is required
try:
    community = sys.argv[0]
except (IndexError):
    print 'Usage:'
    print 'wsadmin -f getCommSize.py <community name>'
    sys.exit(1)

# Exec the prereq files
execfile('communitiesAdmin.py')
execfile('filesAdmin.py')
execfile('wikisAdmin.py')

print 'Getting size information for community: [' + community + ']'

# Get the community UUID
print 'Getting community UUID...'
try:
    commUuid = CommunitiesService.fetchCommByName(community)[0]['uuid']
except:
    print 'ERROR: Unable to retrieve community. Exiting.' 
    sys.exit(1)
else:
    print 'Community UUID: [' + commUuid + ']' 

# Get the Files library size
print 'Getting Files library size...'
try:
    filesLibId = FilesLibraryService.getByExternalContainerId(commUuid)['id']
    filesLibSize = FilesLibraryService.getById(filesLibId)['size']
except:
    print 'WARNING: Unable to retrieve Files library information. Community may not have the Files app installed.'

# Get the Wikis library size
print 'Getting Wikis library size...'
try:
    wikisLibId = WikisLibraryService.getByExternalContainerId(commUuid)['id']
    wikisLibSize = WikisLibraryService.getById(wikisLibId)['size']
except:
    print 'WARNING: Unable to retrieve Wikis library information. Community may not have the Wikis app installed.'

print 'Files library:\t' + str(filesLibSize) + ' bytes'
print 'Wikis library:\t' + str(wikisLibSize) + ' bytes'
print 'Total:\t' + str((filesLibSize + wikisLibSize) / 1024 / 1024) + ' MB'

