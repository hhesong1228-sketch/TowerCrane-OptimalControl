function plot_results(out,folder)
if ~exist(folder,'dir'), mkdir(folder); end
f=figure('Visible','off','Color','w','Position',[100 100 1200 800]);
tiledlayout(3,2); t=out.t;
nexttile; plot(t,1000*[out.topX-out.topX(1),out.tipY-out.tipY(1)]); grid on;
xlabel('Time (s)'); ylabel('Change from initial (mm)'); legend('Tower top x','Jib tip y');
nexttile; plot(t,out.theta*180/pi); grid on; xlabel('Time (s)'); ylabel('Payload chord angle (deg)');
nexttile; plot(t,[out.L,out.z(:,out.c.ix)]); grid on; xlabel('Time (s)'); ylabel('Length / position (m)'); legend('Rope material length','Trolley x');
nexttile; plot(t,out.axialForceMin); grid on; xlabel('Time (s)'); ylabel('Min. sampled axial force (N)');
nexttile; plot(t,out.lambda(:,1:2)); grid on; xlabel('Time (s)'); ylabel('Cable force on suspension (N)'); legend('Horizontal','Downward');
nexttile; semilogy(t,max(out.constraint,1e-16)); grid on; xlabel('Time (s)'); ylabel('Constraint error (m)');
exportgraphics(f,fullfile(folder,'simulation.png'),'Resolution',160); close(f);
f=figure('Visible','off','Color','w'); hold on; c=out.c; p=out.p;
z=linspace(0,p.H,100)'; x=linspace(0,p.B,100)';
for k=unique(round(linspace(1,numel(t),5)))
 q=out.z(k,1:c.n).';
 plot(continuum.modes(z,p.H,c.nt)*q(c.it),p.H-z,'Color',[.6 .6 .6]);
 plot(x+c.top*q(c.it),-x*(c.slope*q(c.it))+continuum.modes(x,p.B,c.nj)*q(c.ij),'Color',[.4 .4 .4]);
 rope=[];
 for e=1:p.nElem
  for u=linspace(0,1,15)
   S=aleancf.shape(u,[0 out.L(k)/p.nElem],[0 0],[0 0]);
   rope(:,end+1)=S*q(c.ie(4*(e-1)+(1:8))); %#ok<AGROW>
  end
 end
 plot(rope(1,:),rope(2,:),'LineWidth',1.2);
end
set(gca,'YDir','reverse'); axis equal; grid on; xlabel('x (m)'); ylabel('y downward from tower top (m)');
title('Five snapshots: true displacement scale');
exportgraphics(f,fullfile(folder,'geometry.png'),'Resolution',160); close(f);
end
