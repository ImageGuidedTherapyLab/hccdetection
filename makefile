SHELL := /bin/bash
WORKDIR=Processed
DATADIR=/Radonc/Cancer\ Physics\ and\ Engineering\ Lab/Matthew\ Cagley/HCC\ MRI\ Cases/

-include datalocation/dependencies

art: $(addprefix $(WORKDIR)/,$(addsuffix /Art.raw.nii.gz,$(UIDLIST)))  
scaled: $(addprefix $(WORKDIR)/,$(addsuffix /Art.scaled.nii.gz,$(UIDLIST)))  
pre: $(addprefix $(WORKDIR)/,$(addsuffix /Pre.raw.nii.gz,$(UIDLIST)))  
ven: $(addprefix $(WORKDIR)/,$(addsuffix /Ven.raw.nii.gz,$(UIDLIST)))  
truth: $(addprefix $(WORKDIR)/,$(addsuffix /Truth.nii.gz,$(UIDLIST)))  
view: $(addprefix $(WORKDIR)/,$(addsuffix /view,$(UIDLIST)))  
info: $(addprefix $(WORKDIR)/,$(addsuffix /info,$(UIDLIST)))  
lstat: $(addprefix $(WORKDIR)/,$(addsuffix /lstat.csv,$(UIDLIST)))  


%/Art.scaled.nii.gz: %/Art.raw.nii.gz
	python normalization.py --imagefile=$< 
%/Art.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIR)/$(word 2,$(subst /, ,$*))/ART $@
%/Ven.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIR)/$(word 2,$(subst /, ,$*))/PV $@
%/Pre.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIR)/$(word 2,$(subst /, ,$*))/PRE $@
%/Truth.nii.gz: %/Art.raw.nii.gz
	mkdir -p $(@D)
	plastimatch convert --fixed $(@D)/Art.raw.nii.gz  --output-labelmap $@ --output-ss-img $(@D)/ss.nii.gz --output-ss-list $(@D)/ss.txt --output-dose-img $(@D)/dose.nii.gz --input $(DATADIR)/$(word 2,$(subst /, ,$*))/ART/RTSTRUCT*.dcm 
%/view: 
	vglrun itksnap -g  $(@D)/Art.raw.nii.gz  -s  $(@D)/Truth.nii.gz 

%/info: %/Art.raw.nii.gz
	c3d $< -info 
%/lstat.csv: %/Art.raw.nii.gz %/Truth.nii.gz
	c3d $^ -lstat > $(@D)/lstat.txt &&  sed "s/^\s\+/$(word 3 ,$(subst /, ,$*)),$(MODELID)$(word 7 ,$(subst /, ,$*)),$(word 5 ,$(subst /, ,$*)),/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/lstat.txt  > $@
