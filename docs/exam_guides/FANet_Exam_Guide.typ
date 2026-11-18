// FANet exam guide: follows docs/report.typ (Part A) and the 20 slides (Part B).
// Quotes are copied from DLproject/docs/report.typ and presentation/build_deck.js (deck: 20 slides, 18 Nov).
// Theory citations point to the student's revision notes in
// collegestuff/sem07/DeepLearning/guides/ (Ch4, Ch5, Master Revision Guide).
#set document(title: "FANet exam guide", author: "Chaitanya Shinde")
#set page(paper: "a4", margin: (x: 2cm, y: 1.9cm), numbering: "1",
  header: context { if counter(page).get().first() > 1 [
    #set text(8pt, fill: luma(120)); FANet exam guide #h(1fr) Chaitanya Shinde, 231070066 ] })
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 11pt, lang: "en")
#set par(justify: false, leading: 0.58em)
#show heading: set text(font: "Inter", weight: "bold")
#show heading.where(level: 1): it => { pagebreak(weak: true); text(16pt, fill: rgb("#0e3b43"), it); v(0.2em) }
#show heading.where(level: 2): it => { v(0.5em); text(13pt, fill: rgb("#14545e"), it) }
#show heading.where(level: 3): set text(11.5pt, fill: rgb("#14545e"))
#show raw.where(block: true): it => block(fill: luma(246), inset: 6pt, radius: 2pt, width: 100%, text(8.6pt, it))
#show raw.where(block: false): it => text(font: "DejaVu Sans Mono", size: 9pt, fill: rgb("#14545e"), it.text)
#set table(stroke: 0.4pt + luma(165), inset: 4.5pt)
#show table.cell.where(y: 0): set text(weight: "bold")

// ---------------------------------------------------------------- the four boxes
#let bx(title, bg, accent, body) = block(width: 100%, fill: bg, stroke: (left: 3pt + accent),
  inset: (x: 9pt, y: 6pt), radius: 2pt, above: 0.55em, below: 0.55em, breakable: false)[
  #text(font: "Inter", size: 8pt, weight: "bold", fill: accent)[#upper(title)] \ #body]
#let says(body) = bx("Your report says", rgb("#eef0f4"), rgb("#4a5568"), text(style: "italic", body))
#let slidesays(body) = bx("Your slide says", rgb("#eef0f4"), rgb("#4a5568"), text(style: "italic", body))
#let plain(body) = bx("In plain words", rgb("#edf7ea"), rgb("#2e7d32"), body)
#let where(body) = bx("Where it is in the code", rgb("#e6f2f3"), rgb("#1f6f78"), body)
#let ask(..qs) = block(breakable: false, width: 100%, bx("Ma'am may ask", rgb("#fff6e2"), rgb("#b9790a"), {
  let items = qs.pos()
  for i in range(0, items.len(), step: 2) {
    block(above: 0.45em, below: 0.45em)[*Q.* #items.at(i) \ *A.* #items.at(i + 1)]
  }
}))
#let note(body) = text(fill: rgb("#7a4b00"), size: 9.5pt)[#body]
#let thumb(n) = align(center, image("figures/slides/s-" + (if n < 10 { "0" } else { "" }) + str(n) + ".jpg", width: 62%))

// ---------------------------------------------------------------- title page
#align(center)[
  #v(1.2cm)
  #text(10pt, font: "Inter", fill: luma(90))[DEEP LEARNING LAB EXAM · THU 19 NOV 2026 · LAB 1B]
  #v(0.4cm)
  #text(24pt, font: "Inter", weight: "bold", fill: rgb("#0e3b43"))[FANet: your exam guide]
  #v(0.15cm)
  #text(12.5pt)[Your report and your slides, explained one part at a time]
  #v(0.5cm)
  Chaitanya Shinde · Roll no. 231070066 \ B.Tech Computer Engineering, Semester VII, 2026-27
]
#v(0.5cm)
#block(width: 100%, inset: 11pt, stroke: 0.7pt + rgb("#1f6f78"), radius: 3pt)[
  *Why this guide looks like this.* Ma'am will open your *report* and your *slides* and ask about anything in them. So this guide follows them exactly:
  - *Part 0* starts from zero: the story, the pipeline, the words, the repo, how to run it.
  - *Part A* walks through `docs/report.typ` in its own order, with its own headings.
  - *Part B* walks through the 20 slides in order.
  - *Part C* lists the few places where the report, the slides and the logs disagree, and what to say.
  - *Part D* is a one-page cheat sheet.

  *Every unit has the same four boxes:*
  #bx("Your report says / Your slide says", rgb("#eef0f4"), rgb("#4a5568"))[An exact quote from your report or slide. Numbers are exactly as printed there.]
  #bx("In plain words", rgb("#edf7ea"), rgb("#2e7d32"))[A short explanation. Theory is taken from *your own class notes* and cited like this: _(your Ch4 notes, §3)_. "Ch4" = `DL_Ch4_CNNs_Architectures_Backprop.pdf`, "Ch5" = `DL_Ch5_Object_Detection.pdf`, "Master" = `DL_Master_Revision_Guide.pdf`. If your notes do not cover a concept, the box says so.]
  #bx("Where it is in the code", rgb("#e6f2f3"), rgb("#1f6f78"))[`file:line` in the `DLproject` repo, with a few real lines copied from `src/`.]
  #bx("Ma'am may ask", rgb("#fff6e2"), rgb("#b9790a"))[Two to four likely questions with short answers.]

  *How to read it.* Tonight: Part 0, then Part A. Wednesday: Part B, saying each slide out loud, then Part C. Thursday morning: Part D. (Details in 0.6.)
]

#pagebreak()
#outline(depth: 2, indent: 1em)

// =====================================================================
= Part 0: your project from zero

#let story(body) = bx("The story", rgb("#f3f0fa"), rgb("#5b3fa0"), body)

== 0.1 The whole project as a story
#story[
- *The problem.* Colorectal cancer usually starts as a *polyp*, a small growth on the colon wall. Doctors find polyps with a camera test called *colonoscopy*, but about one adenoma in four is missed (26%, Zhao et al. 2019). Each +1% in detection lowers later cancer risk by about 3% (Corley et al. 2014). A model that outlines polyps can be a second pair of eyes.
- *What goes in and what comes out.* In: one colour colonoscopy photo, resized to 256×256. Out: a 256×256 *mask*, one 0/1 value per pixel (1 = polyp). See the pictures below.
- *Segmentation vs detection here.* *Segmentation* = a label for every pixel (your main output). *Detection* = a box around each object. You get boxes for free by drawing one box around each blob of your mask.
- *What you did.* You implemented the IEEE TNNLS 2023 paper *FANet* from scratch in PyTorch. FANet remembers the mask it predicted for each image and feeds it back in as a "look here" hint (feedback attention). At test time it refines its own mask over 10 rounds, starting from a rough Otsu guess.
- *The headline results* (Kvasir-SEG, 120 test images): Dice *0.842* with the paper's protocol, against *0.880* in the paper. *0.900* from an empty start. Without feedback: *0.883*. At 512×512: *0.831*.
- *The custom dataset.* You took 30 public leaf photos (LDSD, CC0), drew the disease spots by hand in Roboflow, and made 126 images with augmentation. Fine-tuned from your polyp model: *0.517* Dice on 118 unseen leaf photos (0.467 from random weights).
]

#figure(image("figures/kvasir_example.png", width: 80%),
  caption: [Input and target. Left: a Kvasir-SEG test image (the input). Middle: its ground-truth mask, drawn by a doctor (white = polyp). Right: the mask over the image. From `presentation/assets/kvasir_example.png`.])
#figure(image("figures/strip_kvasir_official.png", width: 100%),
  caption: [What your model does on three test images. Columns: image | ground truth | Otsu start | round 1 | round 2 | round 10. The *last column is your final prediction* (blue overlay). From `presentation/assets/strip_kvasir_official.png` (slide 16, report Fig.).])

== 0.2 The pipeline, end to end
Thirteen steps from raw data to your report. Each row: what happens, and where.
#{
set text(9.6pt)
table(columns: (auto, auto, 1fr, auto),
  [\#], [Step], [What happens here], [File : lines],
  [1], [Download], [Get Kvasir-SEG (1000 images + masks) into `data/Kvasir-SEG/images` and `masks`.], [`dataset/README.md`],
  [2], [Split], [Shuffle with seed 42; first 120 = test, rest 880 = train; write `train.txt`, `test.txt`.], [`src/split.py:36-49`],
  [3], [Load], [Resize every image and mask to 256×256 and keep them in memory; return (image, mask, index).], [`src/dataset.py:59-113`],
  [4], [Memory start], [Make one Otsu mask per image: the first "previous mask".], [`src/memory.py:31-52`],
  [5], [Augmentation], [Randomly rotate (±35°) and flip image + mask; the memory is not moved.], [`src/augment.py:78-99`, `src/train.py:79-82`],
  [6], [Model], [Encoder (4 blocks) → decoder (4 blocks), each with a MixPool that uses the memory; 1×1 head.], [`src/model.py:56-88`, `src/blocks.py:109-116`],
  [7], [Loss], [0.5·BCE + 0.5·Dice between prediction and true mask.], [`src/losses.py:21-29`],
  [8], [Training loop], [For each batch: predict, loss, backward, Adam step, stage the predicted mask. Laptop RTX 5050, or Kaggle T4 via `kaggle/offload.sh`.], [`src/train.py:54-111`, `:177-217`],
  [9], [Checkpoint], [If the validation loss improved: commit the memory and save `best.pt`.], [`src/train.py:187-201`],
  [10], [Evaluation], [Load `best.pt`; start from Otsu; predict and feed back for 10 rounds.], [`src/evaluate.py:81-120`],
  [11], [Metrics], [Per-image Dice, IoU, precision, recall, F2; boxes from blobs; write `results.csv`.], [`src/metrics.py:27-149`],
  [12], [Figures], [Learning curves, refinement chart, image strips.], [`src/figures.py`, `presentation/make_assets.py`],
  [13], [Report and deck], [The deck reads the CSVs in `runs/`; the report is written in Typst.], [`presentation/build_deck.js`, `docs/report.typ`],
)
}

