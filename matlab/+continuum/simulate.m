function out=simulate(p)
c=continuum.setup(p); z0=continuum.initial_state(p,c);
opts=odeset('RelTol',p.relTol,'AbsTol',p.absTol,'MaxStep',p.maxStep,'Events',@events);
[t,z]=ode15s(@(t,z)continuum.rhs(t,z,p,c),linspace(0,p.tEnd,p.nOutput),z0,opts);
if t(end)<p.tEnd-1e-8, error('continuum:Slack','Stopped: sampled cable strain reached zero.'); end
out.p=p; out.t=t; out.z=z; out.c=c;
for k=1:numel(t)
 q=z(k,1:c.n).'; v=z(k,c.n+1:end).';
 [~,~,~,phi,phid,~,a]=continuum.assemble(t(k),q,v,p,c);
 [~,lam,res]=continuum.rhs(t(k),z(k,:).',p,c);
 fields={'energy','L','axialForceMin','aleForceNorm','topX','tipY','theta'};
 for j=1:numel(fields), out.(fields{j})(k,1)=a.(fields{j}); end
 out.constraint(k,1)=norm(phi,inf); out.velocityConstraint(k,1)=norm(phid,inf);
 out.lambda(k,:)=lam.'; out.residual(k,1)=res; out.suspension(k,:)=a.suspension.';
end
 function [value,isterminal,direction]=events(t,z)
 [~,~,~,~,~,~,a]=continuum.assemble(t,z(1:c.n),z(c.n+1:end),p,c);
 value=a.axialForceMin; isterminal=1; direction=-1;
 end
end
