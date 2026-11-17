// FANet exam guide: follows docs/report.typ (Part A) and the 17 slides (Part B).
// Quotes are copied from DLproject/docs/report.typ and presentation/build_deck.js (commit ce2194e).
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
  - *Part A* walks through `docs/report.typ` in its own order, with its own headings.
  - *Part B* walks through the 17 slides in order.
  - *Part C* lists the few places where the report, the slides and the logs disagree, and what to say.
  - *Part D* is a one-page cheat sheet.

  *Every unit has the same four boxes:*
  #bx("Your report says / Your slide says", rgb("#eef0f4"), rgb("#4a5568"))[An exact quote from your report or slide. Numbers are exactly as printed there.]
  #bx("In plain words", rgb("#edf7ea"), rgb("#2e7d32"))[A short explanation. Theory is taken from *your own class notes* and cited like this: _(your Ch4 notes, §3)_. "Ch4" = `DL_Ch4_CNNs_Architectures_Backprop.pdf`, "Ch5" = `DL_Ch5_Object_Detection.pdf`, "Master" = `DL_Master_Revision_Guide.pdf`. If your notes do not cover a concept, the box says so.]
  #bx("Where it is in the code", rgb("#e6f2f3"), rgb("#1f6f78"))[`file:line` in the `DLproject` repo, with a few real lines copied from `src/`.]
  #bx("Ma'am may ask", rgb("#fff6e2"), rgb("#b9790a"))[Two to four likely questions with short answers.]

  *How to read it.* Today: Part A. Tomorrow: Part B, saying each slide out loud. Thursday morning: Parts C and D.
]

#pagebreak()
#outline(depth: 2, indent: 1em)

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
#says["Presentation (17 slides): `01_Presentation/` (PPTX and PDF)" · "Notebook, executed with outputs: `02_Notebook/FANet_project.ipynb` (and an HTML copy)" · "Roboflow dataset: `03_Roboflow_Dataset/`: exported zip, 11 screenshots of each step, label agreement CSV; public link above" · "This report: `04_Report/`" · "Source code and result tables: `05_Code/`" · "Trained weights: published separately (link in the package README)"]
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

For theory, each slide points back to the matching Part A unit.

== Slide 1: Polyp Segmentation with FANet
#thumb(1)
#slidesays["Polyp Segmentation with FANet" · "Feedback Attention Network (IEEE TNNLS 2023), implemented from scratch on Kvasir-SEG, with transfer to plant disease spotting" · "Chaitanya Shinde · 231070066"]
#plain[The title says three things: the task (polyp segmentation), the method (FANet, built from scratch) and the extra (transfer to leaves). The picture is a Kvasir image with its mask.]
#ask([Say your opening line.], [Good morning ma'am. My project is polyp segmentation with FANet, an IEEE TNNLS 2023 paper. I built it from scratch, trained it on Kvasir-SEG, and transferred it to leaf spots with my own Roboflow dataset.])

== Slide 2: One in four adenomas is missed during colonoscopy
#thumb(2)
#slidesays["26%: adenoma miss rate in tandem colonoscopy (meta-analysis, Zhao et al., Gastroenterology 2019)" · "−3%: risk of later colorectal cancer for every +1% in a doctor's adenoma detection rate (Corley et al., NEJM 2014)" · "Hard cases: flat polyps that blend into the wall, glare, bubbles, motion blur" · "Role: a second pair of eyes for the doctor. Decision support, not diagnosis"]
#plain[
- *Tandem colonoscopy*: two colonoscopies on the same patient. The second finds what the first missed.
- Finding more adenomas lowers cancer risk. So a model that highlights polyps can help.
- "Decision support, not diagnosis": the doctor decides, the model only points.
]
#ask([Would you use this in a hospital?], [No. It is a proof of concept for decision support, not validated for clinical use (report §8).])

== Slide 3: Segmentation labels every pixel, not the whole image
#thumb(3)
#slidesays["Classification: One label per image: "polyp present". Not allowed by the brief" · "Detection: A box around each object. We derive boxes from the mask (connected blobs)" · "Segmentation: A 0/1 label for every pixel. FANet's output: a 256×256 mask" · "Polyps cover 14% of a test image on average, so the classes are imbalanced"]
#plain[
- Three tasks, as in your notes _(Ch5, §2)_: one label; a box per object; and (beyond your notes) a label per pixel.
- *Imbalanced*: far more background pixels than polyp pixels. That is why you use Dice, not accuracy (Part A, §6).
]
#ask([Why does imbalance matter?], [An all-background mask would already get high accuracy but Dice 0. So I use Dice and a Dice term in the loss.])