== 0.3 The words you need before Part A
#{
set text(9.8pt)
table(columns: (auto, 1fr, auto),
  [Word], [Meaning (1-2 lines)], [Your notes],
  [Image as numbers], [A grayscale image is one matrix; a colour image has 3 channels (R, G, B). Your code divides pixels by 255 so they lie in [0, 1].], [Ch4 §3],
  [Tensor], [A grid of numbers with several dimensions. A batch of images is B × 3 × H × W; a batch of masks is B × 1 × H × W.], [not in notes],
  [Convolution], [A small filter slides over the image and makes a feature map; each filter detects one kind of pattern.], [Ch4 §2, §3],
  [Channels], [The depth of a feature map. A conv layer's output depth = its number of filters.], [Ch4 §4],
  [Pooling], [Shrinks height and width. Max pooling keeps the largest value in each window.], [Ch4 §3],
  [Encoder / decoder], [Encoder compresses; decoder rebuilds. In your model the decoder rebuilds a mask.], [Master §2.13],
  [Epoch / batch], [Epoch = one full pass over the training set. Batch = the images used for one update (8 here).], [Master §1.3, §1.11],
  [Loss], [One number saying how wrong the prediction is; training makes it smaller.], [Master §1.3, §1.9],
  [Gradient descent], [Move each weight against its gradient: $W_"new" = W_"old" - alpha dot (partial "Loss") / (partial W)$.], [Master §1.11],
  [Sigmoid], [$1 slash (1 + e^(-x))$: squashes any number into (0, 1), read as a probability.], [Master §1.10],
  [Threshold 0.5], [Probability above 0.5 → pixel = polyp (1); otherwise background (0).], [not in notes; `src/memory.py:64`],
  [Dice / IoU], [Overlap of predicted and true masks. Dice = 2TP/(2TP+FP+FN); IoU = intersection ÷ union.], [Master §1.9, Ch5 §6],
  [Overfitting], ["Low training error, high test error": the model memorised instead of learned.], [Ch4 §8],
  [Train / test split], [Train on one part; "test the network on new data" it never saw.], [Master §1.3 step 7],
  [Checkpoint], [A saved copy of the model's weights; yours is `best.pt` (the epoch with the lowest validation loss).], [not in notes; `src/train.py:193`],
  [GPU], [Graphics card that runs the maths in parallel; "GPU training makes training much faster".], [Master §4.13],
)
}

== 0.4 A tour of the repo
The repo is `/mnt/Windows_D/College-work/DLproject` (GitHub `Chaitanya-666/DLproject`).
#block(breakable: false, table(columns: (auto, 1fr),
  [Folder], [What is inside],
  [`src/`], [All the code: model, blocks, memory, data, augmentation, loss, metrics, training, evaluation, memory probe, Roboflow converter, synthetic leaves, figures.],
  [`notebooks/`], [`FANet_project.ipynb` (the submission notebook, run with outputs) and `kaggle_fanet.ipynb`.],
  [`kaggle/`], [`offload.sh` (send a training run to a free Kaggle GPU and pull the results) and `run_template.py`.],
  [`runs/`], [One folder per experiment: `log.csv` (per epoch), `best.pt` (weights, not in git), `eval_test/results.csv` (per round), `memory_probe.csv`.],
  [`data/`], [Downloaded data, not in git: `Kvasir-SEG/`, `LDSD/`, the Roboflow export and the 30 upload photos.],
  [`dataset/`], [Small datasets kept in git: `custom/synthetic_leaf/` (60 generated images) and `custom/roboflow_leaf/` (your converted Roboflow set, `agreement.csv`).],
  [`presentation/`], [The PPTX, `build_deck.js` (builds it), `figures/` and `assets/` (pictures and Roboflow screenshots).],
  [`docs/`], [`report.typ` / `report.pdf` (the submitted report), the project book and the study guide.],
  [`submission/`], [The zipped package sent to ma'am (presentation, notebook, Roboflow dataset, report, code) and the Hugging Face weights. Not in git.],
))
#bx("If ma'am says \"show me the code\", open these 5 files", rgb("#e6f2f3"), rgb("#1f6f78"))[
+ `src/blocks.py` lines 109-116: *MixPool*, the heart of FANet.
+ `src/model.py` lines 56-88: the whole *FANet* (encoders, decoders, head).
+ `src/memory.py`: the *memory* (Otsu start, stage, commit).
+ `src/train.py` lines 54-111 and 187-201: the *training step* and the *save/commit rule*.
+ `src/evaluate.py` lines 95-120: the *10-round refinement*.
]

== 0.5 How to run it (if you are asked to demo)
Run everything from the repo root, inside the project's Python environment (`source ~/.venvs/dlproject/bin/activate.fish`). Do not retrain live: the main run took about 1.7 hours. Use the saved `best.pt`.
```bash
python -m src.model
#   output: (2, 1, 256, 256)
#   parameters: 7,720,266

python -m src.evaluate --ckpt runs/kvasir_official/best.pt \
    --data data/Kvasir-SEG --split test --iters 10
#   round 1 fps 54.1129 dice 0.6148 jaccard 0.5115 ...
#   round 10 fps 87.3115 dice 0.8422 jaccard 0.7790 ...
#   saved to runs/kvasir_official/eval_test     (results.csv, strips/, masks/)

python -m src.memory_probe --ckpt runs/kvasir_official/best.pt \
    --data data/Kvasir-SEG
#   Otsu          dice 0.6151  precision 0.5301  recall 0.9653   (one line per start)
#   saved runs/kvasir_official/memory_probe.csv

# training (only to show it starts; the README's 1-minute sanity check):
python -m src.train --data data/Kvasir-SEG --out runs/sanity --epochs 2 --max-batches 20
#   train 880 | test 120 | device cuda
#   FANet parameters: 7,720,266
#   epoch   1 | loss ... | dice ... | lr 1.0e-04 | ...s | saved
```
The full training command was `python -m src.train --data data/Kvasir-SEG --out runs/kvasir_official` (README §8). Each epoch prints train/validation loss and Dice; `log.csv` and `best.pt` go into the `--out` folder. Add `--start zeros` to `evaluate` for the 0.900 empty-start result.

== 0.6 How to use this guide
#table(columns: (auto, 1fr),
  [When], [What to read],
  [Tonight (Tue 17 Nov)], [Part 0 (this part) slowly, then Part A, report section by section. Say each "Ma'am may ask" answer out loud.],
  [Wednesday 18 Nov], [Part B: present all 20 slides out loud once, using the "Your slide says" box as your script. Then Part C twice.],
  [Thursday morning], [Part D (cheat sheet) and the five code files in 0.4.],
)


// =====================================================================
= Part A: your report, section by section

== Title page and abstract
#says[Polyp Segmentation for Colorectal Cancer Screening using FANet (Feedback Attention Network) \
"Under the paper's test protocol (ten rounds of iterative refinement starting from an Otsu mask) our model reaches a Dice coefficient of *0.842* at 256×256, against 0.880 reported at 512×512; starting the refinement from an empty mask gives *0.900*." \
"Fine-tuned from the polyp weights, FANet reaches Dice *0.517* on 118 held-out leaf photos, against 0.467 when trained from random weights."]
#plain[
- *Segmentation* means giving every pixel a label. Here the label is "polyp" or "background". Your notes list it as one of the vision tasks of deep learning: "splitting an image into regions to find specific features" _(your Master notes, §2.4)_.
- *Dice* measures how well your predicted mask overlaps the true mask. 1 is perfect, 0 is no overlap. Your notes give Dice loss as $1 - 2 Sigma y hat(y) slash (Sigma y + Sigma hat(y))$ _(Master, §1.9)_. So Dice itself is the overlap part.
- *Otsu mask*: a rough first guess made by a classical threshold, with no learning.
- *Iterative refinement*: predict a mask, feed it back in, predict again. Ten rounds.
- 0.842 is your honest reproduction number. 0.900 uses the same weights but a different start, so it is reported separately.
]
#ask(
  [Explain your project in one line.],
  [I built FANet from scratch, a CNN that feeds its own previous mask back as attention, and tested it on Kvasir-SEG polyps (0.842 Dice vs 0.880 in the paper) and on leaves I labelled in Roboflow.],
  [Why is 0.842 your main number and not 0.900?],
  [0.842 follows the paper's test protocol (start from Otsu). 0.900 changes the starting mask. That is my own variant, so I report it separately.],
)

== 1. Introduction
#says["Polyps found during a colonoscopy can be removed, but a meta-analysis of tandem colonoscopies reports that about one in four adenomas is missed [10], and each 1% increase in a doctor's adenoma detection rate lowers the later cancer risk by about 3% [9]. A model that outlines polyps pixel by pixel in the camera image can act as a second pair of eyes." \
Requirement table, for example: "Segmentation / detection, CNN: FANet outputs a 0/1 mask for every pixel; boxes around the predicted blobs give a detection view." "IEEE paper, last 5 years: IEEE TNNLS, vol. 34, no. 11, 2023 (online 2022)." "Paper's dataset: Kvasir-SEG, the paper's 880/120 split ratio."]
#plain[
- A *polyp* is a small growth on the colon wall. An *adenoma* is the kind that can turn into cancer. A *colonoscopy* is the camera test that finds them.
- The brief says "segmentation or detection, not classification". Your notes separate these tasks: classification gives one label, detection gives "a class and a box for every object" _(Ch5, §2)_. Segmentation goes further and labels every pixel.
- Your output is a mask. From the mask you also draw boxes, which is the "detection view" (report §6.1).
- The requirement table maps each line of the brief to where it is met.
]
#ask(
  [Why is this not classification?],
  [Classification gives one label per image. My network gives a 0/1 label for every pixel, a 256×256 mask.],
  [Is your paper within five years?],
  [Yes. IEEE TNNLS, vol. 34, no. 11, 2023, online 2022.],
  [What does "one in four" refer to?],
  [About one adenoma in four is missed in tandem colonoscopy studies (reference [10], Zhao et al.).],
)

