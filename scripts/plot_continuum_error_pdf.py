"""Vector error curves from the sign-corrected validation CSVs; no new simulations."""
import csv, math
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'report/continuum/structure_validation_corrected'
OUT=ROOT/'output/pdf/continuum_error_convergence_zh.pdf'
pdfmetrics.registerFont(TTFont('CJK','/Library/Fonts/Arial Unicode.ttf'))
def read(name):
    return [{k:(v if k=='quantity' else float(v)) for k,v in r.items()} for r in csv.DictReader((DATA/name).open())]
s=read('static_validation.csv'); d=read('dynamic_validation.csv'); diag=read('dynamic_diagnostics.csv')
assert len(s)==16 and len(d)==24 and len(diag)==4
c=canvas.Canvas(str(OUT),pagesize=(842,595));c.setTitle('连续体塔身与臂架：符号修正后误差随阶数变化');c.setAuthor('TowerCrane-OptimalControl')
colors=['#1267AD','#E07822','#599448'];page=0

def text(x,y,t,size=10,color='#243448'):
    c.setFillColor(color);c.setFont('CJK',size);c.drawString(x,y,t)
def start(title,sub):
    global page
    page+=1;text(38,559,title,19);text(38,536,sub,9)
    c.setStrokeColorRGB(.82,.86,.90);c.line(38,524,804,524)
def finish(note):
    text(38,45,note,8);text(38,27,'2026-11-02 | 修正符号后数据 | 连线仅引导视线，不表示新增计算点',8)
    text(775,27,f'{page} / 7',8);c.showPage()
def chart(box,title,x,series,unit,threshold=None,labels=None):
    left,bottom,width,height=box
    text(left,bottom+height-14,title,12)
    # series = (legend, values)
    vals=[v for _,ys in series for v in ys]+([] if threshold is None else [threshold])
    assert all(math.isfinite(v) and v>0 for v in vals)
    lo=math.floor(math.log10(min(vals)));hi=math.ceil(math.log10(max(vals)))
    if lo==hi:hi+=1
    px=left+51;py=bottom+43;pw=width-70;ph=height-103
    def X(v):return px+(v-min(x))/(max(x)-min(x))*pw
    def Y(v):return py+(math.log10(v)-lo)/(hi-lo)*ph
    text(px,py+ph+8,unit+'（对数轴）',8)
    for e in range(lo,hi+1):
        yy=Y(10**e);c.setStrokeColorRGB(.88,.90,.93);c.setLineWidth(.5);c.line(px,yy,px+pw,yy)
        text(left+6,yy-3,f'1e{e:+d}',8)
    for i,v in enumerate(x):
        xx=X(v);c.setStrokeColorRGB(.90,.92,.94);c.line(xx,py,xx,py+ph)
        text(xx-10,py-14,labels[i] if labels else str(int(v)),8)
    text(px+pw*.32,py-31,'比较阶数' if labels else '每根梁保留模态数 N',8)
    if threshold:
        c.setStrokeColorRGB(.65,.25,.28);c.setDash(4,3);c.line(px,Y(threshold),px+pw,Y(threshold));c.setDash()
        text(px+pw-69,Y(threshold)+4,f'判据 {threshold:g}%',8,'#A54047')
    for j,(name,ys) in enumerate(series):
        c.setStrokeColor(colors[j]);c.setFillColor(colors[j]);c.setLineWidth(1.5)
        p=c.beginPath();p.moveTo(X(x[0]),Y(ys[0]))
        for xx,yy in zip(x[1:],ys[1:]):p.lineTo(X(xx),Y(yy))
        c.drawPath(p)
        for xx,yy in zip(x,ys):c.circle(X(xx),Y(yy),2.4,fill=1,stroke=0)
        text(left+12+j*(width/2),bottom+height-34,name,8,colors[j])
        # Explicit terminal values in legend avoid collisions between near-equal curves.
        text(left+12+j*(width/2),bottom+height-46,f'末点 {ys[-1]:.4g}',8,colors[j])

