SHELL := /bin/bash
methods:
	pdflatex methods.tex; bibtex methods; pdflatex methods.tex; pdflatex methods.tex
doc:
	latex2rtf -M12 -D 600 -o methods.doc methods.tex
WORKDIR=anonymize
#
# Defaults
#
MATLABROOT      := /data/apps/MATLAB/R2020a/
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
anon: $(foreach idfile,$(IMAGEFILELIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idfile),$(ANONLIST))))  \
      $(foreach idfile,$(IMAGEFILELIST),$(addprefix $(WORKDIR)/pre,$(addsuffix /$(idfile),$(ANONLIST))))  \
      $(foreach idfile,$(IMAGEFILELIST),$(addprefix $(WORKDIR)/art,$(addsuffix /$(idfile),$(ANONLIST))))  \
      $(foreach idfile,$(IMAGEFILELIST),$(addprefix $(WORKDIR)/ven,$(addsuffix /$(idfile),$(ANONLIST)))) 
$(WORKDIR)/prehcc%/image.nii:
	mkdir -p $(@D)
	c3d Processed/$(word $*, $(MRILIST))/Pre.raw.nii.gz  -o $@
$(WORKDIR)/prehcc%/label.nii:
	mkdir -p $(@D)
	c3d Processed/$(word $*, $(MRILIST))/Truth.raw.nii.gz  -o $@
$(WORKDIR)/venhcc%/image.nii:
	mkdir -p $(@D)
	c3d Processed/$(word $*, $(MRILIST))/Ven.raw.nii.gz  -o $@
$(WORKDIR)/venhcc%/label.nii:
	mkdir -p $(@D)
	c3d Processed/$(word $*, $(MRILIST))/Truth.raw.nii.gz  -o $@
$(WORKDIR)/arthcc%/image.nii:
	mkdir -p $(@D)
	c3d Processed/$(word $*, $(MRILIST))/Art.raw.nii.gz  -o $@
$(WORKDIR)/arthcc%/label.nii:
	mkdir -p $(@D)
	c3d Processed/$(word $*, $(MRILIST))/Truth.raw.nii.gz  -o $@
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
%/amiralabel: 
	vglrun /opt/apps/Amira/2020.2/bin/start -tclcmd "load $(@D)/Pre.raw.nii.gz; load $(@D)/Ven.raw.nii.gz; load $(@D)/Art.raw.nii.gz; load $(@D)/Truth.raw.nii.gz; create HxCastField ConvertImage; ConvertImage data connect Truth.raw.nii.gz; ConvertImage fire; ConvertImage outputType setIndex 0 7; ConvertImage create result setLabel ; Truth.raw.nii.to-labelfield-8_bits ImageData connect Art.raw.nii.gz;"
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

# setup BCM data
bcmlirads/dataqa.csv:
	echo StudyUID,Status > $@
	for idfile in  bcmdata/BCM*/reviewsolution.txt ; do STUDYUID=$$(echo $$idfile | cut -d '/' -f2); sed "s/^/$$STUDYUID,/g" $$idfile; done >> $@
bcmlirads/wideanon.csv:
	 cat newwide.sql  | sqlite3
BCMDATADIR=LiverMRIProjectDataV2/tmpconvert/
BCMWORKDIR=bcmdata
BCMLISTUID  = $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f1 )
BCMLISTPRE  = $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f5 )
BCMLISTART  = $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f6 )
BCMLISTVEN  = $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f7 )
BCMLISTDEL  = $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f8 )
BCMLISTPST  = $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f9 )
BCMLISTFIX  = $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f14)
BCMCONTRASTLIST = Pre Art Ven Del Pst fixed

rawbcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).raw.nii.gz,$(BCMLISTUID)))) 
epmbcm:  $(addprefix $(BCMWORKDIR)/,$(addsuffix /EPM_3.nii,$(BCMLISTUID)))

$(BCMWORKDIR)/%/EPM_3.nii:
	cp /Radonc/Cancer\ Physics\ and\ Engineering\ Lab/David\ Fuentes/hccdetection/$@ $@

$(BCMWORKDIR)/%/Pre.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTPRE)).nii.gz -swapdim RAI  -o $@
$(BCMWORKDIR)/%/Art.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTART)).nii.gz -swapdim RAI -o $@
$(BCMWORKDIR)/%/Ven.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTVEN)).nii.gz -swapdim RAI  -o $@
$(BCMWORKDIR)/%/Del.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTDEL)).nii.gz -swapdim RAI  -o $@
$(BCMWORKDIR)/%/Pst.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTPST)).nii.gz -swapdim RAI  -o $@
$(BCMWORKDIR)/%/fixed.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$(word $(shell sed 1d bcmlirads/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTFIX)).nii.gz    -swapdim RAI  -o $@