== 2. Background
#says["*Semantic segmentation* assigns a class to every pixel. ... Most medical segmentation networks follow the *U-Net* shape [3]: an encoder that halves the resolution and doubles the channels at each stage, a decoder that upsamples back, and skip connections that copy encoder features to the decoder at the same scale so fine edges are not lost." \
"A *residual block* [4] adds a learned correction to its input, which keeps gradients flowing in deep networks. *Squeeze-and-excitation* [5] learns one weight per channel from globally pooled features (channel attention). *Hard attention* multiplies features by a 0/1 mask, so the next layer only sees the attended region." \
"*Otsu's method* [6] picks the grey-level threshold that best separates an image into dark and bright pixels."]
#plain[
- *Convolution*: a small learnable filter slides over the image and makes a feature map; each filter detects one kind of pattern _(your Ch4 notes, §2 and §3)_.
- *Pooling* shrinks height and width. Max pooling keeps the strongest value in each window _(Ch4, §3)_. This is how the encoder "halves the resolution".
- *Encoder and decoder*: your autoencoder notes describe the same two halves: the encoder compresses, the decoder reconstructs _(Master, §2.13)_. In U-Net the decoder rebuilds a *mask*, not the input image.
- *Skip connection*: your ResNet notes show a skip that *adds* the input to a block's output, $H(x) = f(x) + x$, so gradients have "a direct path back" _(Ch4, §8)_. U-Net's skips are similar but *concatenate* encoder features into the decoder. (U-Net itself is not in your notes.)
- *Residual block*: exactly the ResNet idea from your notes. When sizes differ, a 1×1 convolution projects the shortcut _(Ch4, §8)_. Your blocks do this.
- *Squeeze-and-excitation*, *hard attention* and *Otsu* are not in your notes. SE gives each channel a weight between 0 and 1. Hard attention multiplies by 0 or 1. Otsu picks the threshold that best splits dark from bright.
]
#where[`src/blocks.py:61-64` (residual block) and `:31-35` (squeeze-and-excitation):
```python
def forward(self, x):                        # ResidualBlock
    y = F.relu(self.bn1(self.conv1(x)))
    y = self.bn2(self.conv2(y))
    return F.relu(y + self.shortcut(x))      # shortcut = 1x1 conv + BN + SE

def forward(self, x):                        # SqueezeExcite
    b, c, _, _ = x.shape
    w = F.adaptive_avg_pool2d(x, 1).view(b, c)   # one number per channel
    w = self.fc(w).view(b, c, 1, 1)              # weights in (0, 1)
    return x * w
```]
#ask(
  [What is a skip connection for?],
  [Pooling loses fine detail. The skip brings the encoder's high-resolution features to the decoder, so edges stay sharp.],
  [How is your residual block related to ResNet?],
  [Same idea: output = ReLU(main path + shortcut). The shortcut uses a 1×1 conv because the channel counts differ.],
  [Max or average pooling, and why?],
  [Max pooling. It keeps the strongest response in each window, which keeps sharp features.],
)

== 3. The base paper: FANet
#says["FANet [1] adds a *feedback memory* to a U-Net-style network. For every training image the network keeps the mask it predicted in an earlier epoch and feeds it back in as a second input, where it acts as attention inside every encoder and decoder block. At test time the same idea becomes *iterative refinement*: the network's own output is fed back as the next input mask for several rounds. The paper reports Dice 0.880 on Kvasir-SEG, against 0.852 for the same network without its MixPool attention blocks."]
#plain[
- An *epoch* is one full pass over the training set _(Master, §1.3, step 6)_. A normal network forgets what it predicted for an image in the last epoch.
- FANet keeps that prediction in a *memory*: one 0/1 mask per image.
- The memory is a second input. It tells each block "look here".
- 0.852 is the paper's *ablation*: the same network with the MixPool blocks removed. An ablation removes one part to see what it adds. The paper claims about +0.03.
]
#where[`src/memory.py:60-68`: predictions are first staged, then committed.
```python
def stage(self, indices, probs):
    """Write this epoch's predictions to a staging copy (not yet used)."""
    if not self.feedback:
        return
    self.staged[indices.cpu()] = (probs.detach().cpu() > 0.5).to(torch.uint8)

def commit(self):
    """Make the staged predictions the new memory."""
    self.masks.copy_(self.staged)
```]
#ask(
  [What is FANet's one new idea?],
  [It remembers its last mask for each image and feeds it back as attention in every block. At test time it refines its mask over several rounds.],
  [Is feeding back your own prediction cheating?],
  [No. The ground truth is never an input. The memory only holds Otsu masks or the model's own predictions.],
)

=== 3.1 Architecture
#says["Each *encoder block* is two residual blocks (with squeeze-and-excitation), a MixPool block and 2×2 max pooling. Each *decoder block* upsamples by a transposed convolution, concatenates the skip features, and applies two residual blocks and a MixPool block. The last decoder output is concatenated with the previous mask and a 1×1 convolution gives one channel of logits. The model has 7,720,266 parameters." \
Figure caption: "The previous mask (red) enters every encoder (E) and decoder (D) block and is concatenated before the output layer. Dashed lines are skip connections."]
#plain[
- *Sizes*: your notes give $O = floor((I - K + 2P) slash S) + 1$, and "same padding, stride 1" keeps the size: $P = 1$ for a 3×3 kernel _(Ch4, §4)_. So every 3×3 conv keeps 256×256. Each 2×2 max pool halves it: 256 → 128 → 64 → 32 → 16.
- *Parameters*: your notes give $(k_w times k_h times C_"in" + 1) times C_"out"$ _(Ch4, §4)_. Your first conv (3 → 32 channels, 3×3) is $(3 dot 3 dot 3 + 1) times 32 = 896$. That is the same number as Conv1 in your notes' Q2.
- *Transposed convolution* (not in your notes): a learned upsampling layer. With kernel 4, stride 2, padding 1 it doubles the size.
- *1×1 convolution*: mixes channels at each pixel. Your GoogLeNet notes use it to "reduce channels" _(Ch4, §8)_. Here it turns 17 channels into 1.
- *Logit*: the raw number before the sigmoid. Sigmoid gives a probability in (0, 1) _(Master, §1.10)_. Above 0.5 = polyp.
- Channels: 32, 64, 128, 256 down; 128, 64, 32, 16 up.
]
#where[`src/model.py:35-38` (encoder), `:50-53` (decoder), `:88` (head):
```python
def forward(self, x, m):                       # EncoderBlock
    skip = self.r2(self.r1(x))                 # two residual blocks
    out = self.pool(self.mix(skip, m))         # MixPool, then 2x2 max pool
    return out, skip

def forward(self, x, skip, m):                 # DecoderBlock
    x = torch.cat([self.up(x), skip], dim=1)   # transposed conv up, concat skip
    x = self.r2(self.r1(x))
    return self.mix(x, m)

return self.head(torch.cat([d, prev_mask], dim=1))   # 16 + 1 channels -> 1x1 conv
```
Run `python -m src.model` to print the output shape and 7,720,266.]
#ask(
  [How many parameters, and where are most of them?],
  [7,720,266. Most sit at the bottom (E4 and D1), where there are 256 channels.],
  [What is the output for one image?],
  [1×256×256 logits. Sigmoid and a 0.5 threshold give the mask.],
  [Why does the size stay 256 after a 3×3 conv?],
  [Padding 1, stride 1: $(256 - 3 + 2)/1 + 1 = 256$.],
)

=== 3.2 MixPool: the feedback-attention block
#says["For features $x$ of size $C times h times w$ and the previous mask $M$: \
1. a small convolutional head predicts a mask $F$ from $x$, thresholded at 0.5; \
2. $M$ is max-pooled to $h times w$, so a cell is on if any pixel in it was on (small polyps survive); \
3. the attention map is $A = F or M$; \
4. the *masked half* $x dot A$ passes through conv–BN–ReLU to $C slash 2$ channels; \
5. the *plain half* $x$ passes through its own conv–BN–ReLU to $C slash 2$ channels; \
6. the two halves are concatenated. \
The plain half guarantees that a wrong previous mask cannot destroy the prediction; the network learns how much to trust each half."]
#plain[
- *Why max-pool the mask?* Your notes say max pooling answers "was the feature present anywhere here?" _(Ch4, §3)_. For a mask that means: if any pixel in the window was polyp, keep the cell as polyp. Small polyps are not lost.
- *Hard attention*: multiply by 0 or 1. Features outside the mask become 0 in the masked half.
- *OR*: a pixel is attended if either the fmask guess or the previous mask points at it.
- *Two halves*: one half looks only where the mask says. The other half sees everything. If the mask is wrong, nothing is lost.
- *BN* (batch normalization) normalizes each channel and has $2 times$ channels learnable values ($gamma$, $beta$) _(Ch4, §3 and §4)_.
]
#where[`src/blocks.py:109-116`:
```python
def forward(self, x, m):
    fmask = (self.fmask(x) > 0.5).float()                       # step 1
    kh, kw = m.shape[2] // x.shape[2], m.shape[3] // x.shape[3]
    m = F.max_pool2d(m, (kh, kw)) if kh > 1 or kw > 1 else m    # step 2
    attention = torch.logical_or(fmask > 0, m > 0.5).float()    # step 3
    masked = self.conv1(x * attention)                          # step 4
    plain = self.conv2(x)                                       # step 5
    return torch.cat([masked, plain], dim=1)                    # step 6
```]
#ask(
  [What happens if the previous mask is completely wrong?],
  [The plain half still sees every feature, so the prediction is not destroyed. The network learns how much to trust each half.],
  [Why not average-pool the mask?],
  [Averaging would fade a small polyp below 0.5 and lose it. Max keeps it.],
)

=== 3.3 Training with a feedback memory, and testing with refinement
#says["Before the first epoch the memory holds the Otsu mask of every training image. In each epoch, image $i$ is passed with `memory[i]`, the loss ($0.5 dot "BCE" + 0.5 dot "Dice"$) is minimised with Adam, and the thresholded prediction is staged. Only when the validation loss improves does the staged copy replace the memory, so the memory always comes from the best model so far. The ground truth is never an input." \
"At test time the memory starts from Otsu and the network is run ten times, each round feeding its thresholded output back in. Metrics are recorded after every round."]
#plain[
- *BCE* (binary cross-entropy) is your notes' loss for a binary probability output: $-(1/n) Sigma [y log hat(y) + (1-y) log(1 - hat(y))]$ _(Master, §1.9)_. It judges each pixel.
- *Dice loss* "measures overlap, and works well for imbalanced segmentation" _(Master, §1.9)_. Polyps are only 14% of an image, so this matters.
- Your notes' rule "Segmentation: Dice or Jaccard (IoU)" _(Master, §1.9)_ is why Dice is in the loss.
- *Adam* = momentum + RMSprop, "a safe default" _(Master, §1.11)_.
- *Validation loss*: the loss on images not used for training. The memory only updates when it improves, so a bad epoch cannot spoil the memory.
]
#where[`src/train.py:187-190` (commit rule) and `src/evaluate.py:95-108` (refinement):
```python
improved = val_loss < best
if improved or args.memory_update == "always":
    train_mem.commit()
    val_mem.commit()

for it in range(1, args.iters + 1):          # 10 rounds
    for image, target, idx in loader:
        prev = memory.get(idx, device)
        probs = torch.sigmoid(model(image, prev))
        memory.write(idx, probs)             # feed the prediction back
```
(Timing lines removed from the loop for clarity.) Loss: `src/losses.py:26-29`.]
#ask(
  [Why combine BCE and Dice?],
  [BCE gives smooth per-pixel gradients. Dice handles the imbalance (polyps are a small part of the image) and matches the metric.],
  [Why update the memory only when the validation loss improves?],
  [So the memory always comes from the best model so far. A bad epoch cannot poison the next input.],
)

