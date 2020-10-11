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
LiverMRIProjectData/dataqa.csv:
	echo StudyUID,Status > $@
	for idfile in  bcmdata/BCM*/reviewsolution.txt ; do STUDYUID=$$(echo $$idfile | cut -d '/' -f2); sed "s/^/$$STUDYUID,/g" $$idfile; done >> $@
LiverMRIProjectData/wideanon.csv:
	 cat wide.sql  | sqlite3
BCMDATADIR=LiverMRIProjectData/tmpconvert/
BCMWORKDIR=bcmdata
BCMLISTUID  = $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f1 )
BCMLISTPRE  = $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f4 )
BCMLISTART  = $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f5 )
BCMLISTVEN  = $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f6 )
BCMLISTDEL  = $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f7 )
BCMLISTPST  = $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f8 )
BCMLISTFIX  = $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f12)
BCMCONTRASTLIST = Pre Art Ven Del Pst fixed

rawbcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).raw.nii.gz,$(BCMLISTUID)))) 
$(BCMWORKDIR)/%/Pre.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTPRE)).nii.gz  -o $@
$(BCMWORKDIR)/%/Art.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTART)).nii.gz  -o $@
$(BCMWORKDIR)/%/Ven.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTVEN)).nii.gz  -o $@
$(BCMWORKDIR)/%/Del.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTDEL)).nii.gz  -o $@
$(BCMWORKDIR)/%/Pst.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$*/$(word $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTPST)).nii.gz  -o $@
$(BCMWORKDIR)/%/fixed.raw.nii.gz:
	mkdir -p $(@D); c3d  $(BCMDATADIR)/$(word $(shell sed 1d LiverMRIProjectData/wideanon.csv | cut -d, -f1 | grep -n $* |cut -f1 -d: ), $(BCMLISTFIX)).nii.gz  -o $@

viewbcm: $(addprefix $(BCMWORKDIR)/,$(addsuffix /viewbcm,$(BCMLISTUID)))  
%/viewbcm: 
	c3d $(@D)/Pre.raw.nii.gz -info  $(@D)/Ven.raw.nii.gz -info $(@D)/Art.raw.nii.gz -info   $(@D)/Del.raw.nii.gz  -info $(@D)/Pst.raw.nii.gz  -info
	vglrun itksnap -g  $(@D)/Art.raw.nii.gz   -o $(@D)/Ven.raw.nii.gz $(@D)/Pre.raw.nii.gz $(@D)/Del.raw.nii.gz $(@D)/Pst.raw.nii.gz
	vglrun itksnap -g  $(@D)/Pre.256.nii.gz   -o $(@D)/Pre/score.nii.gz -s  $(@D)/Pre/label.nii.gz
	vglrun itksnap -g  $(@D)/Art.256.nii.gz   -o $(@D)/Art/score.nii.gz -s  $(@D)/Art/label.nii.gz
	vglrun itksnap -g  $(@D)/Ven.256.nii.gz   -o $(@D)/Ven/score.nii.gz -s  $(@D)/Ven/label.nii.gz
	vglrun itksnap -g  $(@D)/Del.256.nii.gz   -o $(@D)/Del/score.nii.gz -s  $(@D)/Del/label.nii.gz
