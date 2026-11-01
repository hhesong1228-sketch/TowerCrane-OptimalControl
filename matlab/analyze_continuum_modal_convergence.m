function result=analyze_continuum_modal_convergence()
% Compare 3/4 modes per beam with the same six-element cable and full input.
% Static references are exact within the implemented linear beam kinematics.
folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'report','continuum','modal_convergence_corrected');
if ~exist(folder,'dir'), mkdir(folder); end
diary(fullfile(folder,'run_log.txt')); cleanup=onCleanup(@()diary('off')); %#ok<NASGU>
p=continuum.parameters(); p.nElem=6; p.relTol=2e-8; p.absTol=1e-10;
p.maxStep=0.01; p.nOutput=2001;
fprintf('Modal study: 0-%g s, 6 rope elements, RelTol %.1e, AbsTol %.1e\n',p.tEnd,p.relTol,p.absTol);
stat=[]; rotationStats=[];
for n=1:4
 p.nTower=n; p.nJib=n; c=continuum.setup(p);
 [top,tip]=static_values(p.x0,p.L0,p,c);
 [te,je]=exact_static(p.x0,p.L0,p);
 % Independent exact modal stiffness: tip-normalized cantilever modal mass = mu*H/4.
 roots=[1.875104068711961 4.694091132974174 7.854757438237612 10.99554073487547];
 moment=p.muJib*p.g*p.B^2/2+(p.mT+p.mP+p.rhoA*p.L0)*p.g*p.x0;
 stiffness=p.EITower*roots(1:n).^4/(4*p.H^3);
 slope=moment*sum(c.slope.^2./stiffness); exactSlope=moment*p.H/p.EITower;
 rotationStats(end+1,:)=[n slope exactSlope p.B*slope p.B*exactSlope p.B*(exactSlope-slope)*1000]; %#ok<AGROW>
 stat(end+1,:)=[n top te top-te abs((top-te)/te)*100 tip je tip-je abs((tip-je)/je)*100]; %#ok<AGROW>
end
staticTable=array2table(stat,'VariableNames',{'modes','tower_m','tower_exact_m','tower_error_m','tower_error_pct','jib_m','jib_exact_m','jib_error_m','jib_error_pct'});
writetable(staticTable,fullfile(folder,'static_convergence.csv')); disp(staticTable);
rotationTable=array2table(rotationStats,'VariableNames',{'modes','tower_slope_rad','exact_slope_rad','jib_tip_from_rotation_m','exact_jib_tip_from_rotation_m','rotation_contribution_error_mm'});
writetable(rotationTable,fullfile(folder,'static_rotation.csv'));
outs=cell(2,1);
for j=1:2
 n=j+2; p.nTower=n; p.nJib=n;
 fprintf('Running %d modes per beam...\n',n); tic;
 out=continuum.simulate(p); elapsed=toc;
 for k=1:numel(out.t)
  x=out.z(k,out.c.ix);
  [out.staticTop(k,1),out.staticTip(k,1)]=static_values(x,out.L(k),p,out.c);
  [out.exactStaticTop(k,1),out.exactStaticTip(k,1)]=exact_static(x,out.L(k),p);
 end
 out.vibTop=out.topX-out.staticTop; out.vibTip=out.tipY-out.staticTip;
 save(fullfile(folder,sprintf('modes_%d.mat',n)),'out'); outs{j}=out;
 fprintf('Completed %d modes in %.1f s; constraint %.3e m, min axial %.5f N\n',n,elapsed,max(out.constraint),min(out.axialForceMin));
end
a=outs{1}; b=outs{2};
labels={'tower_total','jib_total','tower_change_from_initial','jib_change_from_initial','tower_vibration_about_static','jib_vibration_about_static','payload_angle','support_force_x','support_force_y','trolley_drive'};
units={'m','m','m','m','m','m','rad','N','N','N'};
A=[a.topX a.tipY a.topX-a.topX(1) a.tipY-a.tipY(1) a.vibTop a.vibTip a.theta a.lambda(:,1:2) -a.lambda(:,5)];
B=[b.topX b.tipY b.topX-b.topX(1) b.tipY-b.tipY(1) b.vibTop b.vibTip b.theta b.lambda(:,1:2) -b.lambda(:,5)];
D=A-B; peak=max(abs(D),[],1).'; rms=sqrt(mean(D.^2,1)).'; ref=max(abs(B),[],1).';
relPeak=100*peak./max(ref,1e-12); relL2=100*sqrt(sum(D.^2,1)./max(sum(B.^2,1),1e-24)).';
metrics=table(labels.',units.',peak,rms,ref,relPeak,relL2, ...
 'VariableNames',{'quantity','unit','max_abs_difference','rms_difference','four_mode_peak_abs','peak_relative_pct','L2_relative_pct'});
