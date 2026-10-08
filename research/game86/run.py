"""Reproducible experiments. Run from any directory: python research/game86/run.py.

Reports are deterministic; wall-clock measurements go in a separate timing.json.
No third-party dependency, network, Godot, canonical fixture or save access.
"""
from collections import defaultdict
import argparse
from concurrent.futures import ProcessPoolExecutor, as_completed
import fcntl
import os
import tempfile
from dataclasses import asdict, replace
import csv
import gzip
import hashlib
import json
from pathlib import Path
import statistics
import time

from combat import Battle, Rules, replay_commands
from diagnostics import all_diagnostics

OUT = Path(__file__).parent / "results"
MATCHUPS = {
    "fighter_archer": (("fighter",), ("archer",)),
    "fighter_rogue": (("fighter",), ("rogue",)),
    "rogue_archer": (("rogue",), ("archer",)),
    "mage_fighter": (("mage",), ("fighter",)),
    "mage_monk": (("mage",), ("monk",)),
    "monk_archer": (("monk",), ("archer",)),
    "party": (("fighter", "rogue", "mage"), ("fighter", "archer", "controller")),
}
TERRAINS = ("open", "moderate", "dense", "objective")


def cases():
    for model in "ABC":
        for match, (left,right) in MATCHUPS.items():
            for terrain in TERRAINS:
                yield f"core/{model}/{match}/{terrain}", 128, dict(rules=Rules(model=model), left=left, right=right, terrain=terrain)
    for name, changes in {"no_charge": dict(charge=False), "no_dash": dict(dash=False), "neither": dict(charge=False,dash=False), "no_reactions": dict(reactions=False), "no_cover": dict(cover_bonus=0)}.items():
        for terrain in TERRAINS:
            yield f"ablation/{name}/fighter_archer/{terrain}",128,dict(rules=Rules(**changes), terrain=terrain)
    # One variable at a time where possible; geometry uses a documented factorial.
    for size in (10,12,14,16):
        for gap in (4,6,8,10):
            if gap > size-3: continue
            for bow in (6,8,10):
                for move in (4,5):
                    yield f"geometry/{size}/{gap}/{bow}/{move}",32,dict(rules=Rules(bow_range=bow,fighter_move=move),size=size,separation=gap)
    left,right=MATCHUPS["party"]
    for mode in ("individual","alternating","team"):
        yield f"initiative/{mode}",256,dict(rules=Rules(initiative=mode),left=left,right=right,terrain="moderate")
    for control in ("none","slow","stun"):
        yield f"control/{control}",256,dict(rules=Rules(control=control),left=left,right=right,terrain="moderate")
    for scale in (.65,1.0,1.4):
        for model in "ABC":
            yield f"lethality/{model}/{scale}",128,dict(rules=Rules(model=model,damage_scale=scale),left=left,right=right,terrain="moderate")
    for name,args in {
        "open_duel": dict(left=("fighter",),right=("rogue",)),
        "concealed_opening": dict(left=("fighter",),right=("rogue",),conceal=True),
        "broken_ground": dict(left=("fighter",),right=("rogue",),terrain="dense"),
        "objective": dict(left=("fighter",),right=("rogue",),terrain="objective"),
        "ally_flank": dict(left=("fighter","fighter"),right=("fighter","rogue")),
        "protect_mage": dict(left=("fighter","mage"),right=("rogue","archer")),
    }.items():
        yield f"rogue/{name}",128,args
    for model in "ABC":
        for terrain in ("moderate","objective"):
            yield f"scale6/{model}/{terrain}",32,dict(rules=Rules(model=model),left=left*2,right=right*2,terrain=terrain,size=16,separation=10)


def wilson(wins,n):
    z=1.96;p=wins/n;d=1+z*z/n
    mid=(p+z*z/(2*n))/d
    half=z*((p*(1-p)/n+z*z/(4*n*n))**.5)/d
    return round(mid-half,4),round(mid+half,4)


