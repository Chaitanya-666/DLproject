// FANet 101: the one guide to read before the lab exam (Thu 19 Nov 2026, batch 2, 11:30).
// Facts are taken from README.md §4–§10, src/*.py and the run CSVs (runs/*/eval_test*/results.csv).
#set document(title: "FANet 101", author: "Chaitanya Shinde")
#set page(paper: "a4", margin: (x: 2cm, y: 1.8cm), numbering: "1",
  header: context { if counter(page).get().first() > 1 [
    #set text(8pt, fill: luma(120)); FANet 101 #h(1fr) Chaitanya Shinde, 231070066 ] })
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 11pt, lang: "en")
#set par(justify: false, leading: 0.6em)
#show heading: set text(font: "Inter", weight: "bold")
#show heading.where(level: 1): it => { v(0.6em); text(15pt, fill: rgb("#0e3b43"), it); v(0.1em) }
#show heading.where(level: 2): it => { v(0.3em); text(12pt, fill: rgb("#14545e"), it) }
#show raw.where(block: true): it => block(fill: luma(244), inset: 6pt, radius: 2pt, width: 100%, text(8.8pt, it))
#show raw.where(block: false): it => text(font: "DejaVu Sans Mono", size: 9pt, fill: rgb("#14545e"), it.text)
#set table(stroke: 0.4pt + luma(165), inset: 4.5pt)
#show table.cell.where(y: 0): set text(weight: "bold")

#let box2(title, bg, accent, body) = block(width: 100%, fill: bg, stroke: (left: 3pt + accent),
  inset: (x: 9pt, y: 6pt), radius: 2pt, breakable: false)[
  #text(font: "Inter", size: 8pt, weight: "bold", fill: accent)[#upper(title)] \ #body]
#let say(body) = box2("Say it like this", rgb("#edf7ea"), rgb("#2e7d32"), body)
#let trap(body) = box2("Trap: don't say this", rgb("#fdecea"), rgb("#b3261e"), body)
#let qa(..qs) = {
  let items = qs.pos()
  for i in range(0, items.len(), step: 2) {
    block(above: 0.5em, below: 0.5em, breakable: false)[*Q.* #items.at(i) \ *A.* #items.at(i + 1)]
  }
}

#align(center)[
  #text(9pt, font: "Inter", fill: luma(90))[DL LAB EXAM · THU 19 NOV 2026 · BATCH 2 · 11:30 AM]
  #v(0.2cm)
  #text(22pt, font: "Inter", weight: "bold", fill: rgb("#0e3b43"))[FANet 101]
  #v(0.1cm)
  #text(12pt)[Your whole mini-project from zero: theory, paper, code, results, demo]
  #v(0.2cm)
  Chaitanya Shinde · 231070066
]
#block(width: 100%, inset: 9pt, stroke: 0.6pt + rgb("#1f6f78"), radius: 3pt)[
  *How to use it.* Read §1–§9 once, in order (about 2 hours). Say every green box out loud. Run the demo (§10) once on your laptop tonight. Read the cheat sheet on the last page tomorrow morning and again before you walk in.
  The older guides (Exam Guide, OneShot) go deeper; you only need them to look something up.
]
#outline(depth: 1, title: none)

// =====================================================================
= 1. The project in 60 seconds

#say[
  "My mini-project implements *FANet*, a *Feedback Attention Network*, from an *IEEE Transactions on Neural Networks and Learning Systems* paper (2023), *from scratch in PyTorch*.
  The task is *polyp segmentation*: in a colonoscopy image, mark every pixel that belongs to a polyp, the small growth that can turn into colon cancer.
  FANet's idea: the network *remembers its last prediction for every image* and feeds it back as a hint, and at test time it *refines* its mask over several rounds.
  On the paper's dataset, *Kvasir-SEG*, I get *Dice 0.842* with the paper's test protocol (paper 0.880), and *0.900* when refinement starts from an empty mask.
  For my own data, I hand-labelled leaf photos in *Roboflow* and transferred the model to *leaf disease spots*. I also built a separate 4-class tomato-leaf detection dataset in Roboflow."
]

What you must be able to defend: *what* the problem is (§3), *how* FANet works (§5), *what you built* (§6), *your data* (§7), *what the numbers mean* (§8), and *running it live* (§10).

