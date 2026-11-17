function result=compare_rigid_flexible(reuseResults)
% Same cable, motion, loads and solver; zero beam coordinates = rigid frame.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
folder=fullfile(root,'report','rigid_flexible');
if ~exist(folder,'dir'), mkdir(folder); end
if nargin<1, reuseResults=false; end
p=continuum.parameters();
% Use current default model as the baseline, without changing the scenario.
if reuseResults
 load(fullfile(folder,'flexible.mat'),'a');
 load(fullfile(folder,'rigid.mat'),'b');
else
a=continuum.simulate(p); save(fullfile(folder,'flexible.mat'),'a');
p.nTower=0; p.nJib=0;
b=continuum.simulate(p); save(fullfile(folder,'rigid.mat'),'b');
end
assert(isequal(a.t,b.t));
A=[a.z(:,a.c.ip) a.theta a.suspension a.lambda(:,1:2) -a.lambda(:,5)];
B=[b.z(:,b.c.ip) b.theta b.suspension b.lambda(:,1:2) -b.lambda(:,5)];
names={'payload_x','payload_y_down','swing','suspension_x','suspension_y_down','suspension_force_x','suspension_force_y','drive_force'}';
units={'m','m','rad','m','m','N','N','N'}';
D=A-B;
metrics=table(names,units,max(abs(A),[],1)',max(abs(B),[],1)',max(abs(D),[],1)',sqrt(mean(D.^2,1))', ...
 'VariableNames',{'quantity','unit','flexible_peak_abs','rigid_peak_abs','max_abs_difference','rms_difference'});
writetable(metrics,fullfile(folder,'metrics.csv')); disp(metrics);
headers={'time_s'}; data=a.t;
for j=1:numel(names)
 headers=[headers {[names{j} '_flexible'],[names{j} '_rigid'],[names{j} '_difference']}]; %#ok<AGROW>
 data=[data A(:,j) B(:,j) D(:,j)]; %#ok<AGROW>
end
writetable(array2table(data,'VariableNames',headers),fullfile(folder,'timeseries.csv'));
checks=table([max(a.constraint);max(b.constraint)],[max(a.residual);max(b.residual)], ...
 [min(a.axialForceMin);min(b.axialForceMin)],'RowNames',{'flexible','rigid'}, ...
 'VariableNames',{'max_constraint_m','max_equation_residual','min_cable_axial_force_N'});
writetable(checks,fullfile(folder,'checks.csv'),'WriteRowNames',true); disp(checks);
% Remove the initial static offset to distinguish motion error from predeflection.
result.metrics=metrics; result.checks=checks;
result.initial_payload_offset=A(1,1:2)-B(1,1:2);
result.peak_payload_motion_difference=max(abs((A(:,1:2)-A(1,1:2))-(B(:,1:2)-B(1,1:2))),[],1);
result.residual_swing_deg=[max(abs(a.theta(a.t>=8))) max(abs(b.theta(b.t>=8)))]*180/pi;
save(fullfile(folder,'summary.mat'),'result'); disp(result);
f=figure('Visible','off','Color','w','Position',[50 50 1250 1000]); tiledlayout(3,2);
cols=[1 2 3 4 5 7]; scales=[1000 1000 180/pi 1000 1000 1];
labels={'Payload X (mm)','Payload Y down (mm)','Cable chord angle (deg)','Suspension X (mm)','Suspension Y down (mm)','Vertical suspension force (N)'};
for k=1:6
 nexttile; j=cols(k); plot(a.t,A(:,j)*scales(k),'b-',b.t,B(:,j)*scales(k),'r--','LineWidth',1.2);
 grid on; xlabel('Time (s)'); ylabel(labels{k}); legend('Flexible beams','Rigid beams','Location','best');
end
continuum.light_figure(f); exportgraphics(f,fullfile(folder,'comparison.png'),'Resolution',160); close(f);
f=figure('Visible','off','Color','w','Position',[50 50 1200 850]); tiledlayout(2,2);
nexttile; plot(a.t,1000*D(:,1:2),'LineWidth',1.2); ylabel('Absolute payload error (mm)'); legend('X','Y down'); grid on; xlabel('Time (s)');
nexttile; plot(a.t,1000*((A(:,1:2)-A(1,1:2))-(B(:,1:2)-B(1,1:2))),'LineWidth',1.2); ylabel('Payload motion error from initial (mm)'); legend('X','Y down'); grid on; xlabel('Time (s)');
nexttile; plot(a.t,D(:,3)*180/pi,'LineWidth',1.2); ylabel('Chord angle difference (deg)'); grid on; xlabel('Time (s)');
nexttile; plot(a.t,D(:,6:7),'LineWidth',1.2); ylabel('Suspension force difference (N)'); legend('X','Y'); grid on; xlabel('Time (s)');
continuum.light_figure(f); exportgraphics(f,fullfile(folder,'differences.png'),'Resolution',160); close(f);
end
