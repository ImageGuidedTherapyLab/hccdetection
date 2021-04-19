SHELL := /bin/bash
-include lrbcm256kfold009.makefile
WORKDIR=$(TRAININGROOT)/bcmdata
DATADIR=$(TRAININGROOT)/datalocation/train
mask:        $(addprefix $(WORKDIR)/,$(addsuffix /unet/mask.nii.gz,$(UIDLIST)))
normalize:   $(addprefix $(WORKDIR)/,$(addsuffix /Ven.normalize.nii.gz,$(UIDLIST)))
normroi:     $(addprefix $(WORKDIR)/,$(addsuffix /Ven.normroi.nii.gz,$(UIDLIST)))
roi:         $(addprefix $(WORKDIR)/,$(addsuffix /Ven.roi.nii.gz,$(UIDLIST)))
combine:     $(addprefix $(DATADIR)/,$(addsuffix /TruthVen6.nii.gz,$(UIDLIST)))
labels:      $(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/lirads.nii.gz,$(UIDLIST)))
labelsmrf:   $(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/tumormrf.nii.gz,$(UIDLIST)))
labelsmedian:$(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/tumormedian.nii.gz,$(UIDLIST)))
lstat:       $(addprefix    qastats/,$(addsuffix /lstat.sql,$(UIDLIST)))
overlap:     $(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/overlap.sql,$(UIDLIST)))
overlappost: $(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/overlapmrf.sql,$(UIDLIST))) $(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/overlapmedian.sql,$(UIDLIST)))
reviewsoln:  $(addprefix $(WORKDIR)/,$(addsuffix /reviewsoln,$(UIDLIST)))
C3DEXE=/rsrch2/ip/dtfuentes/bin/c3d
# keep tmp files
.SECONDARY: 

LIRADSLIST = BCM0001001 BCM0001002 BCM0002001 BCM0002002 BCM0015002 BCM0016002 BCM0017001 BCM0017002 BCM0018003 BCM0018004 BCM0019001 BCM0019002 BCM0020001 BCM0020002 BCM0021001 BCM0021003 BCM0022001 BCM0022002
viewlirads: $(addprefix bcmdata/,$(addsuffix /viewlirads,$(LIRADSLIST)))  
trainlirads: $(addprefix bcmlirads/,$(addsuffix lrtrain.nii.gz,$(LIRADSLIST)))  
multiphaselirads: $(addprefix bcmdata/,$(addsuffix /multiphase.nii.gz,$(LIRADSLIST)))  
bcmlirads/%lrtrain.nii.gz: bcmlirads/%fixed.train.nii.gz bcmdata/%/fixed.liver.nii.gz
	c3d $< $(word 2,$^) -add -binarize $< -add -replace 6 5 5 4 4 3 3 1 2 1 -o $@
bcmdata/%/viewlirads: 
	echo $*
	c3d bcmlirads/$*fixed.train.nii.gz -info -dup -lstat  -thresh 3 inf  1 0 -comp -lstat
	vglrun itksnap -l labelkey.txt  -g  $(@D)/fixed.raw.nii.gz -s  bcmlirads/$*lrtrain.nii.gz  -o bcmdata/$*/multiphase.nii.gz bcmdata/$*/EPM_3.nii 
bcmdata/%/multiphase.nii.gz: bcmdata/%/Pre.longregcc.nii.gz  bcmdata/%/Art.longregcc.nii.gz  bcmdata/%/Ven.longregcc.nii.gz bcmdata/%/Del.longregcc.nii.gz  bcmdata/%/Pst.longregcc.nii.gz
	c3d $^ -omc $@

bcmdata/%/viewnnlirads: 
	vglrun itksnap -g bcmdata/$*/EPM_3.nii -s bcmdata/$*/lrbcmpocket/lirads.nii.gz -o bcmdata/$*/lrbcmpocket/lirads-?.nii.gz bcmlirads/$*lrtrain.nii.gz


$(TRAININGROOT)/bcmlirads/%-mask.nii.gz: bcmlirads/%fixed.train.nii.gz bcmdata/%/fixed.liver.nii.gz
	c3d $< $(word 2,$^) -add -binarize -o $@
$(TRAININGROOT)/bcmlirads/%-lesionmask.nii.gz: bcmlirads/%fixed.train.nii.gz 
	c3d $< -thresh 3 inf 1 0  -o $@
## intensity statistics
qastats/%/lstat.csv: 
	mkdir -p $(@D)
	$(C3DEXE) $(WORKDIR)/$*/Ven.raw.nii.gz  $(DATADIR)/$*/TruthVen1.nii.gz -replace 2 1 3 1 4 1 5 0  -lstat > $(@D)/lstat.txt &&  sed "s/^\s\+/$(subst /,\/,$*),TruthVen1.nii.gz,Ven.raw.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/lstat.txt > $@

