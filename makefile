SHELL := /bin/bash
WORKDIR=Processed
DATADIR=/Radonc/Cancer\ Physics\ and\ Engineering\ Lab/Matthew\ Cagley/HCC\ MRI\ Cases/

-include datalocation/dependencies

art: $(addprefix $(WORKDIR)/,$(addsuffix /Art.raw.nii.gz,$(UIDLIST)))  


%/Art.raw.nii.gz:
	DicomSeriesReadImageWrite2 $(DATADIR) $@
