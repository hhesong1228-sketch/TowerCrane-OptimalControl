function [N,B,C,Nt,Ntt]=shape(xi,s,sd,sdd)
% Cubic Hermite interpolation, q_e=[r1(2);r_s1(2);r2(2);r_s2(2)].
% Nt,Ntt are at FIXED MATERIAL COORDINATE s, not fixed xi.
l=s(2)-s(1); ld=sd(2)-sd(1); ldd=sdd(2)-sdd(1);
H=[1-3*xi^2+2*xi^3,xi-2*xi^2+xi^3,3*xi^2-2*xi^3,-xi^2+xi^3];
Hx=[-6*xi+6*xi^2,1-4*xi+3*xi^2,6*xi-6*xi^2,-2*xi+3*xi^2];
Hxx=[-6+12*xi,-4+6*xi,6-12*xi,-2+6*xi];
f=[1 l 1 l]; fd=[0 ld 0 ld]; fdd=[0 ldd 0 ldd];
xd=-(sd(1)+xi*ld)/l;
xdd=-(sdd(1)+xi*ldd+2*xd*ld)/l;
N=kron(H.*f,eye(2));
B=kron(Hx.*f/l,eye(2)); C=kron(Hxx.*f/l^2,eye(2));
Nt=kron(Hx.*f*xd+H.*fd,eye(2));
Ntt=kron((Hxx*xd^2+Hx*xdd).*f+2*Hx.*fd*xd+H.*fdd,eye(2));
end