qastats/%/lstat.sql: qastats/%/lstat.csv
	-sqlite3 $(SQLITEDB)  -init .loadcsvsqliterc ".import $< lstat"

$(DATADIR)/%/TruthVen6.nii.gz:
	c3d -verbose $(@D)/TruthVen1.nii.gz -replace 3 2 4 3 5 4 -o $@
	
##$(WORKDIR)/%/Ven.normalize.nii.gz:
##	python ./tissueshift.py --image=$(@D)/Ven.raw.nii.gz --gmm=$(DATADIR)/$*/TruthVen1.nii.gz  

$(WORKDIR)/%/Ven.normroi.nii.gz:
	python ./tissueshift.py --image=$(@D)/Ven.roi.nii.gz --gmm=$(@D)/Truthroi.nii.gz  

$(WORKDIR)/%/Ven.roi.nii.gz: 
	python ./liverroi.py --image=$(@D)/Ven.raw.nii.gz --gmm=$(DATADIR)/$*/TruthVen6.nii.gz --outputdir=$(@D)

$(WORKDIR)/%/$(DATABASEID)/tumormrf.nii.gz:
	c3d -verbose $(@D)/tumor-1.nii.gz -scale .5 $(@D)/tumor-[2345].nii.gz -vote-mrf  VA .1 -o $@

$(WORKDIR)/%/$(DATABASEID)/tumormedian.nii.gz:
	c3d -verbose $(@D)/tumor.nii.gz -median 1x1x1 -o $@

$(WORKDIR)/%/$(DATABASEID)/overlapmrf.csv: $(WORKDIR)/%/$(DATABASEID)/tumormrf.nii.gz
	$(C3DEXE) $(DATADIR)/$*/TruthVen1.nii.gz  -as A $< -as B -overlap 1 -overlap 2 -overlap 3 -overlap 4  -overlap 5  > $(@D)/overlap.txt
	grep "^OVL" $(@D)/overlap.txt  |sed "s/OVL: \([0-9]\),/\1,$(subst /,\/,$*),/g;s/OVL: 1\([0-9]\),/1\1,$(subst /,\/,$*),/g;s/^/TruthVen1.nii.gz,tumormrf,/g;"  | sed "1 i FirstImage,SecondImage,LabelID,InstanceUID,MatchingFirst,MatchingSecond,SizeOverlap,DiceSimilarity,IntersectionRatio" > $@

$(WORKDIR)/%/overlapmrf.sql: $(WORKDIR)/%/overlapmrf.csv
	-sqlite3 $(SQLITEDB)  -init .loadcsvsqliterc ".import $< overlap"

## dice statistics
$(WORKDIR)/%/$(DATABASEID)/overlap.csv: $(WORKDIR)/%/$(DATABASEID)/tumor.nii.gz
	mkdir -p $(@D)
	$(C3DEXE) $<  -as A $(DATADIR)/$*/TruthVen1.nii.gz -as B -overlap 1 -overlap 2 -overlap 3 -overlap 4  -thresh 2 3 1 0 -comp -as C  -clear -push C -replace 0 255 -split -pop -foreach -push B -multiply -insert A 1 -overlap 1 -overlap 2 -overlap 3 -overlap 4 -pop -endfor
	grep "^OVL" $(@D)/overlap.txt  |sed "s/OVL: \([0-9]\),/\1,$(subst /,\/,$*),/g;s/OVL: 1\([0-9]\),/1\1,$(subst /,\/,$*),/g;s/^/TruthVen1.nii.gz,$(DATABASEID)\/tumor.nii.gz,/g;"  | sed "1 i FirstImage,SecondImage,LabelID,InstanceUID,MatchingFirst,MatchingSecond,SizeOverlap,DiceSimilarity,IntersectionRatio" > $@

$(WORKDIR)/%/overlap.sql: $(WORKDIR)/%/overlap.csv
	-sqlite3 $(SQLITEDB)  -init .loadcsvsqliterc ".import $< overlap"

$(WORKDIR)/%/reviewsoln: 
	vglrun itksnap -g $(WORKDIR)/$*/Ven.raw.nii.gz -s $(DATADIR)/$*/TruthVen1.nii.gz & vglrun itksnap -g $(WORKDIR)/$*/Ven.raw.nii.gz -s $(WORKDIR)/$*/$(DATABASEID)/tumor.nii.gz ;\
        pkill -9 ITK-SNAP



