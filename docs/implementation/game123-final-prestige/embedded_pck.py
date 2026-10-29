"""Read the production executable's embedded Godot4.6 PCK; no game execution.
Directory layout follows Godot4.6.3 core/io/file_access_pack.cpp (v3 format).
This independent delivery audit verifies shipping resources, not just QA resources.
"""
import hashlib,struct

def resources(binary):
 assert binary[:2]==b'MZ';pe=struct.unpack_from('<I',binary,60)[0];assert binary[pe:pe+4]==b'PE\0\0'
 count=struct.unpack_from('<H',binary,pe+6)[0];optional=struct.unpack_from('<H',binary,pe+20)[0];sections=[]
 for i in range(count):
  at=pe+24+optional+40*i
  if binary[at:at+8].rstrip(b'\0')==b'pck':sections.append(struct.unpack_from('<II',binary,at+16))
 assert len(sections)==1,'One embedded production PCK section is required'
 size,start=sections[0];assert start+size<=len(binary)
 magic,version,major,minor,patch,flags,base,directory=struct.unpack_from('<6I2Q',binary,start)
 assert magic==0x43504447 and version==3 and (major,minor,patch)==(4,6,3)and flags==2
 base+=start;pos=start+directory;count=struct.unpack_from('<I',binary,pos)[0];pos+=4;assert 0<count<100000
 entries={}
 for i in range(count):
  length=struct.unpack_from('<I',binary,pos)[0];pos+=4;assert 0<length<65536
  path=binary[pos:pos+length].rstrip(b'\0').decode('utf-8').removeprefix('res://');pos+=length
  offset,length,digest,entry_flags=struct.unpack_from('<QQ16sI',binary,pos);pos+=36;offset+=base
  assert path not in entries and not path.startswith('/')and '..'not in path.split('/')and start<=offset<=offset+length<=start+size
  entries[path]=(offset,length,digest,entry_flags)
 def read(path):
  offset,length,digest,entry_flags=entries[path];assert entry_flags==0,'Audit expects original unencrypted full resources'
  raw=binary[offset:offset+length];assert hashlib.md5(raw).digest()==digest,'Embedded resource integrity failure: '+path
  return raw
 project=read('project.binary')
 assert b'res://scenes/intro/intro_sequence.tscn'in project and b'res://tests/final_prestige/review.tscn'not in project,'Shipping executable must use the original game entry point'
 return dict(pack_version=version,engine=[major,minor,patch],files=count,embedded_offset=start,production_entry_verified=True),read
