"""Static independent ZIP/PE/source audit; never executes the game on this host."""
from pathlib import Path
import json,hashlib,zipfile,struct,sys
root=Path(__file__).resolve().parents[3];archive=Path(sys.argv[1]);evidence=Path(sys.argv[2]);receipt=json.loads((evidence/'distribution-proof.json').read_text())
sha=hashlib.file_digest(archive.open('rb'),'sha256').hexdigest();assert sha==receipt['sha256'];assert Path(str(archive)+'.sha256').read_text().split()[0]==sha
with zipfile.ZipFile(archive)as z:
 assert z.testzip()is None;names=z.namelist();assert len(names)==len(set(names));assert all(not n.startswith('/') and '..'not in Path(n).parts for n in names)
 def entry(basename):
  found=[x for x in names if x.rsplit('/',1)[-1]==basename];assert len(found)==1,(basename,found);return found[0]
 def machine(name):
  b=z.read(name);assert b[:2]==b'MZ';at=struct.unpack_from('<I',b,60)[0];assert b[at:at+4]==b'PE\0\0';return struct.unpack_from('<H',b,at+4)[0]
 exe=entry('road-has-gone-dark.exe');assert machine(exe)==0x8664
 nodes=[x for x in names if x.rsplit('/',1)[-1].lower()=='node.exe'];assert nodes and all(machine(x)==0x8664 for x in nodes)
 assert not any(x.rsplit('/',1)[-1].startswith('road-has-gone-dark-qa')for x in names)
 metadata=json.loads(z.read(entry('distribution.json')));assert metadata['source_commit']==receipt['source_commit'];assert metadata['executable_sha256']==hashlib.sha256(z.read(exe)).hexdigest()
 manifest=z.read(entry('CHARACTER-RULES-MANIFEST.json'));assert manifest==(root/'data/rules/packs.json').read_bytes()
 core=z.read(entry('CORE-CHARACTER-CONTENT.json'));assert core==(root/'data/rules/trhgd-character-v32.json').read_bytes()
 data=json.loads(core);assert data['pack_id']=='trhgd-character-v32'
 pin=next(x['rules_ref']for x in json.loads(manifest)['packs']if x['rules_ref']['pack_id']==data['pack_id']);assert pin==receipt['rules_ref']
 assert hashlib.sha256(json.dumps(data,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
 credit_files=[x for x in names if any(s in x.rsplit('/',1)[-1].lower()for s in ['license','credits'])];assert credit_files
 result=dict(source_commit=receipt['source_commit'],archive=archive.name,sha256=sha,archive_entries=len(names),crc_integrity=True,production_machine='AMD64',bundled_nodes=nodes,node_machine='AMD64',production_executable_sha256=metadata['executable_sha256'],qa_executable_absent=True,manifest_matches_source=True,core_matches_source=True,rules_ref=pin,licence_credit_files=len(credit_files),scope='Independent host static archive/PE/hash audit. Native game execution and empty-PATH proof are from the Windows workflow; no Linux game validation.')
(root/'docs/implementation/game123-ranger-steward/evidence').mkdir(parents=True,exist_ok=True)
(root/'docs/implementation/game123-ranger-steward/evidence/archive-audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
