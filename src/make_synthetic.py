"""Generate a small synthetic segmentation dataset (for the PPT's "own dataset").

Two modes:

1) procedural  -- draws everything from scratch: a leaf on a plain background,
   with 1-4 irregular brown "disease spots". The mask is known exactly because
   we drew the spots ourselves, so no manual annotation is needed.

       python -m src.make_synthetic procedural --out dataset/custom/synthetic_leaf --n 60

2) paste       -- copy-paste synthesis from real photos: cut objects out of
   annotated images (using their masks) and paste them, randomly scaled,
   rotated and colour-shifted, onto clean background photos. Each paste
   position is recorded, so the new mask is exact.

       python -m src.make_synthetic paste --objects dataset/custom/leaf \
           --backgrounds dataset/custom/backgrounds --out dataset/custom/leaf_paste --n 100

Output layout matches Kvasir-SEG: images/*.jpg, masks/*.png, plus
bboxes.json (boxes per image) and generation_log.csv (every random choice),
so the dataset can be explained and regenerated exactly with the same --seed.
"""

import argparse
import csv
import json
import math
import os
from glob import glob

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

from .metrics import mask_to_boxes


def blob_polygon(rng, cx, cy, radius, points=24, roughness=0.35):
    """An irregular closed shape: a circle whose radius wobbles with angle."""
    phase = rng.uniform(0, 2 * math.pi, size=3)
    poly = []
    for k in range(points):
        a = 2 * math.pi * k / points
        wobble = (math.sin(2 * a + phase[0]) + 0.6 * math.sin(3 * a + phase[1])
                  + 0.3 * math.sin(5 * a + phase[2])) / 1.9
        r = radius * (1 + roughness * wobble + rng.uniform(-0.08, 0.08))
        poly.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return poly


