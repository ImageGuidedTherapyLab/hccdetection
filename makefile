SHELL := /bin/bash
WORKDIR=anonymize
#
# Defaults
#
MATLABROOT      := /opt/apps/matlab/R2020a/
MEX=$(MATLABROOT)/bin/mex
MCC=$(MATLABROOT)/bin/mcc
applymodel: applymodel.m
	$(MCC) -d './' -R -nodisplay -R '-logfile,./matlab.log' -S -v -m $^ $(CTF_ARCHIVE)  -o $@
tags: 
	ctags -R *
CTF_ARCHIVE=$(addprefix -a ,$(SOURCE_FILES))
SOURCE_FILES  = dicePixelClassification3dLayer.m segmentImagePatchwise.m

IMAGEFILELIST = image.nii label.nii

# setup MRI data
DATADIRMRI=/Radonc/Cancer\ Physics\ and\ Engineering\ Lab/Matthew\ Cagley/HCC\ MRI\ Cases/
include datalocation/dependencies
MRILIST  = $(shell sed 1d datalocation/trainingdatakey.csv | cut -d, -f2 )
ANONLIST = $(shell sed 1d datalocation/trainingdatakey.csv | cut -d, -f1 )
art:   $(addprefix Processed/,$(addsuffix /Art.raw.nii.gz,$(MRILIST)))  
pre:   $(addprefix Processed/,$(addsuffix /Pre.raw.nii.gz,$(MRILIST)))  
ven:   $(addprefix Processed/,$(addsuffix /Ven.raw.nii.gz,$(MRILIST)))  
truth: $(addprefix Processed/,$(addsuffix /Truth.raw.nii.gz,$(MRILIST)))  
viewraw: $(addprefix Processed/,$(addsuffix /viewraw,$(MRILIST)))  
COUNT := $(words $(MRILIST))
SEQUENCE = $(shell seq $(COUNT))
anon: $(foreach idfile,$(IMAGEFILELIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idfile),$(ANONLIST)))) 
$(WORKDIR)/hcc%/image.nii:
	echo ln -sf ../Processed/$(word $*, $(MRILIST)) $(@D)
	c3d Processed/$(word $*, $(MRILIST))/Art.raw.nii.gz  -o $@
$(WORKDIR)/hcc%/label.nii:
	c3d Processed/$(word $*, $(MRILIST))/Truth.raw.nii.gz  -o $@
%/Art.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIRMRI)/$(word 2,$(subst /, ,$*))/ART $@
%/Ven.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIRMRI)/$(word 2,$(subst /, ,$*))/PV $@
%/Pre.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIRMRI)/$(word 2,$(subst /, ,$*))/PRE $@
%/Truth.raw.nii.gz: %/Art.raw.nii.gz
	mkdir -p $(@D)
	plastimatch convert --fixed $(@D)/Art.raw.nii.gz  --output-labelmap $@ --output-ss-img $(@D)/ss.nii.gz --output-ss-list $(@D)/ss.txt --output-dose-img $(@D)/dose.nii.gz --input $(DATADIRMRI)/$(word 2,$(subst /, ,$*))/ART/RTSTRUCT*.dcm 
%/viewraw: 
	c3d $(@D)/Pre.raw.nii.gz -info  $(@D)/Ven.raw.nii.gz -info $(@D)/Art.raw.nii.gz -info   $(@D)/Truth.raw.nii.gz  -info
	vglrun itksnap -g  $(@D)/Art.raw.nii.gz -s  $(@D)/Truth.raw.nii.gz  -o $(@D)/Ven.raw.nii.gz $(@D)/Pre.raw.nii.gz
# art and ven input
washout: $(foreach idfile,$(IMAGEFILELIST),$(addprefix $(WORKDIR)/washout,$(addsuffix /$(idfile),$(ANONLIST)))) 
$(WORKDIR)/washouthcc%/image.nii:
	mkdir -p $(@D)
	c3d Processed/$(word $*, $(MRILIST))/Art.raw.nii.gz Processed/$(word $*, $(MRILIST))/Ven.raw.nii.gz  -omc $@
$(WORKDIR)/washouthcc%/label.nii:
	mkdir -p $(@D)
	c3d Processed/$(word $*, $(MRILIST))/Truth.raw.nii.gz -type uchar -o $@

# setup CRC data
CRCLIST       = $(shell sed 1d crctrainingdata.csv | cut -f1 )
CRCIMAGELIST  = $(shell sed 1d crctrainingdata.csv | cut -f3 )
CRCLABELLIST  = $(shell sed 1d crctrainingdata.csv | cut -f4 )
DATADIRCRC=/rsrch1/ip/jacctor/LiTS/LiTS/
crcsetup: $(addprefix $(WORKDIR)/,$(addsuffix /image.nii,$(CRCLIST)))  $(addprefix $(WORKDIR)/,$(addsuffix /label.nii,$(CRCLIST)))  
$(WORKDIR)/i%/image.nii:
	mkdir -p $(@D)
	cp $(DATADIRCRC)/$(word $(shell expr $* + 1 ), $(CRCIMAGELIST)) $@
