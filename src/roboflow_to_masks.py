"""Convert a Roboflow export into the images/ + masks/ layout used here.

Two Roboflow export formats are understood (unzip the download first):

  "Semantic Segmentation Masks" (png-mask-semantic, Semantic Segmentation projects)
      train/ valid/ test/ each holding  NAME.jpg  and  NAME_mask.png
      Mask pixels are class indices (0 = background); every non-zero class
      counts as foreground ("disease").
  "COCO Segmentation" (Instance Segmentation projects)
      train/ valid/ test/ each holding images and _annotations.coco.json;
      every polygon is filled as foreground.

Roboflow's train/valid/test folders become train.txt / val.txt / test.txt, so
train.py selects its checkpoint on Roboflow's valid split (never on the test
images). Augmented copies made by Roboflow are only in train/.

    python -m src.roboflow_to_masks --src ~/Downloads/leaf-spots.v1i.png-mask-semantic \
        --out dataset/custom/roboflow_leaf
    # optional: how close are my hand labels to LDSD's own masks?
    python -m src.roboflow_to_masks --src ... --out ... --compare data/LDSD/data/data

Roboflow renames files to ORIGINAL_jpg.rf.<hash>.jpg; the original name is
recovered for --compare (and written to sources.csv).
"""

import argparse
import csv
import json
import os
import re
import shutil
from glob import glob

import numpy as np
from PIL import Image, ImageDraw

from .dataset import IMAGE_EXTS, load_mask

SPLITS = {"train": "train", "valid": "val", "val": "val", "test": "test"}
RF_NAME = re.compile(r"^(?P<orig>.+?)_(jpe?g|png|bmp)\.rf\.[0-9a-zA-Z]+$")


def original_stem(stem):
    m = RF_NAME.match(stem)
    return m.group("orig") if m else stem


def pairs_semantic(folder):
    """(image path, mask array 0/1) for NAME.jpg + NAME_mask.png pairs."""
    for mpath in sorted(glob(os.path.join(folder, "*_mask.png"))):
        stem = os.path.basename(mpath)[: -len("_mask.png")]
        img = next((os.path.join(folder, stem + e) for e in IMAGE_EXTS
                    if os.path.exists(os.path.join(folder, stem + e))), None)
        if img is None:
            print(f"  no image for {mpath}, skipped")
            continue
        mask = np.asarray(Image.open(mpath))
        if mask.ndim == 3:
            mask = mask.max(axis=2)
        yield img, (mask > 0).astype(np.uint8)


def pairs_coco(folder):
    """(image path, mask array 0/1) from _annotations.coco.json polygons."""
    with open(os.path.join(folder, "_annotations.coco.json")) as f:
        coco = json.load(f)
    by_image = {}
    for ann in coco["annotations"]:
        by_image.setdefault(ann["image_id"], []).append(ann)
    for info in coco["images"]:
        canvas = Image.new("L", (info["width"], info["height"]), 0)
        draw = ImageDraw.Draw(canvas)
        for ann in by_image.get(info["id"], []):
            seg = ann.get("segmentation")
            if isinstance(seg, list) and seg:
                for poly in seg:
                    if len(poly) >= 6:
                        draw.polygon(list(zip(poly[0::2], poly[1::2])), fill=1)
            else:  # no polygon: fall back to the box
                x, y, w, h = ann["bbox"]
                draw.rectangle((x, y, x + w, y + h), fill=1)
        yield os.path.join(folder, info["file_name"]), np.asarray(canvas, dtype=np.uint8)


def dice(a, b):
    a, b = a.astype(bool), b.astype(bool)
    return (2 * (a & b).sum() + 1e-9) / (a.sum() + b.sum() + 1e-9)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--src", required=True, help="unzipped Roboflow export (has train/, valid/, ...)")
    ap.add_argument("--out", required=True)
    ap.add_argument("--compare", help="dataset with reference masks (e.g. LDSD) to score the hand labels")
    args = ap.parse_args()

    for sub in ("images", "masks"):
        os.makedirs(os.path.join(args.out, sub), exist_ok=True)

    lists = {"train": [], "val": [], "test": []}
    sources = []
    for folder_name, split in SPLITS.items():
        folder = os.path.join(args.src, folder_name)
        if not os.path.isdir(folder):
            continue
        if os.path.exists(os.path.join(folder, "_annotations.coco.json")):
            pairs = pairs_coco(folder)
        else:
            pairs = pairs_semantic(folder)
        for img, mask in pairs:
            stem = os.path.splitext(os.path.basename(img))[0]
            shutil.copy(img, os.path.join(args.out, "images", os.path.basename(img)))
            Image.fromarray(mask * 255).save(os.path.join(args.out, "masks", stem + ".png"))
            lists[split].append(stem)
            sources.append((stem, split, original_stem(stem), float(mask.mean())))

    for split, stems in lists.items():
        path = os.path.join(args.out, f"{split}.txt")
        if stems:
            with open(path, "w") as f:
                f.write("\n".join(sorted(stems)) + "\n")
        elif os.path.exists(path):
            os.remove(path)
    with open(os.path.join(args.out, "sources.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["stem", "split", "original", "mask_fraction"])
        w.writerows(sources)
    print("converted: " + ", ".join(f"{k} {len(v)}" for k, v in lists.items()) + f" -> {args.out}")
    if not lists["val"] and not lists["test"]:
        print("warning: no valid/test split; train.py needs val.txt or test.txt "
              "(python -m src.split can make one)")

    if args.compare:
        # Score each original photo once. Augmented copies in train/ are flipped or
        # rotated, so the best-matching copy is taken as the un-augmented one.
        best = {}
        for stem, split, orig, _ in sources:
            ref = os.path.join(args.compare, "masks", orig.replace("leaf_", "", 1) + ".png")
            if not os.path.exists(ref):
                continue
            mine = load_mask(os.path.join(args.out, "masks", stem + ".png"), 256)
            d = dice(mine, load_mask(ref, 256))
            best[orig] = max(best.get(orig, 0.0), d)
        if best:
            vals = np.array(list(best.values()))
            print(f"hand labels vs reference masks ({len(vals)} photos, 256x256): "
                  f"Dice mean {vals.mean():.3f}, median {np.median(vals):.3f}, "
                  f"min {vals.min():.3f}, max {vals.max():.3f}")
            with open(os.path.join(args.out, "agreement.csv"), "w", newline="") as f:
                w = csv.writer(f)
                w.writerow(["original", "dice_vs_reference"])
                w.writerows(sorted(best.items()))


if __name__ == "__main__":
    main()
