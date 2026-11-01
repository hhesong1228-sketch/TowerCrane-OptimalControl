function [M,f,G,phi,phid,gamma,a]=assemble(t,q,v,p,c)
n=c.n; M=zeros(n); f=zeros(n,1);
[r,J,h]=continuum.point(q,v,p,c);
M(1:c.ns,1:c.ns)=c.M+p.mT*(J.'*J);
f(1:c.ns)=c.Fg-c.K*q(1:c.ns)-c.C*v(1:c.ns)+p.mT*J.'*([0;p.g]-h);
[~,L,Ld,Ldd]=flexcrane.inputs(t,p); mesh=linspace(-1,0,p.nElem+1);
Fg=zeros(numel(c.ie),1); U=0; kinetic=0; emin=inf; anorm=zeros(numel(c.ie),1);
for e=1:p.nElem
 loc=4*(e-1)+(1:8); idx=c.ie(loc);
 [Me,Qe,Ge,Ae,Ue,Ke,em]=aleancf.element(q(idx),v(idx), ...
 L*mesh(e:e+1),Ld*mesh(e:e+1),Ldd*mesh(e:e+1),p);
 M(idx,idx)=M(idx,idx)+Me; f(idx)=f(idx)+Ge-Qe-Ae;
 Fg(loc)=Fg(loc)+Ge; anorm(loc)=anorm(loc)+Ae;
 U=U+Ue; kinetic=kinetic+Ke; emin=min(emin,em);
end
M(c.ip,c.ip)=p.mP*eye(2); f(c.ip)=[0;p.mP*p.g];
G=zeros(5,n); G(1:2,1:c.ns)=-J; G(1:2,c.ie(1:2))=eye(2);
G(3:4,c.ie(end-3:end-2))=eye(2); G(3:4,c.ip)=-eye(2); G(5,c.ix)=1;
[x,xd,xdd]=continuum.trajectory(t,p);
phi=[q(c.ie(1:2))-r; q(c.ie(end-3:end-2))-q(c.ip);q(c.ix)-x];
phid=G*v-[0;0;0;0;xd]; gamma=[h;0;0;xdd];
a.energy=0.5*v(1:c.ns).'*c.M*v(1:c.ns)+0.5*p.mT*norm(J*v(1:c.ns))^2 ...
 +kinetic+0.5*p.mP*norm(v(c.ip))^2+0.5*q(1:c.ns).'*c.K*q(1:c.ns) ...
 +U-c.Fg.'*q(1:c.ns)-p.mT*p.g*r(2)-Fg.'*q(c.ie)-p.mP*p.g*q(c.ip(2));
a.L=L; a.axialForceMin=p.EA*emin; a.aleForceNorm=norm(anorm);
a.topX=c.top*q(c.it); a.tipY=p.B*c.slope*q(c.it)+continuum.modes(p.B,p.B,c.nj)*q(c.ij);
a.theta=atan2(q(c.ip(1))-r(1),q(c.ip(2))-r(2)); a.suspension=r;
end
