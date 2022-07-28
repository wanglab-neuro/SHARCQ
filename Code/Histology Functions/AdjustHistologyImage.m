% Load and Adjust Histology Section
function userParams=AdjustHistologyImage(userParams,use_ds_image)

% load histology image
disp(['Loading image ' num2str(userParams.file_num) '...'])
original_image = imread(fullfile(userParams.image_folder,userParams.image_file_names{userParams.file_num}));
ROI_location = fullfile(userParams.coords_folder,userParams.coords_file_names{userParams.file_num});
ROI_values = readmatrix(ROI_location);
ROI_table = readtable(ROI_location);

if ~use_ds_image
    % resize (downsample) image and ROI to reference atlas size
    disp('Downsampling image')
    original_image_size = size(original_image);
    original_image = imresize(original_image, [round(original_image_size(1)*userParams.microns_per_pixel/userParams.microns_per_pixel_after_downsampling)  NaN]);
    
    disp('Adding ROI layer')
    sz = size(squeeze(original_image(:,:,1)));
    ROI = zeros(sz);
    if size(ROI_values,2) == 2
        X = 1;
        Y = 2;
    else
        X = find(strcmpi(ROI_table.Properties.VariableNames,'X'));
        Y = find(strcmpi(ROI_table.Properties.VariableNames,'Y'));
        ROI_values = ROI_values(2:end,:);
    end

    % ROI_values contains the data from the ROI coordinate file.
    % If this file was obtained through 'multi-point' tool on FIJI and
    % analyze->measure, then the X,Y data will be in the 6th and 7th col
    x = round(ROI_values(:,X)*(sz(1,1)/original_image_size(1,1)));
    y = round(ROI_values(:,Y)*(sz(1,2)/original_image_size(1,2)));

    % Create binary ROI matrix 'image' and populate pixels with values if
    % they represent labeled cell locations. If downsampled size causes two
    % cell locations to overlap, move one pixel away until empty space
    for i = 1:length(ROI_values(:,1))
        if ROI(y(i),x(i)) == 0
            ROI(y(i),x(i)) = 10;
        else
            if ROI(y(i)+1,x(i)) == 0
                ROI(y(i)+1,x(i)) = 10;
            else
                ROI(y(i)-1,x(i)) = 10;
            end
        end
    end
else
    % images are already downsampled to the atlas resolution 10um/px
    disp('Adding ROI layer...');
    sz = size(squeeze(original_image(:,:,1)));
    ROI = zeros(sz);
    x = round(ROI_values(:,6));
    y = round(ROI_values(:,7));
    for i = 1:length(ROI_values(:,1))
        if ROI(y(i),x(i)) == 0
            ROI(y(i),x(i)) = 10;
        else
            if ROI(y(i)+1,x(i)) == 0
                ROI(y(i)+1,x(i)) = 10;
            else
                ROI(y(i)-1,x(i)) = 10;
            end
        end
    end
end
userParams.file_name_suffix = '_processed';
userParams.channel = min( 3, size(original_image,3));
userParams.original_image = original_image;
userParams.adjusted_image = original_image(:,:,1:userParams.channel)*userParams.gain;

% save pre-processed image and ROI
imwrite(userParams.adjusted_image, fullfile(userParams.save_folder, ...
    [userParams.image_file_names{userParams.file_num}(1:end-4) userParams.file_name_suffix '.tif']))
writematrix(ROI,fullfile(userParams.save_folder, ...
    [userParams.image_file_names{userParams.file_num}(1:end-4) userParams.file_name_suffix '.csv']));
