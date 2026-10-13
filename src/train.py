"""Train FANet with feedback attention.

    python -m src.train --data data/Kvasir-SEG --out runs/kvasir
    python -m src.train --data dataset/custom/leaf --out runs/leaf \
        --init runs/kvasir/best.pt --epochs 60 --lr 5e-5        # fine-tune

What happens each epoch (the "feedback" loop):
    1. Every image is passed in together with its mask from memory (an Otsu
       guess at epoch 1, the model's own earlier prediction afterwards).
    2. The new predictions are written to a staging copy of the memory.
    3. If validation loss improved, the checkpoint is saved and the staged
       predictions become the memory for the next epoch. Otherwise the old
       memory is kept. That is the official code's rule; `--memory-update
       always` refreshes the memory every epoch instead.

Outputs in --out: best.pt (weights + memories + settings) and log.csv.
"""

import argparse
import csv
import os
import random
import time

import numpy as np
import torch
from torch.utils.data import DataLoader

from . import augment
from .dataset import SegmentationDataset
from .losses import DiceBCELoss
from .memory import MaskMemory
from .metrics import MetricAverager
from .model import FANet, count_parameters


def pick_device(name):
    if name != "auto":
        return torch.device(name)
    if torch.cuda.is_available():
        return torch.device("cuda")
    if getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def seed_everything(seed):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)


def run_epoch(model, loader, memory, loss_fn, device, optimizer=None, use_aug=False, max_batches=None):
    """One pass over a loader. Trains if an optimizer is given, else evaluates.
    Stages each prediction into `memory`. Returns (mean loss, metrics dict)."""
    training = optimizer is not None
    model.train(training)
    total, batches = 0.0, 0
    scores = MetricAverager()

    for step, (image, target, idx) in enumerate(loader):
        if max_batches and step >= max_batches:
            break
        image, target = image.to(device), target.to(device)
        prev = memory.get(idx, device)

        params = None
        if use_aug:
            params = augment.sample_params(image.shape[0])
            image = augment.apply_geometric(image, params)
            target = augment.apply_geometric(target, params)
            prev = augment.apply_geometric(prev, params)
            image = augment.photometric(image)

        with torch.set_grad_enabled(training):
            logits = model(image, prev)
            loss = loss_fn(logits, target)
        if training:
            optimizer.zero_grad(set_to_none=True)
            loss.backward()
            optimizer.step()

        with torch.no_grad():
            probs = torch.sigmoid(logits)
            if params is not None:
                # Back to the original orientation before storing.
                probs = augment.invert_geometric(probs, params)
                target = augment.invert_geometric(target, params)
            memory.stage(idx, probs)
            scores.update((probs > 0.5).cpu().numpy(), target.cpu().numpy())

        total += loss.item()
        batches += 1

    return total / max(batches, 1), scores.result()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", required=True)
    ap.add_argument("--out", default="runs/fanet")
    ap.add_argument("--size", type=int, default=256)
    ap.add_argument("--epochs", type=int, default=200)
    ap.add_argument("--batch", type=int, default=8)
    ap.add_argument("--lr", type=float, default=1e-4)
    ap.add_argument("--workers", type=int, default=2)
    ap.add_argument("--memory-update", choices=["on-improve", "always"], default="on-improve")
    ap.add_argument("--no-aug", action="store_true", help="turn augmentation off")
    ap.add_argument("--init", help="checkpoint to start from (fine-tuning)")
    ap.add_argument("--early-stop", type=int, default=40, help="stop after N epochs without improvement (0 = never)")
    ap.add_argument("--device", default="auto")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--max-batches", type=int, default=0, help="debug: cap batches per epoch")
    args = ap.parse_args()

    seed_everything(args.seed)
    device = pick_device(args.device)
    os.makedirs(args.out, exist_ok=True)

    train_set = SegmentationDataset(args.data, "train", args.size)
    val_split = "val" if os.path.exists(os.path.join(args.data, "val.txt")) else "test"
    val_set = SegmentationDataset(args.data, val_split, args.size)
    print(f"train {len(train_set)} | {val_split} {len(val_set)} | device {device}")

    train_loader = DataLoader(train_set, batch_size=args.batch, shuffle=True,
                              num_workers=args.workers, drop_last=len(train_set) > args.batch)
    val_loader = DataLoader(val_set, batch_size=args.batch, shuffle=False, num_workers=args.workers)

    train_mem = MaskMemory(train_set.images)
    val_mem = MaskMemory(val_set.images)

    model = FANet().to(device)
    if args.init:
        state = torch.load(args.init, map_location=device)
        model.load_state_dict(state["model"])
        print(f"initialised from {args.init}")
    print(f"FANet parameters: {count_parameters(model):,}")

    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, "min", factor=0.1, patience=5)
    loss_fn = DiceBCELoss()

    log_path = os.path.join(args.out, "log.csv")
    with open(log_path, "w", newline="") as f:
        csv.writer(f).writerow(["epoch", "train_loss", "val_loss", "train_dice", "val_dice",
                                "val_jaccard", "lr", "seconds", "saved"])

    best, stale = float("inf"), 0
    for epoch in range(1, args.epochs + 1):
        t0 = time.time()
        train_loss, train_scores = run_epoch(model, train_loader, train_mem, loss_fn, device,
                                             optimizer, use_aug=not args.no_aug,
                                             max_batches=args.max_batches)
        val_loss, val_scores = run_epoch(model, val_loader, val_mem, loss_fn, device,
                                         max_batches=args.max_batches)
        scheduler.step(val_loss)

        improved = val_loss < best
        if improved or args.memory_update == "always":
            train_mem.commit()
            val_mem.commit()
        if improved:
            best, stale = val_loss, 0
            torch.save({
                "model": model.state_dict(),
                "train_memory": train_mem.state_dict(),
                "val_memory": val_mem.state_dict(),
                "epoch": epoch,
                "val_loss": val_loss,
                "val_scores": val_scores,
                "args": vars(args),
            }, os.path.join(args.out, "best.pt"))
        else:
            stale += 1

        lr = optimizer.param_groups[0]["lr"]
        secs = time.time() - t0
        print(f"epoch {epoch:3d} | loss {train_loss:.4f} / {val_loss:.4f} | "
              f"dice {train_scores['dice']:.4f} / {val_scores['dice']:.4f} | "
              f"lr {lr:.1e} | {secs:.0f}s{' | saved' if improved else ''}")
        with open(log_path, "a", newline="") as f:
            csv.writer(f).writerow([epoch, f"{train_loss:.5f}", f"{val_loss:.5f}",
                                    f"{train_scores['dice']:.5f}", f"{val_scores['dice']:.5f}",
                                    f"{val_scores['jaccard']:.5f}", f"{lr:.2e}", f"{secs:.1f}", int(improved)])

        if args.early_stop and stale >= args.early_stop:
            print(f"no improvement for {stale} epochs, stopping")
            break

    print(f"best val loss {best:.4f}; checkpoint at {os.path.join(args.out, 'best.pt')}")


if __name__ == "__main__":
    main()
