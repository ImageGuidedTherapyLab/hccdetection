%load data
mytable = readtable('overlap.csv', 'Delimiter', ',');

% get subsets
rowsdensenet2d = contains(mytable.InstanceUID,'densenet2d');
rowsdensenet3d = contains(mytable.InstanceUID,'densenet3d');
rowsunet2d     = contains(mytable.InstanceUID,'unet2d');
rowsunet3d     = contains(mytable.InstanceUID,'unet2d');
tabledensenet2d = mytable(rowsdensenet2d,:);
tabledensenet3d = mytable(rowsdensenet3d,:);
tableunet2d     = mytable(rowsunet2d    ,:);
tableunet3d     = mytable(rowsunet3d    ,:);

% summary statistics
meanvalues   = [mean(tabledensenet2d.DiceSimilarity)  ; mean(tabledensenet3d.DiceSimilarity)  ; mean(tableunet2d.DiceSimilarity)  ; mean(tableunet3d.DiceSimilarity)  ];
stdvalues    = [std(tabledensenet2d.DiceSimilarity)   ; std(tabledensenet3d.DiceSimilarity)   ; std(tableunet2d.DiceSimilarity)   ; std(tableunet3d.DiceSimilarity)   ];
varvalues    = [var(tabledensenet2d.DiceSimilarity)   ; var(tabledensenet3d.DiceSimilarity)   ; var(tableunet2d.DiceSimilarity)   ; var(tableunet3d.DiceSimilarity)   ];
medianvalues = [median(tabledensenet2d.DiceSimilarity); median(tabledensenet3d.DiceSimilarity); median(tableunet2d.DiceSimilarity); median(tableunet3d.DiceSimilarity)];
maxvalues    = [max(tabledensenet2d.DiceSimilarity)   ; max(tabledensenet3d.DiceSimilarity)   ; max(tableunet2d.DiceSimilarity)   ; max(tableunet3d.DiceSimilarity)   ];
minvalues    = [min(tabledensenet2d.DiceSimilarity)   ; min(tabledensenet3d.DiceSimilarity)   ; min(tableunet2d.DiceSimilarity)   ; min(tableunet3d.DiceSimilarity)   ];
tableuid     = [ {'densenet2d'}; {'densenet3d'}; {'unet2d'}; {'unet3d'}]
table(tableuid       , meanvalues   , stdvalues    , varvalues    , medianvalues , maxvalues    , minvalues    )


% bar graph
figure(1)
datalabels = split(tabledensenet2d.InstanceUID,'.')
bar(categorical({datalabels{:,1}}) , [tabledensenet2d.DiceSimilarity tabledensenet3d.DiceSimilarity tableunet2d.DiceSimilarity     tableunet3d.DiceSimilarity     ])
ylabel('Dice Similarity')
legend('densenet2d', 'densenet3d', 'unet2d', 'unet3d','Location','SouthEast')


% histogram
figure(2)
myhistogram = histogram(tabledensenet2d.DiceSimilarity,'BinWidth',.01,'Normalization','probability')
ycoords = myhistogram.Values;
edgecoords = myhistogram.BinEdges;
xcoords = (edgecoords(1:end-1)+edgecoords(2:end))./2;
hold on
plot(xcoords, ycoords)

