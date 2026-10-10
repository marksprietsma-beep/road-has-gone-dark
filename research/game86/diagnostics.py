"""Small executable counterexamples, not substitutes for the grid battle batches."""
from dataclasses import asdict, dataclass
import json

from combat import Board, keyed


def lane(distance=10, move=4, bow=8, dash=False, charge=False, limit=40, boundary=None):
    """Archer acts first: fire if in range, then retreat. Fighter closes afterwards.

    Main + movement; straight lane, no obstacles, no damage/death, no reactions.
    First credible fighter opportunity is checked before spending its movement.
    Charge travels move+2 then attacks at reach1. Dash sacrifices attack.
    """
    f, a, shots = 0, distance, 0
    trace = []
    for turn in range(1, limit+1):
        if a-f <= bow:
            shots += 1
        else:
            # Stationary until the approaching target is visible/in weapon range.
            trace.append(dict(turn=turn, fighter=f, archer=a, shots=shots, phase="wait"))
        if a-f <= bow:
            a = a+move if boundary is None else min(a+move, boundary)
        threat = move+3 if charge else move+1
        contact = a-f <= threat
        trace.append(dict(turn=turn, fighter=f, archer=a, shots=shots, contact=contact))
        if contact:
            return dict(contact_turn=turn, shots_before_contact=shots, trace=trace)
        f += move*(2 if dash else 1)
    return dict(contact_turn=None, shots_before_contact=shots, trace=trace)


@dataclass(frozen=True)
class IllusionTruth:
    false_wall: bool = True
    secret_origin: str = "illusionist"


def illusion_observation(truth, disproved=False):
    # Both a physical and illusory wall have the SAME observable presentation.
    # Neither type nor secret origin is in the payload or policy arguments.
    return {"size": 9, "start": (1, 4), "goal": (7, 4),
            "apparent_walls": () if disproved else ((4, 3), (4, 4), (4, 5))}


def route_from_observation(view):
    b = Board(view["size"], frozenset(view["apparent_walls"]))
    return b.paths(view["start"], 100)[view["goal"]]


def illusion_proof():
    true_wall = IllusionTruth(False, "stonemason")
    false_wall = IllusionTruth(True)
    a, b = illusion_observation(true_wall), illusion_observation(false_wall)
    assert a == b
    assert route_from_observation(a) == route_from_observation(b)
    direct = route_from_observation(illusion_observation(false_wall, True))
    detour = route_from_observation(b)
    # Authority: probing consumes a main action and adds knowledge for ONE observer.
    # Demonstrates knowledge transition, not a full illusion-targeting battle AI.
    knowledge = {"scout": set(), "archer": set()}
    consumed_actions = 1
    knowledge["scout"].add("wall:1:disproved")
    scout = illusion_observation(false_wall, "wall:1:disproved" in knowledge["scout"])
    archer = illusion_observation(false_wall, "wall:1:disproved" in knowledge["archer"])
    assert len(route_from_observation(scout)) == len(direct)
    assert len(route_from_observation(archer)) == len(detour)
    # Fake creature and genuine creature project the same target signature.
    observed_targets = [{"id": "apparent:1", "position": (4, 4), "threat": "guard"}]
    target = min(observed_targets, key=lambda u: u["id"])["id"]
    before = dict(actions=1, known_false=[])
    after = dict(actions=0, known_false=[target])  # attack resolves air; never free validation failure
    return {"equal_precontact_observations": True, "detour_steps": len(detour), "direct_steps": len(direct),
            "redirected_steps": len(detour)-len(direct), "disbelief_probe_actions": consumed_actions,
            "other_observer_still_believes": len(route_from_observation(archer)) == len(detour),
            "route_before": detour, "route_after": direct, "decoy_attack_before": before, "decoy_attack_after": after,
            "limit": "BFS belief/command-boundary proof, not measured expert combat effectiveness or actual damage prevented"}


def probability_diagnostics():
    # Exact enumeration, not fitted to the battle data.
    rows = []
    for attack in (5, 7, 9):
        for ac in (12, 15, 18):
            outcomes = [0 if r == 1 or (r != 20 and r+attack < ac) else 8+(4 if r==20 else 0) for r in range(1,21)]
            rows.append({"attack": attack, "ac": ac, "hit_probability": sum(d>0 for d in outcomes)/20,
                         "expected_damage": sum(outcomes)/20, "two_independent_misses": (outcomes.count(0)/20)**2,
                         "max_single_damage": max(outcomes)})
    return rows


def resource_diagnostic():
    """Transparent budget arithmetic, not a campaign simulation."""
    return {"battles": 3, "focus_without_restock": 2, "maximum_power_casts": 2,
            "if_focus_refills_each_battle": 6, "healing_example": {"action_cost": 1, "healed": 10, "enemy_hit_damage": 8, "enemy_hit_probability": .65,
            "expected_two_attacker_damage": 10.4, "net_hp_if_two_attacks_arrive": -.4},
            "hard_stun_team_action_loss_one_round": {"party3": 1/3, "party6": 1/6},
            "ct_speed_ratio": 1.5, "ct_plus_stride_distance_ratio": 2.25}


def all_diagnostics():
    lanes = {}
    for name, opts in {"unbounded_no_tools": {}, "bounded_no_tools": {"boundary": 15},
                       "unbounded_dash": {"dash": True}, "unbounded_charge": {"charge": True},
                       "unbounded_both": {"dash": True, "charge": True}}.items():
        lanes[name] = lane(**opts)
    return {"lane": lanes, "illusion": illusion_proof(), "accuracy": probability_diagnostics(), "resources": resource_diagnostic()}


if __name__ == "__main__":
    print(json.dumps(all_diagnostics(), indent=2))

