"""Convert Labelme annotations into the images/ + masks/ layout.

Labelme (pip install labelme) saves one JSON per photo, next to the photo,
with every polygon you drew. This script fills those polygons into a binary
mask (all labels count as foreground), resizes nothing, and copies the photo.

    python -m src.labelme_to_masks --src raw_photos/ --out dataset/custom/leaf
"""

import argparse
import json
import os
import shutil
from glob import glob

from PIL import Image, ImageDraw


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--src", required=True, help="folder with photos and their Labelme .json files")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    os.makedirs(os.path.join(args.out, "images"), exist_ok=True)
    os.makedirs(os.path.join(args.out, "masks"), exist_ok=True)

    done = 0
    for jpath in sorted(glob(os.path.join(args.src, "*.json"))):
        with open(jpath) as f:
            ann = json.load(f)
        photo = os.path.join(os.path.dirname(jpath), ann["imagePath"])
        stem = os.path.splitext(os.path.basename(photo))[0]
        w, h = ann["imageWidth"], ann["imageHeight"]

        mask = Image.new("L", (w, h), 0)
        draw = ImageDraw.Draw(mask)
        for shape in ann["shapes"]:
            pts = [tuple(p) for p in shape["points"]]
            kind = shape.get("shape_type", "polygon")
            if kind == "polygon" and len(pts) >= 3:
                draw.polygon(pts, fill=255)
            elif kind == "rectangle" and len(pts) == 2:
                draw.rectangle(pts, fill=255)
            elif kind == "circle" and len(pts) == 2:
                (cx, cy), (px, py) = pts
                r = ((px - cx) ** 2 + (py - cy) ** 2) ** 0.5
                draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)

        shutil.copy(photo, os.path.join(args.out, "images", os.path.basename(photo)))
        mask.save(os.path.join(args.out, "masks", stem + ".png"))
        done += 1
    print(f"converted {done} annotated photos into {args.out}")


if __name__ == "__main__":
    main()
