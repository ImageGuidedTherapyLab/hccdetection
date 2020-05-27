SHELL := /bin/bash
WORKDIR=Processed
DATADIR=/Radonc/Cancer\ Physics\ and\ Engineering\ Lab/Matthew\ Cagley/HCC\ MRI\ Cases/

-include datalocation/dependencies

art: $(addprefix $(WORKDIR)/,$(addsuffix /Art.raw.nii.gz,$(UIDLIST)))  
pre: $(addprefix $(WORKDIR)/,$(addsuffix /Pre.raw.nii.gz,$(UIDLIST)))  
ven: $(addprefix $(WORKDIR)/,$(addsuffix /Ven.raw.nii.gz,$(UIDLIST)))  
truth: $(addprefix $(WORKDIR)/,$(addsuffix /Truth.nii.gz,$(UIDLIST)))  


%/Art.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIR)/$(word 2,$(subst /, ,$*))/ART $@
%/Ven.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIR)/$(word 2,$(subst /, ,$*))/PV $@
%/Pre.raw.nii.gz:
	mkdir -p $(@D)
	DicomSeriesReadImageWrite2 $(DATADIR)/$(word 2,$(subst /, ,$*))/PRE $@
%/Truth.nii.gz: %/Art.raw.nii.gz
	mkdir -p $(@D)
	plastimatch convert --fixed $(@D)/Art.raw.nii.gz  --output-labelmap $@ --output-ss-img $(@D)/ss.nii.gz --output-ss-list $(@D)/ss.txt --output-dose-img $(@D)/dose.nii.gz --input $(DATADIR)/$(word 2,$(subst /, ,$*))/ART/RTSTRUCT*.dcm 
