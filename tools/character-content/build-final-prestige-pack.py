"""Bounded existing-career v35; retain every historical v1–v34 byte/pin."""
from pathlib import Path
import copy,hashlib,json,re
ROOT=Path(__file__).resolve().parents[2]
def content():
 p=json.loads((ROOT/'data/rules/trhgd-character-v34.json').read_text(encoding='utf-8'));p.update(pack_id='trhgd-character-v35',rules_version='35.0.0')
 prov=dict(origin='Original TRHGD final-prestige adaptations; no sourcebook prose copied',license='Original project-authored content',revision='game169-final-prestige-acceptance');p['provenance']=dict(p['provenance'],revision=prov['revision'])
 classes={x['id']:x for x in p['classes']};abilities={x['id']:x for x in p['abilities']};statuses={x['id']:x for x in p['statuses']};features={x['id']:x for x in p['features']}
 def const(n):return dict(op='const',value=n)
 def all_of(*args):return dict(op='all',args=list(args))
 def feature(identity,name,owned=(),resources=(),tags=(),**extra):
  row=dict(id=identity,name=name,abilities=list(owned),resources=list(resources),modifiers=[],tags=list(tags),senses=[],hooks=[],grants=[],description=name,provenance=prov);row.update(extra);p['features'].append(row);return row
 def action(identity,name,cost,effects,targeting,**extra):
  row=dict(id=identity,name=name,cost=cost,effects=effects,tags=[],timing=dict(kind='instant'),requirements=all_of(),targeting=targeting,description=name,provenance=prov);row.update(extra);p['abilities'].append(row);return row
 def paid(main=1,move=0,reaction=0,uses=1,pool='eldritch-knight-uses'):return dict(main=main,move=move,reaction=reaction,resources={pool:uses}if uses else{})
 knight=classes['eldritch-knight'];parents=[x for x in p['classes']if x.get('class_kind')=='base'and x.get('casting_tradition')=='arcane'and x.get('spell_mode')]
 knight['requirements']['args'] += [dict(op='spell_tier',id='arcane',min=3),dict(op='any',args=[all_of(dict(op='class_level',id=c['id'],min=1),dict(op='attribute',id=c['casting_attribute'],min=11))for c in parents])]
 parent_choices=[]
 for c in parents:
  marker='eldritch-parent-'+c['id'];feature(marker,'Knight casting parent: '+c['name'])
  parent_choices.append(dict(id=c['id'],name=c['name'],description='Advance only this actually existing caster once per Knight level, using its own attribute, spell choices and slots. Does not grant unrelated base-class features.',features=[marker],requirements=all_of(dict(op='class_level',id=c['id'],min=1),dict(op='attribute',id=c['casting_attribute'],min=11)),advance_casting=c['id'],progression_class='eldritch-knight'))
 knight['career_choices'][0]['options']=parent_choices
 # Existing single-target spells supply all channel effects/costs. These are
 # class-bound delivery references, never additional unique spell identities.
 def channel_effects(effects):return all(e['op']in ['damage','apply_status','remove_status','save']and not e.get('recipient')and(e['op']!='save'or channel_effects(e['on_failure'])and channel_effects(e.get('on_success',[])))for e in effects)
 reserve='eldritch-knight-battle-reserve';feature(reserve,'Battle reserve',unique_selection=True,capabilities=dict(resource_bonuses={'eldritch-knight-uses':1}))
 prior_channels=[]
 for at,tier in [(3,1),(5,2)]:
  options=copy.deepcopy(prior_channels)if at==5 else[]
  for c in parents:
   spells=sorted([a for a in list(p['abilities'])if a.get('casting_class')==c['id']and a.get('spell_tier')==tier and 'spell'in a['tags']and not a.get('channel_spell')and a['targeting']['kind']=='creature'and a['targeting'].get('radius',0)==0 and channel_effects(a['effects'])],key=lambda a:a['id'])
   for spell in spells:
    identity='eldritch-channel-'+spell['id'];fid=identity+'-feature';wrapper=copy.deepcopy(spell)
    wrapper.update(id=identity,name='Knight channel: '+spell['name'],effects=[],tags=list(dict.fromkeys(spell['tags']+['weapon_strike'])),targeting=dict(kind='creature',range=1,radius=0),requirements=all_of(dict(op='feature',id='eldritch-parent-'+c['id']),dict(op='class_level',id='eldritch-knight',min=at)),channel_spell=spell['id'],requires_melee=True,description='One ordinary proficient equipped melee strike carrying the actually selected '+c['name']+' spell. Pay the original main action, own slot and prepared copy even on a miss or decoy. Spell effects resolve only after an actual weapon hit; original saves/resistance apply. No borrowed caster pools, ranged/natural weapons or duplicate spell effect.',provenance=prov)
    p['abilities'].append(wrapper);feature(fid,wrapper['name'],[identity],unique_selection=True)
    options.append(dict(id=spell['id'],name=spell['name']+' ('+c['name']+')',description=wrapper['description'],features=[fid],requirements=all_of(dict(op='feature',id='eldritch-parent-'+c['id']),dict(op='attribute',id=c['casting_attribute'],min=10+tier))))
  if at==3:prior_channels=copy.deepcopy(options)
  options.append(dict(id='battle-reserve',name='Battle reserve (+1 capacity)',description='One additional Knight reserve capacity, recovered only by eligible rest. Keep your current spell delivery instead of selecting another channel.',features=[reserve],requirements=all_of()))
  knight['career_choices'].append(dict(id='eldritch-channel-'+str(at),name='Spellblade specialisation',at=at,options=options))
 knight['description']='Five earned Knight levels: BAB4, Spellcraft4, Weapon Focus and genuine permanent arcane tier3. Explicitly choose a usable existing arcane parent; every Knight level advances only its casting. Choose actual spell channels or finite battle reserve at3/5. Spellguard strike, armed riposte and reaction-funded bulwark compete with spells, attacks, movement and one shared reaction.';knight['provenance']=prov
 k1=abilities['eldritch-knight-power-1'];k1.update(name='Spellguard strike',cost=paid(),tags=['weapon_strike','supernatural'],requires_melee=True,description='Main action and1 Knight reserve: one ordinary equipped proficient melee strike plus a self +2 training defence ward for2 global rounds, even if the strike misses. Ward does not stack with itself. No slot/focus borrowing, ranged/natural channel or transformed-body activation.',provenance=prov)
 statuses['eldritch-knight-power-1-stance'].update(modifiers=[dict(stat='defence',type='training',value=const(2))],provenance=prov)
 k3=abilities['eldritch-knight-power-3'];k3.update(name='Ready arcane riposte',cost=paid(),effects=[dict(op='apply_status',id='eldritch-knight-power-3-stance')],tags=['supernatural'],requirements=all_of(),targeting=dict(kind='self',range=0,radius=0),description='Main action and1 reserve arm one actual melee-miss counter for2 global rounds. Requires a proficient equipped melee weapon in range when triggered, and the unspent shared reaction. Arming is consumed even if the counter misses; concealment interception is not an accuracy miss.',provenance=prov)
 statuses['eldritch-knight-power-3-stance'].update(modifiers=[],provenance=prov)
 counter=action('eldritch-knight-riposte','Arcane riposte',paid(main=0,reaction=1,uses=0),[dict(op='remove_status',id='eldritch-knight-power-3-stance',recipient='actor')],dict(kind='creature',range=1,radius=0),tags=['supernatural'],requirements=dict(op='class_level',id='eldritch-knight',min=3),trigger='melee_miss',requires_status='eldritch-knight-power-3-stance',counterattack=True)
 counter['description']=k3['description'];features['eldritch-knight-power-3-feature']['abilities'].append(counter['id'])
 k5=abilities['eldritch-knight-power-5'];k5.update(name='Instant spellguard',cost=paid(main=0,reaction=1,uses=2),effects=[dict(op='apply_status',id='eldritch-knight-power-1-stance'),dict(op='temporary_hp',amount=dict(op='sum',args=[const(4),dict(op='class_level',id='eldritch-knight')]))],tags=['supernatural'],requirements=all_of(),targeting=dict(kind='self',range=0,radius=0),description='During your activation spend the shared reaction and2 reserve, preserving main/move: self ward +2 training defence for2 global rounds and4 + Knight level temporary HP (maximum, not additive or healing). Competes with riposte, opportunity and ally-guard reactions. No out-of-turn manual interrupt; buffer persists until damage under the shared policy.',provenance=prov)
 for at in [1,3,5]:
  f=features['eldritch-knight-power-'+str(at)+'-feature'];f.update(name=abilities['eldritch-knight-power-'+str(at)]['name'],description=abilities['eldritch-knight-power-'+str(at)]['description'],resources=['eldritch-knight-uses'],provenance=prov)
 shade=classes['shadowdancer'];shade.update(description='Ten earned Shadowdancer levels: permanent level5, Stealth5 and Dodge. Main-funded weapon shroud, movement-funded slipping shroud, finite unmasking sight and a single umbral double offer real positioning/detection choices. Never invisibility, immunity, teleportation or world stealth. Supernatural activations are suppressed in transformed bodies.',provenance=prov)
 for at,name in [(1,'Shadow shroud'),(4,'Slipping shroud'),(7,'Unmasking focus'),(10,'Umbral double')]:
  a=abilities['shadowdancer-technique-'+str(at)];a.update(name=name,tags=['supernatural'],provenance=prov)
  if at==1:a['description']='Main action and1 shadow reserve:22% weapon miss chance and+1 training stride for2 global rounds; remove Slowed. Identity/position and legal hostile targeting remain visible. Direct spells bypass weapon concealment. No immunity or teleportation.'
  if at==4:a['cost']=paid(main=0,move=1,pool='shadowdancer-uses');a['description']='Movement token and1 shadow reserve, preserving main:28% weapon miss chance/+1 training stride for2 global rounds; remove Slowed. Activation is not displacement and cannot fake a moved-this-turn rider. Cannot activate after actual movement; the main-funded shroud remains an alternative.'
  if at==7:
   a['effects']=[dict(op='apply_status',id='shadowdancer-technique-7-shroud'),dict(op='remove_status',id='off-balance')];a['description']='Main action and1 shadow reserve:2-round true sight bypasses finite weapon doubles and reveals apparent effects under their existing observer rules; also remove Off-balance. Does not bypass physical blockers or ordinary weapon-concealment chance. No world vision mechanic.'
   statuses['shadowdancer-technique-7-shroud'].update(tags=['true_sight'],capabilities={},modifiers=[],provenance=prov)
  if at==10:
   a['cost']['resources']['shadowdancer-uses']=2;a['effects']=[dict(op='apply_status',id='shadowdancer-technique-10-shroud')];a['description']='Main action and2 shadow reserve: one finite umbral double and+2 training stride for2 global rounds. The first ordinary weapon attempt consumes the entire double before an accuracy roll, hit rider or counter. True sight bypasses it; direct spells also bypass it. No duplicate unit, collision, immunity or extra attack. Refreshing never adds another layer.'
   statuses['shadowdancer-technique-10-shroud'].update(tags=['weapon_decoy'],capabilities={},modifiers=[dict(stat='stride',type='training',value=const(2))],provenance=prov)
  f=features['shadowdancer-technique-'+str(at)+'-feature'];f.update(name=name,description=a['description'],provenance=prov)
 defender=classes['dwarven-defender'];defender.update(description='Ten earned Defender levels: permanent BAB5, Dwarf ancestry and Toughness. Exclusive anchored stances preserve actual armour-stacking training defence and physical resistance. Early full-turn anchoring, a movement-funded ready bulwark, extended-reach line defence and a two-use redoubt offer real trade-offs. Stance-only melee-miss counters share the one reaction with opportunity and ally guarding.',provenance=prov)
 for at,name in [(1,'Anchored guard'),(4,'Ready bulwark'),(7,'Hold the line'),(10,'Stone redoubt')]:
  a=abilities['dwarven-defender-technique-'+str(at)];a.update(name=name,cost=paid(main=0 if at==4 else 1,move=1,uses=2 if at==10 else 1,pool='dwarven-defender-uses'),provenance=prov)
  s=statuses['dwarven-defender-technique-'+str(at)+'-stance'];s.update(tags=['defender_stance'],stance_group='martial-stance',provenance=prov)
  if at in [7,10]:s['duration']['amount']=3
  if at==7:s['modifiers'].append(dict(stat='reach',type='training',value=const(1)))
  a['description']=('Movement token, preserving main'if at==4 else'Main and movement tokens')+' and'+str(2 if at==10 else 1)+' Defender reserve: exclusive immobile stance for'+str(s['duration']['amount'])+' global rounds, +'+str(s['modifiers'][0]['value']['value'])+' training defence and physical resistance'+str(s['capabilities']['resistances']['physical'])+'. '+('Threat/reach +1; choose wider coverage instead of the heavier redoubt. 'if at==7 else'')+'One shared-reaction counter after an actual incoming melee accuracy miss, only with proficient equipped melee weapon in reach/clear sight. Opportunity/guarding can consume it first; ranged, decoy and concealed attempts do not trigger it. Temporary HP remains a max buffer, never healing. No movement while active; expiry/rest restores normal mobility.'
  f=features['dwarven-defender-technique-'+str(at)+'-feature'];f.update(name=name,description=a['description'],provenance=prov)
 dcounter=action('dwarven-defender-counter','Anchored counter',paid(main=0,reaction=1,uses=0),[],dict(kind='creature',range=1,radius=0),requirements=dict(op='tag',id='defender_stance'),trigger='melee_miss',counterattack=True)
 dcounter['description']='Actual melee accuracy miss against the living anchored Defender; one ordinary proficient equipped melee counter in reach, consuming the same shared reaction as opportunity/guard. No reaction chain, ranged trigger or hit on a concealment/decoy interception.'
 features['dwarven-defender-technique-1-feature']['abilities'].append(dcounter['id'])
 for r in p['resources']:
  if r['id']in ['eldritch-knight-uses','shadowdancer-uses','dwarven-defender-uses']:r.update(name={'eldritch-knight-uses':'Spellblade reserve','shadowdancer-uses':'Shadow reserve','dwarven-defender-uses':'Defender reserve'}[r['id']],provenance=prov)
 return p

