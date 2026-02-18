function [sig_e,sig_n,sig_u,sig_lt] = set_weighting(data, horizontal, ver, ver_lt, base)
    sig_e = data.Sigeast_inter(data.notnanind_east);
    sig_n = data.Signorth_inter(data.notnanind_north);
    sig_u = data.Sigup_inter(data.notnanind_up);
    sig_lt = data.Sigup_lt;
    
    sig_e(sig_e<base)=base;
    sig_n(sig_n<base)=base;
    sig_u(sig_u<base)=base;
    sig_lt(sig_lt<base)=base;
    
    sig_e = sig_e*5*horizontal;
    sig_n = sig_n*5*horizontal;
    sig_u = sig_u*5*ver;
    sig_lt = sig_lt*5*ver_lt;
end

