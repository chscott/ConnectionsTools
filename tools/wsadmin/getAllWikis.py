from java.util import ArrayList

batchSize = 100

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

# Initialize Wikis administration
execfile('wikisAdmin.py')

# Open output file for writing
fd = None
if outfile is not None:
    try:
        fd = open(outfile, 'w')
    except:
        print('Unable to create file. Printing to stdout')

# Get the count of wikis
numWikis = WikisLibraryService.getWikiCount()

# Get the number of batches
if numWikis % batchSize is 0:
    numBatches = numWikis / batchSize
else:
    numBatches = (numWikis / batchSize) + 1  

# Loop through the batches
for i in range(1, numBatches + 1):
    batch = WikisLibraryService.browseWiki('title', 'true', i, batchSize)
    # Loop through each wiki in the batch and print the title
    for wiki in batch:
        log(fd, wiki['title'])

# Close the output file
if fd is not None:
    fd.close()
