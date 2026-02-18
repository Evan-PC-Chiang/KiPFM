function [xy_stats, data, xy_coast, data_matrix] =load_data(data_file,coast_file,origin)

    data_matrix = load(data_file);
    coastline = load(coast_file);
    data_type = data_matrix(:,1);

    c = data_matrix(data_type == 1,2:3);
    [~, ~, idx] = unique(c, 'rows');
    rowcount = accumarray(idx, 1);
    delete = rowcount(idx)>1;
    data_matrix(delete,:) = [];

    xy_coast = llh2local(coastline',origin)';
    xy_stats = llh2local(data_matrix(:,2:3)',origin)';
    xy_stats_wgs = data_matrix(:,2:3);


    poly =   [  -63.0547   60.4786;
      -54.7150   29.8998;
      -46.8386    9.5138;
      -42.6687   -7.1656;
      -41.2788  -24.3083;
      -45.9119  -39.1344;
      -61.6647  -46.5475;
      -76.0275  -58.1304;
      -95.4868  -70.1766;
     -128.8456  -86.8560];
    
    data_type = data_matrix(:,1);
    
    [in, ~] = inpolygon( xy_stats(:,1), xy_stats(:,2), poly(:,1), poly(:,2));
    
    data_matrix(in & data_type==1,9) = 9999*ones(size(in & data_type==1,9));
    
    poly2 = [  -40.8974 -199.8718;
      -40.3846 -164.4872;
      -40.8974 -140.3846;
      -40.8974 -131.6667;
      -51.1538 -123.9744;
      -57.8205 -139.8718;
      -65.0000 -167.0513;
      -71.6667 -199.3590];
    
    [inin, ~] = inpolygon( xy_stats(:,1), xy_stats(:,2), poly2(:,1), poly2(:,2));
    
    data_matrix(inin & data_type==1,9) = 9999*ones(size(inin & data_type==1,9));

    
    correct = isnan(data_matrix(:,5));
    data_matrix(correct,7:8) = data_matrix(correct,4:5);
    
    
    ind = data_type==1;
    
    xy_inter = xy_stats(ind,:);
    xy_inter_wgs = xy_stats_wgs(ind,:);
    
    Veast_inter = data_matrix(ind,4);
    Vnorth_inter = data_matrix(ind,5);
    Vup_inter = data_matrix(ind,6);
    indddd = find(Vup_inter<-15 | Vup_inter>15);
    
    
    Sigeast_inter = data_matrix(ind,7);
    Signorth_inter = data_matrix(ind,8);
    Sigup_inter = data_matrix(ind,9);
    inddd = find(Sigup_inter>8);
    Sigup_inter(inddd) = 9999*ones(size(Sigup_inter(inddd)));
    Sigup_inter(indddd) = 9999*ones(size(Sigup_inter(indddd)));
    
    ind = data_type==2;
    
    xy_lt = xy_stats(ind,:);
    xy_lt_wgs = xy_stats_wgs(ind,:);
    Vup_lt = data_matrix(ind,6);
    Sigup_lt = data_matrix(ind,9);

    notnanind_east = ~isnan(Veast_inter);
    notnanind_north = ~isnan(Vnorth_inter);
    notnanind_up = ~isnan(Vup_inter);

    data = struct( ...
        'xy_inter', xy_inter,...
        'Veast_inter', Veast_inter, ...
        'Vnorth_inter',Vnorth_inter, ...
        'Vup_inter',Vup_inter, ...
        'Sigeast_inter', Sigeast_inter, ...
        'Signorth_inter', Signorth_inter, ...
        'Sigup_inter', Sigup_inter, ...
        'xy_lt', xy_lt, ...
        'Vup_lt',Vup_lt, ...
        'Sigup_lt',Sigup_lt, ...
        'xy_inter_wgs',xy_inter_wgs, ...
        'xy_lt_wgs',xy_lt_wgs, ...
        'notnanind_east',notnanind_east, ...
        'notnanind_north',notnanind_north, ...
        'notnanind_up',notnanind_up, ...
        'data_type',data_type);

end