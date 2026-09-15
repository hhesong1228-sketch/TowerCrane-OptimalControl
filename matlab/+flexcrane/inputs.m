function [u,L,Ld,Ldd] = inputs(t,p)
% Positive Ld pays out rope; quintic profile is C2 at both endpoints.
s = min(1,max(0,(t-p.hoistStart)/p.hoistDuration));
f = 10*s^3-15*s^4+6*s^5;
fd = (30*s^2-60*s^3+30*s^4)/p.hoistDuration;
fdd = (60*s-180*s^2+120*s^3)/p.hoistDuration^2;
L = p.L0+(p.L1-p.L0)*f;
Ld = (p.L1-p.L0)*fd; Ldd = (p.L1-p.L0)*fdd;
u = 0;
if t>=0 && t<=p.forceDuration
    u = p.forceAmplitude*sin(2*pi*t/p.forceDuration)^3;
end
end
