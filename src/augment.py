"""Data augmentation that keeps the mask memory aligned.

The memory stores each image's predicted mask in the image's *original*
orientation. If we flip an image for training, we must flip its ground truth
and its memory mask the same way, and un-flip the prediction before storing
it. So the geometric part uses only exactly invertible moves: horizontal flip,
vertical flip, and rotation by a multiple of 90 degrees.

Photometric changes (brightness, contrast, cut-out holes) touch the image only.
"""

import torch


def sample_params(batch_size, generator=None):
    g = generator
    return {
        "hflip": torch.rand(batch_size, generator=g) < 0.5,
        "vflip": torch.rand(batch_size, generator=g) < 0.5,
        "rot90": torch.randint(0, 4, (batch_size,), generator=g),
    }


def apply_geometric(x, params):
    """x: (B,C,H,W). Flip, then rotate, per sample. H must equal W."""
    out = []
    for i in range(x.shape[0]):
        t = x[i]
        if params["hflip"][i]:
            t = t.flip(-1)
        if params["vflip"][i]:
            t = t.flip(-2)
        t = torch.rot90(t, int(params["rot90"][i]), dims=(-2, -1))
        out.append(t)
    return torch.stack(out)


def invert_geometric(x, params):
    """Undo apply_geometric: rotate back, then un-flip (reverse order)."""
    out = []
    for i in range(x.shape[0]):
        t = torch.rot90(x[i], -int(params["rot90"][i]), dims=(-2, -1))
        if params["vflip"][i]:
            t = t.flip(-2)
        if params["hflip"][i]:
            t = t.flip(-1)
        out.append(t)
    return torch.stack(out)


def photometric(images, p_jitter=0.5, p_cutout=0.3, max_holes=10, hole=32):
    """Brightness/contrast jitter and CoarseDropout-style black holes."""
    b, _, h, w = images.shape
    images = images.clone()
    dev = images.device
    for i in range(b):
        if torch.rand(1).item() < p_jitter:
            brightness = 1.0 + (torch.rand(1, device=dev) - 0.5) * 0.4   # 0.8 .. 1.2
            contrast = 1.0 + (torch.rand(1, device=dev) - 0.5) * 0.4
            mean = images[i].mean()
            images[i] = ((images[i] - mean) * contrast + mean) * brightness
        if torch.rand(1).item() < p_cutout:
            for _ in range(int(torch.randint(1, max_holes + 1, (1,)))):
                y = int(torch.randint(0, max(h - hole, 1), (1,)))
                x = int(torch.randint(0, max(w - hole, 1), (1,)))
                images[i, :, y:y + hole, x:x + hole] = 0.0
    return images.clamp(0.0, 1.0)
