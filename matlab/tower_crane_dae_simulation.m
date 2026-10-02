%% tower_crane_dae_simulation.m
% 二维塔式起重机：绝对坐标多体动力学 + 固定绳长约束 + DAE 仿真
%
% 坐标：q = [xT; yT; phiT; xP; yP]
%   T: trolley（小车，平面刚体）
%   P: payload（吊物，质点）
%
% 约束：
%   C1 = yT - h = 0
%   C2 = phiT = 0
%   C3 = 1/2*((xP-xT)^2 + (yP-yT)^2 - l^2) = 0
%
% DAE 增广方程：
%   [M   Cq'] [qdd   ] = [F]
%   [Cq   0 ] [lambda]   [b]
%
% 其中 b = -gamma - 2*alpha*Cdot - beta^2*C，后两项为
% Baumgarte 约束稳定化项，用于抑制数值积分造成的约束漂移。
%
% 运行方法：在 MATLAB 命令窗口执行
%   tower_crane_dae_simulation
%
% 需要：MATLAB R2016b 或更高版本（脚本末尾使用局部函数）。

clear; clc; close all;

%% 1. 参数与仿真设置
p.mT = 20.0;            % 小车质量 [kg]
p.mP = 5.0;             % 吊物质量 [kg]
p.JT = 0.20;            % 小车转动惯量 [kg*m^2]
p.g  = 9.81;            % 重力加速度 [m/s^2]
p.h  = 5.0;             % 吊臂/小车轨道高度 [m]
p.l  = 2.0;             % 固定绳长 [m]

% Baumgarte 参数。对应约束误差方程 Cdd + 2*alpha*Cd + beta^2*C = 0。
p.alpha = 10.0;
p.beta  = 10.0;

p.forceAmplitude = 8.0; % 小车驱动力幅值 [N]
p.forceEndTime   = 2.0; % t <= forceEndTime 时施加恒定驱动力
p.tEnd = 12.0;          % 仿真终止时间 [s]

% 是否播放动画、是否将图片保存到 figures 文件夹
makeAnimation = true;
saveFigures   = false;

%% 2. 一致初始条件
theta0    = deg2rad(8.0); % 绳相对竖直向下方向的初始摆角 [rad]
thetaDot0 = 0.0;          % 初始角速度 [rad/s]
xT0       = 0.0;          % 小车初始位置 [m]
xTDot0    = 0.0;          % 小车初始速度 [m/s]

% 使用几何关系生成满足 C(q0)=0 和 Cq(q0)*qd0=0 的初值。
q0 = [xT0;
      p.h;
      0.0;
      xT0 + p.l*sin(theta0);
      p.h - p.l*cos(theta0)];

qd0 = [xTDot0;
       0.0;
       0.0;
       xTDot0 + p.l*cos(theta0)*thetaDot0;
       p.l*sin(theta0)*thetaDot0];

z0 = [q0; qd0];

[C0, Cq0] = constraintData(q0, p);
assert(norm(C0, inf) < 1e-12, '初始位置不满足约束。');
assert(norm(Cq0*qd0, inf) < 1e-12, '初始速度不满足约束。');

%% 3. 数值积分
opts = odeset('RelTol', 1e-9, 'AbsTol', 1e-11, 'MaxStep', 0.01);
[t, z] = ode45(@(t,z) stateEquation(t, z, p), [0 p.tEnd], z0, opts);

q  = z(:, 1:5);
qd = z(:, 6:10);
n  = numel(t);

theta       = zeros(n,1);
ropeLength  = zeros(n,1);
constraintE = zeros(n,1);
velocityE   = zeros(n,1);
daeResidual = zeros(n,1);
lambda      = zeros(n,3);
energy      = zeros(n,1);
inputForce  = zeros(n,1);
inputPower  = zeros(n,1);

for k = 1:n
    qk  = q(k,:).';
    qdk = qd(k,:).';
    [C, Cq] = constraintData(qk, p);
    [qdd, lambdak, residual] = solveDAE(t(k), qk, qdk, p);

    dx = qk(4) - qk(1);
    dy = qk(5) - qk(2);
    theta(k)       = atan2(dx, -dy);
    ropeLength(k)  = hypot(dx, dy);
    constraintE(k) = norm(C, inf);
    velocityE(k)   = norm(Cq*qdk, inf);
    daeResidual(k) = residual;
    lambda(k,:)    = lambdak.';
    inputForce(k)  = trolleyForce(t(k), p);
    inputPower(k)  = inputForce(k)*qdk(1);

    kinetic = 0.5*p.mT*(qdk(1)^2 + qdk(2)^2) ...
            + 0.5*p.JT*qdk(3)^2 ...
            + 0.5*p.mP*(qdk(4)^2 + qdk(5)^2);
    potential = p.mT*p.g*qk(2) + p.mP*p.g*qk(5);
    energy(k) = kinetic + potential;
end

work = cumtrapz(t, inputPower);
energyWorkError = energy - energy(1) - work;

%% 4. 自动数值测试
maxPositionConstraint = max(constraintE);
maxVelocityConstraint = max(velocityE);
maxRopeLengthError    = max(abs(ropeLength - p.l));
maxDAEResidual        = max(daeResidual);
maxEnergyWorkError    = max(abs(energyWorkError));
energyScale           = max(1.0, max(abs(energy - energy(1))) + abs(energy(1)));

fprintf('\n===== 二维塔吊 DAE 仿真测试 =====\n');
fprintf('时间步输出点数                 : %d\n', n);
fprintf('最大位置约束误差 ||C||_inf     : %.3e\n', maxPositionConstraint);
fprintf('最大速度约束误差 ||Cq*qd||_inf : %.3e\n', maxVelocityConstraint);
fprintf('最大绳长误差                   : %.3e m\n', maxRopeLengthError);
fprintf('最大动力学线性方程残差         : %.3e\n', maxDAEResidual);
fprintf('最大能量-外力做功误差          : %.3e J\n', maxEnergyWorkError);
fprintf('最终小车位置                   : %.4f m\n', q(end,1));
fprintf('最终摆角                       : %.4f deg\n', rad2deg(theta(end)));

assert(all(isfinite(z(:))), '测试失败：仿真结果包含 NaN 或 Inf。');
assert(maxRopeLengthError < 1e-6, '测试失败：固定绳长约束误差过大。');
assert(maxDAEResidual < 1e-8, '测试失败：DAE 增广方程残差过大。');
assert(maxEnergyWorkError/energyScale < 2e-4, ...
    '测试失败：能量与外力做功不平衡。请减小 MaxStep。');
fprintf('自动测试结果                   : PASS\n\n');

%% 5. 仿真结果绘图
fig1 = figure('Color','w','Name','Tower crane DAE results');
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

nexttile;
plot(t, q(:,1), 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('x_T [m]');
title('Trolley position');

nexttile;
plot(t, rad2deg(theta), 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('\theta [deg]');
title('Payload swing angle');

nexttile;
semilogy(t, max(abs(ropeLength-p.l), eps), 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('|l_{calc}-l| [m]');
title('Fixed-rope constraint error');

nexttile;
plot(q(:,4), q(:,5), 'LineWidth', 1.5);
axis equal; grid on; xlabel('x_P [m]'); ylabel('y_P [m]');
title('Payload trajectory');

fig2 = figure('Color','w','Name','DAE verification');
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

nexttile;
plot(t, inputForce, 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('u [N]'); title('Input force');

nexttile;
plot(t, lambda(:,3), 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('\lambda_3'); title('Rope constraint multiplier');

nexttile;
plot(t, energy-energy(1), 'LineWidth', 1.5); hold on;
plot(t, work, '--', 'LineWidth', 1.5); hold off;
grid on; xlabel('Time [s]'); ylabel('Energy / work [J]');
legend('E(t)-E(0)', 'Input work', 'Location','best');
title('Energy-work balance');

nexttile;
semilogy(t, max(daeResidual,eps), 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('Residual');
title('Augmented DAE equation residual');

if saveFigures
    scriptDir = fileparts(mfilename('fullpath'));
    figureDir = fullfile(scriptDir, '..', 'figures');
    if ~exist(figureDir, 'dir'); mkdir(figureDir); end
    exportgraphics(fig1, fullfile(figureDir, 'tower_crane_dae_results.png'), ...
        'Resolution', 200);
    exportgraphics(fig2, fullfile(figureDir, 'tower_crane_dae_verification.png'), ...
        'Resolution', 200);
end

%% 6. 简单运动动画
if makeAnimation
    figure('Color','w','Name','Tower crane animation');
    frameIndex = unique(round(linspace(1,n,min(n,500))));
    xMin = min([q(:,1);q(:,4)]) - 0.5;
    xMax = max([q(:,1);q(:,4)]) + 0.5;

    for k = frameIndex.'
        cla;
        plot([xMin xMax], [p.h p.h], 'k-', 'LineWidth', 2); hold on;
        plot(q(k,1), q(k,2), 'ks', 'MarkerSize', 10, ...
            'MarkerFaceColor', [0.2 0.5 0.9]);
        plot([q(k,1) q(k,4)], [q(k,2) q(k,5)], 'k-', 'LineWidth', 1.5);
        plot(q(k,4), q(k,5), 'o', 'MarkerSize', 12, ...
            'MarkerFaceColor', [0.9 0.3 0.2], 'MarkerEdgeColor','k');
        hold off; axis equal; grid on;
        xlim([xMin xMax]); ylim([p.h-p.l-0.5 p.h+0.5]);
        xlabel('X [m]'); ylabel('Y [m]');
        title(sprintf('2D tower crane DAE simulation, t = %.2f s', t(k)));
        drawnow limitrate;
    end
end

%% 局部函数
function dz = stateEquation(t, z, p)
    q  = z(1:5);
    qd = z(6:10);
    qdd = solveDAE(t, q, qd, p);
    dz = [qd; qdd];
end

function [qdd, lambda, residual] = solveDAE(t, q, qd, p)
    M = diag([p.mT, p.mT, p.JT, p.mP, p.mP]);
    [C, Cq] = constraintData(q, p);

    dxDot = qd(4) - qd(1);
    dyDot = qd(5) - qd(2);
    gamma = [0.0; 0.0; dxDot^2 + dyDot^2];
    Cdot = Cq*qd;

    % F = [小车水平驱动力; 小车重力; 转矩; 吊物水平力; 吊物重力]
    F = [trolleyForce(t,p); -p.mT*p.g; 0.0; 0.0; -p.mP*p.g];

    b = -gamma - 2.0*p.alpha*Cdot - p.beta^2*C;
    augmentedMatrix = [M, Cq.'; Cq, zeros(3,3)];
    rightHandSide   = [F; b];
    solution = augmentedMatrix \ rightHandSide;

    qdd    = solution(1:5);
    lambda = solution(6:8);
    residual = norm(augmentedMatrix*solution-rightHandSide, inf);
end

function [C, Cq] = constraintData(q, p)
    xT = q(1); yT = q(2); phiT = q(3);
    xP = q(4); yP = q(5);
    dx = xP - xT;
    dy = yP - yT;

    C = [yT - p.h;
         phiT;
         0.5*(dx^2 + dy^2 - p.l^2)];

    Cq = [ 0.0,  1.0, 0.0, 0.0, 0.0;
           0.0,  0.0, 1.0, 0.0, 0.0;
           -dx,  -dy, 0.0,  dx,  dy];
end

function u = trolleyForce(t, p)
    % 简单开环测试输入：前 2 秒施加恒定水平力，此后撤去。
    if t <= p.forceEndTime
        u = p.forceAmplitude;
    else
        u = 0.0;
    end
end