viewbcm: $(addprefix $(BCMWORKDIR)/,$(addsuffix /viewbcm,$(BCMLISTUID)))  
%/viewbcm: 
	c3d $(@D)/Pre.raw.nii.gz -info  $(@D)/Ven.raw.nii.gz -info $(@D)/Art.raw.nii.gz -info   $(@D)/Del.raw.nii.gz  -info $(@D)/Pst.raw.nii.gz  -info
	vglrun itksnap -g  $(@D)/Art.raw.nii.gz   -o $(@D)/Ven.raw.nii.gz $(@D)/Pre.raw.nii.gz $(@D)/Del.raw.nii.gz $(@D)/Pst.raw.nii.gz
	vglrun itksnap -g  $(@D)/Pre.raw.nii.gz   -o $(@D)/Pre/score.nii.gz -s  $(@D)/Pre/label.nii.gz
	vglrun itksnap -g  $(@D)/Art.raw.nii.gz   -o $(@D)/Art/score.nii.gz -s  $(@D)/Art/label.nii.gz
	vglrun itksnap -g  $(@D)/Ven.raw.nii.gz   -o $(@D)/Ven/score.nii.gz -s  $(@D)/Ven/label.nii.gz
	vglrun itksnap -g  $(@D)/Del.raw.nii.gz   -o $(@D)/Del/score.nii.gz -s  $(@D)/Del/label.nii.gz
viewbcmlong: $(addprefix $(BCMWORKDIR)/,$(addsuffix /viewbcmlong,$(BCMLISTUID)))  
%/viewbcmlong: 
	c3d -verbose $(@D)/fixed.bias.nii.gz  -info $(@D)/fixed.mask.nii.gz  -info -lstat
	c3d -verbose $(@D)/Pre.bias.nii.gz    -info $(@D)/Pre.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Art.bias.nii.gz    -info $(@D)/Art.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Ven.bias.nii.gz    -info $(@D)/Ven.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Del.bias.nii.gz    -info $(@D)/Del.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Pst.bias.nii.gz    -info $(@D)/Pst.mask.nii.gz    -info -lstat
	mkdir -p $(subst bcmdata,bcmlirads,$(@D))
	vglrun itksnap -g  $(@D)/fixed.bias.nii.gz  -s $(@D)/fixed.liver.nii.gz  -o $(@D)/Pre.longregcc.nii.gz $(@D)/Art.longregcc.nii.gz $(@D)/Ven.longregcc.nii.gz $(@D)/Del.longregcc.nii.gz $(@D)/Pst.longregcc.nii.gz & vglrun itksnap -g  $(@D)/Pre.raw.nii.gz  -s $(@D)/Pre.mask.nii.gz  & vglrun itksnap -g  $(@D)/Art.raw.nii.gz  -s $(@D)/Art.mask.nii.gz  & vglrun itksnap -g  $(@D)/Ven.raw.nii.gz  -s $(@D)/Ven.mask.nii.gz & vglrun itksnap -g  $(@D)/Del.raw.nii.gz  -s $(@D)/Del.mask.nii.gz   & vglrun itksnap -g  $(@D)/Pst.raw.nii.gz  -s $(@D)/Pst.mask.nii.gz & SOLNSTATUS=$$(zenity  --list --title="QA" --text="$*"  --editable  --column "Status" RegistrationError MaskError PulseSequence Usable ) ; echo $$SOLNSTATUS; echo $$SOLNSTATUS >  $*/reviewsolution.txt ;   pkill -9 ITK-SNAP
