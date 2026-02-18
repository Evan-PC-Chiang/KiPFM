function data_table = slip_rates_Mw(file_name_ss, file_name_ds, faults, origin, data_table)
    % Initialize output files
    fid = fopen(file_name_ss, 'w'); fclose(fid);
    fidss = fopen(file_name_ss, 'a');

    fid = fopen(file_name_ds, 'w'); fclose(fid);
    fidds = fopen(file_name_ds, 'a');

    % Get all field names from the faults structure
    namelist = fieldnames(faults);

    for i = 1:numel(namelist)-4  % Loop through each fault (excluding the last 5 fields)
        fieldName = namelist{i};
        obj = faults.(fieldName);

        % Get the location of the topmost trinode(s)
        pos = [obj.trinode(obj.trinode(:,3)==max(obj.trinode(:,3)),1), ...
               obj.trinode(obj.trinode(:,3)==max(obj.trinode(:,3)),2)];

        % Find the nearest patch index to the position
        [~, idx] = min(pdist2(pos, obj.patch_stuff.centroids_faces(:,1:2)), [], 2);

        % Get slip rates
        ss_i = obj.nodes.ss_i(idx);
        ds_i = obj.nodes.ds_i(idx);

        % Convert local coordinates to lat/lon and append slip rate
        xy_ss = [local2llh(pos', origin)' ss_i];
        xy_ds = [local2llh(pos', origin)' ds_i];

        % Interpolate slip along the profile
        Xi = 20*(1:size(xy_ss,1));
        Xo = 20:Xi(end);
        B_ss = interp1(Xi, xy_ss, Xo);

        Xi = 20*(1:size(xy_ds,1));
        Xo = 20:Xi(end);
        B_ds = interp1(Xi, xy_ds, Xo);

        % Write to strike-slip output file
        fprintf(fidss, ['> ', fieldName, '\r\n']);
        for q = 1:size(B_ss, 1)
            fprintf(fidss, '%.4f %.4f %.4f\r\n', B_ss(q, :));
        end  

        % Write to dip-slip output file
        fprintf(fidds, ['> ', fieldName, '\r\n']);
        for q = 1:size(B_ds, 1)
            fprintf(fidds, '%.4f %.4f %.4f\r\n', B_ds(q, :));
        end  

        % Mw
        area = obj.patch_stuff.area_faces .* 10^6; % km^2 to m^2
        D = sqrt(obj.nodes.ds_i.^2 + obj.nodes.ss_i.^2) .* 10^-3; % mm/yr to m/yr
        mu = 3*10^10; % Pa
    
        M0 = sum(area .*D .* mu) * 100;
    
        Mw = (2/3) * log10(M0) - 6;
        data_table.eq_Mw(i) = Mw;
    end

    % Close output files
    fclose(fidss);
    fclose(fidds);
end