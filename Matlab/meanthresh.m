%MEANTHRESH local thresholding.
%   BW = MEANTHRESH(IMAGE) performs local thresholding of a two-dimensional 
%   array IMAGE with mean thresh algorithm.
%      
%   BW = MEANTHRESH(IMAGE, [M N], THRESHOLD, PADDING) performs local 
%   thresholding with M-by-N neighbourhood (the default is 15-by-15) and 
%   threshold THRESHOLD between 0 and 1 (the default is 0.1). 
%   To deal with border pixels the image is padded with PADARRAY. The 
%   PADDING parameter can be either set to a scalar or a string: 
%       'circular'    Pads with circular repetition of elements.
%       'replicate'   Repeats border elements of matrix A (default).
%       'symmetric'   Pads array with mirror reflections of itself. 
%       
%   Example
%   -------
%       imshow(meanthresh(imread('eight.tif'), [150 150], 0.14));
%
%   See also PADARRAY, RGB2GRAY.

%   Contributed by Jan Motl (jan@motl.us)
%   $Revision: 1.1 $  $Date: 2013/03/09 16:58:01 $

function output = meanthresh(image, varargin)
% Initialization
numvarargs = length(varargin);      % Only want 3 optional inputs at most
if numvarargs > 3
    error('myfuns:somefun2Alt:TooManyInputs', ...
     'Possible parameters are: (image, [m n], threshold, padding)');
end
 
optargs = {[15 15] 0.1 'replicate'};  % Set defaults
 
optargs(1:numvarargs) = varargin;   % Use memorable variable names
[window, c, padding] = optargs{:};


% Convert to grayscale double in range 0..1
image = mat2gray(image(:,:,1));

% Mean value
mean = averagefilter(image, window, padding);

% Set pixel to white if brightnes is above the local neighbourhood
output = zeros(size(image));
output(image >= mean-c) = 1;
