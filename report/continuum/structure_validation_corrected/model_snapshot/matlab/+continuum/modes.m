function [P,D,DD]=modes(x,L,n)
% Tip-normalized unloaded cantilever modes. Stable exponential evaluation.
% cosh(z)-sigma*sinh(z) is evaluated without subtracting large numbers.
assert(n>=1 && n<=16 && n==fix(n),'Use 1 to 16 modes per beam.');
persistent roots
if isempty(roots)
 roots=zeros(1,16);
 for k=1:16
  mid=(k-.5)*pi;
  roots(k)=fzero(@(b)cos(b)+1/cosh(b),[mid-.5 mid+.5]);
 end
end
x=x(:); P=zeros(numel(x),n); D=P; DD=P;
for k=1:n
 b=roots(k); den=sinh(b)+sin(b);
 sigma=(cosh(b)+cos(b))/den;
 minus=(sin(b)-cos(b)-exp(-b))/den; plus=1+sigma;
 z=b*x/L;
 A=.5*(minus*exp(z)+plus*exp(-z));
 B=.5*(minus*exp(z)-plus*exp(-z));
 tip=.5*(minus*exp(b)+plus*exp(-b))-cos(b)+sigma*sin(b);
 P(:,k)=(A-cos(z)+sigma*sin(z))/tip;
 D(:,k)=b/L*(B+sin(z)+sigma*cos(z))/tip;
 DD(:,k)=(b/L)^2*(A+cos(z)-sigma*sin(z))/tip;
end
end
