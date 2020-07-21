%% liver segmentation on MRI
% Setting up the code: fresh start
clear all
close all

%% instantiate class
% TODO - load  multiple networks ? 

% https://www.mathworks.com/help/matlab/matlab_external/use-python-dict-type-in-matlab.html
% order = py.dict(pyargs('soup',3.57,'bread',2.29,'bacon',3.91,'salad',5.00))

trainingList = {...
     ImageSegmentationUnet3D('Processed/hccmrilog/dscimg/unet3d/adadelta/512/run_a/005020/005/000/setup.json'),...
     ImageSegmentationUnet3D('Processed/hccmrilog/dscimg/unet3d/adadelta/512/run_a/005020/005/001/setup.json'),...
     ImageSegmentationUnet3D('Processed/hccmrilog/dscimg/unet3d/adadelta/512/run_a/005020/005/002/setup.json'),...
     ImageSegmentationUnet3D('Processed/hccmrilog/dscimg/unet3d/adadelta/512/run_a/005020/005/003/setup.json'),...
     ImageSegmentationUnet3D('Processed/hccmrilog/dscimg/unet3d/adadelta/512/run_a/005020/005/004/setup.json'),...
     ImageSegmentationDensenet3D('Processed/hccmrilog/dscimg/densenet3d/adadelta/512/run_a/005020/005/000/setup.json'),...
     ImageSegmentationDensenet3D('Processed/hccmrilog/dscimg/densenet3d/adadelta/512/run_a/005020/005/001/setup.json'),...
     ImageSegmentationDensenet3D('Processed/hccmrilog/dscimg/densenet3d/adadelta/512/run_a/005020/005/002/setup.json'),...
     ImageSegmentationDensenet3D('Processed/hccmrilog/dscimg/densenet3d/adadelta/512/run_a/005020/005/003/setup.json'),...
     ImageSegmentationDensenet3D('Processed/hccmrilog/dscimg/densenet3d/adadelta/512/run_a/005020/005/004/setup.json'),...
                };

%for idtrain= 1: numel(trainingList )
for idtrain= 7:7
  % walker - best way to parallelize ? 
  a = trainingList{idtrain} ; 
  
  % before starting, need to define "n" which is the number of channels.
  NumberOfChannels = 1;
  a.loadneuralnet(NumberOfChannels)
  
  % functiom point to load mat files
  procReader = @(x) niftiread(x);
  
  % read image volume data
  trainData      = imageDatastore(fullfile('anonymize',a.jsonData.trainset     ,'Art.scaled.nii') , 'FileExtensions','.nii','ReadFcn',procReader);
  validationData = imageDatastore(fullfile('anonymize',a.jsonData.validationset,'Art.scaled.nii') , 'FileExtensions','.nii','ReadFcn',procReader);
  
  % read these into pixellabeldatastores
  classNames = ["background","liver"];
  pixelLabelID = [0 1];
  trainMask      = pixelLabelDatastore(fullfile('anonymize',a.jsonData.trainset     ,'Truth.resize.nii'),classNames,pixelLabelID, 'FileExtensions','.nii','ReadFcn',procReader );
  validationMask = pixelLabelDatastore(fullfile('anonymize',a.jsonData.validationset,'Truth.resize.nii'),classNames,pixelLabelID, 'FileExtensions','.nii','ReadFcn',procReader );
  
  % Need Random Patch Extraction on testing and validation Data
  patchSize = [64 64 64];
  patchPerImage = 16;
  miniBatchSize = 8;
    %training patch datastore
  trainPatch = randomPatchExtractionDatastore(trainData,trainMask,patchSize, ...
      'PatchesPerImage',patchPerImage);
  trainPatch.MiniBatchSize = miniBatchSize;
    %validation patch datastore
  validationPatch = randomPatchExtractionDatastore(validationData,validationMask,patchSize, ...
      'PatchesPerImage',patchPerImage);
  validationPatch.MiniBatchSize = miniBatchSize;
  
  % training options
  options = trainingOptions('adam', ...
      'MaxEpochs',50, ...
      'InitialLearnRate',5e-4, ...
      'LearnRateSchedule','piecewise', ...
      'LearnRateDropPeriod',5, ...
      'LearnRateDropFactor',0.95, ...
      'ValidationData',validationPatch, ...
      'ValidationFrequency',400, ...
      'Plots','training-progress', ...
      'Verbose',false, ...
      'MiniBatchSize',miniBatchSize);
      
  % train and save 
  modelDateTime = datestr(now,'dd-mmm-yyyy-HH-MM-SS')
  [net,info] = trainNetwork(trainPatch,a.lgraph,options);
  save([a.jsonData.uidoutputdir '/trained3DUNet.mat'],'net','options','modelDateTime');
end

