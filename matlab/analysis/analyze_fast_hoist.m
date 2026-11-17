function analyze_fast_hoist()
% Same travel, beams, rope and trolley input; vary only hoist duration.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
folder=fullfile(root,'report','fast_hoist'); if ~exist(folder,'dir'), mkdir(folder); end
diary(fullfile(folder,'run_log.txt')); cleanup=onCleanup(@()diary('off')); %#ok<NASGU>
for duration=[1.5 .75]
 p=continuum.parameters(); p.hoistDuration=duration; p.nOutput=2001;
 casefolder=fullfile(folder,sprintf('duration_%g',duration));
 fprintf('Running hoist duration %.3f s, peak speed %.3f m/s, peak acceleration %.3f m/s^2\n',duration,1.875*abs(p.L1-p.L0)/duration,(10/sqrt(3))*abs(p.L1-p.L0)/duration^2);
 compare_singlepend_aleancf(false,p,casefolder);
end
end
