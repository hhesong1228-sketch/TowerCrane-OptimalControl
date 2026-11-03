function result=validate_continuum_structure()
% Independent closed-form statics and fixed-cable structural modal refinement.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
folder=fullfile(root,'report','continuum','structure_validation_corrected');
if ~exist(folder,'dir'),mkdir(folder);end
diary(fullfile(folder,'run_log.txt')); finish=onCleanup(@()diary('off')); %#ok<NASGU>
p=continuum.parameters(); p.nElem=6; p.relTol=2e-8;p.absTol=1e-10;p.maxStep=.01;p.nOutput=2001;
% Check stable implementation against the original direct formula at low order.
z=linspace(0,p.H,301)'; [P,D,DD]=continuum.modes(z,p.H,4);
beta=[1.875104068711961 4.694091132974174 7.854757438237612 10.99554073487547];
err=0;
for k=1:4
 b=beta(k);s=(cosh(b)+cos(b))/(sinh(b)+sin(b));r=b*z/p.H;
 tip=cosh(b)-cos(b)-s*(sinh(b)-sin(b));
 old=[(cosh(r)-cos(r)-s*(sinh(r)-sin(r)))/tip, ...
 b/p.H*(sinh(r)+sin(r)-s*(cosh(r)-cos(r)))/tip, ...
 (b/p.H)^2*(cosh(r)+cos(r)-s*(sinh(r)+sin(r)))/tip];
 err=max(err,max(abs(old-[P(:,k) D(:,k) DD(:,k)]),[],'all'));
end
assert(err<1e-9);fprintf('Stable basis versus old 1-4 modes: %.3e\n',err);
% Independent physical cantilever closed forms, positive tower tip displacement.
rows=[];
for scenario=1:2
 if scenario==1,x=p.x0;L=p.L0;else,x=p.x1;L=p.L1;end
 zz=linspace(0,p.H,501)';xx=linspace(0,p.B,501)';
 W=(p.mT+p.mP+p.rhoA*L)*p.g; w=p.muJib*p.g;
 M=w*p.B^2/2+W*x;
 towerExact=M*zz.^2/(2*p.EITower); slopeExact=M*p.H/p.EITower;
 % Cantilever Green function under downward point load at x.
 point=zeros(size(xx));left=xx<=x;
 point(left)=W*xx(left).^2.*(3*x-xx(left))/(6*p.EIJib);
 point(~left)=W*x^2*(3*xx(~left)-x)/(6*p.EIJib);
 relExact=w*xx.^2.*(6*p.B^2-4*p.B*xx+xx.^2)/(24*p.EIJib)+point;
 jibExact=xx*slopeExact+relExact;
 for n=[1 2 3 4 6 8 12 16]
  p.nTower=n;p.nJib=n;c=continuum.setup(p);
  [q,top,tip,slope]=statics(x,L,p,c);
  tw=continuum.modes(zz,p.H,n)*q(c.it);
  rel=continuum.modes(xx,p.B,n)*q(c.ij);jw=xx*slope+rel;
  rows(end+1,:)=[scenario n top towerExact(end) 100*abs(top/towerExact(end)-1) ...
   slope slopeExact 100*abs(slope/slopeExact-1) tip jibExact(end) 100*abs(tip/jibExact(end)-1) ...
   max(abs(tw-towerExact)) max(abs(jw-jibExact)) max(abs(rel-relExact))]; %#ok<AGROW>
  if n==16
   fields=table(zz,towerExact,tw,xx,jibExact,jw,relExact,rel);
   writetable(fields,fullfile(folder,sprintf('static_fields_case%d.csv',scenario)));
  end
 end
end
static=array2table(rows,'VariableNames',{'case_id','modes','tower_m','tower_exact_m','tower_error_pct', ...
 'rotation_rad','rotation_exact_rad','rotation_error_pct','jib_m','jib_exact_m','jib_error_pct', ...
 'tower_field_max_error_m','jib_field_max_error_m','jib_relative_field_max_error_m'});
writetable(static,fullfile(folder,'static_validation.csv'));disp(static);
% Model-to-model convergence criteria specified independently of results:
% total displacements: 1% peak-norm; vibration: 5% peak-norm;
% swing: 1% peak-norm; reactions/drive: 1% peak-norm.
signature='';
for name={'point','setup','assemble','modes','rhs','simulate','initial_state'}
 signature=[signature fileread(fullfile(root,'matlab','+continuum',[name{1} '.m']))]; %#ok<AGROW>