== Slide 4: FANet remembers its last prediction for every image
#thumb(4)
#slidesays["Evaluated on 7 biomedical datasets; this project reproduces Kvasir-SEG" · "1. Mask memory across epochs: For each training image, keep the mask the network predicted for it last time" · "2. Hard attention at every stage: A MixPool block in every encoder and decoder stage uses that mask as a "look here" gate" · "3. Refinement at test time: Predict, feed the prediction back, predict again: up to 10 rounds"]
#plain[The three ideas are explained in Part A, §3 (memory), §3.2 (MixPool) and §3.3 (refinement). Memory = one stored mask per image. Gate = multiply by 0 or 1. Refinement = repeat with the last mask.]
#ask([What does FANet add to a U-Net?], [A memory of the last mask, MixPool attention that uses it in every block, and refinement at test time.])

== Slide 5: Architecture: a U-Net that also takes the previous mask
#thumb(5)
#slidesays["Encoder: Residual ×2 → MixPool → MaxPool" · "Decoder: TransposedConv ↑2 → concat skip → Residual ×2 → MixPool" · "Residual: two 3×3 conv + BN, 1×1 shortcut with squeeze-and-excitation" · "Output: previous mask concatenated, then 1×1 conv" · "7,720,266 parameters"]
#plain[
- The boxes show the skip size of each stage: 32 ch at 256², 64 at 128², 128 at 64², 256 at 32².
- Output size rule and parameter rule come from your notes _(Ch4, §4)_. Details in Part A, §3.1.
]
#where[`src/model.py:56-88` (FANet), `src/blocks.py:38-64` (residual block).]
#ask([Why the 1×1 shortcut?], [The input and output channel counts differ, and you can only add tensors of the same shape. Your ResNet notes call this a 1×1 projection (Ch4, §8).])

== Slide 6: MixPool: the previous mask decides where to look
#thumb(6)
#slidesays["Why two halves? If the mask is wrong, the unmasked half still carries every feature, so a bad mask cannot erase the polyp." · "Found in the code: the > 0.5 threshold has no gradient, so the fmask convs (982,088 parameters, 13%) never train."]
#plain[The six steps are in Part A, §3.2. The gradient finding is in §6.2: a step function passes no gradient back, so those convs keep their random weights.]
#where[`src/blocks.py:109-116`; the step is line `:110`.]
#ask([Why does a threshold stop learning?], [Backprop multiplies derivatives along the chain. The derivative of a step is 0, so nothing reaches the fmask convs.])

== Slide 7: Each image's last prediction is fed back as its next input
#thumb(7)
#slidesays["1 Start: Before epoch 1, every image's memory is an Otsu threshold of the blurred grey image" · "2 Predict: pred = FANet(image, memory[i]); loss = 0.5·BCE + 0.5·Dice; Adam step" · "3 Stage: Store pred > 0.5 for image i in a staging copy" · "4 Commit: If test loss improved: save the checkpoint and memory ← staging" · "Augmentation (as in the authors' code): rotate ±35°, flips, cut-out holes on image and ground truth; the memory is not moved." · "Otsu marks 60% of each image on average; polyps cover 14%"]
#plain[
- The four steps are the training loop of Part A, §3.3.
- "Test loss" is said honestly: for Kvasir, the validation set is the test set (Part A, §4).
- Otsu marks far more than the polyp, so it is a poor start. That is why round 1 is low.
]
#where[`src/memory.py:31-36` (Otsu), `:60-68` (stage, commit), `src/train.py:187-190` (commit rule).]
#ask([What does Otsu do?], [It picks the grey level that best splits dark from bright pixels and marks the bright ones. No learning.])

