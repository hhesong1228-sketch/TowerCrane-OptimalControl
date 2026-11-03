# MATLAB 目录与运行指南

从项目根目录打开 MATLAB，先执行：

```matlab
addpath('matlab'); setup_paths;
```

`setup_paths` 只添加本目录、`tests` 和 `analysis`，不扫描报告中的历史代码快照。每次新的 MATLAB 会话执行一次即可；不需要永久保存路径。

## 目录

```text
matlab/
├── README.md                         使用导航
├── setup_paths.m                     初始化当前项目路径
├── tower_crane_*.m                   四种模型的仿真入口
├── +flexcrane/                       简化柔性变绳长模型实现
├── +aleancf/                         ALE-ANCF 吊索模型实现
├── +continuum/                       连续体塔身—吊臂耦合模型实现
├── tests/                           回归测试与模态基函数检查
└── analysis/                        结构验证、收敛分析与结果绘图
```

`+` 开头的目录是 MATLAB 包，用 `continuum.parameters()` 等方式调用，保留在当前层级。

## 选择仿真入口

| 入口 | 用途 |
| --- | --- |
| `tower_crane_continuum_ancf` | 连续体塔身、吊臂与 ANCF / ALE-ANCF 吊索耦合模型 |
| `tower_crane_aleancf` | ALE-ANCF 变长度柔性吊索与集总柔性支撑 |
| `tower_crane_flexible_variable_length` | 简化的柔性支撑、弹性绳与变绳长模型 |
| `tower_crane_dae_simulation` | 最初的绝对坐标多体、固定绳长 DAE 演示脚本 |

例如运行连续体耦合模型：

```matlab
out = tower_crane_continuum_ancf;
```

前三个入口为函数；DAE 入口是脚本。仿真会生成图表或结果文件；输出位置仍沿用项目的 `report/` 和 `figures/`。

## 测试与验证

| 文件 | 用途 |
| --- | --- |
| `tests/test_flexible_variable_length.m` | 简化变绳长模型回归测试 |
| `tests/test_aleancf.m` | ALE 运动学、质量、弹性、静力、能量与网格测试 |
| `tests/test_continuum_ancf.m` | 连续体耦合模型回归测试，内部调用连接审计 |
| `tests/test_continuum_high_modes.m` | 高阶梁模态归一化与正交性检查 |
| `analysis/audit_continuum_connection.m` | 塔身与吊臂刚接几何符号审计 |
| `analysis/validate_continuum_structure.m` | 独立静挠度核对和动态模态加密 |
| `analysis/plot_continuum_static_validation.m` | 绘制结构验证已生成的静态结果 |
| `analysis/analyze_continuum_modal_convergence.m` | 修正后模型的三阶、四阶模态比较 |
| `analysis/summarize_continuum_sign_fix.m` | 比较修正前后已生成的动态结果 |

初始化路径后，可以直接按函数名运行，不需要切换目录：

```matlab
audit_continuum_connection;
test_continuum_high_modes;
test_continuum_ancf;
result = validate_continuum_structure;
plot_continuum_static_validation;
```

完整动态验证可能耗时较长。绘图和修正前后汇总依赖已有结果，先运行对应分析；`summarize_continuum_sign_fix` 同时需要历史验证结果。历史快照和报告保留在 `report/`，其中的旧路径和运行命令记录当时的目录结构，现行操作以本指南为准。
