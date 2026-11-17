function plot_model_limits()
% Reproducible report figures, generated only from completed validation data.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
src=fullfile(root,'report','model_limits');dst=fullfile(src,'figures');
if ~exist(dst,'dir'),mkdir(dst);end
C=[.13 .36 .63;.85 .43 .12;.48 .47 .17;.67 .31 .49]; styles={'-','--','-.',':'};
s=readtable(fullfile(src,'static.csv'));p=readtable(fullfile(src,'pendulum.csv'));a=readtable(fullfile(src,'ale.csv'));
f=newfig();tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile;plot(s.modes,s.deflection_m*1e3,'o-','Color',C(1,:));hold on;yline(s.exact_deflection_m(1)*1e3,'k--','解析解');xlabel('梁模态数');ylabel('端部挠度 (mm)');title('(a) 端部挠度');ylim([2.90 3.015]);
nexttile;semilogy(s.modes,100*s.deflection_relative_error,'o-','Color',C(1,:));hold on;semilogy(s.modes,100*s.rotation_relative_error,'s--','Color',C(2,:));xlabel('梁模态数');ylabel('相对解析误差 (%)');title('(b) 挠度与端部转角误差');legend('挠度','转角','Location','northeast');out(f,'01_static');
f=newfig();tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile;hold on;
for j=0:1,r=p(p.near_ideal==j,:);plot(r.elements,r.omega_rad_s,'o-','Color',C(j+1,:),'LineStyle',styles{j+1});end
yline(p.ideal_omega_rad_s(1),'k:','LineWidth',1.4);xlabel('ANCF 单元数');ylabel('角频率 (rad/s)');title('(a) 固定悬点、固定索长');legend('原始弹性索参数','近理想单摆参数','理想单摆解析值','Location','best');
nexttile;hold on;for j=0:1,r=p(p.near_ideal==j,:);plot(r.elements,100*r.relative_error,'o-','Color',C(j+1,:),'LineStyle',styles{j+1});end
xlabel('ANCF 单元数');ylabel('相对理想单摆的频率差异 (%)');title('(b) 频率差异');legend('原始弹性索参数','近理想单摆参数','Location','best');out(f,'02_pendulum');
f=newfig();bar([a.fixed_domain_force_N,a.moving_domain_force_N]*1e3,.5,'FaceColor',C(1,:));xticks(1:2);xticklabels({'固定材料域：L̇ = L̈ = 0','移动材料域对照'});ylabel('ALE 附加惯性项范数 (mN)');title('ALE 固定材料域极限检查');ylim([0 .0055]*1e3);text(1,.00015*1e3,'0 mN','HorizontalAlignment','center');text(2,a.moving_domain_force_N*1e3+.2,sprintf('%.4f mN',a.moving_domain_force_N*1e3),'HorizontalAlignment','center');out(f,'03_ale_limit');
meshes=[3 6 9 12];os={};ns=[];
for n=meshes
 file=fullfile(src,sprintf('mesh_%d.mat',n));if exist(file,'file'),x=load(file,'o');os{end+1}=x.o;ns(end+1)=n;end %#ok<AGROW>
end
assert(numel(ns)>=2);ref=os{end};labels=compose('%d 单元',ns); scope=sprintf('已完成网格：%s；差值参考 %d 单元',strjoin(string(ns),'/'),ns(end));
f=newfig();tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
for dim=1:2
 nexttile(dim);hold on;for j=1:numel(ns),o=os{j};plot(o.t,o.z(:,o.c.ip(dim)),styles{j},'Color',C(j,:));end
 xlabel('时间 (s)');if dim==1,ylabel('吊荷 X (m)');else,ylabel('吊荷 Y，向下为正 (m)');end;legend(labels,'Location','best');
 nexttile(dim+2);hold on;for j=1:numel(ns)-1,o=os{j};assert(isequal(o.t,ref.t));plot(o.t,1e6*(o.z(:,o.c.ip(dim))-ref.z(:,ref.c.ip(dim))),styles{j},'Color',C(j,:));end
 xlabel('时间 (s)');ylabel('相对最细网格的位置差 (μm)');legend(labels(1:end-1),'Location','best');