viewbcmlong: $(addprefix $(BCMWORKDIR)/,$(addsuffix /viewbcmlong,$(BCMLISTUID)))  
%/viewbcmlong: 
	c3d -verbose $(@D)/fixed.256.nii.gz  -info $(@D)/fixed.mask.nii.gz  -info -lstat
	c3d -verbose $(@D)/Art.256.nii.gz    -info $(@D)/Art.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Pre.256.nii.gz    -info $(@D)/Pre.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Art.256.nii.gz    -info $(@D)/Art.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Ven.256.nii.gz    -info $(@D)/Ven.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Del.256.nii.gz    -info $(@D)/Del.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Pst.256.nii.gz    -info $(@D)/Pst.mask.nii.gz    -info -lstat
	vglrun itksnap -g  $(@D)/fixed.256.nii.gz  -s $(@D)/fixed.liver.nii.gz  -o $(@D)/Pre.longregcc.nii.gz $(@D)/Art.longregcc.nii.gz $(@D)/Ven.longregcc.nii.gz $(@D)/Del.longregcc.nii.gz $(@D)/Pst.longregcc.nii.gz & vglrun itksnap -g  $(@D)/Pre.256.nii.gz  -s $(@D)/Pre.mask.nii.gz  & vglrun itksnap -g  $(@D)/Art.256.nii.gz  -s $(@D)/Art.mask.nii.gz  & vglrun itksnap -g  $(@D)/Ven.256.nii.gz  -s $(@D)/Ven.mask.nii.gz & vglrun itksnap -g  $(@D)/Del.256.nii.gz  -s $(@D)/Del.mask.nii.gz   & vglrun itksnap -g  $(@D)/Pst.256.nii.gz  -s $(@D)/Pst.mask.nii.gz & SOLNSTATUS=$$(zenity  --list --title="QA" --text="$*"  --editable  --column "Status" RegistrationError MaskError PulseSequence Usable ) ; echo $$SOLNSTATUS; echo $$SOLNSTATUS >  $*/reviewsolution.txt ;   pkill -9 ITK-SNAP
$(BCMWORKDIR)/%/slic.nii.gz:
	c3d $(@D)/Pre.longregcc.nii.gz  -info $(@D)/Art.longregcc.nii.gz  -info  $(@D)/Ven.longregcc.nii.gz  -info $(@D)/Del.longregcc.nii.gz  -info   $(@D)/Pst.longregcc.nii.gz  -info -omc $(@D)/liverprotocol.nii.gz
	/rsrch1/ip/dtfuentes/github/ExLib/SLICImageFilter/itkSLICImageFilterTest $(@D)/liverprotocol.nii.gz $@ 10 1

# preprocess data
resizebcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).crop.nii.gz,$(BCMLISTUID)))) 
$(BCMWORKDIR)/%.normalize.nii.gz: $(BCMWORKDIR)/%.raw.nii.gz
	/opt/apps/ANTS/dev/install/bin/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -i $<  -o  $@
	python normalization.py --imagefile=$@  --output=$@
	/opt/apps/ANTS/dev/install/bin/ImageMath 3 $@ RescaleImage           $@ 0 1
$(BCMWORKDIR)/%.crop.nii.gz: $(BCMWORKDIR)/%.normalize.nii.gz
	python resize.py --imagefile=$<  --output=$@
# label data
labelbcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).label.nii.gz,$(BCMLISTUID)))) 
bcmdata/%/label.nii.gz: bcmdata/%.256.nii.gz
	echo applymodel\('$<','Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/trainedNet.mat','$(@D)','1','gpu'\)
	mkdir -p $(@D);./run_applymodel.sh $(MATLABROOT) $< Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/trainedNet.mat $(@D) 1 gpu
	echo vglrun itksnap -g $< -s bcmdata/$*/label.nii.gz -o bcmdata/$*/score.nii.gz
bcmdata/%.label.nii.gz: bcmdata/%/label.nii.gz
	c3d -verbose bcmdata/$*.raw.nii.gz $< -reslice-identity -o $@
# dilate mask
maskbcm: $(foreach idc,$(BCMCONTRASTLIST),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).mask.nii.gz,$(BCMLISTUID)))) 
bcmdata/%.mask.nii.gz: 
	c3d -verbose bcmdata/$*.label.nii.gz  -thresh 2 2 1 0  -comp -thresh 1 1 1 0  -o  bcmdata/$*.liver.nii.gz -dilate 1 15x15x15vox -o $@
