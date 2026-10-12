"""Author GAME118 continuation without changing any previously published pack."""
import copy
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
pack = json.loads((root / 'data/rules/trhgd-character-v4.json').read_text())
pack.update(pack_id='trhgd-character-v5', rules_version='5.0.0')
provenance = {
    'origin': 'Original TRHGD tactical adaptations of generic fantasy concepts; no sourcebook prose copied',
    'license': 'Original project-authored content',
    'revision': 'game118-core-continuation-1',
}
pack['provenance'] = provenance
constant = lambda value: {'op': 'const', 'value': value}
formula = lambda op, *args: {'op': op, 'args': list(args)}
level = lambda cls: {'op': 'class_level', 'id': cls}
modifier = lambda stat, value, kind='untyped': {'stat': stat, 'type': kind, 'value': constant(value)}
unrestricted = {'op': 'all', 'args': []}


def feature(key, name, *, modifiers=(), abilities=(), resources=(), description=''):
    pack['features'].append(dict(id=key, name=name, modifiers=list(modifiers), abilities=list(abilities),
        resources=list(resources), tags=[], senses=[], hooks=[], grants=[], provenance=provenance,
        description=description))
    return key


def status(key, modifiers, rounds=3):
    pack['statuses'].append(dict(id=key, tags=[], duration=dict(type='round', amount=rounds,
        expiry='global_round_start'), stacking='refresh', modifiers=modifiers, effects=[], provenance=provenance))


def ability(key, name, effects, kind='self', distance=0, costs=None, tags=(), radius=0, description=''):
    row = dict(id=key, name=name, cost=dict(main=1, move=0, reaction=0, resources=costs or {}),
        effects=effects, tags=list(tags), timing=dict(kind='instant'), requirements=unrestricted,
        targeting=dict(kind=kind, range=distance, radius=radius), provenance=provenance, description=description)
    pack['abilities'].append(row)
    return row


def resource(key, name, capacity):
    row = dict(id=key, name=name, capacity=capacity, refresh='eligible_rest', provenance=provenance)
    pack['resources'].append(row)
    return row


def unlock(cls, key):
    next(row for row in pack['classes'] if row['id'] == cls)['features'].append(dict(at=7, id=key))


# New tier access has real resources, preparation copies, casting prerequisites and save effects.
for cls in ['wizard', 'sorcerer', 'cleric', 'druid', 'paladin', 'ranger']:
    definition = next(row for row in pack['classes'] if row['id'] == cls)
    tier = 3 if cls in ['paladin', 'ranger'] else 4
    start = 8 if cls in ['sorcerer', 'paladin', 'ranger'] else 7
    attr, mode = definition['casting_attribute'], definition['spell_mode']
    pool = f'{cls}-slots-{tier}'
    resource(pool, f'{cls.title()} tier {tier} slots', formula('max', constant(1), formula('sum',
        constant(2 if cls == 'sorcerer' else 1), formula('floor_divide', formula('sum', level(cls), constant(-start)), constant(2)),
        formula('max', constant(0), {'op': 'modifier', 'id': attr})))).update(slot_class=cls, spell_tier=tier)
    if cls in ['wizard', 'sorcerer']:
        spells = [('ice-lance', 'Ice lance', 'cold', '4d6'), ('greater-ward', 'Greater arcane ward', None, None)]
    elif cls in ['cleric', 'paladin']:
        spells = [('restoring-light', 'Restoring light', 'healing', '4d6' if tier == 4 else '3d6'), ('faith-ward', 'Ward of faith', None, None)]
    else:
        spells = [('storm-lance', 'Storm lance', 'lightning', '4d6' if tier == 4 else '3d6'), ('oak-ward', 'Oak ward', None, None)]
    granted, pools = [], [pool]
    for key, name, damage_type, dice in spells:
        sid = f'{cls}-{key}'
        if damage_type:
            effect = {'op': 'heal' if damage_type == 'healing' else 'damage', 'amount': {'dice': dice, 'bonus': constant(tier)}}
            if damage_type != 'healing':
                effect['damage_type'] = damage_type
                half = copy.deepcopy(effect)
                half['save_half'] = True
                effects = [dict(op='save', save='reflex', dc=formula('sum', constant(10+tier), {'op': 'modifier', 'id': attr},
                    {'op': 'stat', 'id': 'save_dc'}), on_failure=[effect], on_success=[half])]
            else:
                effects = [effect]
        else:
            ward = sid + '-status'
            status(ward, [modifier('defence', 4 if tier == 4 else 3, 'condition'), modifier('will', 2, 'condition')])
            effects = [dict(op='apply_status', id=ward)]
        row = ability(sid, name, effects, 'ally' if damage_type in [None, 'healing'] else 'creature', 6,
            {pool: 1}, ['spell', mode, f'tier_{tier}'], description=f'Tier {tier}: '+
            ('three-round Defence/Will ward.' if damage_type is None else 'healing bounded by maximum HP.' if damage_type == 'healing' else 'Reflex saves for half; Evasion applies.'))
        row.update(casting_class=cls, spell_tier=tier, requirements=dict(op='attribute', id=attr, min=10+tier))
        if mode == 'prepared':
            prepared = f'{cls}-prepared-{key}'
            resource(prepared, name+' prepared copies', constant(0)).update(prepared_ability=sid)
            pools.append(prepared)
            row['cost']['resources'][prepared] = 1
        granted.append(sid)
    fid = feature(f'{cls}-casting-{tier}', f'{mode.title()} {definition["casting_tradition"]} spells · tier {tier}',
        abilities=granted, resources=pools, description=f'Class {start}: new tier, individual prepared copies or persistent known repertoire, shared slots.')
    definition['features'].append(dict(at=start, id=fid))

