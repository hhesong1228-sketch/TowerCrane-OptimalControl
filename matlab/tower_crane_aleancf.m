function out=tower_crane_aleancf(makePlots,saveResults)
% Planar ALE-ANCF cable + lumped flexible support + point payload.
% Prescribed material mesh: s_i(t)=(-1+i/nElem)*L(t), payload end s=0.
if nargin<1, makePlots=true; end
if nargin<2, saveResults=true; end
out=aleancf.simulate(aleancf.parameters());
n=size(out.q,2); folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'report','aleancf');
fprintf('ALE-ANCF: %d elements, %d mechanical coordinates\n',out.p.nElem,n);
fprintf('Max chord swing %.6f deg; minimum sampled axial force %.6f N\n', ...
    max(abs(out.theta))*180/pi,min(out.axialForceMin));
if saveResults
    if ~exist(folder,'dir'), mkdir(folder); end
    save(fullfile(folder,'simulation.mat'),'out');
    data=table(out.t,out.q(:,1),out.q(:,2),out.q(:,n-3),out.q(:,n-2), ...
        out.theta,out.L,out.arcLength,out.axialForceMin,out.aleForceNorm, ...
        'VariableNames',{'time_s','trolley_x_m','support_down_m','payload_x_m', ...
        'payload_down_m','chord_angle_rad','material_length_m','arc_length_m', ...
        'min_axial_force_N','ale_generalized_force_norm'});
    writetable(data,fullfile(folder,'simulation.csv'));
end
if makePlots
    fig=aleancf.plot_results(out);
    if saveResults, exportgraphics(fig,fullfile(folder,'simulation.png'),'Resolution',150); end
end
end
