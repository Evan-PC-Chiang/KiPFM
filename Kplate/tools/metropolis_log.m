
function accept=metropolis_log(d1,d2)

rat=exp(d2-d1);
if rat>1
   accept=1;
else
   r=rand;
   if r<rat
      accept=1;
   else
      accept=0;
   end
end