static=[('tower_error_pct','塔顶位移相对误差','%',1,1),('rotation_error_pct','塔顶转角相对误差','%',1,1),('jib_error_pct','臂端总挠度相对误差','%',1,1),('tower_field_max_error_m','塔身全场最大绝对误差','mm',1000,None),('jib_field_max_error_m','臂架总挠度全场最大绝对误差','mm',1000,None),('jib_relative_field_max_error_m','臂架相对挠度全场最大绝对误差','mm',1000,None)]
for group in range(2):
    start('静态对照 | '+('相对误差' if group==0 else '全场绝对误差'),'基准：独立连续梁解析解；工况 1：小车 2 m、绳长 2 m；工况 2：小车 2.4 m、绳长 1.4 m。')
    for j,(key,title,unit,scale,tol) in enumerate(static[group*3:group*3+3]):
        rows=[[r for r in s if r['case_id']==i] for i in [1,2]]
        chart((38+j*259,91,248,414),title,[r['modes'] for r in rows[0]],[(f'工况 {i+1}',[r[key]*scale for r in a]) for i,a in enumerate(rows)],unit,tol)
    finish('相对误差 = |模态解 - 解析解| / |解析解| × 100%；全场误差取 501 个空间点中的最大绝对差。')
quant=[('tower_total','塔顶总位移','mm',1000),('jib_total','臂端总位移','mm',1000),('tower_vibration','塔顶振动分量','mm',1000),('jib_vibration','臂端振动分量','mm',1000),('payload_angle','吊重摆角','deg',180/math.pi),('support_x','支承水平力','N',1),('support_y','支承竖向力','N',1),('trolley_drive','小车驱动力','N',1)]
for absolute in [False,True]:
    for group in range(2):
        start('动态截断比较 | '+('最大绝对差' if absolute else '相对差异')+f'（{group+1}/2）','同一 0-10 s 算例、6 个吊索单元；横轴位置为较低阶数 N，标签表示实际比较的两组阶数。')
        for j,(key,title,unit,scale) in enumerate(quant[group*4:group*4+4]):
            a=[r for r in d if r['quantity']==key];x=[r['coarse_modes'] for r in a]
            series=[('全时段最大绝对差',[r['max_abs_diff']*scale for r in a])] if absolute else [('峰值归一化差异',[r['peak_relative_pct'] for r in a]),('L2 相对差异',[r['L2_relative_pct'] for r in a])]
            chart((38+(j%2)*389,80+(1-j//2)*217,373,211),title,x,series,unit if absolute else '%',None if absolute else a[0]['tolerance_pct'],[f'{int(r["coarse_modes"])}→{int(r["fine_modes"])}' for r in a])
        finish('相邻阶数差异不是解析误差；阶数间隔不同，不能据此拟合收敛阶。判据仅用于峰值归一化差异，L2 曲线供参考。')
start('数值约束与求解残差 | 随模态阶数变化','辅助诊断：用于检查积分与约束精度，不作为结构模态截断误差，也不要求随阶数单调下降。')
for j,(key,title,unit) in enumerate([('max_position_constraint_m','位置约束最大残差','m'),('max_velocity_constraint_m_s','速度约束最大残差','m/s'),('max_dynamic_residual','动力学方程最大残差','原始方程单位')]):
    chart((38+j*259,147,248,350),title,[r['modes'] for r in diag],[('全时段最大值',[r[key] for r in diag])],unit)
text(49,117,'结论：8→12 阶有 6/8 项通过判据；臂端总位移 1.139%、小车驱动力 1.299%，尚未达到 1%。',11)
text(49,94,'16 阶静态臂端总挠度误差仍为 1.63%-1.68%；符号修正并不等于截断误差全部达标。',10)
finish('数据来源：report/continuum/structure_validation_corrected/ 下 static_validation、dynamic_validation、dynamic_diagnostics.csv。')
c.save()
print(OUT)
