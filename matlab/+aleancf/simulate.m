function out=simulate(p)
validateattributes(p.nElem,{'numeric'},{'scalar','integer','>=',1});
validateattributes([p.L0 p.L1 p.EA p.EI p.rhoA p.mT p.mP p.kB ...
    p.tEnd p.hoistDuration p.forceDuration],{'numeric'},{'real','finite','positive'});
assert(p.hoistStart>=0,'Initial state requires hoisting to start at or after zero.');
z0=aleancf.initial_state(p);
n=numel(z0)/2; pattern=sparse(n,n);
for e=1:p.nElem
    idx=4*(e-1)+1:4*(e+1); pattern(idx,idx)=1;
end
jacPattern=[sparse(n,n),speye(n);pattern,pattern];
opts=odeset('Mass',@(t,z) aleancf.mass(t,p), ...
    'MStateDependence','none','MassSingular','no','JPattern',jacPattern, ...
    'RelTol' ,p.relTol,'AbsTol',p.absTol,'MaxStep',p.maxStep, ...
    'Events',@(t,z) taut(t,z,p));
[out.t,out.z,te]=ode15s(@(t,z) forces(t,z,p), ...
    linspace(0,p.tEnd,p.nOutput),z0,opts);
if ~isempty(te), error('aleancf:Compression','Axial compression detected at %.6g s; taut-cable model stopped.',te(1)); end
out.p=p; n=numel(z0)/2; out.q=out.z(:,1:n); out.v=out.z(:,n+1:end);
fields={'L','arcLength','energy','axialForceMin','aleForceNorm'};
for j=1:numel(fields), out.(fields{j})=zeros(size(out.t)); end
for i=1:numel(out.t)
    [~,~,a]=aleancf.assemble(out.t(i),out.q(i,:).',out.v(i,:).',p);
    for j=1:numel(fields), out.(fields{j})(i)=a.(fields{j}); end
end
h=out.q(:,n-3:n-2)-out.q(:,1:2);
out.theta=atan2(h(:,1),h(:,2)); % Chord angle; a curved cable has no single local angle.
end
function [value,isterminal,direction]=taut(t,z,p)
[~,L,Ld,Ldd]=flexcrane.inputs(t,p); mesh=linspace(-1,0,p.nElem+1);
value=inf;
for e=1:p.nElem
    idx=4*(e-1)+1:4*(e+1);
    % Use the exact same geometry key as mass/RHS to reuse cached integrals.
    geo=aleancf.geometry(L*mesh(e:e+1),Ld*mesh(e:e+1),Ldd*mesh(e:e+1));
    for j=1:8
        value=min(value,norm(geo.B(:,:,j)*z(idx))-1);
    end
end
isterminal=1; direction=-1;
end
function f=forces(t,z,p)
n=numel(z)/2; [~,force]=aleancf.assemble(t,z(1:n),z(n+1:end),p);
f=[z(n+1:end);force];
end
