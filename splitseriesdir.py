import csv
import os
import re
with open('methodistdb/wideformat.csv') as csvfile:
    myreader = csv.reader(csvfile, delimiter=',')
    next(myreader, None)  # skip the headers
    dirfilepaths = [ (row[0],row[9],row[10]) for row in myreader]

for (ptidtmp,idir,postdir) in dirfilepaths :
    linuxpath = idir.replace('X:','/Radonc')
    linuxstudy = "/".join(list(filter(len,linuxpath.split('/')))[:-1])
    linuxseries = list(filter(len,linuxpath.split('/')))[-1]
    myoutputdir = '/%s/raystation/%s' % (linuxstudy ,linuxseries)
    mysplitcmd = '/rsrch3/ip/dtfuentes/github/anonymizationtransfer/DicomSeriesReadSplitSeriesWrite "%s" "%s_"' % (linuxpath ,myoutputdir  )
    print(mysplitcmd)
    os.system(mysplitcmd)
    mymatch = re.search(r'(?<=LAB)\d+', ptidtmp)
    #if mymatch  == None:
    #  ptid = ptidtmp
    #else:
    ptid = 'LAB'+mymatch.group(0)
    for idseries in range(4):
       updateptidcmd = 'for idfile in "%s_%d/"*.dcm ; do echo "$idfile" ; dcmodify -nb -i "(0010,0020)=%s" -i "(0010,0010)=%s" -i "(0008,103e)=liverprotocol%d" "$idfile"   ; done' % (myoutputdir,idseries,ptid,ptid,idseries)
       print(updateptidcmd )
       os.system(updateptidcmd )
    pstlinuxpath = postdir.replace('X:','/Radonc')
    pstseries = list(filter(len,pstlinuxpath.split('/')))[-1]
    pstoutputdir = '/%s/raystation/%s' % (linuxstudy ,pstseries )
    pstupdateptidcmd = 'mkdir -p "%s_a"; for idfile in "%s/"* ; do echo "$idfile" ;cp "$idfile" "%s_a"/$(basename "$idfile").dcm; dcmodify -nb -i "(0010,0020)=%s" -i "(0010,0010)=%s" "%s_a"/$(basename "$idfile").dcm ; done' % (pstoutputdir,pstlinuxpath,pstoutputdir ,ptid,ptid,pstoutputdir )
    print(pstupdateptidcmd )
    os.system(pstupdateptidcmd )