== 4. Implementation
#says["Everything is written in PyTorch from basic layers (`Conv2d`, `BatchNorm2d`, `ConvTranspose2d`, pooling, `Linear`). No pretrained weights, no `torchvision.models`, no segmentation libraries. The authors' public code was read only to check details." \
"*Deviations from the official code.* Batch 8 instead of 2 and at most 200 epochs with early stopping (patience 40) instead of 500, to fit the available time; the memory is a tensor indexed by image instead of run-length strings; BCE is computed on logits for numerical stability. As in the authors' code, the Kvasir-SEG checkpoint is selected on the test images, which is slightly optimistic; we state this wherever the numbers appear."]
#plain[
- *From scratch* here means: you built the network from PyTorch's basic layers. You did not load a ready-made model or pretrained weights.
- *Batch*: images processed together in one update. *Early stopping* (not in your notes): stop when the validation loss has not improved for 40 epochs.
- *BCE on logits*: same value as sigmoid + BCE, but it avoids $log(0)$.
- *Checkpoint selected on the test images*: Kvasir has no separate validation split, so the 120 test images also choose the best epoch. The authors did the same. It makes the number slightly optimistic, and the report says so.
]
#where[`src/losses.py:26-29` and `src/train.py:147`:
```python
def forward(self, logits, target):
    # BCE on logits is numerically safer than sigmoid followed by BCE.
    bce = F.binary_cross_entropy_with_logits(logits, target)
    return self.bce_weight * bce + (1.0 - self.bce_weight) * dice_loss(logits, target)

val_split = "val" if os.path.exists(os.path.join(args.data, "val.txt")) else "test"
```]
#ask(
  [Is this really from scratch?],
  [Yes: every layer, the loss, metrics, Otsu, the box code, training and evaluation are my code on PyTorch primitives. No pretrained weights or model libraries. The design is the paper's; I read the authors' code only to check details.],
  [Did you use the test set as validation?],
  [For Kvasir, yes, exactly like the authors' code, so the numbers are comparable. It is slightly optimistic and I state it. My Roboflow runs use a real validation split.],
  [Did you use AI tools?],
  [Answer truthfully. For example: "I used AI assistance for parts of the code and documentation. I checked every part, ran every experiment, and can explain any line."],
)

== 5. Experimental setup
#says["*Dataset.* Kvasir-SEG [2]: 1000 colonoscopy images with polyp masks drawn by doctors. Split 880 train / 120 test with a fixed seed, the paper's ratio. Images resized to 256×256 (the size used in the authors' code; the paper's text uses 512×512, which we also run)." \
"*Training.* Adam, learning rate $10^(-4)$, ReduceLROnPlateau (factor 0.1, patience 5), batch 8, official augmentation. Hardware: RTX 5050 laptop GPU (8 GB); extra runs on Kaggle T4/P100. The final run stopped at epoch 147; the best checkpoint is from epoch 107." \
"*Metrics.* Per-image Dice, IoU (Jaccard), precision, recall and F2, averaged over the test images as in the authors' test script."]
#plain[
- *Learning rate* is the step size of each update. Too high overshoots, too low is slow _(Master, §1.4)_.
- *ReduceLROnPlateau* (not in your notes): if the validation loss has not improved for 5 epochs, divide the learning rate by 10.
- *Official augmentation*: random rotation up to ±35° and flips of the image and its mask. Your notes say augmentation "creates variations of the training images, which helps generalization" _(Master, §4.13, AlexNet)_.
- *IoU* = intersection ÷ union _(Ch5, §6)_. Your notes use it for boxes; here it is computed on pixels.
- *Per-image average*: compute the score for each test image, then take the mean. The mean IoU is called mIoU.
- *Kaggle*: free cloud GPUs, used for the extra runs.
]
#where[`src/train.py:166-168`:
```python
optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)
scheduler = (torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, "min", factor=0.1,
             patience=args.lr_patience) if args.lr_patience > 0 else None)
```
Split: `python -m src.split --data data/Kvasir-SEG` (seed 42, `src/split.py:36`).]
#ask(
  [How did you split Kvasir-SEG?],
  [880 train and 120 test with a fixed seed (42), the paper's ratio. My 120 images may not be the paper's 120.],
  [When did training stop?],
  [Epoch 147, because of early stopping. The best checkpoint is epoch 107.],
)

== 6. Results on Kvasir-SEG
#says[Table rows (Dice, mIoU, Recall, Precision, F2): \
"FANet, paper (512×512): 0.880, 0.815, 0.906, 0.901, 0.887" \
"Paper's baseline without MixPool: 0.852, 0.773, 0.884, 0.871, 0.861" \
"*Ours, paper's protocol* (Otsu start, round 10): *0.842*, *0.779*, 0.934, 0.835, 0.868" \
"Ours, Otsu start, round 1 only: 0.615, 0.512, 0.965, 0.530, 0.729" \
"*Ours, empty start* (round 10): *0.900*, *0.841*, 0.900, 0.935, 0.898" \
"Ours, no feedback (ablation): 0.883, 0.817, 0.897, 0.915, 0.886" \
"Ours, 512×512, 100 epochs: 0.831, 0.758, 0.917, 0.831, 0.860" \
"Our 256×256 model runs at about 87 images/s on the laptop GPU." \
"Under the paper's protocol our reproduction is 0.038 Dice below the paper. Training at the paper's 512×512 does not close the gap (0.831), so input size is not the cause." \
"*Refinement.* Otsu marks about 60% of a colonoscopy image (bright wall and glare) while polyps cover 14%, so the first round is far too large and each round trims it."]
#plain[
- *Precision* = TP ÷ (TP + FP): of what you marked, how much was right. *Recall* = TP ÷ (TP + FN): of what was really there, how much you found _(Ch4, §6)_.
- Your notes' cancer example says on imbalanced medical data "report recall (and F1), not accuracy", because a miss is worse than a false alarm _(Ch4, §6)_. Your recall is high (0.934).
- *F1* is the harmonic mean of precision and recall _(Ch4, §6)_. For masks, F1 equals Dice. *F2* is like F1 but weights recall more.
- Round 1 from Otsu has recall 0.965 but precision 0.530: the mask is far too big. Each round trims it, so precision rises.
- The 512 run is no better, so image size is not why you are below the paper.
]
#image("figures/refinement_rounds.png", width: 62%)
#where[`src/evaluate.py:82-84` (the empty start) and `src/metrics.py:38-39` (Dice and IoU per image):
```python
if args.start == "zeros":
    memory.masks.zero_()
    memory.staged.zero_()

"dice": (2 * tp + EPS) / (2 * tp + fp + fn + EPS),
"jaccard": (tp + EPS) / (tp + fp + fn + EPS),
```]
#ask(
  [Why is your Dice lower than the paper's?],
  [Not resolution: my 512 run gives 0.831. Likely reasons are batch 8 instead of 2, a different random test split, and single runs.],
  [Why is round 1 so low?],
  [Otsu marks about 60% of the image, so the first mask is far too big. Each round trims it: 0.615 to 0.842.],
  [Why not report accuracy?],
  [Polyps are about 14% of the pixels. Predicting all background already gives high accuracy but Dice 0. My notes make the same point for imbalanced medical data.],
)

=== 6.1 Detection view
#says["Bounding boxes are drawn around each connected blob of the predicted mask and matched to the ground-truth boxes at IoU ≥ 0.5. Under the paper's protocol, box precision is 0.685 and box recall 0.800 (mean matched IoU 0.881); from an empty start, 0.836 and 0.896."]
#plain[
- Your notes: detection gives "a class and a box for every object" _(Ch5, §2)_.
- A *connected blob* is a group of touching mask pixels. Each blob gets one box.
- *IoU* = area of intersection ÷ area of union, and "a common rule is IoU ≥ 0.5 for a correct detection" _(Ch5, §6)_. You use exactly that rule.
- TP, FP and FN for boxes follow your notes: TP = a box matched at IoU ≥ threshold; FP = an unmatched box; FN = a missed object _(Ch5, §7)_.
- You do not report mAP. Your notes compute AP by ranking boxes by confidence _(Ch5, §7)_, and your boxes have no confidence score.
]
#where[`src/metrics.py:91-99` (one box per blob) and `:129-134` (matching):
```python
def mask_to_boxes(mask, min_area=20):
    labels, count = connected_components(mask)      # BFS over 8 neighbours
    boxes = []
    for k in range(1, count + 1):
        ys, xs = np.nonzero(labels == k)
        if len(ys) >= min_area:
            boxes.append((int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())))
    return boxes
```]
#ask(
  [Is this really detection?],
  [It is segmentation with a detection view: one box per blob, matched at IoU ≥ 0.5. There is no detector head and no confidence score, so no mAP.],
  [What does box recall 0.800 mean?],
  [80% of the true polyp boxes were found at IoU ≥ 0.5.],
)

