parm = struct();

namelist = fieldnames(faults);
for i = 1:numel(namelist)
    fieldName = namelist{i};  % Extract field name from the namelist
    switch faults.(fieldName).meshtype
        case 'tri'
            parm.(fieldName).ss_i = faults.(fieldName).nodes.ss_i;
            parm.(fieldName).ds_i = faults.(fieldName).nodes.ds_i;
            parm.(fieldName).tri_py = faults.(fieldName).tri - 1;
            parm.(fieldName).trinodes_py = [local2llh(faults.(fieldName).trinode(:,1:2)',origin)' faults.(fieldName).trinode(:,3)];
            parm.(fieldName).depth = faults.(fieldName).patch_stuff.centroids_faces(:,3);
            parm.(fieldName).locking = faults.(fieldName).nodes.locking_patches;
            parm.(fieldName).Mw = data_table(i,'eq_Mw');
            parm.(fieldName).ss = data_table(i,'ss');
            parm.(fieldName).ds = data_table(i,'ds');
            parm.(fieldName).ss_std = data_table(i,'ss_std');
            parm.(fieldName).ds_std = data_table(i,'ds_std');
        otherwise
            continue
    end
end

saveStructureToJSON(parm, 'fault_prop.json')