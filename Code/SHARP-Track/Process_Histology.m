% ------------------------------------------------------------------------
%              UPDATED SHARP-Track: PRE-PROCESS IMAGES and ROI
%   
%   This first takes .csv file(s) of x,y coordinates denoting the region-
%   of-interest (ROI) of labeled cell locations and creates an ROI binary
%   matrix the size of the corresponding image.
%
%   The ROI and the image are downsampled and borders are filled in for
%   consistent size and resolution matching Allen Atlas (800x1140 px) and
%   10um/pixel. 
%
%   1 or 3 channel .tif(s) have been tested in this program and the
%   contrast of each channel can be augmented independently
% ------------------------------------------------------------------------

function Process_Histology(image_folder, coords_folder, ~, microns_per_pixel, plane, downsampled_already)
%%  SET PARAMETERS

% name of images, in order anterior to posterior or vice versa
% once these are downsampled they will be named ['original name' '_processed.tif']
image_file_names = dir([image_folder filesep '*.tif']); % get the contents of the image_folder
image_file_names = natsortfiles({image_file_names.name});

% name of coordinate files matching images
coords_file_names = dir([coords_folder filesep '*.csv']);
coords_file_names = natsortfiles({coords_file_names.name});

% microns_per_pixel_after_downsampling should typically be set to 10 to match the atlas
microns_per_pixel_after_downsampling = 10;

% change if the user wants to save the images to a different folder
save_folder = image_folder;

% ----------------------
% additional parameters
% ----------------------

% if the images are cropped (image_file_are_individual_slices = false),
% name to save cropped slices as; e.g. the third cropped slice from the 2nd
% image containing many slices will be saved as: save_folder/processed/save_file_name02_003.tif

% increase gain if for some reason the images are not bright enough
gain = 1; 

% images are already downsampled to resolution of atlas
use_ds_image = downsampled_already;

% size in pixels of reference atlas brain. For coronal slice, this is 800 x 1140
if strcmp(plane,'coronal')
    atlas_reference_size = [800 1140]; 
elseif strcmp(plane,'sagittal')
    atlas_reference_size = [800 1320]; 
elseif strcmp(plane,'transverse')
    atlas_reference_size = [1140 1320];
end

% finds or creates a folder location for processed images -- 
% a folder within save_folder called processed
folder_processed_images = fullfile(save_folder, 'processed');
if ~exist(folder_processed_images,'dir')
    mkdir(folder_processed_images)
end


%% LOAD AND PROCESS SLICE PLATE IMAGES

% close all figures
close all
   
% if the images need to be downsampled to 10um pixels (use_already_downsampled_image = false), 
% this will downsample and allow you to adjust contrast of each channel of each image from image_file_names
%
% if the images are already downsampled (use_already_downsampled_image = true), this will allow
% you to adjust the contrast of each channel

% Open Histology Viewer figure
if ~exist('histology_figure','var')
    histology_figure = figure('Name','Histology Viewer',  'NumberTitle', 'off', 'color', 'k'); 
end
warning('off', 'images:initSize:adjustingMag'); warning('off', 'MATLAB:colon:nonIntegerIndex');

userParams = struct(...
'show_original',0,...
'adjusting_contrast',0,...
'file_num',1,...
'num_files',length(image_file_names),...
'save_folder',folder_processed_images,...
'coords_folder',coords_folder,...
'image_folder',image_folder,...
'image_file_names',{image_file_names},...
'coords_file_names',{coords_file_names},...
'microns_per_pixel',microns_per_pixel,...
'microns_per_pixel_after_downsampling',microns_per_pixel_after_downsampling,...
'gain',gain);

% Function to downsample and adjust histology image
HistologyBrowser(histology_figure, userParams, use_ds_image);

uiwait(histology_figure);
while size(findobj(histology_figure))>0
   pause;
end

%check that all processed files have been created 
procFileList=dir(folder_processed_images);
file2ProcIdx=find(~cellfun(@(fName) any(contains({procFileList.name},fName(1:end-4))) ,image_file_names));
for fileNum=1:length(file2ProcIdx)
    userParams.file_num=file2ProcIdx(fileNum);
    AdjustHistologyImage(userParams,use_ds_image); 
end

%% GO THROUGH TO FLIP HORIZONTAL SLICE ORIENTATION, ROTATE, SHARPEN, and CHANGE ORDER

% close all figures
close all
            
% this takes images from folder_processed_images ([save_folder/processed]),
% and allows you to rotate, flip, sharpen, crop, and switch their order, so they
% are in anterior->posterior or posterior->anterior order, and aesthetically pleasing
% 
% it also pads images smaller than the reference_size and requests that you
% crop images larger than this size
%
% note -- presssing left or right arrow saves the modified image, so be
% sure to do this even after modifying the last slice in the folder

slice_figure = figure('Name','Slice Viewer');
SliceFlipper(slice_figure, folder_processed_images, atlas_reference_size)

end