# https://fixyacloud.wordpress.com/2020/01/26/caching-preloading-files-on-linux-into-ram/
%/qabcmlong: 
	-c3d -verbose $(@D)/fixed.bias.nii.gz  -info $(@D)/fixed.mask.nii.gz  -info -lstat
	-c3d -verbose $(@D)/Pre.bias.nii.gz    -info $(@D)/Pre.mask.nii.gz    -info -lstat
	-c3d -verbose $(@D)/Art.bias.nii.gz    -info $(@D)/Art.mask.nii.gz    -info -lstat
	-c3d -verbose $(@D)/Ven.bias.nii.gz    -info $(@D)/Ven.mask.nii.gz    -info -lstat
	-c3d -verbose $(@D)/Del.bias.nii.gz    -info $(@D)/Del.mask.nii.gz    -info -lstat
	-c3d -verbose $(@D)/Pst.bias.nii.gz    -info $(@D)/Pst.mask.nii.gz    -info -lstat
	if [ ! -f $(subst bcmdata,bcmlirads,$(@D))fixed.train.nii.gz ] ; then echo creating file; c3d $(@D)/Art.longregcc.nii.gz -scale 0 -type char $(subst bcmdata,bcmlirads,$(@D))fixed.train.nii.gz  ;fi
	export AMIRA_DATADIR=$(subst bcmdata,bcmlirads,$(@D));echo vglrun /opt/apps/Amira/2020.2/bin/start -tclcmd "load $(@D)/Pre.raw.nii.gz; load $(@D)/Art.raw.nii.gz;load $(@D)/Ven.raw.nii.gz; load $(@D)/Del.raw.nii.gz;load $(@D)/Pst.raw.nii.gz; echo save liver mask as $(subst bcmdata,bcmlirads,$(@D))/Pre.rawlivertrain.nii.gz $(subst bcmdata,bcmlirads,$(@D))/Art.rawlivertrain.nii.gz  $(subst bcmdata,bcmlirads,$(@D))/Ven.rawlivertrain.nii.gz  $(subst bcmdata,bcmlirads,$(@D))/Del.rawlivertrain.nii.gz  $(subst bcmdata,bcmlirads,$(@D))/Pst.rawlivertrain.nii.gz;load $(@D)/Pre.liver.nii.gz; load $(@D)/Art.liver.nii.gz;load $(@D)/Ven.liver.nii.gz; load $(@D)/Del.liver.nii.gz;load $(@D)/Pst.liver.nii.gz ; create HxCastField ConvertImage; ConvertImage data connect Pre.liver.nii.gz; ConvertImage fire; ConvertImage outputType setIndex 0 7; ConvertImage create result setLabel ; Pre.liver.nii.to-labelfield-8_bits ImageData connect Pre.raw.nii.gz;create HxCastField ConvertImage0; ConvertImage0 data connect Art.liver.nii.gz; ConvertImage0 fire; ConvertImage0 outputType setIndex 0 7; ConvertImage0 create result setLabel ; Art.liver.nii.to-labelfield-8_bits ImageData connect Art.raw.nii.gz;create HxCastField ConvertImage1; ConvertImage1 data connect Ven.liver.nii.gz; ConvertImage1 fire; ConvertImage1 outputType setIndex 0 7; ConvertImage1 create result setLabel ; Ven.liver.nii.to-labelfield-8_bits ImageData connect Ven.raw.nii.gz;create HxCastField ConvertImage2; ConvertImage2 data connect Del.liver.nii.gz; ConvertImage2 fire; ConvertImage2 outputType setIndex 0 7; ConvertImage2 create result setLabel ; Del.liver.nii.to-labelfield-8_bits ImageData connect Del.raw.nii.gz;create HxCastField ConvertImage3; ConvertImage3 data connect Pst.liver.nii.gz; ConvertImage3 fire; ConvertImage3 outputType setIndex 0 7; ConvertImage3 create result setLabel ; Pst.liver.nii.to-labelfield-8_bits ImageData connect Pst.raw.nii.gz " & vglrun itksnap -g  $(@D)/fixed.bias.nii.gz  -s $(@D)/fixed.liver.nii.gz  -o $(@D)/Pre.longregcc.nii.gz $(@D)/Art.longregcc.nii.gz $(@D)/Ven.longregcc.nii.gz $(@D)/Del.longregcc.nii.gz $(@D)/Pst.longregcc.nii.gz & vglrun itksnap -g  $(@D)/Pre.raw.nii.gz  -s $(@D)/Pre.liver.nii.gz  & vglrun itksnap -g  $(@D)/Art.raw.nii.gz  -s $(@D)/Art.liver.nii.gz  & vglrun itksnap -g  $(@D)/Ven.raw.nii.gz  -s $(@D)/Ven.liver.nii.gz & vglrun itksnap -g  $(@D)/Del.raw.nii.gz  -s $(@D)/Del.liver.nii.gz   & vglrun itksnap -g  $(@D)/Pst.raw.nii.gz  -s $(@D)/Pst.liver.nii.gz & vglrun itksnap -g   $(@D)/Art.longregcc.nii.gz -s $(subst bcmdata,bcmlirads,$(@D))fixed.train.nii.gz -o $(@D)/EPM.nii  & SOLNSTATUS=$$(zenity  --list --title="QA" --text="$*"  --editable  --column "Status" MissingRawData RegistrationError FixedMaskErrorMissing PreMaskErrorMissing ArtMaskErrorMissing VenMaskErrorMissing DelMaskErrorMissing PstMaskErrorMissing MultipleMaskMissing PulseSequence UseDifferentTimePoint Usable ) ; echo $$SOLNSTATUS; echo $$SOLNSTATUS >  $*/reviewsolution.txt ;  pkill -9 Amira; pkill -9 ITK-SNAP
	
