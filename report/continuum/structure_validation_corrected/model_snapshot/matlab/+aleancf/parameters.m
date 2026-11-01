function p=parameters()
% SI units; illustrative parameters, not calibrated to the paper.
p=flexcrane.parameters();
p=rmfield(p,'cR'); % No axial dashpot in the ANCF elastic element.
p.nElem=3; p.rhoA=0.10; p.EI=0.02;
p.theta0=3*pi/180;
p.relTol=2e-7; p.absTol=1e-9; p.maxStep=0.02;
p.nOutput=601;
end
