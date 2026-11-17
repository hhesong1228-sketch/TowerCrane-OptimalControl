function result=validate_model_limits(runDynamics)
% Four independent checks. Run with false to skip the expensive mesh study.
if nargin<1, runDynamics=true; end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
folder=fullfile(root,'report','model_limits');
if ~exist(folder,'dir'),mkdir(folder);end
p=continuum.parameters(); rows=[];
% Isolated cantilever under a tip load: compare deflection AND tip slope.
F=10; L=p.B; EI=p.EIJib;
for n=[1 2 4 8 16]
 p.nTower=n;p.nJib=n;c=continuum.setup(p);
 [N,D]=continuum.modes(L,L,n); a=c.K(c.ij,c.ij)\(F*N.');
 exact=[F*L^3/(3*EI),F*L^2/(2*EI)]; actual=[N*a,D*a];
 rows(end+1,:)=[n actual exact abs(actual./exact-1)]; %#ok<AGROW>
end
result.static=array2table(rows,'VariableNames',{'modes','deflection_m','rotation_rad','exact_deflection_m','exact_rotation_rad','deflection_relative_error','rotation_relative_error'});
writetable(result.static,fullfile(folder,'static.csv'));
assert(all(rows(end,6:7)<.02),'Cantilever comparison failed');
% Fixed suspension: eliminate ONLY the first two positional DOFs. Slopes free.
% Linearize about the exact gravity-stretched hanging equilibrium.
rows=[];
for ideal=[false true]
 for ne=[3 6 9]
  a=aleancf.parameters();a.nElem=ne;a.theta0=0;a.L1=a.L0;
  if ideal,a.rhoA=1e-5;a.EA=2e6;a.EI=1e-6;end
  z=aleancf.initial_state(a); nd=numel(z)/2;q=z(1:nd);v=zeros(nd,1);
  [M,f]=aleancf.assemble(0,q,v,a);free=3:nd;
  assert(norm(f(free),inf)<1e-6,'Hanging equilibrium');
  K=zeros(nd);h=1e-6;
  for j=free
   d=zeros(nd,1);d(j)=h;
   [~,fp]=aleancf.assemble(0,q+d,v,a);[~,fm]=aleancf.assemble(0,q-d,v,a);
   K(:,j)=-(fp-fm)/(2*h);
  end
  Kf=K(free,free);Kf=(Kf+Kf.')/2;
  ev=eig(Kf,M(free,free));assert(all(real(ev)>0),'Stable fixed suspension');
  omega=sqrt(min(real(ev)));ref=sqrt(a.g/a.L0);
  rows(end+1,:)=[ideal ne omega ref abs(omega/ref-1)]; %#ok<AGROW>
 end
end
result.pendulum=array2table(rows,'VariableNames',{'near_ideal','elements','omega_rad_s','ideal_omega_rad_s','relative_error'});
writetable(result.pendulum,fullfile(folder,'pendulum.csv'));
assert(rows(end,5)<.005,'Near-ideal pendulum limit');
% Zero length rate AND acceleration, arbitrary nonzero nodal velocities.
a=aleancf.parameters();q=[0;0;.1;1; .2;1;.1;1];v=(1:8)'/10;
[~,~,~,A]=aleancf.element(q,v,[-1 0],[0 0],[0 0],a);
[~,~,~,active]=aleancf.element(q,v,[-1 0],[.1 0],[.02 0],a);
result.ale=[norm(A),norm(active)];
assert(norm(A)==0 && norm(active)>1e-8,'ALE stationary-domain limit');
writetable(array2table(result.ale,'VariableNames',{'fixed_domain_force_N','moving_domain_force_N'}),fullfile(folder,'ale.csv'));
if runDynamics
 p=continuum.parameters();p.nTower=4;p.nJib=4;
 p.relTol=2e-8;p.absTol=1e-10;p.maxStep=.01;
 meshes=[3 6 9 12];outs=cell(size(meshes));rows=[];
 for k=1:numel(meshes)
  p.nElem=meshes(k);fprintf('Mesh study: %d elements\n',p.nElem);
  o=continuum.simulate(p);outs{k}=o;
  % End axial constitutive tension EA*(|r_s|-1); separate from end traction.
  o.endTension=zeros(size(o.t));
  for j=1:numel(o.t)
   [~,LL]=flexcrane.inputs(o.t(j),p);
   B=endpointGradient(LL,p.nElem);
   o.endTension(j)=p.EA*(norm(B*o.z(j,o.c.ie(end-7:end)).')-1);
  end
  outs{k}=o;save(fullfile(folder,sprintf('mesh_%d.mat',p.nElem)),'o');
  assert(max(o.constraint)<1e-6 && min(o.axialForceMin)>0,'Mesh constraints/tension');
  if k>1
   old=outs{k-1};dx=old.z(:,old.c.ip)-o.z(:,o.c.ip);
   pos=max(vecnorm(dx,2,2));dt=max(abs(old.endTension-o.endTension));
   reaction=max(vecnorm(old.lambda(:,3:4)-o.lambda(:,3:4),2,2));
   rows(end+1,:)=[meshes(k-1) meshes(k) pos dt dt/max(abs(o.endTension)) reaction]; %#ok<AGROW>
  end
 end
 result.mesh=array2table(rows,'VariableNames',{'coarse_elements','fine_elements','max_payload_distance_m','max_end_tension_difference_N','tension_peak_relative_error','max_payload_traction_difference_N'});
 writetable(result.mesh,fullfile(folder,'mesh.csv'));
 % Report stability with explicit engineering tolerances, not monotonicity alone.
 result.meshPass=rows(end,3)<1e-3 && rows(end,5)<.01;
 % Repeat finest mesh with tighter time integration to identify temporal error.
 p.relTol=2e-9;p.absTol=1e-11;p.maxStep=.005;tight=continuum.simulate(p);
 result.timePayloadError=max(vecnorm(tight.z(:,tight.c.ip)-o.z(:,o.c.ip),2,2));
 save(fullfile(folder,'time_refinement.mat'),'tight');
end
save(fullfile(folder,'validation.mat'),'result');disp(result);
end
function B=endpointGradient(L,n)
[~,B]=aleancf.shape(1,[-L/n 0],[0 0],[0 0]);
end
