function plot_locking(faults)

% ind = ss_i, ds_i
namelist = fieldnames(faults);
for i =1:numel(namelist)
    fieldName = namelist{i};
    switch faults.(fieldName).meshtype
        case 'tri'
            p = faults.(fieldName).trinode;
            trisurf(faults.(fieldName).tri,p(:,1),p(:,2),p(:,3),double(faults.(fieldName).nodes.locking_patches),'EdgeColor',[0.8 0.8 0.8])
        otherwise
            continue
    end


end