function A=mass(t,p)
% First-order mass matrix diag(I,M(t)); independent of mechanical state.
[~,L,Ld,Ldd]=flexcrane.inputs(t,p);
mesh=linspace(-1,0,p.nElem+1); n=4*(p.nElem+1); M=sparse(n,n);
for e=1:p.nElem
    idx=4*(e-1)+1:4*(e+1);
    a=aleancf.geometry(L*mesh(e:e+1),Ld*mesh(e:e+1),Ldd*mesh(e:e+1));
    M(idx,idx)=M(idx,idx)+p.rhoA*a.M;
end
M(1:2,1:2)=M(1:2,1:2)+p.mT*eye(2);
last=n-3:n-2; M(last,last)=M(last,last)+p.mP*eye(2);
A=blkdiag(speye(n),M);
end