def aggregate(group,rows):
    contacts=[v for r in rows for v in r["contact"].values()]
    exposures=[v for r in rows for v in r["exposure"].values()]
    wins=sum(r["outcome"]=="0" for r in rows)
    lo,hi=wilson(wins,len(rows))
    turns=sum(r["turns"] for r in rows)
    return {"group":group,"n":len(rows),"left_wins":wins,"right_wins":sum(r["outcome"]=="1" for r in rows),
            "timeouts":sum(r["outcome"]=="timeout" for r in rows),"draws":sum(r["outcome"]=="draw" for r in rows),
            "left_win_rate":round(wins/len(rows),4),"win_ci_low":lo,"win_ci_high":hi,
            "mean_rounds":round(statistics.mean(r["rounds"] for r in rows),3),
            "median_contact_activation_observed":statistics.median(contacts) if contacts else None,
            "mean_contact_activation_observed":round(statistics.mean(contacts),3) if contacts else None,
            "contact_observed_n":len(contacts),"contact_censored_n":sum(r["never_contact"] for r in rows),
            "precontact_attempts_per_melee_including_censored":round(statistics.mean(v[0] for v in exposures),3) if exposures else None,
            "precontact_hits_per_melee_including_censored":round(statistics.mean(v[1] for v in exposures),3) if exposures else None,
            "turns":turns,"walking_only_fraction":round(sum(r["walk_only"] for r in rows)/max(1,turns),4),
            "idle_fraction":round(sum(r["idle"] for r in rows)/max(1,turns),4),
            "attack_hit_rate":round(sum(r["hits"] for r in rows)/max(1,sum(r["attacks"] for r in rows)),4),
            "mean_denied_turns":round(statistics.mean(r["denied_turns"] for r in rows),3),
            "mean_slowed_turns":round(statistics.mean(r["slowed_turns"] for r in rows),3),
            "casts":sum(r["casts"] for r in rows),"interrupts":sum(r["cancelled"] for r in rows),
            "burst_damage":sum(r["burst_damage"] for r in rows),"mean_walls":round(statistics.mean(r["wall_count"] for r in rows),2)}


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode()


def atomic_write(path, data):
    """A checkpoint is visible only after all bytes have been flushed."""
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".partial-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data); f.flush(); os.fsync(f.fileno())
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try: os.fsync(directory)
        finally: os.close(directory)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)


def experiment_identity():
    root = Path(__file__).parent
    sources = {name: hashlib.sha256((root/name).read_bytes()).hexdigest()
               for name in ("combat.py", "run.py", "diagnostics.py")}
    design = [(g, n, {k: asdict(v) if isinstance(v, Rules) else v for k,v in kw.items()})
              for g,n,kw in cases()]
    return hashlib.sha256(canonical(dict(sources=sources, cases=design))).hexdigest()


def checkpoint_path(out, group):
    return Path(out)/"groups"/(group + ".json")


def load_checkpoint(path, identity, group, n):
    data = json.loads(path.read_bytes())
    assert data["identity"] == identity, f"Stale checkpoint: {path}; use a new --output directory"
    rows = data["rows"]
    assert len(rows) == n and all(r["seed"] == i and r["group"] == group for i,r in enumerate(rows)), path
    assert data["rows_sha256"] == hashlib.sha256(canonical(rows)).hexdigest(), f"Corrupt checkpoint: {path}"
    assert data["summary"] == aggregate(group, rows), path
    return data


def run_group(out, identity, case):
    group,n,kwargs = case
    path = checkpoint_path(out, group)
    if path.exists():
        return group, load_checkpoint(path, identity, group, n), True
    started = time.perf_counter(); rows = []
    for seed in range(n):
        row = Battle(seed=seed, **kwargs).run(); row["group"] = group; rows.append(row)
    data = dict(identity=identity, rows=rows, summary=aggregate(group,rows),
                rows_sha256=hashlib.sha256(canonical(rows)).hexdigest(),
                timing=dict(group=group,battles=n,seconds=round(time.perf_counter()-started,4)))
    atomic_write(path, canonical(data)+b"\n")
    return group, data, False


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUT)
    parser.add_argument("--workers", type=int, default=1)
    parser.add_argument("--group", action="append", help="Run matching group prefixes; default is the COMPLETE suite")
    args = parser.parse_args(argv)
    if args.workers < 1: parser.error("--workers must be positive")
    out = args.output; out.mkdir(parents=True, exist_ok=True)
    # Kernel releases the lock after interruption; no unsafe stale-PID guessing.
    lock = (out/".runner.lock").open("w")
    try: fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        lock.close()
        raise SystemExit("Another runner owns this output directory")
    try:
        execute(args, out)
    finally:
        lock.close()