$(BCMWORKDIR)/%/slic.nii.gz:
	c3d $(@D)/Pre.longregcc.nii.gz  -info $(@D)/Art.longregcc.nii.gz  -info  $(@D)/Ven.longregcc.nii.gz  -info $(@D)/Del.longregcc.nii.gz  -info   $(@D)/Pst.longregcc.nii.gz  -info -omc $(@D)/liverprotocol.nii.gz
	/rsrch1/ip/dtfuentes/github/ExLib/SLICImageFilter/itkSLICImageFilterTest $(@D)/liverprotocol.nii.gz $@ 10 1

# preprocess data
zscorebcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).zscore.nii.gz,$(BCMLISTUID)))) 
biasbcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).bias.nii.gz,$(BCMLISTUID)))) 
fixedbiasbcm:  $(addprefix $(BCMWORKDIR)/,$(addsuffix /fixed.bias.nii.gz,$(BCMLISTUID)))
resizebcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).crop.nii.gz,$(BCMLISTUID)))) 
resizebcmfixed: $(addprefix $(BCMWORKDIR)/,$(addsuffix /fixed.crop.nii.gz,$(BCMLISTUID)))
$(BCMWORKDIR)/%.zscore.nii.gz: 
	python normalization.py --imagefile=$(BCMWORKDIR)/$*.raw.nii.gz  --output=$@
#/opt/apps/ANTS/ANTS-build/ANTS-build/Examples/N4BiasFieldCorrection
#/opt/apps/ANTS/dev/install/bin/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -i  $@  -o  $@
$(BCMWORKDIR)/%.bias.nii.gz: 
	c3d -verbose $(BCMWORKDIR)/$*.raw.nii.gz  -shift 1  -o  $@
	/opt/apps/ANTS/build/ANTS-build/Examples/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -i  $@  -o  $@
	python normalization.py --imagefile=$@  --output=$@
$(BCMWORKDIR)/%.crop.nii.gz: $(BCMWORKDIR)/%.zscore.nii.gz
	python resize.py --imagefile=bcmdata/$*.zscore.nii.gz  --output=$@
# label data
labelbcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).label.nii.gz,$(BCMLISTUID)))) 
labelbcmfixed: $(addprefix $(BCMWORKDIR)/,$(addsuffix /fixed.label.nii.gz,$(BCMLISTUID)))
bcmdata/%/label.nii.gz: bcmdata/%.256.nii.gz
	echo applymodel\('$<','Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat','$(@D)','1','gpu'\)
	mkdir -p $(@D);./run_applymodel.sh $(MATLABROOT) $< Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat $(@D) 1 gpu
	echo HACK - matlab losing header info
	c3d $< bcmdata/$*/label.nii.gz -copy-transform -o bcmdata/$*/label.nii.gz 
	c3d $< bcmdata/$*/score.nii.gz -copy-transform -o bcmdata/$*/score.nii.gz 
	echo vglrun itksnap -g $< -s bcmdata/$*/label.nii.gz -o bcmdata/$*/score.nii.gz
bcmdata/BCM0015000/%/label.nii.gz: bcmdata/BCM0015000/%.256.nii.gz
	echo applymodel\('$<','Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat','$(@D)','1','cpu'\)
	mkdir -p $(@D);./run_applymodel.sh $(MATLABROOT) $< Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat $(@D) 1 cpu
	echo HACK - matlab losing header info
	c3d $< bcmdata/BCM0015000/$*/label.nii.gz -copy-transform -o bcmdata/BCM0015000/$*/label.nii.gz 
	c3d $< bcmdata/BCM0015000/$*/score.nii.gz -copy-transform -o bcmdata/BCM0015000/$*/score.nii.gz 
	echo vglrun itksnap -g $< -s bcmdata/BCM0015000/$*/label.nii.gz -o bcmdata/BCM0015000/$*/score.nii.gz
