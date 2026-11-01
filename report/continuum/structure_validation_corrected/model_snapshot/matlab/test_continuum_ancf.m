function test_continuum_ancf()
% Independent invariants and refinement checks for the hybrid model.
folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'report','continuum','structure_validation_corrected','regression');
if ~exist(folder,'dir'), mkdir(folder); end
diary(fullfile(folder,'validation.txt')); cleanup=onCleanup(@()diary('off')); %#ok<NASGU>
audit_continuum_connection(); % Independent physical check guards against sign regressions.
fprintf('Continuous-beam / ANCF validation %s\n',datestr(now,30));
p=continuum.parameters(); p.theta0=0; p.L1=p.L0; p.x1=p.x0;
c=continuum.setup(p); z=continuum.initial_state(p,c); q=z(1:c.n); v=z(c.n+1:end);
[M,f,G,phi]=continuum.assemble(0,q,v,p,c);
assert(norm(M-M.','fro')<1e-10 && min(eig(M))>0,'Mass SPD');
assert(rank(G)==5 && norm(phi,inf)<1e-12,'Independent consistent constraints');
dz=continuum.rhs(0,z,p,c); assert(norm(dz,inf)<1e-6,'Static balance');
fprintf('PASS static acceleration %.3e, SPD mass, independent constraints\n',norm(dz,inf));
% Analytic continuous-beam first frequency against integrated modal energies.
b=1.875104068711961;
fExpected=b^2/(2*pi*p.H^2)*sqrt(p.EITower/p.muTower);
[Pt,~,Bt]=continuum.modes(linspace(0,p.H,20001)',p.H,1);
fIntegrated=sqrt(p.EITower*trapz(linspace(0,p.H,20001)',Bt.^2)/(p.muTower*trapz(linspace(0,p.H,20001)',Pt.^2)))/(2*pi);
assert(abs(fExpected-fIntegrated)<1e-6);
fprintf('PASS isolated tower first frequency %.8f Hz\n',fExpected);
% Convective acceleration of moving trolley versus directional differences.
v(1:c.ns)=linspace(-.1,.15,c.ns); step=1e-4;
[r,J,h]=continuum.point(q,v,p,c);
rp=continuum.point(q+step*v,v,p,c); rm=continuum.point(q-step*v,v,p,c);
assert(norm((rp-rm)/(2*step)-J*v(1:c.ns))<1e-8);
assert(norm((rp-2*r+rm)/step^2-h)<1e-6);
fprintf('PASS moving attachment velocity and convective acceleration\n');
% Coupled tangent frequencies at loaded equilibrium, constrained x fixed.
[~,lambda]=continuum.rhs(0,z,p,c); K=zeros(c.n); step=1e-6;
for j=1:c.n
 dq=zeros(c.n,1); dq(j)=step;
 [~,fp,Gp]=continuum.assemble(0,q+dq,zeros(c.n,1),p,c);
 [~,fm,Gm]=continuum.assemble(0,q-dq,zeros(c.n,1),p,c);
 K(:,j)=(-fp+Gp.'*lambda+fm-Gm.'*lambda)/(2*step);
end
Z=null(G); Kr=Z.'*K*Z; Mr=Z.'*M*Z;
assert(norm(Kr-Kr.','fro')/norm(Kr,'fro')<1e-7,'Tangent symmetry');
w2=sort(eig((Kr+Kr.')/2,Mr)); assert(all(w2>0),'Loaded equilibrium stability');
freq=sqrt(w2)/(2*pi); writematrix(freq,fullfile(folder,'frequencies_hz.csv'));
fprintf('Coupled first six frequencies (Hz):'); fprintf(' %.7f',freq(1:min(6,end))); fprintf('\n');
p.theta0=.035; p.zeta=0; p.tEnd=2; p.nOutput=201; p.relTol=1e-9; p.absTol=1e-11; p.maxStep=.01;
a=continuum.simulate(p); drift=max(abs(a.energy-a.energy(1)));
assert(drift<2e-5,'Conservative fixed-domain energy');
assert(max(a.constraint)<1e-7,'Position drift');
fprintf('PASS fixed-domain energy drift %.3e J; constraint %.3e m\n',drift,max(a.constraint));
p=continuum.parameters(); p.tEnd=6; p.nOutput=301;
a=continuum.simulate(p);
assert(min(a.axialForceMin)>0 && max(a.aleForceNorm)>1e-5);
assert(max(a.constraint)<1e-6 && max(a.velocityConstraint)<1e-5);
assert(max(a.residual)<1e-7);
fprintf('PASS trolley + hoist: min axial %.5f N, constraint %.3e m, dynamics %.3e\n',min(a.axialForceMin),max(a.constraint),max(a.residual));
p.relTol=2e-8; p.absTol=1e-10; p.maxStep=.01;
fprintf('Running tighter time tolerances...\n');
bout=continuum.simulate(p); et=max(abs(a.theta-bout.theta)); assert(et<1e-4);
p.nElem=6; fprintf('Running six rope elements...\n'); d=continuum.simulate(p); em=max(abs(d.theta-bout.theta)); assert(em<2e-3);
p.nTower=3; p.nJib=3; fprintf('Running three modes per beam...\n'); e=continuum.simulate(p); es=max(abs(e.theta-d.theta));
assert(es<2e-3);
fprintf('PASS angle sensitivity: time %.3e rad; rope 3/6 %.3e rad; modes 2/3 %.3e rad\n',et,em,es);
fprintf('Tower displacement mode sensitivity %.3e m; jib tip %.3e m\n',max(abs(e.topX-d.topX)),max(abs(e.tipY-d.tipY)));
fprintf('ALL CHECKS PASSED. Sensitivity checks do not establish local stress convergence.\n');
end
