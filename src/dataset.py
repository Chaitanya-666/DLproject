"""Loading Kvasir-SEG (or any folder of images + binary masks).

Expected layout (Kvasir-SEG already looks like this after unzipping):

    root/
      images/  cju0qkwl35piu0993l0dewei2.jpg ...
      masks/   cju0qkwl35piu0993l0dewei2.jpg ...   (same file stem)
      train.txt, val.txt, test.txt                  (one stem per line; made by split.py)

Every image is resized once to `size` x `size` and kept in RAM: 1000 images
at 256x256 is about 200 MB as float32, so each epoch avoids decoding JPEGs.
"""

import os
from glob import glob

import numpy as np
import torch
from PIL import Image
from torch.utils.data import Dataset

IMAGE_EXTS = (".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff")


def find_file(folder, stem):
    for ext in IMAGE_EXTS:
        path = os.path.join(folder, stem + ext)
        if os.path.exists(path):
            return path
    raise FileNotFoundError(f"no image named {stem}.* in {folder}")


def list_stems(root):
    """All file stems in root/images that also have a mask."""
    stems = []
    for path in sorted(glob(os.path.join(root, "images", "*"))):
        stem, ext = os.path.splitext(os.path.basename(path))
        if ext.lower() not in IMAGE_EXTS:
            continue
        try:
            find_file(os.path.join(root, "masks"), stem)
        except FileNotFoundError:
            continue
        stems.append(stem)
    return stems


def read_split(root, split):
    """Stems listed in root/<split>.txt; the whole folder if split is 'all'."""
    if split == "all":
        return list_stems(root)
    path = os.path.join(root, f"{split}.txt")
    if not os.path.exists(path):
        raise FileNotFoundError(f"{path} missing. Run: python -m src.split --data {root}")
    with open(path) as f:
        return [line.strip() for line in f if line.strip()]


def load_image(path, size):
    img = Image.open(path).convert("RGB").resize((size, size), Image.BILINEAR)
    return np.asarray(img, dtype=np.uint8)


def load_mask(path, size):
    # Kvasir masks are JPEGs, so edges carry compression noise: threshold at 127.
    m = Image.open(path).convert("L").resize((size, size), Image.NEAREST)
    return (np.asarray(m) > 127).astype(np.uint8)


class SegmentationDataset(Dataset):
    """Returns (image, mask, index).

    image: float32 (3,H,W) in [0,1]. mask: float32 (1,H,W) of 0/1.
    index: position in this dataset, used to look up the image's slot in the
    mask memory (see memory.py). That is why shuffling is safe here, unlike
    the official code, which had to keep the loader order fixed.
    """

    def __init__(self, root, split="train", size=256, with_masks=True):
        self.root = root
        self.size = size
        self.stems = read_split(root, split)
        self.image_paths = [find_file(os.path.join(root, "images"), s) for s in self.stems]
        self.images = np.stack([load_image(p, size) for p in self.image_paths])
        if with_masks:
            self.masks = np.stack(
                [load_mask(find_file(os.path.join(root, "masks"), s), size) for s in self.stems]
            )
        else:
            self.masks = np.zeros((len(self.stems), size, size), dtype=np.uint8)

    def __len__(self):
        return len(self.stems)

    def __getitem__(self, i):
        image = torch.from_numpy(self.images[i]).permute(2, 0, 1).float() / 255.0
        mask = torch.from_numpy(self.masks[i]).unsqueeze(0).float()
        return image, mask, i


class ImageFolderDataset(SegmentationDataset):
    """Images only (no ground truth), e.g. new photos to predict on."""

    def __init__(self, folder, size=256):
        self.root = folder
        self.size = size
        paths = sorted(
            p for p in glob(os.path.join(folder, "*")) if p.lower().endswith(IMAGE_EXTS)
        )
        self.image_paths = paths
        self.stems = [os.path.splitext(os.path.basename(p))[0] for p in paths]
        self.images = np.stack([load_image(p, size) for p in paths])
        self.masks = np.zeros((len(paths), size, size), dtype=np.uint8)
