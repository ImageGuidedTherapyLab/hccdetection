%% liver segmentation on MRI
%function livermodel( jsonFilename  )
  % load all configuration data
  jsonFilename = 'Processed/hccmrilog/dscimg/densenet3d/adadelta/256/hccmrima/005020/001/000/setup.json'
  disp(jsonFilename  )
  jsonText = fileread(jsonFilename);
  jsonData = jsondecode(jsonText)

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
  NumberOfChannels =  1; %jsonData.NumberOfChannels;
  a.loadneuralnet(NumberOfChannels)
  
  % functiom point to load mat files
  procReader  = @(x) (niftiread(x));
  labelReader = @(x) (niftiread(x));
  
  % read image volume data
  trainData      = imageDatastore(fullfile('anonymize',jsonData.trainset     ,sprintf('%d',jsonData.resolution),'Volume.nii') , 'FileExtensions','.nii','ReadFcn',procReader)
  imdstrainReSz = transform(trainData,@(x) x(:,:,:,1));
  validationData = imageDatastore(fullfile('anonymize',jsonData.validationset,sprintf('%d',jsonData.resolution),'Volume.nii') , 'FileExtensions','.nii','ReadFcn',procReader);
  imdsvalidationReSz = transform(validationData,@(x) x(:,:,:,1));
  
  % read these into pixellabeldatastores
  classNames = ["background","liver"]
  pixelLabelID = [0 1]
  trainMask      = pixelLabelDatastore(fullfile('anonymize',jsonData.trainset     ,sprintf('../%d',jsonData.resolution),'Truth.nii'),classNames,pixelLabelID, 'FileExtensions','.nii','ReadFcn',labelReader )
  validationMask = pixelLabelDatastore(fullfile('anonymize',jsonData.validationset,sprintf('../%d',jsonData.resolution),'Truth.nii'),classNames,pixelLabelID, 'FileExtensions','.nii','ReadFcn',labelReader );
  
  % Need Random Patch Extraction on testing and validation Data
  miniBatchSize = 8;
    %training patch datastore
  trainPatch = randomPatchExtractionDatastore(trainData,trainMask,a.patchSize, ...
      'PatchesPerImage',a.patchPerImage);
  trainPatch.MiniBatchSize = miniBatchSize;
    %validation patch datastore
  validationPatch = randomPatchExtractionDatastore(validationData ,validationMask,a.patchSize, ...
      'PatchesPerImage',a.patchPerImage);
  validationPatch.MiniBatchSize = miniBatchSize;
  
  % training options
  options = trainingOptions('adam', ...
      'MaxEpochs',100, ...
      'InitialLearnRate',5e-4, ...
      'LearnRateSchedule','piecewise', ...
      'LearnRateDropPeriod',5, ...
      'LearnRateDropFactor',0.95, ...
      'ValidationData',validationPatch, ...
      'ValidationFrequency',400, ...
      'ValidationPatience',10, ...
      'Plots','training-progress', ...
      'Verbose',false, ...
      'MiniBatchSize',miniBatchSize)

  % train and save 
  modelDateTime = datestr(now,'dd-mmm-yyyy-HH-MM-SS')
  [net,info] = trainNetwork(trainPatch,a.lgraph,options);
  save([jsonData.uidoutputdir '/trainedNet.mat'],'net','options','modelDateTime','info');
  infotable = struct2table(info);
  writetable(infotable, [jsonData.uidoutputdir  '/info.txt']);

%end