// =====================================================================
= 2. Deep-learning basics you need (and nothing more)

== 2.1 From neuron to CNN
- *Neuron:* multiplies its inputs by *weights*, adds a *bias*, then applies an *activation* (a non-linear function). Learning = finding good weights.
- *Neural network:* layers of neurons. Without non-linear activations, many layers would collapse into one linear function, so they could only draw straight-line boundaries.
- *CNN (convolutional neural network):* for images. Instead of connecting every pixel to every neuron, a small *filter* (3×3 here) slides over the image and computes a weighted sum at each position. The same filter is reused everywhere (*weight sharing*), so it finds the same pattern (edge, texture, colour change) anywhere in the image. Stacked layers combine small patterns into bigger ones.

#table(columns: (auto, 1fr),
  [Layer], [What it does, in one line],
  [`Conv2d` 3×3], [learned filter; finds local patterns. Output = a *feature map* per filter (*channels*)],
  [`Conv2d` 1×1], [mixes channels at each pixel; used to change the channel count and for the final output],
  [`BatchNorm2d`], [normalises each channel to mean 0, variance 1 over the batch → faster, stabler training],
  [`ReLU`], [$max(0, x)$: the non-linearity],
  [`MaxPool2d` 2×2], [keeps the max of every 2×2 window → halves height and width, widens the view],
  [`ConvTranspose2d`], [learned *up*-sampling: doubles height and width],
  [`Sigmoid`], [squashes any number into (0, 1) → a probability per pixel],
)

== 2.2 How a network learns
1. *Forward pass:* image in → prediction out.
2. *Loss:* one number for how wrong the prediction is.
3. *Backpropagation:* the chain rule computes how much each weight contributed to the loss (its *gradient*).
4. *Optimizer step:* move every weight a little against its gradient. We use *Adam* (gradient descent with momentum and a per-weight step size). The step size is the *learning rate* (lr), here $10^(-4)$.
5. Repeat for every *batch* (8 images at a time). One pass over the whole training set = one *epoch*.

- *Overfitting:* the model memorises the training images and does worse on new ones. Counter it with *augmentation* (random flips, rotations, brightness changes, so it sees "new" images every epoch), *early stopping*, and more data.
- *Train / validation / test:* train on one part, pick the best checkpoint on another, report on images the model never trained on.
- *Learning-rate schedule:* `ReduceLROnPlateau` multiplies the lr by 0.1 if the validation loss has not improved for 5 epochs.
- *Transfer learning / fine-tuning:* start from weights trained on another task instead of random weights. It helps most when the new dataset is small (you'll see this in §8).

== 2.3 Classification vs detection vs segmentation
#table(columns: (auto, auto, 1fr),
  [Task], [Output], [Example],
  [Classification], [one label per image], ["polyp present". *Not allowed* by the brief],
  [Object detection], [a *box + class* per object], [a rectangle around the polyp],
  [Semantic segmentation], [a label *for every pixel*], [a mask: 1 = polyp pixel, 0 = background],
  [Instance segmentation], [a separate mask per object], [polyp \#1, polyp \#2],
)
FANet does *binary semantic segmentation*. We also get a *detection view* for free: draw a box around each connected blob of the mask.

== 2.4 Metrics (memorise these four)
Compare the predicted mask $P$ with the true mask $G$, pixel by pixel. TP = polyp pixels we marked, FP = background we wrongly marked, FN = polyp pixels we missed.
#table(columns: (auto, auto, 1fr),
  [Metric], [Formula], [Meaning],
  [*Dice* (= F1)], [$2 T P \/ (2 T P + F P + F N)$], [overlap of $P$ and $G$, 0 to 1. *The main number*],
  [*IoU* (Jaccard)], [$T P \/ (T P + F P + F N)$], [intersection over union; always ≤ Dice],
  [Precision], [$T P \/ (T P + F P)$], [of what I marked, how much is really polyp],
  [Recall], [$T P \/ (T P + F N)$], [of the real polyp, how much I found. *Matters most in medicine*: a missed polyp is worse than a false alarm],
)
Pixel *accuracy* is misleading here: a polyp usually covers only a small part of the image, so predicting "all background" already gets most pixels right. That is why we use Dice. *F2* is like Dice but weights recall more.

