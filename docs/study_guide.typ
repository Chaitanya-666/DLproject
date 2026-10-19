// Weekend study guide for the FANet project. Compile: typst compile docs/study_guide.typ
#set document(title: "FANet project: weekend study guide", author: "Chaitanya Shinde")
#set page(paper: "a4", margin: (x: 2cm, y: 2cm), numbering: "1")
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 10.5pt)
#set par(justify: true)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => { if it.numbering != none { pagebreak(weak: true) }; it }
#show raw.where(block: true): it => block(fill: luma(244), inset: 8pt, radius: 3pt, width: 100%, it)
#show raw.where(block: false): it => box(fill: luma(240), inset: (x: 2pt), outset: (y: 2pt), radius: 2pt, it)

#let task(body) = block(fill: rgb("#e6f2f3"), inset: 9pt, radius: 3pt, width: 100%)[*Do it yourself.* #body]
#let note(body) = block(stroke: (left: 2pt + rgb("#e0604f")), inset: (left: 9pt, y: 4pt), body)

#align(center)[
  #text(18pt, weight: "bold")[FANet project: weekend study guide] \
  #v(2pt)
  Chaitanya Shinde · 231070066 · Deep Learning mini-project \
  For Sat 24 – Sun 25 Oct 2026 · repo state `bf255f4` and later
]

#v(8pt)
*Goal.* By Sunday evening you can (1) explain FANet's idea in two sentences, (2) open any file in `src/` and say what it does and why, (3) present the 14-slide deck, and (4) answer "why 0.842 and not 0.880?" without notes.

*How to use this.* Four sessions of about 1.5–2 hours. In each: read the code listed, answer the quiz *in writing before* looking at the answers (they are all in @answers at the end), then make the small change yourself. Typing the change is what makes it stick; do not ask Claude to type it for you, ask Claude to check it.

*Setup (fish shell), once:*
```fish
cd /mnt/Windows_D/College-work/DLproject
git pull
source ~/.venvs/dlproject/bin/activate.fish
python -m src.model            # should print (2, 1, 256, 256) and 7,720,266
```

#outline(depth: 1, indent: 1em)

= Saturday morning: the idea and the data

*Read:* README §2–§4 (the problem, background, the paper), then `src/dataset.py` and `src/memory.py`.

== What to understand
- The task is *binary segmentation*: one 0/1 label per pixel, polyp or background. Boxes are drawn around the mask's blobs afterwards (detection view).
- FANet's one new idea: for every image, keep the mask the network predicted for it *last time* (the memory), and feed it back in as a second input.
- Before the network has predicted anything, the memory is a classical Otsu threshold (`src/memory.py:17`, `:31`).
- The memory is only replaced when the test loss improves (`src/train.py:171–173`), so it always comes from the best model so far.

== Quiz
+ Why is this segmentation and not classification? What exactly is the output tensor's shape for one image?
+ `dataset.py` returns `(image, mask, index)`. Why does it need to return the *index*?
+ What does Otsu's method maximise? Why is its mask a poor polyp guess on colonoscopy images (give the 60% / 14% numbers)?
+ In `MaskMemory`, what is the difference between `stage()` and `commit()`? Why have two steps?
+ Is ground truth ever fed into the network as input? Where would you look to prove it?

#task[
  In a Python shell, load the memory for the test set and print what fraction of each image Otsu marks:
  ```python
  from src.dataset import SegmentationDataset
  from src.memory import MaskMemory
  d = SegmentationDataset("data/Kvasir-SEG", "test", 256)
  m = MaskMemory(d.images)
  print(m.masks.float().mean().item(), d.masks.mean())
  ```
  You should get about 0.596 and 0.142. Write one sentence on what that means for round 1.
]

= Saturday afternoon: the network

*Read:* `src/blocks.py` (all of it) and `src/model.py`. Keep slide 5 (architecture) and slide 6 (MixPool) open beside the code.

== What to understand
- `ResidualBlock` (`blocks.py:38`): two 3×3 convs plus a 1×1 shortcut with squeeze-and-excitation. Output = ReLU(main + shortcut).
- `MixPool` (`blocks.py:67`, forward at `:109`): fmask guess OR previous mask = attention; masked features and *unmasked* features go through separate convs; concatenate.
- `FANet.forward` (`model.py:72`): four encoder blocks, four decoder blocks, the memory goes into *every* block, and is concatenated once more before the final 1×1 conv.

