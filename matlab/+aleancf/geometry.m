function a=geometry(s,sd,sdd)
% Cache ONLY geometry-dependent integrals; never cache state-dependent forces.
% Reused by RHS, events, numerical Jacobians and mass evaluations at the same t.
persistent pts weights keys values cursor
if isempty(pts)
    j=(1:7)'; b=j./sqrt(4*j.^2-1);
    [V,D]=eig(diag(b,1)+diag(b,-1));
    [d,idx]=sort(diag(D)); pts=(d+1)/2; weights=V(1,idx).^2;
    keys=nan(64,6); values=cell(64,1); cursor=0;
end
key=[s(:);sd(:);sdd(:)].';
hit=find(all(keys==key,2),1);
if ~isempty(hit), a=values{hit}; return; end
l=s(2)-s(1); a.w=l*weights;
a.N=zeros(2,8,8); a.B=a.N; a.C=a.N; a.Nt=a.N;
a.M=zeros(8); a.A1=zeros(8); a.A2=zeros(8); a.G=zeros(8,1);
for j=1:8
    [N,B,C,Nt,Ntt]=aleancf.shape(pts(j),s,sd,sdd);
    a.N(:,:,j)=N; a.B(:,:,j)=B; a.C(:,:,j)=C; a.Nt(:,:,j)=Nt;
    a.M=a.M+a.w(j)*(N.'*N);
    a.A1=a.A1+a.w(j)*(N.'*(2*Nt));
    a.A2=a.A2+a.w(j)*(N.'*Ntt);
    a.G=a.G+a.w(j)*N.'*[0;1];
end
cursor=mod(cursor,64)+1; keys(cursor,:)=key; values{cursor}=a;
end