// =====================================================================
= 3. The problem: why polyp segmentation

- *Colorectal cancer* is among the most common and deadliest cancers. Most cases start as *polyps* (small growths on the colon wall); some (*adenomas*) slowly turn cancerous.
- In a *colonoscopy*, a doctor guides a camera through the colon and removes the polyps they see. But about *1 in 4 adenomas is missed* (26% miss rate, Zhao et al., _Gastroenterology_ 2019). Each *1% increase in the adenoma detection rate lowers the risk of later cancer by about 3%* (Corley et al., _NEJM_ 2014).
- So a model that *outlines the polyp pixel by pixel* is a second pair of eyes. A mask beats a yes/no label: it shows *where*, *how big*, and *where the edges are*.
- *Why it is hard:* polyps vary in size, shape and colour; flat ones blend into the wall; images contain glare, bubbles, blur and instruments.

#trap["My model diagnoses cancer." Say instead: *decision support / a second pair of eyes; a proof of concept, not a medical device.*]

// =====================================================================
= 4. The base paper

#table(columns: (auto, 1fr),
  [Title], [*FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation*],
  [Authors], [N. K. Tomar, D. Jha, M. A. Riegler, H. D. Johansen, D. Johansen, J. Rittscher, P. Halvorsen, S. Ali],
  [Venue], [*IEEE Transactions on Neural Networks and Learning Systems*, vol. 34, no. 11, 2023 (online 2022)],
  [Why it fits the brief], [IEEE, within 5 years, segmentation (not classification), CNN-based, more advanced than a plain U-Net],
  [Paper's result], [Kvasir-SEG Dice *0.880* at 512×512],
)

*The problem the paper attacks:* a normal segmentation network looks at every image fresh, every epoch. It forgets what it predicted for that image last time. FANet's question: *what if the network could use its own previous mask for the same image as a hint?*

// =====================================================================
= 5. How FANet works

== 5.1 The skeleton: a U-Net
#image("figures/kvasir_example.png", width: 55%)
- *Encoder* (going down): 4 stages, each = 2 residual blocks → MixPool → 2×2 max-pool. Image size goes $256 → 128 → 64 → 32 → 16$; channels go $32 → 64 → 128 → 256$. It learns *what* is in the image.
- *Decoder* (going up): 4 stages, each = transposed conv (×2 size) → join the encoder's features of the same size (*skip connection*) → 2 residual blocks → MixPool. It learns *where exactly*.
- *Skip connections* bring back the fine detail (sharp edges) that pooling threw away.
- *Output:* the last decoder features + the previous mask → 1×1 conv → sigmoid → probability per pixel → threshold at 0.5 → 0/1 mask.
- Size: *7.72 million parameters*.

== 5.2 Residual block and squeeze-and-excitation (SE)
- *Residual block:* conv3×3 → BN → ReLU → conv3×3 → BN, then *add the input back* through a shortcut (1×1 conv + BN + SE), then ReLU. The block only learns a *correction* to its input, and the shortcut lets gradients flow straight back, so deep networks train well (idea from ResNet).
- *SE (channel attention):* average each channel to one number → tiny 2-layer network + sigmoid → one weight per channel in (0, 1) → multiply. The network learns *which channels matter for this image*.

