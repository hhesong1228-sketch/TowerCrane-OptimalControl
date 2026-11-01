function audit_continuum_connection()
% Independent geometric audit of the claimed rigid mast/jib connection.
% X right, Y down, z upward: mast tangent [w_T'(H);-1].
% A rigid orthogonal jib must have slope +w_T'(H), to first order.
folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'report','continuum','structure_validation_corrected');
if ~exist(folder,'dir'),mkdir(folder);end
p=continuum.parameters();p.theta0=0; rows=[];
for n=[2 4 8 12 16]
 p.nTower=n;p.nJib=n;c=continuum.setup(p);z=continuum.initial_state(p,c);q=z(1:c.n);
 slope=c.slope*q(c.it);h=1e-5;qp=q;qm=q;qp(c.ix)=h;qm(c.ix)=-h;
 rp=continuum.point(qp,zeros(c.n,1),p,c);rm=continuum.point(qm,zeros(c.n,1),p,c);
 tangent=(rp-rm)/(2*h);mast=[slope;-1];dotnorm=dot(mast,tangent)/norm(mast)/norm(tangent);
 P=(p.mT+p.mP+p.rhoA*p.L0)*p.g;M=p.muJib*p.g*p.B^2/2+P*p.x0;
 physicalTop=M*p.H^2/(2*p.EITower);numTop=c.top*q(c.it);
 rows(end+1,:)=[n numTop physicalTop 100*abs(numTop-physicalTop)/abs(physicalTop) ...
 slope tangent(2)/tangent(1) dotnorm abs(acos(max(-1,min(1,dotnorm)))-pi/2)*180/pi]; %#ok<AGROW>
end
T=array2table(rows,'VariableNames',{'modes','computed_tower_x_m','physical_tower_x_m','signed_static_error_pct', ...
 'mast_slope','computed_jib_root_slope','normalized_tangent_dot','angle_deviation_deg'});
writetable(T,fullfile(folder,'connection_sign_audit.csv'));disp(T);
assert(max(abs(T.normalized_tangent_dot))<1e-8,'Rigid connection directions');
assert(all(T.computed_tower_x_m>0),'Static deflection direction');
fprintf('PASS physical rigid-joint sign and independently differentiated root tangent.\n');
end
