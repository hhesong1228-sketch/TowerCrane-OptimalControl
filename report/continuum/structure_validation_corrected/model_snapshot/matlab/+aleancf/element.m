function [M,Q,Fg,Qale,U,kinetic,minStrain,arc]=element(q,v,s,sd,sdd,p)
% Reduced equations with prescribed material coordinates. Eight-point Gauss rule.
geo=aleancf.geometry(s,sd,sdd);
M=p.rhoA*geo.M; Fg=p.rhoA*p.g*geo.G;
Qale=p.rhoA*(geo.A1*v+geo.A2*q); Q=zeros(8,1);
U=0; kinetic=0; minStrain=inf; arc=0;
for j=1:8
    N=geo.N(:,:,j); B=geo.B(:,:,j); C=geo.C(:,:,j); Nt=geo.Nt(:,:,j);
    a=B*q; b=C*q; D=a.'*a; stretch=sqrt(D);
    if stretch<1e-8, error('aleancf:Collapsed','Degenerate cable tangent.'); end
    eps=stretch-1; crossAB=a(1)*b(2)-a(2)*b(1);
    K=crossAB/D; % Signed version of the paper's curvature measure.
    dKa=[b(2);-b(1)]/D-2*crossAB*a/D^2;
    dKb=[-a(2);a(1)]/D;
    w=geo.w(j);
    Q=Q+w*(p.EA*eps*(B.'*a)/stretch+p.EI*K*(B.'*dKa+C.'*dKb));
    vm=N*v+Nt*q;
    kinetic=kinetic+0.5*w*p.rhoA*(vm.'*vm);
    U=U+0.5*w*(p.EA*eps^2+p.EI*K^2);
    arc=arc+w*stretch; minStrain=min(minStrain,eps);
end
end
