"""Append GAME-150's bounded original repertoire; never rewrite published packs."""
from pathlib import Path
import copy
import hashlib
import json

root = Path(__file__).resolve().parents[2]
p = json.loads((root / 'data/rules/trhgd-character-v22.json').read_text())
p.update(pack_id='trhgd-character-v23', rules_version='23.0.0')
prov = dict(origin='Original TRHGD upper-tier tactical adaptations; no sourcebook prose copied',
            license='Original project-authored content', revision='game150-upper-prepared')
p['provenance'] = dict(p['provenance'], revision=prov['revision'])

def row(category, identity):
    return next(r for r in p[category] if r['id'] == identity)

def const(n):
    return dict(op='const', value=n)

def remove(identity):
    return dict(op='remove_status', id=identity)

def status(identity, rounds, *, tags=None, capabilities=None, activation=False, periodic=False):
    record = dict(id=identity, tags=tags or [], stacking='refresh', modifiers=[], effects=[],
                  duration=dict(type='activation' if activation else 'round', amount=rounds,
                                expiry='target_activation_end' if activation else 'global_round_start'),
                  provenance=prov)
    if capabilities:
        record['capabilities'] = capabilities
    if periodic:
        record['activation_effects'] = [dict(op='heal', amount=const(12))]
    p['statuses'].append(record)
    return dict(op='apply_status', id=identity)

def save(tier, effects):
    return dict(op='save', save='will',
                dc=dict(op='sum', args=[const(10+tier), dict(op='modifier', id='INT'),
                                       dict(op='stat', id='save_dc')]),
                on_failure=effects, on_success=[])

def spell(cls, identity, name, tier, effects, description, *, enemy=False, radius=0):
    identity = cls + '-' + identity
    pool = identity + '-prepared'
    ability = dict(id=identity, name=name, casting_class=cls, spell_tier=tier,
                   cost=dict(main=1, move=0, reaction=0,
                             resources={cls+'-slots-'+str(tier): 1, pool: 1}),
                   effects=effects, tags=['spell', 'prepared', 'tier_'+str(tier)],
                   timing=dict(kind='instant'),
                   requirements=dict(op='attribute', id='INT' if cls == 'wizard' else 'WIS', min=10+tier),
                   targeting=dict(kind='creature' if enemy else 'ally', range=6, radius=radius),
                   description=description + f' Main action, one tier{tier} slot and prepared copy; '
                   + ('INT' if cls == 'wizard' else 'WIS') + str(10+tier)
                   + f'. Range6/clear sight, radius{radius}; area targets share the centre team.',
                   provenance=prov)
    p['abilities'].append(ability)
    p['resources'].append(dict(id=pool, name=name+' · prepared copies', capacity=const(0),
                               refresh='eligible_rest', prepared_ability=identity, provenance=prov))
    access = row('features', cls+'-casting-'+str(tier))
    access['abilities'].append(identity)
    access['resources'].append(pool)
    access['description'] = 'Shared tier slots and selected prepared copies; actual casting attribute required.'

boons = ['warded', 'haste', 'wizard-greater-ward-status', 'cleric-faith-ward-status',
         'perfect-shadow', 'beguiling-veil', 'runic-shell', 'spirit-shelter', 'spirit-lattice',
         'lucid-poise', 'sovereign-clarity', 'elemental-covenant', 'company-veil', 'freedom-path',
         'concord-release', 'renewing-benediction']
spell('wizard', 'unweaving-tide', 'Unweaving tide', 8, [save(8, [remove(s) for s in boons])],
      'Each enemy saves Will separately against removal of the sixteen listed temporary boons, '
      'including the new divine protection/regeneration. No damage, ancestry suppression, '
      'form removal or universal dispel. Broadens the existing single-target unravelling family.',
      enemy=True, radius=1)
lattice = status('stillness-lattice', 1, tags=['main_action_suppressed'], activation=True)
spell('wizard', 'stillness-lattice', 'Stillness lattice', 9, [save(9, [lattice])],
      'Will negates loss of the next main action for one target activation. Movement and the shared '
      'reaction remain available. A prior allied cleanse/immunity prevents the loss; expiry does not '
      'refund an already prevented action. No damage or immobilisation.', enemy=True)
conditions = ['stillness-lattice', 'dissonant-seal', 'gravitic-snare', 'slowed', 'off-balance']
release = status('concord-release', 2, capabilities=dict(immunities=conditions))
spell('cleric', 'concord-release', 'Concord of release', 8,
      [remove(s) for s in conditions] + [release],
      'Allies clear the five listed action, casting, movement and balance conditions and resist their '
      'reapplication for two global round boundaries. No HP, slots or action tokens are restored. '
      'This is timely control prevention, not another burst-healing spell.', radius=1)
renewal = status('renewing-benediction', 3, periodic=True)
spell('cleric', 'renewing-benediction', 'Renewing benediction', 9,
      [dict(op='heal', amount=const(20)), renewal],
      'Living allies heal20 now, then12 at each of their own activation starts while the three-global-'
      'boundary boon remains. Healing is capped by actual HP; dead/downed units receive no activation '
      'healing. Unweaving tide can dispel it. No resurrection, slot recovery or additional actions.', radius=1)

# v23 fixes permanent domain lineage; historical v22 cross-domain choices stay valid.
for option in row('classes', 'cleric')['career_choices'][1]['options']:
    option['requirements'] = dict(op='feature', id='cleric-'+option['id']+'-1-feature')

# An allied ward's buffer belongs to that ally, not secretly to its caster.
for cls, branch in [('wizard', 'abjuration'), ('cleric', 'war')]:
    ability = row('abilities', f'{cls}-{branch}-6')
    for effect in ability['effects']:
        if effect['op'] == 'temporary_hp':
            effect.pop('recipient', None)
    ability['description'] += ' The selected ally receives both the ward and the class-level temporary HP; the caster gains none unless self-targeted.'
for cls in ['wizard', 'cleric']:
    for group in row('classes', cls)['career_choices']:
        for option in group['options']:
            acts = [row('abilities', aid) for fid in option['features'] for aid in row('features', fid)['abilities']]
            if acts:
                option['description'] = ' '.join(a['description'] for a in acts)
                if group['at'] > 1:
                    option['description'] += ' Requires the original matching school/domain selection.'

path = root / 'data/rules/trhgd-character-v23.json'
path.write_text(json.dumps(p, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
pin = {k:p[k] for k in ['pack_id', 'schema_version', 'rules_version', 'engine_schema']}
pin['content_hash'] = hashlib.sha256(json.dumps(p, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
mp = root / 'data/rules/packs.json'
m = json.loads(mp.read_text())
m['packs'] = [x for x in m['packs'] if x['rules_ref']['pack_id'] != p['pack_id']] + [dict(path='res://data/rules/'+path.name, rules_ref=pin)]
mp.write_text(json.dumps(m, indent=2)+'\n')
print(json.dumps(pin))
