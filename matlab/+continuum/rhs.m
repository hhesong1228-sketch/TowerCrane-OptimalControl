function [dz,lambda,res]=rhs(t,z,p,c)
q=z(1:c.n); v=z(c.n+1:end);
[M,f,G,phi,phid,gamma]=continuum.assemble(t,q,v,p,c);
b=gamma-2*p.alpha*phid-p.beta^2*phi;
sol=[M G.';G zeros(5)]\[f;b];
dz=[v;sol(1:c.n)]; lambda=sol(c.n+1:end);
res=norm(M*sol(1:c.n)+G.'*lambda-f,inf);
end
