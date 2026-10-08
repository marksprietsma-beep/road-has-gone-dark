import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest

from combat import Battle, Board, Budget, choose
from run import cases, canonical, checkpoint_path, experiment_identity, load_checkpoint, main, run_group


class RunnerTests(unittest.TestCase):
    def test_scope_is_preserved(self):
        design=list(cases())
        self.assertEqual(len(design),209)
        self.assertEqual(sum(n for _,n,_ in design),19456)
        self.assertEqual(len({g for g,_,_ in design}),209)

    def test_resume_and_corruption_rejection(self):
        with tempfile.TemporaryDirectory() as tmp:
            case=('test/duel',3,{})
            identity=experiment_identity()
            _,first,cached=run_group(tmp,identity,case)
            self.assertFalse(cached)
            path=checkpoint_path(tmp,case[0]); before=path.read_bytes()
            _,second,cached=run_group(tmp,identity,case)
            self.assertTrue(cached);self.assertEqual(first,second);self.assertEqual(before,path.read_bytes())
            with self.assertRaises(AssertionError):load_checkpoint(path,'different-source',case[0],3)
            broken=json.loads(before);broken['rows'][0]['outcome']='corrupted'
            path.write_text(json.dumps(broken))
            with self.assertRaises(AssertionError):run_group(tmp,identity,case)

    def test_serial_parallel_and_interrupted_group_resume_equivalent(self):
        # Finish two actual groups in either schedule, then resume one completed
        # group beside an abandoned temporary file (the interrupted-write case).
        groups=['core/A/fighter_archer/open','core/A/fighter_archer/moderate']
        with tempfile.TemporaryDirectory() as a,tempfile.TemporaryDirectory() as b:
            with contextlib.redirect_stdout(io.StringIO()):
                main(['--output',a,'--group',groups[0]])
                (Path(a)/'groups/.partial-interrupted').write_text('{incomplete')
                main(['--output',a,'--group',groups[0],'--group',groups[1]])
                main(['--output',b,'--workers','2','--group',groups[0],'--group',groups[1]])
            for group in groups:
                left=json.loads(checkpoint_path(a,group).read_bytes())
                right=json.loads(checkpoint_path(b,group).read_bytes())
                self.assertEqual(left['rows'],right['rows'])
                self.assertEqual(left['rows_sha256'],right['rows_sha256'])
            self.assertFalse((Path(a)/'summary.json').exists()) # no false COMPLETE

    def test_cached_paths_occupancy_and_immutability(self):
        board=Board(5)
        clear=board.paths((0,0),3)
        blocked=board.paths((0,0),3,{(1,0)})
        self.assertIn((1,0),clear);self.assertNotIn((1,0),blocked)
        with self.assertRaises(TypeError):clear[(4,4)]=()
        self.assertEqual(list(board.paths((0,0),2).items()),[(p,path) for p,path in clear.items() if len(path)<=2])

    def test_pending_observation_is_detached(self):
        battle=Battle(left=('mage',))
        actor=battle.units[0];actor.pending={'tile':(2,2)}
        view=battle.observe(actor);view['units'][0]['pending']['tile']=(3,3)
        self.assertEqual(actor.pending['tile'],(2,2))

if __name__=='__main__':unittest.main()
