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

bar(categorical(tabledensenet2d.InstanceUID) , [tabledensenet2d.DiceSimilarity tabledensenet3d.DiceSimilarity tableunet2d.DiceSimilarity     tableunet3d.DiceSimilarity     ])
legend('densenet2d', 'densenet3d', 'unet2d', 'unet3d')

