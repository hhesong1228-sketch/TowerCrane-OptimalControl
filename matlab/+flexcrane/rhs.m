function [dz,a] = rhs(t,z,p)
% z=[x;d;X;Y;vx;vd;vX;vY;W]. All vertical coordinates point DOWN.
% W integrates the exact net input power of this reduced model.
[u,L,Ld] = flexcrane.inputs(t,p);
h = z(3:4)-z(1:2); v = z(7:8)-z(5:6);
r = norm(h); n = h/r; rd = n.'*v;
e = r-L; ed = rd-Ld; k = p.EA/L;
T = k*e+p.cR*ed; % Valid only in taut regime; event stops before compression.
acc = [(u+T*n(1))/p.mT; ...
    p.g+(T*n(2)-p.kB*z(2)-p.cB*z(6))/p.mT; ...
    -T*n(1)/p.mP; p.g-T*n(2)/p.mP];
kdot = -p.EA*Ld/L^2;
power = u*z(5)-p.cB*z(6)^2-p.cR*ed^2-T*Ld+0.5*kdot*e^2;
dz = [z(5:8);acc;power];
if nargout>1
    a.r = r; a.L = L; a.extension = e; a.tension = T;
    a.theta = atan2(h(1),h(2));
    a.thetaDot = (h(2)*v(1)-h(1)*v(2))/r^2;
    a.rDot = rd;
    a.energy = 0.5*p.mT*sum(z(5:6).^2)+0.5*p.mP*sum(z(7:8).^2) ...
        -p.mT*p.g*z(2)-p.mP*p.g*z(4)+0.5*p.kB*z(2)^2+0.5*k*e^2;
end
end
