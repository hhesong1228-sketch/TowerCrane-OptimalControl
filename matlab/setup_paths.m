function setup_paths()
% Add the model packages, tests and analysis tools for this checkout.
% Run from the repository root: addpath('matlab'); setup_paths;
matlabRoot = fileparts(mfilename('fullpath'));
addpath(matlabRoot, fullfile(matlabRoot,'tests'), fullfile(matlabRoot,'analysis'));
end