bcmdata/BCM0002002/Pst/label.nii.gz: bcmdata/BCM0002002/Pst.256.nii.gz
	echo applymodel\('$<','Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat','$(@D)','1','cpu'\)
	mkdir -p $(@D);./run_applymodel.sh $(MATLABROOT) $< Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat $(@D) 1 cpu
	echo HACK - matlab losing header info
	c3d $< bcmdata/BCM0002002/Pst/label.nii.gz -copy-transform -o bcmdata/BCM0002002/Pst/label.nii.gz 
	c3d $< bcmdata/BCM0002002/Pst/score.nii.gz -copy-transform -o bcmdata/BCM0002002/Pst/score.nii.gz 
	echo vglrun itksnap -g $< -s bcmdata/BCM0002002/Pst/label.nii.gz -o bcmdata/BCM0002002/Pst/score.nii.gz
bcmdata/%.label.nii.gz: bcmdata/%/label.nii.gz
	c3d -verbose bcmdata/$*.raw.nii.gz $<  -reslice-identity -o $@
# dilate mask
maskbcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).mask.nii.gz,$(BCMLISTUID)))) 
bcmdata/%.mask.nii.gz: 
	echo $*
	if [  -f bcmlirads/$*.rawlivertrain.nii.gz  ] ; then echo found training data ; c3d -verbose bcmlirads/$*.rawlivertrain.nii.gz -type char -o bcmdata/$*.liver.nii.gz -dilate 1 15x15x15vox -o $@ ; else  echo using NN label; c3d -verbose bcmdata/$*.label.nii.gz  -thresh 2 2 1 0  -comp -thresh 1 1 1 0  -o  bcmdata/$*.liver.nii.gz -dilate 1 15x15x15vox -o $@ ;fi




# register study
regbcm:  $(foreach idc,$(filter-out Art fixed,$(BCMCONTRASTLIST)),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).regcc.nii.gz,$(BCMLISTUID)))) 
bcmdata/%.regcc.nii.gz: bcmdata/%.bias.nii.gz bcmdata/%.mask.nii.gz
	export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=24; /opt/apps/ANTS/dev/install/bin/antsRegistration --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/Art.mask.nii.gz,$(word 2,$^)] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/Art.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[ 0.1 ] --metric MI[ $(@D)/Art.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[ 0.1,3,0 ] --metric CC[ $(@D)/Art.bias.nii.gz,$<,1,4 ] --convergence [ 100x70x50x20,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox > $(basename $(basename $@)).log  2>&1
# register longitudinal
CLUSTERDIR = /rsrch3/home/imag_phy-rsrch/dtfuentes/github/hccdetection
longregbcm: $(foreach idc,$(filter-out fixed,$(BCMCONTRASTLIST)),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).longregcc.nii.gz,$(BCMLISTUID)))) 
# debug initialization
bcmdata/%.longregdbginitial.nii.gz: bcmdata/%.bias.nii.gz 
	/opt/apps/ANTS/dev/install/bin/antsRegistration  --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/fixed.mask.nii.gz,bcmdata/$*.mask.nii.gz] -r [ $(@D)/fixed.mask.nii.gz,bcmdata/$*.mask.nii.gz,1] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/fixed.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 0x0x0x0,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox 
	vglrun itksnap -g $(@D)/fixed.bias.nii.gz -o $@
clusterrsync:
	rsync -n -v -avz  --include={'*256.nii.gz','*mask.nii.gz'} --include='BCM*/' --exclude='*'  bcmdata/  /rsrch3/ip/dtfuentes/github/hccdetection/bcmdata/
badawyrsync:
	rsync  -v -avz  --include={'*raw.nii.gz','*longregcc.nii.gz','*liver.nii.gz','*bias.nii.gz','*mask.nii.gz'} --include='BCM*/' --exclude='*'  bcmdata/  /rsrch1/ip/mebadawy/github/hccdetection/bcmdata/
radoncsync:
	rsync    -v -avz  --include={'*raw.nii.gz','*longregcc.nii.gz','*liver.nii.gz','*bias.nii.gz','*mask.nii.gz'} --include='BCM*/' --exclude='*'  bcmdata/  /Radonc/Cancer\ Physics\ and\ Engineering\ Lab/David\ Fuentes/hccdetection/bcmdata/

biostatsync:
	rsync    -v -avz  --include={'*raw.nii.gz','*longregcc.nii.gz','*liver.nii.gz','*bias.nii.gz','*mask.nii.gz'} --include='BCM*/' --exclude='*'  bcmdata/  /rsrch1/biostat/epmdata

