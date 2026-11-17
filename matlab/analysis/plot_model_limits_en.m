function plot_model_limits_en()
% Reproducible report figures, generated only from completed validation data.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
src=fullfile(root,'report','model_limits');dst=fullfile(src,'figures_en');
if ~exist(dst,'dir'),mkdir(dst);end
C=[.13 .36 .63;.85 .43 .12;.48 .47 .17;.67 .31 .49]; styles={'-','--','-.',':'};
s=readtable(fullfile(src,'static.csv'));p=readtable(fullfile(src,'pendulum.csv'));a=readtable(fullfile(src,'ale.csv'));
f=newfig();tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile;plot(s.modes,s.deflection_m*1e3,'o-','Color',C(1,:));hold on;yline(s.exact_deflection_m(1)*1e3,'k--','Analytical solution');xlabel('Number of beam modes');ylabel('Tip deflection (mm)');title('(a) Tip deflection');ylim([2.90 3.015]);
nexttile;semilogy(s.modes,100*s.deflection_relative_error,'o-','Color',C(1,:));hold on;semilogy(s.modes,100*s.rotation_relative_error,'s--','Color',C(2,:));xlabel('Number of beam modes');ylabel('Relative analytical error (%)');title('(b) Deflection and rotation errors');legend('Deflection','Rotation','Location','northeast');out(f,'01_static');
f=newfig();tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile;hold on;
for j=0:1,r=p(p.near_ideal==j,:);plot(r.elements,r.omega_rad_s,'o-','Color',C(j+1,:),'LineStyle',styles{j+1});end
yline(p.ideal_omega_rad_s(1),'k:','LineWidth',1.4);xlabel('Number of ANCF elements');ylabel('Angular frequency (rad/s)');title('(a) Fixed suspension and cable length');legend('Original cable parameters','Near-ideal pendulum parameters','Ideal pendulum','Location','best');
nexttile;hold on;for j=0:1,r=p(p.near_ideal==j,:);plot(r.elements,100*r.relative_error,'o-','Color',C(j+1,:),'LineStyle',styles{j+1});end
xlabel('Number of ANCF elements');ylabel('Frequency difference from ideal pendulum (%)');title('(b) Frequency difference');legend('Original cable parameters','Near-ideal pendulum parameters','Location','best');out(f,'02_pendulum');
f=newfig();bar([a.fixed_domain_force_N,a.moving_domain_force_N]*1e3,.5,'FaceColor',C(1,:));xticks(1:2);xticklabels({'Fixed domain: zero length rate/acceleration','Moving-domain control'});ylabel('ALE inertial force norm (mN)');title('ALE fixed-domain limit check');ylim([0 .0055]*1e3);text(1,.00015*1e3,'0 mN','HorizontalAlignment','center');text(2,a.moving_domain_force_N*1e3+.2,sprintf('%.4f mN',a.moving_domain_force_N*1e3),'HorizontalAlignment','center');out(f,'03_ale_limit');
meshes=[3 6 9 12];os={};ns=[];
for n=meshes
 file=fullfile(src,sprintf('mesh_%d.mat',n));if exist(file,'file'),x=load(file,'o');os{end+1}=x.o;ns(end+1)=n;end %#ok<AGROW>
end
assert(numel(ns)>=2);ref=os{end};labels=compose('%d elements',ns); scope=sprintf('Meshes: %s; reference: %d elements',strjoin(string(ns),'/'),ns(end));
f=newfig();tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
for dim=1:2
 nexttile(dim);hold on;for j=1:numel(ns),o=os{j};plot(o.t,o.z(:,o.c.ip(dim)),styles{j},'Color',C(j,:));end
 xlabel('Time (s)');if dim==1,ylabel('Payload X (m)');else,ylabel('Payload Y, positive downward (m)');end;legend(labels,'Location','best');
 nexttile(dim+2);hold on;for j=1:numel(ns)-1,o=os{j};assert(isequal(o.t,ref.t));plot(o.t,1e6*(o.z(:,o.c.ip(dim))-ref.z(:,ref.c.ip(dim))),styles{j},'Color',C(j,:));end
 xlabel('Time (s)');ylabel('Position difference from finest mesh (μm)');legend(labels(1:end-1),'Location','best');