$(WORKDIR)/i%/label.nii:
	mkdir -p $(@D)
	cp $(DATADIRCRC)/$(word $(shell expr $* + 1 ), $(CRCLABELLIST)) $@
# mask the liver to segment the tumor
crctumor: $(addprefix $(WORKDIR)/crctumor,$(addsuffix /setup,$(CRCLIST)))
$(WORKDIR)/crctumori%/setup:
	mkdir -p $(@D)
	python liverboundingbox.py --imagefile=$(DATADIRCRC)/$(word $(shell expr $* + 1 ), $(CRCIMAGELIST)) --labelfile=$(DATADIRCRC)/$(word $(shell expr $* + 1 ), $(CRCLABELLIST))  --output=$(@D)
	c3d -verbose $(@D)/label.nii -thresh 2 2 1 0 -connected-components -o  $(@D)/comp.nii.gz
	python tumorboundingbox.py --imagefile=$(@D)/maskimage.nii --labelfile=$(@D)/comp.nii.gz --output=$(@D)

# setup CT HCC data
HCCCTLIST       = $(shell sed 1d datalocation/cthccdatakey.csv | cut -f2 )
HCCCTIMAGELIST  = $(shell sed 1d datalocation/cthccdatakey.csv | cut -f3 )
HCCCTLABELLIST  = $(shell sed 1d datalocation/cthccdatakey.csv | cut -f5 )
DATADIRHCCCT=/rsrch1/ip/dtfuentes/github/RandomForestHCCResponse/
hccctsetup: $(addprefix $(WORKDIR)/,$(addsuffix /image.nii,$(HCCCTLIST)))  $(addprefix $(WORKDIR)/,$(addsuffix /label.nii,$(HCCCTLIST)))  
$(WORKDIR)/ct%/image.nii:
	mkdir -p $(@D)
	echo $*
	cp $(DATADIRHCCCT)/$(word $*, $(HCCCTIMAGELIST)) $@
$(WORKDIR)/ct%/label.nii:
	mkdir -p $(@D)
	echo $*
	cp $(DATADIRHCCCT)/$(word $*, $(HCCCTLABELLIST)) $@

# keep tmp files
.SECONDARY: 



-include hccmrikfold005.makefile

#DATALIST = $(ANONLIST) $(addprefix washout,$(ANONLIST)) $(HCCCTLIST) $(CRCLIST) $(addprefix crctumor,$(CRCLIST)) 
#DATALIST = $(ANONLIST) $(addprefix washout,$(ANONLIST)) $(CRCLIST) $(addprefix crctumor,$(CRCLIST)) 
DATALIST = $(addprefix crctumor,$(CRCLIST)) 
print:
	@echo $(DATALIST)

view: $(addprefix $(WORKDIR)/,$(addsuffix /view,$(DATALIST)))  
info: $(addprefix $(WORKDIR)/,$(addsuffix /info,$(DATALIST)))  
lstat: $(addprefix $(WORKDIR)/,$(addsuffix /lstat.sql,$(DATALIST)))  

resize: $(addprefix $(WORKDIR)/,$(addsuffix /crop/Truth.nii,$(DATALIST)))   \
        $(addprefix $(WORKDIR)/,$(addsuffix /scaled/crop/Volume.nii,$(DATALIST)))  
scaled:   $(addprefix $(WORKDIR)/,$(addsuffix /scaled/normalize.nii,$(DATALIST)))  

#MODELLIST = scaled/256/unet2d scaled/256/unet3d scaled/256/densenet2d scaled/256/densenet3d scaled/512/densenet2d scaled/512/unet2d
#APPLYLIST=$(UIDLIST0) $(UIDLIST1) $(UIDLIST2) $(UIDLIST3) $(UIDLIST4) 
#MODELLIST = scaled/256/unet2d/run_a scaled/256/unet3d/run_a scaled/256/densenet2d/run_a scaled/256/densenet3d/run_a 
APPLYLIST=$(UIDLIST20) $(UIDLIST21) $(UIDLIST22) $(UIDLIST23) $(UIDLIST24) 
#MODELLIST = scaled/256/unet2d/crctumor scaled/256/unet3d/crctumor scaled/256/densenet2d/crctumor scaled/256/densenet3d/crctumor 
MODELLIST = scaled/256/unet2d/crctumor 
#APPLYLIST=$(UIDLIST25) $(UIDLIST26) $(UIDLIST27) $(UIDLIST28) $(UIDLIST29) 