# setup MDA data
MDADATADIR="/Radonc/Cancer Physics and Engineering Lab/Milli Roach/LIRADS EPM/LIRADS_MRI_NIFTI"
MDALISTUID  = $(shell sed 1d bcmlirads/mdafilepaths.csv | cut -d, -f1 )
MDALISTFIX  = $(shell sed 1d bcmlirads/mdafilepaths.csv | cut -d, -f8 )
rawmda: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix mdadata/,$(addsuffix /$(idc).raw.nii.gz,$(MDALISTUID)))) 
mdadata/%/Pre.raw.nii.gz:
	mkdir -p $(@D); c3d  $(MDADATADIR)/$*/Pre.raw.nii  -o $@
mdadata/%/Art.raw.nii.gz:
	mkdir -p $(@D); c3d  $(MDADATADIR)/$*/Art.raw.nii  -o $@
mdadata/%/Ven.raw.nii.gz:
	mkdir -p $(@D); c3d  $(MDADATADIR)/$*/Ven.raw.nii  -o $@
mdadata/%/Del.raw.nii.gz:
	mkdir -p $(@D); c3d  $(MDADATADIR)/$*/Del.raw.nii  -o $@
mdadata/%/Pst.raw.nii.gz:
	mkdir -p $(@D); c3d  $(MDADATADIR)/$*/Pst.raw.nii  -o $@
mdadata/%/fixed.raw.nii.gz:
	mkdir -p $(@D); c3d  $(MDADATADIR)/$(word $(shell sed 1d bcmlirads/mdafilepaths.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(MDALISTFIX))  -o $@

# preprocess data
zscoremda: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix mdadata/,$(addsuffix /$(idc).zscore.nii.gz,$(MDALISTUID)))) 
biasmda: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix mdadata/,$(addsuffix /$(idc).bias.nii.gz,$(MDALISTUID)))) 
resizemda: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix mdadata/,$(addsuffix /$(idc).crop.nii.gz,$(MDALISTUID)))) 
resizemdafixed: $(addprefix mdadata/,$(addsuffix /fixed.crop.nii.gz,$(MDALISTUID))) $(addprefix mdadata/,$(addsuffix /fixed.bias.nii.gz,$(MDALISTUID)))
mdadata/%.zscore.nii.gz: 
	python normalization.py --imagefile=mdadata/$*.raw.nii.gz  --output=$@
mdadata/%.bias.nii.gz: 
	c3d -verbose mdadata/$*.raw.nii.gz  -shift 1  -o  $@
	/opt/apps/ANTS/build/ANTS-build/Examples/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -i  $@  -o  $@
	#/opt/apps/ANTS/dev/install/bin/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -i  $@  -o  $@
	python normalization.py --imagefile=$@  --output=$@
mdadata/%.crop.nii.gz: mdadata/%.zscore.nii.gz
	python resize.py --imagefile=mdadata/$*.zscore.nii.gz  --output=$@
# label data
labelmda: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix mdadata/,$(addsuffix /$(idc).label.nii.gz,$(MDALISTUID)))) 
mdadata/%/label.nii.gz: mdadata/%.256.nii.gz
	echo applymodel\('$<','Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat','$(@D)','1','gpu'\)
	mkdir -p $(@D);./run_applymodel.sh $(MATLABROOT) $< Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat $(@D) 1 gpu
	echo vglrun itksnap -g $< -s mdadata/$*/label.nii.gz -o mdadata/$*/score.nii.gz
mdadata/%.label.nii.gz: mdadata/%/label.nii.gz
	c3d -verbose mdadata/$*.raw.nii.gz $< -reslice-identity -o $@
# dilate mask
maskmda: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix mdadata/,$(addsuffix /$(idc).mask.nii.gz,$(MDALISTUID)))) 
mdadata/%.mask.nii.gz: 
	c3d -verbose mdadata/$*.label.nii.gz  -thresh 2 2 1 0  -comp -thresh 1 1 1 0  -o  mdadata/$*.liver.nii.gz -dilate 1 15x15x15vox -o $@