=== 6.2 Findings beyond the paper
#says["*The feedback adds little in our reproduction.* With the memory fixed at zeros (no feedback), the same network reaches 0.883: above our FANet under the paper's protocol and 0.017 below our best setting. The paper reports a larger gain (0.852 → 0.880) than we could reproduce." \
"*The unaligned memory acts as a regulariser.* The official code rotates and flips each image but not its memory mask, so for about two-thirds of training samples the memory points at the wrong place. Our first run "fixed" this by moving the memory with the image. That model learned to copy its memory: probed with one pass from different starting masks, it scored 0.517 from an empty mask and 0.383 from an all-ones mask, while the model trained the official way scored 0.828 and 0.518." \
"*Part of MixPool never trains.* The fmask head is thresholded with a step function, which has zero gradient, so 982,088 parameters (about 13% of the model) keep their random initial values."]
#plain[
- *Ablation*: switch one part off and compare. Here the memory is always zeros.
- *Regulariser*: something that stops the model from taking a shortcut. Your notes define overfitting as "low training error, high test error" _(Ch4, §8)_. The aligned model took a shortcut: it copied its hint.
- "Two-thirds": each sample is rotated, flipped horizontally or flipped vertically with probability 0.3 each. It stays untouched only with probability $0.7^3 approx 0.34$.
- *Why the fmask never learns*: backprop multiplies derivatives along the chain _(Master, §1.6)_. Your Ch4 notes show the ReLU gradient is 0 for inputs ≤ 0, and a 0 there stops the update _(Ch4, §9)_. A "> 0.5" step has gradient 0 everywhere, so no gradient reaches the fmask convs.
]
#where[`src/train.py:79-82` (memory not moved) and `src/blocks.py:110` (the step):
```python
elif aug == "official":
    # The memory mask is NOT moved, and the prediction is stored as made.
    image, target = augment.official_geometric(image, target)
    image = augment.photometric(image, p_jitter=0.0)

fmask = (self.fmask(x) > 0.5).float()      # no gradient flows through "> 0.5"
```
Memory probe: `python -m src.memory_probe --ckpt runs/kvasir_official/best.pt --data data/Kvasir-SEG`.]
#ask(
  [What happens if you remove the feedback?],
  [0.883, above FANet from Otsu (0.842) and only 0.017 below the empty start (0.900). In my runs the feedback adds little.],
  [How do you know 13% never trains?],
  [After a backward pass, 48 parameter tensors (982,088 values, all in the fmask heads) have no gradient. The notebook prints it.],
  [How would you fix it?],
  [Use a soft (sigmoid) gate, or a straight-through estimator, so gradient can flow.],
)

== 7. Own dataset in Roboflow
=== 7.1 Motivation and source photos
#says["Colonoscopy images cannot be collected by a student, so we kept the *task* (segmenting irregular spots on a textured surface) and changed the *domain* to disease spots on leaves. Taking our own photos of diseased leaves was not possible, so the photos come from the public LDSD leaf-disease set [12] (CC0, real photos from PlantDoc [11]). LDSD was split 470 / 118; the 118 photos are the leaf test set. From the 470 we picked 30 photos with a seeded script (at least 300 px, disease covering 3–50% of the image) and uploaded them to Roboflow *without* their masks."]
#plain[
- *Domain*: the kind of images. Same task (find spots), new domain (leaves instead of colon walls).
- *CC0*: public domain. Anyone may use the photos.
- The photos are not yours. The *labels* are yours: you drew them by hand.
- The 30 photos come from the 470 *training* pool, so none of them is in the 118 test photos.
]
#ask(
  [Did you take the leaf photos yourself?],
  [No. They are public CC0 photos from LDSD. I uploaded them without masks and drew every label myself in Roboflow.],
  [Why leaves?],
  [I cannot collect colonoscopy images. Leaf spots are the same kind of task, and they test whether the model transfers.],
)

=== 7.2 Building the dataset in Roboflow
#says["*Project:* type Semantic Segmentation (an Object Detection project would store only boxes, while FANet learns from pixel masks), one disease class." \
"*Labelling by hand:* every disease spot on all 30 photos outlined with the Smart Polygon (SAM-assisted) and Polygon tools, about two hours in total." \
"*Version v1:* split 24 train / 6 valid / 0 test; Auto-Orient; resize (stretch) to 256×256; augmentation on the training photos only: horizontal and vertical flips, 90° rotations (clockwise, counter-clockwise, upside down), rotation ±15°, brightness ±15%, five outputs per photo. Total 126 images (120 train, 6 valid)." \
"*Export:* Semantic Segmentation Masks format, converted by `src/roboflow_to_masks.py` into our image/mask layout with Roboflow's split preserved."]
#plain[
- *Semantic Segmentation project*: stores a mask per image. A detection project stores only boxes _(boxes vs masks: Ch5, §2)_.
- *Augmentation* makes new versions of training photos. Only the 24 training photos are augmented, so the 6 validation photos stay real.
- 24 photos × 5 = 120, plus 6 = 126.
- The export stores class numbers in each mask pixel (0 = background, 1 = disease). Your converter turns every non-zero value into foreground.
]
#where[`src/roboflow_to_masks.py:57-60`:
```python
mask = np.asarray(Image.open(mpath))
if mask.ndim == 3:
    mask = mask.max(axis=2)
yield img, (mask > 0).astype(np.uint8)       # any class number > 0 = disease
```]
#ask(
  [Why no test split in Roboflow?],
  [My test set is LDSD's 118 photos, never used in training and scored with LDSD's own masks.],
  [Why augment only the training photos?],
  [So validation measures real, unchanged photos.],
)

=== 7.3 Quality of the hand labels
#says["LDSD's own masks for the same 30 photos give an independent check. Mean Dice between our labels and LDSD's is *0.730* (median 0.781, range 0.09–0.96). The largest disagreements are differences of definition rather than careless labels: on one photo LDSD marks a whole yellowed leaf as diseased where we marked only the spots." \
Figure caption: "Our label (pink) and LDSD's (blue). Top: close agreement (Dice 0.96). Bottom: a definition difference (Dice 0.09)."]
#plain[
- You compare your mask with LDSD's mask for the same photo, using Dice.
- 0.730 on average. The median (the middle value) is 0.781.
- The worst photo (0.09) is not a careless label. LDSD and you define "diseased" differently.
]
#where[`src/roboflow_to_masks.py:85-87` (used with `--compare`, results in `agreement.csv`):
```python
def dice(a, b):
    a, b = a.astype(bool), b.astype(bool)
    return (2 * (a & b).sum() + 1e-9) / (a.sum() + b.sum() + 1e-9)
```]
#ask(
  [How do you know your labels are good?],
  [LDSD has its own masks for the same 30 photos. My labels agree at mean Dice 0.730. The big misses are definition differences.],
)

=== 7.4 Results on real leaves
#says["All models are tested on the same 118 LDSD photos with LDSD's masks, ten refinement rounds." \
Rows (Dice, Otsu start / empty start): "Polyp model, no fine-tuning: 0.010 / 0.004" · "*Our Roboflow set (24 photos ×5), from the polyp weights*: *0.517* / *0.520*" · "*Our Roboflow set, from random weights*: 0.467 / 0.461" · "Our Roboflow set, default lr schedule (fine-tuned / scratch): 0.472 / 0.434, 0.465 / 0.419" · "470 LDSD photos, from the polyp weights: 0.670 / 0.681" · "470 LDSD photos, from random weights: 0.678 / 0.667" \
"With only 24 labelled photos, starting from the polyp weights helps (0.517 against 0.467), while with 470 photos it made no difference. Twenty times less data costs about 0.16 Dice." \
"*Learning-rate schedule.* The Roboflow models are trained for 100 epochs at a constant learning rate. With the default schedule ..., the 6 noisy validation photos cut the rate to almost zero within 30 epochs and both models scored about 0.04 lower (last row). This choice was fixed before looking at the test scores."]
#plain[
- *Transfer learning / fine-tuning* (only touched in your notes, which call VGG "popular for transfer learning", Ch4, §7): start from weights trained on one task, then keep training on a new one.
- *Domain gap*: the polyp model, unchanged, finds almost nothing on leaves (0.010).
- With little data (24 photos), starting from polyp weights helps: 0.517 vs 0.467. With lots of data (470), it does not matter.
- *Constant learning rate*: with only 6 validation photos the validation loss jumps around, so the usual "cut on plateau" rule fired too early. Your notes: a learning rate that is too low makes training slow _(Master, §1.4)_.
]
#where[`src/train.py:159-161` (start from the polyp weights) and the command used:
```python
if args.init:
    state = torch.load(args.init, map_location=device)
    model.load_state_dict(state["model"])
```
```bash
python -m src.train --data dataset/custom/roboflow_leaf --out runs/roboflow_leaf_constlr \
    --init runs/kvasir_official/best.pt --epochs 100 --early-stop 0 --lr-patience 0 --lr 5e-5 --amp
```]
#ask(
  [What is your leaf result?],
  [0.517 on 118 LDSD photos when fine-tuned from the polyp weights, 0.467 from random weights.],
  [Why is 0.517 lower than polyps?],
  [Leaves are harder (many small spots, busy backgrounds), I had only 24 photos, and the test masks are LDSD's while my labels agree with them at 0.730.],
  [Why a constant learning rate?],
  [Six validation photos give a noisy loss, so the plateau rule cut the rate too early. I fixed this rule before seeing test scores.],
)

== 8. Limitations
#says["Each setting was trained once; differences of 0.01–0.02 Dice are within run-to-run noise." · "The Kvasir-SEG checkpoint was selected on the test images, as in the authors' code (slightly optimistic). The Roboflow models were selected on only 6 validation photos." · "Only one of the paper's seven datasets was used, and our 120 test images may differ from the paper's." · "The own dataset is small (30 photos) and its photos are public, not collected by us; only the labels are our own." · "Research and coursework only; not validated for clinical use."]
#plain[
- *Run-to-run noise*: training twice with different random starts gives slightly different scores. With one run each, a 0.01 to 0.02 difference is not proof.
- Every limitation here is also an honest answer to a trap question. Use them.
]
#ask(
  [What would you improve with more time?],
  [Repeat runs with different seeds, use a separate validation split for Kvasir, and label more leaf photos.],
  [Is the +0.017 of feedback real?],
  [It is within run-to-run noise, so I cannot claim a clear gain.],
)

== 9. Conclusion and future work
#says["FANet was implemented from scratch and reproduced on Kvasir-SEG: Dice 0.842 under the paper's protocol (paper 0.880) and 0.900 with an empty starting mask. The experiments show that resolution does not explain the gap, that the feedback memory contributes less than reported, that the official unaligned memory works as a regulariser, and that 13% of the parameters never train." \
"Future work: more hand-labelled leaf photos, a trainable soft gate for the fmask head, repeated runs with different seeds, and video, where the previous frame's mask is a natural feedback input."]
#plain[
- Four findings: resolution is not the gap; feedback adds less than claimed; the unaligned memory helps; 13% never trains.
- *Video*: in a colonoscopy video, the mask from the previous frame is a natural "previous mask" for FANet.
]
#ask(
  [Summarise your conclusion in one sentence.],
  [I reproduced FANet within 0.04 Dice, found that its feedback adds less than claimed, and transferred it to my own Roboflow leaf dataset.],
)