end
sgtitle(['Payload trajectory | ' scope],'Color','k','FontName','Arial');out(f,'04_payload_mesh');
f=newfig();tiledlayout(2,1,'Padding','compact','TileSpacing','compact');
nexttile;hold on;for j=1:numel(ns),o=os{j};plot(o.t,o.endTension,styles{j},'Color',C(j,:));end
xlabel('Time (s)');ylabel('Lower-end constitutive axial force (N)');legend(labels,'Location','best');title('Constitutive axial force EA(|r_s| - 1); distinct from total end traction');
nexttile;hold on;for j=1:numel(ns)-1,o=os{j};plot(o.t,1e3*(o.endTension-ref.endTension),styles{j},'Color',C(j,:));end
xlabel('Time (s)');ylabel('Force difference from finest mesh (mN)');legend(labels(1:end-1),'Location','best');sgtitle(['Cable axial force | ' scope],'Color','k','FontName','Arial');out(f,'05_tension_mesh');
rows=[];
for j=1:numel(ns)-1
 u=os{j};v=os{j+1};d=u.z(:,u.c.ip)-v.z(:,v.c.ip);df=max(abs(u.endTension-v.endTension));
 rows(end+1,:)=[ns(j),ns(j+1),max(vecnorm(d,2,2)),df,100*df/max(abs(v.endTension))]; %#ok<AGROW>
end
T=array2table(rows,'VariableNames',{'coarse','fine','payload_max_m','axial_force_max_N','axial_force_relative_pct'});writetable(T,fullfile(dst,'plotted_mesh_metrics.csv'));
f=newfig();tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile;semilogy(1:height(T),T.payload_max_m,'o-','Color',C(1,:));xlabel('Adjacent mesh comparison');ylabel('Maximum payload position difference (m)');title('(a) Payload trajectory difference');
nexttile;semilogy(1:height(T),T.axial_force_relative_pct,'s--','Color',C(2,:));xlabel('Adjacent mesh comparison');ylabel('Peak-normalized axial force difference (%)');title('(b) Axial force difference');
ax=findall(f,'Type','axes');for k=1:numel(ax),xticks(ax(k),1:height(T));xticklabels(ax(k),compose('%d→%d',T.coarse,T.fine));xlim(ax(k),[.7 height(T)+.3]);end
sgtitle('Adjacent mesh differences','Color','k','FontName','Arial');out(f,'06_mesh_differences');
fid=fopen(fullfile(dst,'figure_scope.txt'),'w');fprintf(fid,'%s\nCompleted simulations only; not experimental validation. Near-ideal frequencies are sensitive to finite-difference linearization.\n',scope);fclose(fid);
 function f=newfig()
 f=figure('Visible','off','Color','w','Position',[80 80 1180 650]);
 end
 function out(f,name)
 axes=findall(f,'Type','axes');set(axes,'FontName','Arial','FontSize',12,'LineWidth',.8,'Box','off','XGrid','on','YGrid','on','GridAlpha',.12);
 set(findall(f,'Type','text'),'FontName','Arial');set(findall(f,'Type','legend'),'FontName','Arial','FontSize',11,'Box','off');
 set(findall(f,'Type','line'),'LineWidth',1.5);
 continuum.light_figure(f);
 exportgraphics(f,fullfile(dst,[name '.png']),'Resolution',300);
 exportgraphics(f,fullfile(dst,[name '.pdf']),'ContentType','vector');
 savefig(f,fullfile(dst,[name '.fig']));
 exportgraphics(f,fullfile(dst,'Model_Validation_Figures_EN.pdf'),'ContentType','vector','Append',~strcmp(name,'01_static'));close(f);
 end
end
