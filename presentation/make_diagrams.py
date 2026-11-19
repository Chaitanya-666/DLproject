"""Paper-style diagrams of FANet as implemented in src/ (shapes for a 256x256 input).

    ~/.venvs/dlproject/bin/python presentation/make_diagrams.py

Writes presentation/figures/diagram_{architecture,blocks,loop,pipeline}.svg and .png
(PNG via rsvg-convert at 2x). Every layer, channel count and size matches
src/model.py and src/blocks.py; the Dice-per-round bars are read from
runs/kvasir_official/eval_test/results.csv.
"""
import base64
import csv
import io
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
OUT = ROOT / "presentation" / "figures"

TEAL, CORAL, AMBER, SLATE, DARK, INK = "#0F7C86", "#E0604F", "#F2B134", "#5A6B7B", "#0E3B43", "#1B2631"
FILL = {
    "res": "#CFE9EC", "mix": TEAL, "maxp": "#E3E7EA", "tconv": "#FDE3CF", "concat": "#FBF0C4",
    "conv": "#D6EAF8", "bn": "#FCE5B6", "relu": "#F9D5D3", "sig": "#E8DAEF", "thr": "#FDE2DE",
    "se": "#D5F5E3", "plain": "#FFFFFF", "mem": "#FDE8E4", "feat": "#E6F2F3", "note": "#F4F6F7",
}
FONT = "Noto Sans, DejaVu Sans, sans-serif"


class Svg:
    def __init__(self, w, h):
        self.w, self.h, self.el = w, h, []

    def rect(self, x, y, w, h, fill="#fff", stroke=SLATE, sw=1.2, rx=6, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.el.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}/>')

    def text(self, x, y, s, size=14, anchor="middle", weight="normal", fill=INK, italic=False, rotate=None):
        lines = s.split("\n")
        y0 = y - (len(lines) - 1) * size * 0.62
        style = ' font-style="italic"' if italic else ""
        rot = f' transform="rotate({rotate} {x} {y})"' if rotate is not None else ""
        spans = "".join(
            f'<tspan x="{x}" y="{y0 + i * size * 1.24:.1f}">{esc(l)}</tspan>' for i, l in enumerate(lines))
        self.el.append(f'<text font-family="{FONT}" font-size="{size}" text-anchor="{anchor}" '
                       f'dominant-baseline="central" font-weight="{weight}" fill="{fill}"{style}{rot}>{spans}</text>')

    def box(self, x, y, w, h, s, kind="plain", size=14, weight="normal", stroke=SLATE, sw=1.2, color=None, dash=None):
        fill = FILL.get(kind, kind)
        self.rect(x, y, w, h, fill, stroke, sw, dash=dash)
        self.text(x + w / 2, y + h / 2, s, size, weight=weight, fill=color or ("#fff" if kind == "mix" else INK))

    def line(self, pts, color=INK, width=1.8, dash=None, head=True):
        d = "M " + " L ".join(f"{x},{y}" for x, y in pts)
        da = f' stroke-dasharray="{dash}"' if dash else ""
        mk = f' marker-end="url(#a{color[1:]})"' if head else ""
        self.el.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}"{da}{mk}/>')

    def circle(self, x, y, r, s, size=20):
        self.el.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#fff" stroke="{INK}" stroke-width="1.6"/>')
        self.text(x, y, s, size, weight="bold")

    def image(self, x, y, w, h, png_bytes):
        b64 = base64.b64encode(png_bytes).decode()
        self.el.append(f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="data:image/png;base64,{b64}"/>')
        self.rect(x, y, w, h, "none", SLATE, 1, rx=0)

    def save(self, name):
        markers = "".join(
            f'<marker id="a{c[1:]}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
            f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{c}"/></marker>'
            for c in (INK, TEAL, CORAL, SLATE))
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
               f'viewBox="0 0 {self.w} {self.h}"><defs>{markers}</defs>'
               f'<rect width="{self.w}" height="{self.h}" fill="#fff"/>' + "".join(self.el) + "</svg>")
        OUT.mkdir(parents=True, exist_ok=True)
        path = OUT / f"diagram_{name}.svg"
        path.write_text(svg)
        subprocess.run(["rsvg-convert", "-z", "2", "-o", str(path.with_suffix(".png")), str(path)], check=True)
        print("wrote", path.with_suffix(".png"))


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def png(arr, size=120):
    buf = io.BytesIO()
    Image.fromarray(arr).resize((size * 2, size * 2), Image.NEAREST).save(buf, "PNG")
    return buf.getvalue()


