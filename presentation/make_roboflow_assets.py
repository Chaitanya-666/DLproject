"""Pictures for the Roboflow slides (run from the repo root, after src.roboflow_to_masks):

    python presentation/make_roboflow_assets.py

Writes to presentation/assets/:
    roboflow_grid.png        the 30 hand-labelled photos (cropped from the Roboflow dataset screenshot)
    roboflow_agreement.png   photo | my label | LDSD label, for a close match and a disagreement
"""

import csv
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.getcwd())
from src.dataset import load_mask  # noqa: E402
from src.roboflow_to_masks import dice  # noqa: E402

OUT = "presentation/assets"
SHOTS = os.path.join(OUT, "roboflow")
DATA = "dataset/custom/roboflow_leaf"
LDSD = "data/LDSD/data/data"
TILE = 256


def overlay(img, mask, colour):
    a = np.asarray(img.convert("RGB").resize((TILE, TILE)), dtype=float).copy()
    a[mask] = 0.45 * a[mask] + 0.55 * np.array(colour)
    return Image.fromarray(a.astype("uint8"))


def best_copy(rows, orig, ref):
    """Training photos only exist as augmented copies; take the copy closest to the reference."""
    copies = [r for r in rows if r["original"] == orig]
    return max(copies, key=lambda r: dice(load_mask(f"{DATA}/masks/{r['stem']}.png", TILE), ref))


def agreement(examples):
    rows = list(csv.DictReader(open(f"{DATA}/sources.csv")))
    scores = {r["original"]: float(r["dice_vs_reference"]) for r in csv.DictReader(open(f"{DATA}/agreement.csv"))}
    gap, head = 8, 28
    canvas = Image.new("RGB", (3 * TILE + 2 * gap, len(examples) * (TILE + head) ), "white")
    d = ImageDraw.Draw(canvas)
    for i, orig in enumerate(examples):
        ref = load_mask(f"{LDSD}/masks/{orig.replace('leaf_', '')}.png", TILE) > 0
        r = best_copy(rows, orig, ref)
        mine = load_mask(f"{DATA}/masks/{r['stem']}.png", TILE) > 0
        photo = Image.open(f"{DATA}/images/{r['stem']}.jpg")
        y = i * (TILE + head)
        d.text((4, y + 8), f"{orig}: Dice {scores[orig]:.2f} between the two labels", fill="black")
        canvas.paste(photo.convert("RGB").resize((TILE, TILE)), (0, y + head))
        canvas.paste(overlay(photo, mine, (230, 40, 200)), (TILE + gap, y + head))
        canvas.paste(overlay(Image.open(f"{LDSD}/images/{orig.replace('leaf_', '')}.jpg"), ref, (0, 190, 255)),
                     (2 * (TILE + gap), y + head))
    canvas.save(os.path.join(OUT, "roboflow_agreement.png"))


def grid():
    shot = Image.open(os.path.join(SHOTS, "01_dataset_grid_30_labelled.png"))
    shot.crop((362, 205, 1832, 1095)).save(os.path.join(OUT, "roboflow_grid.png"))


if __name__ == "__main__":
    grid()
    agreement(["leaf_00260", "leaf_00278"])
    print("wrote roboflow_grid.png, roboflow_agreement.png")