def enable_versions(text):
 text=re.sub(r'"trhgd-character-v34"(\s*)\]',r'"trhgd-character-v34","trhgd-character-v35"\1]',text)
 text=text.replace('["trhgd-character-v34","34.0.0",3]]','["trhgd-character-v34","34.0.0",3],["trhgd-character-v35","35.0.0",3]]')
 text=text.replace('pack_id=="trhgd-character-v34"','pack_id in ["trhgd-character-v34","trhgd-character-v35"]')
 text=text.replace('get("pack_id")=="trhgd-character-v34"','get("pack_id") in ["trhgd-character-v34","trhgd-character-v35"]')
 return text.replace('const NEW_PACK := "trhgd-character-v34"','const NEW_PACK := "trhgd-character-v35"')
if __name__=='__main__':
 p=content();(ROOT/'data/rules/trhgd-character-v35.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 pin={k:p[k]for k in ['pack_id','schema_version','rules_version','engine_schema']};pin['content_hash']=hashlib.sha256(json.dumps(p,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 path=ROOT/'data/rules/packs.json';m=json.loads(path.read_text(encoding='utf-8'));m['packs']=[r for r in m['packs']if r['rules_ref']['pack_id']!=p['pack_id']];m['packs'].append(dict(path='res://data/rules/trhgd-character-v35.json',rules_ref=pin));path.write_text(json.dumps(m,indent=2)+'\n',encoding='utf-8',newline='\n')
 for f in (ROOT/'scripts').rglob('*.gd'):
  before=f.read_text(encoding='utf-8');after=enable_versions(before)
  if before!=after:f.write_text(after,encoding='utf-8',newline='\n')
 print(json.dumps(pin))