== Slide 8: Every layer, loss and metric is written from scratch
#thumb(8)
#slidesays[File table: "blocks.py: Squeeze-excite, residual block, MixPool" · "model.py: Encoder / decoder blocks, FANet" · "memory.py: Mask memory, Otsu threshold" · "augment.py: Rotation, flips, cut-out (torch only)" · "losses.py: 0.5·BCE + 0.5·Dice" · "metrics.py: Dice, IoU, precision, recall, F2; boxes from blobs (BFS)" · "train.py: Feedback training loop, checkpoints, log" · "evaluate.py: Test-time refinement, strips, FPS" · "memory_probe.py: How much the model relies on its memory" \
"Not used: pretrained weights, torchvision.models, segmentation_models_pytorch, the authors' repository (read only to check details)"]
#plain[
- Know one file for each job. The code map is on the cheat sheet (Part D).
- *BFS* (breadth-first search) finds connected blobs for the boxes.
]
#ask([Where is MixPool?], [`src/blocks.py`, class `MixPool`, lines 109 to 116.], [Where is the refinement loop?], [`src/evaluate.py`, lines 95 to 120.])

== Slide 9: Setup: Kvasir-SEG with the paper's 880 / 120 split
#thumb(9)
#slidesays["1000 colonoscopy images with polyp masks drawn by a doctor and verified by a gastroenterologist (Vestre Viken, Norway)" · "880 train / 120 test, fixed seed 42; the paper's split ratio (Table I)" · "Resized to 256×256 (512×512 run on Kaggle)" \
Table (Paper | Authors' code | This project): Input "512×512" | "256×256" | "256×256 (laptop) · 512×512 (Kaggle)" · Batch / epochs "100 epochs" | "2 / 500" | "8 / ≤200, early stop 40 · 512: 4 / 100" · Optimiser "Adam 1e-4" | "Adam 1e-4, plateau ×0.1" | "same" · Test "refinement" | "10 rounds from Otsu" | "same" · Hardware (this project) "RTX 5050 8 GB · Kaggle T4 / P100"]
#plain[The three columns are paper, authors' code and your project. The paper's text says 512 and 100 epochs; the authors' code uses 256, batch 2 and up to 500 epochs. You follow the code at 256 and the paper at 512.]
#ask([Why batch 8 and not 2?], [To use the GPU better and finish in time. It is one possible reason for the small gap to the paper.])

== Slide 10: Results on the 120 Kvasir-SEG test images
#thumb(10)
#slidesays[Rows (Dice, mIoU, Recall, Precision, F2): "FANet, paper: 0.880, 0.815, 0.906, 0.900, 0.887" · "FANet, ours, official protocol: 0.842, 0.779, 0.934, 0.835, 0.868" · "FANet, ours, round 1: 0.615, 0.512, 0.965, 0.530, 0.729" · "FANet, ours, empty start: 0.900, 0.841, 0.900, 0.935, 0.898" · "FANet, ours, 512×512: 0.831, 0.758, 0.917, 0.831, 0.860" · "No feedback (ablation): 0.883, 0.817, 0.897, 0.915, 0.886" · "Aligned memory (our first run): 0.684, 0.589, 0.958, 0.619, 0.775" \
"Ablation: without feedback the same network scores 0.883, above FANet from Otsu (0.842); the memory helps only from an empty start (+0.017)." \
"Detection view: boxes around the predicted blobs find 80% of the true polyp boxes at IoU ≥ 0.5 (box precision 0.685, official protocol)."]
#plain[Same table as report §6, plus the aligned-memory row (your first run, see slide 12). Read it top to bottom: paper, yours, round 1, empty start, 512, ablation, first attempt. The paper's precision is rounded differently in the report (see Part C, item 1).]
#ask([Which row is the most important?], [The ablation. Without feedback the network gets 0.883, so in my runs the memory adds little.])

== Slide 11: Refinement: an empty start climbs higher than Otsu
#thumb(11)
#slidesays["From Otsu (marks ~60% of the image): 0.615 → 0.842; each round trims the oversized guess" · "From an empty mask: 0.829 → 0.900, above the paper's 0.880, same weights" · "Strips: image | truth | Otsu | round 1 | round 2 | round 10 (Otsu start)"]
#plain[The chart shows Dice per round for both starts, with the paper's line for reference. An empty start does not over-mark, so it starts higher and ends higher.]
#where[`src/evaluate.py:95-120`; empty start with `--start zeros` (`:82-84`).]
#ask([Why is the empty start better?], [Otsu marks about 60% of the image, so the first mask is too big. An empty mask avoids that, and the model was trained to check its memory against the image.])

