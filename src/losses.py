"""Loss: 0.5 * binary cross-entropy + 0.5 * Dice loss (as in the official code).

BCE judges every pixel on its own, so it is dominated by the large background.
Dice loss measures overlap of the whole predicted region with the true region,
so a small polyp still matters. Mixing the two gives stable gradients (BCE)
and a target that matches the evaluation metric (Dice).
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


def dice_loss(logits, target, smooth=1.0):
    probs = torch.sigmoid(logits).reshape(-1)
    target = target.reshape(-1)
    inter = (probs * target).sum()
    return 1.0 - (2.0 * inter + smooth) / (probs.sum() + target.sum() + smooth)


class DiceBCELoss(nn.Module):
    def __init__(self, bce_weight=0.5):
        super().__init__()
        self.bce_weight = bce_weight

    def forward(self, logits, target):
        # BCE on logits is numerically safer than sigmoid followed by BCE.
        bce = F.binary_cross_entropy_with_logits(logits, target)
        return self.bce_weight * bce + (1.0 - self.bce_weight) * dice_loss(logits, target)