== 5.3 MixPool: the feedback-attention block (the paper's key block)
Inputs: the feature map $x$ and the *previous mask* $m$ for this image.
1. *fmask:* a small conv head predicts a rough mask from $x$ itself, thresholded at 0.5 (hard 0/1).
2. $m$ is max-pooled down to the feature map's size.
3. *attention = fmask OR m.* Features outside the attention region are set to zero (*hard attention*), then go through conv 1.
4. The *untouched* features go through conv 2.
5. Concatenate both halves.

Step 4 is the safety net: even if the previous mask is wrong, the full features still reach the next layer.

#say["MixPool lets the previous mask decide *where to look*. Half the channels see only the region the mask points to; the other half see everything, so a wrong mask can't blind the network."]

*Soft vs hard attention:* soft attention multiplies by weights in (0, 1) (like SE); hard attention multiplies by exactly 0 or 1 (like MixPool's gate).

== 5.4 The feedback memory (training)
- The model keeps *one mask per training image* in memory.
- *Before epoch 1:* every slot is filled with an *Otsu* guess. Otsu's method picks the grey level that best splits the image's brightness histogram into two groups; pixels brighter than it become 1. No learning needed, just a rough start.
- *Each epoch:* image + its stored mask → model → new prediction. The prediction is *staged*.
- *If the validation loss improved*, the checkpoint is saved and the staged predictions become the new memory (`--memory-update on-improve`).
- So next epoch, each image comes with the model's own *earlier* answer for it.

== 5.5 Iterative refinement (testing)
#image("figures/strip_kvasir_official.png", width: 100%)
For each test image: start memory = Otsu guess → predict → put the prediction back as memory → predict again … *10 rounds* (official setting). The mask gets better round by round: Dice 0.615 after round 1 → 0.842 after round 10.

== 5.6 Loss
*Loss = 0.5 × binary cross-entropy + 0.5 × Dice loss* (same as the official code).
- *BCE* judges each pixel separately → smooth, stable gradients, but dominated by the large background.
- *Dice loss* $= 1 - "Dice"$ judges the overlap of the whole region → a small polyp still counts, and it matches the metric we report.

// =====================================================================
= 6. What I built

*"From scratch"* means every layer is written with plain PyTorch pieces (`nn.Conv2d`, `nn.BatchNorm2d`, …). No pretrained weights, no model zoo, no `segmentation_models_pytorch`. The authors' code was only read to check details.

#table(columns: (auto, 1fr),
  [File in `src/`], [What it does],
  [`blocks.py`], [SE, residual block, MixPool],
  [`model.py`], [the U-Net: 4 encoder + 4 decoder stages, output head],
  [`memory.py`], [Otsu initial guess, the per-image mask memory (stage / commit)],
  [`losses.py`], [0.5 BCE + 0.5 Dice loss],
  [`dataset.py`, `augment.py`], [load images + masks at 256×256; flips, rotations, brightness, cut-out holes],
  [`train.py`], [training loop, Adam, lr schedule, early stopping, checkpoint + memory saving],
  [`evaluate.py`], [10-round refinement, all metrics per round, picture strips, FPS],
  [`metrics.py`], [Dice, IoU, precision, recall, F2, box metrics],
  [`roboflow_to_masks.py`], [converts my Roboflow export into image + mask folders],
)

*Settings:* 256×256 input, batch 8, Adam lr $10^(-4)$, up to 200 epochs with early stop after 40 without improvement, trained on my laptop GPU (RTX 5050, 8 GB).

*Differences from the paper (say them honestly):* the paper reports 512×512 and the official code uses batch 2. I used 256×256 (as the official code does) and batch 8 to fit the time. My 512×512 run scored 0.831, *no better*, so resolution is not the gap.

== The one surprising finding (worth bringing up yourself)
The official code flips and rotates the image and its true mask, but *not the stored memory mask*. That looks like a bug, so my first run "fixed" it by moving the memory too. Result: the model learned to *copy its memory*. Given an empty memory, its recall fell to 0.41; given an all-ones memory, its precision fell to 0.27. From an Otsu start it scored only 0.684.
With the official (misaligned) behaviour, the memory is often wrong during training, so the model *must check it against the image*. It acts as a regulariser. I switched back to the official behaviour: 0.842.

#say["I first thought the misaligned memory in the authors' code was a bug and fixed it. The model then just copied its hint. The misalignment is actually what forces it to look at the image."]

// =====================================================================
= 7. The datasets

== 7.1 Kvasir-SEG (the paper's dataset)
- *1000 colonoscopy images* with polyp masks, drawn by a doctor and verified by a gastroenterologist (Vestre Viken hospital, Norway). Same research group as FANet's authors.
- Split *880 train / 120 test*, like the official code. All images resized to 256×256. Masks are JPEGs, so they are thresholded at 127 to get clean 0/1.

== 7.2 My Roboflow segmentation dataset (leaf disease spots)
- *Why leaves:* I can't collect colonoscopy images. Leaf disease spots are the *same kind of task* (irregular blobs on a textured surface) in a different domain.
- *Photos:* 30 real leaf photos from *LDSD* (Leaf Disease Segmentation Dataset, Kaggle, CC0, 588 photos taken from PlantDoc). Taking my own photos wasn't possible, so I used public ones and *drew every label by hand*.
- *In Roboflow:* Semantic Segmentation project `leaf-disease-seg`. Spots outlined with Smart Polygon + Polygon (about 2 hours). Rule: brown/dead tissue yes, standalone yellow blotches yes, thin yellow rims no.
- *Version v1:* split 24 train / 6 valid; Auto-Orient; resize 256×256; flip, 90° rotate, ±15° rotation, ±15% brightness; *5× on train* → 120 + 6 = *126 images*. Exported as semantic masks. Public on Roboflow Universe.
- *Label check:* LDSD has its own masks for these 30 photos. My labels agree with them at *Dice 0.730*. The gap is mostly a difference in *definition* (LDSD sometimes marks the whole yellowed leaf, I marked only the spots).

== 7.3 My Roboflow detection dataset (tomato leaves, 4 classes)
Made for the lab's dataset rule (*≥ 200 annotated images, ≥ 4 classes, detection or segmentation*). It is separate from FANet; FANet stays the main project.
- *Photos:* 220 tomato-leaf photos from *PlantVillage* (Hughes & Salathé, 2015), 55 per class.
- *Classes:* `bacterial_spot` (many tiny dark specks), `early_blight` (brown spots with *target-like rings*), `late_blight` (large irregular greasy dark patches, no rings), `healthy`.
- *Annotation:* Object Detection project in Roboflow; *I drew one bounding box per leaf* and chose its class.
- *Version:* split 80 / 10 / 10; Auto-Orient, resize 640×640; flips, ±15° rotation, ±15% brightness; 3× augmentation; exported in YOLOv8 format.

#qa(
  [Why are augmented images not "more annotated images"?], [They are copies of the same photos with flips/rotations; the labels move with them automatically. The 220 originals are the annotated images.],
  [Why augment only the training set?], [Validation and test must be real, unchanged photos, or the score would be measured on near-copies of training images.],
  [Why 4 classes in detection but 1 class in segmentation?], [Different goals: the segmentation set measures *where* disease is on a leaf (FANet is binary); the detection set labels *which disease* each leaf has.],
)

// =====================================================================
= 8. Results, and what they mean

== 8.1 Kvasir-SEG test set (120 images, 10 refinement rounds)
#table(columns: (1fr, auto, auto, auto, auto),
  [Model], [Dice], [IoU], [Recall], [Precision],
  [FANet, paper (512×512)], [0.880], [0.815], [0.906], [0.901],
  [Paper's baseline without MixPool], [0.852], [0.773], [0.884], [0.871],
  [*Mine, paper's protocol* (Otsu start)], [*0.842*], [0.779], [0.934], [0.835],
  [*Mine, empty start*], [*0.900*], [0.841], [0.900], [0.935],
  [Mine, no feedback (memory always zero)], [0.883], [0.817], [0.897], [0.915],
)
Speed: about *87 images per second* on the laptop GPU.

How to read it:
- *0.842 vs 0.880:* close, but 0.04 below the paper. Not the resolution (512 gave 0.831). Likely the batch size (8 vs 2), maybe a different 120-image test split, and one training run per setting.
- *Empty start 0.900:* same weights, different *test procedure*: start refinement from an empty mask instead of Otsu. The Otsu guess marks bright glare, not polyps, and pulls the model toward wrong regions. Reported separately because it changes the paper's protocol.
- *The honest finding (ablation):* switching the feedback off entirely gives 0.883. So in my reproduction the feedback memory adds *little* (+0.02 at best). The paper claims a bigger gain (0.852 → 0.880).
- *Recall is high (0.93):* the model rarely misses polyp pixels; it tends to over-mark. That is the safer error in screening.
- *Detection view* (boxes from blobs, a box counts if IoU ≥ 0.5): box recall 0.80, box precision 0.69 (empty start: 0.90 / 0.84).

== 8.2 Leaves (118 LDSD test photos)
#table(columns: (1fr, auto),
  [Model], [Dice],
  [Polyp model, no fine-tuning], [0.01],
  [Fine-tuned on 470 LDSD photos (from polyp weights / from random)], [0.681 / 0.679],
  [*Fine-tuned on my 24 Roboflow photos* (from polyp weights)], [*0.517*],
  [Trained on my 24 photos from random weights], [0.467],
)
- Without fine-tuning the polyp model fails on leaves (0.01): different domain.
- *Transfer learning helps when data is small:* with only 24 photos, starting from the polyp weights gives +0.05. With 470 photos it makes no difference. With little data, pretrained filters (edges, blobs) are a head start; with enough data, the model learns them anyway.
- Leaves are harder than polyps: many small scattered spots, cluttered backgrounds, and test masks drawn by someone else to a different definition.
- These runs use a *constant learning rate*: with only 6 validation photos, the noisy validation loss cut the lr too early in the first runs.

// =====================================================================
= 9. Limitations and future scope

*Limitations:* 0.04 below the paper's Dice; one run per setting (no error bars); the best checkpoint is picked on the test images (as the authors' code does), so the numbers are slightly optimistic; the fmask heads get *no gradient* (their output is thresholded, which has zero slope), so about 13% of the parameters never train; only 24 hand-labelled leaf photos.

