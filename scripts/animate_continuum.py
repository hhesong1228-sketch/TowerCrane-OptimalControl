"""Render corrected MATLAB continuum simulation to PowerPoint-ready MP4 and GIF.
Run: python scripts/animate_continuum.py
Dependencies: numpy scipy matplotlib pillow imageio imageio-ffmpeg
"""
from pathlib import Path
import os, hashlib, json, argparse
parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['zh', 'ja'], default='zh')
parser.add_argument('--emphasis', action='store_true', help='Title-free layout with amplified motion')
ARGS = parser.parse_args()
LANG = ARGS.lang
EMPHASIS = ARGS.emphasis
JA = {
'柔性塔吊 · 耦合动力学仿真': '柔軟タワークレーンの連成動力学シミュレーション',
'连续体塔身 / 起重臂 + ALE–ANCF 吊索    |    刚接符号修正后的默认算例': '連続体タワー・ジブ + ALE–ANCF ロープ  |  剛接合部の符号修正後の標準ケース',
'水平位置 x / m': '水平位置 x / m',
'距塔顶向下 y / m': 'タワー頂部から下向き y / m',
'未变形参考': '無変形時の形状',
'柔性塔身 / 起重臂': '柔軟タワー・ジブ',
'柔性吊索': '柔軟ロープ',
'整体运动 · 真实位移比例': '全体の運動・変位倍率 1 倍',
'相对初始构形的结构振动 ×10': '初期形状からの振動変位 ×10',
'仿真时间 / s': 'シミュレーション時間 / s',
'吊物弦摆角 / °': '吊荷の振れ角（弦角）/ °',
'10 s 实际仿真时程  ·  实时播放  ·  默认 2 阶塔身 + 2 阶臂架 / 3 个吊索单元  ·  示范参数，未经实机标定': '10 秒間の応答を等速再生  ·  タワー・ジブ各 2 モード / ロープ 3 要素  ·  例示用パラメータ（実機未同定）',
}
def translate(text):
    return JA.get(text, text) if LANG == 'ja' else text
os.environ.setdefault('MPLCONFIGDIR', '/tmp/crane-mpl')
import numpy as np
from scipy.io import loadmat
from scipy.optimize import brentq
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties
import imageio.v2 as imageio
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'report/continuum/simulation.mat'
OUT=ROOT/'presentation/animation'
if LANG == 'ja': OUT = OUT/'ja'
if EMPHASIS: OUT = OUT.parent/(OUT.name+'_clear')
OUT.mkdir(exist_ok=True,parents=True)
o=loadmat(SRC,simplify_cells=True)['out']; p=o['p']; c=o['c']; t=o['t']
idx=lambda k: np.atleast_1d(c[k]).astype(int)-1
q=o['z'][:,:int(c['n'])]; it,ij,ie,ip=map(idx,['it','ij','ie','ip']); ix=int(c['ix'])-1

def modes(x,L,n):
    cols=[]
    for k in range(1,n+1):
        b=brentq(lambda b: np.cos(b)+1/np.cosh(b),(k-.5)*np.pi-.5,(k-.5)*np.pi+.5)
        sigma=(np.cosh(b)+np.cos(b))/(np.sinh(b)+np.sin(b))
        def f(z): return np.cosh(z)-sigma*np.sinh(z)-np.cos(z)+sigma*np.sin(z)
        cols.append(f(b*np.asarray(x)/L)/f(b))
    return np.array(cols).T
z=np.linspace(0,p['H'],100); x=np.linspace(0,p['B'],100)
Pt=modes(z,p['H'],len(it)); Pj=modes(x,p['B'],len(ij))
b=[]
for k in range(1,len(it)+1):
    root=brentq(lambda a: np.cos(a)+1/np.cosh(a),(k-.5)*np.pi-.5,(k-.5)*np.pi+.5)
    sig=(np.cosh(root)+np.cos(root))/(np.sinh(root)+np.sin(root))
    tip=np.cosh(root)-sig*np.sinh(root)-np.cos(root)+sig*np.sin(root)
    b.append(root/p['H']*(np.sinh(root)-sig*np.cosh(root)+np.sin(root)+sig*np.cos(root))/tip)
b=np.array(b)
tower=q[:,it]@Pt.T
jib=(q[:,it]@b)[:,None]*x + q[:,ij]@Pj.T
assert np.allclose(tower[:,-1],o['topX'],atol=1e-10)
assert np.allclose(jib[:,-1],o['tipY'],atol=1e-10)

