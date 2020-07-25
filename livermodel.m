%% liver segmentation on MRI
function livermodel( jsonFilename  )
  % load all configuration data
  disp(jsonFilename  )
  jsonText = fileread(jsonFilename);
  jsonData = jsondecode(jsonText);

  % https://www.mathworks.com/help/matlab/matlab_external/use-python-dict-type-in-matlab.html
  % order = py.dict(pyargs('soup',ImageSegmentationUnet3D,'bread',2.29,'bacon',3.91,'salad',5.00))
  
  %% instantiate class
  switch jsonData.nnmodel
       case 'densenet2d' 
         a = ImageSegmentationDensenet2D(jsonData.resolution)
       case 'densenet3d' 
         a = ImageSegmentationDensenet3D(jsonData.resolution)
       case 'unet2d'     
         a = ImageSegmentationUnet2D(jsonData.resolution)
       case 'unet3d'    
         a = ImageSegmentationUnet3D(jsonData.resolution)
       otherwise
         disp('unknown')
  end

  gpuDevice(1)
  
  % before starting, need to define "n" which is the number of channels.
  NumberOfChannels = 1;
  a.loadneuralnet(NumberOfChannels)
  
  % functiom point to load mat files
  procReader = @(x) niftiread(x);
  
  % read image volume data
  trainData      = imageDatastore(fullfile('anonymize',jsonData.trainset     ,jsonData.normalization,sprintf('%d',jsonData.resolution),'Art.nii') , 'FileExtensions','.nii','ReadFcn',procReader);
  validationData = imageDatastore(fullfile('anonymize',jsonData.validationset,jsonData.normalization,sprintf('%d',jsonData.resolution),'Art.nii') , 'FileExtensions','.nii','ReadFcn',procReader);
  
  % read these into pixellabeldatastores
  classNames = ["background","liver"];
  pixelLabelID = [0 1];
  trainMask      = pixelLabelDatastore(fullfile('anonymize',jsonData.trainset     ,sprintf('%d',jsonData.resolution),'Truth.nii'),classNames,pixelLabelID, 'FileExtensions','.nii','ReadFcn',procReader );
  validationMask = pixelLabelDatastore(fullfile('anonymize',jsonData.validationset,sprintf('%d',jsonData.resolution),'Truth.nii'),classNames,pixelLabelID, 'FileExtensions','.nii','ReadFcn',procReader );
  
  % Need Random Patch Extraction on testing and validation Data
  miniBatchSize = 8;
    %training patch datastore
  trainPatch = randomPatchExtractionDatastore(trainData,trainMask,a.patchSize, ...
      'PatchesPerImage',a.patchPerImage);
  trainPatch.MiniBatchSize = miniBatchSize;
    %validation patch datastore
  validationPatch = randomPatchExtractionDatastore(validationData,validationMask,a.patchSize, ...
      'PatchesPerImage',a.patchPerImage);
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
  save([jsonData.uidoutputdir '/trainedNet.mat'],'net','options','modelDateTime','info');

end
