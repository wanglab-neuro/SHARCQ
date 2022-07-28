function ud = PadSlice(ud,folder_processed_images)

ud.processed_image_name = ud.processed_image_names{ud.slice_num};
ud.processed_ROI_name = ud.processed_ROI_names{ud.slice_num};
ud.current_slice_image = imread(fullfile(folder_processed_images, ud.processed_image_name));
ud.current_slice_ROI = readmatrix(fullfile(folder_processed_images, ud.processed_ROI_name));
[ud.original_slice_image,ud.original_ish_slice_image] = deal(ud.current_slice_image);
[ud.original_slice_ROI,ud.original_ish_slice_ROI] = deal(ud.current_slice_ROI);

% pad if possible (if small enough)
try
    imPadding=[floor((ud.reference_size(1) - size(ud.current_slice_image,1)) / 2) + mod(size(ud.current_slice_image,1),2) ...
        floor((ud.reference_size(2) - size(ud.current_slice_image,2)) / 2) + mod(size(ud.current_slice_image,2),2)];
    if any(imPadding)
    ud.current_slice_image = padarray(ud.current_slice_image, imPadding,0);
    ud.current_slice_ROI = padarray(ud.current_slice_ROI,...
        [floor((ud.reference_size(1) - size(ud.current_slice_ROI,1)) / 2) + mod(size(ud.current_slice_ROI,1),2) ...
        floor((ud.reference_size(2) - size(ud.current_slice_ROI,2)) / 2) + mod(size(ud.current_slice_ROI,2),2)],0);
    else 
        return
    end

[ud.original_slice_image,ud.original_ish_slice_image] = deal(ud.current_slice_image);
[ud.original_slice_ROI,ud.original_ish_slice_ROI] = deal(ud.current_slice_ROI);
imwrite(ud.current_slice_image, fullfile(folder_processed_images, ud.processed_image_name));
writematrix(ud.current_slice_ROI, fullfile(folder_processed_images, ud.processed_ROI_name));

catch
    disp('Error while padding image');
end
