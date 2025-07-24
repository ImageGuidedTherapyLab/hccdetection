
/rsrch1/ip/dtfuentes/minicondamist/bin/mist_convert_dataset --format csv --train-csv /rsrch3/ip/dtfuentes/github/hccdetection/litstrainingdata.csv --dest /rsrch3/ip/dtfuentes/github/hccdetection/mistlits/train

/rsrch1/ip/dtfuentes/minicondamist/bin/mist_run_all --data /rsrch3/ip/dtfuentes/github/oncopigdata/misttrain/dataset.json --numpy /rsrch3/ip/dtfuentes/github/oncopigdata/misttrainnumpy --results /rsrch3/ip/dtfuentes/github/oncopigdata/misttrainresults --gpus 0

/rsrch1/ip/dtfuentes/minicondamist/bin/mist_analyze --data /rsrch3/ip/dtfuentes/github/oncopigdata/misttrain/dataset.json  --results /rsrch3/ip/dtfuentes/github/oncopigdata/misttrainresults 
/rsrch1/ip/dtfuentes/minicondamist/bin/mist_preprocess --data /rsrch3/ip/dtfuentes/github/oncopigdata/misttrain/dataset.json --numpy /rsrch3/ip/dtfuentes/github/oncopigdata/misttrainnumpy --results /rsrch3/ip/dtfuentes/github/oncopigdata/misttrainresults 
/rsrch1/ip/dtfuentes/minicondamist/bin/mist_train --data /rsrch3/ip/dtfuentes/github/oncopigdata/misttrain/dataset.json --numpy /rsrch3/ip/dtfuentes/github/oncopigdata/misttrainnumpy --results /rsrch3/ip/dtfuentes/github/oncopigdata/misttrainresults --gpus 0 --amp --pocket 

