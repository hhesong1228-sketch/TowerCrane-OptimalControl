function plot_continuum_static_validation()
folder=fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'report','continuum','structure_validation_corrected');
f=figure('Visible','off','Color','w','Position',[100 100 1150 800]);tiledlayout(2,2);
for j=1:2
 T=readtable(fullfile(folder,sprintf('static_fields_case%d.csv',j)));
 nexttile;plot(T.zz,1000*T.towerExact,'k-',T.zz,1000*T.tw,'r--');grid on;
 xlabel('Tower coordinate z (m)');ylabel('Horizontal deflection (mm)');title(sprintf('Static case %d: tower',j));legend('Physical closed form','16 modes','Location','best');
 nexttile;plot(T.xx,1000*T.jibExact,'k-',T.xx,1000*T.jw,'r--');grid on;
 xlabel('Jib coordinate (m)');ylabel('Vertical deflection (mm)');title(sprintf('Static case %d: jib',j));legend('Physical closed form','16 modes','Location','best');
end
continuum.light_figure(f);
exportgraphics(f,fullfile(folder,'independent_static_fields.png'),'Resolution',160);close(f);
end
