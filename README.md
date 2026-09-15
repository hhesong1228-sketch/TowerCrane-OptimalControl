# TowerCrane-OptimalControl

Research and implementation workspace for tower crane modeling, DAE systems, and optimal control.

## Project Structure

```text
TowerCrane-OptimalControl
├── matlab
├── python
├── paper
├── report
├── figures
├── presentation
└── README.md
```

## Folders

- `matlab`: MATLAB models, simulations, and optimal-control scripts.
- `python`: Python implementations, numerical experiments, and analysis tools.
- `paper`: Literature notes, paper drafts, and references.
- `report`: Project reports and technical writeups.
- `figures`: Diagrams, plots, simulation outputs, and model illustrations.
- `presentation`: Slides and presentation materials.

## Topics

- Tower crane dynamics
- Differential-algebraic equations
- Optimal control
- MATLAB and Python simulation workflows


## 二维柔性变绳长模型

根据 Li et al. (2022) 建立的降阶模型，包含吊点竖向柔性、绳索轴向弹性和规定收放绳输入。它不是完整 ALE-ANCF 有限元复现。

```matlab
addpath('matlab');
test_flexible_variable_length;
out = tower_crane_flexible_variable_length;
```

- [中文推导、假设和使用说明](report/flexible_variable_length_model_zh.md)
- [MATLAB 入口](matlab/tower_crane_flexible_variable_length.m)
- [仿真图](report/flexible_variable_length/simulation.png)
- [验证记录](report/flexible_variable_length/validation.txt)

## 二维 ALE-ANCF 变长度柔性绳

新增分布质量、轴向/弯曲弹性和材料流动惯性。采用给定材料坐标的固定数量移动网格；吊点继续使用集总竖向柔性支撑。

```matlab
addpath('matlab');
test_aleancf;
out = tower_crane_aleancf;
```

- [ALE-ANCF 推导、实现范围和验证说明](report/aleancf_model_zh.md)
- [MATLAB 入口](matlab/tower_crane_aleancf.m)
- [ALE-ANCF 仿真图](report/aleancf/simulation.png)
- [ALE-ANCF 验证记录](report/aleancf/validation.txt)
