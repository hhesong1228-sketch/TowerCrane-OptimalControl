function out = tower_crane_flexible_variable_length(makePlots,saveResults)
% 2D flexible-support, axially elastic, variable-length tower crane.
% Run: out = tower_crane_flexible_variable_length;
% Headless: out = tower_crane_flexible_variable_length(false,false);
if nargin<1, makePlots=true; end
if nargin<2, saveResults=true; end
p=flexcrane.parameters(); out=flexcrane.simulate(p);
fprintf('Max swing: %.4f deg; minimum tension: %.4f N\n', ...
    max(abs(out.theta))*180/pi,min(out.tension));
fprintf('Max energy balance error: %.3e J\n',max(abs(out.energyError)));
root=fileparts(fileparts(mfilename('fullpath')));
if saveResults
    folder=fullfile(root,'report','flexible_variable_length');
    if ~exist(folder,'dir'), mkdir(folder); end
    save(fullfile(folder,'simulation.mat'),'out');
    data=table(out.t,out.z(:,1),out.z(:,2),out.z(:,3),out.z(:,4), ...
        out.theta,out.L,out.r,out.extension,out.tension,out.energyError, ...
        'VariableNames',{'time_s','trolley_x_m','support_down_m','payload_x_m', ...
        'payload_down_m','swing_rad','natural_length_m','actual_length_m', ...
        'extension_m','tension_N','energy_error_J'});
    writetable(data,fullfile(folder,'simulation.csv'));
end
if makePlots
    fig=figure('Color','w','Name','2D flexible variable-length crane', ...
        'Position',[100 100 1100 850]);
    tiledlayout(3,2,'Padding','loose','TileSpacing','loose');
    nexttile; plot(out.t,[out.z(:,1),out.z(:,3)]); grid on;
    xlabel('Time [s]'); ylabel('Horizontal position [m]'); legend('Trolley','Payload');
    nexttile; plot(out.t,out.theta*180/pi); grid on;
    xlabel('Time [s]'); ylabel('Swing [deg]');
    nexttile; plot(out.t,[out.L,out.r]); grid on;
    xlabel('Time [s]'); ylabel('Length [m]'); legend('Unstretched L','Actual r');
    nexttile; plot(out.t,out.extension*1000); grid on;
    xlabel('Time [s]'); ylabel('Rope extension [mm]');
    nexttile; plot(out.t,out.tension); grid on;
    xlabel('Time [s]'); ylabel('Tension [N]');
    nexttile; plot(out.t,out.z(:,2)*1000); grid on;
    xlabel('Time [s]'); ylabel('Support deflection [mm]');
    if saveResults
        exportgraphics(fig,fullfile(folder,'simulation.png'),'Resolution',160);
    end
end
end
