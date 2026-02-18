function [Gmatrix, Gmatrix_load] = make_G_matrix(faults, faults_loading, data)
% how to call? use Gmatrix(1).Gbs_e_ds; for the fist fault, back-slip in e dir

    % regular faults
    name_list = fieldnames(faults);
    
    lt_e_ss = cell(numel(name_list),1);
    lt_n_ss = cell(numel(name_list),1);
    lt_u_ss = cell(numel(name_list),1);
    
    lt_e_ds = cell(numel(name_list),1);
    lt_n_ds = cell(numel(name_list),1);
    lt_u_ds = cell(numel(name_list),1);
    
    bs_e_ss = cell(numel(name_list),1);
    bs_n_ss = cell(numel(name_list),1);
    bs_u_ss = cell(numel(name_list),1);
    
    bs_e_ds = cell(numel(name_list),1);
    bs_n_ds = cell(numel(name_list),1);
    bs_u_ds = cell(numel(name_list),1);
    
    for i = 1:numel(name_list)
        fieldName = name_list{i};
    
        % long-term = elastic + viscoelastic
        lt_e_ss{i} = faults.(fieldName).Greens.ss.elastic.e() + faults.(fieldName).Greens.ss.viscoelastic.e();
        lt_n_ss{i} = faults.(fieldName).Greens.ss.elastic.n() + faults.(fieldName).Greens.ss.viscoelastic.n();
        lt_u_ss{i} = faults.(fieldName).Greens.ss.elastic.u() + faults.(fieldName).Greens.ss.viscoelastic.u();
        
        lt_e_ds{i} = faults.(fieldName).Greens.ds.elastic.e() + faults.(fieldName).Greens.ds.viscoelastic.e();
        lt_n_ds{i} = faults.(fieldName).Greens.ds.elastic.n() + faults.(fieldName).Greens.ds.viscoelastic.n();
        lt_u_ds{i} = faults.(fieldName).Greens.ds.elastic.u() + faults.(fieldName).Greens.ds.viscoelastic.u();
        
        % back-slip = -elastic
        bs_e_ss{i} = -1*faults.(fieldName).Greens.ss.elastic.e();
        bs_n_ss{i} = -1*faults.(fieldName).Greens.ss.elastic.n();
        bs_u_ss{i} = -1*faults.(fieldName).Greens.ss.elastic.u();
        
        bs_e_ds{i} = -1*faults.(fieldName).Greens.ds.elastic.e();
        bs_n_ds{i} = -1*faults.(fieldName).Greens.ds.elastic.n();
        bs_u_ds{i} = -1*faults.(fieldName).Greens.ds.elastic.u();
        
    end
    
    
    Glt_e_ss = cell(numel(name_list),1);
    Glt_n_ss = cell(numel(name_list),1);
    Glt_u_ss = cell(numel(name_list),1);
    Glt_lt_u_ss = cell(numel(name_list),1);
    
    Glt_e_ds = cell(numel(name_list),1);
    Glt_n_ds = cell(numel(name_list),1);
    Glt_u_ds = cell(numel(name_list),1);
    Glt_lt_u_ds = cell(numel(name_list),1);
    
    Gbs_e_ss = cell(numel(name_list),1);
    Gbs_n_ss = cell(numel(name_list),1);
    Gbs_u_ss = cell(numel(name_list),1);
    
    Gbs_e_ds = cell(numel(name_list),1);
    Gbs_n_ds = cell(numel(name_list),1);
    Gbs_u_ds = cell(numel(name_list),1);
    
    % setup the actually G for mcmc
    for j = 1:numel(name_list)
        % vertical, long-term data
        Glt_lt_u_ss{j} = lt_u_ss{j}(data.data_type==2,:);
        Glt_lt_u_ds{j} = lt_u_ds{j}(data.data_type==2,:);
    
        % horizontal and vertical, long-term (for calculate short-term)
        Glt_e_ss{j} = lt_e_ss{j}(data.notnanind_east,:);
        Glt_e_ds{j} = lt_e_ds{j}(data.notnanind_east,:);
        Glt_n_ss{j} = lt_n_ss{j}(data.notnanind_north,:);
        Glt_n_ds{j} = lt_n_ds{j}(data.notnanind_north,:);
        Glt_u_ss{j} = lt_u_ss{j}(data.notnanind_up,:);
        Glt_u_ds{j} = lt_u_ds{j}(data.notnanind_up,:);
    
        % horizontal and vertical, bacl-slip (for calculate short-term)
        Gbs_e_ss{j} = bs_e_ss{j}(data.notnanind_east,:);
        Gbs_e_ds{j} = bs_e_ds{j}(data.notnanind_east,:);
        Gbs_n_ss{j} = bs_n_ss{j}(data.notnanind_north,:);
        Gbs_n_ds{j} = bs_n_ds{j}(data.notnanind_north,:);
        Gbs_u_ss{j} = bs_u_ss{j}(data.notnanind_up,:);
        Gbs_u_ds{j} = bs_u_ds{j}(data.notnanind_up,:);
    
    end
    
    % loading faults (no back-slip)
    name_list = fieldnames(faults_loading);
    
    Gloading_e_ss = cell(numel(name_list),1);
    Gloading_n_ss = cell(numel(name_list),1);
    Gloading_u_ss = cell(numel(name_list),1);
    Gloading_e_ds = cell(numel(name_list),1);
    Gloading_n_ds = cell(numel(name_list),1);
    Gloading_u_ds = cell(numel(name_list),1);
    
    for k = 1:numel(name_list)
        fieldName = name_list{k};
        % long-term = elastic + viscoelastic
        Gloading_e_ss{k} = faults_loading.(fieldName).Greens.ss.elastic.e() + faults_loading.(fieldName).Greens.ss.viscoelastic.e();
        Gloading_n_ss{k} = faults_loading.(fieldName).Greens.ss.elastic.n() + faults_loading.(fieldName).Greens.ss.viscoelastic.n();
        Gloading_u_ss{k} = faults_loading.(fieldName).Greens.ss.elastic.u() + faults_loading.(fieldName).Greens.ss.viscoelastic.u();
        
        Gloading_e_ds{k} = faults_loading.(fieldName).Greens.ds.elastic.e() + faults_loading.(fieldName).Greens.ds.viscoelastic.e();
        Gloading_n_ds{k} = faults_loading.(fieldName).Greens.ds.elastic.n() + faults_loading.(fieldName).Greens.ds.viscoelastic.n();
        Gloading_u_ds{k} = faults_loading.(fieldName).Greens.ds.elastic.u() + faults_loading.(fieldName).Greens.ds.viscoelastic.u();
        
    end

    Gmatrix = struct( ...
        'Glt_lt_u_ss',Glt_lt_u_ss, ...
        'Glt_lt_u_ds',Glt_lt_u_ds, ...
        'Glt_e_ss',Glt_e_ss, ...
        'Glt_e_ds',Glt_e_ds, ...
        'Glt_n_ss',Glt_n_ss, ...
        'Glt_n_ds',Glt_n_ds, ...
        'Glt_u_ss',Glt_u_ss, ...
        'Glt_u_ds',Glt_u_ds, ...
        'Gbs_e_ss',Gbs_e_ss, ...
        'Gbs_e_ds',Gbs_e_ds, ...
        'Gbs_n_ss',Gbs_n_ss, ...
        'Gbs_n_ds',Gbs_n_ds, ...
        'Gbs_u_ss',Gbs_u_ss, ...
        'Gbs_u_ds',Gbs_u_ds ...
        );
    Gmatrix_load = struct( ...
        'Gloading_e_ss',Gloading_e_ss, ...
        'Gloading_e_ds',Gloading_e_ds, ...
        'Gloading_n_ss',Gloading_n_ss, ...
        'Gloading_n_ds',Gloading_n_ds, ...
        'Gloading_u_ss',Gloading_u_ss, ...
        'Gloading_u_ds',Gloading_u_ds ...
        );
end