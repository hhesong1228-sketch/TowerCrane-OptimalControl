function [r,J,h]=point(q,v,p,c)
% y downward, origin at undeformed tower top. Small structural rotations.
x=q(c.ix); [P,D,DD]=continuum.modes(x,p.B,c.nj);
r=[x+c.top*q(c.it); -x*c.slope*q(c.it)+P*q(c.ij)];
J=zeros(2,c.ns); J(1,c.it)=c.top; J(1,c.ix)=1;
J(2,c.it)=-x*c.slope; J(2,c.ij)=P;
J(2,c.ix)=-c.slope*q(c.it)+D*q(c.ij);
h=[0;2*(-c.slope*v(c.it)+D*v(c.ij))*v(c.ix)+DD*q(c.ij)*v(c.ix)^2];
end