== Slide 12: Finding: an aligned memory teaches the model to copy it
#thumb(12)
#slidesays["Our first run rotated the memory together with the image, which looked like a fix to the authors' code" · "Its predictions followed the hint: given nothing, recall fell to 0.41; given everything, precision fell to 0.27" · "In the authors' code about 2/3 of training samples are rotated or flipped while their memory is not, so the model must check the memory against the image" · "With it, an empty start works (0.83 vs 0.52), but an over-full start (all ones, Otsu) still pulls the first pass"]
#plain[
- The bar chart is the *memory probe*: one pass from five starting masks.
- A model that copies its hint swings with it. A model that checks the hint stays steady.
- The authors' "bug" (memory not rotated) is really a regulariser (Part A, §6.2).
]
#where[`src/memory_probe.py:49-59` (the five starts); `src/train.py:79-82` (memory not moved).]
#ask([What was your most interesting finding?], [Aligning the memory made the model copy it. The authors' misalignment forces the model to check the memory, so it works as a regulariser.])

== Slide 13: Own dataset: 30 leaf photos, hand-labelled in Roboflow
#thumb(13)
#slidesays["Task kept, domain changed: irregular spots on a textured surface, but leaf disease instead of polyps (colonoscopy images cannot be collected by a student)" · "Photos: 30 real diseased-leaf photos from the public LDSD set (CC0); taking our own was not possible" · "Labels: every disease spot outlined by me in Roboflow (Smart Polygon + Polygon), about 2 hours" · "Project type: Semantic Segmentation, one class, so the export is a pixel mask, not boxes"]
#plain[Same story as report §7.1 and §7.2. Say clearly: the photos are public, the labels are yours.]
#ask([Did you take the photos?], [No. Public CC0 photos from LDSD. I drew every label myself.])

== Slide 14: Roboflow, step by step (my screenshots)
#thumb(14)
#slidesays["1. Label by hand: Smart Polygon + Polygon; each layer on the left is one spot I outlined (leaf_00097)" · "2. 30 jobs: one labelling job per photo, about 2 hours" · "3. Resize: stretch to 256×256, the training size" · "4. Augment: 90° turns shown; also flips, ±15° tilt, ±15% brightness" · "Then: split 24 / 6 / 0, generate version v1 (126 images), export as Semantic Segmentation Masks, convert with src/roboflow_to_masks.py."]
#plain[Four screenshots that prove you built the dataset. *Smart Polygon* is Roboflow's AI-assisted outline tool (it uses SAM, a segmentation model); you adjust its outline by hand.]
#where[`src/roboflow_to_masks.py:48-60` (reads `NAME_mask.png`).]
#ask([How long did labelling take?], [About 2 hours for all 30 photos.])

== Slide 15: Roboflow version v1: split, resize, 5× augmentation
#thumb(15)
#slidesays["126 images = 24 train photos × 5 + 6 validation photos" · "24 / 6 / 0 split: the test set is LDSD's own 118 photos, never seen in training" · "256×256 stretch: the size the model is trained at; image and mask stretch together" · "Flips, 90° turns, ±15° tilt: a leaf has no natural 'up'" · "±15% brightness: photos taken in different light" · "5× only on train; validation stays real" · "Offline vs online augmentation: Roboflow's copies are fixed files (offline); our training code also flips and rotates differently in every epoch (online)."]
#plain[
- *Offline augmentation*: copies made once and saved. *Online augmentation*: new random changes every epoch during training.
- Your notes list augmentation as a way to help generalization _(Master, §4.13)_.
]
#ask([Does stretching distort the image?], [Yes, the shape changes, but image and mask stretch together, so the labels stay aligned.])