== 10. Deliverables
#says["Presentation (20 slides): `01_Presentation/` (PPTX and PDF)" · "Notebook, executed with outputs: `02_Notebook/FANet_project.ipynb` (and an HTML copy)" · "Roboflow dataset: `03_Roboflow_Dataset/`: exported zip, 11 screenshots of each step, label agreement CSV; public link above" · "This report: `04_Report/`" · "Source code and result tables: `05_Code/`" · "Trained weights: published separately (link in the package README)"]
#plain[
- The Roboflow dataset is public at `universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne`.
- The weights are on Hugging Face: `huggingface.co/Ckorion/fanet-polyp-leaf-from-scratch`.
- `05_Code/results/` holds every CSV behind the numbers.
]
#ask(
  [Can you show me where a number comes from?],
  [Yes. For example, 0.842 is round 10 of `runs/kvasir_official/eval_test/results.csv`.],
)

== References
#says[13 entries. [1] FANet (Tomar et al., IEEE TNNLS 2023) · [2] Kvasir-SEG · [3] U-Net · [4] ResNet · [5] Squeeze-and-Excitation · [6] Otsu · [7] Adam · [8] Batch Normalization · [9] Corley et al., NEJM 2014 · [10] Zhao et al., Gastroenterology 2019 · [11] PlantDoc · [12] LDSD (Kaggle, CC0) · [13] Roboflow documentation.]
#ask(
  [Which reference gives the "3%" figure?],
  [[9], Corley et al., NEJM 2014: each 1% rise in adenoma detection rate lowers later cancer risk by about 3%.],
  [Which gives the "one in four" miss rate?],
  [[10], Zhao et al., Gastroenterology 2019.],
)

// =====================================================================
= Part B: your slides, one by one

#let secbar(name, range) = block(width: 100%, fill: rgb("#0e3b43"), inset: (x: 9pt, y: 5pt), radius: 2pt, above: 1em, below: 0.6em, breakable: false, sticky: true,
  text(font: "Inter", size: 9pt, weight: "bold", fill: white)[#upper(name) #h(1fr) #range])

The deck has *20 slides* in the five sections of ma'am's PPT brief (17 Nov): *Problem Statement, Proposed System, Dataset Used, Result Analysis, Future Scope*, then the Conclusion. The section name is printed in small capitals at the top of each slide. For theory, each slide points back to the matching Part A unit.

#table(columns: (auto, auto, 1fr),
  [Section], [Slides], [What you are showing],
  [Title], [1], [Task, method, your name],
  [Problem Statement], [2–4], [Outline; why missed polyps matter; why pixel-level segmentation],
  [Proposed System], [5–9], [FANet's idea, architecture, MixPool, the feedback loop, your from-scratch code],
  [Dataset Used], [10–14], [Kvasir-SEG setup; your Roboflow leaf dataset (3 slides); the 4-class tomato detection set (1 slide)],
  [Result Analysis], [14–17], [Kvasir results, refinement, the aligned-memory finding, leaf results],
  [Future Scope], [18], [Next steps, each tied to a limit you found],
  [Conclusion], [19], [Works, limits, next],
)
#note[If you rehearsed from an older copy: the Roboflow slides now come *before* the results (11–13), and slides 2 (Outline) and 19 (Future scope) are new.]

== Slide 1: Polyp Segmentation with FANet
#thumb(1)
#slidesays["Polyp Segmentation with FANet" · "Feedback Attention Network (IEEE TNNLS 2023), implemented from scratch on Kvasir-SEG, with transfer to plant disease spotting" · "Chaitanya Shinde · 231070066"]
#plain[The title says three things: the task (polyp segmentation), the method (FANet, built from scratch) and the extra (transfer to leaves). The picture is a Kvasir image with its mask.]
#ask([Say your opening line.], [Good morning ma'am. My project is polyp segmentation with FANet, an IEEE TNNLS 2023 paper. I built it from scratch, trained it on Kvasir-SEG, and transferred it to leaf spots with my own Roboflow dataset.])

#secbar("Problem Statement", "slides 2–4")

== Slide 2: Outline
#thumb(2)
#slidesays["1 Problem Statement: Missed polyps in colonoscopy; why pixel-level segmentation" · "2 Proposed System: FANet: a U-Net that feeds its previous mask back in; built from scratch in PyTorch" · "3 Dataset Used: Kvasir-SEG (the paper's dataset) and my own leaf-disease dataset labelled in Roboflow" · "4 Result Analysis: Dice vs the paper, refinement rounds, ablation, transfer to real leaves" · "5 Future Scope: More own data, the paper's full protocol, video, multi-class"]
#plain[
- This slide is the map of your talk. The five parts are the headings ma'am's PPT brief asked for, in her order.
- Say it in about 15 seconds: one line per part, then move on. Do not explain FANet here.
]
#ask([Why is the dataset section separate from the results?], [The brief asks for "Dataset Used" before "Result Analysis". So I first show what the model is trained and tested on (Kvasir-SEG and my Roboflow leaves), then all the numbers together.])

== Slide 3: One in four adenomas is missed during colonoscopy
#thumb(3)
#slidesays["26%: adenoma miss rate in tandem colonoscopy (meta-analysis, Zhao et al., Gastroenterology 2019)" · "−3%: risk of later colorectal cancer for every +1% in a doctor's adenoma detection rate (Corley et al., NEJM 2014)" · "Hard cases: flat polyps that blend into the wall, glare, bubbles, motion blur" · "Role: a second pair of eyes for the doctor. Decision support, not diagnosis"]
#plain[
- *Tandem colonoscopy*: two colonoscopies on the same patient. The second finds what the first missed.
- Finding more adenomas lowers cancer risk. So a model that highlights polyps can help.
- "Decision support, not diagnosis": the doctor decides, the model only points.
]
#ask([Would you use this in a hospital?], [No. It is a proof of concept for decision support, not validated for clinical use (report §8).])

== Slide 4: Segmentation labels every pixel, not the whole image
#thumb(4)
#slidesays["Classification: One label per image: "polyp present". Not allowed by the brief" · "Detection: A box around each object. We derive boxes from the mask (connected blobs)" · "Segmentation: A 0/1 label for every pixel. FANet's output: a 256×256 mask" · "Polyps cover 14% of a test image on average, so the classes are imbalanced"]
#plain[
- Three tasks, as in your notes _(Ch5, §2)_: one label; a box per object; and (beyond your notes) a label per pixel.
- *Imbalanced*: far more background pixels than polyp pixels. That is why you use Dice, not accuracy (Part A, §6).
]
#ask([Why does imbalance matter?], [An all-background mask would already get high accuracy but Dice 0. So I use Dice and a Dice term in the loss.])

#secbar("Proposed System", "slides 5–9")

== Slide 5: FANet remembers its last prediction for every image
#thumb(5)
#slidesays["Evaluated on 7 biomedical datasets; this project reproduces Kvasir-SEG" · "1. Mask memory across epochs: For each training image, keep the mask the network predicted for it last time" · "2. Hard attention at every stage: A MixPool block in every encoder and decoder stage uses that mask as a "look here" gate" · "3. Refinement at test time: Predict, feed the prediction back, predict again: up to 10 rounds"]
#plain[The three ideas are explained in Part A, §3 (memory), §3.2 (MixPool) and §3.3 (refinement). Memory = one stored mask per image. Gate = multiply by 0 or 1. Refinement = repeat with the last mask.]
#ask([What does FANet add to a U-Net?], [A memory of the last mask, MixPool attention that uses it in every block, and refinement at test time.])

== Slide 6: Architecture: a U-Net that also takes the previous mask
#thumb(6)
#slidesays["Encoder: Residual ×2 → MixPool → MaxPool" · "Decoder: TransposedConv ↑2 → concat skip → Residual ×2 → MixPool" · "Residual: two 3×3 conv + BN, 1×1 shortcut with squeeze-and-excitation" · "Output: previous mask concatenated, then 1×1 conv" · "7,720,266 parameters"]
#plain[
- The boxes show the skip size of each stage: 32 ch at 256², 64 at 128², 128 at 64², 256 at 32².
- Output size rule and parameter rule come from your notes _(Ch4, §4)_. Details in Part A, §3.1.
]
#where[`src/model.py:56-88` (FANet), `src/blocks.py:38-64` (residual block).]
#ask([Why the 1×1 shortcut?], [The input and output channel counts differ, and you can only add tensors of the same shape. Your ResNet notes call this a 1×1 projection (Ch4, §8).])

== Slide 7: MixPool: the previous mask decides where to look
#thumb(7)
#slidesays["Why two halves? If the mask is wrong, the unmasked half still carries every feature, so a bad mask cannot erase the polyp." · "Found in the code: the > 0.5 threshold has no gradient, so the fmask convs (982,088 parameters, 13%) never train."]
#plain[The six steps are in Part A, §3.2. The gradient finding is in §6.2: a step function passes no gradient back, so those convs keep their random weights.]
#where[`src/blocks.py:109-116`; the step is line `:110`.]
#ask([Why does a threshold stop learning?], [Backprop multiplies derivatives along the chain. The derivative of a step is 0, so nothing reaches the fmask convs.])

== Slide 8: Each image's last prediction is fed back as its next input
#thumb(8)
#slidesays["1 Start: Before epoch 1, every image's memory is an Otsu threshold of the blurred grey image" · "2 Predict: pred = FANet(image, memory[i]); loss = 0.5·BCE + 0.5·Dice; Adam step" · "3 Stage: Store pred > 0.5 for image i in a staging copy" · "4 Commit: If test loss improved: save the checkpoint and memory ← staging" · "Augmentation (as in the authors' code): rotate ±35°, flips, cut-out holes on image and ground truth; the memory is not moved." · "Otsu marks 60% of each image on average; polyps cover 14%"]
#plain[
- The four steps are the training loop of Part A, §3.3.
- "Test loss" is said honestly: for Kvasir, the validation set is the test set (Part A, §4).
- Otsu marks far more than the polyp, so it is a poor start. That is why round 1 is low.
]
#where[`src/memory.py:31-36` (Otsu), `:60-68` (stage, commit), `src/train.py:187-190` (commit rule).]
#ask([What does Otsu do?], [It picks the grey level that best splits dark from bright pixels and marks the bright ones. No learning.])

