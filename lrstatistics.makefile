SHELL := /bin/bash
-include lrbcm256kfold010.makefile
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
overlap:     $(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/overlap.sql,$(UIDLIST)))
overlappost: $(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/overlapmrf.sql,$(UIDLIST))) $(addprefix $(WORKDIR)/,$(addsuffix /$(DATABASEID)/overlapmedian.sql,$(UIDLIST)))
reviewsoln:  $(addprefix $(WORKDIR)/,$(addsuffix /reviewsoln,$(UIDLIST)))
C3DEXE=/rsrch2/ip/dtfuentes/bin/c3d
# keep tmp files
.SECONDARY: 

#LIRADSLIST = BCM0001002 BCM0002001 BCM0015002 BCM0016001 BCM0016002 BCM0017001 BCM0017002 BCM0018003 BCM0018004 BCM0019001 BCM0019002 BCM0020001 BCM0020002 BCM0021001 BCM0021003 BCM0022001 
LIRADSLIST = BCM0001000 BCM0001001 BCM0001002 BCM0001003 BCM0002001 BCM0002002 BCM0003001 BCM0003007 BCM0004000 BCM0005000 BCM0006000 BCM0007000 BCM0008000 BCM0010000 BCM0011000 BCM0013000 BCM0014000 BCM0015000 BCM0015002 BCM0016001 BCM0016002 BCM0017001 BCM0017002 BCM0018003 BCM0018004 BCM0019001 BCM0019002 BCM0020001 BCM0020002 BCM0021001 BCM0021003 BCM0022001 BCM0022002 BCM0025001 BCM0025003 BCM0025004 BCM0027002 BCM0029000 BCM0029001 BCM0031003 BCM0032001 BCM0032002 BCM0033008 BCM0034001 BCM0035005 BCM0036000 BCM0037002 BCM0042011 BCM0042021 BCM0045000 BCM0046008 BCM0047007 BCM0048004 BCM0049011 BCM0050002 BCM0051006 BCM0052013 BCM0054001 BCM0054012 BCM0056005 BCM0059013 BCM0059016 BCM0060014 BCM0061000 BCM0062003 BCM0063002 BCM0064007 BCM0066002 BCM0067001 BCM0068010 BCM0069003 BCM0070000 BCM0071007 BCM0072006 BCM0119000 BCM0144007 BCM0156008 BCM0169024
lstat:       $(addprefix    qastats/,$(addsuffix /lstat.csv,$(LIRADSLIST)))
qalirads: $(addprefix bcmdata/,$(addsuffix /qalirads,$(LIRADSLIST)))  
viewlirads: $(addprefix bcmdata/,$(addsuffix /viewlirads,$(LIRADSLIST)))  
epm: $(addprefix bcmdata/,$(addsuffix /EPM.nii,$(LIRADSLIST)))  
trainlirads: $(addprefix bcmlirads/,$(addsuffix lrtrain.nii.gz,$(LIRADSLIST)))  
multiphaselirads: $(addprefix bcmdata/,$(addsuffix /multiphase.nii.gz,$(LIRADSLIST)))  
#make -k -i -f lrstatistics.makefile qalirads > qa.log 2>&1
bcmdata/%/qalirads: 
	c3d bcmlirads/$*fixed.train.nii.gz -info -dup -lstat  -thresh 3 inf  1 0 -comp -lstat bcmdata/$*/fixed.liver.nii.gz -info bcmdata/$*/Art.longregcc.nii.gz -info bcmdata/$*/Art.raw.nii.gz  -info 
bcmlirads/%lrtrain.nii.gz: bcmlirads/%fixed.train.nii.gz bcmdata/%/fixed.liver.nii.gz
	c3d bcmdata/$*/Art.longregcc.nii.gz -info bcmdata/$*/Art.raw.nii.gz  -info 
	c3d $< -info $(word 2,$^) -info  -add -binarize $< -add -replace 6 5 5 4 4 3 3 1 2 1 -o $@ 

bcmdata/%/EPM.nii: bcmdata/%/Pre.longregcc.nii.gz  bcmdata/%/Art.longregcc.nii.gz  bcmdata/%/Ven.longregcc.nii.gz bcmdata/%/Del.longregcc.nii.gz  bcmdata/%/Pst.longregcc.nii.gz
	/rsrch1/ip/dtfuentes/github/cmd_line_epm/run_epm.sh /data/apps/MATLAB/R2021a/  $(@D)/ $(PWD)/bcmdata/$*/Pre.longregcc.nii.gz $(PWD)/bcmdata/$*/Art.longregcc.nii.gz $(PWD)/bcmdata/$*/Ven.longregcc.nii.gz  $(PWD)/bcmdata/$*/Del.longregcc.nii.gz  $(PWD)/bcmdata/$*/Pst.longregcc.nii.gz  $(PWD)/bcmlirads/$*fixed.train.nii.gz  2

bcmdata/%/viewlirads: 
	echo $*
	c3d bcmlirads/$*fixed.train.nii.gz -info -dup -lstat  -thresh 3 inf  1 0 -comp -lstat
	vglrun itksnap -l labelkey.txt  -g bcmdata/$*/EPM.nii -s bcmlirads/$*fixed.train.nii.gz 
	#vglrun itksnap -l labelkey.txt  -g  $(@D)/fixed.raw.nii.gz -s  bcmlirads/$*lrtrain.nii.gz  -o bcmdata/$*/multiphase.nii.gz bcmdata/$*/EPM.nii 