== Slide 16: Real leaves: my labels and the transferred model
#thumb(16)
#slidesays["0.73: mean Dice between my labels and LDSD's masks on the same 30 photos. Most misses are definitions: LDSD marks a whole yellowed leaf (bottom) where I marked spots" \
Rows (Otsu start, empty start): "Polyp model, no fine-tuning: 0.010, 0.004" · "My 24 Roboflow photos, from polyp weights: 0.517, 0.520" · "My 24 Roboflow photos, from random weights: 0.467, 0.461" · "470 LDSD photos, from polyp weights: 0.670, 0.681" · "470 LDSD photos, from random weights: 0.678, 0.667" \
"With only 24 photos, starting from the polyp weights helps: 0.520 vs 0.461 (empty start)" · "Constant learning rate, 100 epochs: with only 6 validation photos the usual lr cut fired too early (first runs: 0.472 / 0.434)"]
#plain[Same as report §7.3 and §7.4. Left: label agreement. Right: transfer results. The 470-photo rows are an upper reference with 20 times more labelled data.]
#ask([Does transfer learning help?], [With 24 photos, yes (0.520 vs 0.461 from an empty start). With 470 photos it made no difference.])

== Slide 17: Conclusion
#thumb(17)
#slidesays["FANet reproduced from scratch on Kvasir-SEG at 256×256: Dice 0.842 with the paper's protocol, 0.900 from an empty start (paper: 0.880 at 512×512)" · Works: "Full FANet from scratch; refinement adds +0.23 Dice from Otsu" · "Found: aligned memory makes the model copy it" · "Boxes from masks; own Roboflow dataset of real leaves" · Limits: "Feedback adds little: no-feedback ablation 0.883" · "512×512 no better: gap is not resolution" · "One dataset of seven; our test split may differ" · "Checkpoint chosen on test images, as in the authors' code" · Next: "More hand-labelled leaf photos in Roboflow" · "Train the fmask head (soft gate)" · "Video: reuse the previous frame's mask"]
#plain[+0.23 is 0.842 − 0.615: what refinement adds from Otsu. Close with Works, Limits, Next, in that order.]
#ask([What is the main limitation?], [The feedback adds little in my ablation, and each setting was trained once.])

// =====================================================================
= Part C: where the report, slides and logs disagree

None of these changes a headline number. If ma'am points one out, stay calm and give the correct value.

#table(columns: (auto, 1fr, 1fr),
  [\#], [What differs], [Correct value and what to say],
  [1], [Paper precision: slide 10 shows 0.900; the report shows 0.901.], [The paper's value is 0.9005. "Rounding, ma'am."],
  [2], [470 LDSD from random weights (Otsu start): the README says 0.679; report and slide 16 say 0.678.], [The log value is 0.67846, so 0.678 is right.],
  [3], [Report §5: "extra runs on Kaggle T4/P100". The README says the first 512 run used a P100.], [The Kaggle logs show Tesla T4 for all three Kaggle runs. Say "Kaggle T4".],
  [4], [The README says the 512×512 run's best epoch was 77.], [The saved checkpoint is from epoch 80 (lowest loss). Epoch 77 only had the highest test Dice. 0.831 comes from epoch 80.],
  [5], [Report §7.4 and slide 16: the default schedule cut the rate and "both models" scored about 0.04 lower.], [Only the fine-tuned run's rate was cut (epochs 13, 19, 25, 31; best epoch 7). The scratch run's rate was never cut; its re-run gained from 100 instead of 60 epochs.],
  [6], [Slide 7: "cut-out holes on image and ground truth".], [Rotation and flips move image and mask together. Cut-out is applied to the image only (`src/train.py:82`).],
  [7], [The notebook and project book show the main run's command with `--amp`.], [The saved run settings show no AMP; the flag was added later. AMP was used for the 512 official, LDSD and Roboflow runs.],
  [8], [Report §8 mentions test-set selection only for Kvasir.], [The 470-photo LDSD runs and the synthetic-leaf runs also had no validation split, so they chose checkpoints on their test sets. Only the Roboflow runs are fully clean.],
  [9], [Report §6 lists "no feedback (ablation)" as a plain ablation.], [It was trained with the older augmentation (flips, 90° turns, brightness), not ±35° rotations. It also keeps MixPool, while the paper's baseline removes it.],
  [10], [Empty start round 1: slide 11 says 0.829; slide 12 and report §6.2 say 0.83 and 0.828.], [Two scripts (evaluate vs memory probe) give 0.8292 and 0.8284. Not a real difference.],
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
    [Aligned memory (slide 10)], [0.684], [0.589],
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