def execute(args, out):
    started = time.perf_counter(); identity = experiment_identity()
    full = list(cases())
    selected = [c for c in full if not args.group or any(c[0].startswith(p) for p in args.group)]
    if not selected: parser.error("No experiment groups matched")
    completed = {}; reused = 0
    def accept(result):
        nonlocal reused
        group,data,cached = result; completed[group] = data; reused += cached
        print("RESUMED" if cached else "CHECKPOINT", group, len(data["rows"]), data["timing"]["seconds"], "seconds", flush=True)
    if args.workers == 1:
        for case in selected: accept(run_group(out,identity,case))
    else:
        with ProcessPoolExecutor(max_workers=args.workers) as pool:
            futures = [pool.submit(run_group,out,identity,case) for case in selected]
            for future in as_completed(futures): accept(future.result())
    # Consolidation always follows the original case order and seed order,
    # regardless of scheduling, sharding, worker count or interruption history.
    for group,n,_ in full:
        path = checkpoint_path(out,group)
        if group not in completed and path.exists(): completed[group] = load_checkpoint(path,identity,group,n)
    if len(completed) != len(full):
        print("PARTIAL", len(completed), "of", len(full), "groups; rerun without --group to finish", flush=True)
        return
    summaries = [aggregate(g, completed[g]["rows"]) for g,_,_ in full]
    paired = {g: completed[g]["rows"] for g,_,_ in full}
    timing = [completed[g]["timing"] for g,_,_ in full]
    count = sum(len(rows) for rows in paired.values())
    raw = b"".join(canonical(r)+b"\n" for rows in paired.values() for r in rows)
    import io
    compressed = io.BytesIO()
    with gzip.GzipFile(fileobj=compressed,mode="wb",filename="",mtime=0) as archive: archive.write(raw)
    atomic_write(out/"battles.jsonl.gz",compressed.getvalue())
    csv_text = io.StringIO(newline="")
    writer = csv.DictWriter(csv_text,fieldnames=list(summaries[0])); writer.writeheader(); writer.writerows(summaries)
    atomic_write(out/"summary.csv",csv_text.getvalue().encode())
    atomic_write(out/"summary.json",(json.dumps(summaries,indent=2)+"\n").encode())
    comparisons=[]
    for alternate in ("none","stun"):
        base=paired["control/slow"];other=paired["control/"+alternate]
        diffs=[int(a["outcome"]=="0")-int(b["outcome"]=="0") for a,b in zip(base,other)]
        comparisons.append({"paired":f"left win: slow minus {alternate}","n":len(diffs),"mean":statistics.mean(diffs),
                            "descriptive_se":statistics.stdev(diffs)/(len(diffs)**.5),"discordant_seeds":sum(d!=0 for d in diffs)})
    atomic_write(out/"paired.json", (json.dumps(comparisons,indent=2)+"\n").encode())
    atomic_write(out/"diagnostics.json", (json.dumps(all_diagnostics(),indent=2)+"\n").encode())
    b=Battle(seed=1,left=MATCHUPS["party"][0],right=MATCHUPS["party"][1],terrain="moderate")
    result=b.run()
    replay=Battle(seed=1,left=MATCHUPS["party"][0],right=MATCHUPS["party"][1],terrain="moderate")
    assert result==replay.run(replay_commands(b))
    trace={"seed":1,"rules":asdict(b.rules),"left":MATCHUPS["party"][0],"right":MATCHUPS["party"][1],"terrain":"moderate","size":12,"separation":8,
           "board":{"walls":sorted(b.board.walls),"cover":sorted(b.board.cover)},"initiative":b.order,"events":b.log,"result":result,
           "command_replay_sha256":replay.state_hash(),"identical":True}
    atomic_write(out/"walkthrough.json", (json.dumps(trace,indent=2)+"\n").encode())
    timing_bytes = (json.dumps({"total_battles":count,"seconds":round(time.perf_counter()-started,3),"workers":args.workers,"resumed_selected_groups":reused,"identity":identity,"group_seconds_sum":round(sum(t["seconds"] for t in timing),4),"groups":timing},indent=2)+"\n").encode()
    atomic_write(out/"timing.json", timing_bytes)
    atomic_write(out/"timings"/(str(time.time_ns())+".json"), timing_bytes)
    manifest={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(out.iterdir()) if p.name not in ("timing.json","manifest.json",".runner.lock") and p.is_file()}
    atomic_write(out/"manifest.json", (json.dumps(manifest,indent=2)+"\n").encode())
    print("COMPLETE",count,"battles",round(time.perf_counter()-started,2),"seconds",flush=True)


if __name__ == "__main__":
    main()
