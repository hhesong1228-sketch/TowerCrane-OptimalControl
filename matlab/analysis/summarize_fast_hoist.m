function summarize_fast_hoist()
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); folder=fullfile(root,'report','fast_hoist');
paths={fullfile(root,'report','singlepend_aleancf','comparison.mat'), ...
 fullfile(folder,'duration_1.5','comparison.mat'),fullfile(folder,'duration_0.75','comparison.mat')};
rows=[]; aa=cell(3,1); bb=aa;
for k=1:3
 s=load(paths{k}); a=s.a; b=s.b; aa{k}=a; bb{k}=b;
 dy=a.z(:,a.c.ip(2))-b.payload(:,2); dx=a.z(:,a.c.ip(1))-b.payload(:,1);
 df=a.lambda(:,2)-b.force(:,2); da=(a.theta-b.theta)*180/pi;
 chord=vecnorm(a.z(:,a.c.ip)-a.suspension,2,2); a.extension=chord-a.L;
 a.nodeOffset=zeros(size(a.t));
 for i=1:numel(a.t)
  d=a.z(i,a.c.ip)-a.suspension(i,:); normal=[d(2);-d(1)]/norm(d);
  for e=1:a.p.nElem
   idx=a.c.ie(4*(e-1)+(1:8));
   N=aleancf.shape(.5,a.L(i)*[-1+(e-1)/a.p.nElem,-1+e/a.p.nElem],[0 0],[0 0]);
   pos=(N*a.z(i,idx).').';
   a.nodeOffset(i)=max(a.nodeOffset(i),abs((pos-a.suspension(i,:))*normal));
  end
 end
 aa{k}=a;
 duration=a.p.hoistDuration;
 rows(k,:)=[duration 1.875*.6/duration (10/sqrt(3))*.6/duration^2 ...
 max(abs(dx))*1000 max(abs(dy))*1000 max(abs(dy-dy(1)))*1000 max(abs(da)) ...
 max(abs(df)) 100*max(abs(df))/max(abs(a.lambda(:,2))) min(a.axialForceMin) ...
 max(a.extension)*1000 max(a.nodeOffset)*1000 max(a.constraint) max(b.constraint) ...
 max(abs(df(a.t>=5.5)))]; %#ok<AGROW>
end
names={'duration_s','peak_speed_m_s','peak_acceleration_m_s2','max_x_difference_mm','max_y_difference_mm', ...
 'max_y_motion_difference_mm','max_angle_difference_deg','max_vertical_force_difference_N', ...
 'force_difference_pct_ALE_peak','min_ALE_axial_force_N','max_chord_extension_mm','max_sampled_transverse_offset_mm','ALE_constraint_m','single_constraint_m','post_stop_force_difference_N'};
summary=array2table(rows,'VariableNames',names); writetable(summary,fullfile(folder,'summary.csv')); disp(summary);
f=figure('Visible','off','Position',[50 50 1250 1000]); tiledlayout(3,2); labels={'6 s','1.5 s','0.75 s'}; colors=[.1 .35 .75;.85 .3 .1;.2 .5 .25];
for j=1:6
 nexttile; hold on;
 for k=1:3
  a=aa{k}; b=bb{k};
  switch j
   case 1, y=a.L; yl='Deployed length (m)';
   case 2, y=a.lambda(:,2); yl='ALE vertical support force (N)';
   case 3, y=(a.z(:,a.c.ip(2))-b.payload(:,2))*1000; yl='Payload Y difference (mm)';
   case 4, y=(a.theta-b.theta)*180/pi; yl='Chord angle difference (deg)';
   case 5, y=a.extension*1000; yl='ALE chord length minus L (mm)';
   case 6, y=a.lambda(:,2)-b.force(:,2); yl='Vertical support force difference (N)';
  end
  plot(a.t,y,'Color',colors(k,:),'LineWidth',1.1);
 end
 grid on; xlabel('Time (s)'); ylabel(yl); legend(labels,'Location','best');
end
continuum.light_figure(f); exportgraphics(f,fullfile(folder,'speed_comparison.png'),'Resolution',160); close(f);
save(fullfile(folder,'summary.mat'),'summary');
refined=fullfile(folder,'refined_0.75.mat');
if exist(refined,'file')
 s=load(refined,'out'); r=s.out; a=aa{3}; b=bb{3};
 A=[a.z(:,a.c.ip) a.theta a.topX a.tipY a.lambda(:,1:2)];
 R=[r.z(:,r.c.ip) r.theta r.topX r.tipY r.lambda(:,1:2)];
 B=[b.payload b.theta b.topX b.tipY b.force];
 quantity={'payload_x','payload_y','angle','tower_top','jib_tip','force_x','force_y'}';
 refinement=table(quantity,max(abs(A-R))',max(abs(A-B))',max(abs(R-B))', ...
 'VariableNames',{'quantity','coarse_refined_max_difference','coarse_single_max_difference','refined_single_max_difference'});
 writetable(refinement,fullfile(folder,'refinement.csv')); disp(refinement);
 f=figure('Visible','off','Position',[50 50 1150 850]); tiledlayout(2,2);
 for j=1:4
  nexttile;
  switch j
   case 1, yy=[A(:,7) R(:,7) B(:,7)]; yl='Vertical support force (N)';
   case 2, yy=[A(:,2) R(:,2) B(:,2)]*1000; yl='Payload Y down (mm)';
   case 3, yy=[A(:,3) R(:,3) B(:,3)]*180/pi; yl='Chord angle (deg)';
   case 4, yy=[A(:,5) R(:,5) B(:,5)]*1000; yl='Jib tip down (mm)';
  end
  plot(a.t,yy,'LineWidth',1.1); grid on; xlim([2 4]); xlabel('Time (s)'); ylabel(yl);
  legend('ALE 3 elements','ALE 6 elements, tighter solver','Single pendulum','Location','best');
 end
 continuum.light_figure(f); exportgraphics(f,fullfile(folder,'fast_refined_comparison.png'),'Resolution',160); close(f);
end
end