def sample_pictures():
    """Input image, its Otsu start mask and the final predicted mask, for one test image."""
    from src.dataset import load_image
    from src.memory import otsu_mask
    data = ROOT / "data" / "Kvasir-SEG"
    stem = (data / "test.txt").read_text().split()[0]
    img = load_image(str(data / "images" / f"{stem}.jpg"), 256)
    otsu = otsu_mask(img) * 255
    pred_path = ROOT / "runs" / "kvasir_official" / "eval_test" / "masks" / f"{stem}.png"
    pred = np.asarray(Image.open(pred_path).convert("L").resize((256, 256)))
    return png(img), png(otsu.astype(np.uint8)), png(pred)


# ----------------------------------------------------------------- A. architecture

def architecture():
    s = Svg(1330, 660)
    img_png, otsu_png, pred_png = sample_pictures()
    xs, sw = [380, 610, 840, 1070], 190
    ch = 30  # chip pitch

    def stage(x, y, title, right, chips, width=sw, size=13):
        h = 30 + len(chips) * ch + 6
        s.rect(x, y, width, h, "#fff", DARK, 1.6, rx=8)
        s.text(x + 10, y + 15, title, 15, anchor="start", weight="bold", fill=DARK)
        s.text(x + width - 10, y + 15, right, 12, anchor="end", fill=SLATE)
        for i, (label, kind) in enumerate(chips):
            s.box(x + 8, y + 30 + i * ch, width - 16, ch - 5, label, kind, size=size)
        return h

    enc = [(3, 32, 256), (32, 64, 128), (64, 128, 64), (128, 256, 32)]
    ey = 430
    for k, (ci, co, r) in enumerate(enc):
        stage(xs[k], ey, f"Encoder {k + 1}", f"out {co}×{r // 2}²", [
            (f"SE-Residual  {ci}→{co}", "res"), (f"SE-Residual  {co}→{co}", "res"),
            (f"MixPool  {co}→{co}", "mix"), ("MaxPool 2×2  ↓2", "maxp")])
    enc_h = 30 + 4 * ch + 6
    dec = [(256, 128, 32), (128, 64, 64), (64, 32, 128), (32, 16, 256)]  # D1..D4
    dy = 40
    for k, (ci, co, r) in enumerate(dec):
        x = xs[3 - k]
        stage(x, dy, f"Decoder {k + 1}", f"out {co}×{r}²", [
            (f"TConv 4×4, s2  {r // 2}²→{r}²", "tconv"), (f"Concat skip s{4 - k}  → {2 * ci}", "concat"),
            (f"SE-Residual  {2 * ci}→{co}", "res"), (f"SE-Residual  {co}→{co}", "res"), (f"MixPool  {co}→{co}", "mix")])
    dec_h = 30 + 5 * ch + 6
    hx, hw = 185, 170
    stage(hx, dy, "Output head", "", [("Concat prev mask → 17", "concat"), ("1×1 Conv  17→1", "conv"),
                                       ("Sigmoid", "sig"), ("> 0.5  →  0/1 mask", "thr")], width=hw, size=12)

    # pictures: output, memory, Otsu, input
    s.text(85, 52, "Predicted mask\n1×256×256", 13, weight="bold")
    s.image(25, 78, 120, 120, pred_png)
    s.box(15, 268, 140, 96, "Mask memory\none mask per image\ntrain: commit when\nval loss falls\ntest: overwrite", "mem",
          size=12, stroke=CORAL, sw=1.6)
    s.text(85, 612, "Otsu start (epoch 0 / round 0)", 11)
    s.image(25, 475, 120, 120, otsu_png)
    s.text(272, 448, "Input image\n3×256×256", 13, weight="bold")
    s.image(212, 475, 120, 120, img_png)

    mid_d = dy + 15 + dec_h / 2
    mid_e = ey + 15 + enc_h / 2
    # main feature flow
    s.line([(332, mid_e), (xs[0], mid_e)])
    for k in range(3):
        s.line([(xs[k] + sw, mid_e), (xs[k + 1], mid_e)])
    s.line([(xs[3] + sw, mid_e), (1305, mid_e), (1305, mid_d), (xs[3] + sw, mid_d)])
    s.text(1318, (mid_e + mid_d) / 2, "bottleneck 256×16²", 12, rotate=-90, fill=SLATE)
    for k in range(3, 0, -1):
        s.line([(xs[k], mid_d), (xs[k - 1] + sw, mid_d)])
    s.line([(xs[0], mid_d), (hx + hw, mid_d)])
    s.line([(hx, mid_d), (145, mid_d)])
    s.line([(85, 198), (85, 268)], CORAL)
    s.line([(85, 475), (85, 364)], CORAL)

    # skip connections
    for k, (ci, co, r) in enumerate(enc):
        x = xs[k] + 40
        s.line([(x, ey), (x, dy + dec_h)], TEAL, 1.8, dash="7 5")
        s.text(x + 8, 280, f"skip s{k + 1}\n{co}×{r}²", 12, anchor="start", fill=TEAL)

    # previous-mask bus
    bus = 365
    s.line([(155, bus), (xs[3] + 150, bus)], CORAL, 2.6, head=False)
    for x in xs:
        s.line([(x + 150, bus), (x + 150, dy + dec_h)], CORAL, 1.8)
        s.line([(x + 150, bus), (x + 150, ey)], CORAL, 1.8)
    s.line([(hx + 110, bus), (hx + 110, dy + 30 + 4 * ch + 6)], CORAL, 1.8)
    s.text(hx + 6, 392, "previous mask, max-pooled\nto each block's size", 12, anchor="start", fill=CORAL)

    # legend
    ly = 622
    items = [("SE-Residual", "res"), ("MixPool", "mix"), ("MaxPool", "maxp"), ("Transposed conv", "tconv"),
             ("Concat", "concat"), ("Conv / Sigmoid / Threshold", "conv")]
    x = 190
    for label, kind in items:
        w = 14 + 7.6 * len(label)
        s.box(x, ly, w, 24, label, kind, size=12)
        x += w + 10
    s.line([(x + 6, ly + 12), (x + 46, ly + 12)])
    s.text(x + 52, ly + 12, "features", 12, anchor="start")
    s.line([(x + 120, ly + 12), (x + 160, ly + 12)], TEAL, dash="7 5")
    s.text(x + 166, ly + 12, "skip (concat)", 12, anchor="start", fill=TEAL)
    s.line([(x + 262, ly + 12), (x + 302, ly + 12)], CORAL)
    s.text(x + 308, ly + 12, "previous mask", 12, anchor="start", fill=CORAL)
    s.text(1318, 652, "7,720,266 parameters · shapes for a 256×256 input", 11, anchor="end", fill=SLATE, italic=True)
    s.save("architecture")


