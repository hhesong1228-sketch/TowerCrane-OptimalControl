function [M,f,a]=assemble(t,q,v,p)
% Shared position/slope DOFs at interfaces; upper position shared with trolley.
[u,L,Ld,Ldd]=flexcrane.inputs(t,p);
mesh=linspace(-1,0,p.nElem+1);
s=L*mesh; sd=Ld*mesh; sdd=Ldd*mesh;
n=numel(q); M=zeros(n); Q=zeros(n,1); Fg=Q; Qale=Q;
a.elasticEnergy=0; a.ropeKinetic=0; a.arcLength=0; a.minStrain=inf;
for e=1:p.nElem
    idx=(4*(e-1)+1):(4*(e+1));
    [Me,Qe,Ge,Ae,Ue,Ke,emin,arc]=aleancf.element(q(idx),v(idx), ...
        s(e:e+1),sd(e:e+1),sdd(e:e+1),p);
    M(idx,idx)=M(idx,idx)+Me;
    Q(idx)=Q(idx)+Qe; Fg(idx)=Fg(idx)+Ge; Qale(idx)=Qale(idx)+Ae;
    a.elasticEnergy=a.elasticEnergy+Ue; a.ropeKinetic=a.ropeKinetic+Ke;
    a.arcLength=a.arcLength+arc; a.minStrain=min(a.minStrain,emin);
end
last=n-3:n-2;
M(1:2,1:2)=M(1:2,1:2)+p.mT*eye(2);
M(last,last)=M(last,last)+p.mP*eye(2);
f=Fg-Q-Qale;
f(1)=f(1)+u;
f(2)=f(2)+p.mT*p.g-p.kB*q(2)-p.cB*v(2);
f(last(2))=f(last(2))+p.mP*p.g;
a.L=L; a.aleForceNorm=norm(Qale);
a.energy=a.ropeKinetic+0.5*p.mT*sum(v(1:2).^2) ...
    +0.5*p.mP*sum(v(last).^2)+a.elasticEnergy+0.5*p.kB*q(2)^2 ...
    -Fg.'*q-p.mT*p.g*q(2)-p.mP*p.g*q(last(2));
a.axialForceMin=p.EA*a.minStrain; % Constitutive axial force, not total end traction.
end
