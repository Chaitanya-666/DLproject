"""How much does a trained FANet rely on its memory? One forward pass on the
test images, starting from five different "previous masks".

    python -m src.memory_probe --ckpt runs/kvasir_official/best.pt --data data/Kvasir-SEG

    Otsu         the official test-time start
    zeros        no hint at all
    ones         "everything is polyp"
    own memory   the model's own predictions kept from training (in the checkpoint)
    ground truth an oracle hint, the best possible memory

A model that has learned to *check* its memory against the image scores well
from every start; one that *copies* its memory swings with the hint (recall
drops with zeros, precision drops with ones). Writes memory_probe.csv next to
the checkpoint.
"""

import argparse
import csv
import os

import torch

from .dataset import SegmentationDataset
from .memory import MaskMemory
from .metrics import MetricAverager
from .model import FANet
from .train import pick_device


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ckpt", required=True)
    ap.add_argument("--data", required=True)
    ap.add_argument("--split", default="test")
    ap.add_argument("--batch", type=int, default=8)
    ap.add_argument("--device", default="auto")
    args = ap.parse_args()

    device = pick_device(args.device)
    state = torch.load(args.ckpt, map_location=device, weights_only=False)
    model = FANet().to(device)
    model.load_state_dict(state["model"])
    model.eval()

    data = SegmentationDataset(args.data, args.split, state["args"]["size"])
    images = torch.from_numpy(data.images).permute(0, 3, 1, 2).float() / 255.0
    truth = torch.from_numpy(data.masks).unsqueeze(1).float()
    starts = {
        "Otsu": MaskMemory(data.images).masks.float(),
        "zeros": torch.zeros_like(truth),
        "ones": torch.ones_like(truth),
        "ground truth": truth,
    }
    # The training-time memory only matches these images if they were the
    # validation set during training (val falls back to test in train.py).
    own = state.get("val_memory", {}).get("masks")
    if own is not None and own.shape == truth.shape:
        starts["own memory"] = own.float()

    rows = []
    for name, prev in starts.items():
        scores = MetricAverager()
        with torch.no_grad():
            for i in range(0, len(data), args.batch):
                logits = model(images[i:i + args.batch].to(device), prev[i:i + args.batch].to(device))
                scores.update((torch.sigmoid(logits) > 0.5).cpu().numpy(), truth[i:i + args.batch].numpy())
        r = scores.result()
        rows.append({"start": name, "dice": r["dice"], "precision": r["precision"], "recall": r["recall"]})
        print(f"{name:13s} dice {r['dice']:.4f}  precision {r['precision']:.4f}  recall {r['recall']:.4f}")

    out = os.path.join(os.path.dirname(args.ckpt), "memory_probe.csv")
    with open(out, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print("saved", out)


if __name__ == "__main__":
    main()