# register study
regbcm:  $(foreach idc,$(filter-out Art fixed,$(BCMCONTRASTLIST)),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).regcc.nii.gz,$(BCMLISTUID)))) 
bcmdata/%.regcc.nii.gz: bcmdata/%.256.nii.gz bcmdata/%.mask.nii.gz
	export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=24; /opt/apps/ANTS/dev/install/bin/antsRegistration --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/Art.mask.nii.gz,$(word 2,$^)] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/Art.256.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[ 0.1 ] --metric MI[ $(@D)/Art.256.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[ 0.1,3,0 ] --metric CC[ $(@D)/Art.256.nii.gz,$<,1,4 ] --convergence [ 100x70x50x20,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox > $(basename $(basename $@)).log  2>&1
# register longitudinal
CLUSTERDIR = /rsrch3/home/imag_phy-rsrch/dtfuentes/github/hccdetection
longregbcm: $(foreach idc,$(filter-out fixed,$(BCMCONTRASTLIST)),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).longregcc.nii.gz,$(BCMLISTUID)))) 
# debug initialization
bcmdata/%.longregdbginitial.nii.gz: bcmdata/%.256.nii.gz 
	/opt/apps/ANTS/dev/install/bin/antsRegistration  --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/fixed.mask.nii.gz,bcmdata/$*.mask.nii.gz] -r [ $(@D)/fixed.mask.nii.gz,bcmdata/$*.mask.nii.gz,1] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/fixed.256.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 0x0x0x0,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox 
	vglrun itksnap -g $(@D)/fixed.256.nii.gz -o $@
bcmdata/%.longregcc.nii.gz: bcmdata/%.256.nii.gz 
	echo "bsub -Is -q interactive -W 6:00 -M 32 -R rusage[mem=32] -n 4 /usr/bin/bash"
	export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=28; bsub  -env "all" -J $(subst /,,$*) -Ip -cwd $(CLUSTERDIR) -n 28 -W 00:25 -q short -M 128 -R rusage[mem=128] -o  $(basename $(basename $@)).log /risapps/rhel7/ANTs/20200622/bin/antsRegistration --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/fixed.mask.nii.gz,bcmdata/$*.mask.nii.gz] -r [ $(@D)/fixed.mask.nii.gz,bcmdata/$*.mask.nii.gz,1] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/fixed.256.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[ 0.1 ] --metric MI[ $(@D)/fixed.256.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[ 0.1,3,0 ] --metric CC[ $(@D)/fixed.256.nii.gz,$<,1,4 ] --convergence [ 100x70x50x20,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox 

clusterrsync:
	rsync -n -v -avz  --include={'*256.nii.gz','*mask.nii.gz'} --include='BCM*/' --exclude='*'  bcmdata/  /rsrch3/ip/dtfuentes/github/hccdetection/bcmdata/
radoncsync:
	rsync    -v -avz  --include={'*bias.nii.gz','*256.nii.gz','*mask.nii.gz'} --include='BCM*/' --exclude='*'  bcmdata/  /Radonc/Cancer\ Physics\ and\ Engineering\ Lab/David\ Fuentes/hccdetection/bcmdata/

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
	/opt/apps/ANTS/dev/install/bin/ImageMath 3 $@ RescaleImage           $@ 0 1
%/zscore/normalize.nii: 
	mkdir -p $(@D)
	python normalization.py --imagefile=$*/image.nii  --output=$@
	/opt/apps/ANTS/dev/install/bin/ImageMath 3 $@ RescaleImage           $@ 0 1
%/bias/normalize.nii: 
	mkdir -p $(@D)
	/opt/apps/ANTS/dev/install/bin/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -i $*/image.nii  -o  $@
	python normalization.py --imagefile=$@  --output=$@
	/opt/apps/ANTS/dev/install/bin/ImageMath 3 $@ RescaleImage           $@ 0 1
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

bcmdata/BCM0001000/Pre/label.nii.gz: bcmdata/BCM0001000/Pre.256.nii.gz
	echo applymodel('$<','Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/trainedNet.mat','$(@D)','1','gpu')
	mkdir -p $(@D);./run_applymodel.sh $(MATLABROOT) $< Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/trainedNet.mat $(@D) 1 gpu
	echo vglrun itksnap -g bcmdata/BCM0001000/Pre.256.nii.gz -s bcmdata/BCM0001000/Pre/label.nii.gz -o bcmdata/BCM0001000/Pre/score.nii.gz


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
#https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
# dilate mask
biasbcm: $(foreach idc,$(filter-out fixed,$(BCMCONTRASTLIST)),$(addprefix $(BCMWORKDIR)/,$(addsuffix /$(idc).bias.nii.gz,$(BCMLISTUID)))) 
#bias correction
bcmdata/%.bias.nii.gz: bcmdata/%.longregcc.nii.gz bcmdata/$$(*D)/fixed.liver.nii.gz
	/opt/apps/ANTS/dev/install/bin/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -x $(word 2,$^)  -i $< -o $@
