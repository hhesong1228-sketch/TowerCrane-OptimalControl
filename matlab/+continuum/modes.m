function [P,D,DD]=modes(x,L,n)
% Exact unloaded cantilever modes, tip normalized; x is a column.
roots=[1.875104068711961 4.694091132974174 7.854757438237612 10.99554073487547];
assert(n>=1 && n<=4 && n==fix(n),'Use 1 to 4 modes per beam.');
x=x(:); P=zeros(numel(x),n); D=P; DD=P;
for k=1:n
 b=roots(k); a=(cosh(b)+cos(b))/(sinh(b)+sin(b)); z=b*x/L;
 normtip=cosh(b)-cos(b)-a*(sinh(b)-sin(b));
 P(:,k)=(cosh(z)-cos(z)-a*(sinh(z)-sin(z)))/normtip;
 D(:,k)=b/L*(sinh(z)+sin(z)-a*(cosh(z)-cos(z)))/normtip;
 DD(:,k)=(b/L)^2*(cosh(z)+cos(z)-a*(sinh(z)+sin(z)))/normtip;
end
end
