"""Verify every completed battle against the unmodified pushed simulator."""
import argparse
from concurrent.futures import ProcessPoolExecutor
from dataclasses import asdict
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time

from run import cases, canonical, checkpoint_path
from verify_equivalence import BASELINE


def compare(task):
    directory, output, case = task
    group,n,kwargs=case
    spec=importlib.util.spec_from_file_location('reference',Path(directory)/'combat.py')
    module=importlib.util.module_from_spec(spec);sys.modules[spec.name]=module;spec.loader.exec_module(module)
    if 'rules' in kwargs: kwargs['rules']=module.Rules(**asdict(kwargs['rules']))
    rows=json.loads(checkpoint_path(output,group).read_bytes())['rows']
    started=time.perf_counter()
    for seed in range(n):
        actual=module.Battle(seed=seed,**kwargs).run();actual['group']=group
        assert actual==rows[seed], (group,seed,'baseline result divergence')
    return dict(group=group,battles=n,seconds=time.perf_counter()-started,
                rows_sha256=hashlib.sha256(canonical(rows)).hexdigest())


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',type=Path,default=Path(__file__).parent/'results')
    parser.add_argument('--workers',type=int,default=4)
    args=parser.parse_args();started=time.perf_counter()
    source=subprocess.check_output(['git','show',BASELINE+':research/game86/combat.py'])
    with tempfile.TemporaryDirectory() as directory:
        (Path(directory)/'combat.py').write_bytes(source)
        with ProcessPoolExecutor(max_workers=args.workers) as pool:
            results=list(pool.map(compare,[(directory,args.output,c) for c in cases()]))
    report=dict(baseline_commit=BASELINE,baseline_source_sha256=hashlib.sha256(source).hexdigest(),
                battles=sum(r['battles'] for r in results),groups=len(results),
                every_result_and_final_state_equal=True,workers=args.workers,
                seconds=time.perf_counter()-started,group_timings=results)
    (args.output/'profile/full-equivalence.json').write_text(json.dumps(report,indent=2)+'\n')
    print('PASS',report['battles'],'baseline results and final state hashes',report['seconds'],'seconds')

if __name__=='__main__':main()
