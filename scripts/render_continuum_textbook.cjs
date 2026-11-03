// Dependencies: mathjax-full 3.2.2, playwright. Override paths for other machines.
const fs=require('fs'),path=require('path');
const mjroot=process.env.MATHJAX_ROOT||'/tmp/continuum-mathjax/node_modules/mathjax-full';
const {mathjax}=require(mjroot+'/js/mathjax.js');
const {TeX}=require(mjroot+'/js/input/tex.js');
const {SVG}=require(mjroot+'/js/output/svg.js');
const {liteAdaptor}=require(mjroot+'/js/adaptors/liteAdaptor.js');
const {RegisterHTMLHandler}=require(mjroot+'/js/handlers/html.js');
const {AllPackages}=require(mjroot+'/js/input/tex/AllPackages.js');
const {chromium}=require(process.env.PLAYWRIGHT_ROOT||'/Users/hesong/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const root=path.resolve(__dirname,'..'),data=JSON.parse(fs.readFileSync(root+'/report/continuum/textbook/content.json'));
const adaptor=liteAdaptor();RegisterHTMLHandler(adaptor);
const doc=mathjax.document('',{InputJax:new TeX({packages:AllPackages}),OutputJax:new SVG({fontCache:'none'})});
const esc=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
let eqno=0;const diagnostics=[];
for(const p of data)for(const i of p.items)if(i.type==='eq'){
 const node=doc.convert(i.tex,{display:true,em:18,ex:9,containerWidth:650});
 let s=adaptor.outerHTML(node);if(s.includes('data-mjx-error'))throw Error(i.tex+' '+s);
 const w=parseFloat(s.match(/width="([\d.]+)ex"/)[1])*8.3,h=parseFloat(s.match(/height="([\d.]+)ex"/)[1])*8.3;
 const scale=Math.min(1,610/w);i.eqno=++eqno;diagnostics.push({n:eqno,width:w,scale,tex:i.tex});
 s=s.replace(/width="[\d.]+ex"/,`width="${w*scale}px"`).replace(/height="[\d.]+ex"/,`height="${h*scale}px"`);
 i.svg=s;
}
fs.writeFileSync(root+'/tmp/pdfs/continuum/textbook/formula_metrics.json',JSON.stringify(diagnostics,null,2));
const css=`@font-face{font-family:CJK;src:url('file:///Library/Fonts/Arial Unicode.ttf')}*{box-sizing:border-box} @page{size:A4;margin:0}body{margin:0;color:#182b40;font-family:CJK,'Arial Unicode MS',sans-serif;font-size:10.5pt}.sheet{width:210mm;height:297mm;padding:17mm 18mm 18mm;position:relative;page-break-after:always;overflow:hidden}.sheet:last-child{page-break-after:auto}.content{height:255mm}.header{font-size:8pt;color:#55758c;letter-spacing:1px;border-bottom:1px solid #c6d4df;padding-bottom:7px;margin-bottom:17px}h1{font-size:20pt;line-height:1.4;margin:0 0 15px;color:#183c58}p{line-height:1.65;margin:10px 0;text-align:justify;overflow-wrap:anywhere}.equation{position:relative;text-align:center;margin:17px 0;padding-right:27px;break-inside:avoid;line-height:0;color:#111}.eqn{position:absolute;right:0;top:50%;font-family:serif;font-size:9pt;line-height:1;color:#526575}mjx-container{margin:0!important;display:inline-block!important}svg{max-width:100%;vertical-align:middle}.footer{position:absolute;bottom:10mm;left:18mm;right:18mm;display:flex;justify-content:space-between;font-size:8pt;color:#617486;border-top:1px solid #c6d4df;padding-top:6px}table{border-collapse:collapse;width:100%;font-size:9.4pt;line-height:1.55;margin:15px 0;table-layout:auto}th{background:#e9f0f5;color:#173a55;text-align:left}td,th{border-bottom:1px solid #d5e0e8;padding:7px 8px;vertical-align:top}tr:nth-child(2n){background:#f7f9fb}pre{font-family:monospace;font-size:9pt;line-height:1.65;padding:13px;background:#eff4f8;white-space:pre-wrap;overflow-wrap:anywhere}figure{margin:15px 0;text-align:center}figure img{max-width:100%;max-height:340px;object-fit:contain}figcaption{font-size:9pt;line-height:1.5;color:#536d81;margin-top:8px}.cover h1{font-size:30pt;line-height:1.55;margin-top:70px}.cover p{font-size:12pt;line-height:1.9;margin:23px 0}.cover .equation{margin:40px 0}.compact{font-size:10pt}.compact p{line-height:1.55}.compact .equation{margin:12px 0}.compact table{font-size:9pt}.compact td,.compact th{padding:5px 7px}`;
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_PATH||'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
 for(let lang=0;lang<2;lang++){
  let html='<!doctype html><html lang="'+(lang?'ja':'zh-CN')+'"><meta charset="utf-8"><title>'+data[0].title[lang]+'</title><style>'+css+'</style><body>';
  for(let k=0;k<data.length;k++){
   const p=data[k];html+=`<section class="sheet ${k===0?'cover':''}"><div class="content"><div class="header">CONTINUUM + ANCF / ${lang?'詳細導出・数値検証':'完整推导与数值验证'}</div><h1>${esc(p.title[lang])}</h1>`;
   for(const i of p.items){
    if(i.type==='p')html+='<p>'+esc(i.text[lang]).replaceAll('\n','<br>')+'</p>';
    if(i.type==='eq')html+=`<div class="equation" data-eq="${i.eqno}">${i.svg}<span class="eqn">(${i.eqno})</span></div>`;
    if(i.type==='table')html+='<table><thead><tr>'+i.headers[lang].map(x=>'<th>'+esc(x)+'</th>').join('')+'</tr></thead><tbody>'+i.rows.map(r=>'<tr>'+r[lang].map(x=>'<td>'+esc(x)+'</td>').join('')+'</tr>').join('')+'</tbody></table>';
    if(i.type==='code')html+='<pre>'+esc(i.text)+'</pre>';
    if(i.type==='img')html+='<figure><img src="data:image/png;base64,'+fs.readFileSync(i.path).toString('base64')+'"><figcaption>'+esc(i.text[lang])+'</figcaption></figure>';
   }
   html+=`</div><div class="footer"><span>2026-11-03 · ${lang?'符号修正後のモデル':'符号修正后模型'}</span><span>${k+1} / ${data.length}</span></div></section>`;
  }
  html+='</body></html>';const tag=lang?'ja':'zh',dest=root+'/report/continuum/textbook/textbook_'+tag+'.html';fs.writeFileSync(dest,html);
  const tab=await browser.newPage();await tab.goto('file://'+dest);await tab.evaluate(()=>document.fonts.ready);
  const fits=await tab.evaluate(()=>Array.from(document.querySelectorAll('.sheet')).map((s,i)=>{
   const content=s.querySelector('.content');const bottom=()=>Math.max(...Array.from(content.children).map(e=>e.getBoundingClientRect().bottom));
   if(bottom()>content.getBoundingClientRect().bottom)s.classList.add('compact');
   return {page:i+1,over:bottom()-content.getBoundingClientRect().bottom,compact:s.classList.contains('compact')};
  }));
  fs.writeFileSync(root+'/tmp/pdfs/continuum/textbook/layout_'+tag+'.json',JSON.stringify(fits,null,2));
  const bad=fits.filter(x=>x.over>1);if(bad.length)throw Error(tag+' overflow '+JSON.stringify(bad));
  await tab.pdf({path:root+'/output/pdf/continuum_ancf_textbook_'+tag+'.pdf',printBackground:true,preferCSSPageSize:true});console.log(tag,JSON.stringify(fits.filter(x=>x.compact)), 'PDF generated');await tab.close();
 }
 await browser.close();
})();
