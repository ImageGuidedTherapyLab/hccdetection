import csv
import os
import re
with open('methodistdb/wideformat.csv') as csvfile:
    myreader = csv.reader(csvfile, delimiter=',')
    next(myreader, None)  # skip the headers
    dirfilepaths = [ (row[0],row[9]) for row in myreader]

for (ptidtmp,idir) in dirfilepaths :
    linuxpath = idir.replace('X:','/Radonc')
    mysplitcmd = '/rsrch3/ip/dtfuentes/github/anonymizationtransfer/DicomSeriesReadSplitSeriesWrite "%s" "%s_"' % (linuxpath ,linuxpath[:-1] )
    print(mysplitcmd)
    os.system(mysplitcmd)
    mymatch = re.search(r'(?<=LAB)\d+', ptidtmp)
    #if mymatch  == None:
    #  ptid = ptidtmp
    #else:
    ptid = 'LAB'+mymatch.group(0)
    for idseries in range(4):
       updateptidcmd = 'for idfile in "%s_%d/"*.dcm ; do echo "$idfile" ; dcmodify -nb -i "(0010,0020)=%s" -i "(0010,0010)=%s" "$idfile"   ; done' % (linuxpath[:-1],idseries,ptid,ptid)
       print(updateptidcmd )
       os.system(updateptidcmd )