end
sgtitle(['吊荷轨迹网格对比 | ' scope],'Color','k','FontName','PingFang SC');out(f,'04_payload_mesh');
f=newfig();tiledlayout(2,1,'Padding','compact','TileSpacing','compact');
nexttile;hold on;for j=1:numel(ns),o=os{j};plot(o.t,o.endTension,styles{j},'Color',C(j,:));end
xlabel('时间 (s)');ylabel('下端轴向本构力 (N)');legend(labels,'Location','best');title('索端轴向力 EA(|r_s|−1)，不等同于总端部牵引力');
nexttile;hold on;for j=1:numel(ns)-1,o=os{j};plot(o.t,1e3*(o.endTension-ref.endTension),styles{j},'Color',C(j,:));end
xlabel('时间 (s)');ylabel('相对最细网格的力差 (mN)');legend(labels(1:end-1),'Location','best');sgtitle(['索端轴向力网格对比 | ' scope],'Color','k','FontName','PingFang SC');out(f,'05_tension_mesh');
rows=[];
for j=1:numel(ns)-1
 u=os{j};v=os{j+1};d=u.z(:,u.c.ip)-v.z(:,v.c.ip);df=max(abs(u.endTension-v.endTension));
 rows(end+1,:)=[ns(j),ns(j+1),max(vecnorm(d,2,2)),df,100*df/max(abs(v.endTension))]; %#ok<AGROW>
end
T=array2table(rows,'VariableNames',{'coarse','fine','payload_max_m','axial_force_max_N','axial_force_relative_pct'});writetable(T,fullfile(dst,'plotted_mesh_metrics.csv'));
f=newfig();tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile;semilogy(1:height(T),T.payload_max_m,'o-','Color',C(1,:));xlabel('相邻网格比较');ylabel('吊荷位置最大差 (m)');title('(a) 轨迹差异');
nexttile;semilogy(1:height(T),T.axial_force_relative_pct,'s--','Color',C(2,:));xlabel('相邻网格比较');ylabel('索端轴向力峰值归一化差异 (%)');title('(b) 轴向力差异');
ax=findall(f,'Type','axes');for k=1:numel(ax),xticks(ax(k),1:height(T));xticklabels(ax(k),compose('%d→%d',T.coarse,T.fine));xlim(ax(k),[.7 height(T)+.3]);end
sgtitle('相邻网格差异：接近数值精度时不要求误差严格单调','Color','k','FontName','PingFang SC');out(f,'06_mesh_differences');
fid=fopen(fullfile(dst,'figure_scope.txt'),'w');fprintf(fid,'%s\n仅使用已完成数据；不代表实验验证。近理想参数频率存在有限差分敏感性。\n',scope);fclose(fid);
 function f=newfig()
 f=figure('Visible','off','Color','w','Position',[80 80 1180 650]);
 end
 function out(f,name)
 axes=findall(f,'Type','axes');set(axes,'FontName','PingFang SC','FontSize',12,'LineWidth',.8,'Box','off','XGrid','on','YGrid','on','GridAlpha',.12);
 set(findall(f,'Type','text'),'FontName','PingFang SC');set(findall(f,'Type','legend'),'FontName','PingFang SC','FontSize',11,'Box','off');
 set(findall(f,'Type','line'),'LineWidth',1.5);
 continuum.light_figure(f);
 exportgraphics(f,fullfile(dst,[name '.png']),'Resolution',300);
 exportgraphics(f,fullfile(dst,[name '.pdf']),'ContentType','vector');
 savefig(f,fullfile(dst,[name '.fig']));close(f);
 end
end
