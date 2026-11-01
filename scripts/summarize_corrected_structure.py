"""Summarize freshly rerun corrected-sign simulations; retain pre-fix records."""
from pathlib import Path
import csv,json,re,math
ROOT=Path(__file__).resolve().parents[1];F=ROOT/'report/continuum/structure_validation_corrected'
def read(n):
 with (F/n).open() as f:return list(csv.DictReader(f))
s=read('static_validation.csv');d=read('dynamic_validation.csv');a=read('connection_sign_audit.csv')
reg=(F/'regression/validation.txt').read_text()
assert 'ALL CHECKS PASSED' in reg
summary=json.loads((F/'default_summary.json').read_text())
last=[r for r in d if r['fine_modes']=='12'];failed=[r['quantity'] for r in last if not float(r['pass'])]
rates=[]
for case in ['1','2']:
 for lo,hi in [(4,8),(8,16)]:
  r1=next(r for r in s if r['case_id']==case and int(r['modes'])==lo);r2=next(r for r in s if r['case_id']==case and int(r['modes'])==hi)
  rates.append([case,lo,hi]+[math.log(float(r1[k])/float(r2[k]),2) for k in ['tower_error_pct','rotation_error_pct','jib_error_pct']])
with (F/'static_convergence_rates.csv').open('w') as f:
 w=csv.writer(f);w.writerow(['case','coarse','fine','tower_order','rotation_order','jib_order']);w.writerows(rates)
