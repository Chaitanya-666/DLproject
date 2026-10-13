"""Evaluation metrics, computed per image on 0/1 masks and then averaged over
images (the same way the official test script does it).

    TP = predicted 1 and truly 1      FP = predicted 1, truly 0
    FN = predicted 0, truly 1         TN = predicted 0, truly 0

    Dice (F1)   = 2TP / (2TP + FP + FN)    overlap; the headline number
    Jaccard/IoU = TP / (TP + FP + FN)      stricter overlap; IoU <= Dice
    Precision   = TP / (TP + FP)           of what I marked, how much is polyp
    Recall      = TP / (TP + FN)           of the polyp, how much I found
    Specificity = TN / (TN + FP)           of the background, how much I left alone
    Accuracy    = (TP + TN) / all          inflated by the large background
    F2          = 5PR / (4P + R)           like F1 but recall counts more

Also: boxes from masks. Each connected blob of a mask becomes one bounding
box, which turns the segmentation into a detection output.
"""

from collections import deque

import numpy as np

EPS = 1e-15
NAMES = ["dice", "jaccard", "precision", "recall", "specificity", "accuracy", "f2"]


def mask_scores(pred, true):
    """pred, true: 0/1 numpy arrays of the same shape. Returns a dict."""
    pred = pred.astype(bool).ravel()
    true = true.astype(bool).ravel()
    tp = float(np.sum(pred & true))
    fp = float(np.sum(pred & ~true))
    fn = float(np.sum(~pred & true))
    tn = float(np.sum(~pred & ~true))
    precision = (tp + EPS) / (tp + fp + EPS)
    recall = (tp + EPS) / (tp + fn + EPS)
    return {
        "dice": (2 * tp + EPS) / (2 * tp + fp + fn + EPS),
        "jaccard": (tp + EPS) / (tp + fp + fn + EPS),
        "precision": precision,
        "recall": recall,
        "specificity": tn / (tn + fp) if tn + fp > 0 else 0.0,
        "accuracy": (tp + tn) / max(tp + tn + fp + fn, 1.0),
        "f2": 5 * precision * recall / (4 * precision + recall + EPS),
    }


class MetricAverager:
    def __init__(self):
        self.sums = {k: 0.0 for k in NAMES}
        self.n = 0

    def update(self, preds, trues):
        """preds, trues: (B,1,H,W) or (B,H,W) arrays/tensors of 0/1."""
        preds = np.asarray(preds).reshape(len(preds), -1)
        trues = np.asarray(trues).reshape(len(trues), -1)
        for p, t in zip(preds, trues):
            for k, v in mask_scores(p, t).items():
                self.sums[k] += v
            self.n += 1

    def result(self):
        return {k: v / max(self.n, 1) for k, v in self.sums.items()}


# ---------------------------------------------------------------- boxes

def connected_components(mask):
    """Label 8-connected blobs of a 0/1 mask. Returns (labels, count)."""
    mask = np.asarray(mask).astype(bool)
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    count = 0
    for y, x in zip(*np.nonzero(mask)):
        if labels[y, x]:
            continue
        count += 1
        labels[y, x] = count
        queue = deque([(y, x)])
        while queue:
            cy, cx = queue.popleft()
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not labels[ny, nx]:
                        labels[ny, nx] = count
                        queue.append((ny, nx))
    return labels, count


def mask_to_boxes(mask, min_area=20):
    """One (x1, y1, x2, y2) box per blob; blobs under min_area pixels are noise."""
    labels, count = connected_components(mask)
    boxes = []
    for k in range(1, count + 1):
        ys, xs = np.nonzero(labels == k)
        if len(ys) >= min_area:
            boxes.append((int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())))
    return boxes


def box_iou(a, b):
    ix1, iy1 = max(a[0], b[0]), max(a[1], b[1])
    ix2, iy2 = min(a[2], b[2]), min(a[3], b[3])
    inter = max(0, ix2 - ix1 + 1) * max(0, iy2 - iy1 + 1)
    area_a = (a[2] - a[0] + 1) * (a[3] - a[1] + 1)
    area_b = (b[2] - b[0] + 1) * (b[3] - b[1] + 1)
    return inter / float(area_a + area_b - inter)


class BoxAverager:
    """Detection view of the masks: a predicted box is a hit if it overlaps an
    unmatched true box with IoU >= threshold (greedy matching, best IoU first).
    Reports box precision, box recall and mean IoU of the hits."""

    def __init__(self, iou_threshold=0.5, min_area=20):
        self.t = iou_threshold
        self.min_area = min_area
        self.tp = self.fp = self.fn = 0
        self.ious = []

    def update(self, preds, trues):
        preds = np.asarray(preds)
        trues = np.asarray(trues)
        for p, t in zip(preds.reshape(len(preds), *preds.shape[-2:]),
                        trues.reshape(len(trues), *trues.shape[-2:])):
            pb = mask_to_boxes(p, self.min_area)
            tb = mask_to_boxes(t, self.min_area)
            pairs = sorted(((box_iou(a, b), i, j) for i, a in enumerate(pb)
                            for j, b in enumerate(tb)), reverse=True)
            used_p, used_t = set(), set()
            for iou, i, j in pairs:
                if iou < self.t:
                    break
                if i in used_p or j in used_t:
                    continue
                used_p.add(i)
                used_t.add(j)
                self.ious.append(iou)
            self.tp += len(used_p)
            self.fp += len(pb) - len(used_p)
            self.fn += len(tb) - len(used_t)

    def result(self):
        return {
            "box_precision": self.tp / max(self.tp + self.fp, 1),
            "box_recall": self.tp / max(self.tp + self.fn, 1),
            "box_mean_iou": float(np.mean(self.ious)) if self.ious else 0.0,
        }
