# FANet from scratch: polyp segmentation with feedback attention

Individual Deep Learning mini-project, B.Tech Computer Engineering, Sem VII, 2026–27.
Chaitanya Shinde, 231070066.

**Paper implemented:** N. K. Tomar, D. Jha, M. A. Riegler, H. D. Johansen, D. Johansen, J. Rittscher, P. Halvorsen, S. Ali,
*"FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation"*,
**IEEE Transactions on Neural Networks and Learning Systems**, vol. 34, no. 11, 2023 (online 2022).
DOI [10.1109/TNNLS.2022.3159394](https://doi.org/10.1109/TNNLS.2022.3159394) ·
[IEEE Xplore](https://ieeexplore.ieee.org/document/9741842) ·
[arXiv 2103.17235](https://arxiv.org/abs/2103.17235) ·
[authors' code](https://github.com/nikhilroxtomar/FANet).

**Dataset:** Kvasir-SEG (1000 colonoscopy images with polyp masks), the paper's own dataset.

**PPT title:** *Polyp Segmentation for Colorectal Cancer Screening using FANet (Feedback Attention), with Transfer to Plant Disease Spotting.*

**Status (13 Oct 2026):** topic registered (row 29 of the sheet). Code scaffold written and smoke-tested on CPU. Next: first full training run on Kaggle.

This README is the whole project's documentation. Read it top to bottom once and you should be able to run everything, explain every design choice, and answer viva questions.

---

## Contents

1. [The assignment, and how this project meets it](#1-the-assignment-and-how-this-project-meets-it)
2. [The problem: why polyp segmentation](#2-the-problem-why-polyp-segmentation)
3. [Background you need](#3-background-you-need)
4. [The paper: FANet explained](#4-the-paper-fanet-explained)
5. [This implementation](#5-this-implementation)
6. [Setup](#6-setup)
7. [Getting Kvasir-SEG](#7-getting-kvasir-seg)
8. [Training, testing, refinement](#8-training-testing-refinement)
9. [Your own dataset](#9-your-own-dataset)
10. [Results](#10-results)
11. [PPT outline](#11-ppt-outline)
12. [Viva questions and answers](#12-viva-questions-and-answers)
13. [How the topic was chosen](#13-how-the-topic-was-chosen)
14. [Timeline](#14-timeline)
15. [Glossary](#15-glossary)
16. [References](#16-references)

---

## 1. The assignment, and how this project meets it

The faculty brief (photo: [`brief/finalProjectDeepLearning.jpeg`](brief/finalProjectDeepLearning.jpeg), translated from Hinglish):

> Individual project. Topic: object segmentation and detection, not classification; it must use a CNN.
> Implement an IEEE paper found on Google, from scratch. Prepare a PPT.
> Fairly advanced topic, paper from the last 5 years. Use the research paper's dataset.
> For the PPT, make a small dataset yourself and explain how you generated it.
> (Update, 12 Oct: allowed domains are detection, segmentation, LSTM.)

| Requirement | Met? | How |
|---|---|---|
| Individual | Yes | One person, one model |
| Segmentation / detection, not classification | Yes | Outputs a pixel mask per image. Bounding boxes are derived from the mask as a detection view (§5.5) |
| Uses a CNN | Yes | Convolutional encoder–decoder (residual blocks, SE, transposed convs) |
| IEEE paper | Yes | IEEE Transactions on Neural Networks and Learning Systems, a top IEEE journal |
| Last 5 years | Yes | Published 2023 (online 2022) |
| "Fairly advanced" | Yes | Not a plain U-Net: a cross-epoch mask memory, hard-attention MixPool blocks, test-time iterative refinement |
| From scratch | Yes | Every layer written with `nn.Conv2d`, `nn.BatchNorm2d` etc. No model zoo, no pretrained weights, no `segmentation_models_pytorch`. The authors' code was only read to check details |
| Paper's dataset | Yes | Kvasir-SEG, same loss, same 880/120 split. Input 256×256 as in the official code (the paper reports 512×512; `--size 512` reproduces that) |
| Own small dataset, explained | Yes | Procedural synthetic leaf-spot generator (exact masks, logged parameters) and/or 40–60 phone photos annotated in Labelme (§9) |
| PPT | Planned | Outline in §11 |

**What "from scratch" means here:** the model, data loader, augmentation, loss, training loop, metrics and evaluation are written by me in PyTorch. Using `torchvision.models` or the authors' repository as-is would not count.

---

## 2. The problem: why polyp segmentation

- **Colorectal cancer** is among the most common and deadly cancers worldwide. Most cases begin as **polyps**: small growths on the inner wall of the colon. Some polyps (adenomas) slowly turn cancerous.
- In a **colonoscopy**, a doctor guides a camera through the colon and removes polyps they see. But polyps are missed: studies report miss rates for adenomas around **one in four** (meta-analysis by Zhao et al., *Gastroenterology* 2019). Each **1% rise in the adenoma detection rate lowers the later cancer risk by about 3%** (Corley et al., *NEJM* 2014). *Check both figures against the papers before putting them in the PPT.*
- So a model that **outlines the polyp pixel by pixel** in the camera image can act as a second pair of eyes. A mask is more useful than a yes/no label: it shows where the polyp is, how big it is and where its edges are, which matters for removing it.
- Why it is hard: polyps vary a lot in size, shape and colour; they can be flat and blend into the wall; images contain glare, bubbles, motion blur and instruments.

**Framing for the PPT:** decision support / proof of concept, never "diagnosis".

**Transfer story:** the same model, fine-tuned on photos of leaves with disease spots, segments the spots. Same task (find irregular blobs on a textured surface), different domain. That is the "own dataset" part of the brief.

---

## 3. Background you need

Skip what you already know. Everything here appears in the code.

### 3.1 Classification vs detection vs segmentation

| Task | Output for one image | Example |
|---|---|---|
| Classification | one label | "polyp present" |
| Detection | boxes + labels | a rectangle around the polyp |
| Semantic segmentation | a label **for every pixel** | a mask: 1 = polyp pixel, 0 = background |

FANet does **binary semantic segmentation**: the output is an H×W map of probabilities, thresholded at 0.5 into a 0/1 mask. A detection-style output (boxes) is obtained by drawing a box around each connected blob of the mask.

### 3.2 CNN building blocks

- **Convolution (`Conv2d`)**: slides small learned filters (here 3×3) over the image; each filter detects a local pattern (edge, texture, colour change). Stacking layers builds larger, more abstract patterns.
- **Batch normalisation (`BatchNorm2d`)**: normalises each channel over the batch to mean 0 / variance 1, then rescales with learned parameters. Makes training faster and more stable.
- **ReLU**: `max(0, x)`. The non-linearity that lets the network learn non-linear functions.
- **Max pooling (2×2)**: keeps the maximum of each 2×2 window → halves height and width. Gives a wider view per pixel at lower cost.
- **Transposed convolution (`ConvTranspose2d`, kernel 4, stride 2, padding 1)**: learned upsampling; doubles height and width.
- **1×1 convolution**: mixes channels at each pixel without looking at neighbours. Used to change channel counts and for the final output layer.
- **Sigmoid**: squashes any number into (0, 1), i.e. a probability.

### 3.3 Residual block

```
x ──► conv3×3 ─► BN ─► ReLU ─► conv3×3 ─► BN ──►(+)──► ReLU ──► out
│                                                ▲
└──────────► conv1×1 ─► BN ─► SE ────────────────┘   (shortcut)
```

The block learns a *correction* to its input instead of a whole new mapping. The shortcut lets gradients flow straight back, so deeper networks train well (He et al., ResNet). The 1×1 conv on the shortcut makes the channel counts match so the two paths can be added.

### 3.4 Squeeze-and-excitation (SE)

Channel attention (Hu et al., SENet). For a feature map with C channels:
1. **Squeeze:** average each channel over all pixels → C numbers.
2. **Excite:** a tiny 2-layer MLP + sigmoid → C weights in (0, 1).
3. Multiply each channel by its weight.

The network learns, per image, which channels to boost or suppress.

### 3.5 Encoder–decoder (U-Net shape) and skip connections

```
input 256² ─ enc1 ─────────────────────────────────────── dec4 ─ output 256²
               └ 128² enc2 ─────────────────────── dec3 ┘
                      └ 64² enc3 ─────────── dec2 ┘
                              └ 32² enc4 ─ dec1 ┘
                                     └ 16² (bottom)
           (── = skip connection: encoder features copied to the decoder)
```

- **Encoder:** convolutions + pooling. Resolution goes down, channels go up. Learns *what* is in the image.
- **Decoder:** upsampling + convolutions. Resolution goes back up. Learns *where* exactly.
- **Skip connections:** the decoder at each scale also receives the encoder's features of the same scale (concatenated). Fine detail lost by pooling (sharp edges) is restored.

### 3.6 Attention: soft vs hard

*Attention* = weighting parts of the input by importance.
- **Soft attention:** multiply by learned weights in [0, 1] (SE is soft channel attention). Differentiable.
- **Hard attention:** multiply by a 0/1 mask: keep these pixels, zero the rest. Not differentiable through the mask itself.

FANet uses **hard spatial attention**, and the mask comes from the network's **own earlier prediction**.

### 3.7 Loss: BCE + Dice

- **Binary cross-entropy (BCE):** per-pixel log loss, averaged over pixels. Smooth, stable gradients. But a polyp may cover only 5–20% of the image, so BCE is dominated by background pixels.
- **Dice loss:** `1 − 2|P∩G| / (|P| + |G|)` with soft probabilities P and ground truth G. Measures overlap of whole regions, so it does not care how much background there is.
- **Used here (as in the official code):** `0.5·BCE + 0.5·Dice`. BCE for stable training, Dice to optimise what we measure.

### 3.8 Metrics

Computed **per image** on the thresholded mask, then **averaged over images** (as the official test script does). TP/FP/FN/TN count pixels.

| Metric | Formula | Meaning |
|---|---|---|
| **Dice** (= F1) | 2TP / (2TP+FP+FN) | Overlap. The headline number in polyp papers |
| **Jaccard / IoU** (mIoU when averaged) | TP / (TP+FP+FN) | Stricter overlap; always ≤ Dice |
| Precision | TP / (TP+FP) | Of what I marked, how much is really polyp |
| Recall (sensitivity) | TP / (TP+FN) | Of the real polyp, how much I found. Clinically the most important: a missed polyp is the dangerous error |
| Specificity | TN / (TN+FP) | Of the background, how much I correctly left alone |
| Accuracy | (TP+TN) / all | Misleading here: predicting "all background" already scores ~0.85 |
| F2 | 5PR / (4P+R) | F-score that weights recall more than precision |
| FPS | images / second | Speed; matters for real-time use during a colonoscopy |

Dice and IoU are linked: `IoU = Dice / (2 − Dice)`, but only per image; averages over images do not follow the formula exactly.

### 3.9 Otsu thresholding

A classic, non-learning method to split a greyscale image into two classes: it tries every threshold t in 0..255 and picks the one that maximises the **between-class variance** of the histogram, i.e. the cleanest split into "dark" and "bright". FANet uses it only to make a rough **starting mask** for each image before the network has predicted anything.

---

## 4. The paper: FANet explained

### 4.1 The idea in one paragraph

A normal segmentation network sees each training image many times (once per epoch) but **forgets what it predicted last time**. FANet keeps a **memory**: for every training image, the mask the network predicted for it in an earlier epoch. Next time the image comes round, that mask is fed back in and used as **hard attention** inside every encoder and decoder stage: "look here first". At **test time**, the same trick allows **iterative refinement**: predict, feed the prediction back, predict again, a few times.

### 4.2 The paper's claims

From the abstract: "existing methods do not use the information from different learning epochs effectively"; FANet "unifies the previous epoch mask with the feature map of the current training epoch"; the previous mask provides "a hard attention to the learned feature maps at different convolutional layers"; the network "allows to rectify the predictions in an iterative fashion during the test time". Evaluated on **seven** public biomedical datasets: Kvasir-SEG, CVC-ClinicDB (polyps), DRIVE, CHASE-DB1 (retinal vessels), 2018 Data Science Bowl (nuclei), ISIC 2018 (skin lesions), EM (cell membranes). This project reproduces **Kvasir-SEG only**.

### 4.3 Architecture

Input: image (3×256×256) **and** previous mask (1×256×256).

```
 image ─► E1 ─► E2 ─► E3 ─► E4 ─► D1 ─► D2 ─► D3 ─► D4 ─► concat(prev mask) ─► 1×1 conv ─► logits
           │     │     │     └─────┘ skip  │     │     │
           │     │     └───────────────────┘     │     │
           │     └───────────────────────────────┘     │
           └───────────────────────────────────────────┘
 prev mask ─► fed into the MixPool block of every E and D (max-pooled to that block's size)
```

Every **encoder block** (E): ResidualBlock → ResidualBlock → **MixPool** → MaxPool 2×2.
Every **decoder block** (D): TransposedConv ×2 up → concat skip → ResidualBlock → ResidualBlock → **MixPool**.

Shapes for one 256×256 image (exactly what `src/model.py` produces):

| Stage | Output | Skip passed to decoder |
|---|---|---|
| E1 (3→32) | 32×128×128 | 32×256×256 |
| E2 (32→64) | 64×64×64 | 64×128×128 |
| E3 (64→128) | 128×32×32 | 128×64×64 |
| E4 (128→256) | 256×16×16 | 256×32×32 |
| D1 (256→128) | 128×32×32 | |
| D2 (128→64) | 64×64×64 | |
| D3 (64→32) | 32×128×128 | |
| D4 (32→16) | 16×256×256 | |
| concat prev mask | 17×256×256 | |
| 1×1 conv | **1×256×256 logits** | |

**Parameters: 7,720,266** (counted by `python -m src.model`).

### 4.4 The MixPool block (the heart of FANet)

```
            ┌─► fmask head: conv3×3-BN-ReLU-conv1×1-sigmoid ─► >0.5 ─► F (0/1)
            │                                                          │
 features x ┤        prev mask M ─► maxpool to x's size ─────────────►OR──► A (0/1)
            │                                                               │
            ├─────────────────────────► x · A ─► conv3×3-BN-ReLU ─► half 1 ─┐
            │                                                               ├─► concat ─► out
            └─────────────────────────► x ─────► conv3×3-BN-ReLU ─► half 2 ─┘
```

1. **fmask head** guesses a mask from the current features, thresholded to 0/1.
2. The **previous mask** is max-pooled down to the feature size (a cell is 1 if any pixel in it was 1, so small polyps survive).
3. **Attention = fmask OR previous mask.** Features outside it are zeroed (hard attention).
4. The masked features and the **unmasked** features go through separate convs, and the two halves are concatenated.

Why two branches: if the previous mask is wrong (e.g. the Otsu guess in epoch 1), the unmasked branch still carries the full information, so a bad mask cannot destroy the prediction. The network learns how much to trust each half.

### 4.5 Training with feedback

```
before epoch 1:  memory[i] = Otsu(image i)              for every training image i
each epoch:      for each batch:
                     pred = FANet(image, memory[i])
                     loss = 0.5·BCE + 0.5·Dice ; backprop ; Adam step
                     staged[i] = (sigmoid(pred) > 0.5)
                 if validation loss improved:  save checkpoint ; memory ← staged
```

Details from the official code (`train.py`, `utils.py`):
- The memory starts from **Otsu masks**: grey → 5×5 Gaussian blur → Otsu threshold.
- The memory is **only replaced when validation loss improves**, so it always matches the best model so far. (`--memory-update always` in this repo refreshes it every epoch instead, which is a possible ablation.)
- The validation images keep their own memory, updated by the same rule.
- Hyperparameters (official code): 256×256, Adam lr 1e-4, ReduceLROnPlateau (patience 5), batch 2, up to 500 epochs. **The paper itself** (§IV-A, Table IX) says 100 epochs and 512×512 for Kvasir-SEG. Augmentation: rotate ±35°, horizontal/vertical flip, coarse dropout.

### 4.6 Test-time iterative refinement

```
memory[i] = Otsu(test image i)
repeat K times (official: K = 10):
    pred = FANet(image, memory[i]);  memory[i] = pred > 0.5;  record metrics
```

The official test script reports metrics after every round. In this repo `src/evaluate.py` does the same and writes one row per round to `results.csv`, so you can show whether (and how much) refinement helps.

---

## 5. This implementation

### 5.1 Repository layout

```
README.md                  this file: the full documentation
PLAN.md                    short status + timeline
requirements.txt
brief/                     the faculty brief (photo)
src/
  blocks.py                SqueezeExcite, ResidualBlock, MixPool
  model.py                 EncoderBlock, DecoderBlock, FANet  (python -m src.model prints shapes + params)
  memory.py                MaskMemory (the feedback memory) + Otsu from scratch
  dataset.py               loads images/ + masks/ into RAM, resized; returns (image, mask, index)
  augment.py               invertible flips/rot90 (applied to image, mask AND memory) + photometric
  losses.py                0.5·BCE + 0.5·Dice
  metrics.py               Dice, IoU, precision, recall, specificity, accuracy, F2; boxes from masks
  split.py                 writes train.txt / val.txt / test.txt
  train.py                 training loop with feedback memory; best.pt + log.csv
  evaluate.py              test + iterative refinement; results.csv, strips/, masks/
  make_synthetic.py        own dataset generator (procedural leaf spots, or copy-paste)
  labelme_to_masks.py      Labelme JSON polygons → masks
notebooks/kaggle_fanet.ipynb   everything end to end on a Kaggle T4
dataset/README.md          download instructions
dataset/custom/synthetic_leaf/   60 generated samples (committed)
papers/README.md           paper links (PDFs not committed)
docs/v1-condinst-plan.md   the abandoned first plan
presentation/              the PPT goes here
```

### 5.2 Data flow in one training step

```
dataset[i] ─► image (3,256,256) in [0,1], gt (1,256,256) 0/1, index i
memory.get(i) ─► prev (1,256,256) 0/1
augment: same random flip/rot90 on image, gt, prev ; brightness/contrast/cut-out on image only
model(image, prev) ─► logits ─► loss(logits, gt) ─► backward ─► Adam
sigmoid(logits) ─► undo flip/rot90 ─► memory.stage(i, pred)
```

### 5.3 Deviations from the official code, and why

| Official code | Here | Reason |
|---|---|---|
| Rotates (±35°) / flips the image and ground truth but **not** the memory mask, and stores predictions made on the rotated image | Default `--memory-aug official` does exactly the same. `--memory-aug aligned` moves the memory too (flips + 90° steps, prediction un-rotated before storing) | We first used `aligned`, expecting it to be better. It made the model copy its memory and fail from an Otsu start (§5.4, point 4), so the official behaviour is the default |
| Memory stored as run-length strings, loader order fixed (`shuffle=False`) to keep images matched to their masks | Memory is a tensor indexed by the dataset index returned with each sample | Simpler, and allows shuffling every epoch |
| Batch 2, 500 epochs | Defaults batch 8, 200 epochs, early stop after 40 without improvement | Fits one Kaggle session. Use `--batch 2 --epochs 500 --early-stop 0` to match exactly |
| `sigmoid` + `binary_cross_entropy` | `binary_cross_entropy_with_logits` | Same value, numerically safer |
| Checkpoint selected on the test images (val = test) | Same by default (comparable to the paper); `python -m src.split --val 80` holds out a separate validation set | Selecting on test data is slightly optimistic; mention it honestly in the viva |
| CUDA-only (`torch.cuda.FloatTensor`) | Runs on CUDA, Apple MPS or CPU | Testing on a laptop |

### 5.4 Observations worth mentioning (found while implementing)

1. **The fmask head never learns.** Its output is thresholded with `> 0.5`, which has zero gradient, so the 3×3 and 1×1 convs inside every MixPool's fmask head receive **no gradient** and keep their random initial weights (verified: 48 parameter tensors, 982,088 parameters, ≈13% of the model, have `grad = None` after `backward()`). Only their BatchNorm running statistics change. In effect the fmask is a fixed random gate on the features; the learned part of the attention is the previous mask. A possible improvement: a straight-through estimator or soft (sigmoid) gating. This is a good "I read the code critically" point.
2. **SE with a 1-unit bottleneck.** The official ResidualBlock builds SE with `reduction = out_channels`, so the hidden layer has exactly one unit. Copied as-is here for faithfulness.
3. **Otsu on colonoscopy images** picks the bright regions (glare, lit mucosa), not specifically polyps: on our 120 test images it marks 59.6% of each image on average, while polyps cover 14.2%. It is a poor starting mask.
4. **The "misaligned memory" in the official code is doing real work.** Our first run (`runs/kvasir`, `--memory-aug aligned`, 256×256) kept the memory exactly aligned with every flip and rotation. Its test Dice during training was 0.844, but that number uses the model's own earlier predictions as memory. Started from Otsu, as the official test script does, it got Dice 0.536 after round 1 and 0.684 after 10 rounds. Feeding the same checkpoint different starting masks (one pass, 120 test images) shows why:

   | Starting memory | Dice | Precision | Recall |
   |---|---|---|---|
   | Otsu (official test start) | 0.536 | 0.440 | 0.955 |
   | all zeros | 0.517 | 0.965 | 0.415 |
   | all ones | 0.383 | 0.267 | 0.993 |
   | its own training-time memory | 0.848 | 0.886 | 0.881 |
   | ground truth (oracle) | 0.958 | 0.971 | 0.956 |

   The model largely **copies its memory**: give it nothing and recall falls to 0.41, give it everything and recall is 0.99. With perfectly aligned memory, copying is always rewarded. In the official code about two-thirds of training samples are rotated or flipped while their memory is not, so the memory is often wrong and the model must learn to check it against the image. That is why `--memory-aug official` is now the default; `runs/kvasir_official` tests it.
5. **With the official augmentation, the model is robust to an empty memory but still pulled by an over-full one.** Same probe on `runs/kvasir_official` (`python -m src.memory_probe`), one pass:

   | Starting memory | aligned (first run) | official (final) |
   |---|---|---|
   | Otsu | 0.536 | 0.615 |
   | all zeros | 0.517 | **0.828** |
   | all ones | 0.383 | 0.518 |
   | own training-time memory | 0.848 | 0.908 |
   | ground truth | 0.958 | 0.935 |

   An empty mask is now a good start, while Otsu (which marks ~60% of the image) still makes round 1 over-segment, and refinement only slowly trims it: 0.615 → 0.842 in 10 rounds. Starting from zeros instead (`evaluate.py --start zeros`) gives 0.829 → 0.900 in 10 rounds, above the paper's 0.880. This changes the test procedure, not the model, so the official-protocol number (0.842) stays the headline reproduction result.

### 5.5 Detection view: boxes from masks

`metrics.BoxAverager` labels each connected blob (8-connectivity, written from scratch with BFS) of the predicted and true masks, draws a box around each blob (ignoring blobs under 20 pixels), matches predicted to true boxes greedily by IoU ≥ 0.5, and reports **box precision, box recall and mean box IoU**. Kvasir-SEG also ships `kavsir_bboxes.json` (boxes derived from its masks), so this is consistent with the dataset's own boxes. This answers "where is the detection part?".

### 5.6 Verified so far (CPU, this container, no GPU)

- `python -m src.model`: output 1×256×256 per image, 7,720,266 parameters.
- Augmentation round trip: `invert_geometric(apply_geometric(x)) == x` exactly.
- Full pipeline on 60 synthetic leaf images at 128×128, 12 epochs, ~9 s/epoch on CPU: validation Dice rose from 0.08 to ~0.85; `evaluate.py` produced metrics per refinement round, strips and masks. So the code runs end to end; real numbers come from the Kaggle run.

---

## 6. Setup

**Kaggle from the terminal (used for the ablation and 512 runs).** With the Kaggle CLI logged in, [`kaggle/offload.sh`](kaggle/offload.sh) uploads the current `src/` and runs one training + evaluation on a free GPU as a private script notebook, then downloads the results:
```bash
kaggle/offload.sh push kvasir-nofb t4 "--epochs 200 --batch 8 --no-feedback" 1   # name, GPU, train args, eval rounds
kaggle/offload.sh status kvasir-nofb
kaggle/offload.sh pull kvasir-nofb                                                 # -> runs/kvasir_nofb/
```
It trains on the private dataset `kvasir-seg-fanet-split`: our exact Kvasir-SEG copy with its `train.txt` / `test.txt`, so the 120 test images are the same as on the laptop. Kaggle's free GPUs are a T4 or a P100 (16 GB each); two sessions can run at once.

**Kaggle notebook (by hand).** Open [`notebooks/kaggle_fanet.ipynb`](notebooks/kaggle_fanet.ipynb) in Kaggle (*File → Import Notebook*).
- Settings: Accelerator **GPU T4 x1**, Internet **On** (needs a phone-verified account).
- The repo is private, so the notebook clones it with a token: create a GitHub fine-grained token (read-only, this repo only), add it in Kaggle under **Add-ons → Secrets** as `GITHUB_TOKEN`.
- Free quota: about 30 GPU-hours a week, 12 hours per session.

**Laptop (RTX 5050 8 GB, or CPU for small tests).**
```bash
git clone https://github.com/Chaitanya-666/DLproject.git && cd DLproject
python -m venv .venv && source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt                        # for CUDA, install torch from pytorch.org first
python -m src.model                                    # prints shapes and parameter count
```
The RTX 5050 (Blackwell) needs a CUDA 12.8 build of PyTorch: `pip install torch --index-url https://download.pytorch.org/whl/cu128`. At 256×256, batch 8 uses about 4 GB and an epoch takes 35–55 s (the laptop GPU slows down when it reaches ~89 °C). At 512×512 only batch 4 fits in 8 GB, so the 512 run went to Kaggle.

All scripts are run from the repo root as modules: `python -m src.<script> --help`.

---

## 7. Getting Kvasir-SEG

- **What it is:** 1000 colonoscopy images of polyps, each with a pixel mask, from Vestre Viken Health Trust, Norway. Masks were drawn by a medical doctor and verified by an experienced gastroenterologist. Images vary in size (roughly 332×487 up to 1920×1072); we resize everything to 256×256. About 46 MB. Same group as FANet's authors (Simula, Norway).
- **Download:** https://datasets.simula.no/kvasir-seg/ (direct: https://datasets.simula.no/downloads/kvasir-seg.zip), or a Kaggle copy via *Add Data* → search "Kvasir-SEG".
- **Layout after unzip:**
  ```
  Kvasir-SEG/
    images/   1000 .jpg
    masks/    1000 .jpg   (same names; white = polyp)
    kavsir_bboxes.json    (boxes; the typo is in the original)
  ```
- **Split:** the authors' code reads `train.txt` (880) and `val.txt` (120) and reports test numbers on the 120. If your copy has no split files, make a fixed one:
  ```bash
  python -m src.split --data data/Kvasir-SEG              # 880 train / 120 test, seed 42
  python -m src.split --data data/Kvasir-SEG --val 80     # 800 / 80 / 120: separate validation set
  ```
  Our split is not guaranteed to be the same 120 images as the paper's, so expect small differences in the numbers. Check the paper's experimental-setup section for its exact protocol and state it on the results slide.
- Masks are JPEGs, so their edges contain grey values; the loader thresholds them at 127.

---

## 8. Training, testing, refinement

```bash
# sanity check (2 epochs, 20 batches each): catches bugs in a minute
python -m src.train --data data/Kvasir-SEG --out runs/sanity --epochs 2 --max-batches 20

# full training
python -m src.train --data data/Kvasir-SEG --out runs/kvasir
#   --batch 8 --lr 1e-4 --epochs 200 --early-stop 40 --size 256      (defaults)
#   --memory-update always     ablation: refresh memory every epoch
#   --no-feedback              ablation: memory stays all zeros (no previous mask ever fed back)
#   --batch 2 --epochs 500 --early-stop 0                              official settings

# test with 10 refinement rounds (official setting)
python -m src.evaluate --ckpt runs/kvasir/best.pt --data data/Kvasir-SEG --split test --iters 10

# predict on any folder of images (no ground truth)
python -m src.evaluate --ckpt runs/kvasir/best.pt --images some_folder/
```

**Outputs:**
- `runs/kvasir/log.csv`: per epoch train/val loss, Dice, IoU, learning rate, time, whether saved.
- `runs/kvasir/best.pt`: weights + both memories + settings.
- `runs/kvasir/eval_test/results.csv`: one row per refinement round with all metrics, box metrics and FPS.
- `runs/kvasir/eval_test/strips/*.png`: image | ground truth | Otsu start | round 1 | round 2 | … (blue overlay). Ready-made PPT figures.
- `runs/kvasir/eval_test/masks/*.png`: final masks.

**What to expect:** Dice should climb above 0.5 within the first ~10 epochs and plateau later. If validation loss stops improving, the learning rate drops ×0.1 after 5 epochs (ReduceLROnPlateau). One epoch of 880 images at batch 8 should take well under a minute on a T4.

**Ideas for extra experiments (good for the PPT):**
- Refinement rounds 1 vs 10 (already in `results.csv`).
- `--memory-update on-improve` vs `always`.
- Remove the feedback: `--no-feedback` keeps the memory all zeros, so MixPool only has its own (untrained) fmask gate → shows what feedback adds. `evaluate.py` reads the flag from the checkpoint and tests the same way.

---

## 9. Your own dataset

The brief asks for a small dataset you made yourself, and an explanation of **how it was generated**. Colonoscopy images cannot be collected at home, so we keep the **task** (segment irregular blobs on a textured surface) and change the **subject** to **disease spots on leaves**. Two ways, which can be combined.

### 9.1 Synthetic, generated by script (already in the repo)

```bash
python -m src.make_synthetic procedural --out dataset/custom/synthetic_leaf --n 60 --seed 0
python -m src.split --data dataset/custom/synthetic_leaf --test 0.2
```

How each image is generated (`src/make_synthetic.py`, `procedural_sample`):
1. Random plain background colour.
2. A leaf: an ellipse in a random shade of green, with a midrib and side veins.
3. 1–4 **spots**: each is an irregular blob, a circle whose radius wobbles with angle (sum of sines with random phases plus noise), drawn in a random brown with a yellow halo ring, like real leaf-spot disease. The same polygon is filled white on the mask, and both are clipped to the leaf.
4. Camera realism: random Gaussian blur, a left-to-right lighting gradient, Gaussian sensor noise.

Because we drew the spots, the **masks are exact, with no annotation needed**. Every random choice is saved in `generation_log.csv` (spot positions and radii, colours) and boxes in `bboxes.json`; the same `--seed` regenerates the identical dataset. That is the explanation for the slide.

### 9.2 Real photos annotated by hand

1. Take **40–60 phone photos** of leaves with spots/blight (garden, park, vegetable market). Vary the background, lighting and distance. Note the date, phone and place: that goes on the slide.
2. Install Labelme on your laptop: `pip install labelme`, run `labelme`, open the photo folder.
3. For each photo: *Create Polygons*, click around every spot, label it `spot`, save. Labelme writes a `.json` next to each photo. (Expect 1–3 minutes per photo; record the total time.)
4. Convert:
   ```bash
   python -m src.labelme_to_masks --src raw_photos/ --out dataset/custom/leaf
   python -m src.split --data dataset/custom/leaf --test 0.2
   ```
5. Optional: **copy-paste augmentation** to multiply the data: cut your annotated spots out and paste them onto clean leaf photos:
   ```bash
   python -m src.make_synthetic paste --objects dataset/custom/leaf \
       --backgrounds dataset/custom/backgrounds --out dataset/custom/leaf_paste --n 100
   ```

### 9.3 Using it

```bash
# How does the polyp model do on leaves before fine-tuning? (expected: badly; a domain gap)
python -m src.evaluate --ckpt runs/kvasir/best.pt --data dataset/custom/synthetic_leaf --split test --out runs/leaf_before
# Fine-tune from the Kvasir weights (transfer learning)
python -m src.train --data dataset/custom/synthetic_leaf --out runs/leaf --init runs/kvasir/best.pt --epochs 60 --lr 5e-5
python -m src.evaluate --ckpt runs/leaf/best.pt --data dataset/custom/synthetic_leaf --split test
```

Slide content: how many images, how they were made (script or photos + Labelme), time spent, spot-size statistics (`mask_fraction` column in `generation_log.csv`), split, before/after strips.

---

## 10. Results

All numbers: 120 Kvasir-SEG test images, per-image scores averaged (as the official test script does), 10 refinement rounds. Our own rows are 256×256, batch 8, trained on the laptop RTX 5050 (19 Oct 2026). They come from `runs/<run>/eval_test*/results.csv`; regenerate with `python -m src.evaluate ... --iters 10`.

| Kvasir-SEG test (120 images) | Dice | mIoU | Recall | Precision | F2 | FPS |
|---|---|---|---|---|---|---|
| FANet, paper (Table II/IX, 512×512, GTX 1050 Ti) | 0.8803 | 0.8153 | 0.9058 | 0.9005 | 0.8872 | 68.18 |
| Baseline without MixPool, paper (Table IX, B1) | 0.8516 | 0.7732 | 0.8835 | 0.8710 | 0.8614 | 104.20 |
| **FANet, mine, official protocol** (Otsu start, round 10) | **0.8422** | **0.7790** | 0.9341 | 0.8345 | 0.8684 | 87 |
| FANet, mine, Otsu start, round 1 | 0.6148 | 0.5115 | 0.9653 | 0.5298 | 0.7291 | |
| **FANet, mine, empty start** (`--start zeros`, round 10) | **0.8999** | **0.8414** | 0.9001 | 0.9346 | 0.8977 | 88 |
| FANet, mine, 512×512 (Kaggle P100) | *running* | | | | | |
| No feedback (`--no-feedback`), mine | *running (Kaggle T4)* | | | | | |
| First attempt, `--memory-aug aligned`, Otsu start, round 10 | 0.6835 | 0.5887 | 0.9578 | 0.6191 | 0.7749 | |

FPS: the round-10 figure from `results.csv`, RTX 5050 laptop GPU, batch 8 (round 1 is slower because it includes CUDA warm-up).

**Detection view** (boxes from blobs, IoU ≥ 0.5, `metrics.BoxAverager`): official protocol box precision 0.685, box recall 0.800, mean box IoU 0.881; empty start box precision 0.836, box recall 0.896.

**How to read this.** Under the paper's own test protocol we get Dice 0.842, 0.038 below the paper. Likely reasons: half the paper's input resolution (the 512 run tests this), batch 8 instead of 2, and a test split that may hold different images. Starting refinement from an empty mask instead of Otsu gives 0.900 with the same weights. That is a change to the test procedure, not to the model, so it is reported separately from the reproduction (§5.4, point 5). Both rows pick the checkpoint on the test images, as the authors' code does, so both are slightly optimistic.

| Own dataset: synthetic leaf spots (12 test images) | Dice | mIoU | Box recall |
|---|---|---|---|
| Kvasir model, no fine-tuning (best of 3 rounds) | 0.474 | 0.382 | 0.364 |
| After fine-tuning from the Kvasir weights, 60 epochs | 0.984 | 0.969 | 0.909 |

The synthetic leaves are much easier than real photos (clean shapes, plain backgrounds); real Labelme-annotated photos are the next step (§9.2).

---

## 11. PPT outline

About 12 slides:
1. Title, name, roll number, paper citation.
2. Problem: colorectal cancer, polyps, miss rate, why masks help (§2).
3. Task: segmentation vs classification vs detection (§3.1) with a Kvasir image + mask.
4. The paper: FANet, IEEE TNNLS 2023, the idea in one sentence (§4.1).
5. Architecture diagram (§4.3), shapes table, 7.7M parameters.
6. MixPool block (§4.4), the key slide.
7. Training with feedback and test-time refinement (§4.5, §4.6).
8. My implementation: code structure (§5.1), from-scratch list, deviations and the fmask observation (§5.3–5.4).
9. Dataset: Kvasir-SEG, split, preprocessing, augmentation.
10. Results: table vs paper, learning curves, refinement rounds.
11. Qualitative: strips (good cases and failure cases: tiny/flat polyps, glare).
12. Own dataset: how it was generated, examples, before/after fine-tuning.
13. Conclusion and future work (soft fmask, video, other datasets).

---

## 12. Viva questions and answers

**Why is this segmentation and not classification?** The output is a label for every pixel (a 256×256 mask), not one label per image.

**Where is the CNN?** The whole network is convolutional: residual blocks of 3×3 convs, 1×1 convs, transposed convs. There are no fully connected layers except the tiny SE MLP.

**What is new in FANet compared with U-Net?** (1) A per-image memory of the previous prediction, fed back as input. (2) MixPool blocks that use it as hard spatial attention at every scale. (3) Iterative refinement at test time.

**Where does the very first mask come from?** Otsu thresholding of the blurred greyscale image, a classical method with no learning.

**Isn't using your own prediction as input cheating?** No. Ground truth is never fed in. The memory only contains the model's own past predictions (and Otsu at the start), and the same is done at test time.

**What if the previous mask is wrong?** MixPool has a second branch on the unmasked features, so information outside the mask is never lost. The network learns to rely on it when the mask is unhelpful.

**Why is the memory only updated when validation loss improves?** So the memory always comes from the best model so far, and a bad epoch does not poison the next epoch's input.

**Why BCE + Dice?** BCE gives smooth, per-pixel gradients but is dominated by background; Dice measures region overlap and handles the imbalance. The sum gets both.

**Why Dice and not accuracy?** Polyps are small, so accuracy is high even for an empty prediction. Dice only rewards overlap with the polyp.

**Dice vs IoU?** Both measure overlap. IoU = TP/(TP+FP+FN) is stricter; Dice = 2TP/(2TP+FP+FN). Per image, IoU = Dice/(2−Dice).

**What does SE do?** Learns per-channel weights from globally pooled features, so it boosts useful channels and damps others (channel attention).

**Why skip connections?** Pooling loses fine spatial detail; skips bring the encoder's high-resolution features to the decoder so edges are sharp.

**Why transposed convolution and not plain resize?** It is a learned upsampling: the network learns how to fill in detail.

**How did you handle augmentation with the memory?** Like the official code: rotation (±35°) and flips move the image and ground truth, not the memory mask. I first "fixed" this by moving the memory too (`--memory-aug aligned`), but then the model learned to copy its memory: from an Otsu start its test Dice was 0.54, against 0.85 with a good memory. The misalignment forces the model to check the memory against the image, so it acts as a regulariser (§5.4, point 4).

**Did you find anything odd in the paper's design?** Yes: the fmask head's output is thresholded with `> 0.5`, so no gradient reaches its convs; about 13% of the parameters never train. The useful attention comes from the previous mask.

**What Dice did you get, and why is it below the paper?** 0.842 with the paper's test protocol (Otsu start, 10 refinement rounds) at 256×256, against 0.880 in the paper at 512×512. Reasons: half the resolution, batch 8 instead of 2, and possibly a different set of 120 test images. The 512×512 run checks the resolution part.

**How did you get 0.900?** Same weights, different test-time start: an empty mask instead of Otsu. Otsu marks about 60% of each image, so the first prediction over-segments and refinement trims it only slowly. An empty start avoids that. It is our variant of the test procedure, so the headline reproduction number stays 0.842.

**How do you get detection from segmentation?** Connected components of the mask → one bounding box per blob → match to true boxes by IoU ≥ 0.5 → box precision/recall.

**How many parameters, and how fast?** 7.72M parameters. FPS is measured in `evaluate.py` (fill in from the T4 run).

**What did you write yourself vs reuse?** Everything in `src/` is mine, on top of PyTorch primitives. No pretrained weights or model libraries. The authors' code was read to check the architecture and training rules.

**How was your own dataset made?** §9: a seeded script that draws leaves with irregular brown spots (exact masks, every parameter logged), and/or phone photos annotated with polygons in Labelme.

**Limitations?** One dataset; split may differ from the paper's; still images only (no video); synthetic leaves are simpler than real ones; the model is a proof of concept, not a medical device.

---

## 13. How the topic was chosen

Full comparison: the "DL Mini-Project: Candidate Papers" doc. In short:
- Hard rules: IEEE, 2021 onwards, segmentation/detection (or LSTM), CNN, public dataset small enough for a Kaggle T4, trainable in a few sessions.
- First plan, **CondInst** (instance segmentation, COCO): dropped, since COCO (118k images, 8 GPUs) cannot be reproduced on one T4. See [`docs/v1-condinst-plan.md`](docs/v1-condinst-plan.md).
- Next, **ColonSegNet** (Jha et al., IEEE Access 2021, detection + segmentation on Kvasir-SEG): dropped on 13 Oct because March 2021 is outside a strict 5-year window.
- **FANet** (IEEE TNNLS 2023): strongest venue, safely inside the window, same dataset and pipeline. Registered 13 Oct, row 29; nobody else on the sheet has FANet or a polyp topic.
- Other shortlisted: MALUNet (skin lesions), NanoNet (too small), PredRNN (LSTM), SA-UNet (2020/21).

---

## 14. Timeline

| When | What | Status |
|---|---|---|
| Tue 13 Oct | Register topic; code scaffold + this README | Done |
| Wed 14 – Fri 16 Oct | Read the paper's method and experiments (note its Kvasir-SEG table and protocol); set up the Kaggle notebook; sanity run | |
| Sat 17 – Sun 18 Oct | Full training run. **Target: baseline Dice by Sunday** | |
| Mon 19 – Sun 25 Oct (DL viva week) | Evaluation, refinement rounds, ablation; own dataset (synthetic + photos), fine-tune | |
| Mon 26 – Sat 31 Oct | PPT, figures, rehearse. **Project complete by Sat 31 Oct** | |
| 1 – 7 Nov | Buffer before Diwali | |

---

## 15. Glossary

- **Epoch:** one pass over all training images.
- **Batch:** images processed together in one step (here 8).
- **Logits:** raw network outputs before sigmoid.
- **Mask:** image of 0/1 values, 1 = object pixel.
- **Feature map:** a (channels × height × width) tensor inside the network.
- **Hard attention:** multiply features by a 0/1 mask.
- **Memory (FANet):** the stored previous predicted mask for each image.
- **Refinement round:** one more pass at test time, using the last prediction as the memory.
- **Ablation:** removing one component to measure its contribution.
- **Fine-tuning / transfer learning:** start from weights trained on one dataset, continue training on another.
- **Domain gap:** the drop in accuracy when test images look different from training images.
- **ReduceLROnPlateau:** cut the learning rate when validation loss stops improving.

---

## 16. References

1. Tomar N. K. et al., *FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation*, IEEE TNNLS 34(11), 2023. DOI 10.1109/TNNLS.2022.3159394. arXiv 2103.17235. Code: https://github.com/nikhilroxtomar/FANet
2. Jha D. et al., *Kvasir-SEG: A Segmented Polyp Dataset*, MMM 2020. arXiv 1911.07069. https://datasets.simula.no/kvasir-seg/
3. Ronneberger O. et al., *U-Net: Convolutional Networks for Biomedical Image Segmentation*, MICCAI 2015.
4. He K. et al., *Deep Residual Learning for Image Recognition*, CVPR 2016.
5. Hu J. et al., *Squeeze-and-Excitation Networks*, CVPR 2018.
6. Otsu N., *A Threshold Selection Method from Gray-Level Histograms*, IEEE Trans. SMC, 1979.
7. Corley D. A. et al., *Adenoma Detection Rate and Risk of Colorectal Cancer and Death*, NEJM 2014.
8. Zhao S. et al., *Magnitude, Risk Factors, and Factors Associated With Adenoma Miss Rate of Tandem Colonoscopy*, Gastroenterology 2019.
9. Jha D. et al., *Real-Time Polyp Detection, Localization and Segmentation in Colonoscopy Using Deep Learning* (ColonSegNet), IEEE Access 2021: the earlier candidate.
