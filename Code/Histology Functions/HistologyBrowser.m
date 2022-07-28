function HistologyBrowser(histology_figure, ud, use_already_downsampled_image)

% display image and set up user controls for contrast change

ud=AdjustHistologyImage(ud,use_already_downsampled_image);

figure(histology_figure)
imshow(ud.original_image);
figDims=get(histology_figure, 'position');
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
function HistologyHotkeyFcn(histology_figure, keydata, use_already_downsampled_image)

ud = get(histology_figure, 'UserData');

if strcmpi(keydata.Key, 'space') % adjust contrast
    ud.adjusting_contrast = ~ud.adjusting_contrast;

    if ud.adjusting_contrast
        disp(['adjust contrast on channel ' num2str(ud.channel)])
        imshow(ud.adjusted_image(:,:,ud.channel))
        imcontrast(histology_figure)
    else
        adjusted_image_channel = histology_figure.Children.Children.CData;
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
figure(histology_figure)
if ~(ud.adjusting_contrast || (strcmpi(keydata.Key,'e')&&ud.show_original) )
    imshow(ud.adjusted_image)
end
colorLabels={'Red','Green','Blue'};
title({['Image ' num2str(ud.file_num) ' / ' num2str(ud.num_files)];...
    ['Adjusting channel ' num2str(ud.channel) ' (' colorLabels{ud.channel} ')']},...
    'color','w')

set(histology_figure, 'UserData', ud);
