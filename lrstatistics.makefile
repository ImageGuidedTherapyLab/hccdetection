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

# grep Usable bcmdata/*/reviewsolution.txt 
LIRADSLIST = BCM0001001 BCM0001002 BCM0001003 BCM0002001 BCM0002002 BCM0003002 BCM0003007 BCM0004000 BCM0005000 BCM0006000 BCM0007000 BCM0008000 BCM0011000 BCM0013000 BCM0014000 BCM0015000 BCM0015002 BCM0016001 BCM0016002 BCM0017001 BCM0017002 BCM0018003 BCM0018004 BCM0019002 BCM0020002 BCM0021001 BCM0021003 BCM0022002 BCM0025001 BCM0025002 BCM0027002 BCM0027003 BCM0029000 BCM0029001 BCM0031003 BCM0031004 BCM0032001 BCM0032002 BCM0033008 BCM0034001 BCM0035005 BCM0035006 BCM0036000 BCM0036002 BCM0037002 BCM0037003 BCM0039008 BCM0039010 BCM0042011 BCM0042012 BCM0044010 BCM0044013 BCM0045000 BCM0045001 BCM0046005 BCM0046007 BCM0047007 BCM0047008 BCM0048004 BCM0048005 BCM0049011 BCM0049012 BCM0050001 BCM0050002 BCM0051007 BCM0052013 BCM0052014 BCM0054001 BCM0054013 BCM0056005 BCM0056006 BCM0057012 BCM0057013 BCM0059013 BCM0059014 BCM0060014 BCM0060015 BCM0061000 BCM0061002 BCM0062003 BCM0062004 BCM0063002 BCM0063005 BCM0064007 BCM0064008 BCM0065001 BCM0065005 BCM0066002 BCM0066004 BCM0067001 BCM0067002 BCM0068010 BCM0068012 BCM0069003 BCM0069004 BCM0070000 BCM0070001 BCM0071007 BCM0071008 BCM0072006 BCM0072007 BCM0073000 BCM0074000 BCM0075000 BCM0076000 BCM0077000 BCM0078000 BCM0079000 BCM0080000 BCM0081000 BCM0082000 BCM0083000 BCM0084000 BCM0085001 BCM0086002 BCM0087000 BCM0088000 BCM0089000 BCM0090000 BCM0091000 BCM0092000 BCM0093001 BCM0094001 BCM0095001 BCM0096000 BCM0097000 BCM0098000 BCM0099000 BCM0100001 BCM0101000 BCM0102000 BCM0103000 BCM0104001 BCM0105000 BCM0106000 BCM0107002 BCM0108001 BCM0109001 BCM0110000 BCM0111000 BCM0112000 BCM0113000 BCM0115000 BCM0116000 BCM0118000 BCM0119000 BCM0120000 BCM0121000 BCM0122000 BCM0123000 BCM0124001 BCM0126001 BCM0127000 BCM0128000 BCM0129003 BCM0130000 BCM0131001 BCM0132000 BCM0133000 BCM0135000 BCM0136000 BCM0137000 BCM0138001 BCM0139000 BCM0140000 BCM0141000 BCM0142000 BCM0143002 BCM0144004 BCM0145000 BCM0146000 BCM0148002 BCM0149001 BCM0150000 BCM0151004 BCM0153002 BCM0154001 BCM0155001 BCM0156000 BCM0157002 BCM0158001 BCM0159001 BCM0160001 BCM0161000 BCM0162000 BCM0163003 BCM0164000 BCM0166000 BCM0167000 BCM0168001 BCM0169000


lstat:    $(addprefix qastats/,$(addsuffix /lstat.csv,$(LIRADSLIST)))
epmstatdf: $(addprefix epmstats/,$(addsuffix /lstat.csv,$(LIRADSLIST)))
qalirads: $(addprefix bcmdata/,$(addsuffix /qalirads,$(LIRADSLIST)))  
viewlirads: $(addprefix bcmdata/,$(addsuffix /viewlirads,$(LIRADSLIST)))  
epm: $(addprefix bcmdata/,$(addsuffix /EPM.nii,$(LIRADSLIST)))  
trainlirads: $(addprefix bcmlirads/,$(addsuffix lrtrain.nii.gz,$(LIRADSLIST)))  
multiphaselirads: $(addprefix bcmdata/,$(addsuffix /multiphase.nii.gz,$(LIRADSLIST)))  
#make -k -i -f lrstatistics.makefile qalirads > qa.log 2>&1
bcmdata/%/qalirads: 
	c3d bcmdata/$*/Art.longregcc.nii.gz  bcmlirads/$*fixed.train.nii.gz -lstat > $@.txt 2>&1
