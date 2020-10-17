SHELL := /bin/bash
# keep tmp files
.SECONDARY: 
MATLABROOT      := /opt/apps/matlab/R2020a/

MTHLISTUID  = $(shell sed 1d BerettaLab/wideformat.csv | cut -d, -f7 | cut -d/ -f9)
MTHCONTRASTLIST = Del Pre Art Ven Pst fixed
rawmethodist: $(foreach idc,$(MTHCONTRASTLIST),$(addprefix methodist/,$(addsuffix /$(idc).raw.nii.gz,$(MTHLISTUID)))) 
methodist/%/Pre.raw.nii.gz: ;
methodist/%/Art.raw.nii.gz: ;
methodist/%/Ven.raw.nii.gz: ;
methodist/%/Del.raw.nii.gz:
	mkdir -p $(@D)
	/rsrch1/ip/dtfuentes/github/FileConversionScripts/seriesreadwriteall/DicomSeriesReadImageWriteAll $(shell sed 1d BerettaLab/wideformat.csv | cut -d, -f7 | grep $*  ) $(@D) '0008|0032' 
	c3d -verbose $(@D)/$(shell sed 1d BerettaLab/wideformat.csv | grep $* | cut -d, -f3 )/*.nii.gz -o $(@D)/Del.raw.nii.gz -pop -o $(@D)/Ven.raw.nii.gz  -pop -o $(@D)/Art.raw.nii.gz  -pop -o $(@D)/Pre.raw.nii.gz
methodist/%/Pst.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(shell sed 1d BerettaLab/wideformat.csv | grep $* | cut -d, -f8 )  $@
rawmethodistfixed: $(addprefix methodist/,$(addsuffix /fixed.raw.nii.gz,$(MTHLISTUID)))
methodist/%/fixed.raw.nii.gz:
	ln -snf Art.raw.nii.gz $@
methodist/%Pre/fixed.raw.nii.gz:
	ln -snf ../$*HCC/Art.raw.nii.gz $@
viewraw: $(addprefix methodist/,$(addsuffix /viewraw,$(MTHLISTUID)))  
%/viewraw: 
	c3d $(@D)/Pre.raw.nii.gz -info  $(@D)/Ven.raw.nii.gz -info $(@D)/Art.raw.nii.gz -info  $(@D)/Del.raw.nii.gz -info  $(@D)/Pst.raw.nii.gz -info
	vglrun itksnap -g  $(@D)/Art.raw.nii.gz  -o $(@D)/Ven.raw.nii.gz $(@D)/Pre.raw.nii.gz  $(@D)/Del.raw.nii.gz $(@D)/Pst.raw.nii.gz 
viewlbl: $(addprefix methodist/,$(addsuffix /viewlbl,$(MTHLISTUID)))  
%/viewlbl: 
	vglrun itksnap -g $(@D)/Pre.raw.nii.gz -s $(@D)/Pre.liver.nii.gz-s $(@D)/Pre.liver.nii.gz &
	vglrun itksnap -g $(@D)/Art.raw.nii.gz -s $(@D)/Art.liver.nii.gz-s $(@D)/Art.liver.nii.gz &
	vglrun itksnap -g $(@D)/Ven.raw.nii.gz -s $(@D)/Ven.liver.nii.gz-s $(@D)/Ven.liver.nii.gz &
	vglrun itksnap -g $(@D)/Del.raw.nii.gz -s $(@D)/Del.liver.nii.gz-s $(@D)/Del.liver.nii.gz ; pkill -9 ITK-SNAP
viewmthlong: $(addprefix methodist/,$(addsuffix /viewmthlong,$(MTHLISTUID)))  
%/viewmthlong: 
	c3d -verbose $(@D)/fixed.bias.nii.gz  -info $(@D)/fixed.mask.nii.gz  -info -lstat
	c3d -verbose $(@D)/Pre.bias.nii.gz    -info $(@D)/Pre.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Art.bias.nii.gz    -info $(@D)/Art.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Ven.bias.nii.gz    -info $(@D)/Ven.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Del.bias.nii.gz    -info $(@D)/Del.mask.nii.gz    -info -lstat
	c3d -verbose $(@D)/Pst.bias.nii.gz    -info $(@D)/Pst.mask.nii.gz    -info -lstat
	vglrun itksnap -g  $(@D)/fixed.bias.nii.gz  -s $(@D)/fixed.liver.nii.gz  -o $(@D)/Pre.longregcc.nii.gz $(@D)/Art.longregcc.nii.gz $(@D)/Ven.longregcc.nii.gz $(@D)/Del.longregcc.nii.gz $(@D)/Pst.longregcc.nii.gz & vglrun itksnap -g  $(@D)/Pre.bias.nii.gz  -s $(@D)/Pre.mask.nii.gz  & vglrun itksnap -g  $(@D)/Art.bias.nii.gz  -s $(@D)/Art.mask.nii.gz  & vglrun itksnap -g  $(@D)/Ven.bias.nii.gz  -s $(@D)/Ven.mask.nii.gz & vglrun itksnap -g  $(@D)/Del.bias.nii.gz  -s $(@D)/Del.mask.nii.gz   & vglrun itksnap -g  $(@D)/Pst.bias.nii.gz  -s $(@D)/Pst.mask.nii.gz & SOLNSTATUS=$$(zenity  --list --title="QA" --text="$*"  --editable  --column "Status" RegistrationError MaskError PulseSequence Usable ) ; echo $$SOLNSTATUS; echo $$SOLNSTATUS >  $*/reviewsolution.txt ;   pkill -9 ITK-SNAP

