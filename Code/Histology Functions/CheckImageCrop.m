function ud=CheckImageCrop(ud)

ud.size = size(ud.current_slice_image);
if ud.size(1) > ud.reference_size(1)+1 || ud.size(2) > ud.reference_size(2)+2
    disp(['Slice ' num2str(ud.slice_num) ' / ' num2str(ud.total_num_files) ' is ' num2str(ud.size(1)) 'x' num2str(ud.size(2)) ' pixels:']);
    disp(['I suggest you crop this image down to under ' num2str(ud.reference_size(1)) ' x ' num2str(ud.reference_size(2)) ' pxl'])
end