== Quiz
+ Trace the shapes for one 256×256 image through `e1`…`e4` and `d1`…`d4`. Which tensors are the skip connections?
+ Why does `MixPool` max-pool the previous mask (not average-pool) down to the feature size?
+ What happens in `MixPool` if the previous mask is completely wrong? Which line saves the network?
+ Line `blocks.py:110` thresholds with `> 0.5`. Why does that mean the fmask convolutions never train? How many parameters is that?
+ Why does `ResidualBlock` need a 1×1 conv on the shortcut?
+ What does squeeze-and-excitation do, in one sentence? What is odd about how this code builds it (`reduction=out_c`)?

#task[
  1. In `FANet.forward`, add `print(p1.shape, p2.shape, p3.shape, p4.shape, d.shape)` before the `return`, run `python -m src.model`, check against your answer to question 1, then remove the print.
  2. Prove the fmask claim yourself:
  ```python
  import torch
  from src.model import FANet
  net = FANet()
  out = net(torch.rand(1, 3, 256, 256), torch.ones(1, 1, 256, 256))
  out.mean().backward()
  dead = [n for n, p in net.named_parameters() if p.grad is None]
  print(len(dead), dead[:4])
  ```
  3. Change `widths=(32, 64, 128, 256)` to `(16, 32, 64, 128)` in a shell (`FANet(widths=...)`), count parameters, and explain why it drops by roughly 4×. Do not commit this.
]

= Sunday morning: training and testing

*Read:* `src/losses.py`, `src/augment.py` (especially `official_geometric` at `:78`), `src/train.py` (`run_epoch` at `:54`, the epoch loop from `:160`), `src/evaluate.py` (refinement loop around `:95–110`), `src/metrics.py`.

== What to understand
- Loss: `0.5·BCE + 0.5·Dice` (`losses.py`). BCE gives smooth per-pixel gradients; Dice handles the 14%-polyp imbalance.
- Augmentation: the *official* mode rotates and flips the image and ground truth, but *not* the memory (`train.py:78`). This is deliberate (see the afternoon).
- Test-time refinement (`evaluate.py`): start from Otsu (or zeros with `--start zeros`), predict, write the prediction back into memory (`:108`), repeat 10 times; metrics after every round.
- Metrics are computed per image and averaged over images. Dice = 2TP/(2TP+FP+FN); IoU = TP/(TP+FP+FN).

== Quiz
+ Why not use plain accuracy? What accuracy would an all-background prediction get on Kvasir-SEG?
+ Why is `binary_cross_entropy_with_logits` used instead of `sigmoid` followed by `binary_cross_entropy`?
+ `ReduceLROnPlateau(patience=5, factor=0.1)`: what did it do in our run (look at `runs/kvasir_official/train.log`)? Why did training stop at epoch 147?
+ Which checkpoint is saved, and by which number is it chosen? Why is that "slightly optimistic"?
+ How are bounding boxes produced from a mask (`metrics.py:68`, `:91`)? When is a predicted box counted as a hit?
+ Round 1 from Otsu gives Dice 0.615, round 10 gives 0.842. What is the model doing between rounds (look at precision and recall in `runs/kvasir_official/eval_test/results.csv`)?

#task[
  1. Run a sanity training on the leaf set and read every printed column:
  ```fish
  python -m src.train --data dataset/custom/synthetic_leaf --out /tmp/try --epochs 3 --size 128
  ```
  2. Evaluate the real model with only 3 rounds, once from each start, and compare round 1:
  ```fish
  python -m src.evaluate --ckpt runs/kvasir_official/best.pt --data data/Kvasir-SEG --iters 3 --out /tmp/e1
  python -m src.evaluate --ckpt runs/kvasir_official/best.pt --data data/Kvasir-SEG --iters 3 --start zeros --out /tmp/e2
  ```
  3. Open three images in `/tmp/e1/strips/` and say, for each, which round fixed what.
]

= Sunday afternoon: the results and the story

*Read:* README §5.4 points 3–5, §10 (results), §12 (viva answers). Then the deck, slide by slide.

== The story in five lines (memorise these)
+ FANet feeds each image's last predicted mask back into every encoder and decoder block (MixPool) and refines its answer at test time.
+ We built it from scratch and trained on Kvasir-SEG at 256×256: Dice *0.842* with the paper's protocol (paper: 0.880 at 512×512).
+ Our first attempt "fixed" the authors' augmentation by rotating the memory with the image. That made the model *copy* its memory: 0.684. The authors' misalignment acts as a regulariser.
+ The final model still over-trusts an over-full start (Otsu marks 60% of the image). Starting from an empty mask instead gives *0.900* with the same weights; this is our test-time variant, reported separately.
+ The same network, fine-tuned on a script-generated leaf-spot dataset, goes from 0.474 to 0.984 Dice.