# preprocess data
resizemth: $(foreach idc,$(MTHCONTRASTLIST),$(addprefix methodist/,$(addsuffix /$(idc).crop.nii.gz,$(MTHLISTUID)))) 
biasmth: $(foreach idc,$(MTHCONTRASTLIST),$(addprefix methodist/,$(addsuffix /$(idc).bias.nii.gz,$(MTHLISTUID)))) 
resizemthfixed: $(addprefix methodist/,$(addsuffix /fixed.crop.nii.gz,$(MTHLISTUID))) 
methodist/%.zscore.nii.gz: 
	python normalization.py --imagefile=methodist/$*.raw.nii.gz  --output=$@
methodist/%.bias.nii.gz: 
	c3d -verbose methodist/$*.raw.nii.gz  -shift 1  -o  $@
	/opt/apps/ANTS/dev/install/bin/N4BiasFieldCorrection -v 1 -d 3 -c [20x20x20x10,0] -b [200] -s 2 -i  $@  -o  $@
	python normalization.py --imagefile=$@  --output=$@
methodist/%.crop.nii.gz: methodist/%.zscore.nii.gz
	python resize.py --imagefile=methodist/$*.zscore.nii.gz  --output=$@
# label data
labelmth: $(foreach idc,$(MTHCONTRASTLIST),$(addprefix methodist/,$(addsuffix /$(idc).label.nii.gz,$(MTHLISTUID)))) 
methodist/%/label.nii.gz: methodist/%.256.nii.gz
	echo applymodel\('$<','Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat','$(@D)','1','gpu'\)
	mkdir -p $(@D);./run_applymodel.sh $(MATLABROOT) $< Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/restore_10162020/trainedNet.mat $(@D) 1 gpu
	echo vglrun itksnap -g $< -s methodist/$*/label.nii.gz -o methodist/$*/score.nii.gz
methodist/%.label.nii.gz: methodist/%/label.nii.gz
	c3d -verbose methodist/$*.raw.nii.gz $< -reslice-identity -o $@