*Future scope:* train with batch 2 for 500 epochs as in the official code; repeat runs with different seeds; make fmask trainable (soft sigmoid gate); test on other polyp datasets (CVC-ClinicalDB) and on video; label more leaf photos; train a detector (e.g. YOLO) on the 4-class tomato set.

// =====================================================================
= 10. The live demo

Bring your laptop, charged. Open a terminal *before* your turn:
```
cd /mnt/Windows_D/College-work/DLproject
./demo.sh polyp 4      # 4 random Kvasir-SEG test images, with the doctor's mask (≈10 s)
./demo.sh leaf 4       # 4 random leaf test photos, model fine-tuned on my Roboflow labels
./demo.sh test         # all 120 test images: prints Dice 0.842 again (≈2 min on the GPU)
./demo.sh folder ~/Pictures/x polyp   # any images ma'am gives you (no ground truth)
```
It prints the Dice after each refinement round and opens one picture strip per image:
*image | true mask | Otsu start | round 1 | round 2 | … | round 10* (blue = predicted polyp).

What happens inside (say this while it runs): the script loads the trained weights (`runs/kvasir_official/best.pt`), resizes each image to 256×256, makes the Otsu guess as the starting memory, then runs the network 10 times, each time feeding back its last mask. No training happens; this is *inference*.

