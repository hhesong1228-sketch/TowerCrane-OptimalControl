# PPT 仿真动画

- `tower_crane_simulation.mp4`：推荐插入 PowerPoint，H.264 / yuv420p，1600×900，30 fps，约 10 s，无音轨。
- `tower_crane_simulation.gif`：960×540 循环版本。
- `preview.png`：中间时刻封面。

PowerPoint：插入 → 视频 → 此设备，选择 MP4；在“播放”中选择自动或单击播放。

数据来自 `report/continuum/simulation.mat`（2026-11-04 生成的现行修正后默认算例）。动画重放已保存仿真，不重新积分。塔身与臂架采用与 MATLAB 一致的归一化悬臂梁模态，吊索由 ANCF 三次 Hermite 形函数还原。主图真实比例，右上图仅将相对初始状态的结构位移放大 10 倍；初始重力挠度保留。摆角为吊索端点连线的弦摆角。

默认模型：塔身和臂架各 2 阶模态、3 个吊索单元；演示参数未经实机标定。本动画不代表高阶模态收敛验证结果或最优控制效果。

复现：安装 numpy、scipy、matplotlib、pillow、imageio、imageio-ffmpeg，然后在项目根目录运行 `python scripts/animate_continuum.py`。数据来源散列与导出信息见 `metadata.json`。
