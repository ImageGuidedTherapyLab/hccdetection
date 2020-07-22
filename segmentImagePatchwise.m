% https://www.mathworks.com/matlabcentral/answers/385273-why-do-i-get-maximum-variable-size-allowed-on-the-device-is-exceeded-error-when-running-the-sema
%segmentImagePatchwise performs patchwise semantic segmentation on the input image
% using the provided network.
%
%  OUT = segmentImagePatchwise(IM, NET, PATCHSIZE) returns a semantically 
%  segmented image, segmented using the network NET. The segmentation is
%  performed patches-wise on patches of size PATCHSIZE.
%  PATCHSIZE is 1x2 vector holding [WIDTH HEIGHT] of the patch.

%   Copyright 1984-2018 The MathWorks, Inc.

function out = segmentImagePatchwise(im, net, patchSize)

[height, width, depth, nChannel] = size(im);
patch = zeros([patchSize, nChannel], 'like', im);

% pad image to have dimensions as multiples of patchSize
padSize(1) = patchSize(1) - mod(height,patchSize(1));
padSize(2) = patchSize(2) - mod(width, patchSize(2));
padSize(3) = patchSize(3) - mod(depth, patchSize(3));

im_pad = padarray (im, padSize, 0, 'post');
[height_pad, width_pad, depth_pad, nChannel_pad] = size(im_pad);

disp(sprintf('image size = [%d %d %d %d] ',height, width, depth, nChannel) )
disp(sprintf('pad   size = [%d %d %d %d] ',height_pad, width_pad, depth_pad, nChannel_pad) )
out = zeros([size(im_pad,1), size(im_pad,2), size(im_pad,3)], 'uint8');

for i = 1:patchSize(1):height_pad
  for j =1:patchSize(2):width_pad
    for k =1:patchSize(3):depth_pad
        disp([i j k])
        patch = im_pad(i:i+patchSize(1)-1, j:j+patchSize(2)-1, k:k+patchSize(3)-1,:);
        
        patch_seg = semanticseg(patch, net, 'outputtype', 'uint8');
        
        out(i:i+patchSize(1)-1, j:j+patchSize(2)-1, k:k+patchSize(3)-1) = patch_seg;
    end
  end
end

% Remove the padding
out = out(1:height, 1:width, 1:depth);