def rope(k):
    u=np.linspace(0,1,20); ell=o['L'][k]/p['nElem']
    h=np.array([1-3*u*u+2*u**3,ell*(u-2*u*u+u**3),3*u*u-2*u**3,ell*(-u*u+u**3)]).T
    nodes=q[k,ie].reshape(-1,2)
    return np.concatenate([h@nodes[2*e:2*e+4] for e in range(int(p['nElem']))])
for k in range(len(t)):
    r=rope(k)
    assert np.linalg.norm(r[0]-o['suspension'][k])<1e-8
    assert np.linalg.norm(r[-1]-q[k,ip])<1e-8

font='/System/Library/Fonts/STHeiti Medium.ttc'
if LANG == 'ja':
    import unicodedata
    font = next(str(f) for f in Path('/System/Library/Fonts').glob('*.ttc') if unicodedata.normalize('NFC',f.name) == 'ヒラギノ角ゴシック W3.ttc')
if Path(font).exists():
    from matplotlib import font_manager
    font_manager.fontManager.addfont(font)
    plt.rcParams['font.family']=FontProperties(fname=font).get_name()
plt.rcParams.update({'font.size':13,'axes.spines.top':False,'axes.spines.right':False,'text.color':'#19334b','axes.labelcolor':'#52667b','xtick.color':'#52667b','ytick.color':'#52667b'})
fig=plt.figure(figsize=(16,9),dpi=100,facecolor='white')
if not EMPHASIS:
    fig.text(.055,.935,translate('柔性塔吊 · 耦合动力学仿真'),fontsize=27,weight='bold')
    fig.text(.055,.89,translate('连续体塔身 / 起重臂 + ALE–ANCF 吊索    |    刚接符号修正后的默认算例'),fontsize=13,color='#63778b')
ax=fig.add_axes([.025,.10,.57,.85] if EMPHASIS else [.055,.15,.50,.68]); ax.set_aspect('equal'); ax.set_xlim(-.5,3.65); ax.set_ylim(4.15,-.35)
if EMPHASIS: ax.set_xlim(-.35,3.65)
ax.set_xlabel(translate('水平位置 x / m')); ax.set_ylabel(translate('距塔顶向下 y / m')); ax.grid(alpha=.12)
ax.plot([0,0,3],[4,0,0],color='#bdc8d2',ls='--',lw=1.8,label=translate('未变形参考'))
ax.plot([-.28,.28],[4.04,4.04],color='#19334b',lw=7)
tl,=ax.plot([],[],color='#176c92',lw=5,label=translate('柔性塔身 / 起重臂')); jl,=ax.plot([],[],color='#176c92',lw=5)
rl,=ax.plot([],[],color='#e39a2b',lw=3,label=translate('柔性吊索'))
tr,=ax.plot([],[],marker='s',ms=17 if EMPHASIS else 12,color='#19334b'); payload,=ax.plot([],[],marker='s',ms=24 if EMPHASIS else 18,color='#df674b')
ax.legend(loc='lower right',fontsize=10,frameon=False)
if not EMPHASIS: ax.set_title(translate('整体运动 · 真实位移比例'),loc='left',fontsize=15,pad=12)
zoom=fig.add_axes([.66,.59,.28,.30] if EMPHASIS else [.64,.57,.30,.24]); zoom.set_aspect('equal'); zoom.set_xlim(-.5,3.8); zoom.set_ylim(4.5,-1.1); zoom.axis('off')
zoom.plot(tower[0],4-z,color='#bfcbd4',ls='--'); zoom.plot(x+tower[0,-1],jib[0],color='#bfcbd4',ls='--')
zt,=zoom.plot([],[],lw=3,color='#176c92'); zj,=zoom.plot([],[],lw=3,color='#176c92')
if not EMPHASIS: zoom.set_title(translate('相对初始构形的结构振动 ×10'),loc='left',fontsize=14)
else: fig.text(.65,.58,'初期形状からの振動変位 ×10',fontsize=12,color='#63778b')
chart=fig.add_axes([.64,.22,.30,.24]); ang=np.rad2deg(o['theta'])
chart.plot(t,ang,color='#d3dde5',lw=2); trace,=chart.plot([],[],color='#df674b',lw=2.5); cursor=chart.axvline(0,color='#19334b',lw=1,alpha=.5)
chart.set_xlim(0,10); chart.set_ylim(-2.6,2.6); chart.set_xlabel(translate('仿真时间 / s')); chart.set_ylabel(translate('吊物弦摆角 / °')); chart.grid(alpha=.15)
clock=fig.text(.64,.93 if EMPHASIS else .84,'',fontsize=19,weight='bold'); stats=fig.text(.64,.495,'',fontsize=13)
if not EMPHASIS: fig.text(.055,.045,translate('10 s 实际仿真时程  ·  实时播放  ·  默认 2 阶塔身 + 2 阶臂架 / 3 个吊索单元  ·  示范参数，未经实机标定'),fontsize=11,color='#738497')
if EMPHASIS:
    fig.text(.055,.025,'表示倍率：初期形状からの構造変位 ×5 ／ ロープの水平振れ ×5　・　右側の数値・波形は実際の応答',fontsize=11,color='#63778b')
    trail,=ax.plot([],[],color='#df674b',alpha=.45,lw=2,ls='--',label='吊荷の軌跡')
    ax.legend(loc='lower right',fontsize=11,frameon=False)
    history=[]
