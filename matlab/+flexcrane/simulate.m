function out = simulate(p)
% Exact vertical static equilibrium if theta0=0; inclined release otherwise.
validateattributes([p.mT p.mP p.g p.kB p.EA p.L0 p.L1 ...
    p.hoistDuration p.forceDuration p.tEnd p.maxStep],{'numeric'}, ...
    {'real','finite','positive'});
validateattributes([p.cB p.cR],{'numeric'},{'real','finite','nonnegative'});
d0 = (p.mT+p.mP)*p.g/p.kB;
r0 = p.L0+p.mP*p.g/(p.EA/p.L0);
z0 = [0;d0;r0*sin(p.theta0);d0+r0*cos(p.theta0);zeros(5,1)];
opts = odeset('RelTol',p.relTol,'AbsTol',p.absTol,'MaxStep',p.maxStep, ...
    'Events',@(t,z) validity(t,z,p));
[~,a0] = flexcrane.rhs(0,z0,p);
assert(a0.tension>0 && a0.extension>0,'Initial rope must be taut.');
[t,z,te] = ode15s(@(t,z) flexcrane.rhs(t,z,p),linspace(0,p.tEnd,1201),z0,opts);
if ~isempty(te)
    error('flexcrane:OutsideModel','Rope lost tension/extension at t=%.6g s. Slack dynamics are not modeled.',te(1));
end
out.t=t; out.z=z; out.p=p;
fields={'r','L','extension','tension','theta','thetaDot','rDot','energy'};
for j=1:numel(fields), out.(fields{j})=zeros(size(t)); end
for i=1:numel(t)
    [~,a]=flexcrane.rhs(t(i),z(i,:).',p);
    for j=1:numel(fields), out.(fields{j})(i)=a.(fields{j}); end
end
out.energyError = out.energy-out.energy(1)-z(:,9);
end
function [value,isterminal,direction] = validity(t,z,p)
[~,a]=flexcrane.rhs(t,z,p);
value=[a.tension;a.extension;a.r-1e-6];
isterminal=[1;1;1]; direction=[-1;-1;-1];
end
