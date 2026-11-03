function summarize_continuum_sign_fix()
% Compare before/after runs without treating the former solution as truth.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
old=fullfile(root,'report','continuum','structure_validation');
folder=fullfile(root,'report','continuum','structure_validation_corrected');
rows=[];diagnostics=[];
for n=[4 6 8 12]
 a=load(fullfile(old,sprintf('modes_%d.mat',n)),'out');
 b=load(fullfile(folder,sprintf('modes_%d.mat',n)),'out');
 assert(isequaln(a.out.p,b.out.p),'Before/after inputs differ');
 rows(end+1,:)=[n a.out.topX(1) b.out.topX(1) ...
  max(abs(a.out.theta))*180/pi max(abs(b.out.theta))*180/pi ...
  max(abs(a.out.theta-b.out.theta))*180/pi max(abs(a.out.tipY-b.out.tipY))]; %#ok<AGROW>
 diagnostics(end+1,:)=[n b.out.t(end) max(b.out.constraint) max(b.out.velocityConstraint) ...
  max(b.out.residual) min(b.out.axialForceMin)]; %#ok<AGROW>
end
T=array2table(rows,'VariableNames',{'modes','old_tower_initial_m','corrected_tower_initial_m', ...
 'old_max_angle_deg','corrected_max_angle_deg','max_angle_change_deg','max_jib_tip_change_m'});
writetable(T,fullfile(folder,'before_after_comparison.csv'));
D=array2table(diagnostics,'VariableNames',{'modes','final_time_s','max_position_constraint_m', ...
 'max_velocity_constraint_m_s','max_dynamic_residual','min_sampled_axial_N'});
writetable(D,fullfile(folder,'dynamic_diagnostics.csv'));disp(T);disp(D);
assert(all(D.final_time_s==10) && all(D.max_dynamic_residual<1e-7));
end
