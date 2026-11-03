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

- `matlab`: MATLAB models, simulations, and optimal-control scripts. See [MATLAB 目录与运行指南](matlab/README.md).
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
addpath('matlab'); setup_paths;
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
addpath('matlab'); setup_paths;
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
addpath('matlab'); setup_paths;
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

### 修正前的三阶与四阶梁模态比较（历史记录）

- [静态解析核对及完整动态分析](report/continuum/modal_convergence/analysis_zh.md)
- [时程对比图](report/continuum/modal_convergence/response_comparison.png)
- [复现脚本](matlab/analysis/analyze_continuum_modal_convergence.m)

固定六段吊索，在完整 10 s 工况下比较每根梁三阶与四阶模态。摆角对本次加密较不敏感，但臂端静挠度和结构振动尚不能认定收敛；具体误差及判定范围见分析报告。

## 修正前的结构模态收敛与独立静挠度验证（历史记录）

以下链接仅保留修正前的历史结果，不作为现行模型结论。

- [验证说明与判据](report/continuum/structure_validation/verification_zh.md)
- [独立静挠度结果](report/continuum/structure_validation/static_validation.csv)
- [动态模态加密结果](report/continuum/structure_validation/dynamic_validation.csv)
- [静态全场对照](report/continuum/structure_validation/independent_static_fields.png)
- [响应和误差收敛图](report/continuum/structure_validation/convergence.png)

新增稳定的 1–16 阶连续梁振型计算；默认模态数不变。动态比较 4、6、8、12 阶，静态对照至 16 阶；全部固定六段吊索。验证完成不代表所有量均达到 1% 精度，详见各量误差与判据。

**历史问题：** 修正前塔顶斜率与吊臂根部斜率反号，独立静态对照未通过。2026-11-02 已统一修正运动学、惯性、重力及输出，旧记录保留用于追溯。

## 刚接符号修正后的重新验证（2026-11-02）

当前程序使用正号 `rJ,Y = ξ bη + ψ(ξ)ζ`。重新验证入口：

```matlab
addpath('matlab'); setup_paths;
audit_continuum_connection;
test_continuum_high_modes;
test_continuum_ancf;
result=validate_continuum_structure;
plot_continuum_static_validation;
```

- [修正与重新验证报告](report/continuum/structure_validation_corrected/verification_zh.md)
- [独立静态对照](report/continuum/structure_validation_corrected/static_validation.csv)
- [刚接几何检查](report/continuum/structure_validation_corrected/connection_sign_audit.csv)
- [动态模态比较](report/continuum/structure_validation_corrected/dynamic_validation.csv)
- [完整回归记录](report/continuum/structure_validation_corrected/regression/validation.txt)
- [各项误差随模态阶数变化曲线（7 页 PDF）](output/pdf/continuum_error_convergence_zh.pdf)

旧默认算例和说明书归档于 `report/continuum/legacy_before_sign_fix/`。符号正确与模态精度达标是不同检查项；16 阶臂端静挠度仍有约 1.6–1.7% 截断误差。
