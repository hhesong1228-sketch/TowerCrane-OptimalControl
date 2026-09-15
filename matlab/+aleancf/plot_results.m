function fig=plot_results(out)
% Plot a saved result without rerunning the time integration.
n=size(out.q,2);
    fig=figure('Color','w','Position',[100 100 1100 850]);
    tiledlayout(3,2,'Padding','loose','TileSpacing','loose');
    nexttile; plot(out.t,[out.q(:,1),out.q(:,n-3)]); grid on;
    xlabel('Time [s]'); ylabel('Horizontal position [m]'); legend('Trolley','Payload');
    nexttile; plot(out.t,out.theta*180/pi); grid on;
    xlabel('Time [s]'); ylabel('Chord angle [deg]');
    nexttile; plot(out.t,[out.L,out.arcLength]); grid on;
    xlabel('Time [s]'); ylabel('Length [m]'); legend('Material','Actual arc');
    nexttile; plot(out.t,out.axialForceMin); grid on;
    xlabel('Time [s]'); ylabel('Min axial force [N]');
    nexttile; plot(out.t,out.q(:,2)*1000); grid on;
    xlabel('Time [s]'); ylabel('Support deflection [mm]');
    nexttile; hold on;
    for i=round(linspace(1,numel(out.t),6))
        curve=[];
        for e=1:out.p.nElem
            idx=4*(e-1)+1:4*(e+1);
            for xi=linspace(0,1,16)
                N=aleancf.shape(xi,[0 out.L(i)/out.p.nElem],[0 0],[0 0]);
                curve(:,end+1)=N*out.q(i,idx).'; %#ok<AGROW>
            end
        end
        plot(curve(1,:),curve(2,:),'DisplayName',sprintf('t=%.1f s',out.t(i)));
        plot(curve(1,[1 end]),curve(2,[1 end]),'ko','MarkerSize',3,'HandleVisibility','off');
    end
    set(gca,'YDir','reverse'); axis equal; grid on;
    xlim([min(min(out.q(:,1:4:n)))-0.1,max(max(out.q(:,1:4:n)))+0.1]);
    ylim([min(min(out.q(:,2:4:n)))-0.1,max(max(out.q(:,2:4:n)))+0.1]);
    xticks(xlim); xtickformat('%.1f');
    xlabel('Horizontal [m]'); ylabel('Down [m]'); legend('Location','eastoutside');
end
