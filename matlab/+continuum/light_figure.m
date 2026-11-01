function light_figure(f)
% Reproducible exported colors independent of desktop dark/light preferences.
set(f,'Color','w');
set(findall(f,'Type','axes'),'Color','w','XColor','k','YColor','k','GridColor',[.6 .6 .6]);
set(findall(f,'Type','text'),'Color','k');
set(findall(f,'Type','legend'),'Color','w','TextColor','k','EdgeColor',[.5 .5 .5]);
end
