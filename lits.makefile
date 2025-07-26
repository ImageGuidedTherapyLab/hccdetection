SHELL := /bin/bash

# keep tmp files
.SECONDARY: 
# setup CRC data
CRCLIST       = $(shell sed 1d crctrainingdata.csv | cut -f1 )
CRCIMAGELIST  = $(shell sed 1d crctrainingdata.csv | cut -f3 )
CRCLABELLIST  = $(shell sed 1d crctrainingdata.csv | cut -f4 )
DATADIRCRC=/rsrch1/ip/jacctor/LiTS/LiTS/
crcsetup: $(addprefix litsdata/,$(addsuffix /image.nii.gz,$(CRCLIST)))  $(addprefix litsdata/,$(addsuffix /label.nii.gz,$(CRCLIST)))  
litsdata/i%/image.nii.gz:
	mkdir -p $(@D)
	c3d $(DATADIRCRC)/$(word $(shell expr $* + 1 ), $(CRCIMAGELIST)) $@
litsdata/i%/label.nii.gz:
	mkdir -p $(@D)
	c3d $(DATADIRCRC)/$(word $(shell expr $* + 1 ), $(CRCLABELLIST)) $@
# mask the liver to segment the tumor
crctumor: $(addprefix litstumor/crctumor,$(addsuffix /setup,$(CRCLIST)))
litstumor/crctumori%/setup:
	mkdir -p $(@D)
	python liverboundingbox.py --imagefile=$(DATADIRCRC)/$(word $(shell expr $* + 1 ), $(CRCIMAGELIST)) --labelfile=$(DATADIRCRC)/$(word $(shell expr $* + 1 ), $(CRCLABELLIST))  --output=$(@D)
	c3d -verbose $(@D)/label.nii -thresh 2 2 1 0 -connected-components -o  $(@D)/comp.nii.gz
	echo python tumorboundingbox.py --imagefile=$(@D)/maskimage.nii --labelfile=$(@D)/comp.nii.gz --output=$(@D)

convertcsv:
	/opt/apps/miniforge/mist/bin/mist_convert_dataset --format csv --train-csv /rsrch3/ip/dtfuentes/github/hccdetection/litstrainingdata.csv --dest /rsrch3/ip/dtfuentes/github/hccdetection/mistlits/train

runall:
	/opt/apps/miniforge/mist/bin/mist_run_all --data  /rsrch3/ip/dtfuentes/github/hccdetection/litstumor.json /rsrch3/ip/dtfuentes/github/hccdetection/misttrain/litstumor.json --numpy /rsrch3/ip/dtfuentes/github/hccdetection/litstrainnumpy --results /rsrch3/ip/dtfuentes/github/hccdetection/litstrainresults --gpus 0

analyze:
	/opt/apps/miniforge/mist/bin/mist_analyze --data /rsrch3/ip/dtfuentes/github/hccdetection/litstumor.json  --results /rsrch3/ip/dtfuentes/github/hccdetection/litstrainresults
preprocess:
	/opt/apps/miniforge/mist/bin/mist_preprocess --data /rsrch3/ip/dtfuentes/github/hccdetection/litstumor.json --numpy /rsrch3/ip/dtfuentes/github/hccdetection/litstrainnumpy --results /rsrch3/ip/dtfuentes/github/hccdetection/litstrainresults 
train:
	/opt/apps/miniforge/mist/bin//mist_train  --data //rsrch3/ip/dtfuentes/github/hccdetection/litstumor.json --numpy //rsrch3/ip/dtfuentes/github/hccdetection/litstrainnumpy --results //rsrch3/ip/dtfuentes/github/hccdetection/litstrainresults  --oversampling .9  --gpus 0 --amp --pocket 
traindocker:
	docker run --entrypoint=/bin/bash --rm -it -u $(id -u):$(id -g) --env CUDA_VISIBLE_DEVICES=0   --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 -v $(PWD):/home  mistmedical/mist:0.2.1b0
	docker run --entrypoint=/opt/conda/bin/mist_train --rm -it -u $$(id -u):$$(id -g) --env CUDA_VISIBLE_DEVICES=0   --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 -v $(PWD):/home  mistmedical/mist:0.2.1b0 --data /home/litstumor.json --numpy /home/litstrainnumpy --results /home/litstrainresults --gpus 0 --amp --pocket  --oversampling O.9