# ----------------------------------------------------------------- B. blocks

def blocks():
    s = Svg(1330, 700)
    # (a) SE-Residual
    s.text(20, 22, "(a) SE-Residual block", 17, anchor="start", weight="bold", fill=DARK)
    mx, mw, h = 50, 200, 34
    main = [("Input  C_in×h×w", "feat"), ("3×3 Conv  C_in→C_out", "conv"), ("Batch Norm", "bn"), ("ReLU", "relu"),
            ("3×3 Conv  C_out→C_out", "conv"), ("Batch Norm", "bn")]
    ys = [55 + i * 46 for i in range(len(main))]
    for (label, kind), y in zip(main, ys):
        s.box(mx, y, mw, h, label, kind, size=13)
    for a, b in zip(ys, ys[1:]):
        s.line([(mx + mw / 2, a + h), (mx + mw / 2, b)])
    add_y = ys[-1] + h + 30
    s.circle(mx + mw / 2, add_y, 15, "+")
    s.line([(mx + mw / 2, ys[-1] + h), (mx + mw / 2, add_y - 15)])
    s.box(mx, add_y + 32, mw, h, "ReLU", "relu", size=13)
    s.line([(mx + mw / 2, add_y + 15), (mx + mw / 2, add_y + 32)])
    s.box(mx, add_y + 32 + 58, mw, h, "Output  C_out×h×w", "feat", size=13)
    s.line([(mx + mw / 2, add_y + 32 + h), (mx + mw / 2, add_y + 32 + 58)])
    sx, sww = 285, 160
    short = [("1×1 Conv  C_in→C_out", "conv"), ("Batch Norm", "bn"), ("Squeeze & Excite", "se")]
    sy = [ys[1] + 20 + i * 52 for i in range(3)]
    for (label, kind), y in zip(short, sy):
        s.box(sx, y, sww, h, label, kind, size=13)
    for a, b in zip(sy, sy[1:]):
        s.line([(sx + sww / 2, a + h), (sx + sww / 2, b)], TEAL)
    s.line([(mx + mw, ys[0] + h / 2), (sx + sww / 2, ys[0] + h / 2), (sx + sww / 2, sy[0])], TEAL)
    s.line([(sx + sww / 2, sy[-1] + h), (sx + sww / 2, add_y), (mx + mw / 2 + 15, add_y)], TEAL)
    s.text(sx + sww / 2 + 8, sy[-1] + h + 26, "shortcut", 12, anchor="start", fill=TEAL, italic=True)
    s.text(mx + mw / 2 + 24, add_y + 16, "out = ReLU(main + shortcut)", 12, anchor="start", fill=SLATE)
    # SE detail
    s.rect(20, 520, 430, 165, FILL["note"], SLATE, 1, rx=8)
    s.text(32, 540, "Squeeze & Excite (channel attention)", 14, anchor="start", weight="bold", fill=DARK)
    row1 = [("Global avg pool\nC×h×w → C", "se"), ("FC  C→1", "conv"), ("ReLU", "relu")]
    row2 = [("FC  1→C", "conv"), ("Sigmoid → w (C)", "sig"), ("x × w per channel", "se")]
    for r, row in enumerate((row1, row2)):
        for i, (label, kind) in enumerate(row):
            x, y = 32 + i * 140, 560 + r * 62
            s.box(x, y, 125, 46, label, kind, size=12)
            if i:
                s.line([(x - 15, y + 23), (x, y + 23)])
    s.line([(32 + 2 * 140 + 62, 606), (32 + 2 * 140 + 62, 612), (94, 612), (94, 622)])
    s.text(440, 676, "hidden size 1, as in the official code", 11, anchor="end", fill=SLATE, italic=True)

    # (b) MixPool
    ox = 490
    s.text(ox, 22, "(b) MixPool block (one in every encoder and decoder stage)", 17, anchor="start", weight="bold", fill=DARK)
    s.box(ox, 60, 175, 56, "Previous mask M\n1×256×256", "mem", size=13, stroke=CORAL, sw=1.6)
    s.box(705, 60, 215, 56, "MaxPool (256/h)×(256/w)\n→ M_p  1×h×w", "maxp", size=13)
    s.line([(ox + 175, 88), (705, 88)], CORAL)
    s.box(ox, 250, 175, 56, "Feature map F\nC×h×w", "feat", size=13, stroke=DARK, sw=1.6)
    s.box(705, 160, 280, 56, "fmask head: 3×3 Conv → BN → ReLU\n→ 1×1 Conv → Sigmoid", "sig", size=13)
    s.box(1005, 160, 120, 56, "Threshold\n> 0.5 → M_f", "thr", size=13, stroke=CORAL, sw=1.6)
    s.text(1065, 232, "step: zero gradient", 11, fill=CORAL, italic=True)
    s.line([(ox + 87, 250), (ox + 87, 188), (705, 188)])
    s.line([(985, 188), (1005, 188)])
    ux, uy = 1185, 88
    s.circle(ux, uy, 18, "∪", 20)
    s.line([(920, 88), (ux - 18, 88)], CORAL)
    s.line([(1125, 188), (ux, 188), (ux, uy + 18)])
    s.text(ux - 26, uy - 30, "A = M_f ∪ M_p  (OR)", 13, anchor="end", weight="bold")
    mxx, myy = 1185, 278
    s.circle(mxx, myy, 18, "×", 20)
    s.line([(ux + 18, uy), (1300, uy), (1300, myy), (mxx + 18, myy)])
    s.line([(ox + 175, 278), (mxx - 18, 278)], DARK)
    s.text(mxx - 30, myy - 20, "F × A", 13, anchor="end", weight="bold")
    s.text(mxx - 30, myy + 22, "hard attention: zero outside A", 12, anchor="end", fill=SLATE)
    s.box(1060, 340, 250, 56, "3×3 Conv → BN → ReLU\nattended half  C/2", "conv", size=13)
    s.line([(mxx, myy + 18), (mxx, 340)])
    s.box(705, 412, 280, 56, "3×3 Conv → BN → ReLU\nplain half  C/2 (sees everything)", "conv", size=13)
    s.line([(ox + 87, 306), (ox + 87, 440), (705, 440)], DARK)
    s.box(1060, 470, 250, 46, "Concat → C×h×w", "concat", size=14, weight="bold")
    s.line([(mxx, 396), (mxx, 470)])
    s.line([(985, 440), (1020, 440), (1020, 493), (1060, 493)])
    s.box(1060, 560, 250, 46, "Output → next layer", "feat", size=13)
    s.line([(mxx, 516), (mxx, 560)])
    s.rect(ox, 500, 525, 185, FILL["note"], SLATE, 1, rx=8)
    s.text(ox + 14, 536, "Why two halves? If M is wrong, the plain half still\n"
                         "carries every feature, so a bad mask cannot erase the\npolyp; the next layers learn "
                         "how much to trust each half.", 13, anchor="start")
    s.text(ox + 14, 615, "Found in the code: the > 0.5 step has no gradient, so the\n"
                         "fmask convs (982,088 parameters, 13%) never train.", 13, anchor="start", fill=CORAL)
    s.save("blocks")


