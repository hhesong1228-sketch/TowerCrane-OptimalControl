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

## 模型说明书 / モデル説明書

- [中文版：模型说明书](report/manuals/model_manual_zh.md)
- [日本語版：モデル説明書](report/manuals/model_manual_ja.md)

两版对应当前二维 ALE-ANCF 实现，包含参数、运行步骤、理论公式、输出解释和适用范围。
両版とも現行の二次元 ALE-ANCF 実装を対象とし、パラメータ、実行手順、理論式、出力の解釈および適用範囲を説明します。

- [中文版 PDF](output/pdf/model_manual_zh.pdf)
- [日本語版 PDF](output/pdf/model_manual_ja.pdf)

## 连续体塔身—起重臂 + ANCF / ALE-ANCF 吊索

塔身与臂架采用 Euler–Bernoulli 连续梁假设模态法，包含塔顶平移、转角和移动小车的惯性耦合。吊索与吊物通过位置约束连接，使用加速度级鞍点系统与约束稳定化求解。底座固支，二维平面演示模型。

```matlab
addpath('matlab');
out = tower_crane_continuum_ancf;
test_continuum_ancf;
```

- [完整中文建模与仿真说明书](report/continuum/model_manual_zh.md)
- [入口代码](matlab/tower_crane_continuum_ancf.m)
- [时程图](report/continuum/simulation.png)
- [几何快照](report/continuum/geometry.png)
- [验证记录](report/continuum/validation.txt)

默认各保留两阶梁模态和三个绳单元，支持固定索长与规定材料坐标的收放绳。示例参数未经过真实塔吊标定。

### 连续体耦合模型双语 PDF

- [中文版 PDF](output/pdf/continuum_ancf_manual_zh.pdf)
- [日本語版 PDF](output/pdf/continuum_ancf_manual_ja.pdf)
- [日本語版 Markdown](report/continuum/model_manual_ja.md)

两版包含相同的模型公式、参数、运行方法、结果图与精度限制。PDF 生成脚本：`scripts/build_continuum_manual_pdfs.py`。
