
import csv
import os
with open('methodistdb/wideformat.csv') as csvfile:
    myreader = csv.reader(csvfile, delimiter=',')
    next(myreader, None)  # skip the headers
    dirfilepaths = [ row[9] for row in myreader]

for idir in dirfilepaths :
    linuxpath = idir.replace('X:','/Radonc')
    mysplitcmd = '/rsrch3/ip/dtfuentes/github/anonymizationtransfer/DicomSeriesReadSplitSeriesWrite "%s" "%s_"' % (linuxpath ,linuxpath[:-1] )
    print(mysplitcmd)
    os.system(mysplitcmd)