fps=30; frames=[]
with imageio.get_writer(OUT/'tower_crane_simulation.mp4',fps=fps,codec='libx264',quality=8,pixelformat='yuv420p',macro_block_size=1,ffmpeg_params=['-movflags','+faststart']) as writer:
    for j,tt in enumerate(np.linspace(0,t[-1],301)):
        k=int(np.argmin(abs(t-tt))); r=rope(k)
        tl.set_data(tower[k],4-z); jl.set_data(x+tower[k,-1],jib[k]); rl.set_data(r[:,0],r[:,1]); tr.set_data([o['suspension'][k,0]],[o['suspension'][k,1]]); payload.set_data([q[k,ip[0]]],[q[k,ip[1]]])
        if EMPHASIS:
            # Amplify structural increments while keeping the rope attached to the trolley.
            tx=tower[0]+5*(tower[k]-tower[0])
            jy=jib[0]+5*(jib[k]-jib[0])
            suspension=o['suspension'][k]
            shifted=suspension+4*(suspension-np.array([q[k,ix]+tower[0,-1],q[k,ix]*(q[0,it]@b)+modes(q[k,ix],p['B'],len(ij))@q[0,ij]]).ravel())
            shown=r.copy()
            shown[:,0]=shifted[0]+5*(r[:,0]-suspension[0])
            shown[:,1]=shifted[1]+r[:,1]-suspension[1]
            tl.set_data(tx,4-z); jl.set_data(x+tx[-1],jy)
            rl.set_data(shown[:,0],shown[:,1]); tr.set_data([shifted[0]],[shifted[1]])
            payload.set_data([shown[-1,0]],[shown[-1,1]])
            history.append(shown[-1].copy()); path=np.array(history)
            trail.set_data(path[:,0],path[:,1])
        zt.set_data(tower[0]+10*(tower[k]-tower[0]),4-z)
        zj.set_data(x+tower[0,-1]+10*(tower[k,-1]-tower[0,-1]),jib[0]+10*(jib[k]-jib[0]))
        trace.set_data(t[:k+1],ang[:k+1]); cursor.set_xdata([t[k],t[k]])
        clock.set_text(f't = {tt:05.2f} s'); stats.set_text((f'トロリ x = {q[k,ix]:.2f} m   ロープ長 L = {o["L"][k]:.2f} m\n吊荷の振れ角（弦角）θ = {ang[k]:+.2f}°') if LANG == 'ja' else f'小车 x = {q[k,ix]:.2f} m     索长 L = {o["L"][k]:.2f} m\n吊物弦摆角 θ = {ang[k]:+.2f}°')
        fig.canvas.draw(); rgb=np.asarray(fig.canvas.buffer_rgba())[:,:,:3].copy(); writer.append_data(rgb)
        if j%2==0: frames.append(Image.fromarray(rgb).resize((960,540),Image.Resampling.LANCZOS))
        if j==150: Image.fromarray(rgb).save(OUT/'preview.png')
frames[0].save(OUT/'tower_crane_simulation.gif',save_all=True,append_images=frames[1:],duration=67,loop=0,optimize=False)
meta={'language': LANG, 'source':str(SRC.relative_to(ROOT)),'sha256':hashlib.sha256(SRC.read_bytes()).hexdigest(),'duration_s':10,'fps':30,'resolution':[1600,900],'samples':len(t),'max_constraint_m':float(np.max(o['constraint'])),'geometry_checks':'tower top, jib tip, cable suspension and payload endpoints match MATLAB output','magnification':('main structural increments 5x; rope horizontal offset 5x; inset 10x' if EMPHASIS else 'main 1x; inset 10x increment from initial configuration')}
(OUT/'metadata.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2))
print(json.dumps(meta,ensure_ascii=False,indent=2))