# Signature class-seven features use existing authority/effect operators and action economy.
unlock('barbarian', feature('barbarian-veteran', 'Hardened rage veteran', modifiers=[modifier('HP', 4), modifier('fortitude', 2)], description='Maximum HP +4 and Fortitude +2; existing rage uses continue scaling.'))
unlock('fighter', feature('fighter-battle-awareness', 'Veteran battlefield awareness', modifiers=[modifier('initiative', 2, 'insight')], description='Initiative +2; select another actual bonus feat at Fighter eight.'))
status('heroic-performance', [modifier('defence', 2, 'condition'), modifier('will', 2, 'condition')])
ability('inspire-heroism', 'Inspire heroism', [dict(op='apply_status', id='heroic-performance')], 'ally', 0, {'performance': 2}, radius=3, description='All allies within three tiles: Defence and Will +2 for three rounds; costs two performance uses and one main action.')
unlock('bard', feature('bard-heroism', 'Inspire heroism', abilities=['inspire-heroism'], description='A defensive performance, distinct from Inspire Courage.'))
status('channel-sanctuary', [modifier('defence', 2, 'condition'), modifier('fortitude', 2, 'condition')])
ability('channel-sanctuary', 'Channel sanctuary', [dict(op='apply_status', id='channel-sanctuary')], 'ally', 0, {'channel': 1}, radius=3, description='One channel use and main action: nearby allies gain Defence and Fortitude +2 for three rounds.')
unlock('cleric', feature('cleric-sanctuary', 'Channel sanctuary', abilities=['channel-sanctuary']))
ability('renew-nature', 'Nature renewal', [dict(op='heal', amount=formula('multiply', constant(2), level('druid')))], costs={'wildshape': 1}, description='Spend one wild-shape use and main action to recover twice Druid level HP; cannot exceed maximum HP.')
unlock('druid', feature('druid-renewal', 'Nature renewal', abilities=['renew-nature']))
ability('wholeness', 'Wholeness of body', [dict(op='heal', amount=formula('multiply', constant(2), level('monk')))], costs={'ki': 2}, description='Two Ki and a main action restore twice Monk level HP, bounded by maximum HP.')
unlock('monk', feature('monk-wholeness', 'Wholeness of body', abilities=['wholeness']))
status('oath-shelter', [modifier('defence', 2, 'condition'), modifier('will', 3, 'condition')])
ability('oath-shelter', 'Sheltering oath', [dict(op='apply_status', id='oath-shelter')], 'ally', 0, {'smite-uses': 1}, radius=3, description='Spend one smite use and main action: nearby allies gain Defence +2 and Will +3 for three rounds.')
unlock('paladin', feature('paladin-shelter', 'Sheltering oath', abilities=['oath-shelter']))
resource('tracker-resolve', 'Tracker resolve', formula('max', constant(1), {'op': 'modifier', 'id': 'WIS'}))
status('ranger-steady', [modifier('ranged_attack', 2, 'condition'), modifier('defence', 1, 'condition')], 2)
ability('steady-aim', 'Steady aim', [dict(op='apply_status', id='ranger-steady')], costs={'tracker-resolve': 1}, description='One main action and tracker resolve: ranged attack +2 and Defence +1 for two rounds.')
unlock('ranger', feature('ranger-steady', 'Steady aim', abilities=['steady-aim'], resources=['tracker-resolve']))
status('expert-feint', [modifier('defence', -3, 'condition'), modifier('stride', -1, 'condition')], 2)
ability('expert-feint', 'Expert feint', [dict(op='apply_status', id='expert-feint')], 'creature', 1, description='Adjacent opponent: Defence −3 and movement −1 for two rounds. Main action; ally-assisted Sneak Attack continues scaling.')
unlock('rogue', feature('rogue-expert-feint', 'Expert feint', abilities=['expert-feint']))
resource('blood-surge', 'Bloodline surge', formula('max', constant(1), {'op': 'modifier', 'id': 'CHA'}))
status('blood-surge', [modifier('save_dc', 2, 'insight')], 2)
ability('blood-surge', 'Bloodline surge', [dict(op='apply_status', id='blood-surge')], costs={'blood-surge': 1}, description='A main action and bloodline use: spell save DC +2 for two rounds.')
unlock('sorcerer', feature('sorcerer-surge', 'Bloodline surge', abilities=['blood-surge'], resources=['blood-surge']))
resource('scholar-ward', 'Scholar ward', formula('max', constant(1), {'op': 'modifier', 'id': 'INT'}))
status('scholar-ward', [modifier('defence', 2, 'condition'), modifier('will', 2, 'condition')])
ability('scholar-ward', 'Scholar ward', [dict(op='apply_status', id='scholar-ward')], 'ally', 4, {'scholar-ward': 1}, description='Main action and scholar use: one ally gains Defence and Will +2 for three rounds.')
unlock('wizard', feature('wizard-scholar-ward', 'Scholar ward', abilities=['scholar-ward'], resources=['scholar-ward']))
for row in pack['classes']:
    row['max_level'] = 8
    if row['id'] == 'fighter':
        row['bonus_feat_levels'].append(8)
