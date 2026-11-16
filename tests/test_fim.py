import hashlib, json, subprocess, sys, tempfile, unittest
from pathlib import Path
SCRIPT=Path(__file__).resolve().parents[1]/"scripts"/"fim.py"
class FimTests(unittest.TestCase):
    def test_baseline_match_and_tamper_detection(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)/"site"; root.mkdir(); target=root/"index.php"; target.write_text("safe")
            baseline=Path(temp)/"baseline.json"
            baseline.write_text(json.dumps({"index.php":hashlib.sha256(b"safe").hexdigest()}))
            def run(): return subprocess.run([sys.executable,str(SCRIPT),"--root",str(root),"--version","local","--baseline",str(baseline)],capture_output=True,text=True)
            self.assertEqual(run().returncode,0)
            target.write_text("tampered")
            self.assertEqual(run().returncode,1)
if __name__=="__main__": unittest.main()
