function [dz,a]=rhs(t,z,p,c)
n=c.ns+1; y=z(1:n); w=z(n+1:end);
[q,v,T,b]=singlepend.map(t,y,w,p,c);
[M,f,~,~,~,~,a]=continuum.assemble(t,q,v,p,c);
Mr=T.'*M*T; fr=T.'*(f-M*b);
G=zeros(1,n); G(c.ix)=1;
[x,xd,xdd]=continuum.trajectory(t,p);
sol=[Mr G.';G 0]\[fr;xdd-2*p.alpha*(w(c.ix)-xd)-p.beta^2*(y(c.ix)-x)];
acc=T*sol(1:n)+b; reaction=M*acc-f;
rr=reshape(reaction(c.ie),4,[]);
a.force=-(sum(rr(1:2,:),2)+reaction(c.ip));
a.payload=q(c.ip).'; a.drive=-sol(end);
a.constraint=abs(y(c.ix)-x);
a.residual=norm(Mr*sol(1:n)+G.'*sol(end)-fr,inf);
dz=[w;sol(1:n)];
end
