function test_aleancf()
% ALE kinematics, variational elastic force, mass, statics, energy and mesh tests.
p=aleancf.parameters();
s=[-1.3,-0.2]; sd=[0.15,0.03]; sdd=[-0.07,0.02]; xi=0.37;
q=[0;0;0.1;1.01;0.15;1.12;0.2;1.02]; v=(1:8)'/100; acc=flipud(v);
[N,B,~,Nt,Ntt]=aleancf.shape(xi,s,sd,sdd);
% Reference via finite differences holding physical material coordinate fixed.
sm=s(1)+xi*diff(s); dt=1e-4; r=zeros(2,3);
for j=1:3
    h=(j-2)*dt; sh=s+sd*h+0.5*sdd*h^2;
    Nh=aleancf.shape((sm-sh(1))/diff(sh),sh,[0 0],[0 0]);
    r(:,j)=Nh*(q+v*h+0.5*acc*h^2);
end
assert(norm((r(:,3)-r(:,1))/(2*dt)-(N*v+Nt*q))<1e-7,'Material velocity');
assert(norm((r(:,3)-2*r(:,2)+r(:,1))/dt^2-(N*acc+2*Nt*v+Ntt*q))<1e-6,'Material acceleration');
% Stationary material field represented by a moving computational mesh.
qp=[0;s(1);0;1;0;s(2);0;1]; vp=[0;sd(1);0;0;0;sd(2);0;0];
ap=[0;sdd(1);0;0;0;sdd(2);0;0];
assert(norm(N*vp+Nt*qp)<1e-12,'ALE material velocity patch');
assert(norm(N*ap+2*Nt*vp+Ntt*qp)<1e-12,'ALE acceleration patch');
[~,~,~,Ntf,Nttf]=aleancf.shape(xi,s,[0 0],[0 0]);
assert(norm(Ntf)+norm(Nttf)==0,'Fixed-length ANCF limit');
assert(norm(B*qp-[0;1])<1e-12,'Hermite gradient patch');
fprintf('PASS fixed-material derivatives, ALE patch, fixed-length ANCF limit\n');
[M,Q,~,~,U]=aleancf.element(q,v,s,sd,sdd,p); %#ok<ASGLU>
grad=zeros(8,1); step=1e-6;
for j=1:8
    dq=zeros(8,1); dq(j)=step;
    [~,~,~,~,up]=aleancf.element(q+dq,v,s,sd,sdd,p);
    [~,~,~,~,um]=aleancf.element(q-dq,v,s,sd,sdd,p);
    grad(j)=(up-um)/(2*step);
end
assert(norm(grad-Q)/max(1,norm(Q))<1e-7,'Elastic energy gradient');
assert(norm(M-M.')<1e-12 && min(eig(M))>0,'Positive symmetric mass');
trans=[1;0;0;0;1;0;0;0];
assert(abs(trans.'*M*trans-p.rhoA*diff(s))<1e-12,'Distributed mass');
% Pure curved field with EA=0 isolates the bending gradient.
pbend=p; pbend.EA=0;
[~,qb]=aleancf.element(q,v,s,sd,sdd,pbend);
for j=1:8
    dq=zeros(8,1); dq(j)=step;
    [~,~,~,~,up]=aleancf.element(q+dq,v,s,sd,sdd,pbend);
    [~,~,~,~,um]=aleancf.element(q-dq,v,s,sd,sdd,pbend);
    grad(j)=(up-um)/(2*step);
end
assert(norm(grad-qb)<1e-8,'Bending energy gradient');
fprintf('PASS axial/bending force gradients and consistent mass\n');
zcheck=aleancf.initial_state(p); n=numel(zcheck)/2;
for t=[0 3 6 10]
    [Mc,~]=aleancf.assemble(t,zcheck(1:n),zcheck(n+1:end),p);
    A=aleancf.mass(t,p);
    assert(norm(full(A(n+1:end,n+1:end))-Mc,'fro')<1e-12,'First-order mass');
end
fprintf('PASS first-order mass matches mechanical assembly at four times\n');
p.theta0=0; p.forceAmplitude=0; p.L1=p.L0;
z0=aleancf.initial_state(p); dz=aleancf.rhs(0,z0,p);
assert(norm(dz,inf)<1e-7,'Distributed-weight static equilibrium');
p.theta0=0.05; p.cB=0; p.tEnd=2; p.nOutput=101;
p.relTol=1e-9; p.absTol=1e-11; p.maxStep=0.01;
fixed=aleancf.simulate(p);
energyError=max(abs(fixed.energy-fixed.energy(1)));
assert(energyError<2e-5,'Fixed-domain energy conservation');
fprintf('PASS static equilibrium and fixed-domain energy; drift %.3e J\n',energyError);
fprintf('Running 3-element hoisting case...\n');
p=aleancf.parameters(); coarse=aleancf.simulate(p);
assert(all(isfinite(coarse.z(:))) && coarse.t(end)==p.tEnd,'Finite completed hoist');
assert(abs(coarse.L(end)-p.L1)<1e-12 && min(coarse.axialForceMin)>0,'Hoist and tension');
assert(max(coarse.aleForceNorm)>1e-6,'Active ALE inertia');
p.relTol=2e-8; p.absTol=1e-10; p.maxStep=0.01;
fprintf('Running tighter time tolerances...\n');
fineTime=aleancf.simulate(p);
timeError=max(abs(fineTime.theta-coarse.theta));
assert(timeError<1e-4,'Time integration convergence');
fprintf('Running 6-element mesh comparison...\n');
p.nElem=6; fineMesh=aleancf.simulate(p);
meshError=max(abs(fineMesh.theta-fineTime.theta));
assert(meshError<2e-3,'3 versus 6 element chord-angle comparison');
fprintf('Running 9-element mesh comparison...\n');
p.nElem=9; finerMesh=aleancf.simulate(p);
meshError2=max(abs(finerMesh.theta-fineMesh.theta));
assert(meshError2<meshError && meshError2<1e-3,'6 versus 9 element refinement');
fprintf('PASS hoisting and time/mesh refinement\n');
fprintf('Time error %.3e rad; mesh 3/6 %.3e rad; mesh 6/9 %.3e rad\n',timeError,meshError,meshError2);
fprintf('Demo max chord swing %.6f deg, min axial force %.6f N\n', ...
    max(abs(coarse.theta))*180/pi,min(coarse.axialForceMin));
end
