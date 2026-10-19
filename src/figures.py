"""Make the result figures for the PPT from the runs/ folder.

    python -m src.figures --runs runs --out presentation/figures

Reads whatever exists (missing runs are skipped):
    runs/kvasir/log.csv                  learning curves of the main run
    runs/kvasir_nofb/log.csv             the no-feedback ablation, drawn on the same axes
    runs/kvasir/eval_test/results.csv    metrics after each test-time refinement round
    runs/*/eval_*/strips/*.png           image | ground truth | Otsu | round 1 | ...

Writes PNGs into --out.
"""

import argparse
import csv
import os
from glob import glob

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402


def read_csv(path):
    if not os.path.exists(path):
        return None
    with open(path) as f:
        rows = list(csv.DictReader(f))
    return {k: np.array([float(r[k]) for r in rows]) for k in rows[0]} if rows else None


def learning_curves(runs, out):
    main = read_csv(os.path.join(runs, "kvasir", "log.csv"))
    if main is None:
        return
    nofb = read_csv(os.path.join(runs, "kvasir_nofb", "log.csv"))
    fig, ax = plt.subplots(1, 2, figsize=(11, 3.8))
    ax[0].plot(main["epoch"], main["train_loss"], label="train")
    ax[0].plot(main["epoch"], main["val_loss"], label="test")
    ax[0].set(title="Loss (0.5 BCE + 0.5 Dice)", xlabel="epoch")
    ax[1].plot(main["epoch"], main["val_dice"], label="FANet (feedback)")
    if nofb is not None:
        ax[1].plot(nofb["epoch"], nofb["val_dice"], label="no feedback (zeros memory)")
    ax[1].set(title="Test Dice per epoch", xlabel="epoch", ylim=(0, 1))
    for a in ax:
        a.grid(alpha=0.3)
        a.legend()
    fig.tight_layout()
    fig.savefig(os.path.join(out, "learning_curves.png"), dpi=160)
    plt.close(fig)


def refinement(runs, out):
    res = read_csv(os.path.join(runs, "kvasir", "eval_test", "results.csv"))
    if res is None:
        return
    fig, ax = plt.subplots(figsize=(6, 3.8))
    for k in ("dice", "jaccard", "recall", "precision"):
        ax.plot(res["round"], res[k], marker="o", label=k)
    ax.set(title="Test-time iterative refinement", xlabel="refinement round", ylabel="score")
    ax.set_xticks(res["round"])
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(os.path.join(out, "refinement_rounds.png"), dpi=160)
    plt.close(fig)


def strip_montage(strip_dir, path, n=4):
    """Stack the first n strips vertically into one picture."""
    files = sorted(glob(os.path.join(strip_dir, "*.png")))[:n]
    if not files:
        return
    tiles = [np.asarray(Image.open(f).convert("RGB")) for f in files]
    width = max(t.shape[1] for t in tiles)
    gap = np.full((8, width, 3), 255, dtype=np.uint8)
    rows = []
    for t in tiles:
        pad = np.full((t.shape[0], width - t.shape[1], 3), 255, dtype=np.uint8)
        rows += [np.concatenate([t, pad], axis=1), gap]
    Image.fromarray(np.concatenate(rows[:-1], axis=0)).save(path)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--runs", default="runs")
    ap.add_argument("--out", default="presentation/figures")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    learning_curves(args.runs, args.out)
    refinement(args.runs, args.out)
    for strip_dir in glob(os.path.join(args.runs, "*", "eval_*", "strips")):
        run, ev = strip_dir.split(os.sep)[-3:-1]
        strip_montage(strip_dir, os.path.join(args.out, f"strips_{run}_{ev}.png"))
    print("figures in", args.out, ":", sorted(os.listdir(args.out)))


if __name__ == "__main__":
    main()
