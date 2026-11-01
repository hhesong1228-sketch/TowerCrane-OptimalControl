function z=initial_state(p,c)
% Exact reduced static equilibrium for fixed prescribed trolley x0.
q=zeros(c.n,1); v=q; q(c.ix)=p.x0;
[~,J]=continuum.point(q,v,p,c); m=p.mT+p.mP+p.rhoA*p.L0;
idx=1:c.ns-1; q(idx)=c.K(idx,idx)\(c.Fg(idx)+m*p.g*J(2,idx).');
r=continuum.point(q,v,p,c); u=linspace(0,p.L0,p.nElem+1);
d=[sin(p.theta0);cos(p.theta0)];
for k=1:numel(u)
 stretch=1+(p.mP*p.g+p.rhoA*p.g*(p.L0-u(k)))/p.EA;
 arc=u(k)+(p.mP*p.g*u(k)+p.rhoA*p.g*(p.L0*u(k)-u(k)^2/2))/p.EA;
 idx=c.ie(4*(k-1)+(1:4)); q(idx)=[r+arc*d;stretch*d];
end
q(c.ip)=q(c.ie(end-3:end-2)); z=[q;v];
end
