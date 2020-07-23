% inputniftifilepath - input full path to nifti file
% mynetwork - input full path to the NN we will use
% gpuid  - integer id of gpu card to use
% ExecutionEnvironment -  cpu or gpu
% outputpath - output path where files will be written
function applymodel( inputniftifilepath, mynetwork, outputpath, gpuid ,ExecutionEnvironment  )

disp( ['inputniftifilepath= ''',inputniftifilepath,''';']);      
disp( ['mynetwork         = ''',mynetwork         ,''';']);      
disp( ['outputpath        = ''',outputpath        ,''';']);  

gpuDevice(str2double(gpuid))

%% load nifti file
info = niftiinfo(inputniftifilepath );
niivolume = niftiread(info);

%% load trained network
trainedNN = load(mynetwork )

%% apply trained network to nifti image
tStart = tic;
tempSeg = semanticseg(niivolume ,trainedNN.net,'ExecutionEnvironment',ExecutionEnvironment, 'outputtype', 'uint8');
%tempSeg = segmentImagePatchwise(niivolume ,trainedNN.net, [256 256 144]);
tEnd = toc(tStart)

%% write output to disk as a nifti file
outputlabel = fullfile(outputpath,'label')
infoout = info;
infoout.Filename = outputlabel;
infoout.Datatype = 'uint8';
niftiwrite(uint8(tempSeg) ,outputlabel ,infoout,'Compressed',true)

end
