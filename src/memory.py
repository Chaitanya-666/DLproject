"""The mask memory: FANet's "feedback".

One binary mask per image, stored at the training resolution. Before the first
epoch every slot is filled with an Otsu-threshold guess (no learning needed).
After that, the slot holds the model's own prediction for that image from an
earlier epoch, and is fed back in as `prev_mask` the next time the image is
seen.

Stored as uint8 on the CPU: 1000 images x 256 x 256 = 64 MB.
"""

import numpy as np
import torch
from PIL import Image, ImageFilter


def otsu_threshold(gray):
    """Otsu's method: the grey level that best splits the histogram into two
    classes, i.e. maximises the between-class variance."""
    hist = np.bincount(gray.ravel(), minlength=256).astype(np.float64)
    prob = hist / hist.sum()
    omega = np.cumsum(prob)                  # weight of class 0 up to t
    mu = np.cumsum(prob * np.arange(256))    # cumulative mean up to t
    mu_total = mu[-1]
    with np.errstate(divide="ignore", invalid="ignore"):
        between = (mu_total * omega - mu) ** 2 / (omega * (1.0 - omega))
    between = np.nan_to_num(between)
    return int(np.argmax(between))


def otsu_mask(rgb_uint8):
    """Initial guess used by the official code: grey -> 5x5 Gaussian blur ->
    Otsu threshold. Pixels brighter than the threshold become 1."""
    gray = Image.fromarray(rgb_uint8).convert("L").filter(ImageFilter.GaussianBlur(radius=1))
    gray = np.asarray(gray)
    return (gray > otsu_threshold(gray)).astype(np.uint8)


class MaskMemory:
    def __init__(self, images_uint8, feedback=True):
        """images_uint8: (N,H,W,3) array, e.g. SegmentationDataset.images.

        feedback=False is the ablation: every slot stays all zeros forever, so
        the model never sees an earlier mask (MixPool falls back to its fmask).
        """
        self.feedback = feedback
        if feedback:
            masks = np.stack([otsu_mask(img) for img in images_uint8])
        else:
            masks = np.zeros(np.asarray(images_uint8).shape[:3], dtype=np.uint8)
        self.masks = torch.from_numpy(masks).unsqueeze(1)  # (N,1,H,W) uint8
        self.staged = self.masks.clone()

    def __len__(self):
        return self.masks.shape[0]

    def get(self, indices, device):
        return self.masks[indices.cpu()].to(device=device, dtype=torch.float32)

    def stage(self, indices, probs):
        """Write this epoch's predictions to a staging copy (not yet used)."""
        if not self.feedback:
            return
        self.staged[indices.cpu()] = (probs.detach().cpu() > 0.5).to(torch.uint8)

    def commit(self):
        """Make the staged predictions the new memory."""
        self.masks.copy_(self.staged)

    def write(self, indices, probs):
        """Stage and commit at once (used at test time)."""
        self.stage(indices, probs)
        self.masks[indices.cpu()] = self.staged[indices.cpu()]

    def reset_to_otsu(self, images_uint8):
        self.__init__(images_uint8, self.feedback)

    def state_dict(self):
        return {"masks": self.masks}

    def load_state_dict(self, state):
        self.masks = state["masks"].clone()
        self.staged = self.masks.clone()