bcmdata/%/multiphase.nii.gz: bcmdata/%/Pre.longregcc.nii.gz  bcmdata/%/Art.longregcc.nii.gz  bcmdata/%/Ven.longregcc.nii.gz bcmdata/%/Del.longregcc.nii.gz  bcmdata/%/Pst.longregcc.nii.gz
	c3d $^ -omc $@

bcmdata/%/viewnnlirads: 
	vglrun itksnap -g bcmdata/$*/EPM_3.nii -s bcmdata/$*/lrbcmpocket/lirads.nii.gz -o bcmdata/$*/lrbcmpocket/lirads-?.nii.gz bcmlirads/$*lrtrain.nii.gz bcmlirads/$*-mask.nii.gz  bcmlirads/$*-lesionmask.nii.gz


$(TRAININGROOT)/bcmlirads/%-mask.nii.gz: bcmlirads/%fixed.train.nii.gz bcmdata/%/fixed.liver.nii.gz
	c3d $< $(word 2,$^) -add -binarize -o $@
$(TRAININGROOT)/bcmlirads/%-lesionmask.nii.gz: bcmlirads/%fixed.train.nii.gz 
	c3d $< -thresh 3 inf 1 0  -o $@
## intensity statistics
qastats/%/lstat.csv: 
	mkdir -p $(@D)
	c3d bcmlirads/$*lrtrain.nii.gz -dup -thresh 3  5  1 0 -comp  -lstat > $(@D)/truth.txt &&  sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain.nii.gz,lrtrain.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/truth.txt > $(@D)/truth.csv 
	c3d bcmdata/$*/EPM_3.nii.gz bcmlirads/$*lrtrain.nii.gz  -thresh 3  5  1 0 -comp  -lstat > $(@D)/epm_3.txt &&  sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain.nii.gz,EPM_3.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/epm_3.txt > $(@D)/epm_3.csv 
	c3d bcmdata/$*/lrbcmpocket/lirads-3.nii.gz bcmlirads/$*lrtrain.nii.gz  -thresh 3  5  1 0 -comp  -lstat > $(@D)/predict.3.txt &&  sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain.nii.gz,lirads-3.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/predict.3.txt > $(@D)/predict.3.csv 
	c3d bcmdata/$*/lrbcmpocket/lirads-4.nii.gz bcmlirads/$*lrtrain.nii.gz  -thresh 3  5  1 0 -comp  -lstat > $(@D)/predict.4.txt &&  sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain.nii.gz,lirads-4.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/predict.4.txt > $(@D)/predict.4.csv 
	c3d bcmdata/$*/lrbcmpocket/lirads-5.nii.gz bcmlirads/$*lrtrain.nii.gz  -thresh 3  5  1 0 -comp  -lstat > $(@D)/predict.5.txt &&  sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain.nii.gz,lirads-5.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/predict.5.txt > $(@D)/predict.5.csv 
	c3d bcmlirads/$*lrtrain.nii.gz  -thresh 3  5  1 0 -comp -thresh 1 1  1 0  -dup bcmdata/$*/lrbcmpocket/lirads.nii.gz  -multiply -lstat > $(@D)/label-1.txt && sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain-1.nii.gz,lirads.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/label-1.txt > $(@D)/label-1.csv 
	c3d bcmlirads/$*lrtrain.nii.gz  -thresh 3  5  1 0 -comp -thresh 2 2  1 0  -dup bcmdata/$*/lrbcmpocket/lirads.nii.gz  -multiply -lstat > $(@D)/label-2.txt && sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain-2.nii.gz,lirads.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/label-2.txt > $(@D)/label-2.csv 
	c3d bcmlirads/$*lrtrain.nii.gz  -thresh 3  5  1 0 -comp -thresh 3 3  1 0  -dup bcmdata/$*/lrbcmpocket/lirads.nii.gz  -multiply -lstat > $(@D)/label-3.txt && sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain-3.nii.gz,lirads.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/label-3.txt > $(@D)/label-3.csv 
	c3d bcmlirads/$*lrtrain.nii.gz  -thresh 3  5  1 0 -comp -thresh 4 4  1 0  -dup bcmdata/$*/lrbcmpocket/lirads.nii.gz  -multiply -lstat > $(@D)/label-4.txt && sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain-4.nii.gz,lirads.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/label-4.txt > $(@D)/label-4.csv 
	c3d bcmlirads/$*lrtrain.nii.gz  -thresh 3  5  1 0 -comp -thresh 5 5  1 0  -dup bcmdata/$*/lrbcmpocket/lirads.nii.gz  -multiply -lstat > $(@D)/label-5.txt && sed "1,2d;s/^\s\+/$(subst /,\/,$*),lrtrain-5.nii.gz,lirads.nii.gz,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/label-5.txt > $(@D)/label-5.csv 
	cat $(@D)/label-?.csv $(@D)/predict.?.csv $(@D)/truth.csv $(@D)/epm_3.csv > $@

qastats/lstat.csv: 
	cat qastats/*/lstat.csv > $@

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



