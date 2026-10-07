"""Reproducible experiments. Run from any directory: python research/game86/run.py.

Reports are deterministic; wall-clock measurements go in a separate timing.json.
No third-party dependency, network, Godot, canonical fixture or save access.
"""
from collections import defaultdict
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


def main():
    OUT.mkdir(exist_ok=True)
    started=time.perf_counter();summaries=[];count=0;paired={};timing=[]
    with open(OUT/"battles.jsonl.gz","wb") as raw, gzip.GzipFile(fileobj=raw,mode="wb",filename="",mtime=0) as archive:
        for group,n,kwargs in cases():
            now=time.perf_counter();rows=[]
            for seed in range(n):
                b=Battle(seed=seed,**kwargs);r=b.run();r["group"]=group
                archive.write((json.dumps(r,sort_keys=True,separators=(",",":"))+"\n").encode());rows.append(r);count+=1
            summaries.append(aggregate(group,rows))
            paired[group]=rows
            timing.append({"group":group,"battles":n,"seconds":round(time.perf_counter()-now,4)})
            print(group,n,"rounds",summaries[-1]["mean_rounds"],"timeouts",summaries[-1]["timeouts"],flush=True)
    with (OUT/"summary.csv").open("w") as f:
        writer=csv.DictWriter(f,fieldnames=list(summaries[0]));writer.writeheader();writer.writerows(summaries)
    (OUT/"summary.json").write_text(json.dumps(summaries,indent=2)+"\n")
    comparisons=[]
    for alternate in ("none","stun"):
        base=paired["control/slow"];other=paired["control/"+alternate]
        diffs=[int(a["outcome"]=="0")-int(b["outcome"]=="0") for a,b in zip(base,other)]
        comparisons.append({"paired":f"left win: slow minus {alternate}","n":len(diffs),"mean":statistics.mean(diffs),
                            "descriptive_se":statistics.stdev(diffs)/(len(diffs)**.5),"discordant_seeds":sum(d!=0 for d in diffs)})
    (OUT/"paired.json").write_text(json.dumps(comparisons,indent=2)+"\n")
    (OUT/"diagnostics.json").write_text(json.dumps(all_diagnostics(),indent=2)+"\n")
    b=Battle(seed=1,left=MATCHUPS["party"][0],right=MATCHUPS["party"][1],terrain="moderate")
    result=b.run()
    replay=Battle(seed=1,left=MATCHUPS["party"][0],right=MATCHUPS["party"][1],terrain="moderate")
    assert result==replay.run(replay_commands(b))
    trace={"seed":1,"rules":asdict(b.rules),"left":MATCHUPS["party"][0],"right":MATCHUPS["party"][1],"terrain":"moderate","size":12,"separation":8,
           "board":{"walls":sorted(b.board.walls),"cover":sorted(b.board.cover)},"initiative":b.order,"events":b.log,"result":result,
           "command_replay_sha256":replay.state_hash(),"identical":True}
    (OUT/"walkthrough.json").write_text(json.dumps(trace,indent=2)+"\n")
    (OUT/"timing.json").write_text(json.dumps({"total_battles":count,"seconds":round(time.perf_counter()-started,3),"groups":timing},indent=2)+"\n")
    manifest={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.name not in ("timing.json","manifest.json") and p.is_file()}
    (OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print("COMPLETE",count,"battles",round(time.perf_counter()-started,2),"seconds",flush=True)


if __name__ == "__main__":
    main()
