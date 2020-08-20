SHELL := /bin/bash

# generate probability mask for each image
test/fixed/label.nii.gz:
	mkdir -p $(@D);./run_applymodel.sh /opt/apps/matlab/R2020a/ test/fixed.nii.gz Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/005/004/trainedNet.mat $(@D) 1 gpu
test/moving/label.nii.gz:
	mkdir -p $(@D);./run_applymodel.sh /opt/apps/matlab/R2020a/ test/moving.nii.gz Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/005/004/trainedNet.mat $(@D) 1 gpu
test/fixed_mask.nii.gz:
	c3d test/fixed.nii.gz test/fixed/score.nii.gz  -multiple -o $@
test/moving_mask.nii.gz:
	c3d test/moving.nii.gz test/moving/score.nii.gz  -multiple -o $@

# register probability mask for each image
test/movingdeformed.nii.gz:
	cd $(@D); ../../antsIntroduction.sh -d 3 -r fixed_mask.nii.gz -i moving_mask.nii.gz -o antsintro -n 0 -s MI -t GR -m 60x120x30