# register longitudinal
longregmda: $(foreach idc,$(filter-out fixed,$(BCMCONTRASTLIST)),$(addprefix mdadata/,$(addsuffix /$(idc).longregcc.nii.gz,$(MDALISTUID)))) 
mdadata/%.longregcc.nii.gz: mdadata/%.bias.nii.gz 
	echo "bsub -Is -q interactive -W 6:00 -M 32 -R rusage[mem=32] -n 4 /usr/bin/bash"
	export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=28; bsub  -env "all" -J $(subst /,,$*) -Ip -cwd $(CLUSTERDIR) -n 28 -W 00:55 -q short -M 128 -R rusage[mem=128] -o  $(basename $(basename $@)).log /risapps/rhel7/ANTs/20200622/bin/antsRegistration --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/fixed.mask.nii.gz,mdadata/$*.mask.nii.gz] -r [ $(@D)/fixed.mask.nii.gz,mdadata/$*.mask.nii.gz,1] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/fixed.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[ 0.1 ] --metric MI[ $(@D)/fixed.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[ 0.1,3,0 ] --metric CC[$(@D)/fixed.bias.nii.gz,$<,1,4 ] --convergence [ 100x70x50x20,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox 

viewmdalong: $(addprefix mdadata/,$(addsuffix /viewmdalong,$(MDALISTUID)))  
%/viewmdalong: 
	c3d -verbose $(@D)/fixed.bias.nii.gz  -info $(@D)/fixed.mask.nii.gz  -info -lstat
	c3d -verbose $(@D)/Pre.bias.nii.gz    -info $(@D)/Pre.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Art.bias.nii.gz    -info $(@D)/Art.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Ven.bias.nii.gz    -info $(@D)/Ven.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Del.bias.nii.gz    -info $(@D)/Del.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Pst.bias.nii.gz    -info $(@D)/Pst.mask.nii.gz    -info -lstat
	vglrun itksnap -g  $(@D)/fixed.bias.nii.gz  -s $(@D)/fixed.liver.nii.gz  -o $(@D)/Pre.longregcc.nii.gz $(@D)/Art.longregcc.nii.gz $(@D)/Ven.longregcc.nii.gz $(@D)/Del.longregcc.nii.gz $(@D)/Pst.longregcc.nii.gz & vglrun itksnap -g  $(@D)/Pre.raw.nii.gz  -s $(@D)/Pre.mask.nii.gz  & vglrun itksnap -g  $(@D)/Art.raw.nii.gz  -s $(@D)/Art.mask.nii.gz  & vglrun itksnap -g  $(@D)/Ven.raw.nii.gz  -s $(@D)/Ven.mask.nii.gz & vglrun itksnap -g  $(@D)/Del.raw.nii.gz  -s $(@D)/Del.mask.nii.gz   & vglrun itksnap -g  $(@D)/Pst.raw.nii.gz  -s $(@D)/Pst.mask.nii.gz & SOLNSTATUS=$$(zenity  --list --title="QA" --text="$*"  --editable  --column "Status" RegistrationError MaskError PulseSequence Usable ) ; echo $$SOLNSTATUS; echo $$SOLNSTATUS >  $*/reviewsolution.txt ;   pkill -9 ITK-SNAP
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

comparemodels: Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/004/trainedNet.mat  Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/003/trainedNet.mat Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/trainedNet.mat Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/001/trainedNet.mat Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/002/trainedNet.mat 
#DATALIST = $(ANONLIST) $(addprefix washout,$(ANONLIST)) $(HCCCTLIST) $(CRCLIST) $(addprefix crctumor,$(CRCLIST)) 
#DATALIST = $(ANONLIST) $(addprefix washout,$(ANONLIST)) $(CRCLIST) $(addprefix crctumor,$(CRCLIST)) 
#DATALIST = $(addprefix crctumor,$(CRCLIST)) 
DATALIST = $(addprefix pre,$(ANONLIST)) $(addprefix ven,$(ANONLIST)) $(addprefix art,$(ANONLIST))
print:
	@echo $(BCMCONTRASTLIST)
	@echo $(filter-out fixed,$(BCMCONTRASTLIST))
	@echo $(filter-out Art fixed,$(BCMCONTRASTLIST))

view: $(addprefix $(WORKDIR)/,$(addsuffix /view,$(DATALIST)))  
info: $(addprefix $(WORKDIR)/,$(addsuffix /info,$(DATALIST)))  
lstat: $(addprefix $(WORKDIR)/,$(addsuffix /lstat.sql,$(DATALIST)))  

resize: $(addprefix $(WORKDIR)/,$(addsuffix /crop/Truth.nii,$(DATALIST)))   \
        $(addprefix $(WORKDIR)/,$(addsuffix /scaled/crop/Volume.nii,$(DATALIST)))   \
        $(addprefix $(WORKDIR)/,$(addsuffix /zscore/crop/Volume.nii,$(DATALIST)))   \
        $(addprefix $(WORKDIR)/,$(addsuffix /bias/crop/Volume.nii,$(DATALIST)))    
scaled:   $(addprefix $(WORKDIR)/,$(addsuffix /scaled/normalize.nii,$(DATALIST)))   \
          $(addprefix $(WORKDIR)/,$(addsuffix /zscore/normalize.nii,$(DATALIST)))   \
          $(addprefix $(WORKDIR)/,$(addsuffix /bias/normalize.nii,$(DATALIST)))  

#MODELLIST = scaled/256/unet2d scaled/256/unet3d scaled/256/densenet2d scaled/256/densenet3d scaled/512/densenet2d scaled/512/unet2d
#APPLYLIST=$(UIDLIST0) $(UIDLIST1) $(UIDLIST2) $(UIDLIST3) $(UIDLIST4) 
#MODELLIST = scaled/256/unet2d/run_a scaled/256/unet3d/run_a scaled/256/densenet2d/run_a scaled/256/densenet3d/run_a 
#APPLYLIST=$(UIDLIST20) $(UIDLIST21) $(UIDLIST22) $(UIDLIST23) $(UIDLIST24) 
#MODELLIST = scaled/256/unet2d/crctumor scaled/256/unet3d/crctumor scaled/256/densenet2d/crctumor scaled/256/densenet3d/crctumor 
MODELLIST = scaled/256/densenet3d/hccmrima 
APPLYLIST=$(UIDLIST5) $(UIDLIST6) $(UIDLIST7) $(UIDLIST8) $(UIDLIST9) 

mask:     $(foreach idmodel,$(MODELLIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idmodel)/label.nii.gz,$(APPLYLIST)))) 
liver:    $(foreach idmodel,$(MODELLIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idmodel)/liver.nii.gz,$(APPLYLIST)))) 
overlap:  $(foreach idmodel,$(MODELLIST),$(addprefix $(WORKDIR)/,$(addsuffix /$(idmodel)/overlap.sql,$(APPLYLIST)))) 