#bcmdata/%/qalirads: 
#	@echo make -f lrstatistics.makefile bcmdata/$*/viewlirads
#	c3d bcmlirads/$*fixed.train.nii.gz -info -dup -lstat  bcmdata/$*/fixed.liver.nii.gz -info bcmdata/$*/Art.longregcc.nii.gz -info bcmdata/$*/Art.raw.nii.gz  -info 
#	@echo !!!!!replacecmd - bcmlirads/$*fixed.train.nii.gz -replace 2 6 -o bcmlirads/$*fixed.train.nii.gz 
bcmlirads/%lrtrain.nii.gz: bcmlirads/%fixed.train.nii.gz bcmdata/%/fixed.liver.nii.gz
	c3d bcmdata/$*/Art.longregcc.nii.gz -info bcmdata/$*/Art.raw.nii.gz  -info 
	c3d $< -info $(word 2,$^) -info  -add -binarize $< -add -replace 6 5 5 4 4 3 3 1 2 1 -o $@ 
bcmdata/%/EPM.nii: bcmdata/%/Pre.longregcc.nii.gz  bcmdata/%/Art.longregcc.nii.gz  bcmdata/%/Ven.longregcc.nii.gz bcmdata/%/Del.longregcc.nii.gz  bcmdata/%/Pst.longregcc.nii.gz
	/rsrch1/ip/dtfuentes/github/cmd_line_epm/run_epm.sh /data/apps/MATLAB/R2021a/  $(@D)/ $(PWD)/bcmdata/$*/Pre.longregcc.nii.gz $(PWD)/bcmdata/$*/Art.longregcc.nii.gz $(PWD)/bcmdata/$*/Ven.longregcc.nii.gz  $(PWD)/bcmdata/$*/Del.longregcc.nii.gz  $(PWD)/bcmdata/$*/Pst.longregcc.nii.gz  $(PWD)/bcmlirads/$*fixed.train.nii.gz  6

bcmdata/%/viewlirads: 
	echo $*
	c3d bcmlirads/$*fixed.train.nii.gz -info -dup -lstat  -thresh 3 inf  1 0 -comp -lstat
	vglrun itksnap -l labelkey.txt  -g bcmdata/$*/Art.longregcc.nii.gz  -s bcmlirads/$*fixed.train.nii.gz 
	#vglrun itksnap -l labelkey.txt  -g bcmdata/$*/EPM.nii -s bcmlirads/$*fixed.train.nii.gz 
	#vglrun itksnap -l labelkey.txt  -g  $(@D)/fixed.raw.nii.gz -s  bcmlirads/$*lrtrain.nii.gz  -o bcmdata/$*/multiphase.nii.gz bcmdata/$*/EPM.nii 
bcmdata/%/multiphase.nii.gz: bcmdata/%/Pre.longregcc.nii.gz  bcmdata/%/Art.longregcc.nii.gz  bcmdata/%/Ven.longregcc.nii.gz bcmdata/%/Del.longregcc.nii.gz  bcmdata/%/Pst.longregcc.nii.gz
	c3d $^ -omc $@

bcmdata/%/viewnnlirads: 
	vglrun itksnap -g bcmdata/$*/EPM_3.nii -s bcmdata/$*/lrbcmpocket/lirads.nii.gz -o bcmdata/$*/lrbcmpocket/lirads-?.nii.gz bcmlirads/$*lrtrain.nii.gz bcmlirads/$*-mask.nii.gz  bcmlirads/$*-lesionmask.nii.gz


$(TRAININGROOT)/bcmlirads/%-mask.nii.gz: bcmlirads/%fixed.train.nii.gz bcmdata/%/fixed.liver.nii.gz
	c3d $< $(word 2,$^) -add -binarize -o $@
$(TRAININGROOT)/bcmlirads/%-lesionmask.nii.gz: bcmlirads/%fixed.train.nii.gz 
	c3d $< -thresh 3 inf 1 0  -o $@

## epm statistics
epmstats/%/lstat.csv:
	mkdir -p $(@D)
	c3d bcmdata/$*/EPM.nii bcmlirads/$*fixed.train.nii.gz  -lstat  > $(@D)/epm.txt &&  sed "s/^\s\+/$*,fixed.train.nii.gz,epm,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/epm.txt > $(@D)/epm.csv 
	c3d bcmdata/$*/Art.longregcc.nii.gz bcmlirads/$*fixed.train.nii.gz  -lstat > $(@D)/art.txt &&  sed "s/^\s\+/$*,fixed.train.nii.gz,art,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/art.txt > $(@D)/art.csv 
	c3d bcmdata/$*/Ven.longregcc.nii.gz bcmlirads/$*fixed.train.nii.gz  -lstat > $(@D)/ven.txt &&  sed "s/^\s\+/$*,fixed.train.nii.gz,ven,/g;s/\s\+/,/g;s/LabelID/InstanceUID,SegmentationID,FeatureID,LabelID/g;s/Vol(mm^3)/Vol.mm.3/g;s/Extent(Vox)/ExtentX,ExtentY,ExtentZ/g" $(@D)/ven.txt > $(@D)/ven.csv 
	cat $(@D)/art.csv $(@D)/ven.csv $(@D)/epm.csv  > $@

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



