"""Static independent ZIP/PE/source audit; never executes the game on this host."""
from pathlib import Path
import json,hashlib,zipfile,struct,sys
from embedded_pck import resources
root=Path(__file__).resolve().parents[3];archive=Path(sys.argv[1]);evidence=Path(sys.argv[2]);receipt=json.loads((evidence/'distribution-proof.json').read_text(encoding='utf-8'));assert receipt['acceptance_cohort']=='final-prestige'
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
 packed,resource=resources(z.read(exe))
 manifest=z.read(entry('CHARACTER-RULES-MANIFEST.json'));assert resource('data/rules/packs.json')==manifest
 assert manifest==(root/'data/rules/packs.json').read_bytes()
 core=z.read(entry('CORE-CHARACTER-CONTENT.json'));assert core==(root/'data/rules/trhgd-character-v35.json').read_bytes()
 assert resource('data/rules/trhgd-character-v35.json')==core
 packed['exact_rule_files']={}
 for row in json.loads(manifest)['packs']:
  path=row['path'].removeprefix('res://');raw=resource(path);assert raw==(root/path).read_bytes();packed['exact_rule_files'][row['rules_ref']['pack_id']]=hashlib.sha256(raw).hexdigest()
 assert len(packed['exact_rule_files'])==35
 data=json.loads(core);assert data['pack_id']=='trhgd-character-v35'
 pin=next(x['rules_ref']for x in json.loads(manifest)['packs']if x['rules_ref']['pack_id']==data['pack_id']);assert pin==receipt['rules_ref']
 assert hashlib.sha256(json.dumps(data,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()==pin['content_hash']
 review_files=[x for x in names if '/OPTIONAL-REVIEW-CAMPAIGN/'in x and x.endswith('.json')];assert len(review_files)==1
 raw_save=z.read(review_files[0]);assert hashlib.sha256(raw_save).hexdigest()==receipt['proofs']['portable']['source_save_sha256']
 save=json.loads(raw_save);assert save['mechanics']['rules_ref']==pin and len(save['party_ids'])==3
 for identity in save['party_ids']:
  record=save['mechanics']['records'][identity];assert record['rules_ref']==pin and len(record['advancement_history'])==15
 assert receipt['proofs']['portable']['exact_earned_campaign']and receipt['proofs']['portable']['clean_library_cache']
 credit_files=[x for x in names if any(s in x.rsplit('/',1)[-1].lower()for s in ['license','credits'])];assert credit_files
 assert receipt['production_launch'] and receipt['empty_path'] and receipt['separate_process_restart'] and not receipt['source_helper_override']
 result=dict(source_commit=receipt['source_commit'],archive=archive.name,sha256=sha,archive_entries=len(names),crc_integrity=True,production_machine='AMD64',bundled_nodes=nodes,node_machine='AMD64',production_executable_sha256=metadata['executable_sha256'],qa_executable_absent=True,production_embedded_pack=packed,original_earned_review_save=True,review_save_sha256=receipt['proofs']['portable']['source_save_sha256'],manifest_matches_source=True,core_matches_source=True,rules_ref=pin,licence_credit_files=len(credit_files),scope='Independent host static archive/PE/hash audit. Native game execution and empty-PATH proof are from the Windows workflow; no Linux game validation.')
(root/'docs/implementation/game123-final-prestige/evidence').mkdir(parents=True,exist_ok=True)
(root/'docs/implementation/game123-final-prestige/evidence/archive-audit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,indent=2))
