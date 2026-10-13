"""Write train.txt / val.txt / test.txt (one file stem per line) into a dataset folder.

Kvasir-SEG (1000 images): the FANet code reads an 880 / 120 train / val split
and reports test numbers on those same 120 images. The default here matches
that (`--test 120 --val 0`, val falls back to test in train.py). Use
`--val 80` to also hold out 80 training images for model selection, so the
120 test images are never seen before the final evaluation.

    python -m src.split --data data/Kvasir-SEG
    python -m src.split --data data/Kvasir-SEG --test 120 --val 80
    python -m src.split --data dataset/custom/leaf --test 0.2      # fractions work too
"""

import argparse
import os
import random

from .dataset import list_stems


def count(n_total, value):
    return int(round(n_total * value)) if 0 < value < 1 else int(value)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", required=True, help="folder with images/ and masks/")
    ap.add_argument("--test", type=float, default=120, help="count, or fraction if < 1")
    ap.add_argument("--val", type=float, default=0, help="count, or fraction if < 1")
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    stems = list_stems(args.data)
    if not stems:
        raise SystemExit(f"no image/mask pairs found under {args.data}")
    random.Random(args.seed).shuffle(stems)

    n_test = count(len(stems), args.test)
    n_val = count(len(stems), args.val)
    test, val, train = stems[:n_test], stems[n_test:n_test + n_val], stems[n_test + n_val:]

    for name, items in (("train", train), ("val", val), ("test", test)):
        path = os.path.join(args.data, f"{name}.txt")
        if name == "val" and not items:
            if os.path.exists(path):
                os.remove(path)
            continue
        with open(path, "w") as f:
            f.write("\n".join(sorted(items)) + "\n")
    print(f"{len(stems)} pairs -> train {len(train)}, val {len(val)}, test {len(test)} (seed {args.seed})")


if __name__ == "__main__":
    main()
