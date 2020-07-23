%  @amaleki101 @EGates1 @MBhatter @psarlashkar @RajiMR 
%   base class for image segmentation

classdef ImageSegmentationBaseClass  < handle
   properties
      % Value {mustBeNumeric}
      lgraph %   NN data structure
      patchSize
      patchPerImage 
   end
   % abstact base class methods
   methods (Abstract)
      % TODO - @amaleki101 @EGates1 @MBhatter @psarlashkar @RajiMR  - what other NN methods should we add ? 
      loadneuralnet(obj,NumberChannels) % derived/inherited classes will define the architecture
   end
   methods

      function obj = ImageSegmentationBaseClass()
        
        % initialize NN
        obj.lgraph = layerGraph();
      end

   end
end