lines=['# 刚接符号修正与重新验证','', '日期：2026-11-02。所有动态结果均从修正后的方程重新积分，未将修正前时程取反后充当新结果。旧研究保存在 `../structure_validation/`，旧默认算例及说明书保存在 `../legacy_before_sign_fix/`。','',
'## 1. 修正内容与物理依据','',
'坐标 X 向右、Y 向下，塔身 z 从底座向上。塔顶切线为 [wT′(H),−1]，与其刚接的臂根切线应为 [1,wT′(H)]，故臂架绝对竖向位移必须是 **+ξ bη+ψ(ξ)ζ**。旧负号已统一改正。','',
'```text\nrA,Y = x bη + ψ(x)ζ\nJA,Y = [x b, ψ(x), bη + ψ′(x)ζ]\nhA,Y = 2[bη̇ + ψ′(x)ζ̇]ẋ + ψ″(x)ζ ẋ²\n```','',
'修正覆盖 `point.m` 的位置、雅可比和对流加速度，`setup.m` 的臂架分布惯性与重力，`assemble.m` 的臂端输出，以及 `plot_results.m` 的几何绘制。静态初值、约束矩阵和能量通过上述运动学自动一致更新。旧 3/4 阶分析入口也已修正并使用新输出目录。默认模态数仍为两阶，没有用增加刚度或调整荷载抵消符号错误。','',
'## 2. 独立刚接与静态验证','',
'通过对 `continuum.point` 的位置作中心差分获取臂根切线，与塔顶切线进行正交性检查。该检查独立于预期的解析雅可比。','',
'| 模态数 | 塔顶位移 m | 解析位移 m | 有符号相对误差 % | 两切线归一化内积 |','|---:|---:|---:|---:|---:|']
for r in a:lines.append(f"| {r['modes']} | {float(r['computed_tower_x_m']):.9f} | {float(r['physical_tower_x_m']):.9f} | {float(r['signed_static_error_pct']):.6f} | {float(r['normalized_tangent_dot']):.3e} |")
lines+=['','塔身现在向右挠曲，与独立物理解一致。切线内积约为 2e-13，刚接方向检查通过。有限阶幅值误差仍须单独评价。','',
'静态基准直接积分连续梁方程，不使用模态矩阵。令 a 为固定小车坐标，P=(mT+mP+ρAL)g，w=μJg，M=wB²/2+Pa：','',
'```text\nu(z) = Mz²/(2 EI_T)\nu′(H) = MH/EI_T\nv_w(ξ) = wξ²(6B²−4Bξ+ξ²)/(24 EI_J)\nv_P(ξ) = Pξ²(3a−ξ)/(6 EI_J),  ξ≤a\nv_P(ξ) = Pa²(3ξ−a)/(6 EI_J),  ξ>a\nv_abs(ξ) = ξu′(H)+v_w(ξ)+v_P(ξ)\n```','',
'工况 1：a=2 m、L=2 m；工况 2：a=2.4 m、L=1.4 m。两根梁各使用 501 个空间点检查全场。工况 2 是独立静平衡，不是把 t=10 s 的动态位置当作静态解。','',
'| 工况 | 模态数 | 塔顶位移误差 % | 塔顶转角误差 % | 臂端总挠度误差 % | 臂相对挠度全场误差 mm |','|---|---:|---:|---:|---:|---:|']
for r in s:lines.append(f"| {r['case_id']} | {r['modes']} | {float(r['tower_error_pct']):.5f} | {float(r['rotation_error_pct']):.5f} | {float(r['jib_error_pct']):.5f} | {1000*float(r['jib_relative_field_max_error_m']):.6f} |")
lines+=['','符号修正消除了方向错误，但没有消除基函数截断误差。16 阶时塔顶位移误差约 0.050%，塔顶转角误差约 2.532%，臂端总挠度误差仍约 1.63–1.68%。按 1% 工作目标，后两项尚未达标。塔顶位移约二阶收敛，转角和臂端总挠度约一阶收敛；经验阶次见 `static_convergence_rates.csv`。','',
'![修正后独立静态全场对照](independent_static_fields.png)','',
'## 3. 动态模态截断验证','',
'固定六段绳，比较每根梁 4、6、8、12 阶；时间 0–10 s，RelTol=2e-8、AbsTol=1e-10、MaxStep=0.01 s，保存 2001 个时刻。比较原始总位移、相对各阶瞬时静平衡的振动、吊载弦线摆角、吊点反力和小车驱动力。另输出 8–10 s 停机后的最大差。','',
'最大时程差除以细阶模型的峰值绝对响应，得到 peak-norm 误差；不用逐点相除。总位移、摆角、反力和驱动力采用 1% 工作阈值，分离的振动采用 5%。L2 误差同时提供，未作为本次通过判据。这些是算例工作阈值，不是行业标准。','',
'| 量 | 模态比较 | 最大差（SI） | peak-norm % | L2 % | 阈值 % | 达标 |','|---|---|---:|---:|---:|---:|---|']
for r in d:lines.append(f"| {r['quantity']} | {r['coarse_modes']}→{r['fine_modes']} | {float(r['max_abs_diff']):.6g} | {float(r['peak_relative_pct']):.5f} | {float(r['L2_relative_pct']):.5f} | {r['tolerance_pct']} | {'是' if float(r['pass']) else '否'} |")
lines+=['',f"8→12 阶时，{len(last)-len(failed)}/8 项满足判据。"+('未达标项：'+ '、'.join(failed)+'。' if failed else '相邻比较达标仍不能代替解析静态基准。'),'',
'![修正后的模态收敛](convergence.png)','',
'## 4. 回归测试','',
'完整回归重新检查静平衡、质量矩阵对称正定、约束独立性、孤立梁频率、移动吊点速度/对流加速度、加载平衡点切线对称性与频率正值、固定域能量、收绳张力/约束、时间容差和绳 3/6 单元及梁 2/3 模态敏感性。结果如下：','', '```text',reg.strip(),'```','',
'16 阶稳定振型的独立正交积分测试也通过；其解析质量、刚度积分误差约为 8e-15。能量守恒和小约束残差只证明相应数值性质，不能替代静态独立解析解和刚接几何检查。','',
'## 5. 修正后的默认算例','',f"默认两阶/三段绳的 10 s 仿真重新运行。最大弦线摆角 {summary['max_angle_deg']:.6f}°；采样最小轴力 {summary['min_axial_N']:.6f} N；最大位置约束误差 {summary['max_constraint_m']:.3e} m。塔顶位移范围 {summary['tower_range_m'][0]:.8f} 至 {summary['tower_range_m'][1]:.8f} m，臂端位移范围 {summary['jib_range_m'][0]:.8f} 至 {summary['jib_range_m'][1]:.8f} m。位移包含重力静挠度。",'',
'## 6. 适用结论与复现','',
'刚接符号和方向错误已修复，独立几何、静平衡与数值回归通过。结构模态误差仍需按量报告，不能表述为所有量已经收敛到 1%。若需要更高的结构转角/臂端挠度精度，下一步应考虑端弯矩静态修正形函数或适合连接荷载的 Ritz 基，而不只是提高积分精度。','',
'误差针对已保存时刻；未单独验证高频反力峰值的采样收敛，未对所有高阶模型重新进行时间步和绳网格联合加密。没有新增基础柔性、轴压几何刚度或实机参数识别；本次不构成实验验证。','',
'```matlab\naddpath(\'matlab\');\naudit_continuum_connection;\ntest_continuum_high_modes;\ntest_continuum_ancf;\nresult=validate_continuum_structure;\nplot_continuum_static_validation;\nout=tower_crane_continuum_ancf;\n```','',
'本目录独立保存新结果。动态缓存核对参数及 point/setup/assemble/modes/rhs/simulate/initial_state 源文件内容。该检查不覆盖所有间接依赖；更改绳单元、输入函数、模型或求解器后，请换目录或移走旧缓存再运行。']
(F/'verification_zh.md').write_text('\n'.join(lines)+'\n')
# Update bilingual manuals' result chapter from the same newly computed numbers.
for lang in ['zh','ja']:
 p=ROOT/f'report/continuum/model_manual_{lang}.md';body=p.read_text().split('## 10.')[0]
 if lang=='zh':
  tail=f"""## 10. 修正后算例与重新验证

2026-11-02 已修正塔顶—臂根的转角符号，重新运行全部算例。默认 10 s 工况最大弦线摆角为 {summary['max_angle_deg']:.6f}°，采样最小轴向力为 {summary['min_axial_N']:.6f} N，最大位置约束误差为 {summary['max_constraint_m']:.3e} m。塔顶绝对横移为 {summary['tower_range_m'][0]:.8f} 至 {summary['tower_range_m'][1]:.8f} m，臂端竖向位移为 {summary['jib_range_m'][0]:.8f} 至 {summary['jib_range_m'][1]:.8f} m，均包含静挠度。

刚接切线正交性、静平衡、质量矩阵、运动学、能量和时间/网格回归检查通过。完整数值记录见 structure_validation_corrected/regression/validation.txt。新的结构模态验证比较 4、6、8、12 阶：8→12 阶时 {8-len(failed)}/8 项满足所设工作判据。各量的完整误差和阈值见 structure_validation_corrected/verification_zh.md。

独立静力解对照表明：16 阶时塔顶位移误差约 0.050%，塔顶转角误差约 2.532%，臂端总挠度误差约 1.63–1.68%。符号修正已通过，但不能声称所有结构量已收敛至 1%。默认两阶模型仍用于演示；研究结构挠度应进一步采用静态修正基或合适的 Ritz 基。没有实机实验验证。

![修正后默认工况时程](simulation.png)

![修正后五个时刻的几何形状](geometry.png)
"""
 else:
  tail=f"""## 10. 符号修正後の結果と再検証

2026-11-02 にタワー頂部とジブ根元の回転角の符号を修正し、すべての解析を再実行した。既定の 10 s 条件で最大弦振れ角は {summary['max_angle_deg']:.6f}°、保存時刻の最小軸力は {summary['min_axial_N']:.6f} N、最大位置拘束誤差は {summary['max_constraint_m']:.3e} m である。タワー頂部の絶対横変位は {summary['tower_range_m'][0]:.8f}～{summary['tower_range_m'][1]:.8f} m、ジブ先端鉛直変位は {summary['jib_range_m'][0]:.8f}～{summary['jib_range_m'][1]:.8f} m であり、静的たわみを含む。

剛接部の接線直交性、静的平衡、質量行列、運動学、エネルギー、時間・格子の回帰検証に合格した。全記録は structure_validation_corrected/regression/validation.txt に保存した。構造モード数 4、6、8、12 を比較し、8→12 モードでは設定した判定基準を {8-len(failed)}/8 項目が満たした。各量の誤差と閾値は structure_validation_corrected/verification_zh.md を参照する。

独立静力学解との比較では、16 モードのタワー頂部変位誤差は約 0.050%、頂部回転角誤差は約 2.532%、ジブ先端総たわみ誤差は約 1.63–1.68% であった。符号修正の検証には合格したが、全構造量が 1% 以内に収束したわけではない。既定の二モードは実演用とし、構造たわみの研究では静的補正基底や適切な Ritz 基底を検討する。実機実験との検証は行っていない。

![修正後の既定条件の時刻歴](simulation.png)

![修正後の五つの時刻における形状](geometry.png)
"""
 p.write_text(body.rstrip()+'\n\n'+tail)
print(F/'verification_zh.md')