next(row for row in pack['resources'] if row['id'] == 'wildshape')['capacity'] = formula('max', constant(1), formula('floor_divide', level('druid'), constant(4)))

# Eight selectable feats: real prerequisites, modifiers or active attacks, no placeholder entries.
status('expertise-stance', [modifier('melee_attack', -2, 'condition'), modifier('defence', 2, 'condition')], 2)
ability('defensive-strike', 'Defensive strike', [dict(op='apply_status', id='expertise-stance', recipient='actor')], 'creature', 1, tags=['weapon_strike'], description='A weapon strike at −2 melee attack; Defence +2 for two rounds. One main action.')
status('arcane-strike', [modifier('damage', 2, 'condition')], 2)
ability('arcane-strike', 'Arcane strike', [dict(op='apply_status', id='arcane-strike', recipient='actor')], 'creature', 1, {'focus': 1}, ['weapon_strike'], description='Spend one Focus and a main action: make a melee strike and gain +2 damage for two rounds.')
for action in pack['abilities']:
    if action['id'] in ['defensive-strike', 'arcane-strike']:
        action['requirements'] = dict(op='tag', id='melee')
req = lambda op, key, value: dict(op=op, id=key) if isinstance(value, bool) else dict(op=op, id=key, min=value)
either_caster = dict(op='any', args=[req('casting', 'arcane', 1), req('casting', 'divine', 1)])
feats = [
    ('dodge', 'Dodge', [modifier('defence', 1, 'insight')], [], [], req('attribute', 'DEX', 13), 'Defence +1; requires Dexterity 13.'),
    ('mobility', 'Mobility', [modifier('stride', 1)], [], [], dict(op='all', args=[req('attribute', 'DEX', 13), req('feat', 'dodge', True)]), 'Movement +1; requires Dodge and Dexterity 13. Shared reaction remains unchanged.'),
    ('combat-expertise', 'Combat expertise', [], ['defensive-strike'], [], req('attribute', 'INT', 13), 'Unlock Defensive strike; Intelligence 13.'),
    ('endurance', 'Endurance', [modifier('HP', 4), modifier('fortitude', 1, 'insight')], [], [], unrestricted, 'Maximum HP +4 and Fortitude +1.'),
    ('spell-focus', 'Spell focus', [modifier('save_dc', 1, 'training')], [], [], either_caster, 'Spell save DC +1; requires actual arcane or divine casting. School-specific choices remain future work.'),
    ('arcane-strike', 'Arcane strike', [], ['arcane-strike'], ['focus'], req('casting', 'arcane', 1), 'Unlock a Focus-powered weapon technique; requires arcane casting.'),
    ('battle-awareness', 'Battle awareness', [modifier('initiative', 2, 'insight'), modifier('reflex', 1, 'insight')], [], [], req('attribute', 'DEX', 13), 'Initiative +2 and Reflex +1; Dexterity 13.'),
    ('veteran-weapon-training', 'Veteran weapon training', [modifier('damage', 2)], [], [], dict(op='all', args=[dict(op='bab', min=6), req('feat', 'weapon-focus', True)]), 'Weapon damage +2; requires BAB 6 and Weapon focus.'),
]
for key, name, mods, abilities, resources, requirement, description in feats:
    fid = feature(key+'-feature', name, modifiers=mods, abilities=abilities, resources=resources, description=description)
    pack['feats'].append(dict(id=key, name=name, requirements=requirement, features=[fid], repeatable=False, choice_parameters=[], provenance=provenance))

