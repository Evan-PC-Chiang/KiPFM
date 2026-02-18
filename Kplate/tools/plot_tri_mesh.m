function plot_tri_mesh(faults,ind)

% ind = ss_i, ds_i
namelist = fieldnames(faults);
for i =1:numel(namelist)
    fieldName = namelist{i};
    switch faults.(fieldName).meshtype
        case 'tri'
            p = faults.(fieldName).trinode;
            trisurf(faults.(fieldName).tri,p(:,1),p(:,2),p(:,3),faults.(fieldName).nodes.(ind),'EdgeColor','none')
        otherwise
            plotpatchslip3D(faults.(fieldName).pm,faults.(fieldName).nodes.(ind),1)
    end


end