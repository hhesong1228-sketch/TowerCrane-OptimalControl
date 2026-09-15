# 二维柔性变绳长塔吊模型

## 1. 论文依据与建模范围

参考：Kun Li, Manlan Liu, Zuqing Yu, Peng Lan, Nianli Lu (2022), *Multibody system dynamic analysis and payload swing control of tower crane*, Proc IMechE Part K: J Multi-body Dynamics, 236(3), 407–421. DOI: 10.1177/14644193221101994。

依据用户提供的论文：第 409 页式 (8)–(9) 给出轴向与弯曲应变能；第 411 页式 (20) 给出多体 DAE 框架；第 412 页式 (22)–(23) 讨论吊点竖向运动与摆动耦合，式 (28)–(29) 讨论变绳长耦合。

本实现是受论文启发的**二维四自由度降阶模型**，不是论文 ALE-ANCF 模型的完整复现。把绳视为无质量、可轴向伸缩的直线弹性绳，以一个竖向弹簧阻尼器近似塔身/吊臂柔性。保留非线性大角度摆动及收放绳耦合，不计绳索弯曲、分布质量、材料流动惯性、三维回转、接触或松绳。参数为演示用小型系统数值，未进行论文参数拟合或实验验证。

## 2. 坐标与本构关系

二维平面中水平向右、竖直向下为正：吊点位置 `(x,d)`，吊物位置 `(X,Y)`。`d` 从未加载支撑位置量起，因此包含重力静挠度。广义坐标可取 `q=(x,d,X,Y)`，等价于 `(x,d,r,theta)`：

```text
X = x + r sin(theta)
Y = d + r cos(theta)
h = [X-x; Y-d], r = ||h||, n = h/r
rdot = n' [Xdot-xdot; Ydot-ddot]
```

`L(t)>0` 是卷扬机构给定的无伸长放绳长度，`r(t)` 是实际吊点—吊物距离：

```text
e = r-L                       轴向伸长 [m]
k(t) = EA/L(t)                 轴向刚度 [N/m]
T = k e + cR (rdot-Ldot)       张力 [N]
Urope = EA/(2L) (r-L)^2
```

均匀直绳轴向应变 `epsilon=e/L` 代入论文式 (8) 的轴向能量项，得到上述势能；弯曲项被舍去。阻尼采用集总 Kelvin–Voigt 模型，`cR` 取常数是本模型附加假设。

模型仅用于 `T>0` 且 `e>0` 的张紧小应变工况。事件检测在张力或伸长降至零时停止，不将负张力解释成绳索承压。大变形指大摆角，不表示轴向材料允许任意大应变。

## 3. 完整动力学方程

支撑刚度为 `kB`，阻尼为 `cB`；小车/吊点集总质量 `mT`，吊物质量 `mP`，小车水平驱动力 `u(t)`：

```text
mT ẍ = u + T nx
mT d̈ = mT g + T ny - kB d - cB ḋ
mP Ẍ = -T nx
mP Ÿ = mP g - T ny
```

上点表示时间一阶导数，双点表示二阶导数。

代码采用上述笛卡尔形式，质量矩阵为常数对角矩阵，无需对绳施加固定长度约束。极坐标形式可用于检查收放绳与摆动的耦合：

```text
r θ̈ + 2 ṙ θ̇ + ẍ cosθ + (g-d̈) sinθ = 0
r̈ = r θ̇² + (g-d̈) cosθ - ẍ sinθ - T/mP
```

代入 `r=L+e`，可得弹性伸长方程：

```text
ë = (L+e) θ̇² + (g-d̈) cosθ - ẍ sinθ
     - [EA/L * e + cR*ė]/mP - L̈
```

所以变绳长不仅改变摆动频率，还通过 `2 ṙ θ̇` 产生耦合，并通过 `L̈` 激励轴向运动。刚性支撑、不可伸长、小角度极限恢复论文式 (29)。本文为径向方程显式补入实际绳张力；不直接把论文式 (28) 第三行当作卷扬输入方程。

## 4. 初值、输入与能量验证

竖直静力平衡：

```text
d0 = (mT+mP) g/kB
r0 = L0 + mP g/(EA/L0)
T0 = mP g
```

演示从 5° 初始摆角释放，此时不是严格静力平衡。驱动力是持续 4 秒的平滑正负脉冲 `u=4 sin³(2πt/4) N`；2–8 秒内用五次多项式将 `L` 从 2 m 缩短至 1.4 m。输入是开环演示，不声称具备论文的消摆或最优控制效果。卷扬机构被理想化为规定长度输入，未建电机/卷筒动力学。

系统能量：

```text
E = 1/2 mT (ẋ²+ḋ²) + 1/2 mP (Ẋ²+Ẏ²)
    - mT g d - mP g Y + 1/2 kB d² + 1/2 k e²
Ė = u ẋ - cB ḋ² - cR ė² - T L̇ + 1/2 k̇ e²
k̇ = -EA L̇/L²
```

最后两项共同表示本降阶变参数绳模型的长度输入功率，不能仅用小车做功检验收绳工况的能量。代码将净功率作为第九个状态积分，以检查 `E(t)-E(0)-W(t)`。

## 5. 文件与运行

MATLAB R2020a 或更新版本；仅用基础 MATLAB，无需额外工具箱。在项目根目录执行：

```matlab
addpath('matlab');
test_flexible_variable_length;
out = tower_crane_flexible_variable_length;
```

运行后 `report/flexible_variable_length/` 保存 `simulation.mat`、`simulation.csv` 和 `simulation.png`。不绘图或保存时：

```matlab
out = tower_crane_flexible_variable_length(false,false);
```

自定义参数：

```matlab
p = flexcrane.parameters();
p.L1 = 1.6;
p.EA = 4e4;
out = flexcrane.simulate(p);
```

`+flexcrane/inputs.m` 可替换长度轨迹与水平力。默认初值假设 t=0 放绳速度为零且长度为 L0；自定义输入时应同步调整一致初值。支撑弹簧是集总近似，不包含小车位置变化导致的梁模态变化。

`test_flexible_variable_length.m` 验证静平衡/张力、无阻尼无输入能量守恒、水平动量守恒、变长度能量收支、非线性摆动方程恒等式和更严格积分设置下的收敛性。测试证明实现的内部一致性，不等同于实机或论文有限元结果验证。
