function c=setup(p)
assert(all([p.H p.B p.L0 p.L1 p.muTower p.muJib p.EITower p.EIJib ...
 p.mT p.mP p.rhoA p.EA p.moveDuration p.hoistDuration p.forceDuration p.tEnd]>0), ...
 'Lengths, masses, axial/beam stiffnesses and durations must be positive.');
assert(p.EI>=0 && p.zeta>=0 && p.alpha>=0 && p.beta>=0);
assert(p.nOutput>=2 && p.nOutput==fix(p.nOutput));
assert(min([p.x0 p.x1])>0 && max([p.x0 p.x1])<p.B);
assert(p.nElem>=1 && p.nElem==fix(p.nElem));
c.nt=p.nTower; c.nj=p.nJib; c.ns=c.nt+c.nj+1;
c.it=1:c.nt; c.ij=c.nt+(1:c.nj); c.ix=c.ns;
c.ie=c.ns+(1:4*(p.nElem+1)); c.ip=c.ie(end)+(1:2); c.n=c.ip(end);
[c.top,c.slope]=continuum.modes(p.H,p.H,c.nt);
% Gauss integration of continuous beam energies (not beam finite elements).
nGauss=max(32,4*max(c.nt,c.nj));
j=(1:nGauss-1)'; b=j./sqrt(4*j.^2-1); [V,D]=eig(diag(b,1)+diag(b,-1));
[d,ix]=sort(diag(D)); w=V(1,ix).^2; u=(d+1)/2;
[Pt,~,Bt]=continuum.modes(p.H*u,p.H,c.nt);
[Pj,~,Bj]=continuum.modes(p.B*u,p.B,c.nj);
c.M=zeros(c.ns); c.K=c.M; c.Fg=zeros(c.ns,1);
c.M(c.it,c.it)=p.muTower*p.H*(Pt.'*(w.'.*Pt));
c.K(c.it,c.it)=p.EITower*p.H*(Bt.'*(w.'.*Bt));
c.K(c.ij,c.ij)=p.EIJib*p.B*(Bj.'*(w.'.*Bj));
for k=1:numel(u)
 J=zeros(2,c.ns); J(1,c.it)=c.top;
 J(2,c.it)=p.B*u(k)*c.slope; J(2,c.ij)=Pj(k,:);
 c.M=c.M+p.muJib*p.B*w(k)*(J.'*J);
 c.Fg=c.Fg+p.muJib*p.B*w(k)*p.g*J(2,:).';
end
% Isolated-beam modal damping; jib inertial coupling remains in M.
c.C=zeros(c.ns);
for k=1:c.nt+c.nj
 if k<=c.nt, mm=p.muTower*p.H*sum(w.'.*Pt(:,k).^2);
 else, mm=p.muJib*p.B*sum(w.'.*Pj(:,k-c.nt).^2); end
 c.C(k,k)=2*p.zeta*sqrt(mm*c.K(k,k));
end
end
