"""Independently inspect an already executed Windows package; no game execution."""
from pathlib import Path,PurePosixPath
import argparse,json,zipfile,hashlib,struct
p=argparse.ArgumentParser();p.add_argument('native',type=Path);p.add_argument('--published',type=Path);args=p.parse_args();base=args.native
proof=json.loads((base/'distribution-proof.json').read_text());archive=next((base/'distribution').rglob(proof['archive']));sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();assert sha==proof['sha256']
assert all(x['checks']>0 and x['failures']==0 for x in proof['proofs'].values())
with zipfile.ZipFile(archive)as z:
 assert z.testzip()is None;names=z.namelist();assert len(names)==len(set(names));assert all(not PurePosixPath(n).is_absolute()and'..'not in PurePosixPath(n).parts and'\\'not in n for n in names)
 assert not any('road-has-gone-dark-qa'in n for n in names)
 def one(suffix):
  hits=[n for n in names if n.endswith('/'+suffix)];assert len(hits)==1,(suffix,hits);return z.read(hits[0])
 def amd64(b):
  assert b[:2]==b'MZ';offset=struct.unpack_from('<I',b,60)[0];assert b[offset:offset+4]==b'PE\0\0'and struct.unpack_from('<H',b,offset+4)[0]==0x8664
 amd64(one('road-has-gone-dark.exe'));nodes=[n for n in names if n.endswith('/node.exe')];assert len(nodes)==1;amd64(z.read(nodes[0]))
 manifest=json.loads(one('distribution.json'));assert manifest['source_commit']==proof['source_commit'];assert hashlib.sha256(one('road-has-gone-dark.exe')).hexdigest()==manifest['executable_sha256']
 content=json.loads(one('CORE-CHARACTER-CONTENT.json'));pin=proof['rules_ref'];assert content['pack_id']==pin['pack_id']=='trhgd-character-v23'
 assert hashlib.sha256(json.dumps(content,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
 assert any('license'in n.lower()for n in names)and any('credit'in n.lower()for n in names)
images=[]
for row in proof['captures']['screenshots']:
 b=(base/'captures'/row['file']).read_bytes();assert b[:8]==b'\x89PNG\r\n\x1a\n';w,h=struct.unpack_from('>II',b,16)
 assert (w,h)==(row['width'],row['height'])and row['file'].endswith(f'-{w}x{h}.png')and hashlib.sha256(b).hexdigest()==row['sha256']
 if args.published:assert(args.published/row['file']).read_bytes()==b
 images.append(dict(file=row['file'],width=w,height=h,sha256=row['sha256']))
assert proof['empty_path']and not proof['source_helper_override']and proof['production_launch']and proof['separate_process_restart']
report=dict(source_commit=proof['source_commit'],sha256=sha,entries=len(names),zip_crc_paths_and_duplicates=True,windows_game_and_node_amd64=True,qa_executable_removed=True,exact_v23_content=True,licences_and_credits=True,all_receipts_pass=True,production_empty_path=True,images=images,published_pixels_identical=bool(args.published))
(base/'archive-audit.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
