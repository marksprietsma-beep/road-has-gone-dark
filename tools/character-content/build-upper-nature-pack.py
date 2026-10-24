"""Append the bounded upper-tier Sorcerer/Druid cohort; preserve v1–v26."""
from pathlib import Path
import copy
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
p = json.loads((ROOT / 'data/rules/trhgd-character-v26.json').read_text())
p.update(pack_id='trhgd-character-v27', rules_version='27.0.0')
prov = dict(origin='Original TRHGD bounded upper-tier spell designs; no sourcebook text copied',
            license='Original project-authored content', revision='sorcerer-druid-upper-tiers')
p['provenance'] = dict(p['provenance'], revision=prov['revision'])


def row(category, identity):
    return next(r for r in p[category] if r['id'] == identity)


def const(n):
    return dict(op='const', value=n)


def spell(cls, identity, name, tier, effects, description, target='ally'):
    aid = cls + '-' + identity
    resources = {f'{cls}-slots-{tier}': 1}
    if cls == 'druid':
        pool = aid + '-prepared'
        resources[pool] = 1
        p['resources'].append(dict(id=pool, name=name+' · prepared copies', capacity=const(0),
                                   refresh='eligible_rest', prepared_ability=aid, provenance=prov))
        row('features', cls+'-casting-'+str(tier))['resources'].append(pool)
    attr = 'CHA' if cls == 'sorcerer' else 'WIS'
    p['abilities'].append(dict(id=aid, name=name, casting_class=cls, spell_tier=tier,
        cost=dict(main=1, move=0, reaction=0, resources=resources), effects=effects,
        tags=['spell', 'spontaneous' if cls=='sorcerer' else 'prepared', 'tier_'+str(tier)],
        timing=dict(kind='instant'), requirements=dict(op='attribute', id=attr, min=10+tier),
        targeting=dict(kind=target, range=0 if target=='self' else 6, radius=0),
        description=description + f' Main action; one tier{tier} slot'
        + ('; must be permanently known.' if cls=='sorcerer' else ' and prepared copy.')
        + f' Requires {attr}{10+tier}. ' + ('Self only.' if target=='self' else 'One living ally, range6 and clear sight.'),
        provenance=prov))
    row('features', cls+'-casting-'+str(tier))['abilities'].append(aid)


shells = ['refraction-shell-'+str(n) for n in range(1,4)]
for sid in shells:
    p['statuses'].append(dict(id=sid, tags=['weapon_decoy'], duration=dict(type='round', amount=2,
        expiry='global_round_start'), stacking='refresh', modifiers=[], effects=[], provenance=prov))
spell('sorcerer', 'refraction-guard', 'Refraction guard', 8,
      [dict(op='apply_status', id=sid) for sid in shells],
      'Three finite shells intercept the next three legal weapon attempts before accuracy is rolled. '
      'Each attempt removes one shell, including an attack that might have missed. No damage or hit '
      'rider is delivered. True sight bypasses shells without consuming them; spells and area effects '
      'also bypass them. All shells expire at the second global round boundary. Recasting replaces '
      'missing shells up to three, never stacks more. Shown as statuses/logs, not separate creatures.', 'self')
spell('sorcerer', 'cascade-well', 'Cascade well', 9,
      [dict(op='restore_resource', id='sorcerer-slots-4', amount=const(2)),
       dict(op='restore_resource', id='sorcerer-slots-6', amount=const(1))],
      'Convert one tier9 slot into up to two tier4 and one tier6 Sorcerer slots, each capped by its '
      'permanent capacity. No tier9, other-class slots, prepared copies, bloodline uses or psychic '
      'points recover. No spell is learned. Full lower pools waste the recovery; no refund. '
      'This finite exchange cannot recover its own cost.', 'self')
p['statuses'].append(dict(id='heartwood-renewal', tags=[], duration=dict(type='round', amount=3,
    expiry='global_round_start'), stacking='refresh', modifiers=[], effects=[],
    activation_effects=[dict(op='heal', amount=const(12))], provenance=prov))
spell('druid', 'heartwood-renewal', 'Heartwood renewal', 8,
      [dict(op='remove_status', id=sid) for sid in ['bramble-tether','winter-lock','slowed']]
      + [dict(op='apply_status', id='heartwood-renewal')],
      'Clear Bramble tether, Winter lock and Slowed, then heal12 at each target activation while '
      'the three-global-boundary boon survives. No immediate healing, resurrection or restored '
      'actions. Works on living owned creatures and persists through natural forms; transformed '
      'casters still cannot cast. Recasting refreshes duration, never multiplies ticks.')
spell('druid', 'wildheart-mantle', 'Wildheart mantle', 9,
      [dict(op='apply_status', id='bear-form')],
      'Give a willing living ally the existing large bear form for three global round boundaries: '
      'STR+4, DEX−2, existing bear claws/anatomy, suppressed weapon/armour/shield and spell/psychic/'
      'supernatural casting. Works on owned creatures without changing ownership, identity or HP. '
      'Replaces any prior form. Return to original form costs one main action; expiry also restores '
      'the original equipment. No flight, new creature or custom bear artwork is provided.')

path = ROOT / 'data/rules/trhgd-character-v27.json'
path.write_text(json.dumps(p, ensure_ascii=False, indent=2)+'\n')
pin = {key:p[key] for key in ['pack_id','schema_version','rules_version','engine_schema']}
pin['content_hash'] = hashlib.sha256(json.dumps(p, ensure_ascii=False, sort_keys=True, separators=(',',':')).encode()).hexdigest()
mp = ROOT / 'data/rules/packs.json'
manifest = json.loads(mp.read_text())
manifest['packs'] = [r for r in manifest['packs'] if r['rules_ref']['pack_id'] != p['pack_id']]
manifest['packs'].append(dict(path='res://data/rules/'+path.name, rules_ref=pin))
mp.write_text(json.dumps(manifest, indent=2)+'\n')
print(json.dumps(pin))
