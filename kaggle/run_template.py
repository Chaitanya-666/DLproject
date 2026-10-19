# FANet on Kaggle: finds the private code + data datasets, runs one experiment,
# leaves everything in /kaggle/working/runs (downloaded with `kaggle kernels output`).
import glob, os, subprocess, sys, zipfile

TRAIN_ARGS = "__TRAIN_ARGS__"
EVAL_ITERS = "__EVAL_ITERS__"
OUT = "runs/__RUN__"

W = "/kaggle/working"
os.chdir(W)

def find(pattern):
    hits = glob.glob(os.path.join("/kaggle/input", "**", pattern), recursive=True)
    return sorted(hits, key=len)[0] if hits else None

model = find("src/model.py")
if model:
    code = os.path.dirname(os.path.dirname(model))
else:
    zipfile.ZipFile(find("src.zip")).extractall(os.path.join(W, "code"))
    code = os.path.join(W, "code")

split = find("Kvasir-SEG/train.txt")
if split:
    data = os.path.dirname(split)
else:
    zipfile.ZipFile(find("Kvasir-SEG.zip")).extractall(os.path.join(W, "data"))
    data = os.path.join(W, "data", "Kvasir-SEG")
print("code:", code, "| data:", data, flush=True)
subprocess.run(["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv"])

env = dict(os.environ, PYTHONPATH=code)
def run(cmd):
    print(">>", cmd, flush=True)
    subprocess.run(f"{sys.executable} -u -m {cmd}", shell=True, check=True, env=env)

run(f"src.train --data {data} --out {OUT} --workers 4 {TRAIN_ARGS}")
run(f"src.evaluate --ckpt {OUT}/best.pt --data {data} --split test --iters {EVAL_ITERS} --strips 30")
print(open(f"{OUT}/eval_test/results.csv").read())
