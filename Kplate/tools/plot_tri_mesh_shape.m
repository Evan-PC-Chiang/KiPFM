function plot_tri_mesh_shape(faults)

% ind = ss_i, ds_i
namelist = fieldnames(faults);
for i =1:numel(namelist)
    fieldName = namelist{i};
    switch faults.(fieldName).meshtype
        case 'tri'
            p = faults.(fieldName).trinode;
            trisurf(faults.(fieldName).tri,p(:,1),p(:,2),p(:,3),faults.(fieldName).patch_stuff.centroids_faces(:,3),'EdgeColor','none','HandleVisibility','off')
        otherwise
            plotpatchslip3D(faults.(fieldName).pm,0,1)
    end


end