"""Building blocks of FANet: squeeze-and-excitation, residual block, MixPool.

Every layer here is a plain PyTorch primitive (Conv2d, BatchNorm2d, ReLU,
Linear, pooling). Nothing is imported from a model zoo.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class SqueezeExcite(nn.Module):
    """Channel attention (Hu et al., SENet).

    Squeeze: global-average-pool each channel to one number.
    Excite: a tiny two-layer MLP turns those numbers into per-channel weights
    in (0, 1), which then rescale the feature map. The network learns which
    channels matter for the current image.
    """

    def __init__(self, channels, reduction=16):
        super().__init__()
        hidden = max(channels // reduction, 1)
        self.fc = nn.Sequential(
            nn.Linear(channels, hidden, bias=False),
            nn.ReLU(inplace=True),
            nn.Linear(hidden, channels, bias=False),
            nn.Sigmoid(),
        )

    def forward(self, x):
        b, c, _, _ = x.shape
        w = F.adaptive_avg_pool2d(x, 1).view(b, c)
        w = self.fc(w).view(b, c, 1, 1)
        return x * w


class ResidualBlock(nn.Module):
    """3x3 conv -> BN -> ReLU -> 3x3 conv -> BN, plus a 1x1 shortcut.

    The shortcut (1x1 conv + BN + SE) matches the channel count so the two
    paths can be added. Output = ReLU(main + shortcut).

    Note: the official code builds SE with reduction = out_c, i.e. a hidden
    layer of exactly 1 unit. We copy that to stay faithful (see README,
    "Deviations and observations").
    """

    def __init__(self, in_c, out_c):
        super().__init__()
        self.conv1 = nn.Conv2d(in_c, out_c, 3, padding=1)
        self.bn1 = nn.BatchNorm2d(out_c)
        self.conv2 = nn.Conv2d(out_c, out_c, 3, padding=1)
        self.bn2 = nn.BatchNorm2d(out_c)
        self.shortcut = nn.Sequential(
            nn.Conv2d(in_c, out_c, 1),
            nn.BatchNorm2d(out_c),
            SqueezeExcite(out_c, reduction=out_c),
        )

    def forward(self, x):
        y = F.relu(self.bn1(self.conv1(x)))
        y = self.bn2(self.conv2(y))
        return F.relu(y + self.shortcut(x))


class MixPool(nn.Module):
    """The feedback-attention block: merges features with a mask.

    Inputs:
        x: feature map, shape (B, C, h, w)
        m: the *previous* mask for these images, shape (B, 1, H, W), values 0/1,
           at full input resolution.

    Steps:
        1. fmask: a small conv head predicts a mask from x itself, then it is
           thresholded at 0.5 (hard 0/1).
        2. m is max-pooled down to (h, w), so a pixel stays 1 if any pixel in
           its window was 1.
        3. attention = fmask OR m. Features outside it are zeroed (hard
           attention), then go through conv1.
        4. The untouched features go through conv2.
        5. Concatenate both halves -> out_c channels.

    Branch 4 keeps the network working even when the mask is wrong, because
    the full features always reach the next layer.
    """

    def __init__(self, in_c, out_c):
        super().__init__()
        self.fmask = nn.Sequential(
            nn.Conv2d(in_c, out_c, 3, padding=1),
            nn.BatchNorm2d(out_c),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_c, 1, 1),
            nn.Sigmoid(),
        )
        self.conv1 = nn.Sequential(
            nn.Conv2d(in_c, out_c // 2, 3, padding=1),
            nn.BatchNorm2d(out_c // 2),
            nn.ReLU(inplace=True),
        )
        self.conv2 = nn.Sequential(
            nn.Conv2d(in_c, out_c // 2, 3, padding=1),
            nn.BatchNorm2d(out_c // 2),
            nn.ReLU(inplace=True),
        )

    def forward(self, x, m):
        fmask = (self.fmask(x) > 0.5).float()
        kh, kw = m.shape[2] // x.shape[2], m.shape[3] // x.shape[3]
        m = F.max_pool2d(m, (kh, kw)) if kh > 1 or kw > 1 else m
        attention = torch.logical_or(fmask > 0, m > 0.5).float()
        masked = self.conv1(x * attention)
        plain = self.conv2(x)
        return torch.cat([masked, plain], dim=1)
