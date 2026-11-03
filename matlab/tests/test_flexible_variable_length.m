function test_flexible_variable_length()
% Physics-based regression tests, using MATLAB's actual ODE solver.
p=flexcrane.parameters();
p.theta0=0; p.forceAmplitude=0; p.L1=p.L0;
s=flexcrane.simulate(p);
assert(max(max(abs(s.z(:,1:8)-s.z(1,1:8))))<1e-8,'Static equilibrium');
assert(max(abs(s.tension-p.mP*p.g))<1e-6,'Static rope tension');
fprintf('PASS static equilibrium and tension\n');
p.theta0=0.12; p.cB=0; p.cR=0;
s=flexcrane.simulate(p);
assert(max(abs(s.energy-s.energy(1)))<1e-5,'Conservative energy');
assert(max(abs(p.mT*s.z(:,5)+p.mP*s.z(:,7)))<1e-8,'Horizontal momentum');
fprintf('PASS conservative energy and horizontal momentum\n');
p=flexcrane.parameters(); s=flexcrane.simulate(p);
assert(all(isfinite(s.z(:))) && s.t(end)==p.tEnd,'Complete finite trajectory');
assert(min(s.tension)>0 && min(s.extension)>0,'Taut regime');
assert(abs(s.L(end)-p.L1)<1e-12,'Hoisting endpoint');
assert(max(abs(s.energyError))<1e-5,'Variable-stiffness energy/work');
% Independent polar-form identity, including support acceleration and Coriolis term.
for i=1:30:numel(s.t)
    z=s.z(i,:).'; [dz,a]=flexcrane.rhs(s.t(i),z,p);
    h=z(3:4)-z(1:2); ar=dz(7:8)-dz(5:6);
    thetaDD=(h(2)*ar(1)-h(1)*ar(2))/a.r^2-2*a.rDot*a.thetaDot/a.r;
    residual=a.r*thetaDD+2*a.rDot*a.thetaDot ...
        +dz(5)*cos(a.theta)+(p.g-dz(6))*sin(a.theta);
    assert(abs(residual)<1e-10,'Polar swing identity');
end
p.relTol=1e-10; p.absTol=1e-12; p.maxStep=0.005;
fine=flexcrane.simulate(p);
assert(max(max(abs(fine.z(:,1:8)-s.z(:,1:8))))<2e-5,'Solver convergence');
fprintf('PASS hoisting, energy/work, nonlinear swing identity, convergence\n');
fprintf('Demo: min T %.6f N, max extension %.6f m, max swing %.6f deg\n', ...
    min(s.tension),max(s.extension),max(abs(s.theta))*180/pi);
fprintf('Demo max energy error %.3e J; refined state difference %.3e\n', ...
    max(abs(s.energyError)),max(max(abs(fine.z(:,1:8)-s.z(:,1:8)))));
end
