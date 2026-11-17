function check_fast_hoist_resolution()
% Rope mesh + solver refinement; beam modes deliberately remain at two.
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); folder=fullfile(root,'report','fast_hoist');
p=continuum.parameters(); p.hoistDuration=.75; p.nOutput=2001;
p.nElem=6; p.relTol=2e-8; p.absTol=1e-10; p.maxStep=.01;
tic; out=continuum.simulate(p); elapsed=toc;
save(fullfile(folder,'refined_0.75.mat'),'out','elapsed');
fprintf('Refined fast ALE simulation completed in %.1f s; min axial force %.4f N; max constraint %.3e m\n',elapsed,min(out.axialForceMin),max(out.constraint));
end
