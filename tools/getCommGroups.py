from java.util import ArrayList

def log(fd, string):
    if fd is not None:
        fd.write(string)
    else:
        print(string)

# The first argument is optional and specifies a file for output
outfile = None
try:
    outfile = sys.argv[0]
except (IndexError):
    print('No outfile specified. Printing to stdout')

# Initialize Communities administration
execfile('communitiesAdmin.py')

# Open output file for writing
fd = None
if outfile is not None:
    try:
        fd = open(outfile, 'w')
    except:
        print('Unable to create file. Printing to stdout')

# Get all communities
communities = CommunitiesService.fetchAllComm()

# Get the info for all communities
communitiesInfo = CommunitiesService.fetchMember(communities)

for communityInfo in communitiesInfo:
    communityMembers = communityInfo['memberList']
    for communityMember in communityMembers:
        log(fd, communityMember[0] + ': ' + communityMember[3] + '\n')

# Close the output file
if fd is not None:
    fd.close()
