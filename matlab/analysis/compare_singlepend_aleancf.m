function compare_singlepend_aleancf(reuseResults,p,folder)
if nargin<1, reuseResults=false; end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<3, folder=fullfile(root,'report','singlepend_aleancf'); end
if ~exist(folder,'dir'), mkdir(folder); end
if nargin<2, p=continuum.parameters(); end
% Reuse only a verified parameter-identical baseline.
cache=fullfile(root,'report','rigid_flexible','flexible.mat');
if exist(cache,'file'), s=load(cache,'a'); else, s.a=[]; end
if reuseResults
 s=load(fullfile(folder,'comparison.mat'),'a'); assert(isequaln(s.a.p,p)); a=s.a;
elseif ~isempty(s.a) && isequaln(s.a.p,p), a=s.a;
else, a=continuum.simulate(p); end
if reuseResults, s=load(fullfile(folder,'comparison.mat'),'b'); assert(isequaln(s.b.p,p)); b=s.b; else, b=singlepend.simulate(p); end
save(fullfile(folder,'comparison.mat'),'a','b');
% Sum of cable nodal translation forces gives the support reaction;
% payload is represented separately and contributes its inertial reaction.
for k=1:numel(b.t)
 z=b.z(k,:).'; n=b.c.ns+1;
 [q,v,T,bias]=singlepend.map(b.t(k),z(1:n),z(n+1:end),p,b.c);
 dz=singlepend.rhs(b.t(k),z,p,b.c); acc=T*dz(n+1:end)+bias;
 [M,f]=continuum.assemble(b.t(k),q,v,p,b.c); R=M*acc-f;
 rr=reshape(R(b.c.ie),4,[]);
 b.force(k,:)=-(sum(rr(1:2,:),2)+R(b.c.ip)).';
end
A=[a.z(:,a.c.ip) a.theta a.topX a.tipY a.lambda(:,1:2) -a.lambda(:,5)];
B=[b.payload b.theta b.topX b.tipY b.force b.drive];
names={'payload_x','payload_y_down','swing','tower_top','jib_tip','support_force_x','support_force_y','drive_force'};
units={'m','m','rad','m','m','N','N','N'}; D=A-B;
metrics=table(names',units',max(abs(A))',max(abs(B))',max(abs(D))',sqrt(mean(D.^2))', ...
 'VariableNames',{'quantity','unit','ALE_peak_abs','single_peak_abs','max_abs_difference','rms_difference'});
writetable(metrics,fullfile(folder,'metrics.csv')); disp(metrics);
data=a.t; headers={'time_s'};
for j=1:8, data=[data A(:,j) B(:,j) D(:,j)]; headers=[headers {[names{j} '_ALE'],[names{j} '_single'],[names{j} '_difference']}]; end %#ok<AGROW>
writetable(array2table(data,'VariableNames',headers),fullfile(folder,'timeseries.csv'));
save(fullfile(folder,'comparison.mat'),'a','b','metrics');
f=figure('Visible','off','Position',[50 50 1250 1000]); tiledlayout(3,2);
cols=[1 2 3 4 5 7]; scales=[1000 1000 180/pi 1000 1000 1];
labels={'Payload X (mm)','Payload Y down (mm)','Chord angle (deg)','Tower top (mm)','Jib tip down (mm)','Vertical support force (N)'};
for k=1:6, nexttile; j=cols(k); plot(a.t,A(:,j)*scales(k),b.t,B(:,j)*scales(k),'--','LineWidth',1.2); grid on; xlabel('Time (s)'); ylabel(labels{k}); legend('ALE-ANCF','Single pendulum','Location','best'); end
continuum.light_figure(f); exportgraphics(f,fullfile(folder,'comparison.png'),'Resolution',160); close(f);
f=figure('Visible','off','Position',[50 50 1250 1000]); tiledlayout(3,2);
for k=1:6, nexttile; j=cols(k); plot(a.t,D(:,j)*scales(k),'LineWidth',1.2); grid on; xlabel('Time (s)'); ylabel([labels{k} ' difference']); end
continuum.light_figure(f); exportgraphics(f,fullfile(folder,'differences.png'),'Resolution',160); close(f);
fprintf('Single constraint %.3e, equation residual %.3e\n',max(b.constraint),max(b.residual));
end
