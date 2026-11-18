"""Figure + counts for the Roboflow detection dataset (tomato leaves, 4 classes).

    python presentation/make_det_assets.py ~/Downloads/<export>.zip

Reads a Roboflow YOLOv8 export (train/valid/test with images/ and labels/, data.yaml),
writes presentation/assets/roboflow_det_grid.png (one labelled photo per class, boxes drawn)
and presentation/assets/roboflow_det_stats.json (images per split, originals, boxes per class).
"""
import json
import re
import sys
import zipfile
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "data" / "roboflow_det_export"
ASSETS = ROOT / "presentation" / "assets"
COLOURS = {"bacterial_spot": "#d1495b", "early_blight": "#edae49", "late_blight": "#7b2cbf", "healthy": "#2e7d32"}


def class_names(root):
    text = (root / "data.yaml").read_text()
    m = re.search(r"names:\s*\[(.*?)\]", text, re.S)
    if m:
        return [n.strip().strip("'\"") for n in m.group(1).split(",") if n.strip()]
    block = text.split("names:", 1)[1]
    return [re.sub(r"^\s*(-|\d+:)\s*", "", l).strip().strip("'\"") for l in block.splitlines()[1:]
            if re.match(r"^\s*(-|\d+:)", l)]


def source_name(path):
    # Roboflow renames "early_blight_01.jpg" to "early_blight_01_jpg.rf.<hash>.jpg"; copies share the stem.
    return path.name.split(".rf.")[0]


def main(zip_path):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(OUT_DIR)
    names = class_names(OUT_DIR)
    stats = {"classes": names, "splits": {}, "boxes_per_class": Counter(), "originals_per_class": Counter(), "boxes_on_originals": Counter()}
    originals = set()
    example = {}
    for split in ("train", "valid", "test"):
        imgs = sorted((OUT_DIR / split / "images").glob("*")) if (OUT_DIR / split).exists() else []
        stats["splits"][split] = {"images": len(imgs), "originals": len({source_name(p) for p in imgs})}
        for img in imgs:
            lab = OUT_DIR / split / "labels" / (img.stem + ".txt")
            rows = [l.split() for l in lab.read_text().splitlines() if l.strip()] if lab.exists() else []
            key = source_name(img)
            for r in rows:
                cls = names[int(r[0])]
                stats["boxes_per_class"][cls] += 1
                if key not in originals:
                    stats["boxes_on_originals"][cls] += 1
            if key not in originals:
                for cls in {names[int(r[0])] for r in rows}:
                    stats["originals_per_class"][cls] += 1  # photos containing this class
                if split != "train" and cls not in example and len(rows) == 1:
                    example[cls] = (img, rows)
            originals.add(key)
    stats["original_images"] = len(originals)
    stats["total_images"] = sum(s["images"] for s in stats["splits"].values())

    # 2x2 grid, one held-out photo per class with its box
    tile, pad = 300, 10
    order = [c for c in ("bacterial_spot", "early_blight", "late_blight", "healthy") if c in example] + \
            [c for c in example if c not in COLOURS]
    grid = Image.new("RGB", (2 * tile + 3 * pad, 2 * (tile + 34) + 3 * pad), "white")
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 20)
    except OSError:
        font = ImageFont.load_default()
    for i, cls in enumerate(order[:4]):
        img_path, rows = example[cls]
        im = Image.open(img_path).convert("RGB").resize((tile, tile))
        d = ImageDraw.Draw(im)
        for r in rows:
            cx, cy, w, h = (float(v) * tile for v in r[1:5])
            d.rectangle([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2], outline=COLOURS.get(cls, "red"), width=4)
        x, y = pad + (i % 2) * (tile + pad), pad + (i // 2) * (tile + 34 + pad)
        grid.paste(im, (x, y + 34))
        ImageDraw.Draw(grid).text((x, y + 4), cls, fill=COLOURS.get(cls, "black"), font=font)
    ASSETS.mkdir(exist_ok=True)
    grid.save(ASSETS / "roboflow_det_grid.png")
    stats["boxes_per_class"] = dict(stats["boxes_per_class"])
    stats["originals_per_class"] = dict(stats["originals_per_class"])
    stats["boxes_on_originals"] = dict(stats["boxes_on_originals"])
    stats["universe"] = re.search(r"url:\s*(\S+)", (OUT_DIR / "data.yaml").read_text()).group(1) if "url:" in (OUT_DIR / "data.yaml").read_text() else ""
    (ASSETS / "roboflow_det_stats.json").write_text(json.dumps(stats, indent=2))
    print(json.dumps(stats, indent=2))


if __name__ == "__main__":
    main(sys.argv[1])
