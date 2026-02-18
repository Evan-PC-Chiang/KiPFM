namelist = fieldnames(parm);
% loop over the fault names to get information
for i = numel(namelist)
    % get the fault information
    tmp_fault = parm.(namelist{i});
    % loop over the triangles to write the GMT file
    % make file name by namelist
    filename = strcat('./result/', namelist{i},'_locking_tri.txt');
    fileID = fopen(filename,'w'); fclose(fileID);
    fileID = fopen(filename,'a');
    for j = 1:height(tmp_fault.tri_py)
        % get the connectivity
        tmp_tri = tmp_fault.tri_py(j,:) + 1;
        % find the coordinates of the triangle
        p1 = round(tmp_fault.trinodes_py(tmp_tri(1),:),4);
        p2 = round(tmp_fault.trinodes_py(tmp_tri(2),:),4);
        p3 = round(tmp_fault.trinodes_py(tmp_tri(3),:),4);
        % write the GMT file line by line by using fprintf
        % first line should bo: > Polygon tmp_tri(1)-tmp_tri(2)-tmp_tri(2)
        % -Zlocking
        fprintf(fileID, '> Polygon %d-%d-%d -Z%.4f\n', tmp_tri(1), tmp_tri(2), tmp_tri(3), tmp_fault.locking(j)*100);
        % second line should be: lon1 lat1
        fprintf(fileID, '%.4f %.4f\n', p1(1), p1(2));
        % third line should be: lon2 lat2
        fprintf(fileID, '%.4f %.4f\n', p2(1), p2(2));
        % fourth line should be: lon3 lat3
        fprintf(fileID, '%.4f %.4f\n', p3(1), p3(2));
        % fifth line should be: lon1 lat1
        fprintf(fileID, '%.4f %.4f\n', p1(1), p1(2));
    end
    % close the file
    fclose(fileID);
end