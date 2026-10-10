"""Compare every event and result with the pushed simulator, not just win rates.

Baseline source is loaded from git without changing the checkout. Two seeds per
original experiment group exercise all 209 configurations. --seeds 128 expands it.
"""
import argparse
import cProfile
from dataclasses import asdict
import hashlib
import importlib.util
import json
from pathlib import Path
import pstats
import subprocess
import sys
import tempfile
import time

from combat import Battle
from run import cases, canonical

BASELINE = '4c98a33ee7cf4ea63dddb96c82716242884d49c1'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--seeds', type=int, default=2)
    parser.add_argument('--output', type=Path, default=Path(__file__).parent/'results/profile')
    args = parser.parse_args()
    source = subprocess.check_output(['git','show',BASELINE+':research/game86/combat.py'])
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory)/'baseline.py'; path.write_bytes(source)
        spec = importlib.util.spec_from_file_location('game86_baseline',path)
        baseline = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = baseline; spec.loader.exec_module(baseline)
        timing = {'baseline':0.0, 'optimized':0.0}; profiles={k:cProfile.Profile() for k in timing}
        digest=hashlib.sha256(); count=0; groups=[]
        for group,n,kwargs in cases():
            for seed in range(min(n,args.seeds)):
                old_kwargs=dict(kwargs)
                if 'rules' in kwargs: old_kwargs['rules']=baseline.Rules(**asdict(kwargs['rules']))
                values=[]
                for name,cls,options in [('baseline',baseline.Battle,old_kwargs),('optimized',Battle,kwargs)]:
                    start=time.perf_counter(); profiles[name].enable()
                    battle=cls(seed=seed,**options); result=battle.run()
                    profiles[name].disable(); timing[name]+=time.perf_counter()-start
                    values.append((result,battle.log))
                assert values[0]==values[1], (group,seed,'result/event divergence')
                digest.update(canonical([group,seed,values[1]])); count+=1
            groups.append(group)
        args.output.mkdir(parents=True,exist_ok=True)
        report=dict(baseline_commit=BASELINE,baseline_source_sha256=hashlib.sha256(source).hexdigest(),
                    groups=len(groups),battles=count,seeds_per_group=args.seeds,
                    complete_event_and_result_equivalence=True,comparison_sha256=digest.hexdigest(),
                    profiled_seconds=timing,speedup=timing['baseline']/timing['optimized'])
        (args.output/'equivalence.json').write_text(json.dumps(report,indent=2)+'\n')
        for name,profile in profiles.items():
            with (args.output/(name+'.txt')).open('w') as f:
                pstats.Stats(profile,stream=f).strip_dirs().sort_stats('cumulative').print_stats(35)
            path = args.output/(name+'.txt')
            path.write_text(path.read_text().rstrip()+'\n')
        print(json.dumps(report,indent=2))

if __name__=='__main__': main()