writetable(metrics,fullfile(folder,'dynamic_comparison.csv')); disp(metrics);
% Residual swing after trolley and hoisting have both stopped (8-10 s).
idx=a.t>=8; residual=[max(abs(A(idx,:)),[],1).' max(abs(B(idx,:)),[],1).' max(abs(D(idx,:)),[],1).'];
residualTable=table(labels.',units.',residual(:,1),residual(:,2),residual(:,3), ...
 'VariableNames',{'quantity','unit','three_mode_peak_abs','four_mode_peak_abs','max_abs_difference'});
writetable(residualTable,fullfile(folder,'residual_8_to_10s.csv'));
result.parameters=p; result.metrics=metrics; result.static=staticTable; result.residual=residualTable;
save(fullfile(folder,'comparison.mat'),'result');
f=figure('Visible','off','Color','w','Position',[100 100 1250 950]); tiledlayout(3,2);
fields={'topX','tipY','vibTop','vibTip','theta'};
ylabels={'Tower top total (mm)','Jib tip total (mm)','Tower vibration about static (mm)','Jib vibration about static (mm)','Payload chord angle (deg)'};
scales=[1000 1000 1000 1000 180/pi];
for j=1:5
 nexttile; plot(a.t,scales(j)*a.(fields{j}),'b-',b.t,scales(j)*b.(fields{j}),'r--'); grid on;
 xlabel('Time (s)');ylabel(ylabels{j});legend('3 modes / beam','4 modes / beam','Location','best');
end
nexttile;plot(a.t,a.lambda(:,2),'b-',b.t,b.lambda(:,2),'r--');grid on;xlabel('Time (s)');ylabel('Vertical suspension force (N)');
exportgraphics(f,fullfile(folder,'response_comparison.png'),'Resolution',150);close(f);
f=figure('Visible','off','Color','w','Position',[100 100 1100 850]);tiledlayout(3,2);
for j=1:5
 nexttile;plot(a.t,scales(j)*(a.(fields{j})-b.(fields{j})));grid on;xlabel('Time (s)');shortLabels={'Tower total diff. (mm)','Jib total diff. (mm)','Tower vibration diff. (mm)','Jib vibration diff. (mm)','Chord angle diff. (deg)'};ylabel(shortLabels{j});
end
nexttile;plot(a.t,a.lambda(:,2)-b.lambda(:,2));grid on;xlabel('Time (s)');ylabel('Force difference (N)');
exportgraphics(f,fullfile(folder,'response_differences.png'),'Resolution',150);close(f);
fprintf('Study complete. Finite 3/4 comparison does not prove asymptotic convergence.\n');
end
function [top,tip]=static_values(x,L,p,c)
q=zeros(c.n,1); v=q; q(c.ix)=x; [~,J]=continuum.point(q,v,p,c);
i=1:c.ns-1; weight=(p.mT+p.mP+p.rhoA*L)*p.g;
q(i)=c.K(i,i)\(c.Fg(i)+weight*J(2,i).');
top=c.top*q(c.it);
tip=p.B*c.slope*q(c.it)+continuum.modes(p.B,p.B,c.nj)*q(c.ij);
end
function [top,tip]=exact_static(x,L,p)
weight=(p.mT+p.mP+p.rhoA*L)*p.g;
moment=p.muJib*p.g*p.B^2/2+weight*x;
top=moment*p.H^2/(2*p.EITower);
tip=p.B*moment*p.H/p.EITower+p.muJib*p.g*p.B^4/(8*p.EIJib) ...
 +weight*x^2*(3*p.B-x)/(6*p.EIJib);
end