#say["Here the first column is the image, then the doctor's mask, then Otsu's rough guess. Watch round 1 to round 10: the mask tightens around the polyp because each round the model gets its own previous answer as a hint."]

*If one random image scores low*, don't panic. Average Dice is 0.84, so some images are 0.5. Point to the strip and explain (flat polyp, glare, the model over-marks). It shows you understand failure cases.

*Where else to show results* if the laptop fails: the notebook `notebooks/FANet_project.ipynb` (already executed, all outputs saved), the slides, and `docs/report.pdf`. Weights are public at `huggingface.co/Ckorion/fanet-polyp-leaf-from-scratch`.

#qa(
  [Show me the model code.], [Open `src/model.py` (the U-Net) and `src/blocks.py` (MixPool, lines with `fmask`, `logical_or`, `torch.cat`).],
  [Where is the loss?], [`src/losses.py`: `0.5 * BCE + 0.5 * dice_loss`.],
  [How do you train it?], [`python -m src.train --data data/Kvasir-SEG --out runs/kvasir` (don't actually run it: it takes hours).],
  [Print the parameter count.], [`~/.venvs/dlproject/bin/python -m src.model` → 7,720,266.],
)

// =====================================================================
= 11. Rapid-fire questions

#qa(
  [Why segmentation and not classification?], [The brief forbids classification, and a mask gives location, size and edges, which a yes/no label can't.],
  [What is "feedback" in FANet?], [The model's own previous mask for the same image, stored in memory and given back as an extra input next time.],
  [Why Otsu at the start?], [A free, rough first guess before the model has predicted anything. No learning needed.],
  [Why is refinement useful?], [Each round starts from a better hint, so the mask improves: 0.615 → 0.842 Dice over 10 rounds.],
  [Why skip connections?], [Pooling loses fine detail; skips bring the encoder's sharp features back to the decoder at the same scale.],
  [Why residual blocks?], [The block learns only a correction, and the shortcut lets gradients flow back, so deep networks train well.],
  [Why Dice and not accuracy?], [Most pixels are background, so accuracy looks high even for an empty mask. Dice only counts the polyp region.],
  [Why BCE + Dice loss?], [BCE gives stable per-pixel gradients; Dice handles class imbalance and matches the metric.],
  [Why sigmoid, not softmax?], [Binary task (polyp or not), one output channel: sigmoid gives one probability per pixel.],
  [What is a transposed convolution?], [A learned upsampling layer: it doubles height and width with trainable weights.],
  [Why augmentation?], [Only 880 training images. Random flips, rotations and brightness changes act like new images and reduce overfitting.],
  [What is fine-tuning?], [Start from weights trained on polyps, then train further on leaves with a smaller lr ($5 times 10^(-5)$).],
  [Your result is below the paper. Why?], [Batch 8 vs 2, maybe a different test split, one run each. Not resolution: 512×512 gave 0.831.],
  [What would you improve?], [Train with the official batch 2, make fmask trainable, multiple seeds, more leaf labels.],
  [Did you write it yourself?], [Yes, every layer in plain PyTorch, following the paper and checking details against the authors' code. I can walk you through any file.],
  [What is Roboflow used for?], [Uploading photos, drawing labels (polygons for masks, boxes for detection), splitting, augmenting, and exporting the dataset in a training format.],
  [What is the YOLO export format?], [One `.txt` per image, one line per box: class id, then box centre x, centre y, width, height, all scaled to 0–1.],
  [What is mAP? (detection)], [Mean Average Precision: area under the precision–recall curve per class, averaged over classes. mAP\@0.5 counts a box as correct if IoU ≥ 0.5.],
)

#pagebreak()
// =====================================================================
= Cheat sheet

#set text(10pt)
#grid(columns: (1fr, 1fr), gutter: 12pt,
[
*Paper:* FANet: Feedback Attention Network, Tomar et al., *IEEE TNNLS 2023*. Polyp segmentation on *Kvasir-SEG*.

*Idea:* remember last mask per image → feed back as hint (training); refine 10 rounds (testing).

*Architecture:* U-Net, 4 down + 4 up. Each stage: 2 residual blocks (with SE) + *MixPool*. Channels 32/64/128/256, sizes 256→16. Output: features + prev mask → 1×1 conv → sigmoid. *7.72 M params.*

*MixPool:* attention = fmask OR prev mask. Half channels see only that region (hard attention), half see all. Concatenate.

*Memory:* start = *Otsu* guess. Updated with predictions when val loss improves.

*Loss:* 0.5 BCE + 0.5 Dice. *Optimizer:* Adam, lr 1e-4, ×0.1 on plateau.

*Data:* 1000 images, 880 train / 120 test, 256×256, batch 8.

*Metrics:* Dice = 2TP/(2TP+FP+FN). IoU = TP/(TP+FP+FN). Recall = found / real. Precision = right / marked.
],
[
#table(columns: (1fr, auto),
  [Kvasir test, 10 rounds], [Dice],
  [Paper], [0.880],
  [*Mine, Otsu start*], [*0.842*],
  [Mine, empty start], [0.900],
  [No feedback], [0.883],
  [Round 1 only], [0.615],
  [512×512], [0.831],
)

*Finding:* moving memory with augmentations → model copies its hint → 0.684. Official misalignment = regulariser.

*Leaves (118 LDSD test):* polyp model 0.01 → fine-tuned on my *24* Roboflow photos *0.517* (scratch 0.467). On 470 photos 0.68 either way → transfer helps when data is small.

*Roboflow seg:* 30 LDSD photos, hand polygons, 24/6, 5× aug → 126, labels agree 0.730.

*Roboflow det:* 220 PlantVillage tomato leaves, *4 classes* (bacterial spot, early blight, late blight, healthy), my boxes, 80/10/10, 3× aug, YOLOv8 export.

*Demo:* `./demo.sh polyp 4` · `leaf 4` · `test`.

*Limits:* −0.04 vs paper, 1 run each, fmask gets no gradient (13% params).
],
)
