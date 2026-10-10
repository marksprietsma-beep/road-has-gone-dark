import copy
import unittest
from dataclasses import replace

from combat import Battle, Board, Budget, Command, Rules, choose, replay_commands


class CombatTests(unittest.TestCase):
    def test_deterministic_result_and_full_command_replay(self):
        for model in "ABC":
            args = dict(seed=17, rules=Rules(model=model), left=("fighter", "rogue", "mage"), right=("fighter", "archer", "controller"), terrain="moderate")
            a, b, c = Battle(**args), Battle(**args), Battle(**args)
            self.assertEqual(a.run(), b.run())
            self.assertEqual(c.run(replay_commands(a)), a.result())
            self.assertEqual(a.log, c.log)

    def test_los_symmetric_and_blocked_corner(self):
        board = Board(6, frozenset({(2, 2), (3, 4)}))
        tiles = [(x, y) for x in range(6) for y in range(6) if (x, y) not in board.walls]
        for a in tiles:
            for b in tiles:
                self.assertEqual(board.los(a, b), board.los(b, a))
        self.assertFalse(Board(4, frozenset({(1, 0)})).los((0, 0), (2, 2)))

    def test_all_spawn_routes_connect(self):
        for seed in range(12):
            b = Battle(seed, terrain="dense", left=("fighter", "rogue", "mage"), right=("fighter", "archer", "controller"))
            paths = b.board.paths(b.units[0].pos, 200)
            self.assertTrue(all(u.pos in paths for u in b.units))

    def test_no_damage_action_after_dash(self):
        b = Budget.new("A")
        b.spend("dash")
        self.assertFalse(b.can("attack"))
        self.assertFalse(b.can("move"))

    def test_three_action_attack_penalty_and_cap(self):
        b = Battle(separation=1, rules=Rules(model="C"))
        u, t = b.units; u.pos=(2, 2); t.pos=(3, 2)
        budget=Budget.new("C")
        for _ in range(3):
            b.apply(u, Command("attack", t.id), budget, 4)
        self.assertEqual([e["penalty"] for e in b.log if e["type"] == "hit"], [0, 5, 10])
        self.assertFalse(budget.can("attack"))

    def test_charge_needs_clear_straight_occupied_free_lane(self):
        b = Battle(); u, t = b.units; u.pos=(1, 2); t.pos=(5, 2)
        c = Command("charge", t.id, ((2, 2), (3, 2), (4, 2)))
        self.assertTrue(b.legal(u, c, Budget.new("A"), 4))
        b.board = Board(12, frozenset({(3, 2)}))
        self.assertFalse(b.legal(u, c, Budget.new("A"), 4))
        b.board = Board(12); t.pos=(5, 3)
        self.assertFalse(b.legal(u, c, Budget.new("A"), 4))

    def test_leaving_threat_uses_one_reaction(self):
        b=Battle(); f,a=b.units; f.pos=(2, 2); a.pos=(3, 2)
        b.apply(a, Command("move", path=((4, 2), (3, 2), (4, 2))), Budget.new("A"), 4)
        self.assertEqual(b.reaction_attacks, 1)
        self.assertFalse(f.reaction)

    def test_disengage_costs_main_action_and_prevents_reaction(self):
        b=Battle(); f,a=b.units; f.pos=(2, 2); a.pos=(3, 2)
        budget=Budget.new("A")
        safe=b.apply(a, Command("disengage"), budget, 4)
        b.apply(a, Command("move", path=((4, 2),)), budget, 4, safe)
        self.assertEqual(b.reaction_attacks, 0)
        self.assertFalse(budget.can("attack"))

    def test_delayed_spell_not_immediate_and_hits_friends(self):
        b=Battle(left=("mage", "fighter"), right=("fighter",))
        m,f,e=b.units; m.pos=(2, 2); f.pos=(4, 2); e.pos=(4, 3)
        b.apply(m, Command("cast", tile=(4, 2)), Budget.new("A"), 4)
        self.assertEqual(f.hp, 34); self.assertEqual(e.hp, 34)
        b.resolve_cast(m)
        self.assertEqual(f.hp, 18); self.assertEqual(e.hp, 18)
        self.assertEqual(m.focus, 1)

    def test_melee_hit_can_interrupt_only_with_reaction(self):
        for available in (False, True):
            b=Battle(left=("fighter",), right=("mage",)); f,m=b.units
            f.pos=(2,2);m.pos=(3,2);m.ac=-100; m.pending={"tile": (5, 5)};f.reaction=available
            # Seed/ordinal chosen by explicit actual hit, not an asserted guarantee.
            while b.hits == 0: b.hit(f,m)
            self.assertEqual(m.pending is None, available)
            self.assertEqual(b.cancelled, int(available))

    def test_cover_and_engagement_penalties_are_additive(self):
        b=Battle();f,a=b.units;f.pos=(2,2);a.pos=(3,2)
        b.board=Board(12, cover=frozenset({f.pos}))
        b.hit(a,f)
        self.assertEqual(b.log[-1]["penalty"],7)

    def test_observation_is_detached_and_policy_deterministic(self):
        b=Battle();u=b.units[0]
        view=b.observe(u)
        first=choose(view,b.board,b.rules,Budget.new("A"))
        self.assertEqual(first,choose(copy.deepcopy(view),b.board,b.rules,Budget.new("A")))
        view["units"][0]["hp"]=-999
        self.assertEqual(u.hp,34)

    def test_contact_is_opportunity_not_successful_hit(self):
        b=Battle(separation=6);u=b.units[0]
        b.credible_contact(u,4,Budget.new("A"))
        self.assertIn(u.id,b.first_contact)  # legal charge exists
        b=Battle(separation=8,rules=Rules(charge=False,dash=False));u=b.units[0]
        b.credible_contact(u,4,Budget.new("A"))
        self.assertNotIn(u.id,b.first_contact)

    def test_timeout_is_not_a_win(self):
        b=Battle(rules=Rules(max_rounds=0))
        self.assertEqual(b.run()["outcome"],"timeout")
        self.assertEqual(b.result()["never_contact"],1)

    def test_guard_reduces_one_adjacent_ally_hit(self):
        b=Battle(left=("fighter","mage"),right=("archer",));f,m,a=b.units
        f.pos=(2,2);m.pos=(2,3);a.pos=(5,3);m.ac=-100
        b.apply(f,Command("guard"),Budget.new("A"),4)
        while not b.hits:b.hit(a,m)
        self.assertFalse(f.reaction)
        self.assertEqual(b.log[-1]["damage"], a.damage-4+(4 if b.log[-1]["roll"]==20 else 0))


if __name__ == "__main__":
    unittest.main()
