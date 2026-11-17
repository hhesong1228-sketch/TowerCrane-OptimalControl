function test_singlepend()
p=continuum.parameters(); p.theta0=0; c=continuum.setup(p);
zfull=continuum.initial_state(p,c); n=c.ns+1; z=[zfull(1:c.ns);0;zeros(n,1)];
[q,v,T,b]=singlepend.map(0,z(1:n),z(n+1:end),p,c);
assert(norm(q(c.ip)-q(c.ie(1:2))-[0;p.L0])<1e-12);
assert(norm(v)==0 && norm(b)==0);
[M,~,~,phi]=continuum.assemble(0,q,v,p,c);
assert(norm(phi,inf)<1e-12 && min(eig(T.'*M*T))>0);
[dz,a]=singlepend.rhs(0,z,p,c);
assert(norm(dz)<1e-8 && a.residual<1e-8);
assert(abs(a.force(2)-(p.mP+p.rhoA*p.L0)*p.g)<1e-8);
% Check time-dependent map derivatives during hoisting and trolley motion.
for duration=[6 .75]
p.hoistDuration=duration;
t=2+duration*.3; y=z(1:n); w=0.01*ones(n,1); dt=1e-5;
[q,v,T,b]=singlepend.map(t,y,w,p,c);
[qp,vp]=singlepend.map(t+dt,y+dt*w,w,p,c);
[qm,vm]=singlepend.map(t-dt,y-dt*w,w,p,c);
assert(norm((qp-qm)/(2*dt)-v,inf)<1e-7);
assert(norm((vp-vm)/(2*dt)-b,inf)<1e-7);
end
fprintf('PASS single pendulum static reaction, mass, constraints and moving-map derivatives.\n');
end
