SHELL := /bin/bash
LISTID       = $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 )
LISTOUTCOME  = $(shell sed 1d 3dtrainingdx.csv | cut -d, -f3 )
LISTIMAGE    = $(shell sed 1d 3dtrainingdx.csv | cut -d, -f4 )
LISTLABEL    = $(shell sed 1d 3dtrainingdx.csv | cut -d, -f5 )

dbg:
	echo $(LISTOUTCOME)
raw:   $(addprefix svdnetwork/,$(addsuffix /image.nii.gz,$(LISTID))) 


svdnetwork/%/image.nii.gz:
	echo $*
	mkdir -p svdnetwork/$(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTOUTCOME))
	c3d $(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTIMAGE)) $(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTLABEL)) -binarize -multiply -o svdnetwork/$(word $(shell sed 1d 3dtrainingdx.csv | cut -d, -f2 | grep -n '^$*' |cut -f1 -d: ), $(LISTOUTCOME))/$*.nii