== Slide 9: Every layer, loss and metric is written from scratch
#thumb(9)
#slidesays[File table: "blocks.py: Squeeze-excite, residual block, MixPool" · "model.py: Encoder / decoder blocks, FANet" · "memory.py: Mask memory, Otsu threshold" · "augment.py: Rotation, flips, cut-out (torch only)" · "losses.py: 0.5·BCE + 0.5·Dice" · "metrics.py: Dice, IoU, precision, recall, F2; boxes from blobs (BFS)" · "train.py: Feedback training loop, checkpoints, log" · "evaluate.py: Test-time refinement, strips, FPS" · "memory_probe.py: How much the model relies on its memory" \
"Not used: pretrained weights, torchvision.models, segmentation_models_pytorch, the authors' repository (read only to check details)"]
#plain[
- Know one file for each job. The code map is on the cheat sheet (Part D).
- *BFS* (breadth-first search) finds connected blobs for the boxes.
]
#ask([Where is MixPool?], [`src/blocks.py`, class `MixPool`, lines 109 to 116.], [Where is the refinement loop?], [`src/evaluate.py`, lines 95 to 120.])

#secbar("Dataset Used", "slides 10–14")

== Slide 10: Setup: Kvasir-SEG with the paper's 880 / 120 split
#thumb(10)
#slidesays["1000 colonoscopy images with polyp masks drawn by a doctor and verified by a gastroenterologist (Vestre Viken, Norway)" · "880 train / 120 test, fixed seed 42; the paper's split ratio (Table I)" · "Resized to 256×256 (512×512 run on Kaggle)" \
Table (Paper | Authors' code | This project): Input "512×512" | "256×256" | "256×256 (laptop) · 512×512 (Kaggle)" · Batch / epochs "100 epochs" | "2 / 500" | "8 / ≤200, early stop 40 · 512: 4 / 100" · Optimiser "Adam 1e-4" | "Adam 1e-4, plateau ×0.1" | "same" · Test "refinement" | "10 rounds from Otsu" | "same" · Hardware (this project) "RTX 5050 8 GB · Kaggle T4 / P100"]
#plain[The three columns are paper, authors' code and your project. The paper's text says 512 and 100 epochs; the authors' code uses 256, batch 2 and up to 500 epochs. You follow the code at 256 and the paper at 512.]
#ask([Why batch 8 and not 2?], [To use the GPU better and finish in time. It is one possible reason for the small gap to the paper.])

== Slide 11: Own dataset: 30 leaf photos, hand-labelled in Roboflow
#thumb(11)
#slidesays["Task kept, domain changed: irregular spots on a textured surface, but leaf disease instead of polyps (colonoscopy images cannot be collected by a student)" · "Photos: 30 real diseased-leaf photos from the public LDSD set (CC0); taking our own was not possible" · "Labels: every disease spot outlined by me in Roboflow (Smart Polygon + Polygon), about 2 hours" · "Project type: Semantic Segmentation, one class, so the export is a pixel mask, not boxes"]
#plain[Same story as report §7.1 and §7.2. Say clearly: the photos are public, the labels are yours.]
#ask([Did you take the photos?], [No. Public CC0 photos from LDSD. I drew every label myself.])

== Slide 12: Roboflow, step by step (my screenshots)
#thumb(12)
#slidesays["1. Label by hand: Smart Polygon + Polygon; each layer on the left is one spot I outlined (leaf_00097)" · "2. 30 jobs: one labelling job per photo, about 2 hours" · "3. Resize: stretch to 256×256, the training size" · "4. Augment: 90° turns shown; also flips, ±15° tilt, ±15% brightness" · "Then: split 24 / 6 / 0, generate version v1 (126 images), export as Semantic Segmentation Masks, convert with src/roboflow_to_masks.py."]
#plain[Four screenshots that prove you built the dataset. *Smart Polygon* is Roboflow's AI-assisted outline tool (it uses SAM, a segmentation model); you adjust its outline by hand.]
#where[`src/roboflow_to_masks.py:48-60` (reads `NAME_mask.png`).]
#ask([How long did labelling take?], [About 2 hours for all 30 photos.])

== Slide 13: Roboflow version v1: split, resize, 5× augmentation
#thumb(13)
#slidesays["126 images = 24 train photos × 5 + 6 validation photos" · "24 / 6 / 0 split: the test set is LDSD's own 118 photos, never seen in training" · "256×256 stretch: the size the model is trained at; image and mask stretch together" · "Flips, 90° turns, ±15° tilt: a leaf has no natural 'up'" · "±15% brightness: photos taken in different light" · "5× only on train; validation stays real" · "Offline vs online augmentation: Roboflow's copies are fixed files (offline); our training code also flips and rotates differently in every epoch (online)."]
#plain[
- *Offline augmentation*: copies made once and saved. *Online augmentation*: new random changes every epoch during training.
- Your notes list augmentation as a way to help generalization _(Master, §4.13)_.
]
#ask([Does stretching distort the image?], [Yes, the shape changes, but image and mask stretch together, so the labels stay aligned.])

== Slide 14: Roboflow detection dataset: 220 tomato leaves, 4 classes
#thumb(14)
#slidesays["220 photos from PlantVillage (Hughes & Salathé, 2015), 4 classes: bacterial_spot: 55 · early_blight: 55 · healthy: 55 · late_blight: 55" · "Object Detection project in Roboflow: I drew all 233 boxes by hand (whole leaf; on late blight, the blighted regions)" · "Separate from FANet: it meets the lab's dataset rule (≥ 200 annotated images, ≥ 4 classes)" · "Split 176 train / 22 valid / 22 test photos" · "Auto-Orient, resize 640×640; flips, ±15° rotation, ±15% brightness, 3× on train → 572 images" · "Exported in YOLOv8 format"]
#plain[
- *Why it exists:* the lab rule asks for a Roboflow dataset with at least 200 annotated images and at least 4 classes. FANet is binary (polyp or not), so this set is separate; FANet stays the main project.
- *Detection, not segmentation:* a box + a class per object. The class of each photo comes from PlantVillage's expert-labelled folders; I localised each leaf with a box.
- *The four classes:* bacterial spot (many tiny dark specks), early blight (brown spots with target-like rings), late blight (large irregular greasy dark patches), healthy. "Early" and "late" name two different pathogens, not stages.
- *572 = 176 × 3 + 22 + 22:* augmentation only multiplies the training photos; validation and test stay real.
- *YOLOv8 format:* one `.txt` per image, one line per box: class id, box centre x, centre y, width, height, all scaled to 0–1.
- Public on Roboflow Universe: `universe.roboflow.com/chaitanyadl/tomato-leaf-disease-det`.
]
#ask([Why are some late-blight boxes smaller than the leaf?], [For late blight I boxed the blighted regions, where the class is visible; for the other classes the whole leaf. A next version would make this one rule for all classes.],
  [Did you train a model on it?], [Not yet: it is listed under future scope (train a detector such as YOLO). The brief asked for the annotated dataset.],
  [How many annotated images, really?], [220 hand-annotated photos (55 per class). The 572 includes augmented copies, which are not new annotations.])

#secbar("Result Analysis", "slides 15–18")

== Slide 15: Results on the 120 Kvasir-SEG test images
#thumb(15)
#slidesays[Rows (Dice, mIoU, Recall, Precision, F2): "FANet, paper: 0.880, 0.815, 0.906, 0.900, 0.887" · "FANet, ours, official protocol: 0.842, 0.779, 0.934, 0.835, 0.868" · "FANet, ours, round 1: 0.615, 0.512, 0.965, 0.530, 0.729" · "FANet, ours, empty start: 0.900, 0.841, 0.900, 0.935, 0.898" · "FANet, ours, 512×512: 0.831, 0.758, 0.917, 0.831, 0.860" · "No feedback (ablation): 0.883, 0.817, 0.897, 0.915, 0.886" · "Aligned memory (our first run): 0.684, 0.589, 0.958, 0.619, 0.775" \
"Ablation: without feedback the same network scores 0.883, above FANet from Otsu (0.842); the memory helps only from an empty start (+0.017)." \
"Detection view: boxes around the predicted blobs find 80% of the true polyp boxes at IoU ≥ 0.5 (box precision 0.685, official protocol)."]
#plain[Same table as report §6, plus the aligned-memory row (your first run, see slide 17). Read it top to bottom: paper, yours, round 1, empty start, 512, ablation, first attempt. The paper's precision is rounded differently in the report (see Part C, item 1).]
#ask([Which row is the most important?], [The ablation. Without feedback the network gets 0.883, so in my runs the memory adds little.])

== Slide 16: Refinement: an empty start climbs higher than Otsu
#thumb(16)
#slidesays["From Otsu (marks ~60% of the image): 0.615 → 0.842; each round trims the oversized guess" · "From an empty mask: 0.829 → 0.900, above the paper's 0.880, same weights" · "Strips: image | truth | Otsu | round 1 | round 2 | round 10 (Otsu start)"]
#plain[The chart shows Dice per round for both starts, with the paper's line for reference. An empty start does not over-mark, so it starts higher and ends higher.]
#where[`src/evaluate.py:95-120`; empty start with `--start zeros` (`:82-84`).]
#ask([Why is the empty start better?], [Otsu marks about 60% of the image, so the first mask is too big. An empty mask avoids that, and the model was trained to check its memory against the image.])

== Slide 17: Finding: an aligned memory teaches the model to copy it
#thumb(17)
#slidesays["Our first run rotated the memory together with the image, which looked like a fix to the authors' code" · "Its predictions followed the hint: given nothing, recall fell to 0.41; given everything, precision fell to 0.27" · "In the authors' code about 2/3 of training samples are rotated or flipped while their memory is not, so the model must check the memory against the image" · "With it, an empty start works (0.83 vs 0.52), but an over-full start (all ones, Otsu) still pulls the first pass"]
#plain[
- The bar chart is the *memory probe*: one pass from five starting masks.
- A model that copies its hint swings with it. A model that checks the hint stays steady.
- The authors' "bug" (memory not rotated) is really a regulariser (Part A, §6.2).
]
#where[`src/memory_probe.py:49-59` (the five starts); `src/train.py:79-82` (memory not moved).]
#ask([What was your most interesting finding?], [Aligning the memory made the model copy it. The authors' misalignment forces the model to check the memory, so it works as a regulariser.])

