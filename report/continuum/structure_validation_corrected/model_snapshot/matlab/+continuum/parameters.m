function p=parameters()
% Demonstration SI parameters; equivalent beams, not a calibrated crane.
p=aleancf.parameters();
p.nTower=2; p.nJib=2; p.H=4; p.B=3;
p.muTower=12; p.muJib=8; p.EITower=8e4; p.EIJib=3e4;
p.zeta=0.01; p.x0=2; p.x1=2.4;
p.moveStart=1; p.moveDuration=4;
p.theta0=2*pi/180; p.tEnd=10; p.nOutput=501;
p.relTol=2e-7; p.absTol=1e-9; p.maxStep=0.02;
p.alpha=10; p.beta=10; % Baumgarte gains [1/s]
end
