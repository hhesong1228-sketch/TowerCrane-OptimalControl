"""Build bilingual manuals with embedded CJK font and vector equations.
Requires reportlab and pypdf; run from any directory.
"""
from pathlib import Path
import re,html,unicodedata
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,Table,TableStyle,Image,PageBreak,KeepTogether,Flowable
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.utils import ImageReader
from pypdf import PdfReader
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'output/pdf'; OUT.mkdir(parents=True,exist_ok=True)
FONT='/Library/Fonts/Arial Unicode.ttf'
pdfmetrics.registerFont(TTFont('CJK',FONT))
pdfmetrics.registerFontFamily('CJK',normal='CJK',bold='CJK',italic='CJK',boldItalic='CJK')
NAVY=colors.HexColor('#18344B'); BLUE=colors.HexColor('#236B8E'); GREY=colors.HexColor('#536471')
styles={
 'body':ParagraphStyle('body',fontName='CJK',fontSize=9.5,leading=16,spaceAfter=7,wordWrap='CJK'),
 'h1':ParagraphStyle('h1',fontName='CJK',fontSize=15,leading=22,spaceBefore=15,spaceAfter=10,textColor=NAVY,keepWithNext=True,wordWrap='CJK'),
 'h2':ParagraphStyle('h2',fontName='CJK',fontSize=11,leading=17,spaceBefore=12,spaceAfter=7,textColor=BLUE,keepWithNext=True,wordWrap='CJK'),
 'eq':ParagraphStyle('eq',fontName='CJK',fontSize=11,leading=21,alignment=TA_CENTER,spaceAfter=4,wordWrap='CJK'),
 'cell':ParagraphStyle('cell',fontName='CJK',fontSize=8.3,leading=13,wordWrap='CJK'),
 'code':ParagraphStyle('code',fontName='CJK',fontSize=8.2,leading=13,wordWrap='CJK',backColor=colors.HexColor('#F0F4F6'),borderPadding=8,spaceAfter=10),
 'caption':ParagraphStyle('caption',fontName='CJK',fontSize=8.5,leading=14,alignment=TA_CENTER,textColor=GREY,spaceAfter=12),
}
# Each block is algebraically identical to its source display equation.
# Components are used for long column vectors to retain readable font sizes.
EQ=[
 ['w<sub>T</sub>(z,t) = Σ<sub>i</sub> φ<sub>i</sub>(z) η<sub>i</sub>(t)', 'w<sub>J</sub>(ξ,t) = Σ<sub>j</sub> ψ<sub>j</sub>(ξ) ζ<sub>j</sub>(t)'],
 ['r<sub>J,X</sub>(ξ) = ξ + aη', 'r<sub>J,Y</sub>(ξ) = ξbη + ψ(ξ)ζ'],
 ['F<sub>i</sub>(z) = cosh(β<sub>i</sub>z/H) − cos(β<sub>i</sub>z/H)', '− σ<sub>i</sub>[sinh(β<sub>i</sub>z/H) − sin(β<sub>i</sub>z/H)]', 'φ<sub>i</sub>(z) = F<sub>i</sub>(z) / F<sub>i</sub>(H)', 'σ<sub>i</sub> = (cosh β<sub>i</sub> + cos β<sub>i</sub>) / (sinh β<sub>i</sub> + sin β<sub>i</sub>)'],
 ['T<sub>T</sub> = ½ ∫<sub>0</sub><super>H</super> μ<sub>T</sub> ẇ<sub>T</sub><super>2</super> dz', 'T<sub>J</sub> = ½ ∫<sub>0</sub><super>B</super> μ<sub>J</sub> ṙ<sub>J</sub><super>T</super>ṙ<sub>J</sub> dξ', 'U<sub>s</sub> = ½ ∫<sub>0</sub><super>H</super> EI<sub>T</sub>(w″<sub>T</sub>)<super>2</super> dz + ½ ∫<sub>0</sub><super>B</super> EI<sub>J</sub>(w″<sub>J</sub>)<super>2</super> dξ'],
 ['J<sub>A</sub> = ∂r<sub>A</sub>/∂q<sub>s</sub>', 'ṙ<sub>A</sub> = J<sub>A</sub>q̇<sub>s</sub>,     r̈<sub>A</sub> = J<sub>A</sub>q̈<sub>s</sub> + h<sub>A</sub>'],
 ['h<sub>A,X</sub> = 0', 'h<sub>A,Y</sub> = 2[bη̇ + ψ′(x)ζ̇]ẋ + ψ″(x)ζ ẋ<super>2</super>'],
 ['r = N<sub>e</sub>e<sub>e</sub>', 'N<sub>e</sub> = [H<sub>1</sub>I<sub>2</sub>, ℓH<sub>2</sub>I<sub>2</sub>, H<sub>3</sub>I<sub>2</sub>, ℓH<sub>4</sub>I<sub>2</sub>]'],
 ['ε = ‖r<sub>s</sub>‖ − 1', 'k<sub>m</sub> = (r<sub>s,X</sub>r<sub>ss,Y</sub> − r<sub>s,Y</sub>r<sub>ss,X</sub>) / (r<sub>s</sub><super>T</super>r<sub>s</sub>)', 'U<sub>c</sub> = ½ ∫ (EAε<super>2</super> + EI<sub>c</sub>k<sub>m</sub><super>2</super>) ds'],
 ['v<sub>m</sub> = Nė + N<sub>t</sub>e', 'a<sub>m</sub> = Në + 2N<sub>t</sub>ė + N<sub>tt</sub>e'],
 ['M<sub>c</sub> = ∫ ρA N<super>T</super>N ds', 'Q<sub>ALE</sub> = ∫ ρA N<super>T</super>(2N<sub>t</sub>ė + N<sub>tt</sub>e) ds'],
 ['q = [η; ζ; x; e; r<sub>P</sub>]', 'n = n<sub>T</sub> + n<sub>J</sub> + 1 + 4(N+1) + 2'],
 ['Φ<sub>A</sub> = e<sub>top,pos</sub> − r<sub>A</sub>(q<sub>s</sub>) = 0', 'Φ<sub>B</sub> = e<sub>bottom,pos</sub> − r<sub>P</sub> = 0', 'Φ<sub>x</sub> = x − x<sub>d</sub>(t) = 0', 'Φ = [Φ<sub>A</sub>; Φ<sub>B</sub>; Φ<sub>x</sub>],     G = Φ<sub>q</sub>'],
 ['M(q,t)q̈ + G<super>T</super>λ = f(q,q̇,t),     Φ = 0'],
 ['Mq̈ + G<super>T</super>λ = f', 'Gq̈ = γ − 2αΦ̇ − β<super>2</super>Φ'],
 ['Y(u) − Y<sub>A</sub> = u + [m<sub>P</sub>gu + ρAg(L<sub>0</sub>u − u<super>2</super>/2)]/EA', 'Y<sub>s</sub> = 1 + [m<sub>P</sub>g + ρAg(L<sub>0</sub> − u)]/EA']
]
def clean(t):
 return unicodedata.normalize('NFC',t.replace('—','-').replace('–','-').replace('‑','-'))
