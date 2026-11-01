function dz=rhs(t,z,p)
n=numel(z)/2; q=z(1:n); v=z(n+1:end);
[M,f]=aleancf.assemble(t,q,v,p);
dz=[v;M\f];
end
