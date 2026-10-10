import unittest
from diagnostics import IllusionTruth, illusion_observation, illusion_proof, lane, probability_diagnostics


class DiagnosticTests(unittest.TestCase):
    def test_unbounded_kite_and_bounded_false_reassurance(self):
        self.assertIsNone(lane()["contact_turn"])
        self.assertIsNotNone(lane(boundary=15)["contact_turn"])
        self.assertIsNotNone(lane(dash=True, charge=True)["contact_turn"])

    def test_illusion_truth_does_not_leak_to_policy(self):
        self.assertEqual(illusion_observation(IllusionTruth(False, "secret-a")), illusion_observation(IllusionTruth(True, "secret-b")))
        p=illusion_proof()
        self.assertGreater(p["redirected_steps"], 0)
        self.assertTrue(p["other_observer_still_believes"])
        self.assertEqual(p["decoy_attack_after"]["actions"], 0)

    def test_accuracy_enumeration(self):
        row=next(r for r in probability_diagnostics() if r["attack"]==7 and r["ac"]==15)
        self.assertEqual(row["hit_probability"], .65)
        self.assertAlmostEqual(row["expected_damage"], 5.4)


if __name__ == "__main__":
    unittest.main()

