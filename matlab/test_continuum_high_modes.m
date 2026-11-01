function test_continuum_high_modes()
% Independent normalization / orthogonality checks for the extended basis.
n=16;L=4;j=(1:95)';b=j./sqrt(4*j.^2-1);
[V,D]=eig(diag(b,1)+diag(b,-1));[d,ix]=sort(diag(D));w=L*V(1,ix).^2;
[P,~,DD]=continuum.modes(L*(d+1)/2,L,n);
beta=zeros(n,1);
for k=1:n,beta(k)=fzero(@(b)cos(b)+1/cosh(b),[(k-.5)*pi-.5 (k-.5)*pi+.5]);end
mass=P.'*(w.'.*P);stiff=DD.'*(w.'.*DD);
exactMass=L/4*eye(n);exactStiff=diag(beta.^4/(4*L^3));
me=norm(mass-exactMass,'fro')/norm(exactMass,'fro');
ke=norm(stiff-exactStiff,'fro')/norm(exactStiff,'fro');
[P0,D0]=continuum.modes(0,L,n);Pt=continuum.modes(L,L,n);
assert(me<1e-10 && ke<1e-10,'High-order continuous integrals');
assert(norm(P0,inf)<1e-12 && norm(D0,inf)<1e-12 && norm(Pt-1,inf)<1e-12);
fprintf('PASS 16-mode orthogonality: mass %.3e, stiffness %.3e; clamped base and tip normalization\n',me,ke);
end