end
orders=[4 6 8 12]; outs=cell(size(orders));
for j=1:numel(orders)
 n=orders(j);p.nTower=n;p.nJib=n;
 file=fullfile(folder,sprintf('modes_%d.mat',n));
 if exist(file,'file')
  cached=load(file,'out','signature');assert(isfield(cached,'signature') && strcmp(cached.signature,signature),'Cached source mismatch');assert(isequaln(cached.out.p,p),'Cached parameters mismatch');out=cached.out;
 else
  fprintf('Running %d modes per beam, 0-10 s...\n',n);tic;out=continuum.simulate(p);
  fprintf('Completed in %.1f s\n',toc);save(file,'out','signature');
 end
 assert(max(out.constraint)<1e-7 && max(out.velocityConstraint)<1e-6 && min(out.axialForceMin)>0);
 for k=1:numel(out.t)
  [~,out.staticTop(k,1),out.staticTip(k,1)]=statics(out.z(k,out.c.ix),out.L(k),p,out.c);
 end
 out.vibTop=out.topX-out.staticTop;out.vibTip=out.tipY-out.staticTip;
 outs{j}=out;
end
names={'tower_total','jib_total','tower_vibration','jib_vibration','payload_angle','support_x','support_y','trolley_drive'};
limits=[1 1 5 5 1 1 1 1]; rows=[]; labels={};
for j=1:numel(orders)-1
 a=signals(outs{j});b=signals(outs{j+1});d=a-b;
 for k=1:8
  pk=max(abs(d(:,k)));ref=max(abs(b(:,k)));pct=100*pk/max(ref,1e-12);
  tail=outs{j}.t>=8;
  rows(end+1,:)=[orders(j) orders(j+1) pk ref pct 100*norm(d(:,k))/max(norm(b(:,k)),1e-12) ...
   max(abs(d(tail,k))) limits(k) pct<=limits(k)];labels{end+1,1}=names{k}; %#ok<AGROW>
 end
end
dynamic=array2table(rows,'VariableNames',{'coarse_modes','fine_modes','max_abs_diff','reference_peak', ...
 'peak_relative_pct','L2_relative_pct','residual_max_abs_diff','tolerance_pct','pass'});
dynamic.quantity=labels;dynamic=movevars(dynamic,'quantity','Before',1);
writetable(dynamic,fullfile(folder,'dynamic_validation.csv'));disp(dynamic);
result.static=static;result.dynamic=dynamic;result.orders=orders;result.parameters=p;
save(fullfile(folder,'validation.mat'),'result');
f=figure('Visible','off','Color','w','Position',[100 100 1200 800]);tiledlayout(2,2);
nexttile; hold on;for j=1:numel(outs),plot(outs{j}.t,1000*outs{j}.tipY);end;grid on;xlabel('Time (s)');ylabel('Jib total (mm)');legend(string(orders)+' modes');
nexttile;hold on;for j=1:numel(outs),plot(outs{j}.t,1000*outs{j}.vibTip);end;grid on;xlabel('Time (s)');ylabel('Jib vibration (mm)');
nexttile;hold on;for j=1:numel(outs),plot(outs{j}.t,outs{j}.theta*180/pi);end;grid on;xlabel('Time (s)');ylabel('Payload angle (deg)');
nexttile;sel=static.case_id==1;loglog(static.modes(sel),static.jib_error_pct(sel),'o-',static.modes(sel),static.rotation_error_pct(sel),'s-',static.modes(sel),static.tower_error_pct(sel),'^-');grid on;xlabel('Modes per beam');ylabel('Exact-static error (%)');legend('Jib tip','Tower rotation','Tower top');
continuum.light_figure(f);
exportgraphics(f,fullfile(folder,'convergence.png'),'Resolution',160);close(f);
fprintf('Completed. Report failed criteria explicitly; refinement is not exact truth.\n');
end
function [q,top,tip,slope]=statics(x,L,p,c)
q=zeros(c.n,1);q(c.ix)=x;[~,J]=continuum.point(q,zeros(c.n,1),p,c);
i=1:c.ns-1;q(i)=c.K(i,i)\(c.Fg(i)+(p.mT+p.mP+p.rhoA*L)*p.g*J(2,i).');
top=c.top*q(c.it);slope=c.slope*q(c.it);
tip=p.B*slope+continuum.modes(p.B,p.B,c.nj)*q(c.ij);
end
function a=signals(o)
a=[o.topX o.tipY o.vibTop o.vibTip o.theta o.lambda(:,1:2) -o.lambda(:,5)];
end
