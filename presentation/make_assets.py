"""Pictures for the PPT that do not come out of a training run.

    python presentation/make_assets.py          (from the repo root)

Writes into presentation/assets/:
    kvasir_example.png   one Kvasir-SEG test image | its ground-truth mask | overlay
    otsu_example.png     the same image | the Otsu starting mask FANet begins from
    leaf_examples.png    four synthetic leaf samples with their exact masks overlaid
    strip_<run>.png      first refinement strips of a run, copied for the deck
"""

import os
import shutil
import sys
from glob import glob

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from src.dataset import SegmentationDataset  # noqa: E402
from src.evaluate import overlay  # noqa: E402
from src.memory import otsu_mask  # noqa: E402

OUT = os.path.join("presentation", "assets")
GAP = 8


def row(tiles):
    h = tiles[0].shape[0]
    gap = np.full((h, GAP, 3), 255, dtype=np.uint8)
    parts = []
    for t in tiles:
        parts += [t, gap]
    return np.concatenate(parts[:-1], axis=1)


def gray3(mask):
    return np.repeat((mask * 255).astype(np.uint8)[..., None], 3, axis=2)


def main():
    os.makedirs(OUT, exist_ok=True)

    kv = SegmentationDataset("data/Kvasir-SEG", "test", 256)
    frac = kv.masks.reshape(len(kv), -1).mean(1)
    i = int(np.argmin(np.abs(frac - 0.18)))   # a typical, clearly visible polyp
    img, gt = kv.images[i], kv.masks[i]
    Image.fromarray(row([img, gray3(gt), overlay(img, gt)])).save(os.path.join(OUT, "kvasir_example.png"))
    Image.fromarray(row([img, gray3(otsu_mask(img))])).save(os.path.join(OUT, "otsu_example.png"))
    print("kvasir example:", kv.stems[i], f"polyp covers {100 * frac[i]:.1f}%")

    leaf = SegmentationDataset("dataset/custom/synthetic_leaf", "all", 256)
    Image.fromarray(row([overlay(leaf.images[k], leaf.masks[k]) for k in range(4)])).save(
        os.path.join(OUT, "leaf_examples.png"))

    for strip_dir in glob(os.path.join("runs", "*", "eval_test", "strips")):
        run = strip_dir.split(os.sep)[1]
        files = sorted(glob(os.path.join(strip_dir, "*.png")))
        if files:
            shutil.copy(files[0], os.path.join(OUT, f"strip_{run}.png"))
    print("assets:", sorted(os.listdir(OUT)))


if __name__ == "__main__":
    main()
