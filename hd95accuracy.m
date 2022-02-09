clear all
close all
%load data
mytable = readtable('hd95.csv', 'Delimiter', ',');
meanvalues   = mean(mytable.hd95)   ;
stdvalues    = std(mytable.hd95)    ;
varvalues    = var(mytable.hd95)    ;
medianvalues = median(mytable.hd95) ;
maxvalues    = max(mytable.hd95)    ;
minvalues    = min(mytable.hd95)    ;

table(meanvalues   , stdvalues    , varvalues    , medianvalues , maxvalues    , minvalues    )


