function p = parameters()
% Illustrative laboratory-scale parameters, not identified from Li et al.
p.mT = 20; p.mP = 5; p.g = 9.81;
p.kB = 6000; p.cB = 30; % Equivalent vertical support stiffness/damping
p.EA = 2e4; p.cR = 15; % Axial rigidity [N], rope damping [N s/m]
p.L0 = 2; p.L1 = 1.4; % Unstretched deployed lengths [m]
p.hoistStart = 2; p.hoistDuration = 6;
p.forceAmplitude = 4; p.forceDuration = 4;
p.theta0 = 5*pi/180; p.tEnd = 12;
p.relTol = 1e-9; p.absTol = 1e-11; p.maxStep = 0.01;
end
