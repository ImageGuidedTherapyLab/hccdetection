SHELL := /bin/bash
WORKDIR=Processed
DATADIR=/Radonc/Cancer\ Physics\ and\ Engineering\ Lab/Matthew\ Cagley/HCC\ MRI\ Cases/

-include datalocation/dependencies
-include hccmri512kfold005.makefile

art: $(addprefix $(WORKDIR)/,$(addsuffix /Art.raw.nii.gz,$(UIDLIST)))  
pre: $(addprefix $(WORKDIR)/,$(addsuffix /Pre.raw.nii.gz,$(UIDLIST)))  
ven: $(addprefix $(WORKDIR)/,$(addsuffix /Ven.raw.nii.gz,$(UIDLIST)))  
truth: $(addprefix $(WORKDIR)/,$(addsuffix /Truth.raw.nii.gz,$(UIDLIST)))  
view: $(addprefix $(WORKDIR)/,$(addsuffix /view,$(UIDLIST)))  
info: $(addprefix $(WORKDIR)/,$(addsuffix /info,$(UIDLIST)))  
lstat: $(addprefix $(WORKDIR)/,$(addsuffix /lstat.csv,$(UIDLIST)))  

resize: $(addprefix $(WORKDIR)/,$(addsuffix /Truth.resize.nii,$(UIDLIST)))   \
        $(addprefix $(WORKDIR)/,$(addsuffix /Art.resize.nii.gz,$(UIDLIST)))  
scaled:   $(addprefix $(WORKDIR)/,$(addsuffix /Art.scaled.nii,$(UIDLIST)))  

mask:        $(addprefix $(WORKDIR),$(addsuffix /unet3d/label.nii.gz,$(UIDLIST)))
overlap:     $(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/overlap.sql,$(UIDLIST)))
combined: $(addprefix $(WORKDIR)/,$(addsuffix /Art.combined.nii.gz,$(UIDLIST)))  

%/Art.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIR)/$(word 2,$(subst /, ,$*))/ART $@
%/Ven.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIR)/$(word 2,$(subst /, ,$*))/PV $@
%/Pre.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIR)/$(word 2,$(subst /, ,$*))/PRE $@
%/Truth.raw.nii.gz: %/Art.raw.nii.gz
	mkdir -p $(@D)
	plastimatch convert --fixed $(@D)/Art.raw.nii.gz  --output-labelmap $@ --output-ss-img $(@D)/ss.nii.gz --output-ss-list $(@D)/ss.txt --output-dose-img $(@D)/dose.nii.gz --input $(DATADIR)/$(word 2,$(subst /, ,$*))/ART/RTSTRUCT*.dcm 

# Data set with a valid size for 3-D U-Net (multiple of 8)
%/Art.resize.nii.gz: %/Art.raw.nii.gz
	python resize.py --imagefile=$<  --output=$@

%/Truth.resize.nii: %/Truth.raw.nii.gz
	python resize.py --imagefile=$<  --output=$@

## pre processing
%/Art.scaled.nii: %/Art.resize.nii.gz
	python normalization.py --imagefile=$<  --output=$@
%/Art.combined.nii.gz: %/Art.scaled.nii.gz %/Truth.nii.gz
	c3d $^ -binarize  -omc $@

%/view: 
	c3d  $(@D)/Art.raw.nii.gz  -info   $(@D)/Truth.raw.nii.gz  -info
	vglrun itksnap -g  $(@D)/Art.raw.nii.gz  -s  $(@D)/Truth.raw.nii.gz 

%/info: %/Art.raw.nii.gz
	c3d $< -info 
%/lstat.csv: %/Art.raw.nii.gz %/Truth.nii.gz
	c3d $^ -lstat > $(@D)/lstat.txt &&  sed "s/^\s\+/$(word 3 ,$(subst /, ,$*)),$(MODELID)$(word 7 ,$(subst /, ,$*)),$(word 5 ,$(subst /, ,$*)),/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/lstat.txt  > $@


## dice statistics
$(WORKDIR)/%/$(DATABASEID)/overlap.csv: $(WORKDIR)/%/$(DATABASEID)/tumor.nii.gz
	mkdir -p $(@D)
	$(C3DEXE) $<  -as A $(DATADIR)/$*/TruthVen1.nii.gz -as B -overlap 1 -overlap 2 -overlap 3 -overlap 4  -thresh 2 3 1 0 -comp -as C  -clear -push C -replace 0 255 -split -pop -foreach -push B -multiply -insert A 1 -overlap 1 -overlap 2 -overlap 3 -overlap 4 -pop -endfor
	grep "^OVL" $(@D)/overlap.txt  |sed "s/OVL: \([0-9]\),/\1,$(subst /,\/,$*),/g;s/OVL: 1\([0-9]\),/1\1,$(subst /,\/,$*),/g;s/^/TruthVen1.nii.gz,$(DATABASEID)\/tumor.nii.gz,/g;"  | sed "1 i FirstImage,SecondImage,LabelID,InstanceUID,MatchingFirst,MatchingSecond,SizeOverlap,DiceSimilarity,IntersectionRatio" > $@

$(WORKDIR)/%/overlap.sql: $(WORKDIR)/%/overlap.csv
	-sqlite3 $(SQLITEDB)  -init .loadcsvsqliterc ".import $< overlap"

