function plot_fault_traces_all(faults)
    namelist = fieldnames(faults);
    for i = 1:numel(namelist)
        switch namelist{i}
            case 'detachment'
                continue
            otherwise
                faults.(namelist{i}).plot_trace
        end
    end
end