# ----------------------------------------------------------------- C. training and testing loop

def loop():
    rows = list(csv.DictReader(open(ROOT / "runs" / "kvasir_official" / "eval_test" / "results.csv")))
    dice = [float(r["dice"]) for r in rows]
    s = Svg(1330, 660)
    s.rect(8, 8, 1314, 372, "#FAFCFC", "#C9D6D8", 1, rx=10)
    s.text(22, 30, "Training: one epoch (repeated until no val improvement for 40 epochs; best = epoch 107 of 147)",
           16, anchor="start", weight="bold", fill=DARK)
    y, h = 85, 64
    s.box(22, y, 165, h, "Train set: 880\nshuffled, batch 8", "feat", 13)
    s.box(215, y, 235, h, "Augment (p 0.3 each)\nrotate ±35°, flips: image + GT\ncutout holes: image only", "maxp", 12)
    s.box(480, y, 170, h, "FANet\n(image, prev mask)", "mix", 14, weight="bold")
    s.box(680, y, 165, h, "Probabilities\nsigmoid(logits)", "sig", 13)
    s.box(875, y, 205, h, "Loss vs ground truth\n0.5·BCE + 0.5·Dice", "thr", 13, stroke=CORAL)
    s.box(1110, y, 195, h, "Backward + Adam\nlr 1e-4, batch of 8", "conv", 13)
    for a, b in ((187, 215), (450, 480), (650, 680), (845, 875), (1080, 1110)):
        s.line([(a, y + h / 2), (b, y + h / 2)])
    s.line([(1207, y), (1207, 58), (565, 58), (565, y)], TEAL)
    s.text(886, 46, "update the weights (every batch)", 12, fill=TEAL)
    my = 215
    s.box(480, my, 170, 72, "Mask memory\n880 × 1×256×256\nOtsu before epoch 1", "mem", 12, stroke=CORAL, sw=1.6)
    s.line([(565, my), (565, y + h)], CORAL)
    s.text(573, 178, "get(idx): looked up by\nimage index; NOT rotated", 11, anchor="start", fill=CORAL)
    s.box(680, my, 165, 72, "Staging copy\nstage(idx, probs > 0.5)", "plain", 12, dash="5 4")
    s.line([(762, y + h), (762, my)])
    s.box(875, my, 205, 72, "End of epoch:\nval loss (120 images)\nimproved?", "concat", 13, stroke=AMBER, sw=1.8)
    s.line([(845, my + 36), (875, my + 36)])
    s.box(1110, 196, 195, 52, "Yes → commit:\nmemory ← staging; save best.pt", "se", 12)
    s.box(1110, 262, 195, 52, "No → keep old memory;\nLR ×0.1 after 5, stop after 40", "note", 12)
    s.line([(1080, my + 20), (1110, 222)])
    s.line([(1080, my + 52), (1110, 288)])
    s.line([(1305, 222), (1318, 222), (1318, 345), (565, 345), (565, my + 72)], CORAL)
    s.text(940, 360, "next epoch: each image gets its own last good prediction as the hint", 12, fill=CORAL)

    s.rect(8, 392, 1314, 260, "#FAFCFC", "#C9D6D8", 1, rx=10)
    s.text(22, 414, "Testing: weights frozen (no loss, no backward), 10 refinement rounds per image",
           16, anchor="start", weight="bold", fill=DARK)
    s.box(22, 445, 165, 56, "Test image\n(120, never trained on)", "feat", 12)
    s.box(22, 530, 165, 56, "Round-0 mask\nOtsu (or empty)", "mem", 12, stroke=CORAL)
    s.box(255, 480, 190, 70, "FANet (best.pt)\nsame forward pass", "mix", 14, weight="bold")
    s.box(480, 480, 150, 70, "Mask\nprobs > 0.5", "thr", 13)
    s.box(665, 480, 175, 70, "Write back\nmemory ← mask\n(every round)", "mem", 12, stroke=CORAL)
    s.line([(187, 473), (220, 473), (220, 505), (255, 505)])
    s.line([(187, 558), (220, 558), (220, 525), (255, 525)], CORAL)
    s.line([(445, 515), (480, 515)])
    s.line([(630, 515), (665, 515)])
    s.line([(752, 550), (752, 615), (350, 615), (350, 550)], CORAL)
    s.text(551, 630, "round r+1 uses round r's mask as its hint", 12, fill=CORAL)
    # Dice per round
    bx, by, bw, bh = 885, 440, 425, 200
    s.text(bx, by + 4, "Test Dice after each round (Otsu start)", 13, anchor="start", weight="bold")
    lo, hi = 0.5, 0.9
    gap = bw / len(dice)
    base = by + bh - 18
    for i, d in enumerate(dice):
        top = base - (d - lo) / (hi - lo) * (bh - 60)
        s.rect(bx + i * gap + 4, top, gap - 8, base - top, TEAL if i == len(dice) - 1 else FILL["res"], TEAL, 1, rx=2)
        s.text(bx + i * gap + gap / 2, top - 10, f"{d:.3f}"[1:], 11)
        s.text(bx + i * gap + gap / 2, base + 10, str(i + 1), 11, fill=SLATE)
    s.save("loop")


