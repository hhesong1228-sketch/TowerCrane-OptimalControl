function [q,v,T,b]=map(t,y,w,p,c)
% Map beam coordinates + one swing angle into the existing ANCF coordinates.
ns=c.ns; th=y(end); td=w(end); d=[sin(th);cos(th)]; dp=[cos(th);-sin(th)];
q=zeros(c.n,1); v=q; q(1:ns)=y(1:ns); v(1:ns)=w(1:ns);
[r,J,h]=continuum.point(q,v,p,c);
[~,L,Ld,Ldd]=flexcrane.inputs(t,p);
T=zeros(c.n,ns+1); T(1:ns,1:ns)=eye(ns); b=zeros(c.n,1);
for k=0:p.nElem
 f=k/p.nElem; idx=c.ie(4*k+(1:4));
 q(idx)=[r+L*f*d;d];
 v(idx)=[J*w(1:ns)+Ld*f*d+L*f*dp*td;dp*td];
 T(idx(1:2),1:ns)=J; T(idx(1:2),end)=L*f*dp; T(idx(3:4),end)=dp;
 b(idx)=[h+Ldd*f*d+2*Ld*f*dp*td-L*f*d*td^2;-d*td^2];
end
q(c.ip)=q(c.ie(end-3:end-2)); v(c.ip)=v(c.ie(end-3:end-2));
T(c.ip,:)=T(c.ie(end-3:end-2),:); b(c.ip)=b(c.ie(end-3:end-2));
end
