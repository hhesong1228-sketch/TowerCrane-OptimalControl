function test_rigid_continuum()
% Rigid-frame reduction must retain ALE cable and enforce identical motion.
p=continuum.parameters(); p.nTower=0; p.nJib=0;
c=continuum.setup(p); z=continuum.initial_state(p,c);
assert(c.ns==1 && isempty(c.it) && isempty(c.ij));
[r,J,h]=continuum.point(z(1:c.n),z(c.n+1:end),p,c);
assert(norm(r-[p.x0;0])<1e-12 && isequal(J,[1;0]) && norm(h)==0);
[M,~,G,phi]=continuum.assemble(0,z(1:c.n),z(c.n+1:end),p,c);
assert(norm(phi,inf)<1e-12 && rank(G)==5);
assert(min(eig(M))>0);
[~,~,res]=continuum.rhs(0,z,p,c); assert(res<1e-8);
fprintf('Rigid-frame geometry, initialization, mass, constraints and force balance passed.\n');
end