# ----------------------------------------------------------------- D. data pipeline

def pipeline():
    s = Svg(1330, 250)
    s.text(14, 20, "Data in (dataset.py, split.py)", 15, anchor="start", weight="bold", fill=DARK)
    row = [("Kvasir-SEG\n1000 images + masks\n(doctor-drawn)", "feat"),
           ("split.py, seed 42\nrandom hold-out\n880 train / 120 test", "maxp"),
           ("Resize once to 256²\nimage: bilinear\nmask: nearest (stays 0/1)", "conv"),
           ("Mask clean-up\n> half of max value\n(JPEG noise at edges)", "thr"),
           ("Kept in RAM\npixels ÷ 255 → [0, 1]\nreturns (image, mask, i)", "se"),
           ("DataLoader\nbatch 8, shuffle (train)\nindex i → memory slot", "concat")]
    w, gap = 200, 22
    for i, (label, kind) in enumerate(row):
        x = 14 + i * (w + gap)
        s.box(x, 36, w, 74, label, kind, 12)
        if i:
            s.line([(x - gap, 73), (x, 73)])
    s.text(14, 140, "Scoring (evaluate.py, metrics.py)", 15, anchor="start", weight="bold", fill=DARK)
    row2 = [("best.pt\n(epoch 107)", "mix"), ("10 refinement rounds\nmask = probs > 0.5", "thr"),
            ("Per image: TP, FP, FN, TN\nDice, IoU, P, R, F2 …\nthen mean of 120 images", "conv"),
            ("Boxes from blobs\nconnected components\n(≥ 20 px) per mask", "se"),
            ("Box match at IoU ≥ 0.5\nbox precision 0.685\nbox recall 0.800", "concat"),
            ("Headline (round 10)\nDice 0.842 · IoU 0.779\npaper 0.880", "feat")]
    for i, (label, kind) in enumerate(row2):
        x = 14 + i * (w + gap)
        s.box(x, 156, w, 74, label, kind, 12, weight="bold" if i == 5 else "normal")
        if i:
            s.line([(x - gap, 193), (x, 193)])
    s.save("pipeline")

    # the data row alone, larger, for the setup slide
    d = Svg(1330, 100)
    w, gap = 206, 18
    for i, (label, kind) in enumerate(row):
        x = 4 + i * (w + gap)
        d.box(x, 6, w, 88, label, kind, 14)
        if i:
            d.line([(x - gap, 50), (x, 50)])
    d.save("pipeline_data")


if __name__ == "__main__":
    architecture()
    blocks()
    loop()
    pipeline()
