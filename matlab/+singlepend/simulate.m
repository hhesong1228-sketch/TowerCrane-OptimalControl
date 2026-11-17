function out=simulate(p)
c=continuum.setup(p); full=continuum.initial_state(p,c);
y=[full(1:c.ns);p.theta0]; z0=[y;zeros(size(y))];
opts=odeset('RelTol',p.relTol,'AbsTol',p.absTol,'MaxStep',p.maxStep);
[out.t,out.z]=ode15s(@(t,z)singlepend.rhs(t,z,p,c),linspace(0,p.tEnd,p.nOutput),z0,opts);
out.p=p; out.c=c;
for k=1:numel(out.t)
 [~,a]=singlepend.rhs(out.t(k),out.z(k,:).',p,c);
 fields={'topX','tipY','theta','L','suspension','force','payload','drive','constraint','residual'};
 for j=1:numel(fields), out.(fields{j})(k,:)=a.(fields{j})(:).'; end
end
end