def procedural_sample(rng, size):
    bg = tuple(int(v) for v in rng.integers(170, 235, size=3))
    img = Image.new("RGB", (size, size), bg)
    draw = ImageDraw.Draw(img)

    # Leaf: a big ellipse in a random shade of green, with a midrib and veins.
    green = (int(rng.integers(40, 90)), int(rng.integers(110, 170)), int(rng.integers(30, 80)))
    m = size * 0.08
    leaf_box = (m + rng.uniform(-m / 2, m / 2), m * 2, size - m + rng.uniform(-m / 2, m / 2), size - m * 2)
    draw.ellipse(leaf_box, fill=green)
    cx, cy = (leaf_box[0] + leaf_box[2]) / 2, (leaf_box[1] + leaf_box[3]) / 2
    vein = tuple(min(c + 35, 255) for c in green)
    draw.line([(leaf_box[0] + 10, cy), (leaf_box[2] - 10, cy)], fill=vein, width=3)
    for k in range(1, 5):
        x = leaf_box[0] + (leaf_box[2] - leaf_box[0]) * k / 5
        draw.line([(x, cy), (x + 25, cy - 45)], fill=vein, width=2)
        draw.line([(x, cy), (x + 25, cy + 45)], fill=vein, width=2)
    leaf_mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(leaf_mask).ellipse(leaf_box, fill=255)

    # Spots: drawn on the image and, identically, on the mask. Both are
    # clipped to the leaf afterwards, so a spot never hangs off the edge.
    leaf_only = img.copy()
    mask = Image.new("L", (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    n_spots = int(rng.integers(1, 5))
    spots = []
    for _ in range(n_spots):
        for _try in range(20):
            sx = rng.uniform(leaf_box[0] + 25, leaf_box[2] - 25)
            sy = rng.uniform(leaf_box[1] + 25, leaf_box[3] - 25)
            if leaf_mask.getpixel((int(sx), int(sy))):
                break
        r = rng.uniform(size * 0.04, size * 0.11)
        poly = blob_polygon(rng, sx, sy, r)
        halo = blob_polygon(rng, sx, sy, r * 1.25, roughness=0.2)
        draw.polygon(halo, fill=(int(rng.integers(160, 210)), int(rng.integers(150, 190)), 40))  # yellow ring
        brown = (int(rng.integers(90, 140)), int(rng.integers(50, 80)), int(rng.integers(20, 45)))
        draw.polygon(poly, fill=brown)
        mdraw.polygon(poly, fill=255)
        spots.append({"x": round(sx, 1), "y": round(sy, 1), "r": round(r, 1)})
    img = Image.composite(img, leaf_only, leaf_mask)
    mask = Image.composite(mask, Image.new("L", (size, size), 0), leaf_mask)

    # Camera-like realism: slight blur, lighting gradient, sensor noise.
    img = img.filter(ImageFilter.GaussianBlur(radius=float(rng.uniform(0.3, 1.2))))
    arr = np.asarray(img).astype(np.float32)
    grad = np.linspace(rng.uniform(0.85, 1.0), rng.uniform(1.0, 1.15), size)[None, :, None]
    arr = arr * grad + rng.normal(0, 6, arr.shape)
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    return img, mask, {"spots": n_spots, "spot_detail": spots, "background": bg, "leaf_green": green}


def paste_sample(rng, size, objects, backgrounds, max_objects=3):
    bg_path = backgrounds[int(rng.integers(len(backgrounds)))]
    img = Image.open(bg_path).convert("RGB").resize((size, size))
    mask = Image.new("L", (size, size), 0)
    record = {"background": os.path.basename(bg_path), "pastes": []}
    for _ in range(int(rng.integers(1, max_objects + 1))):
        img_path, mask_path = objects[int(rng.integers(len(objects)))]
        src = Image.open(img_path).convert("RGB")
        src_m = Image.open(mask_path).convert("L").point(lambda v: 255 if v > 127 else 0)
        bbox = src_m.getbbox()
        if bbox is None:
            continue
        src, src_m = src.crop(bbox), src_m.crop(bbox)
        scale = rng.uniform(0.15, 0.45) * size / max(src.size)
        new = (max(int(src.width * scale), 4), max(int(src.height * scale), 4))
        angle = float(rng.uniform(0, 360))
        src = src.resize(new, Image.BILINEAR).rotate(angle, expand=True)
        src_m = src_m.resize(new, Image.NEAREST).rotate(angle, expand=True)
        src = ImageEnhance.Brightness(src).enhance(float(rng.uniform(0.8, 1.2)))
        src = ImageEnhance.Color(src).enhance(float(rng.uniform(0.8, 1.2)))
        x = int(rng.integers(0, max(size - src.width, 1)))
        y = int(rng.integers(0, max(size - src.height, 1)))
        img.paste(src, (x, y), src_m)
        mask.paste(255, (x, y), src_m)
        record["pastes"].append({"object": os.path.basename(img_path), "x": x, "y": y,
                                 "scale": round(scale, 3), "angle": round(angle, 1)})
    return img, mask, record


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("mode", choices=["procedural", "paste"])
    ap.add_argument("--out", required=True)
    ap.add_argument("--n", type=int, default=60)
    ap.add_argument("--size", type=int, default=256)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--objects", help="paste mode: folder with images/ and masks/ to cut objects from")
    ap.add_argument("--backgrounds", help="paste mode: folder of clean background photos")
    args = ap.parse_args()

    rng = np.random.default_rng(args.seed)
    os.makedirs(os.path.join(args.out, "images"), exist_ok=True)
    os.makedirs(os.path.join(args.out, "masks"), exist_ok=True)

    if args.mode == "paste":
        if not (args.objects and args.backgrounds):
            ap.error("paste mode needs --objects and --backgrounds")
        from .dataset import find_file, list_stems
        objects = [(find_file(os.path.join(args.objects, "images"), s),
                    find_file(os.path.join(args.objects, "masks"), s)) for s in list_stems(args.objects)]
        backgrounds = sorted(p for p in glob(os.path.join(args.backgrounds, "*"))
                             if p.lower().endswith((".jpg", ".jpeg", ".png")))
        if not objects or not backgrounds:
            raise SystemExit("no objects or no backgrounds found")

    boxes, log_rows = {}, []
    for i in range(args.n):
        name = f"syn_{i:04d}"
        if args.mode == "procedural":
            img, mask, info = procedural_sample(rng, args.size)
        else:
            img, mask, info = paste_sample(rng, args.size, objects, backgrounds)
        img.save(os.path.join(args.out, "images", name + ".jpg"), quality=95)
        mask.save(os.path.join(args.out, "masks", name + ".png"))
        m = np.asarray(mask) > 127
        boxes[name] = [{"xmin": b[0], "ymin": b[1], "xmax": b[2], "ymax": b[3]} for b in mask_to_boxes(m)]
        log_rows.append({"name": name, "mask_fraction": round(float(m.mean()), 4),
                         "boxes": len(boxes[name]), "params": json.dumps(info)})

    with open(os.path.join(args.out, "bboxes.json"), "w") as f:
        json.dump(boxes, f, indent=1)
    with open(os.path.join(args.out, "generation_log.csv"), "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(log_rows[0].keys()))
        writer.writeheader()
        writer.writerows(log_rows)
    print(f"wrote {args.n} samples to {args.out} (mode {args.mode}, seed {args.seed})")


if __name__ == "__main__":
    main()
