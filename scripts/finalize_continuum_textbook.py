"""Add navigation, verify bilingual parity and retain reproducible source hashes."""
from pathlib import Path
from pypdf import PdfReader,PdfWriter
import json,hashlib
R=Path(__file__).resolve().parents[1];pages=json.loads((R/'report/continuum/textbook/content.json').read_text())
for lang,col in [('zh',0),('ja',1)]:
 path=R/f'output/pdf/continuum_ancf_textbook_{lang}.pdf'
 reader=PdfReader(path);assert len(reader.pages)==len(pages)==31
 writer=PdfWriter();writer.clone_document_from_reader(reader)
 for i,page in enumerate(pages):writer.add_outline_item(page['title'][col],i)
 writer.add_metadata({'/Title':pages[0]['title'][col],'/Author':'TowerCrane-OptimalControl','/Subject':'Complete derivation, expanded matrices and corrected numerical validation; 2026-11-03'})
 temp=path.with_suffix('.tmp.pdf')
 with temp.open('wb') as f:writer.write(f)
 temp.replace(path)
 r=PdfReader(path);texts=[p.extract_text() for p in r.pages]
 assert len(r.outline)==31
 assert all(not any(c in t for c in ['\ufffd','\u25a0']) for t in texts)
 (R/f'tmp/pdfs/continuum/textbook/extracted_{lang}.txt').write_text('\n'.join(texts))
 for k in range(1,93):assert f'({k})' in ''.join(texts), (lang,k)
 print(lang, '31 pages, 31 bookmarks, 92 equation numbers verified')
paths=[*sorted((R/'matlab/+continuum').glob('*.m')),*sorted((R/'matlab/+aleancf').glob('*.m')),R/'matlab/+flexcrane/inputs.m',R/'matlab/+flexcrane/parameters.m',*sorted((R/'report/continuum/structure_validation_corrected').glob('*.csv'))]
manifest={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
(R/'report/continuum/textbook/source_sha256.json').write_text(json.dumps(manifest,indent=2))
