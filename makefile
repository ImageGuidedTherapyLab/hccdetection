SHELL := /bin/bash
WORKDIR=anonymize
DATADIRMRI=/Radonc/Cancer\ Physics\ and\ Engineering\ Lab/Matthew\ Cagley/HCC\ MRI\ Cases/
MATLABROOT      := /opt/apps/matlab/R2020a/
#
# Defaults
#
MEX=$(MATLABROOT)/bin/mex
MCC=$(MATLABROOT)/bin/mcc
applymodel: applymodel.m
	$(MCC) -d './' -R -nodisplay -R '-logfile,./matlab.log' -S -v -m $^ $(CTF_ARCHIVE)  -o $@
tags: 
	ctags -R *
CTF_ARCHIVE=$(addprefix -a ,$(SOURCE_FILES))
SOURCE_FILES  = dicePixelClassification3dLayer.m segmentImagePatchwise.m


# setup MRI data
MRILIST  = $(shell sed 1d datalocation/trainingdatakey.csv | cut -d, -f2 )
COUNT := $(words $(MRILIST))
ANONLIST = $(shell sed 1d datalocation/trainingdatakey.csv | cut -d, -f1 )
SEQUENCE = $(shell seq $(COUNT))
art:   $(addprefix Processed/,$(addsuffix /Art.raw.nii.gz,$(MRILIST)))  
pre:   $(addprefix Processed/,$(addsuffix /Pre.raw.nii.gz,$(MRILIST)))  
ven:   $(addprefix Processed/,$(addsuffix /Ven.raw.nii.gz,$(MRILIST)))  
truth: $(addprefix Processed/,$(addsuffix /Truth.raw.nii.gz,$(MRILIST)))  
anon:
	$(foreach number, $(SEQUENCE), echo $(word $(number), $(MRILIST)) $(number); ln -sf ../Processed/$(word $(number), $(MRILIST)) anonymize/$(word $(number), $(ANONLIST));)
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

printcrc:
	@echo $(CRCSEQUENCE)
print:
	@echo $(SEQUENCE)
	@echo $(MRILIST)
	@echo $(UIDLIST)
	@echo $(ANONLIST)
	@echo $(CRCLIST)
	@echo $(CRCIMAGELIST)
	@echo $(CRCLABELLIST)
	@echo $(join $(ANONLIST),$(addprefix /,$(MRILIST)))

view: $(addprefix $(WORKDIR)/,$(addsuffix /view,$(UIDLIST)))  
info: $(addprefix $(WORKDIR)/,$(addsuffix /info,$(UIDLIST)))  
lstat: $(addprefix $(WORKDIR)/,$(addsuffix /lstat.csv,$(UIDLIST)))  

resize: $(addprefix $(WORKDIR)/,$(addsuffix /crop/Truth.nii,$(UIDLIST)))   \
        $(addprefix $(WORKDIR)/,$(addsuffix /scaled/crop/Art.nii,$(UIDLIST)))  
scaled:   $(addprefix $(WORKDIR)/,$(addsuffix /scaled/Art.nii.gz,$(UIDLIST)))  

MODELLIST = scaled/256/unet2d scaled/256/unet3d scaled/256/densenet2d scaled/256/densenet3d scaled/512/densenet2d scaled/512/unet2d

mask:     $(foreach idmodel,$(MODELLIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idmodel)/label.nii.gz,$(UIDLIST)))) 
liver:    $(foreach idmodel,$(MODELLIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idmodel)/liver.nii.gz,$(UIDLIST)))) 
overlap:  $(foreach idmodel,$(MODELLIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idmodel)/overlap.sql,$(UIDLIST)))) 
combined: $(addprefix $(WORKDIR)/,$(addsuffix /Art.combined.nii.gz,$(UIDLIST)))  


## pre processing
%/scaled/Art.nii.gz: 
	mkdir -p $(@D)
	python normalization.py --imagefile=$*/Art.raw.nii.gz  --output=$@
# Data set with a valid size for 3-D U-Net (multiple of 8)
%/scaled/crop/Art.nii: %/scaled/Art.nii.gz
	mkdir -p $*/scaled/crop; mkdir -p $*/scaled/256; mkdir -p $*/scaled/512;
	python resize.py --imagefile=$<  --output=$@

%/crop/Truth.nii: 
	mkdir -p $*/crop; mkdir -p $*/256; mkdir -p $*/512;
	python resize.py --imagefile=$*/Truth.raw.nii.gz  --output=$@ --datatype=uchar --interpolation=nearest

%/Art.combined.nii.gz: %/Art.scaled.nii.gz %/Truth.nii.gz
	c3d $^ -binarize  -omc $@

%/view: 
	c3d  $(@D)/Ven.raw.nii.gz  -info $(@D)/Art.raw.nii.gz  -info   $(@D)/Truth.raw.nii.gz  -info
	vglrun itksnap -g  $(@D)/Art.raw.nii.gz  -s  $(@D)/Truth.raw.nii.gz  -o $(@D)/Ven.raw.nii.gz 

%/info: %/Art.raw.nii.gz  %/Art.scaled.nii
	c3d $< -info $(word 2,$^) -info

## clean up mask 
%/liver.nii.gz: %/label.nii.gz 
	c3d -verbose $<  -thresh 2 2 1 0 -connected-components   -thresh 1 1 1 0 -o $@

## label statistics
%/lstat.csv: %/Art.raw.nii.gz %/Truth.raw.nii.gz
	c3d $^ -lstat > $(@D)/lstat.txt &&  sed "s/^\s\+/$(word 3 ,$(subst /, ,$*)),$(MODELID)$(word 7 ,$(subst /, ,$*)),$(word 5 ,$(subst /, ,$*)),/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/lstat.txt  > $@


## dice statistics
%/overlap.csv: %/liver.nii.gz
	c3d $(dir $(<D))/Truth.resample256.nii $< -overlap 1 > $(@D)/overlap.txt 
	grep "^OVL" $(@D)/overlap.txt  |sed "s/OVL: \([0-9]\),/\1,$(subst /,.,$*),/g;s/OVL: 1\([0-9]\),/1\1,$(subst /,.,$*),/g;s/^/Truth.resample256.nii,liver.nii.gz,/g;"  | sed "1 i FirstImage,SecondImage,LabelID,InstanceUID,MatchingFirst,MatchingSecond,SizeOverlap,DiceSimilarity,IntersectionRatio" > $@

$(WORKDIR)/%/overlap.sql: $(WORKDIR)/%/overlap.csv
	-sqlite3 $(SQLITEDB)  -init .loadcsvsqliterc ".import $< overlap"