# dilate mask
maskmth: $(foreach idc,$(MTHCONTRASTLIST),$(addprefix methodist/,$(addsuffix /$(idc).mask.nii.gz,$(MTHLISTUID)))) 
methodist/%.mask.nii.gz: 
	c3d -verbose methodist/$*.label.nii.gz  -thresh 2 2 1 0  -comp -thresh 1 1 1 0  -o  methodist/$*.liver.nii.gz -dilate 1 15x15x15vox -o $@
# register study
regmth:  $(foreach idc,$(filter-out Art fixed,$(MTHCONTRASTLIST)),$(addprefix methodist/,$(addsuffix /$(idc).regcc.nii.gz,$(MTHLISTUID)))) 
methodist/%.regcc.nii.gz: methodist/%.bias.nii.gz methodist/%.mask.nii.gz
	export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=24; /opt/apps/ANTS/dev/install/bin/antsRegistration --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/Art.mask.nii.gz,$(word 2,$^)] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/Art.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[ 0.1 ] --metric MI[ $(@D)/Art.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[ 0.1,3,0 ] --metric CC[ $(@D)/Art.bias.nii.gz,$<,1,4 ] --convergence [ 100x70x50x20,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox > $(basename $(basename $@)).log  2>&1
# register longitudinal
CLUSTERDIR = /rsrch3/home/imag_phy-rsrch/dtfuentes/github/hccdetection
longregmth: $(foreach idc,$(filter-out fixed,$(MTHCONTRASTLIST)),$(addprefix methodist/,$(addsuffix /$(idc).longregcc.nii.gz,$(MTHLISTUID)))) 
# debug initialization
methodist/%.longregdbginitial.nii.gz: methodist/%.bias.nii.gz 
	/opt/apps/ANTS/dev/install/bin/antsRegistration  --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/fixed.mask.nii.gz,methodist/$*.mask.nii.gz] -r [ $(@D)/fixed.mask.nii.gz,methodist/$*.mask.nii.gz,1] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/fixed.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 0x0x0x0,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox 
	vglrun itksnap -g $(@D)/fixed.bias.nii.gz -o $@
methodist/%.longregcc.nii.gz: methodist/%.bias.nii.gz 
	echo "bsub -Is -q interactive -W 6:00 -M 32 -R rusage[mem=32] -n 4 /usr/bin/bash"
	export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=28; bsub  -env "all" -J $(subst /,,$*) -Ip -cwd $(CLUSTERDIR) -n 28 -W 00:55 -q short -M 128 -R rusage[mem=128] -o  $(basename $(basename $@)).log /risapps/rhel7/ANTs/20200622/bin/antsRegistration --verbose 1 --dimensionality 3 --float 0 --collapse-output-transforms 1 --output [$(basename $(basename $@)),$@] --interpolation Linear --use-histogram-matching 0 --winsorize-image-intensities [ 0.005,0.995 ] -x [$(@D)/fixed.mask.nii.gz,methodist/$*.mask.nii.gz] -r [ $(@D)/fixed.mask.nii.gz,methodist/$*.mask.nii.gz,1] --transform Rigid[ 0.1 ] --metric MI[ $(@D)/fixed.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[ 0.1 ] --metric MI[ $(@D)/fixed.bias.nii.gz,$<,1,32,Regular,0.25 ] --convergence [ 1000x500x250x100,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[ 0.1,3,0 ] --metric CC[$(@D)/fixed.bias.nii.gz,$<,1,4 ] --convergence [ 100x70x50x20,1e-6,10 ] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox 

clusterrsync:
	rsync -n -v -avz  --include={'*256.nii.gz','*mask.nii.gz'} --include='MTH*/' --exclude='*'  methodist/  /rsrch3/ip/dtfuentes/github/hccdetection/methodist/
radoncsync:
	rsync    -v -avz  --include={'*bias.nii.gz','*256.nii.gz','*mask.nii.gz'} --include='MTH*/' --exclude='*'  methodist/  /Radonc/Cancer\ Physics\ and\ Engineering\ Lab/David\ Fuentes/hccdetection/methodist/