== Slide 18: Real leaves: my labels and the transferred model
#thumb(18)
#slidesays["0.73: mean Dice between my labels and LDSD's masks on the same 30 photos. Most misses are definitions: LDSD marks a whole yellowed leaf (bottom) where I marked spots" \
Rows (Otsu start, empty start): "Polyp model, no fine-tuning: 0.010, 0.004" · "My 24 Roboflow photos, from polyp weights: 0.517, 0.520" · "My 24 Roboflow photos, from random weights: 0.467, 0.461" · "470 LDSD photos, from polyp weights: 0.670, 0.681" · "470 LDSD photos, from random weights: 0.678, 0.667" \
"With only 24 photos, starting from the polyp weights helps: 0.520 vs 0.461 (empty start)" · "Constant learning rate, 100 epochs: with only 6 validation photos the usual lr cut fired too early (first runs: 0.472 / 0.434)"]
#plain[Same as report §7.3 and §7.4. Left: label agreement. Right: transfer results. The 470-photo rows are an upper reference with 20 times more labelled data.]
#ask([Does transfer learning help?], [With 24 photos, yes (0.520 vs 0.461 from an empty start). With 470 photos it made no difference.])

#secbar("Future Scope", "slide 19")

== Slide 19: Future scope
#thumb(19)
#slidesays[More and richer own data: "Label more leaf photos in Roboflow: 24 training photos are the main limit on the leaf result" · "Several classes (e.g. brown spot vs yellow blotch): needs a multi-channel output with softmax and a multi-channel memory; FANet as published is binary" \
Closer to the paper: "Train with the paper's full protocol and several seeds, to tell the 0.038 Dice gap apart from run-to-run noise" · "Test on the paper's other polyp datasets (e.g. CVC-ClinicDB); we used one of seven" · "A separate validation split instead of choosing the checkpoint on test images" \
Towards real use: "Video: use the previous frame's mask as the memory, so feedback comes free during a live colonoscopy" · "Train the soft gate (fmask head) the paper describes" · "Faster inference (mixed precision, smaller encoder) for real-time decision support"]
#plain[
- *Every point answers a limit you found* (speaker notes): few own photos (slide 18), one class, the gap to the paper (slide 15), one dataset of seven, checkpoint chosen on test (Part A, §8).
- *0.038* = 0.880 (paper) − 0.842 (yours). With one run per setting you cannot say whether that gap is real or just noise between runs; several seeds would tell you.
- *Multi-class*: today the output is one channel with a sigmoid (spot or not). For several diseases you need one channel per class with a *softmax*, and the memory must store one mask per class too.
- *Video*: FANet needs a "previous mask". In a video the previous *frame* already gives one, so the feedback costs nothing extra.
- *fmask head*: those convs never train because the 0.5 threshold has no gradient (slide 7). A soft (sigmoid) gate would let them learn.
]
#ask(
  [Which step would you do first?], [Label more leaf photos. With 24 photos I get 0.517; with 470 LDSD photos the same model gets about 0.68, so data is the biggest limit.],
  [How would you make it multi-class?], [Change the last 1×1 conv to one channel per class, use softmax with cross-entropy (plus Dice per class), and keep a multi-channel memory. Roboflow would export one class number per pixel.],
  [Why is video a natural fit?], [The previous frame's prediction is almost the same as the current polyp's mask, so it is a good memory without running extra rounds.],
)

#secbar("Conclusion", "slide 20")

== Slide 20: Conclusion
#thumb(20)
#slidesays["FANet reproduced from scratch on Kvasir-SEG at 256×256: Dice 0.842 with the paper's protocol, 0.900 from an empty start (paper: 0.880 at 512×512)" · Works: "Full FANet from scratch; refinement adds +0.23 Dice from Otsu" · "Found: aligned memory makes the model copy it" · "Boxes from masks; own Roboflow dataset of real leaves" · Limits: "Feedback adds little: no-feedback ablation 0.883" · "512×512 no better: gap is not resolution" · "One dataset of seven; our test split may differ" · "Checkpoint chosen on test images, as in the authors' code" · Next: "More hand-labelled leaf photos in Roboflow" · "Train the fmask head (soft gate)" · "Video: reuse the previous frame's mask"]
#plain[+0.23 is 0.842 − 0.615: what refinement adds from Otsu. Close with Works, Limits, Next, in that order.]
#ask([What is the main limitation?], [The feedback adds little in my ablation, and each setting was trained once.])

// =====================================================================
= Part C: where the report, slides and logs disagree

None of these changes a headline number. If ma'am points one out, stay calm and give the correct value.

#table(columns: (auto, 1fr, 1fr),
  [\#], [What differs], [Correct value and what to say],
  [1], [Paper precision: slide 15 shows 0.900; the report shows 0.901.], [The paper's value is 0.9005. "Rounding, ma'am."],
  [2], [470 LDSD from random weights (Otsu start): the README says 0.679; report and slide 18 say 0.678.], [The log value is 0.67846, so 0.678 is right.],
  [3], [Report §5: "extra runs on Kaggle T4/P100". The README says the first 512 run used a P100.], [The Kaggle logs show Tesla T4 for all three Kaggle runs. Say "Kaggle T4".],
  [4], [The README says the 512×512 run's best epoch was 77.], [The saved checkpoint is from epoch 80 (lowest loss). Epoch 77 only had the highest test Dice. 0.831 comes from epoch 80.],
  [5], [Report §7.4 and slide 18: the default schedule cut the rate and "both models" scored about 0.04 lower.], [Only the fine-tuned run's rate was cut (epochs 13, 19, 25, 31; best epoch 7). The scratch run's rate was never cut; its re-run gained from 100 instead of 60 epochs.],
  [6], [Slide 8: "cut-out holes on image and ground truth".], [Rotation and flips move image and mask together. Cut-out is applied to the image only (`src/train.py:82`).],
  [7], [The notebook and project book show the main run's command with `--amp`.], [The saved run settings show no AMP; the flag was added later. AMP was used for the 512 official, LDSD and Roboflow runs.],
  [8], [Report §8 mentions test-set selection only for Kvasir.], [The 470-photo LDSD runs and the synthetic-leaf runs also had no validation split, so they chose checkpoints on their test sets. Only the Roboflow runs are fully clean.],
  [9], [Report §6 lists "no feedback (ablation)" as a plain ablation.], [It was trained with the older augmentation (flips, 90° turns, brightness), not ±35° rotations. It also keeps MixPool, while the paper's baseline removes it.],
  [10], [Empty start round 1: slide 16 says 0.829; slide 17 and report §6.2 say 0.83 and 0.828.], [Two scripts (evaluate vs memory probe) give 0.8292 and 0.8284. Not a real difference.],
)

*If ma'am asks about something you cannot verify,* say so. Two things the repo cannot prove: which polyp checkpoint the synthetic-leaf zero-shot test used, and the script that picked the 30 Roboflow photos (only its list and rule are saved).

// =====================================================================
= Part D: cheat sheet
#{
set text(9.3pt)
set par(leading: 0.5em)
grid(columns: (1fr, 1fr), gutter: 12pt,
[
  *Kvasir-SEG, 120 test images (report §6)*
  #table(columns: (1fr, auto, auto), inset: 3pt,
    [Model], [Dice], [mIoU],
    [FANet, paper (512×512)], [0.880], [0.815],
    [Paper, no MixPool], [0.852], [0.773],
    [*Ours, paper's protocol*], [*0.842*], [*0.779*],
    [Ours, round 1 only], [0.615], [0.512],
    [Ours, empty start], [0.900], [0.841],
    [No feedback], [0.883], [0.817],
    [Ours, 512×512], [0.831], [0.758],
    [Aligned memory (slide 15)], [0.684], [0.589],
  )
  Recall 0.934, precision 0.835, F2 0.868. Boxes: precision 0.685, recall 0.800. About 87 images/s.

  *Leaves, 118 LDSD photos (Otsu / empty)*
  #table(columns: (1fr, auto), inset: 3pt,
    [Polyp model, no fine-tuning], [0.010 / 0.004],
    [*Roboflow 24, polyp weights*], [*0.517 / 0.520*],
    [Roboflow 24, random weights], [0.467 / 0.461],
    [Default lr (ft / scratch)], [0.472 / 0.434],
    [470 LDSD, polyp weights], [0.670 / 0.681],
    [470 LDSD, random weights], [0.678 / 0.667],
  )
  Label agreement 0.730 (median 0.781, range 0.09-0.96).
],
[
  *Must-know facts*
  - 7,720,266 parameters; 982,088 (about 13%) never train.
  - Kvasir 1000 → 880 / 120, seed 42, 256×256.
  - LDSD 470 / 118. Roboflow 30 → 24 / 6 / 0 → 126.
  - Loss 0.5·BCE + 0.5·Dice. Adam $10^(-4)$. Plateau ×0.1, patience 5. Batch 8.
  - Main run: stopped at 147, best 107.
  - Otsu marks about 60%; polyps cover 14%.
  - Gap to paper 0.038. Refinement from Otsu +0.23.

  *Where in the code*
  - MixPool: `blocks.py:109-116`
  - Encoder / decoder / FANet: `model.py:27-88`
  - Otsu, memory: `memory.py:31-36`, `:60-68`
  - Loss: `losses.py:14-29`
  - Training step: `train.py:54-111`; commit `:187-190`
  - Refinement: `evaluate.py:95-120`
  - Dice, IoU, boxes: `metrics.py:38-39`, `:91-99`
  - Roboflow converter: `roboflow_to_masks.py:48-60`

  *Your notes to cite*
  - Output size, params, BN: Ch4 §4. Pooling: Ch4 §3.
  - Skip / residual: Ch4 §8. Backprop: Ch4 §9, Master §1.6.
  - Precision, recall, F1: Ch4 §6. IoU: Ch5 §6. Detection: Ch5 §2, §7.
  - BCE, Dice loss: Master §1.9. Adam: Master §1.11.

  *Honest one-liners*
  - From scratch: PyTorch layers only, no pretrained weights.
  - Detection: boxes from blobs at IoU ≥ 0.5, no mAP.
  - Test as validation: yes for Kvasir, like the authors.
  - Photos: public CC0; labels are mine.
])
}