mask:     $(foreach idmodel,$(MODELLIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idmodel)/label.nii.gz,$(APPLYLIST)))) 
liver:    $(foreach idmodel,$(MODELLIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idmodel)/liver.nii.gz,$(APPLYLIST)))) 
overlap:  $(foreach idmodel,$(MODELLIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idmodel)/overlap.sql,$(APPLYLIST)))) 


## pre processing
%/scaled/normalize.nii: 
	mkdir -p $(@D)
	python normalization.py --imagefile=$*/image.nii  --output=$@
# FIXME - note this rule is repeated
# https://www.gnu.org/software/make/manual/html_node/Multiple-Rules.html
# If more than one rule gives a recipe for the same file, make uses the last one given
# https://www.gnu.org/software/make/manual/html_node/Pattern-Match.html#Pattern-Match
# It is possible that more than one pattern rule will meet these criteria. In that case, make will choose the rule with the shortest stem (that is, the pattern that matches most specifically). If more than one pattern rule has the shortest stem, make will choose the first one found in the makefile.
$(WORKDIR)/crctumor%/scaled/crop/Volume.nii: $(WORKDIR)/crctumor%/image.nii
	mkdir -p $(@D)
	python crop.py --imagefile=$<  --output=$@

$(WORKDIR)/crctumor%/scaled/256/Volume.nii: $(WORKDIR)/crctumor%/scaled/crop/Volume.nii
	mkdir -p $(@D); 
	python resample.py --imagefile=$<  --output=$@tmp
	c3d -verbose %s -dup %s -info -copy-transform -info -binarize -foreach -type short -endfor -omc $@
$(WORKDIR)/crctumor%/scaled/256/Volume.dir: $(WORKDIR)/crctumor%/scaled/crop/Volume.nii
	python tumorboundingbox.py 

%/scaled/crop/Volume.nii: %/scaled/normalize.nii
	mkdir -p $(@D)
	python crop.py --imagefile=$<  --output=$@
%/scaled/256/Volume.nii: %/scaled/crop/Volume.nii
	mkdir -p $(@D)
	python resample.py --imagefile=$<  --output=$@
%/scaled/512/Volume.nii: %/scaled/crop/Volume.nii
	mkdir -p $(@D)
	python resample.py --imagefile=$<  --output=$@
%/crop/Truth.nii: 
	mkdir -p $*/crop; mkdir -p $*/256; mkdir -p $*/512;
	python resize.py --imagefile=$*/label.nii  --output=$@ --datatype=uchar --interpolation=nearest

%/view: 
	c3d  $(@D)/image.nii -info   $(@D)/label.nii  -info
	vglrun itksnap -g  $(@D)/image.nii  -s  $(@D)/tumor.nii.gz

%/info: %/Art.raw.nii.gz  %/Art.scaled.nii
	c3d $< -info $(word 2,$^) -info

## clean up mask 
%/liver.nii.gz: %/label.nii.gz 
	c3d -verbose $<  -thresh 2 2 1 0 -connected-components   -thresh 1 1 1 0 -o $@

## label statistics
$(WORKDIR)/%/lstat.csv: $(WORKDIR)/%/image.nii $(WORKDIR)/%/label.nii
	echo $*
	c3d $^ -lstat > $(@D)/lstat.txt &&  sed "s/^\s\+/$*,label.nii,image.nii,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/lstat.txt  > $@

$(WORKDIR)/%/lstat.sql: $(WORKDIR)/%/lstat.csv
	-sqlite3 $(SQLITEDB)  -init .loadcsvsqliterc ".import $< lstat"

## dice statistics
$(WORKDIR)/%/overlap.csv: $(WORKDIR)/%/liver.nii.gz
	echo $*
	c3d $(WORKDIR)/$(firstword $(subst /, ,$*))/$(word 3 ,$(subst /, ,$*))/Truth.nii $< -overlap 1 > $(@D)/overlap.txt 
	grep "^OVL" $(@D)/overlap.txt  |sed "s/OVL: \([0-9]\),/\1,$(subst /,.,$*),/g;s/OVL: 1\([0-9]\),/1\1,$(subst /,.,$*),/g;s/^/Truth.nii,liver.nii.gz,/g;"  | sed "1 i FirstImage,SecondImage,LabelID,InstanceUID,MatchingFirst,MatchingSecond,SizeOverlap,DiceSimilarity,IntersectionRatio" > $@

$(WORKDIR)/%/overlap.sql: $(WORKDIR)/%/overlap.csv
	-sqlite3 $(SQLITEDB)  -init .loadcsvsqliterc ".import $< overlap"

overlap.csv: 
	-sqlite3 $(SQLITEDB)  -init .exportoverlap  ".quit"
