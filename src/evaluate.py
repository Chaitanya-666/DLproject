"""Test FANet with iterative refinement, and save pictures.

    python -m src.evaluate --ckpt runs/kvasir/best.pt --data data/Kvasir-SEG --split test
    python -m src.evaluate --ckpt runs/leaf/best.pt --images my_photos/       # no ground truth

Test-time refinement (from the paper): start each test image's memory from the
Otsu guess (or, with --start zeros, from an empty mask), predict, put the prediction back into memory, predict again, and so
on for --iters rounds. Metrics are reported after every round, so you can see
whether the masks improve (results.csv).

Outputs in --out (default: next to the checkpoint, in eval_<split>/):
    results.csv        one row per refinement round: Dice, IoU, ..., box metrics, FPS
    strips/<name>.png  image | ground truth | Otsu start | round 1 | round 2 | ...
    masks/<name>.png   final predicted mask
"""

import argparse
import csv
import os
import time

import numpy as np
import torch
from PIL import Image
from torch.utils.data import DataLoader

from .dataset import ImageFolderDataset, SegmentationDataset
from .memory import MaskMemory
from .metrics import NAMES, BoxAverager, MetricAverager
from .model import FANet
from .train import pick_device


def overlay(image_uint8, mask, color=(0, 110, 255), alpha=0.45):
    """Paint a mask on an image, with a solid outline."""
    img = image_uint8.astype(np.float32).copy()
    m = mask.astype(bool)
    img[m] = img[m] * (1 - alpha) + np.array(color) * alpha
    edge = m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))
    img[edge] = color
    return img.astype(np.uint8)


def save_strip(path, image, panels, gap=6):
    h, w, _ = image.shape
    tiles = [image] + [overlay(image, p) for p in panels]
    canvas = np.full((h, len(tiles) * (w + gap) - gap, 3), 255, dtype=np.uint8)
    for k, tile in enumerate(tiles):
        canvas[:, k * (w + gap):k * (w + gap) + w] = tile
    Image.fromarray(canvas).save(path)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ckpt", required=True)
    ap.add_argument("--data", help="dataset folder (images/, masks/, split files)")
    ap.add_argument("--split", default="test")
    ap.add_argument("--images", help="plain folder of images, no ground truth")
    ap.add_argument("--iters", type=int, default=5, help="refinement rounds (official code: 10)")
    ap.add_argument("--start", choices=["otsu", "zeros"], default="otsu",
                    help="round-0 memory: Otsu (official) or an empty mask (our extra experiment)")
    ap.add_argument("--batch", type=int, default=8)
    ap.add_argument("--strips", type=int, default=30, help="how many example strips to save")
    ap.add_argument("--out")
    ap.add_argument("--device", default="auto")
    args = ap.parse_args()
    if not (args.data or args.images):
        ap.error("give --data or --images")

    device = pick_device(args.device)
    state = torch.load(args.ckpt, map_location=device)
    size = state["args"]["size"]
    model = FANet().to(device)
    model.load_state_dict(state["model"])
    model.eval()

    has_gt = args.images is None
    data = SegmentationDataset(args.data, args.split, size) if has_gt else ImageFolderDataset(args.images, size)
    loader = DataLoader(data, batch_size=args.batch, shuffle=False)
    # A model trained with --no-feedback is also tested without feedback.
    memory = MaskMemory(data.images, feedback=not state["args"].get("no_feedback", False))
    if args.start == "zeros":
        memory.masks.zero_()
        memory.staged.zero_()

    tag = args.split if has_gt else "images"
    if args.start != "otsu":
        tag += f"_{args.start}"
    out = args.out or os.path.join(os.path.dirname(args.ckpt), f"eval_{tag}")
    os.makedirs(os.path.join(out, "strips"), exist_ok=True)
    os.makedirs(os.path.join(out, "masks"), exist_ok=True)

    history = [memory.masks.squeeze(1).numpy().copy()]   # round 0 = Otsu start
    rows = []
    for it in range(1, args.iters + 1):
        scores, boxes, seconds = MetricAverager(), BoxAverager(), 0.0
        for image, target, idx in loader:
            image = image.to(device)
            prev = memory.get(idx, device)
            if device.type == "cuda":
                torch.cuda.synchronize()
            t0 = time.time()
            with torch.no_grad():
                probs = torch.sigmoid(model(image, prev))
            if device.type == "cuda":
                torch.cuda.synchronize()
            seconds += time.time() - t0
            memory.write(idx, probs)
            if has_gt:
                pred = (probs > 0.5).cpu().numpy()
                scores.update(pred, target.numpy())
                boxes.update(pred, target.numpy())
        history.append(memory.masks.squeeze(1).numpy().copy())

        row = {"round": it, "fps": len(data) / max(seconds, 1e-9)}
        if has_gt:
            row.update(scores.result())
            row.update(boxes.result())
        rows.append(row)
        print("round", it, " ".join(f"{k} {v:.4f}" for k, v in row.items() if k != "round"))

    with open(os.path.join(out, "results.csv"), "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    for i, stem in enumerate(data.stems):
        final = history[-1][i]
        Image.fromarray(final * 255).save(os.path.join(out, "masks", f"{stem}.png"))
        if i < args.strips:
            panels = ([data.masks[i]] if has_gt else []) + [h[i] for h in history]
            save_strip(os.path.join(out, "strips", f"{stem}.png"), data.images[i], panels)

    if has_gt:
        best = max(rows, key=lambda r: r["dice"])
        print(f"best round {best['round']}: " + ", ".join(f"{k} {best[k]:.4f}" for k in NAMES))
    print(f"saved to {out}")


if __name__ == "__main__":
    main()
