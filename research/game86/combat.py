"""GAME-86 research model, not production rules. Python standard library only.

Discrete orthogonal grid; deliberately constant damage isolates action/space effects.
All mutations go through Battle. Policies receive copied public observations.
See docs/research/game86/METHOD.md for omissions and metric definitions.
"""
from __future__ import annotations

from collections import deque
from dataclasses import asdict, dataclass, field
from functools import lru_cache
from types import MappingProxyType
import hashlib
import json


def keyed(seed, *path):
    return int.from_bytes(hashlib.sha256(json.dumps([seed, *path], separators=(",", ":")).encode()).digest()[:8], "big")


def distance(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


@dataclass(frozen=True)
class Rules:
    model: str = "A"
    charge: bool = True
    dash: bool = True
    reactions: bool = True
    cover_bonus: int = 3
    bow_range: int = 7
    fighter_move: int = 4
    damage_scale: float = 1.0
    delayed: bool = True
    control: str = "slow"
    initiative: str = "individual"
    max_rounds: int = 24
    crit_bonus: int = 4


# hp, armour, attack, damage, movement, reach, initiative modifier
KITS = {
    "fighter": (34, 15, 7, 8, 4, 1, 0),
    "rogue": (26, 14, 7, 6, 5, 1, 3),
    "archer": (26, 13, 7, 8, 4, 7, 2),
    "mage": (24, 12, 7, 8, 4, 5, 1),
    "monk": (30, 14, 7, 7, 6, 1, 3),
    "controller": (24, 12, 7, 6, 4, 5, 1),
}


@dataclass
class Unit:
    id: str
    team: int
    kind: str
    pos: tuple
    hp: int
    ac: int
    attack: int
    damage: int
    move: int
    reach: int
    initiative: int
    focus: int = 2
    reaction: bool = True
    slow: bool = False
    stun: bool = False
    hidden: bool = False
    guard: bool = False
    pending: dict | None = None
    ordinal: int = 0
    activation: int = 0
    precision_used: bool = False

    @property
    def alive(self):
        return self.hp > 0


@dataclass(frozen=True)
class Board:
    size: int
    walls: frozenset = frozenset()
    cover: frozenset = frozenset()
    objective: bool = False

    @lru_cache(maxsize=32768)
    def neighbours(self, p):
        # Board is immutable; preserve the original BFS neighbour order.
        return tuple(q for q in ((p[0]-1, p[1]), (p[0], p[1]-1), (p[0], p[1]+1), (p[0]+1, p[1]))
                     if 0 <= q[0] < self.size and 0 <= q[1] < self.size and q not in self.walls)

    def paths(self, start, budget, occupied=frozenset()):
        return self._paths(start, budget, frozenset(occupied))

    @lru_cache(maxsize=256)
    def _paths(self, start, budget, occupied):
        # Occupancy participates in the key; no stale paths after moves/deaths.
        paths = {start: ()}
        queue = deque([start])
        while queue:
            p = queue.popleft()
            if len(paths[p]) >= budget:
                continue
            for q in self.neighbours(p):
                if q not in paths and q not in occupied:
                    paths[q] = paths[p] + (q,)
                    queue.append(q)
        return MappingProxyType(paths)

    @lru_cache(maxsize=150000)
    def los(self, a, b):
        """Symmetric supercover; a line grazing a solid corner is blocked."""
        x, y = a
        dx, dy = b[0]-x, b[1]-y
        nx, ny = abs(dx), abs(dy)
        sx, sy = (1 if dx > 0 else -1), (1 if dy > 0 else -1)
        ix = iy = 0
        while ix < nx or iy < ny:
            decision = (1+2*ix)*ny - (1+2*iy)*nx
            if decision == 0:
                if (x+sx, y) in self.walls or (x, y+sy) in self.walls:
                    return False
                x += sx; y += sy; ix += 1; iy += 1
            elif decision < 0:
                x += sx; ix += 1
            else:
                y += sy; iy += 1
            if (x, y) in self.walls:
                return False
        return True


def make_board(seed, size, terrain, starts):
    density = {"open": 0, "moderate": 10, "dense": 23, "objective": 12}[terrain]
    protected = {p for s in starts for p in [(s[0]+dx, s[1]+dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]}
    center = (size//2, size//2)
    protected.add(center)
    walls, cover = set(), set()
    for x in range(size):
        for y in range(size):
            p, mirror = (x, y), (size-1-x, size-1-y)
            h = keyed(seed, "terrain", min(p, mirror)) % 100
            if p in protected or mirror in protected:
                continue
            if h < density:
                walls.add(p)
            elif h < density + (14 if density else 0):
                cover.add(p)
    # Reject individual walls deterministically until ALL spawns/objective connect.
    # No guaranteed straight central lane; removed wall count remains inspectable.
    for p in sorted(walls, key=lambda p: keyed(seed, "repair", p)) + [None]:
        board = Board(size, frozenset(walls), frozenset(cover), terrain == "objective")
        reachable = board.paths(starts[0], size*size)
        if all(s in reachable for s in starts) and center in reachable:
            return board
        if p is not None:
            walls.discard(p)
            walls.discard((size-1-p[0], size-1-p[1]))
    raise AssertionError("map connection repair failed")


@dataclass
class Budget:
    model: str
    move: int = 1
    main: int = 1
    ap: int = 0
    attacks: int = 0

    @classmethod
    def new(cls, model):
        return cls(model, ap={"A": 0, "B": 2, "C": 3}[model])

    def cost(self, action):
        if self.model == "A":
            return {"move": (1, 0), "attack": (0, 1), "cast": (0, 1), "slow": (0, 1), "heal": (0, 1), "guard": (0, 1), "disengage": (0, 1), "dash": (1, 1), "charge": (1, 1)}.get(action)
        return 2 if action == "charge" or (self.model == "C" and action in ("cast", "slow", "heal")) else 1

    def can(self, action):
        if action == "end":
            return True
        if action == "dash" and self.model != "A":
            return False
        cost = self.cost(action)
        if self.model == "A":
            return cost is not None and self.move >= cost[0] and self.main >= cost[1]
        return self.ap >= cost

    def spend(self, action):
        assert self.can(action), (asdict(self), action)
        cost = self.cost(action)
        if self.model == "A":
            self.move -= cost[0]; self.main -= cost[1]
        else:
            self.ap -= cost
        if action in ("attack", "charge"):
            self.attacks += 1


@dataclass(frozen=True)
class Command:
    action: str
    target: str = ""
    path: tuple = ()
    tile: tuple = ()


def enemies(view, actor):
    return [u for u in view["units"] if u["team"] != actor["team"]]


def can_attack(board, actor, target, pos=None):
    p = actor["pos"] if pos is None else pos
    return distance(p, target["pos"]) <= actor["reach"] and board.los(p, target["pos"])


def charge_path(board, actor, target, occupied, stride):
    a, b = actor["pos"], target["pos"]
    if a[0] != b[0] and a[1] != b[1]:
        return ()
    d = distance(a, b)
    if d < 2 or d > stride+3:
        return ()
    dx = (b[0] > a[0]) - (b[0] < a[0]); dy = (b[1] > a[1]) - (b[1] < a[1])
    path = tuple((a[0]+i*dx, a[1]+i*dy) for i in range(1, d))
    return path if all(p not in board.walls and p not in occupied for p in path) else ()


def position_value(board, actor, foes, pos, hazards):
    d = min(distance(pos, e["pos"]) for e in foes)
    if actor["reach"] == 1:
        value = -1.5 * d
    else:
        value = min(d, actor["reach"]-1)*1.6 - max(0, d-actor["reach"])*1.6
        value += 2.0 if any(can_attack(board, actor, e, pos) for e in foes) else -2.0
        value -= 5 if d <= 1 else 0
    value += 1.5 if pos in board.cover else 0
    value -= 24 if any(distance(pos, h) <= 1 for h in hazards) else 0
    if board.objective:
        value -= 2.5 * max(0, distance(pos, (board.size//2, board.size//2))-1)
    return value


def choose(view, board, rules, budget):
    """Public-input heuristic policy v1. Not a minimax/expert balance oracle."""
    actor = next(u for u in view["units"] if u["id"] == view["actor"])
    foes = enemies(view, actor)
    if not foes:
        return Command("end")
    occupied = {u["pos"] for u in view["units"] if u["id"] != actor["id"]}
    hazards = [u["pending"]["tile"] for u in view["units"] if u["pending"]]
    stride = max(1, actor["move"] - (2 if view["slowed"] else 0))
    values = {}
    attackable = {}
    def value(pos):
        if pos not in values:
            values[pos] = position_value(board, actor, foes, pos, hazards)
        return values[pos]
    def can_hit(pos):
        if pos not in attackable:
            attackable[pos] = any(can_attack(board, actor, e, pos) for e in foes)
        return attackable[pos]
    current = value(actor["pos"])
    choices = [(0.05, Command("end"))]
    for foe in foes:
        if budget.can("attack") and can_attack(board, actor, foe):
            penalty = 5*budget.attacks if rules.model == "C" else 0
            expected = actor["damage"] * max(.1, .7-.05*penalty)
            choices.append((expected + (2 if foe["hp"] <= actor["damage"] else 0), Command("attack", foe["id"])))
        if actor["kind"] == "controller" and rules.control != "none" and actor["focus"] and budget.can("slow") and can_attack(board, actor, foe) and not foe["slow"] and not foe["stun"]:
            choices.append((6.8 if distance(actor["pos"], foe["pos"]) > 1 else 3.0, Command("slow", foe["id"])))
        if actor["reach"] == 1 and rules.charge and budget.can("charge"):
            path = charge_path(board, actor, foe, occupied, stride)
            if path:
                score = actor["damage"]*.7 + value(path[-1]) - current
                choices.append((score, Command("charge", foe["id"], path)))
    if actor["kind"] == "mage" and rules.delayed and actor["focus"] and not actor["pending"] and budget.can("cast"):
        for foe in foes:
            if distance(actor["pos"], foe["pos"]) <= 5 and board.los(actor["pos"], foe["pos"]):
                targets = sum(distance(foe["pos"], e["pos"]) <= 1 for e in foes)
                friends = sum(distance(foe["pos"], u["pos"]) <= 1 for u in view["units"] if u["team"] == actor["team"])
                if targets >= 2 and not friends:
                    choices.append((7.5, Command("cast", tile=foe["pos"])))
    actions = [a for a in ("move", "dash") if budget.can(a) and (a != "dash" or rules.dash)]
    # A longer BFS has exactly the same shortest paths and discovery prefix.
    reachable = board.paths(actor["pos"], stride * (2 if "dash" in actions else 1), occupied) if actions else {}
    for action in actions:
        if not budget.can(action) or (action == "dash" and not rules.dash):
            continue
        steps = stride * (2 if action == "dash" else 1)
        for p, path in reachable.items():
            if not path or len(path) > steps:
                continue
            improvement = value(p) - current
            if action == "move" and budget.can("attack") and (rules.model == "A" or budget.ap > 1):
                if not can_hit(actor["pos"]) and can_hit(p):
                    improvement += 4
            # Avoid leaving fresh melee reactions unless worthwhile. Known reaction state.
            threats = [e for e in foes if e["reach"] == 1 and e["reaction"] and distance(actor["pos"], e["pos"]) == 1 and distance(path[0], e["pos"]) > 1]
            reaction_risk = sum(e["damage"]*.7 for e in threats) if rules.reactions and not view.get("disengaged") else 0
            if action == "move" and threats and not view.get("disengaged") and budget.can("disengage") and (rules.model == "A" or budget.ap > 1):
                choices.append((improvement-2, Command("disengage")))
            improvement -= reaction_risk
            improvement -= .015*len(path)
            choices.append((improvement, Command(action, path=path)))
    return max(choices, key=lambda x: (round(x[0], 6), x[1].action, x[1].target, x[1].path, x[1].tile))[1]


class Battle:
    def __init__(self, seed=0, rules=Rules(), left=("fighter",), right=("archer",), terrain="open", size=12, separation=8, conceal=False):
        self.seed, self.rules = seed, rules
        self.round = 0
        self.units = []
        separation = min(separation, size-3)
        lo = (size-1-separation)//2
        hi = lo + separation
        for team, kinds in enumerate((left, right)):
            for index, kind in enumerate(kinds):
                hp, ac, atk, dmg, move, reach, init = KITS[kind]
                x = lo if team == 0 else hi
                y = size//2 - len(kinds)//2 + index
                pos = (x, y)
                if seed % 2:
                    pos = (size-1-x, size-1-y)
                u = Unit(f"{team}:{index}", team, kind, pos, hp, ac, atk, max(1, round(dmg*rules.damage_scale)), rules.fighter_move if kind == "fighter" else move, rules.bow_range if kind == "archer" else reach, init)
                u.hidden = conceal and kind == "rogue"
                self.units.append(u)
        self.board = make_board(seed, size, terrain, [u.pos for u in self.units])
        self.log = []
        self.first_contact = {}
        self.exposure = {u.id: [0, 0] for u in self.units if u.reach == 1}
        self.turns = self.walk_only = self.idle = self.attacks = self.hits = 0
        self.damage = self.reaction_attacks = self.cancelled = self.casts = self.burst_damage = 0
        self.denied_turns = self.slowed_turns = self.control_casts = 0
        self.objective_scores = [0, 0]
        self.outcome = "timeout"
        self.order = self.make_order()

    def make_order(self):
        ordered = sorted(self.units, key=lambda u: (-(keyed(self.seed, "initiative", u.id)%20 + 1 + u.initiative), u.id))
        if self.rules.initiative == "team":
            first = self.seed % 2
            ordered.sort(key=lambda u: u.team != first)
        elif self.rules.initiative == "alternating":
            teams = [[u for u in ordered if u.team == t] for t in (0, 1)]
            ordered = []
            for i in range(max(map(len, teams))):
                for t in (self.seed%2, 1-self.seed%2):
                    if i < len(teams[t]): ordered.append(teams[t][i])
        return [u.id for u in ordered]

    def get(self, identity):
        return next(u for u in self.units if u.id == identity)

    def observe(self, actor, slowed=False):
        # No references to mutable Unit/Battle escape this boundary.
        return {"actor": actor.id, "round": self.round, "slowed": slowed,
                "units": [dict(vars(u), pending=dict(u.pending) if u.pending else None) for u in self.units if u.alive]}

    def event(self, **data):
        self.log.append({"round": self.round, **data})

    def hit(self, actor, target, budget=None, reaction=False):
        actor.ordinal += 1
        roll = keyed(self.seed, "attack", actor.id, actor.ordinal) % 20 + 1
        penalty = 5*max(0, budget.attacks-1) if budget and self.rules.model == "C" else 0
        if actor.reach > 1:
            if any(e.alive and e.team != actor.team and e.reach == 1 and distance(actor.pos, e.pos) <= 1 for e in self.units):
                penalty += 4
            if target.pos in self.board.cover:
                penalty += self.rules.cover_bonus
        success = roll == 20 or (roll != 1 and roll+actor.attack-penalty >= target.ac)
        damage = actor.damage + (self.rules.crit_bonus if roll == 20 else 0)
        flank = any(u.alive and u.team == actor.team and u.id != actor.id and u.reach == 1 and distance(u.pos, target.pos) == 1 for u in self.units)
        if actor.kind == "rogue" and (actor.hidden or flank) and not reaction and not actor.precision_used:
            damage += 4
            actor.precision_used = True
        actor.hidden = False
        self.attacks += 1; self.hits += success; self.reaction_attacks += reaction
        if actor.reach > 1 and target.id in self.exposure and target.id not in self.first_contact:
            self.exposure[target.id][0] += 1
            self.exposure[target.id][1] += success
        if success:
            guards = [u for u in self.units if u.alive and u.team == target.team and u.id != target.id and u.guard and u.reaction and distance(u.pos, target.pos) == 1]
            if guards:
                guard = min(guards, key=lambda u: u.id)
                guard.reaction = False
                damage = max(0, damage-4)
            target.hp = max(0, target.hp-damage)
            self.damage += damage
            if actor.reach == 1 and actor.reaction and target.pending:
                actor.reaction = False
                target.pending = None
                self.cancelled += 1
                self.event(type="interrupt", actor=actor.id, target=target.id)
            if not target.alive:
                target.pending = None
        self.event(type="hit", actor=actor.id, target=target.id, roll=roll, penalty=penalty, success=success, damage=damage if success else 0, reaction=reaction, hp=target.hp)

    def resolve_cast(self, actor):
        tile = tuple(actor.pending["tile"])
        actor.pending = None
        victims = []
        for u in self.units:
            if u.alive and distance(u.pos, tile) <= 1 and self.board.los(tile, u.pos):
                amount = round(16*self.rules.damage_scale)
                u.hp = max(0, u.hp-amount)
                if not u.alive: u.pending = None
                self.burst_damage += amount
                victims.append(u.id)
        self.event(type="burst", actor=actor.id, tile=tile, victims=victims)

    def legal(self, actor, cmd, budget, stride):
        if not actor.alive or not budget.can(cmd.action): return False
        occupied = {u.pos for u in self.units if u.alive and u.id != actor.id}
        if cmd.action == "end": return True
        if cmd.action in ("move", "dash", "charge"):
            if not cmd.path: return False
            if cmd.action == "dash" and not self.rules.dash: return False
            limit = stride*2 if cmd.action == "dash" else stride+2 if cmd.action == "charge" else stride
            if len(cmd.path) > limit: return False
            prev = actor.pos
            for p in cmd.path:
                if p not in self.board.neighbours(prev) or p in occupied: return False
                prev = p
            if cmd.action == "charge":
                target = self.get(cmd.target)
                return self.rules.charge and actor.reach == 1 and target.alive and target.team != actor.team and cmd.path == charge_path(self.board, asdict(actor), asdict(target), occupied, stride)
            return True
        if cmd.action in ("attack", "slow"):
            target = self.get(cmd.target)
            valid = target.alive and target.team != actor.team and can_attack(self.board, asdict(actor), asdict(target))
            if cmd.action == "slow": valid &= actor.kind == "controller" and actor.focus > 0 and self.rules.control != "none"
            return valid
        if cmd.action == "cast":
            return actor.kind == "mage" and self.rules.delayed and actor.focus > 0 and not actor.pending and bool(cmd.tile) and distance(actor.pos, cmd.tile) <= 5 and cmd.tile not in self.board.walls and self.board.los(actor.pos, cmd.tile)
        if cmd.action == "guard": return actor.kind == "fighter"
        if cmd.action == "disengage": return True
        return False

    def apply(self, actor, cmd, budget, stride, safe=False):
        assert self.legal(actor, cmd, budget, stride), (actor.id, cmd, asdict(budget))
        self.event(type="command", actor=actor.id, command=asdict(cmd))
        if cmd.action == "end": return safe
        budget.spend(cmd.action)
        if cmd.action == "disengage": return True
        if cmd.action == "guard": actor.guard = True
        if cmd.path:
            for p in cmd.path:
                if self.rules.reactions and not safe:
                    for e in sorted(self.units, key=lambda u: u.id):
                        if actor.alive and e.alive and e.team != actor.team and e.reach == 1 and e.reaction and distance(actor.pos, e.pos) == 1 and distance(p, e.pos) > 1:
                            e.reaction = False
                            self.hit(e, actor, reaction=True)
                if not actor.alive: break
                actor.pos = p
        if actor.alive and cmd.action in ("attack", "charge"):
            self.hit(actor, self.get(cmd.target), budget)
        if cmd.action == "slow":
            actor.focus -= 1
            target = self.get(cmd.target)
            if self.rules.control == "stun": target.stun = True
            else: target.slow = True
            self.control_casts += 1
        if cmd.action == "cast":
            actor.focus -= 1; self.casts += 1
            actor.pending = {"tile": cmd.tile}
        return safe

    def credible_contact(self, actor, stride, budget):
        if actor.reach != 1 or actor.id in self.first_contact: return
        foes = [u for u in self.units if u.alive and u.team != actor.team]
        occupied = {u.pos for u in self.units if u.alive and u.id != actor.id}
        steps = stride if self.rules.model == "A" else stride*(budget.ap-1)
        paths = self.board.paths(actor.pos, max(0, steps), occupied)
        possible = any(any(distance(p, e.pos) == 1 for e in foes) for p in paths)
        if self.rules.charge:
            possible |= any(charge_path(self.board, asdict(actor), asdict(e), occupied, stride) for e in foes)
        if possible: self.first_contact[actor.id] = actor.activation

    def winner(self):
        live = {u.team for u in self.units if u.alive}
        if len(live) < 2: return str(next(iter(live))) if live else "draw"
        if max(self.objective_scores) >= 3: return str(self.objective_scores.index(max(self.objective_scores)))
        return None

    def run(self, replay=None):
        stream = iter(replay) if replay is not None else None
        for r in range(1, self.rules.max_rounds+1):
            self.round = r
            for u in self.units: u.reaction = True; u.guard = False
            for identity in self.order:
                actor = self.get(identity)
                if not actor.alive: continue
                actor.activation += 1
                actor.precision_used = False
                if actor.pending: self.resolve_cast(actor)
                if self.winner() is not None: break
                self.turns += 1
                if actor.stun:
                    actor.stun = False; self.denied_turns += 1
                    self.event(type="denied", actor=identity)
                    continue
                slowed = actor.slow
                self.slowed_turns += slowed
                actor.slow = False
                stride = max(1, actor.move-(2 if slowed else 0))
                budget = Budget.new(self.rules.model)
                self.credible_contact(actor, stride, budget)
                kinds = []; safe = False
                for _ in range(6):
                    if not actor.alive or self.winner() is not None: break
                    if stream is None:
                        view = self.observe(actor, slowed)
                        view["disengaged"] = safe
                        cmd = choose(view, self.board, self.rules, budget)
                    else:
                        entry = next(stream)
                        assert entry["round"] == r and entry["actor"] == identity
                        raw = entry["command"]
                        cmd = Command(raw["action"], raw["target"], tuple(tuple(p) for p in raw["path"]), tuple(raw["tile"]))
                    safe = self.apply(actor, cmd, budget, stride, safe)
                    if cmd.action == "end": break
                    kinds.append(cmd.action)
                if not kinds: self.idle += 1
                elif all(k in ("move", "dash") for k in kinds): self.walk_only += 1
            if self.board.objective:
                center = (self.board.size//2, self.board.size//2)
                occupiers = {u.team for u in self.units if u.alive and distance(u.pos, center) <= 1}
                if len(occupiers) == 1: self.objective_scores[next(iter(occupiers))] += 1
            outcome = self.winner()
            if outcome is not None:
                self.outcome = outcome; break
        if stream is not None: assert next(stream, None) is None, "unused replay command"
        return self.result()

    def state_hash(self):
        return hashlib.sha256(json.dumps({"units": [asdict(u) for u in self.units], "round": self.round, "scores": self.objective_scores, "outcome": self.outcome}, sort_keys=True).encode()).hexdigest()

    def result(self):
        return {"seed": self.seed, "rules": asdict(self.rules), "outcome": self.outcome, "rounds": self.round,
                "turns": self.turns, "walk_only": self.walk_only, "idle": self.idle,
                "attacks": self.attacks, "hits": self.hits, "damage": self.damage,
                "contact": self.first_contact, "exposure": self.exposure,
                "never_contact": len(self.exposure)-len(self.first_contact),
                "reaction_attacks": self.reaction_attacks, "casts": self.casts, "cancelled": self.cancelled,
                "burst_damage": self.burst_damage, "control_casts": self.control_casts,
                "denied_turns": self.denied_turns, "slowed_turns": self.slowed_turns,
                "wall_count": len(self.board.walls), "cover_count": len(self.board.cover),
                "objective_scores": self.objective_scores, "state_sha256": self.state_hash()}


def replay_commands(battle):
    return [e for e in battle.log if e["type"] == "command"]
