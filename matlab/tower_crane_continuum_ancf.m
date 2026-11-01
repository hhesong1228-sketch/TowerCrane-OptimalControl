function out=tower_crane_continuum_ancf()
% Continuous tower/jib assumed modes + ALE-ANCF cable + constrained payload.
p=continuum.parameters(); out=continuum.simulate(p);
folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'report','continuum');
if ~exist(folder,'dir'), mkdir(folder); end
save(fullfile(folder,'simulation.mat'),'out'); continuum.plot_results(out,folder);
T=table(out.t,out.topX,out.tipY,out.theta,out.L,out.axialForceMin,out.constraint, ...
 'VariableNames',{'time_s','tower_top_x_m','jib_tip_y_m','chord_angle_rad','rope_length_m','minimum_axial_N','constraint_m'});
writetable(T,fullfile(folder,'history.csv'));
fprintf('Completed %.2f s; max constraint %.3e m; min axial %.4f N\n',out.t(end),max(out.constraint),min(out.axialForceMin));
end
