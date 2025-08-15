SHELL := /bin/bash
LISTID       = $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 )
LISTOUTCOME  = $(shell sed 1d 3dtrainingdx.csv | cut -d, -f3 )
LISTIMAGE    = $(shell sed 1d 3dtrainingdx.csv | cut -d, -f4 )
LISTLABEL    = $(shell sed 1d 3dtrainingdx.csv | cut -d, -f5 )
LISTTRAIN    = $(shell sed 1d 3dtrainingdx.csv | cut -d, -f6 )

dbg:
	echo $(LISTOUTCOME)
raw:   $(addprefix svdnetwork/,$(addsuffix /image.nii,$(LISTID))) 
info:   $(addprefix svdnetwork/,$(addsuffix /info,$(LISTID))) 

svdnetwork/%/info:
	c3d $(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTIMAGE)) -info  $(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTLABEL)) -info  $(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTTRAIN)) -info

svdnetwork/%/image.nii:
	echo $*
	mkdir -p svdnetwork/$(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTOUTCOME))
	echo c3d $(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTIMAGE)) $(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTLABEL)) -binarize -multiply -o svdnetwork/$(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTOUTCOME))/$*.nii
	python epmboundingbox.py --imagefile=$(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTIMAGE)) --labelfile=$(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTLABEL))  --trainfile=$(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTTRAIN)) --output=svdnetwork/$(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTOUTCOME))/$* --datatype=float
