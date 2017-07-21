%{
    This script loads the video file selected by the user and performs 
    following operations:
        1)  Creates a video file for adding tracking information to the
            original video.
        2)  Using a Circular Hough Transform (CHT), it selects the circular
            uPADs in the frames.
        3)  Applies an Active Contour algorithm on the detected uPADs to
            refine the edges and handles worm detection even when they 
            are touching the edges of uPADs.
        4)  Removes the background from the frame by applying a local
            thresholding technique with a window size of 100x100 and a
            threshold value of 90%.
        5)  Identifies worms by characterization parameters for L4-stage 
            C. elegans and writes the centroid information to separate 
            excel files.
        6)  Repeats steps 2-5 for every frame.
        7)  Saves the tracking video and excel files.
%}

clc;clear all;close all;

% Worm characterization parameters
nBkgSamples = 50;
minWormArea = 50;
maxWormArea = 500;
maxSingleWormArea = 500;
biggestMove = 50; %pixels
 
% Load video
[file,path]=uigetfile('../../2016_trials/*.avi');
[~,filename,ext]=fileparts(file);

% Create video file with tracking information embedded 
mkdir([path,filename,'_excel']);
writerObj = VideoWriter([path,filename,'_tracked.avi']);
open(writerObj);

vidObj = VideoReader([path,filename,ext]);
nFrames = vidObj.NumberOfFrames;
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
vidFPS = vidObj.FrameRate;
[columnsInImage, rowsInImage] = meshgrid(1:vidWidth, 1:vidHeight);

% Find circles in the image by using the Circular Hough Transform algorithm
% (Refer to Fig. 3(b) in the paper)
firstImg=read(vidObj,1);
gray = rgb2gray(firstImg);
crMask = false(size(gray));
circlePixels = false(size(gray));
offset = 10;

% Circular hough transform with radius range of 50 to 110
[centers, radii, metric] = imfindcircles(imbinarize(gray),[50 110]);

% Fill the circles with white pixels to form a mask
for i = 1:length(radii)
    centerX= centers(i,1);
    centerY= centers(i,2);
    radius = radii(i);
    circlePixels = (rowsInImage - centerY).^2 ...
        + (columnsInImage - centerX).^2 <= (radius+offset).^2;
    k = find(circlePixels);
    crMask = bitor(circlePixels, crMask);
end

% Apply active contour algorithm with the hough circle mask to refine edges
% (Refer to Fig. 3(b) in the paper)
crMask = activecontour(gray,crMask,100,'edge');

% Create background image by taking average of all the frames in the video
IavgF = zeros(vidHeight, vidWidth, 3, 'double');
for i=1:nBkgSamples
    frame = read(vidObj,i);
    IavgF = IavgF + double(frame);
end
IavgF = uint8(IavgF./nBkgSamples);

numTestFrames = round(nFrames);
wormTracks = [];
xls_outputs = 1;
slow = 0;
for i=1:numTestFrames
    % Update background every one thousand frames to account for any
    % physical disturbances in the system
    if(mod(i,1000)==0 && ~slow)
        IavgF = zeros(vidHeight, vidWidth, 3, 'double');
        for j=i:i+nBkgSamples-1
            if(j<nFrames)
                frame = read(vidObj,j);
                IavgF = IavgF + double(frame);
            end
        end
        IavgF = uint8(IavgF./nBkgSamples);
    end
 
    curImg = read(vidObj,i);
    diffImg = abs(IavgF - curImg);
    % Applies Local Thresholding technique with 100x100 window and 90%
    % brightness (Refer to Fig. 3(c) in the paper)
    B = ~meanthresh(255-diffImg,[100 100], 0.1, 'symmetric');
    B=B&crMask;
    CC = bwconncomp(B,8);
    stats = regionprops(CC,'BoundingBox','Centroid','Area');
    
    % Discard any objects obviously too large or too small for worms 
    % (Refer to Fig. 3(d) in the paper)
    validIdx = find([stats.Area]>minWormArea & [stats.Area]<maxWormArea);
    B(:,:) = 0;
    wormPoints = zeros(size(validIdx,2),2);
    wormSizes = zeros(size(validIdx,2),1);
    for j=1:length(validIdx)
        B(CC.PixelIdxList{validIdx(j)}) = 1;
        wormPoints(j,:) = [stats(validIdx(j)).Centroid];
        wormSizes(j) = [stats(validIdx(j)).Area];
    end
 
    % Update existing tracks
    tracks2delete = [];
    for j=1:length(wormTracks)
        % Find the shortest distance of all tracks from new position to 
        % end of previous track
        xdelta = wormPoints(:,1) - wormTracks(j).track(end,1);
        ydelta = wormPoints(:,2) - wormTracks(j).track(end,2);
        delta = sqrt(xdelta.^2 + ydelta.^2);
        [shortestDist, sdIdx] = min(delta);
        if ((shortestDist <= biggestMove) && (wormSizes(sdIdx) < maxSingleWormArea))
            wormTracks(j).track(end+1,:) = wormPoints(sdIdx,:);
            wormPoints(sdIdx,:) = [];
            wormSizes(sdIdx) = [];
        else
            % Mark path for deletion
            tracks2delete = [tracks2delete,j];
        end
    end
 
    % Remove marked tracks and output to excel files
    for j = 1:length(tracks2delete)
        if(length(wormTracks(tracks2delete(j)).track)>15)
            rangeA = ['A',num2str(i-length(wormTracks(tracks2delete(j)).track))];
            xlswrite([path,filename,'_excel/',filename,'_worm',...
                num2str(xls_outputs)],...
                wormTracks(tracks2delete(j)).track,1,rangeA);
            xls_outputs = xls_outputs+1;
        end
    end
    wormTracks(tracks2delete) = [];
 
    % Add tracks for worm points not used for existing tracks
    for j=1:length(wormSizes)
        if(wormSizes(j) < maxSingleWormArea)
            wormTracks(end+1).track(1,:) = wormPoints(j,:);
        end
    end
    
    % Use mask on original image to extract worm
    mask(:,:,1) = uint8(B);
    mask(:,:,2) = uint8(B);
    mask(:,:,3) = uint8(B);
    finImg = mask.*curImg;
 
    % Display the tracks along with the worms
    imshow(finImg, 'Border', 'tight', 'InitialMagnification', 50);
    hold on;
 
    for j=1:length(wormTracks)
        line('XData',wormTracks(j).track(:,1),'YData',wormTracks(j).track(:,2),'Color','red');
    end
    for j=1:length(validIdx)
        if(stats(validIdx(j)).Area > maxSingleWormArea)
            bColor = 'yellow';
        else
            bColor = 'blue';
        end
        rectangle('Position',stats(validIdx(j)).BoundingBox,'EdgeColor',bColor);
    end
    hold off;
 
    F = getframe;
    writeVideo(writerObj,F);
    
    % Save video file
    v.frames(i) = struct('cdata',F.cdata);
    v.times(i) = double(i)/vidFPS;
    disp(i)
end

% Save centroid information to excel files
v.width=size(v.frames(1).cdata,2);
v.height=size(v.frames(1).cdata,1);
    for j = 1:length(wormTracks)
        if(length(wormTracks(j).track)>15)
            rangeA = ['A',num2str(i+1-length(wormTracks(j).track))];
            xlswrite([path,filename,'_excel/',...
                filename,'_worm',num2str(xls_outputs),'.xls'],...
                wormTracks(j).track,1,rangeA);
            xls_outputs = xls_outputs+1;
        end
    end
 
close(writerObj);
beep
disp('FINISHED!!');
close all