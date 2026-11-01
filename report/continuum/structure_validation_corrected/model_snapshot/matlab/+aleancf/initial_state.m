function z=initial_state(p)
% Exact straight hanging static field under distributed weight at theta0=0.
u=linspace(0,p.L0,p.nElem+1);
y=u+(p.mP*p.g*u+p.rhoA*p.g*(p.L0*u-u.^2/2))/p.EA;
grad=1+(p.mP*p.g+p.rhoA*p.g*(p.L0-u))/p.EA;
d=(p.mT+p.mP+p.rhoA*p.L0)*p.g/p.kB;
dir=[sin(p.theta0);cos(p.theta0)];
q=zeros(4*(p.nElem+1),1);
for j=1:p.nElem+1
    k=4*(j-1); q(k+(1:2))=[0;d]+dir*y(j); q(k+(3:4))=dir*grad(j);
end
z=[q;zeros(size(q))];
end
