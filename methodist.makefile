SHELL := /bin/bash

METHODISTLISTUID  = $(shell sed 1d BerettaLab/wideformat.csv | cut -d, -f7 | cut -d/ -f9)
METHODISTCONTRASTLIST = Del Pst fixed
rawmethodist: $(foreach idc,$(METHODISTCONTRASTLIST),$(addprefix methodist/,$(addsuffix /$(idc).raw.nii.gz,$(METHODISTLISTUID)))) 
methodist/%/Del.raw.nii.gz:
	mkdir -p $(@D)
	/rsrch1/ip/dtfuentes/github/FileConversionScripts/seriesreadwriteall/DicomSeriesReadImageWriteAll $(dir $(shell sed 1d BerettaLab/wideformat.csv | cut -d, -f7 | grep $* )) $(@D) '0008|0032' 
	c3d -verbose $(@D)/$(shell sed 1d BerettaLab/wideformat.csv | grep $* | cut -d, -f3 )/*.nii.gz -o $(@D)/Del.raw.nii.gz -o $(@D)/Ven.raw.nii.gz -o $(@D)/Art.raw.nii.gz -o $(@D)/Pre.raw.nii.gz
methodist/%/Pst.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(dir $(shell sed 1d BerettaLab/wideformat.csv | grep $* | cut -d, -f8 ))  $@
methodist/%/fixed.raw.nii.gz:
	echo $@