## pre processing
%/scaled/normalize.nii: 
	mkdir -p $(@D)
	/opt/apps/ANTS/dev/install/bin/ImageMath 3 $@ TruncateImageIntensity $*/image.nii 0.01  0.99 200 
	python normalization.py --imagefile=$@ --output=$@
%/zscore/normalize.nii: 
	mkdir -p $(@D)
	python normalization.py --imagefile=$*/image.nii  --output=$@
%/bias/normalize.nii: 
	mkdir -p $(@D)
	c3d -verbose $*/image.nii  -shift 1  -o  $@
	/opt/apps/ANTS/dev/install/bin/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -i $@ -o  $@
	python normalization.py --imagefile=$@ --output=$@
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

%/crop/Volume.nii: %/normalize.nii
	mkdir -p $*/crop; mkdir -p $*/256; mkdir -p $*/512;
	python resize.py --imagefile=$<  --output=$@
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


###########################################################################
.SECONDEXPANSION:
#https://www.gnu.org/software/make/manual/html_node/Secondary-Expansion.html#Secondary-Expansion
###########################################################################
## #https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
## # dilate mask
## biasbcm: $(foreach idc,$(filter-out fixed,$(BCMCONTRASTLIST)),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).bias.nii.gz,$(BCMLISTUID)))) 
## #bias correction
## bcmdata/%.bias.nii.gz: bcmdata/%.longregcc.nii.gz bcmdata/$$(*D)/fixed.liver.nii.gz
## 	/opt/apps/ANTS/dev/install/bin/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -x $(word 2,$^)  -i $< -o $@
bcmdata/%.longregcc.nii.gz: bcmdata/%.bias.nii.gz bcmdata/$$(*D)/fixed.bias.nii.gz
	echo "bsub -Is -q interactive -W 6:00 -M 32 -R rusage[mem=32] -n 4 /usr/bin/bash"
	export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=28; bsub  -env "all" -J $(subst /,,$*) -Ip -cwd $(CLUSTERDIR) -n 28 -W 00:55 -q short -M 128 -R rusage[mem=128] -o  $(basename $(basename $@)).log /risapps/rhel7/ANTs/20200622/bin/antsRegistration --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/fixed.mask.nii.gz,bcmdata/$*.mask.nii.gz] -r [ $(@D)/fixed.mask.nii.gz,bcmdata/$*.mask.nii.gz,1] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/fixed.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[ 0.1 ] --metric MI[ $(@D)/fixed.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[ 0.1,3,0 ] --metric CC[$(@D)/fixed.bias.nii.gz,$<,1,4 ] --convergence [ 100x70x50x20,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox 

