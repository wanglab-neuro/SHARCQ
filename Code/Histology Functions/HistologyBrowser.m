function HistologyBrowser(histology_figure, ~, image_folder, coords_folder, image_file_names, coords_file_names, folder_processed_images, ...
    use_already_downsampled_image, microns_per_pixel, microns_per_pixel_after_downsampling, gain)

% display image and set up user controls for contrast change
ud = struct(...
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

ud=AdjustHistologyImage(ud,use_already_downsampled_image);

imshow(ud.original_image);
figDims=get(gcf, 'position');
set(gcf,'position',[figDims(1), figDims(2)-200,...
    min([700 size(ud.original_image,1)*4]), min([500 size(ud.original_image,2)+200])])
colorLabels={'Red','Green','Blue'};
title({['Image ' num2str(ud.file_num) ' / ' num2str(ud.num_files)];...
    ['Adjusting channel ' num2str(ud.channel) ' (' colorLabels{ud.channel} ')']},...
    'color','w')

set(histology_figure, 'UserData', ud);

set(histology_figure, 'KeyPressFcn', @(histology_figure,keydata) ...
    HistologyHotkeyFcn(histology_figure, keydata, use_already_downsampled_image));

fprintf(1, '\n Controls: adjust contrast for any RGB channel on any image \n \n');
fprintf(1, 'space: adjust contrast for current channel / return to image-viewing mode \n');
fprintf(1, 'e: view original version \n');
fprintf(1, 'any key: return to modified version \n');
fprintf(1, 'r: reset to original \n');
fprintf(1, 'c: move to next channel \n');
fprintf(1, 's: save image \n');
fprintf(1, 'left/right arrow: save and move to next slide image \n \n');


% --------------------
%% Respond to keypress
% --------------------
function HistologyHotkeyFcn(fig, keydata, use_already_downsampled_image)

ud = get(fig, 'UserData');

if strcmpi(keydata.Key, 'space') % adjust contrast
    ud.adjusting_contrast = ~ud.adjusting_contrast;

    if ud.adjusting_contrast
        disp(['adjust contrast on channel ' num2str(ud.channel)])
        imshow(ud.adjusted_image(:,:,ud.channel))
        imcontrast(fig)
    else
        adjusted_image_channel = fig.Children.Children.CData;
        ud.adjusted_image(:,:,ud.channel) = adjusted_image_channel;
    end

    % ignore commands while adjusting contrast
elseif ~ud.adjusting_contrast
    switch lower(keydata.Key)
        case 'e' % show original
            ud.show_original = ~ud.show_original;
            if ud.show_original
                disp('showing original image (press any key to return)')
                imshow(ud.original_image)
            end
        case 'r' % return to original
            disp('revert to original image')
            ud.adjusted_image = ud.original_image;
        case 'c' % break
            disp('next channel')
            ud.channel = ud.channel + 1 - (ud.channel==3)*3;

        case 's' % save image
            disp(['saving processed image ' num2str(ud.file_num)]);
            imwrite(ud.adjusted_image, fullfile(ud.save_folder, [ud.image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.tif']))
            imshow(ud.adjusted_image)
        case 'leftarrow' % save image and move to previous image
            disp(['saving processed image ' num2str(ud.file_num)]);
            imwrite(ud.adjusted_image, fullfile(ud.save_folder, [ud.image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.tif']))

            if ud.file_num > 1
                ud.file_num = ud.file_num - 1;
                move_on = true;
            else
                move_on = false;
            end
        case 'rightarrow' % save image and move to next image
            disp(['saving processed image ' num2str(ud.file_num)]);
            imwrite(ud.adjusted_image, fullfile(ud.save_folder, [ud.image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.tif']))

            if ud.file_num < ud.num_files
                ud.file_num = ud.file_num + 1;
                move_on = true;
            else
                fprintf('\n');
                disp('That''s all for now - please close the figure to continue')
                move_on = false;
            end
    end
    if (strcmpi(keydata.Key,'leftarrow') || strcmpi(keydata.Key,'rightarrow')) && move_on
        ud=AdjustHistologyImage(ud,use_already_downsampled_image); 
    end
else % if pressing commands while adjusting contrast
    disp(' ')
    disp('Please press space to exit contrast adjustment before issuing other commands')
    disp('If you are dissatisfied with your changes, you can then press ''r'' to revert to the original image')
end

% show the image, unless in other viewing modes
figure(fig)
if ~(ud.adjusting_contrast || (strcmpi(keydata.Key,'e')&&ud.show_original) )
    imshow(ud.adjusted_image)
end
title(['Adjusting channel ' num2str(ud.channel) ' on image ' num2str(ud.file_num) ' / ' num2str(ud.num_files)],...
    'color',[1==ud.channel 2==ud.channel 3==ud.channel])

set(fig, 'UserData', ud);

% ----------------------------------
%% Load and Adjust Histology Section
% ----------------------------------
function userData=AdjustHistologyImage(userData,use_ds_image)

% load histology image
disp(['loading image ' num2str(userData.file_num) '...'])
loadimage = imread(fullfile(userData.image_folder,userData.image_file_names{userData.file_num}));
ROI_location = fullfile(userData.coords_folder,userData.coords_file_names{userData.file_num});
ROI_values = readmatrix(ROI_location);
ROI_table = readtable(ROI_location);

if ~use_ds_image
    % resize (downsample) image and ROI to reference atlas size
    disp('adding ROI layer...')
    disp('downsampling image...')
    original_image_size = size(loadimage);
    loadimage = imresize(loadimage, [round(original_image_size(1)*userData.microns_per_pixel/userData.microns_per_pixel_after_downsampling)  NaN]);
    sz = size(squeeze(loadimage(:,:,1)));
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
    disp('adding ROI layer...');
    sz = size(squeeze(loadimage(:,:,1)));
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
userData.file_name_suffix = '_processed';
userData.channel = min( 3, size(loadimage,3));
original_image = loadimage(:,:,1:userData.channel)*userData.gain;

[userData.original_image,userData.adjusted_image] = deal(original_image);

% save pre-processed image and ROI
imwrite(userData.adjusted_image, fullfile(userData.save_folder, ...
    [userData.image_file_names{userData.file_num}(1:end-4) userData.file_name_suffix '.tif']))
writematrix(ROI,fullfile(userData.save_folder, ...
    [userData.image_file_names{userData.file_num}(1:end-4) userData.file_name_suffix '.csv']));