== Numbers to know without notes
#table(
  columns: (auto, auto),
  inset: 5pt,
  stroke: 0.4pt + luma(180),
  [Parameters], [7,720,266 (fmask: 982,088 never train, about 13%)],
  [Dataset], [Kvasir-SEG, 1000 images, 880 train / 120 test, 256×256],
  [Paper (512×512)], [Dice 0.880, mIoU 0.815],
  [Ours, paper protocol], [Dice 0.842, mIoU 0.779, recall 0.934, precision 0.835],
  [Ours, empty start], [Dice 0.900, mIoU 0.841],
  [First attempt (aligned memory)], [Dice 0.684],
  [Speed], [about 87 images/s on the RTX 5050],
  [Leaf transfer], [0.474 before, 0.984 after fine-tuning],
)

== Rehearsal
#task[
  Present the deck out loud, once, timing yourself (target 12–15 minutes). For each slide, say its title sentence first, then one or two supporting points. The speaker notes in the `.pptx` have a prompt for every slide. Then answer the README §12 questions out loud, without looking.
]

#note[If the Kaggle results (no-feedback ablation, 512×512 run) have arrived, they are in the results table and slide 10. Rebuild the deck with `node presentation/build_deck.js` after any `kaggle/offload.sh pull`.]

= Answers <answers>

== Saturday morning
+ The output is a label for every pixel, not one label per image: logits of shape (1, 256, 256), thresholded at 0.5 after a sigmoid.
+ The index says which slot of the memory belongs to this image. It is what makes shuffling safe; the authors' code had to keep the loader order fixed instead.
+ It picks the grey level that maximises the between-class variance of the histogram. On colonoscopy images it splits bright from dark (lit mucosa and glare vs shadow), not polyp from wall: it marks about 60% of each test image while polyps cover about 14%.
+ `stage()` writes this epoch's predictions to a copy; `commit()` makes them the memory. Two steps so a worse epoch does not overwrite the memory: we only commit when test loss improved.
+ No. `train.py` passes `memory.get(idx)` as `prev`; the memory only ever holds Otsu masks or the model's own thresholded predictions (`memory.py:60–73`).

== Saturday afternoon
+ e1: skip (32, 256, 256), out (32, 128, 128); e2: (64, 128, 128) → (64, 64, 64); e3: (128, 64, 64) → (128, 32, 32); e4: (256, 32, 32) → (256, 16, 16); d1 (128, 32, 32), d2 (64, 64, 64), d3 (32, 128, 128), d4 (16, 256, 256). The skips are the pre-pooling outputs s1–s4.
+ Max pooling keeps a cell at 1 if any pixel in it was 1, so small polyps survive the downsizing; averaging would fade them below 0.5.
+ The unmasked branch (`plain = self.conv2(x)`, `blocks.py:115`) still sees every feature, so a wrong mask cannot erase information.
+ A step function has zero gradient almost everywhere, so no gradient flows back into the fmask convs. 48 parameter tensors, 982,088 parameters, about 13% of the model.
+ The input and output channel counts differ, and you can only add tensors of the same shape.
+ It learns a weight in (0, 1) per channel from the globally averaged features and rescales the channels. With `reduction=out_c` the hidden layer has exactly one unit, a very narrow bottleneck; copied from the authors.

== Sunday morning
+ An all-background prediction is already about 86% accurate because polyps cover ~14% of pixels, so accuracy hides failure. Dice only rewards overlap with the polyp.
+ It combines the sigmoid and the log in one numerically stable function; the value is the same.
+ It cut the learning rate by 10× each time test loss stalled for 5 epochs (1e-4 → 1e-5 → … → 1e-8). The best checkpoint was epoch 107; early stopping ended training 40 epochs later, at 147.
+ `best.pt`, chosen by the lowest test loss, computed with the training-time memory. The same images are then used for the final scores, so model selection has seen the test set (as in the authors' code).
+ Connected components with 8-connectivity (breadth-first search), one box around each blob of at least 20 pixels; predicted and true boxes are matched greedily, a hit needs IoU ≥ 0.5.
+ Precision rises from 0.53 to 0.83 while recall falls slightly (0.97 to 0.93): each round trims the oversized region inherited from Otsu.