def inline(t):
 t=t.replace('运行入口生成本目录下的', '运行入口生成 report/continuum/ 下的').replace('具体容差、时间区间和精度敏感性见同目录', '具体容差、时间区间和精度敏感性见 report/continuum/ 下的')
 t=html.escape(clean(t)).replace('ᵀ','<super>T</super>').replace('ᵢ','<sub>i</sub>')
 t=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',r'<link href="\2" color="#236B8E">\1</link>',t)
 t=re.sub(r'`([^`]+)`',r'<font color="#236B8E">\1</font>',t)
 t=re.sub(r'\*\*([^*]+)\*\*',r'<font color="#18344B">\1</font>',t)
 return t

def para(s,style='body'): return Paragraph(inline(s),styles[style])
def footer(canvas,doc):
 canvas.setStrokeColor(colors.HexColor('#D9E1E7')); canvas.line(45,40,550,40)
 canvas.setFont('CJK',8);canvas.setFillColor(GREY)
 canvas.drawString(45,27,'CONTINUUM + ANCF  |  2026-11-02')
 canvas.drawRightString(550,27,str(doc.page))

def build(lang):
 src=ROOT/f'report/continuum/model_manual_{lang}.md'; text=src.read_text()
 equations=re.findall(r'\\\[(.*?)\\\]',text,re.S); assert len(equations)==len(EQ)
 n=[0]
 def repl(m):
  k=n[0];n[0]+=1;return f'\n\n@@EQ{k}@@\n\n'
 text=re.sub(r'\\\[.*?\\\]',repl,text,flags=re.S)
 lines=text.splitlines(); story=[]
 title='连续体塔身与起重臂\nANCF 吊索耦合模型' if lang=='zh' else '連続体タワー・ジブと\nANCF 吊りロープの連成モデル'
 titleStyle=ParagraphStyle('title',fontName='CJK',fontSize=25,leading=39,textColor=NAVY,wordWrap='CJK')
 story += [Spacer(1,55),Paragraph(title.replace('\n','<br/>'),titleStyle),Spacer(1,16),para('建模、仿真与验证说明书' if lang=='zh' else 'モデル化・シミュレーション・検証説明書','h1'),para('中文版  |  2026-11-02' if lang=='zh' else '日本語版  |  2026-11-02'),Spacer(1,20)]
 brief='Euler-Bernoulli 连续梁 · 假设模态法 · ANCF / ALE-ANCF · 约束动力学' if lang=='zh' else 'Euler-Bernoulli 連続はり · 仮定モード法 · ANCF / ALE-ANCF · 拘束動力学'
 story += [para(brief),Spacer(1,20)]
 for line in lines:
  if line.startswith('## '): story.append(para(line[3:]))
 story += [Spacer(1,15),para('模型条件：二维平面、底部固支、实验室尺度演示参数。' if lang=='zh' else 'モデル条件：二次元平面、基部固定、実験室規模の例示パラメータ。'),PageBreak()]
 i=1
 while i<len(lines):
  line=lines[i].strip()
  if not line: i+=1;continue
  if line.startswith('@@EQ'):
   k=int(re.search(r'\d+',line).group()); items=[Paragraph(clean(x),styles['eq']) for x in EQ[k]]
   items.append(Paragraph(f'({k+1})',styles['caption']))
   story.append(KeepTogether([Spacer(1,5)]+items));i+=1;continue
  if line.startswith('## '):
   if line.startswith('## 10.'): story.append(PageBreak())
   story.append(para(line[3:],'h1'));i+=1;continue
  if line.startswith('### '): story.append(para(line[4:],'h2'));i+=1;continue
  if line.startswith('```'):
   block=[];i+=1
   while i<len(lines) and not lines[i].startswith('```'):block.append(lines[i]);i+=1
   # Separate paragraphs allow long code examples to split across pages.
   story.append(Paragraph('<br/>'.join(html.escape(clean(code)).replace(' ','&#160;') or '&#160;' for code in block),styles['code']))
   i+=1;continue
  if line.startswith('|'):
   rows=[]
   while i<len(lines) and lines[i].strip().startswith('|'):
    t=lines[i].strip();i+=1
    if re.match(r'^\|[-: |]+\|$',t):continue
    rows.append([para(x.strip(),'cell') for x in t.strip('|').split('|')])
   widths=[145,130,230] if len(rows[0])==3 else [305,200]
   table=Table(rows,colWidths=widths,repeatRows=1,hAlign='LEFT',rowSplitRange=(3,-3))
   table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#E7EFF5')),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6),('LINEBELOW',(0,0),(-1,0),.7,BLUE),('LINEBELOW',(0,1),(-1,-1),.3,colors.HexColor('#DBE2E8'))]))
   story.extend([table,Spacer(1,12)]);continue
  if line.startswith('!['):
   m=re.match(r'!\[(.*?)\]\((.*?)\)',line); path=src.parent/m[2]
   iw,ih=ImageReader(str(path)).getSize(); width=505; height=width*ih/iw
   story.append(KeepTogether([Image(str(path),width,height),para(m[1],'caption')]))
   i+=1;continue
  block=[line];i+=1
  while i<len(lines) and lines[i].strip() and not re.match(r'^(#|\||```|@@|!\[|\d+\. )',lines[i].strip()):block.append(lines[i].strip());i+=1
  story.append(para(' '.join(block)))
 dest=OUT/f'continuum_ancf_manual_{lang}.pdf'
 doc=SimpleDocTemplate(str(dest),pagesize=(595.28,841.89),rightMargin=45,leftMargin=45,topMargin=44,bottomMargin=55,title=title.replace('\n',' '),author='TowerCrane-OptimalControl',pageCompression=1)
 doc.build(story,onFirstPage=footer,onLaterPages=footer)
 reader=PdfReader(dest);txt='\n'.join(p.extract_text() for p in reader.pages)
 assert len(reader.pages)>5 and '2026-11-02' in txt and '1.63' in txt
 (ROOT/f'tmp/pdfs/continuum/extracted_{lang}.txt').write_text(txt)
 print(dest,len(reader.pages),'pages')
for lang in ['zh','ja']:build(lang)