# Two more ancestry families, each with a distinct heritage. Culture is never derived from these traits.
for key, name, attributes, size, stride, skills in [
    ('goblin', 'Goblin', {'DEX': 4, 'STR': -2, 'CHA': -2}, 'small', 4, {'stealth': 2, 'perception': 1}),
    ('orc', 'Orc', {'STR': 4, 'INT': -2, 'WIS': -2, 'CHA': -2}, 'medium', 4, {'athletics': 2}),
]:
    for suffix, heritage_attrs, bonus in [('', attributes, 0), ('-cavern' if key == 'goblin' else '-highland',
            {'DEX': 2, 'CON': 2, 'STR': -2, 'CHA': -2} if key == 'goblin' else {'STR': 2, 'CON': 2, 'INT': -2, 'CHA': -2}, 2)]:
        fid = feature('ancestry-'+key+suffix, name+' inherited traits', description='Darkvision is a sense descriptor; no sunlight or world-lighting penalty is claimed.')
        pack['features'][-1]['senses'] = ['darkvision']
        mods = [modifier('HP', bonus)] if bonus else []
        if size == 'small':mods += [modifier('defence', 1), modifier('melee_attack', 1), modifier('ranged_attack', 1)]
        adjustments = ', '.join(f'{attribute} {value:+d}' for attribute, value in heritage_attrs.items())
        pack['ancestries'].append(dict(id='heritage-'+key+suffix, people_id=key, name=name+(suffix.replace('-', ' ').title() if suffix else ' Standard'),
            tags=[key, size], features=[fid], modifiers=mods, provenance=provenance, attribute_adjustments=heritage_attrs, size=size,
            skill_bonuses=skills, body_plan='humanoid', description=f'{adjustments}. {size.title()}, movement {stride}; darkvision; '+
            ', '.join(f'{skill} +{value}' for skill, value in skills.items())+('. Heritage maximum HP +2.' if bonus else '.')+' Culture remains independent; art uses a neutral fallback.'))

path = root / 'data/rules/trhgd-character-v5.json'
path.write_text(json.dumps(pack, ensure_ascii=False, indent=2)+'\n')
manifest_path = root / 'data/rules/packs.json'
manifest = json.loads(manifest_path.read_text())
manifest['packs'] = [row for row in manifest['packs'] if row['rules_ref']['pack_id'] != pack['pack_id']]
pin = {key: pack[key] for key in ['pack_id', 'schema_version', 'rules_version', 'engine_schema']}
pin['content_hash'] = hashlib.sha256(json.dumps(pack, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
manifest['packs'].append(dict(path='res://data/rules/trhgd-character-v5.json', rules_ref=pin))
manifest_path.write_text(json.dumps(manifest, indent=2)+'\n')
