// FANet one-shot exam guide (Deep Learning lab ESE, Thu 19 Nov 2026, Lab 1B).
// Compile:  typst compile FANet_OneShot_Guide.typ
// Every number comes from the DLproject repo (runs/*.csv, docs/report.typ,
// presentation/build_deck.js, README.md) at commit ce2194e.
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#set document(title: "FANet one-shot exam guide", author: "Chaitanya Shinde")
#set page(paper: "a4", margin: (x: 1.9cm, y: 2cm), numbering: "1",
  header: context {
    if counter(page).get().first() > 1 [
      #set text(8pt, fill: luma(120))
      FANet one-shot exam guide #h(1fr) Chaitanya Shinde, 231070066
    ]
  })
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 10.5pt, lang: "en")
#set par(justify: true, leading: 0.62em)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => { pagebreak(weak: true); v(0.2em); it; v(0.3em) }
#show heading: set text(font: "Inter", weight: "bold")
#show heading.where(level: 1): set text(15pt, fill: rgb("#0e3b43"))
#show heading.where(level: 2): set text(11.5pt, fill: rgb("#14545e"))
#show heading.where(level: 3): set text(10.5pt)
#show raw.where(block: true): it => block(fill: luma(243), inset: 7pt, radius: 3pt, width: 100%, text(8.6pt, it))
#show raw.where(block: false): it => box(fill: luma(238), inset: (x: 2pt), outset: (y: 2pt), radius: 2pt, text(9pt, it))
#set table(stroke: 0.4pt + luma(165), inset: 5pt)
#show table.cell.where(y: 0): set text(weight: "bold")
#show figure.caption: set text(size: 9pt)
#show link: set text(fill: rgb("#14545e"))

// ---------------------------------------------------------------- boxes
#let callout(title, bg, accent, body) = block(width: 100%, fill: bg,
  stroke: (left: 3pt + accent), inset: (x: 10pt, y: 7pt), radius: 2pt, above: 0.8em, below: 0.8em)[
  #set par(justify: false)
  #text(font: "Inter", size: 8.5pt, weight: "bold", fill: accent)[#upper(title)] \
  #body
]
#let say(body) = callout("Say this to ma'am", rgb("#fff6e2"), rgb("#b9790a"), body)
#let code(body) = callout("Where in the code", rgb("#e6f2f3"), rgb("#1f6f78"), body)
#let ours(body) = callout("How FANet and our code use it", rgb("#eef1fb"), rgb("#3949ab"), body)
#let key(body) = callout("Remember", rgb("#edf7ea"), rgb("#2e7d32"), body)
#let trap(body) = callout("Careful (honest answer)", rgb("#fdeceb"), rgb("#c0392b"), body)

#let qn = counter("qn")
#let qa(q, a) = {
  qn.step()
  block(breakable: false, below: 0.62em, above: 0.62em)[
    #text(weight: "bold")[Q#context qn.display(). #q] \
    #a
  ]
}
#let fig(path, cap, w: 100%) = figure(image(path, width: w), caption: cap)
#let slide(n, title, shows, sayit) = block(breakable: false, above: 0.9em, below: 0.9em,
  grid(columns: (40%, 1fr), gutter: 10pt,
    [#image("figures/slides/s-" + (if n < 10 { "0" } else { "" }) + str(n) + ".jpg", width: 100%)
     #align(center, text(8pt, fill: luma(100))[Slide #n])],
    [#text(font: "Inter", weight: "bold", size: 9.5pt)[#n. #title] \
     #text(9.5pt)[*Shows:* #shows] \
     #block(fill: rgb("#fff6e2"), inset: 6pt, radius: 2pt, width: 100%, text(9.5pt)[*Say:* _#sayit _])]))

// ---------------------------------------------------------------- title page
#align(center)[
  #v(1.6cm)
  #text(11pt, font: "Inter", fill: luma(90))[DEEP LEARNING LAB · END-SEMESTER EXAM · THU 19 NOV 2026 · BATCH LAB 1B]
  #v(0.7cm)
  #text(26pt, font: "Inter", weight: "bold", fill: rgb("#0e3b43"))[FANet: the one-shot guide]
  #v(0.25cm)
  #text(13.5pt)[Polyp segmentation with a Feedback Attention Network, built from scratch, \ with transfer to leaf-disease spots on my own Roboflow dataset]
  #v(1.1cm)
  #table(columns: (auto, auto), stroke: none, align: (right, left), inset: 4pt,
    [Student:], [*Chaitanya Shinde*],
    [Roll number:], [*231070066*],
    [Programme:], [B.Tech Computer Engineering, Semester VII, 2026-27],
    [Course:], [Deep Learning (individual mini-project)],
    [Base paper:], [N. K. Tomar et al., "FANet: A Feedback Attention Network for \ Improved Biomedical Image Segmentation," _IEEE TNNLS_, vol. 34, no. 11, 2023],
  )
  #v(1cm)
  #block(width: 90%, inset: 12pt, stroke: 0.7pt + rgb("#1f6f78"), radius: 3pt)[
    #set align(left)
    #set par(justify: true)
    *What this is.* One document that lets you explain *everything* about the project after a single careful read: the deep-learning basics from zero, the paper, every block of the model, every line of code that matters, every experiment and number, the custom dataset, the 19 slides and the 10-page report, and 100+ likely viva questions with honest answers.

    *Why you can trust the numbers.* Every number here was checked against the files in the repo (`runs/*/log.csv`, `runs/*/eval_test*/results.csv`, `memory_probe.csv`, `docs/report.typ`, the deck text in `presentation/build_deck.js` and the PPTX). Where the report, the deck and the logs disagree, @sec-incons says so and tells you what to say.

    *The boxes.*
    #box(fill: rgb("#fff6e2"), inset: 3pt)[Say this to ma'am] = a sentence you can say as it is.
    #box(fill: rgb("#e6f2f3"), inset: 3pt)[Where in the code] = real `file:line` references (repo state `ce2194e`).
    #box(fill: rgb("#eef1fb"), inset: 3pt)[How FANet uses it] = theory linked to our model.
    #box(fill: rgb("#fdeceb"), inset: 3pt)[Careful] = a trap and the honest answer.
  ]
  #v(0.6cm)
  #text(9pt, fill: luma(110))[Written Mon 16 Nov 2026 from the `DLproject` repository (read-only). Exam in 3 days.]
]

#pagebreak()
#outline(depth: 2, indent: 1.2em)

// =====================================================================
= Start here <sec-start>

== What the exam is
The ESE for this lab is *project based*. Ma'am will look at your *report* (10 pages, `docs/report.pdf`) and your *slides* (19 slides, `FANet_ChaitanyaShinde_231070066.pptx`) and ask questions. She expects you to know everything in them. This guide follows the report and the slides exactly, and goes deeper so that no follow-up question surprises you.

== Your three-day plan
#table(columns: (auto, 1fr),
  [Day], [What to do],
  [Mon 16 Nov (today)], [Sections 1 to 8: the project on one page, the code map, the theory from zero, the problem, the paper.],
  [Tue 17 Nov], [Sections 9 to 15: architecture, loss and metrics, training, testing, every experiment, the custom dataset, Kaggle.],
  [Wed 18 Nov], [Sections 16 to 19: present the 19 slides out loud once (12 to 15 minutes), then answer the viva bank out loud. Read the inconsistencies section twice.],
  [Thu 19 Nov morning], [Only the cheat sheet (last page) and the "Say this" boxes.],
)

== The project in 60 seconds
#say[My project is polyp segmentation for colorectal cancer screening. I implemented the IEEE TNNLS 2023 paper *FANet, a Feedback Attention Network*, from scratch in PyTorch, with no pretrained weights and no model libraries. FANet is a U-Net-style CNN that remembers the mask it predicted for each image and feeds it back in as hard attention inside every block, and at test time it refines its own mask over ten rounds. On the paper's dataset, Kvasir-SEG, I get a Dice of *0.842* with the paper's protocol, against *0.880* in the paper, and *0.900* when the refinement starts from an empty mask. My ablation without feedback gets *0.883*, so in my reproduction the feedback adds little. For my own dataset I labelled 30 real leaf photos by hand in Roboflow, augmented them five times, and fine-tuned the polyp model on them: *0.517* Dice on 118 unseen leaf photos, against *0.467* when trained from random weights.]

#key[
- *0.842* = ours, paper's protocol (Otsu start, 10 rounds, 256×256). *0.880* = paper (512×512). Gap 0.038.
- *0.900* = same weights, empty start. *0.883* = no-feedback ablation. *0.831* = our 512×512 run.
- *7,720,266* parameters; *982,088* of them (fmask heads, 12.7%) never train.
- Kvasir-SEG *1000* images, split *880 / 120*. Roboflow: *30* photos, *24 / 6* split, *126* images after 5× augmentation. Hand labels vs LDSD masks: Dice *0.730*.
- Leaves: *0.517* fine-tuned vs *0.467* from scratch (118 LDSD test photos).
]

// =====================================================================
= The project on one page <sec-onepage>

#table(columns: (auto, 1fr),
  [Question], [Answer],
  [What], [Binary *semantic segmentation* of polyps in colonoscopy images: for every pixel, polyp (1) or background (0). Boxes around the predicted blobs give a *detection view*.],
  [Why], [Colorectal cancer usually starts as a polyp. About one adenoma in four (26%) is missed in colonoscopy (Zhao et al., Gastroenterology 2019). Each +1% in a doctor's adenoma detection rate lowers later cancer risk by about 3% (Corley et al., NEJM 2014). A model that outlines polyps is a second pair of eyes: decision support, never diagnosis.],
  [Paper], [FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation. Tomar, Jha, Riegler, H. D. Johansen, D. Johansen, Rittscher, Halvorsen, Ali. IEEE Transactions on Neural Networks and Learning Systems, vol. 34, no. 11, 2023 (online 2022). DOI 10.1109/TNNLS.2022.3159394, arXiv 2103.17235.],
  [Idea], [(1) a per-image *memory* of the last predicted mask, (2) a *MixPool* block in every encoder and decoder stage that uses that mask as hard attention, (3) *iterative refinement* at test time.],
  [Data], [Kvasir-SEG: 1000 colonoscopy images with polyp masks drawn by a doctor and verified by a gastroenterologist. Split 880 train / 120 test (seed 42). Resized to 256×256.],
  [Code], [All in `src/`, written with plain PyTorch layers. No pretrained weights, no `torchvision.models`, no `segmentation_models_pytorch`. The authors' repo was only read to check details.],
  [Main result], [Dice 0.842, mIoU 0.779 (paper: 0.880, 0.815). Empty start 0.900. No feedback 0.883. 512×512: 0.831.],
  [Findings], [Feedback adds little in our runs. The official "unaligned" memory acts as a regulariser. 13% of the parameters (fmask heads) never train.],
  [Own dataset], [30 real diseased-leaf photos (public LDSD set, CC0) labelled by hand in Roboflow, Semantic Segmentation project, split 24/6, resized 256×256, augmented 5× (flips, 90° turns, ±15° rotation, ±15% brightness) = 126 images. Public at `universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne`.],
  [Transfer result], [On 118 held-out LDSD photos: 0.517 fine-tuned from polyp weights vs 0.467 from random weights.],
  [Hardware], [RTX 5050 laptop GPU (8 GB) for the main runs; free Kaggle T4 GPUs for the ablation and the 512×512 runs.],
  [Weights], [Published on Hugging Face: `huggingface.co/Ckorion/fanet-polyp-leaf-from-scratch`.],
)

== How the project meets the brief
The brief (photo `brief/finalProjectDeepLearning.jpeg`, Hinglish): individual project; object segmentation and detection, not classification, must use a CNN; implement an IEEE paper from scratch; paper from the last 5 years, fairly advanced; use the paper's dataset; make a small dataset for the PPT and explain how it was generated. Later (30 Oct) ma'am asked that the own dataset be built in *Roboflow*.

#table(columns: (auto, 1fr),
  [Requirement], [How it is met (same as report §1)],
  [Segmentation / detection, CNN], [FANet outputs a 0/1 mask for every pixel; boxes around predicted blobs give a detection view. The network is convolutional end to end.],
  [IEEE paper, last 5 years], [IEEE TNNLS, vol. 34, no. 11, 2023 (online 2022).],
  [From scratch], [Every layer, the loss, training loop, metrics, Otsu, connected components and refinement written with plain PyTorch / NumPy.],
  [Paper's dataset], [Kvasir-SEG, the paper's 880/120 split ratio.],
  [Own dataset in Roboflow], [30 real leaf photos labelled by hand, versioned and augmented in Roboflow.],
  [PPT and notebook], [19-slide deck and an executed Jupyter notebook (`notebooks/FANet_project.ipynb`).],
)

*How the topic was chosen.* First plan CondInst (instance segmentation on COCO) was infeasible on one GPU. Second plan ColonSegNet (IEEE Access, March 2021) was dropped on 13 Oct because March 2021 is outside a strict 5-year window. FANet was registered on 13 Oct (row 29 of the sheet): strongest venue, safely inside the window, same dataset.

// =====================================================================
= Code map: where everything lives <sec-codemap>

Repo: `/mnt/Windows_D/College-work/DLproject` (GitHub `Chaitanya-666/DLproject`). All scripts are run from the repo root as modules: `python -m src.<name> --help`. Line numbers are for commit `ce2194e`.

#{
set text(9pt)
set par(justify: false)
table(columns: (auto, auto, 1fr),
  [Piece], [File : lines], [What it does],
  [Squeeze-and-excitation], [`src/blocks.py:12-35`], [average-pool each channel, 2-layer MLP + sigmoid, rescale channels],
  [Residual block], [`src/blocks.py:38-64`], [conv3×3-BN-ReLU-conv3×3-BN + shortcut (1×1 conv, BN, SE with `reduction=out_c` at `:58`), ReLU of the sum],
  [MixPool (fmask head)], [`src/blocks.py:91-97`], [conv3×3-BN-ReLU-conv1×1-sigmoid],
  [MixPool forward], [`src/blocks.py:109-116`], [`:110` fmask > 0.5; `:111-112` max-pool the previous mask; `:113` OR; `:114` masked half; `:115` plain half; `:116` concat],
  [Encoder block], [`src/model.py:27-38`], [Residual ×2 → MixPool → MaxPool 2×2; returns (pooled, skip)],
  [Decoder block], [`src/model.py:41-53`], [ConvTranspose2d (k4, s2, p1) at `:45` → concat skip → Residual ×2 → MixPool],
  [FANet], [`src/model.py:56-88`], [4 encoders, 4 decoders, head 1×1 conv on 17 channels (`:70`); previous mask concatenated at `:88`],
  [Parameter count], [`src/model.py:91-100`], [`python -m src.model` prints the output shape and 7,720,266],
  [Otsu threshold], [`src/memory.py:17-36`], [between-class variance from scratch (`:17-28`); grey → blur → threshold (`:31-36`)],
  [Memory (feedback)], [`src/memory.py:39-83`], [init Otsu or zeros (`:40-52`), `get` `:57`, `stage` `:60-64`, `commit` `:66-68`, `write` (test time) `:70-73`],
  [Loss], [`src/losses.py:14-29`], [Dice loss with smooth 1 (`:14-18`); 0.5·BCE-with-logits + 0.5·Dice (`:21-29`)],
  [Dataset], [`src/dataset.py:59-113`], [`load_image` `:59`, `load_mask` (threshold rule) `:64-82`, `SegmentationDataset` returns (image, mask, *index*) `:110-113`],
  [Split], [`src/split.py:25-50`], [seeded shuffle (seed 42), writes train/val/test.txt],
  [Augmentation], [`src/augment.py`], [official rotate ±35° / flips (`:78-99`), cut-out and jitter (`:59-75`), aligned flips/rot90 and their inverse (`:23-56`)],
  [Training step], [`src/train.py:54-111`], [memory get `:70`; augmentation `:72-82`; AMP autocast `:84-88`; backward + Adam `:89-97`; stage predictions `:99-106`],
  [Training main], [`src/train.py:114-219`], [flags `:115-140`; val falls back to test `:147`; memories `:155-156`; Adam `:165`; GradScaler `:166`; ReduceLROnPlateau `:167-168`; commit + save `:187-203`; early stop `:215-217`],
  [Evaluation / refinement], [`src/evaluate.py:53-137`], [Otsu or zeros start `:81-84`; refinement loop `:95-120`; write back `:108`; `results.csv` `:122-125`; strips `:127-132`],
  [Metrics], [`src/metrics.py:27-63`], [per-image Dice, IoU, precision, recall, specificity, accuracy, F2; averaged over images],
  [Boxes (detection view)], [`src/metrics.py:68-149`], [BFS connected components `:68-88`; boxes `:91-99`; box IoU `:102-108`; greedy matching at IoU ≥ 0.5 `:111-149`],
  [Memory probe], [`src/memory_probe.py:31-77`], [one pass from Otsu / zeros / ones / ground truth / own memory (`:49-59`)],
  [Roboflow converter], [`src/roboflow_to_masks.py:48-153`], [reads `NAME_mask.png` class-index masks (`:48-60`); keeps Roboflow's split; `--compare` writes `agreement.csv` (`:133-153`)],
  [Synthetic leaves], [`src/make_synthetic.py:37-100`], [irregular blob polygons (`:37-47`), leaf + spots + blur/noise (`:50-100`)],
  [Figures], [`src/figures.py`], [learning curves, refinement chart, strip montages],
  [Kaggle offload], [`kaggle/offload.sh`, `kaggle/run_template.py`], [push (`:34-59`) / status / pull (`:64-75`) a private GPU run],
  [Deck], [`presentation/build_deck.js`], [builds the 19-slide PPTX from the CSVs in `runs/`],
)
}

#table(columns: (auto, 1fr),
  [Folder], [Contents],
  [`runs/<run>/`], [`log.csv` (one row per epoch: train/val loss, Dice, IoU, lr, seconds, saved), `best.pt` (weights + memories + settings, not in git), `eval_test/results.csv` (one row per refinement round), `eval_test_zeros/` (empty start), `memory_probe.csv`],
  [`docs/`], [`report.typ/pdf` (submitted report), `project_book`, `study_guide`, `v1-condinst-plan.md`],
  [`presentation/`], [deck, `build_deck.js`, `figures/`, `assets/` (strips, Roboflow screenshots)],
  [`dataset/custom/`], [`synthetic_leaf/` (60 generated), `roboflow_leaf/` (converted Roboflow export, `agreement.csv`), `roboflow_upload_list.txt`],
  [`data/`], [downloaded data, not in git: `Kvasir-SEG/`, `LDSD/`, `roboflow_export/`, `roboflow_upload/`],
  [`notebooks/`], [`FANet_project.ipynb` (submission notebook, executed), `kaggle_fanet.ipynb`],
)

// =====================================================================
= Deep learning from zero, part 1: how a network learns <sec-dl1>

This chapter and the next two build the theory step by step. Each idea ends with how our project uses it.

== A neuron
A *neuron* takes numbers $x_1, dots, x_n$, multiplies each by a *weight* $w_i$, adds a *bias* $b$, and passes the result through a function $f$:
$ y = f(w_1 x_1 + dots + w_n x_n + b) $
The weights and the bias are the *parameters*. Learning means finding good values for them.

== A layer and a deep network
A *layer* is many neurons side by side, each looking at the same input. A *deep* network stacks many layers: later layers combine the patterns that earlier layers found. Classical methods (like Otsu, used in FANet's first mask) follow rules a person designed. Deep learning learns the features itself from labelled examples: nobody tells FANet what a polyp edge looks like.

== Activation functions
$f$ above is the *activation*. It must be *non-linear*: without it, stacking layers would collapse into one big linear map and the network could only draw straight lines.
- *ReLU*: $max(0, x)$. Cheap, keeps positive values, zeros negative ones. Used after almost every convolution in FANet.
- *Sigmoid*: $sigma(z) = 1 / (1 + e^(-z))$. Squashes any number into $(0, 1)$, which we read as a probability. The raw number before the sigmoid is called a *logit*.

#ours[FANet outputs one *logit* per pixel. Sigmoid turns it into a probability; above 0.5 the pixel is "polyp". ReLU sits inside every residual block and MixPool conv. Sigmoid also appears in the SE block and in the fmask head.]

== Loss: one number for "how wrong"
A *loss function* compares the prediction with the correct answer (the *ground truth*) and returns one number. Lower is better. Training = changing the parameters to make the loss small. This is *supervised learning*: every training image comes with its correct mask, drawn by a doctor. Our loss is $0.5 dot "BCE" + 0.5 dot "Dice loss"$ (explained in @sec-loss).

== Gradient descent
The *gradient* of the loss with respect to a weight says how the loss changes if that weight changes a little. Move every weight a small step *against* its gradient:
$ w <- w - eta (partial L) / (partial w) $
$eta$ is the *learning rate* (step size). Too large: the loss jumps around. Too small: training is slow. Ours: $10^(-4)$ for training from scratch, $5 times 10^(-5)$ for fine-tuning.

== Backpropagation
A network is a chain of functions. *Backpropagation* uses the chain rule to compute the gradient for every weight, starting from the loss and going backwards layer by layer. PyTorch does this automatically when we call `loss.backward()`.

#key[An operation with zero gradient blocks backpropagation. A hard threshold such as `x > 0.5` is a step function: its gradient is zero (and PyTorch does not even track it). This is exactly why FANet's fmask head never learns (@sec-fmask).]

== Batches, epochs, iterations
- A *batch* is a group of images processed together in one step (ours: 8 images at 256×256; 4 at 512×512).
- One *iteration* (step) = one batch forward, loss, backward, update.
- One *epoch* = one pass over all training images. With 880 images and batch 8: 110 steps per epoch.

== Adam
*Adam* is gradient descent with two improvements: a running average of the gradient (momentum, smooths noise) and a running average of its square (gives every weight its own step size). It is the standard choice. We use `torch.optim.Adam(model.parameters(), lr=1e-4)`, as the paper does.

#code[`src/train.py:165` creates Adam. `src/train.py:89-97` does `zero_grad`, `backward`, `step` (with the AMP scaler if `--amp`).]

// =====================================================================
= Deep learning from zero, part 2: CNNs for images <sec-dl2>

== An image is a tensor
A colour image is a 3-D array: *3 × H × W* (red, green, blue), each value in $[0, 1]$ after dividing by 255. A batch of $B$ images is *B × 3 × H × W*. Our masks are *B × 1 × H × W* with values 0 or 1.

#code[`src/dataset.py:110-113`: `image` is `(3, H, W)` float in $[0,1]$, `mask` is `(1, H, W)` of 0/1, plus the image's *index* (needed for the memory).]

== Why not a fully connected layer?
A fully connected neuron on a 256×256 colour image needs $256 dot 256 dot 3 approx 196{,}000$ weights, and it would treat a polyp in the corner as unrelated to the same polyp in the centre. A *convolutional neural network* (CNN) solves both problems with *local connections* and *weight sharing*.

== Convolution
A convolution slides a small *filter* (here 3×3) over the image. At each position it multiplies the filter weights with the pixels under it and adds them up: one output number. A layer has many filters; each gives one output *channel* (a *feature map*). Early layers find edges and colours, middle layers textures and blobs, deep layers object parts.
- *Parameters* of a conv from $C_"in"$ to $C_"out"$ channels with a $k times k$ kernel: $k dot k dot C_"in" dot C_"out" + C_"out"$ (one bias per filter). FANet's first conv (3 → 32 channels): $3 dot 3 dot 3 dot 32 + 32 = 896$.
- *Weight sharing*: the same filter is used everywhere, so few parameters, and a pattern is found wherever it appears (translation equivariance).

== Stride and padding
*Stride* $s$ = how far the filter moves each step. *Padding* $p$ = how many zero pixels are added around the border. Output size for input $n$ and kernel $k$:
$ n_"out" = floor((n + 2p - k) / s) + 1 $
- Our 3×3 convs use $p = 1$, $s = 1$: $(256 + 2 - 3) / 1 + 1 = 256$. *Same size.*
- Max pooling 2×2 with stride 2: $256 -> 128$. *Half size.*
- Transposed convolution (kernel 4, stride 2, padding 1) works the other way: $(n - 1) dot 2 - 2 dot 1 + 4 = 2n$. *Double size.*

== Pooling
*Max pooling 2×2* keeps the largest value of every 2×2 block. It halves height and width, makes the network cheaper, and lets later layers see a wider area. FANet uses it after every encoder block (`src/model.py:33`) and also to shrink the previous mask inside MixPool (`src/blocks.py:112`).

== Receptive field
The *receptive field* of an output pixel is the patch of the input image that can influence it. One 3×3 conv sees 3×3 pixels; two stacked see 5×5; every pooling doubles the growth. Deep in the encoder (16×16 feature maps for a 256×256 input) each position sees a large part of the image, which is what you need to recognise a whole polyp.

== Batch normalisation
*Batch normalisation* (`BatchNorm2d`): for each channel, subtract the batch mean and divide by the batch standard deviation, then scale and shift with two learned numbers. Keeps values in a good range, so training is faster and more stable. During testing it uses running averages collected in training. Small batches give noisy statistics (one reason the authors' batch 2 and our batch 8 may train differently).

== 1×1 convolution and transposed convolution
- *1×1 conv*: mixes channels at each pixel, does not look at neighbours. Used to change channel counts (residual shortcut) and as the output layer (17 channels → 1 logit).
- *Transposed convolution* (`ConvTranspose2d`): learned *upsampling*. The network learns how to fill in detail, instead of a fixed resize.

== Residual block
Output = ReLU(main path + shortcut). The block learns a *correction* to its input, and the shortcut gives gradients a direct road back, so deep networks train well (He et al., ResNet 2016). A 1×1 conv on the shortcut makes the channel counts equal so the two paths can be added.

== Squeeze-and-excitation (SE): channel attention
For a feature map with $C$ channels (Hu et al., SENet 2018): *squeeze* = average each channel over all pixels ($C$ numbers); *excite* = a two-layer MLP + sigmoid gives $C$ weights in $(0,1)$; multiply each channel by its weight. The network learns, per image, which channels to boost or damp.

#ours[
- `ResidualBlock` (`src/blocks.py:38-64`): conv3×3-BN-ReLU-conv3×3-BN, plus a shortcut of conv1×1-BN-*SE*. Output `F.relu(y + self.shortcut(x))` at `:64`.
- SE (`src/blocks.py:12-35`) sits on the *shortcut*. The official code builds it with `reduction = out_c`, so the hidden layer has exactly *one unit* (`max(channels // reduction, 1)` at `:23`). We copied that to stay faithful.
]

// =====================================================================
= Deep learning from zero, part 3: vision tasks and segmentation networks <sec-dl3>

== Four kinds of vision task
#table(columns: (auto, 1fr, auto),
  [Task], [Output for one image], [Typical models],
  [Classification], [one label for the whole image ("polyp present")], [ResNet, VGG],
  [Object detection], [a box + class + confidence for every object], [YOLO, Faster R-CNN],
  [Semantic segmentation], [a class for every pixel; objects of the same class are not separated], [U-Net, DeepLab, *FANet*],
  [Instance segmentation], [a separate mask for every object], [Mask R-CNN, CondInst],
)
#ours[FANet does *binary semantic segmentation*: two classes, polyp and background. Output: a 256×256 map of probabilities, thresholded at 0.5. Kvasir images usually contain one polyp, so semantic and instance segmentation almost coincide here. A *detection view* is derived: one box around every connected blob of the mask (@sec-boxes).]

== Encoder-decoder
A segmentation network must output a mask the same size as the input.
- *Encoder*: convolutions + pooling. Resolution goes down (256 → 128 → 64 → 32 → 16), channels go up (32 → 256). It learns *what* is in the image.
- *Decoder*: upsampling + convolutions. Resolution goes back up to 256. It learns *where* exactly.

== U-Net and skip connections
*U-Net* (Ronneberger et al., MICCAI 2015) adds *skip connections*: the decoder at each scale also receives the encoder's features of the same scale (concatenated). Pooling throws away fine detail; skips bring it back, so edges are sharp. FANet is a U-Net-shaped network with residual blocks, SE, and MixPool attention.

== Attention
*Attention* means weighting parts of the input by importance.
- *Soft attention*: multiply by learned weights between 0 and 1. Differentiable. SE is soft attention over *channels*.
- *Hard attention*: multiply by a 0/1 mask: keep these pixels, zero the rest. A 0/1 step has no useful gradient.
- *Spatial* attention weights pixel positions; *channel* attention weights feature channels.

#ours[FANet's MixPool uses *hard spatial attention*. The 0/1 mask comes from the network's *own previous prediction* for that image (OR-ed with a mask guessed from the current features). That is the "feedback attention" in the paper's title.]

// =====================================================================
= The problem and the dataset <sec-problem>

== Colorectal cancer and polyps
- Colorectal cancer usually begins as a *polyp*: a small growth on the inner wall of the colon. Some polyps (*adenomas*) slowly turn cancerous. Removed early, they never become cancer.
- In a *colonoscopy* a doctor guides a camera through the colon and removes the polyps they see. But about *one adenoma in four is missed* (26%, meta-analysis of tandem colonoscopies, Zhao et al., Gastroenterology 2019). Each *+1% in adenoma detection rate* lowers the later cancer risk by about *3%* (Corley et al., NEJM 2014).
- Why hard: polyps vary in size, shape and colour, can be flat and blend into the wall; images have glare, bubbles, motion blur, instruments.

== Why a mask and not a yes/no
A mask shows *where* the polyp is, *how big* it is and *where its edges are*. A box can be drawn from a mask, but not the other way round: segmentation gives strictly more information.

== Kvasir-SEG
- *1000* colonoscopy images, each with a polyp mask drawn by a medical doctor and verified by an experienced gastroenterologist (Vestre Viken Health Trust, Norway; published by Jha et al., MMM 2020, the same Simula group as FANet's authors).
- Image sizes vary (about 332×487 up to 1920×1072); we resize all to *256×256* (bilinear for images, nearest for masks). Masks are JPEGs, so their edges carry grey values; the loader thresholds them.
- *Split*: 880 train / 120 test with a fixed seed (42), the paper's ratio (`python -m src.split --data data/Kvasir-SEG`). Our 120 may not be the paper's 120 images.
- *Class imbalance*: polyps cover on average *14.2%* of a test image. Predicting "all background" already gets about 86% pixel accuracy. That is why we use Dice, not accuracy (@sec-metrics).
- Kvasir-SEG also ships `kavsir_bboxes.json` (boxes derived from its masks; the typo is in the original).

#fig("figures/kvasir_example.png", [A Kvasir-SEG image, its ground-truth mask (drawn by experts), and the mask laid over the image (the picture on slides 1 and 4).], w: 78%)

#code[`src/dataset.py:59-61` resizes images (bilinear); `src/dataset.py:64-82` loads masks: nearest-neighbour resize, brightest channel, then "max ≤ 10 means class indices, anything non-zero is foreground; otherwise threshold at half the max". `src/split.py:36` shuffles with `random.Random(42)`.]

// =====================================================================
= The paper: FANet <sec-paper>

== The facts
#table(columns: (auto, 1fr),
  [Title], [FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation],
  [Authors], [Nikhil Kumar Tomar, Debesh Jha, Michael A. Riegler, Håvard D. Johansen, Dag Johansen, Jens Rittscher, Pål Halvorsen, Sharib Ali],
  [Venue], [IEEE Transactions on Neural Networks and Learning Systems (TNNLS), vol. 34, no. 11, 2023 (online 2022). A top IEEE journal.],
  [Links], [DOI 10.1109/TNNLS.2022.3159394 · IEEE Xplore 9741842 · arXiv 2103.17235 · code github.com/nikhilroxtomar/FANet],
  [Datasets in the paper], [Seven: Kvasir-SEG and CVC-ClinicDB (polyps), DRIVE and CHASE-DB1 (retinal vessels), 2018 Data Science Bowl (nuclei), ISIC 2018 (skin lesions), EM (cell membranes). *We reproduce Kvasir-SEG only.*],
)

== The problem the paper sees
"Existing methods do not use the information from different learning epochs effectively." A network sees every training image once per epoch, 100+ times in total, but each time it starts fresh: its earlier prediction for that image is thrown away.

== The idea
+ *Memory across epochs.* For every training image, keep the mask the network predicted for it earlier ("the previous epoch mask").
+ *Feedback as hard attention.* Feed that mask back as a second input. Inside every encoder and decoder block, a *MixPool* block uses it as a "look here" gate.
+ *Iterative refinement at test time.* Start from a rough mask, predict, feed the prediction back, predict again (10 rounds in the official test script).

Where does the very first mask come from? *Otsu's threshold* of the blurred grey image: a classical method, no learning.

== Otsu's method
Try every grey level $t$ from 0 to 255. Split the pixels into "darker than $t$" and "brighter than $t$". Pick the $t$ that makes the two groups most different: it maximises the *between-class variance*
$ sigma_B^2 (t) = omega_0(t) omega_1(t) (mu_0(t) - mu_1(t))^2 $
where $omega$ are the two groups' pixel fractions and $mu$ their mean grey levels. Pixels brighter than $t$ become 1.

#code[`src/memory.py:17-28` computes it from the histogram with cumulative sums (`omega`, `mu`). `src/memory.py:31-36`: grey, Gaussian blur, threshold.]

#trap[On colonoscopy images Otsu picks *bright* regions (glare, lit wall), not polyps. On our 120 test images it marks *59.6%* of each image while polyps cover *14.2%*. It is a poor starting mask, and this matters a lot for our results (@sec-testing).]

#fig("figures/otsu_example.png", [A Kvasir image and its Otsu mask: Otsu picks bright regions (glare, lit wall), not the polyp.], w: 62%)

== The training rule
Before epoch 1 every memory slot holds the Otsu mask. In each epoch image $i$ is fed with `memory[i]`; the thresholded prediction goes to a *staging* copy. Only if the *validation loss improves* does the staging copy replace the memory (and the checkpoint is saved). So the memory always comes from the best model so far, and a bad epoch cannot poison the next epoch's input. *Ground truth is never an input.*

== Loss and protocol
Loss: BCE + Dice (official code: $0.5 dot "BCE" + 0.5 dot "Dice"$). Optimiser Adam, learning rate $10^(-4)$.

#table(columns: (auto, 1fr, 1fr, 1.3fr),
  [], [Paper (text)], [Authors' code], [This project],
  [Input], [512×512], [256×256], [256×256 (laptop); 512×512 (Kaggle)],
  [Batch / epochs], [100 epochs], [2 / up to 500], [8 / up to 200, early stop 40; at 512: 4 / 100],
  [Optimiser], [Adam 1e-4], [Adam 1e-4, plateau ×0.1 (patience 5)], [same],
  [Loss], [BCE + Dice], [0.5·BCE + 0.5·Dice], [same (BCE on logits)],
  [Augmentation], [], [rotate ±35°, flips, coarse dropout; memory not moved], [same, rewritten in torch],
  [Test], [refinement], [10 rounds from Otsu], [same],
  [Checkpoint chosen on], [], [the 120 test images (val = test)], [same, for Kvasir],
  [Hardware], [GTX 1050 Ti], [], [RTX 5050 laptop 8 GB; Kaggle T4],
)

== The paper's numbers (Kvasir-SEG)
#table(columns: (1fr, auto, auto, auto, auto, auto, auto),
  [Paper, Tables II / IX], [Dice], [mIoU], [Recall], [Precision], [F2], [FPS],
  [FANet (512×512, GTX 1050 Ti)], [0.8803], [0.8153], [0.9058], [0.9005], [0.8872], [68.18],
  [Baseline B1, without MixPool], [0.8516], [0.7732], [0.8835], [0.8710], [0.8614], [104.20],
)
The paper's *ablation* (Table IX) therefore claims the MixPool / feedback idea is worth about *+0.03 Dice* (0.852 → 0.880). Our repo records only these two rows of Table IX; do not quote other rows from memory.

#say[The paper's observation is that a network sees each image a hundred times in training but forgets its earlier predictions. FANet keeps the previous prediction for every image and feeds it back as hard attention in every block, and at test time it uses the same loop to refine its mask over ten rounds. They report Dice 0.880 on Kvasir-SEG, against 0.852 without the MixPool blocks.]

// =====================================================================
= The architecture, block by block, in our code <sec-arch>

#figure(
  diagram(spacing: (5.2mm, 7mm), node-stroke: 0.6pt, node-corner-radius: 2pt,
    node((0,0), [image \ 3×256²], stroke: none),
    node((1,0), [E1], fill: rgb("#dcecef")), node((2,0), [E2], fill: rgb("#dcecef")),
    node((3,0), [E3], fill: rgb("#dcecef")), node((4,0), [E4], fill: rgb("#dcecef")),
    node((5,0), [D1], fill: rgb("#e8f3dc")), node((6,0), [D2], fill: rgb("#e8f3dc")),
    node((7,0), [D3], fill: rgb("#e8f3dc")), node((8,0), [D4], fill: rgb("#e8f3dc")),
    node((9,0), [concat \ + 1×1 conv]), node((10,0), [logits \ 1×256²], stroke: none),
    edge((0,0), (1,0), "-|>"), edge((1,0), (2,0), "-|>"), edge((2,0), (3,0), "-|>"), edge((3,0), (4,0), "-|>"),
    edge((4,0), (5,0), "-|>"), edge((5,0), (6,0), "-|>"), edge((6,0), (7,0), "-|>"), edge((7,0), (8,0), "-|>"),
    edge((8,0), (9,0), "-|>"), edge((9,0), (10,0), "-|>"),
    edge((4,0), (4,-1), (5,-1), (5,0), "--|>"), edge((3,0), (3,-1.4), (6,-1.4), (6,0), "--|>"),
    edge((2,0), (2,-1.8), (7,-1.8), (7,0), "--|>"), edge((1,0), (1,-2.2), (8,-2.2), (8,0), "--|>", [skips], label-pos: 0.5),
    node((0,1.4), [previous mask \ 1×256²], stroke: none, fill: rgb("#fde8e4")),
    edge((0,1.4), (9,1.4), (9,0), "-|>", stroke: rgb("#c0392b")),
    edge((1,1.4), (1,0), "-|>", stroke: rgb("#c0392b")), edge((2,1.4), (2,0), "-|>", stroke: rgb("#c0392b")),
    edge((3,1.4), (3,0), "-|>", stroke: rgb("#c0392b")), edge((4,1.4), (4,0), "-|>", stroke: rgb("#c0392b")),
    edge((5,1.4), (5,0), "-|>", stroke: rgb("#c0392b")), edge((6,1.4), (6,0), "-|>", stroke: rgb("#c0392b")),
    edge((7,1.4), (7,0), "-|>", stroke: rgb("#c0392b")), edge((8,1.4), (8,0), "-|>", stroke: rgb("#c0392b")),
  ),
  caption: [FANet (same drawing as the report). The previous mask (red) enters every encoder (E) and decoder (D) block and is concatenated before the output layer. Dashed lines are skip connections.],
)

== Two inputs, one output
Inputs: the *image* (3×256×256) and the *previous mask* (1×256×256, 0/1). Output: *logits* (1×256×256). Sigmoid → probability → threshold 0.5 → mask. Width and height must be divisible by 16 (four poolings).

== Encoder block (E)
ResidualBlock → ResidualBlock → *MixPool* → MaxPool 2×2. The output *before* pooling is kept as the *skip* for the decoder.
#code[`src/model.py:27-38`. `forward`: `skip = self.r2(self.r1(x))` then `out = self.pool(self.mix(skip, m))` (`:36-37`). Note: the skip is taken *before* MixPool.]

== Decoder block (D)
Transposed conv (×2 up) → concatenate the skip → ResidualBlock → ResidualBlock → *MixPool*.
#code[`src/model.py:41-53`. `ConvTranspose2d(in_c, in_c, kernel_size=4, stride=2, padding=1)` at `:45`; concat at `:51`; the first residual block takes `in_c + in_c` channels (`:46`).]

== The head
The last decoder output (16 channels) is concatenated with the previous mask (1 channel) → 17 channels → 1×1 conv → 1 logit per pixel.
#code[`src/model.py:70` (`nn.Conv2d(w1 // 2 + 1, 1, kernel_size=1)`) and `:88` (`self.head(torch.cat([d, prev_mask], dim=1))`).]

== Shapes and parameters for one 256×256 image
Exactly what `src/model.py` and the notebook print (`python -m src.model`).
#table(columns: (auto, auto, auto, auto),
  [Stage], [Output], [Skip passed on], [Parameters],
  [E1 (3 → 32)], [32×128×128], [32×256×256], [48,993],
  [E2 (32 → 64)], [64×64×64], [64×128×128], [210,753],
  [E3 (64 → 128)], [128×32×32], [128×64×64], [839,297],
  [E4 (128 → 256)], [256×16×16], [256×32×32], [3,349,761],
  [D1 (256 → 128)], [128×32×32], [], [2,461,569],
  [D2 (128 → 64)], [64×64×64], [], [616,385],
  [D3 (64 → 32)], [32×128×128], [], [154,593],
  [D4 (32 → 16)], [16×256×256], [], [38,897],
  [concat previous mask], [17×256×256], [], [],
  [1×1 conv head], [*1×256×256 logits*], [], [18],
  [*Total*], [], [], [*7,720,266*],
)
Pattern: every encoder halves the size and doubles the channels; every decoder does the opposite. Most parameters sit at the bottom (E4, D1) where there are 256 channels, because a 3×3 conv costs $9 dot C_"in" dot C_"out"$.

*Compute cost* (README §5.7): 40.5 GFLOPs per 256×256 image, 162 at 512×512 (ResNet-50 at 224×224 is about 8). FANet is small in parameters but expensive per image, because it keeps 32 to 64 channels at full resolution and every block runs MixPool's three extra convs.

== MixPool, line by line <sec-mixpool>
#figure(
  diagram(spacing: (4mm, 5mm), node-stroke: 0.6pt, node-corner-radius: 2pt,
    node((0,1), [$x$], stroke: none),
    node((1,0), [fmask head: conv3×3-BN-ReLU \ conv1×1-sigmoid, then > 0.5 → F]),
    node((1,1.2), [previous mask M \ max-pooled to x's size], fill: rgb("#fde8e4")),
    node((2,0.6), [F OR M → A (0/1)]),
    node((3,0.6), [x · A → conv3×3-BN-ReLU \ (masked half, C/2)]),
    node((3,2), [x → conv3×3-BN-ReLU \ (plain half, C/2)]),
    node((4,1.3), [concat]), node((5,1.3), [out (C)], stroke: none),
    edge((0,1), (1,0), "-|>"), edge((1,0), (2,0.6), "-|>"), edge((1,1.2), (2,0.6), "-|>"),
    edge((2,0.6), (3,0.6), "-|>"), edge((0,1), (0,2), (3,2), "-|>"),
    edge((3,0.6), (4,1.3), "-|>"), edge((3,2), (4,1.3), "-|>"), edge((4,1.3), (5,1.3), "-|>"),
  ),
  caption: [The MixPool block (`src/blocks.py`, class `MixPool`).],
)

```python
def forward(self, x, m):                                       # src/blocks.py:109
    fmask = (self.fmask(x) > 0.5).float()                      # :110 hard 0/1 guess
    kh, kw = m.shape[2] // x.shape[2], m.shape[3] // x.shape[3]  # :111
    m = F.max_pool2d(m, (kh, kw)) if kh > 1 or kw > 1 else m   # :112 shrink M
    attention = torch.logical_or(fmask > 0, m > 0.5).float()   # :113 A = F OR M
    masked = self.conv1(x * attention)                         # :114 masked half
    plain = self.conv2(x)                                      # :115 plain half
    return torch.cat([masked, plain], dim=1)                   # :116 C channels
```
+ *fmask*: a small conv head guesses a mask from the features themselves, thresholded to 0/1.
+ *Shrink the previous mask* to the feature size with *max* pooling: a cell is 1 if *any* pixel in it was 1, so small polyps survive. Average pooling would fade a small polyp below 0.5 and lose it.
+ *Attention* $A = F or M$: a pixel is attended if either the current features or the previous mask point at it.
+ *Masked half*: features outside $A$ are set to zero (hard attention), then conv3×3-BN-ReLU to $C/2$ channels.
+ *Plain half*: the *unmasked* features through their own conv3×3-BN-ReLU to $C/2$ channels.
+ *Concatenate* the halves: $C$ channels out.

#key[*Why two halves?* If the previous mask is wrong (for example the Otsu guess in epoch 1), the plain half still carries every feature, so a bad mask cannot erase the polyp. The network learns how much to trust each half.]

== Finding: part of MixPool never trains <sec-fmask>
The fmask output is thresholded with `> 0.5` (`src/blocks.py:110`). A step function has zero gradient, so no gradient reaches the convs inside the fmask heads. Checked with a backward pass in the notebook: *48 parameter tensors, 982,088 parameters (12.7%, "about 13%") have no gradient, all in fmask heads.* They keep their random initial weights; only their BatchNorm running statistics change. In effect the fmask is a *fixed random gate*; the learned part of the attention is the previous mask.

*Fix (future work):* a soft (sigmoid) gate, or a straight-through estimator (use the hard 0/1 in the forward pass but pass the gradient of the sigmoid in the backward pass).

#say[While implementing I found that the fmask head inside MixPool is thresholded with a hard step, which has no gradient. So about 13% of the parameters, 982,088, never train. The useful attention comes from the previous mask. A soft gate would fix it.]

// =====================================================================
= Loss and metrics <sec-loss>

== Binary cross-entropy (BCE)
For pixel $j$ with predicted probability $p_j$ and truth $g_j in {0, 1}$:
$ "BCE" = -1/N sum_j [g_j log p_j + (1 - g_j) log(1 - p_j)] $
Judges every pixel on its own; smooth, stable gradients. But with 86% background pixels it is dominated by the background.

== Dice loss
$ "Dice loss" = 1 - (2 sum_j p_j g_j + 1) / (sum_j p_j + sum_j g_j + 1) $
Measures overlap of the whole predicted region with the true region, so a small polyp still counts. The $+1$ ("smooth") avoids dividing by zero on empty masks.

== Our loss
$0.5 dot "BCE" + 0.5 dot "Dice"$, as in the official code: stable gradients from BCE, and a target that matches the evaluation metric from Dice.
#code[`src/losses.py:14-18` (`dice_loss`, `smooth=1.0`), `:21-29` (`DiceBCELoss`). BCE uses `F.binary_cross_entropy_with_logits` (`:28`): same value as sigmoid + BCE, but numerically safer (no `log(0)`).]

== Metrics <sec-metrics>
Per image, count pixels: *TP* (predicted polyp, truly polyp), *FP* (predicted polyp, truly background), *FN* (missed polyp), *TN* (correct background). Compute the scores per image, then *average over the 120 test images* (as the official test script does; the averaged IoU is "mIoU").

#table(columns: (auto, auto, 1fr),
  [Metric], [Formula], [Meaning],
  [Dice = F1], [$2"TP" / (2"TP" + "FP" + "FN")$], [overlap; the headline number in polyp papers],
  [IoU (Jaccard)], [$"TP" / ("TP" + "FP" + "FN")$], [stricter overlap; always ≤ Dice. Per image, IoU = Dice / (2 − Dice)],
  [Precision], [$"TP" / ("TP" + "FP")$], [of what I marked, how much is really polyp],
  [Recall (sensitivity)], [$"TP" / ("TP" + "FN")$], [of the real polyp, how much I found. Clinically the most important: a missed polyp is the dangerous error],
  [F2], [$5 P R / (4P + R)$], [like F1 but recall counts more],
  [Specificity], [$"TN" / ("TN" + "FP")$], [of the background, how much I left alone],
  [Accuracy], [$("TP" + "TN") / "all"$], [misleading here: mostly background],
)
*Why is Dice the same as F1?* F1 is the harmonic mean of precision and recall: $2 P R / (P + R)$. Substitute $P = "TP"/("TP"+"FP")$, $R = "TP"/("TP"+"FN")$ and it simplifies to $2"TP" / (2"TP" + "FP" + "FN")$.

*Worked example* (from the project book). 100-pixel image, polyp = 20 pixels. The model marks 25 pixels, 15 of them on the polyp. TP = 15, FP = 10, FN = 5, TN = 70. Dice = 30/45 = *0.667*; IoU = 15/30 = *0.5*; precision = 15/25 = 0.6; recall = 15/20 = 0.75; accuracy = 85/100 = 0.85. An *empty* prediction would score accuracy 0.80 and Dice 0. That is why we use Dice.

#code[`src/metrics.py:27-45` (`mask_scores`, with a tiny epsilon so an empty-vs-empty image scores 1), `:48-63` (`MetricAverager`, per-image then mean).]

== Detection view: boxes from masks <sec-boxes>
+ Find each *connected blob* of the mask: breadth-first search over the 8 neighbours of every pixel, written from scratch (`src/metrics.py:68-88`).
+ Draw one box around each blob; ignore blobs under 20 pixels as noise (`:91-99`).
+ Match predicted boxes to true boxes greedily, best IoU first; a hit needs *box IoU ≥ 0.5* (`:111-142`).
+ Report *box precision* (hits / predicted boxes), *box recall* (hits / true boxes) and the mean IoU of the hits.

Results (120 Kvasir test images): paper's protocol box precision *0.685*, box recall *0.800*, mean box IoU *0.881*; empty start *0.836* / *0.896*. Precision is lower than recall: the model finds most polyps but sometimes predicts an extra small blob.

#trap[This is *not* a trained detector: there are no box regression heads and no confidence scores, so no mAP. It is a detection *view* derived from the segmentation. Say exactly that. The brief allows segmentation; the boxes show we cover the detection angle too.]

// =====================================================================
= Training <sec-training>

== Train, validation and test sets
- *Training set*: used to change the weights. *Validation set*: used to choose settings and the best checkpoint. *Test set*: used only to measure, once, at the end.
- *Overfitting*: very good on training images, worse on new ones (the model memorised instead of learned). Signs: training loss keeps falling while validation loss stops falling or rises. In our final run the train loss ends near 0.07 and the test loss near 0.11 (learning-curve figure): a small gap.
- *Our Kvasir setup*: there is no separate validation set. `train.py` uses `val.txt` if it exists, otherwise the *test* split (`src/train.py:147`). The authors' code does the same (their "val" is the 120 test images), so our numbers are comparable with the paper, but *slightly optimistic*. `python -m src.split --val 80` would hold out 80 training images, but it was not used.

#trap[*Test set used as validation?* For Kvasir-SEG, yes, as in the authors' code: the checkpoint, the learning-rate cuts and the memory commits all follow the loss on the 120 test images. Say it openly. The Roboflow runs are clean: checkpoints chosen on Roboflow's 6 validation photos, tested on 118 LDSD photos never seen. (The 470-photo LDSD runs and the synthetic-leaf runs had no val split either, so they also selected on their test set.)]

== Augmentation
*Data augmentation* makes new-looking training images for free (flips, rotations, brightness, cut-out holes). It fights overfitting. A geometric change must be applied to the image *and* its mask.

Our two modes (`--memory-aug`):
- *official* (default, the authors' behaviour, `src/augment.py:78-99`): each sample independently, with probability 0.3 each, rotate by a random angle in ±35° (reflected borders; bilinear for the image, nearest for the mask), flip horizontally, flip vertically. Plus cut-out on the *image only* (`photometric(image, p_jitter=0.0)` at `src/train.py:82`): with probability 0.3, 1 to 10 black holes of 32×32. *The memory mask is not moved*, and the prediction made on the moved image is stored as it is.
- *aligned* (our first attempt): flips and 90° rotations applied to image, mask *and memory*; the prediction is rotated back before storing (`src/augment.py:32-56`, exact inverse); plus brightness/contrast jitter (0.8 to 1.2) and cut-out.

*How often is the memory misaligned in official mode?* A sample is untouched only if all three moves are skipped: $0.7^3 = 0.343$. So $1 - 0.343 approx 0.66$, about *two-thirds* of training samples see a memory that points at the wrong place.

== The training loop with feedback, step by step
```text
before epoch 1: memory[i] = Otsu(image i)      (train and val)
each epoch, each batch:
    prev = memory.get(idx)                       train.py:70
    image, target = official_geometric(...)      train.py:81 (memory NOT moved)
    logits = FANet(image, prev)                  train.py:86
    loss = 0.5*BCE + 0.5*Dice; backward; Adam    train.py:88-97
    memory.stage(idx, sigmoid(logits))           train.py:105 (>0.5, staging copy)
end of epoch:
    same pass on the val (= test) images         train.py:182
    scheduler.step(val_loss)                     train.py:185
    if val_loss improved:                        train.py:187
        memory <- staged (train and val)         train.py:189-190
        save best.pt (weights, memories, args)   train.py:193-201
    stop after 40 epochs without improvement     train.py:215
```
#key[*Why does the dataset return the index?* So each image finds its own memory slot. The official code stored the memory as run-length strings and had to keep the loader order fixed (`shuffle=False`). Returning the index lets us shuffle every epoch (`src/dataset.py:113`, `src/memory.py:57`).]

== Learning-rate schedules and early stopping
- *ReduceLROnPlateau* (factor 0.1, patience 5): if the validation loss has not improved for 5 epochs, divide the learning rate by 10. Big steps first, fine steps later (`src/train.py:167-168`). In the final run the rate dropped at epochs 79, 85, 91 and 113 (1e-4 → 1e-5 → 1e-6 → 1e-7 → 1e-8).
- *Constant learning rate* (`--lr-patience 0`): no schedule. Used for the Roboflow runs, because with only 6 validation photos the validation loss is noisy and the plateau rule cuts the rate too early (@sec-lr-story).
- *Early stopping* (`--early-stop 40`): stop after 40 epochs without improvement. The final run stopped at epoch *147*; best checkpoint epoch *107*.
- *Checkpoint*: `best.pt` holds the weights, both memories, the epoch, the val scores and every argument (`src/train.py:193-201`).

== Mixed precision (AMP)
*Automatic mixed precision* runs the forward pass in 16-bit floats (fp16) where it is safe, which is faster and uses less memory, especially on Tensor Cores (Kaggle's T4). A *GradScaler* multiplies the loss before `backward` so small fp16 gradients do not underflow to zero, then unscales them before the Adam step.
#code[`src/train.py:166` creates `torch.amp.GradScaler("cuda")` if `--amp`; `:85` `torch.autocast(..., dtype=torch.float16)`; `:87` the loss is computed in fp32 (`logits.float()`) because the Dice sums are large; `:91-94` scaled backward and step.]
Measured on the RTX 5050 (README §5.7): a batch of 8 at 256×256 takes 259 ms in fp32 and 146 ms with AMP; an epoch about 33 s vs 24 s. Which runs used AMP (from the stored arguments): the 512×512 official run, the LDSD runs and the Roboflow runs. The main 256×256 Kvasir run was fp32 (the flag did not exist yet).

== Hyper-parameters of the final run (`runs/kvasir_official`)
#table(columns: (auto, 1fr),
  [Setting], [Value (from the checkpoint's stored arguments)],
  [Input], [256×256],
  [Batch], [8],
  [Optimiser], [Adam, lr $10^(-4)$, ReduceLROnPlateau ×0.1, patience 5],
  [Epochs], [up to 200, early stop 40: ran 147, best 107],
  [Augmentation], [`--memory-aug official`],
  [Memory update], [`on-improve` (official rule)],
  [Seed], [42],
  [Hardware / time], [RTX 5050 laptop, fp32, about 42 s per epoch, 1.7 hours in total],
)

#fig("figures/learning_curves.png", [Learning curves of the final run. Left: loss (train and test). Right: test Dice per epoch.], w: 80%)

#trap[The curve's test Dice climbs to about *0.908*, but the headline is *0.842*. Why? During training the test images are fed with *their own memory* (the model's earlier predictions for them). The paper's test protocol instead starts from Otsu and refines 10 rounds. Same weights, different starting mask.]

// =====================================================================
= Testing: iterative refinement <sec-testing>

== The official test protocol
```text
memory[i] = Otsu(test image i)                      (round 0)
repeat 10 times:
    pred = FANet(image, memory[i]);  memory[i] = pred > 0.5;  record metrics
```
#code[`src/evaluate.py:81` builds the memory (Otsu, or zeros for a no-feedback checkpoint); `:82-84` `--start zeros` empties it; `:95-120` the loop; `:108` `memory.write` puts the prediction back; `:122-125` writes one row per round to `results.csv`; `:127-132` saves strips (image, truth, Otsu, round 1, round 2, ...).]

== What happens round by round (main model, `runs/kvasir_official`)
#table(columns: (auto, auto, auto, auto, auto),
  [Round], [Dice (Otsu start)], [Precision], [Recall], [Dice (empty start)],
  [1], [0.615], [0.530], [0.965], [0.829],
  [2], [0.739], [0.687], [0.955], [0.869],
  [3], [0.796], [0.766], [0.947], [0.884],
  [5], [0.832], [0.820], [0.938], [0.893],
  [10], [*0.842*], [0.835], [0.934], [*0.900*],
)
From Otsu, round 1 *over-segments* (recall 0.965, precision 0.530: the mask is far too big because Otsu marked 60% of the image). Each round trims it: precision rises, recall falls a little. Most of the gain is in the first two to four rounds. Refinement adds *+0.23 Dice* from Otsu (0.615 → 0.842).

#fig("figures/refinement_rounds.png", [Test metrics after each refinement round, Otsu start (same figure as the report).], w: 70%)
#fig("figures/strip_kvasir_official.png", [Three test images. Columns: image, ground truth, Otsu start, round 1, round 2, round 10.], w: 88%)

== The empty start (our variant)
`python -m src.evaluate ... --start zeros`: same weights, the round-0 memory is empty instead of Otsu. Round 1 is already 0.829, round 10 is *0.900*, above the paper's 0.880. This changes the *test procedure*, not the model, so it is reported separately. The headline reproduction stays *0.842*.

== The memory probe: does the model check its memory or copy it?
`python -m src.memory_probe --ckpt runs/<run>/best.pt --data data/Kvasir-SEG`: *one* forward pass on the 120 test images from five different starting masks.

#table(columns: (1fr, auto, auto, auto, auto),
  [Starting memory (one pass)], [Aligned run: Dice], [Precision], [Recall], [Official run: Dice],
  [Otsu (official start)], [0.536], [0.440], [0.955], [0.615],
  [all zeros ("nothing")], [0.517], [0.965], [*0.415*], [*0.828*],
  [all ones ("everything")], [0.383], [*0.267*], [0.993], [0.518],
  [its own training-time memory], [0.848], [0.886], [0.881], [0.908],
  [ground truth (oracle)], [0.958], [0.971], [0.956], [0.935],
)
*Reading.* The aligned model *copies* its memory: given nothing, recall falls to 0.41; given everything, precision falls to 0.27. The model trained the official way (memory misaligned for two-thirds of samples) has learned to *check* the memory against the image: from an empty memory it still scores 0.828. But an over-full start (all ones, or Otsu at 60%) still pulls its first pass.

#say[An apparent bug in the authors' code is doing real work. They rotate and flip the image but not its memory mask. My first run fixed that, and the model learned to copy its memory: from an empty start its recall fell to 0.41. With the authors' misalignment the model has to check the memory against the image, so it works as a regulariser.]

== Speed
About *87 images per second* on the RTX 5050 at 256×256 (round 10 of `results.csv`; round 1 is slower because it includes CUDA warm-up). The 512×512 model ran at about 13 images/s on Kaggle's T4 (not comparable). The paper reports 68.18 FPS on a GTX 1050 Ti at 512×512.

// =====================================================================
= Every experiment we ran <sec-experiments>

All Kvasir rows: 120 test images, per-image scores averaged, 10 refinement rounds from Otsu unless stated. "Train-time" = test Dice logged during training with the model's own memory. Source files in brackets.

#{
set text(8.4pt)
set par(justify: false)
show raw.where(block: false): it => text(font: "DejaVu Sans Mono", size: 7.2pt, fill: rgb("#14545e"), it.text)
table(columns: (auto, 4.3cm, 1.35fr, 0.95fr, 1.3fr),
  [\#], [Experiment (folder)], [What it tested / settings], [Result], [What it means],
  [1], [First run, aligned memory (`runs/kvasir`)], [memory moved with flips/90° turns; 256, batch 8, laptop fp32; 116 epochs, best 76], [Dice *0.684* (round 1 0.536); train-time 0.844], [The model learned to copy its memory and fails from Otsu. Led to the official mode.],
  [2], [Main run, official aug (`runs/kvasir_official`)], [paper's augmentation, memory not moved; 256, batch 8, laptop fp32; 147 epochs, best 107], [Dice *0.842*, mIoU 0.779, recall 0.934, precision 0.835, F2 0.868; round 1 0.615], [Our headline reproduction. 0.038 below the paper.],
  [3], [Empty-start test of run 2 (`eval_test_zeros`)], [same weights, round-0 memory zeros], [*0.900*, mIoU 0.841; round 1 0.829; boxes 0.836 / 0.896], [Otsu start hurts. Test-procedure variant, reported separately.],
  [4], [Memory probe (`memory_probe.csv` in runs 1 and 2)], [one pass from Otsu / zeros / ones / own memory / ground truth], [zeros: 0.517 (aligned) vs 0.828 (official)], [Misaligned memory acts as a regulariser.],
  [5], [No-feedback ablation (`runs/kvasir_nofb`)], [`--no-feedback`: memory always zeros; Kaggle T4, fp32, batch 8; 116 epochs, best 76; aligned-style aug (trained before official mode existed); one pass], [*0.883*, mIoU 0.817, recall 0.897, precision 0.915], [Above FANet from Otsu (0.842), only 0.017 below the empty start (0.900): feedback adds little.],
  [6], [512×512, aligned (`runs/kvasir512`)], [paper's size and 100 epochs, batch 4, fp32, Kaggle (log: Tesla T4); best epoch 93], [*0.504* (train-time 0.827)], [Memory copying again, at the paper's resolution.],
  [7], [512×512, official (`runs/kvasir512-official`)], [same with official aug, `--amp`, Kaggle T4; best.pt epoch 80], [*0.831*, mIoU 0.758 (train-time 0.879); 13 FPS], [Not better than 256: resolution is not the gap. Empty-start test not done.],
  [8], [Synthetic leaves (`runs/leaf_before`, `runs/leaf`)], [60 generated images, 48/12; fine-tune from run 2, 60 epochs, lr 5e-5; 3 rounds, best round], [before *0.474*, after *0.984*], [Transfer works but the task is too easy.],
  [9], [LDSD zero-shot (`runs/ldsd_zeroshot`)], [polyp model on 118 LDSD test photos, no training], [Otsu 0.010 (round 1 0.129); empty 0.004], [Domain gap: a polyp model does not see leaf spots.],
  [10], [LDSD fine-tune (`runs/ldsd_finetune`)], [470 LDSD photos with LDSD masks, from polyp weights, 60 epochs, lr 5e-5, AMP; best 46], [Otsu *0.670*, empty *0.681*], [Upper reference with 20× more labelled data.],
  [11], [LDSD from scratch (`runs/ldsd_scratch`)], [same 470 photos, random weights, 60 epochs, lr 1e-4; best 60], [Otsu *0.678*, empty *0.667*], [With 470 photos transfer makes no difference.],
  [12], [Roboflow fine-tune, first (`runs/roboflow_leaf`)], [my 24 photos (120 with copies), val 6; from polyp weights, lr 5e-5, plateau schedule; lr cut at epochs 13, 19, 25, 31; best epoch 7; stopped at 47], [Otsu 0.472, empty 0.465], [Schedule cut the lr too early (noisy 6-photo val).],
  [13], [Roboflow scratch, first (`runs/roboflow_leaf_scratch`)], [same data, random weights, lr 1e-4, 60 epochs, best 55 (lr never cut)], [Otsu 0.434, empty 0.419], [Reference for row 12.],
  [14], [*Roboflow fine-tune, constant lr* (`runs/roboflow_leaf_constlr`)], [`--lr-patience 0`, 100 epochs, lr 5e-5, AMP; best 89], [Otsu *0.517*, empty *0.520*], [Main leaf result.],
  [15], [*Roboflow scratch, constant lr* (`runs/roboflow_leaf_scratch_constlr`)], [same, random weights, lr 1e-4; best 99], [Otsu *0.467*, empty *0.461*], [With only 24 photos, transfer helps: +0.05.],
  [16], [Label agreement (`dataset/custom/roboflow_leaf/agreement.csv`)], [my hand masks vs LDSD's masks for the same 30 photos, 256×256], [mean *0.730*, median 0.781, range 0.09 to 0.96], [My labels and LDSD's use slightly different definitions of "disease".],
)
}

== Reading the Kvasir results honestly
#table(columns: (1fr, auto, auto, auto, auto, auto),
  [Model (120 test images)], [Dice], [mIoU], [Recall], [Precision], [F2],
  [FANet, paper (512×512)], [0.880], [0.815], [0.906], [0.901], [0.887],
  [Paper's baseline without MixPool], [0.852], [0.773], [0.884], [0.871], [0.861],
  [*Ours, paper's protocol* (Otsu start, round 10)], [*0.842*], [*0.779*], [0.934], [0.835], [0.868],
  [Ours, Otsu start, round 1 only], [0.615], [0.512], [0.965], [0.530], [0.729],
  [*Ours, empty start* (round 10)], [*0.900*], [*0.841*], [0.900], [0.935], [0.898],
  [Ours, no feedback (ablation)], [0.883], [0.817], [0.897], [0.915], [0.886],
  [Ours, 512×512, 100 epochs], [0.831], [0.758], [0.917], [0.831], [0.860],
  [Aligned memory (first run)], [0.684], [0.589], [0.958], [0.619], [0.775],
)
This is the report's Table (§6) plus the aligned row from slide 14.

+ *The gap.* Under the paper's own protocol we are 0.038 below (0.842 vs 0.880). Close for an independent from-scratch implementation.
+ *Not the resolution.* The 512×512 run (paper's size, paper's 100 epochs) scores 0.831, no better.
+ *Remaining candidates.* Batch 8 instead of 2 (4 at 512); a test split that may hold different images (ours is a random seed-42 split); run-to-run variance (each setting trained once; 0.01 to 0.02 differences are within noise).
+ *The starting mask matters.* Otsu marks about 60% of the image, so round 1 over-segments. From an empty mask the same weights reach 0.900.
+ *The ablation is the key row.* With the feedback switched off the same network gets 0.883. So the memory is worth at most +0.017 (empty start) and costs 0.04 from the Otsu start. The paper claims +0.03 (0.852 → 0.880).

#trap[*Our ablation is not identical to the paper's B1.* The paper's B1 *removes* MixPool. Our `--no-feedback` *keeps* MixPool but fills the memory with zeros forever, so MixPool's attention is only the (untrained) fmask gate. Also, our ablation was trained with the older aligned-style augmentation (flips, 90° turns, brightness) instead of ±35° rotations. So it is a fair but not perfectly controlled comparison. Possible reasons the feedback helps less for us: larger batch, different augmentation, a different test split, single runs, and the 13% of parameters in fmask heads that never train.]

// =====================================================================
= Transfer learning and the custom dataset <sec-custom>

== Transfer learning and fine-tuning
A network trained on one dataset has already learned general features (edges, textures, blob shapes). *Transfer learning* reuses them. *Fine-tuning* starts training on the new task from those weights instead of random numbers, usually with a smaller learning rate (ours 5e-5 vs 1e-4). It helps most when the new dataset is small. A *domain gap* is the drop in accuracy when test images look different from training images.
#code[`src/train.py:159-162`: `--init runs/kvasir_official/best.pt` loads the polyp weights. The memory is rebuilt from Otsu for the new images (`:155-156`); everything else is the normal training loop.]

== Why leaves?
Colonoscopy images cannot be collected by a student. So we kept the *task* (segment irregular blobs on a textured surface) and changed the *domain* to *disease spots on leaves*. It also shows transfer learning.

== Step 1 (earlier): a synthetic dataset made by a script
`python -m src.make_synthetic procedural --out dataset/custom/synthetic_leaf --n 60 --seed 0`, split 48 / 12.
+ Random plain background colour.
+ A leaf: an ellipse in a random green, with a midrib and side veins.
+ 1 to 4 spots: each an irregular blob (a circle whose radius wobbles with angle: a sum of sines plus noise, `src/make_synthetic.py:37-47`), brown with a yellow halo. The same polygon is filled white on the mask; both are clipped to the leaf.
+ Camera realism: random blur, a lighting gradient, Gaussian noise.
Masks are exact (we drew the spots); every random choice is logged in `generation_log.csv`, boxes in `bboxes.json`; the same seed regenerates the same set. Result: polyp model 0.474 before, 0.984 after fine-tuning. *Too easy* (clean shapes, plain backgrounds), and ma'am later asked for a manual dataset in Roboflow. So the final custom dataset uses real photos.

== Step 2: the source photos (LDSD)
- *LDSD, Leaf Disease Segmentation Dataset* (Kaggle, F. Alam, 2021, licence *CC0* public domain): *588* real photos of diseased leaves taken from *PlantDoc* (Singh et al., 2020), each with a disease mask. The photos are "in the wild": hands, soil, other leaves, watermarks.
- Split with `python -m src.split --data data/LDSD/data/data --test 0.2`: *470 train / 118 test*. The *118 test photos are the leaf test set* for every leaf result, scored against LDSD's masks, never used in training.
- *30 photos* were picked from the 470-photo *training* pool by a seeded pick (at least 300 px, disease covering 3 to 50% of the image). List: `dataset/custom/roboflow_upload_list.txt`. They were uploaded to Roboflow *without* their masks.

#trap[*How were the photos taken?* We did not take them. Taking our own photos of diseased leaves was not possible, so the photos are public (LDSD, CC0). *The labels are ours*, drawn by hand. Ma'am's 30 Oct instruction allowed this route: "if building one from scratch does not suit the project, take a separate image set and apply flips/rotations in Roboflow to show it was used." Say this plainly; do not claim you photographed them.]

== Step 3: building the dataset in Roboflow (7 Nov)
+ *Project.* Workspace `chaitanyadl`, project `leaf-disease-seg`, type *Semantic Segmentation*, one class. (Why: an Object Detection project would store only boxes, and FANet learns from pixel masks. An earlier Object Detection project was replaced. The class ended up named after the project; the name does not matter because every labelled pixel counts as disease.)
+ *Upload* the 30 photos, no masks.
+ *Label by hand.* One labelling job per photo (30 jobs). Every disease spot outlined with *Smart Polygon* (SAM-assisted: click a spot, it proposes an outline, you adjust it) and the plain *Polygon* tool. About *2 hours* in total. *Labelling rule*: brown or dead tissue on every leaf in the photo, and standalone yellow blotches; thin yellow rims around brown spots excluded; one shape around a dense cluster of tiny dots.
+ *Split*: 24 train / 6 valid / 0 test. (Our real test set is LDSD's 118 photos.)
+ *Version v1, preprocessing*: Auto-Orient; Resize, *stretch to 256×256* (the training size; image and mask stretch together).
+ *Augmentation* (training photos only): horizontal and vertical *flip*; *90° rotate* (clockwise, counter-clockwise, upside down); *rotation ±15°*; *brightness ±15%*. *5 outputs* per training photo (the free-plan maximum). Total: 24 × 5 = *120 train* + *6 valid* = *126 images*.
+ *Export*: format *Semantic Segmentation Masks* (`leaf-disease-seg.v1i.png-mask-semantic.zip`). Each split folder holds `NAME.jpg` + `NAME_mask.png`; each mask pixel is a *class number* (0 background, 1 disease), not 0/255. Roboflow renames files `ORIGINAL_jpg.rf.<hash>.jpg`.
+ *Convert*: `python -m src.roboflow_to_masks --src <unzipped> --out dataset/custom/roboflow_leaf --compare data/LDSD/data/data`. Every non-zero class becomes foreground; Roboflow's train/valid folders become `train.txt` (120) / `val.txt` (6), so training picks its checkpoint on Roboflow's *valid* photos.
+ *Published*: public on Roboflow Universe, `universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne`. Eleven screenshots of every step are in the submission package.

#fig("figures/roboflow_steps.png", [My screenshots (report Fig., slide 12): (1) labelling one photo, each layer is one outlined spot; (2) the 30 labelling jobs; (3) resize to 256×256; (4) the 90° rotation augmentation.], w: 95%)

#fig("figures/roboflow_version.png", [Version v1 in Roboflow: split, preprocessing and augmentation (slide 13).], w: 80%)

== Offline vs online augmentation
Roboflow's 5× copies are *offline* augmentation: fixed files made once. Our training code also flips and rotates *online*, differently in every epoch. Both happen in the Roboflow runs. Validation photos are never augmented, so they stay real.

== Step 4: how good are my labels? (label agreement)
LDSD has its own masks for the same 30 photos, an independent check. Dice between my label and LDSD's (per photo, at 256×256, best-matching copy): *mean 0.730, median 0.781, range 0.09 to 0.96*. The biggest disagreements are definitions, not careless labels: on `leaf_00278` LDSD marks the whole yellowed leaf where I marked only the spots (Dice 0.09); on `leaf_00076` I marked more of the speckled area (0.37). Best match `leaf_00260` (0.96).
#fig("figures/roboflow_agreement.png", [My label (pink) and LDSD's (blue). Top: close agreement (Dice 0.96). Bottom: a definition difference (Dice 0.09).], w: 62%)

== Step 5: results on real leaves
#table(columns: (1fr, auto, auto),
  [Model, tested on 118 LDSD photos, 10 rounds], [Otsu start], [Empty start],
  [Polyp model, no fine-tuning], [0.010], [0.004],
  [*My Roboflow set (24 photos ×5), from polyp weights*], [*0.517*], [*0.520*],
  [*My Roboflow set, from random weights*], [0.467], [0.461],
  [My Roboflow set, default lr schedule (fine-tuned / scratch)], [0.472 / 0.434], [0.465 / 0.419],
  [470 LDSD photos, from polyp weights], [0.670], [0.681],
  [470 LDSD photos, from random weights], [0.678], [0.667],
)
+ *Domain gap.* Without fine-tuning the polyp model finds almost nothing on leaves (0.129 after one round), and refinement makes it worse (0.010 after 10): its masks shrink to nothing.
+ *Transfer helps when data is small.* With 24 photos: 0.517 vs 0.467 (+0.05; +0.06 from the empty start). With 470 photos it made no difference (0.681 vs 0.667, 0.670 vs 0.678).
+ *Data matters most.* Twenty times less labelled data costs about 0.16 Dice (0.52 vs 0.68).
+ *Leaves are harder than polyps*: many small scattered spots, cluttered backgrounds, coarse reference masks. And the model learns *my* definition of a spot but is scored against *LDSD's* (they agree only at 0.730).

== Why the constant learning rate <sec-lr-story>
The first Roboflow runs used the default schedule (lr ×0.1 after 5 epochs without validation improvement). With only 6 validation photos the validation loss is noisy, so in the fine-tuned run the rate was cut at epochs 13, 19 and 25 (three times within 30 epochs) and its best checkpoint was epoch 7. Re-run with `--lr-patience 0` (constant rate) for 100 epochs: best epochs 89 (fine-tuned) and 99 (scratch); both models improved by about 0.04 (0.472 → 0.517, 0.434 → 0.467). The rule was fixed *before* looking at the test scores: the constant-rate runs became the main result whichever way they turned out, and the first runs stay in the table.

#trap[One nuance the slides do not show: the first *from-scratch* Roboflow run never had its rate cut (constant 1e-4 for all 60 epochs, best epoch 55). Its improvement in the re-run comes from training 100 instead of 60 epochs, not from the schedule. If asked: "the schedule problem hit the fine-tuned run; for a fair comparison both were re-run with the same constant-rate, 100-epoch recipe."]

== All splits at a glance
#table(columns: (auto, auto, auto, auto, 1fr),
  [Dataset], [Train], [Val], [Test], [How made],
  [Kvasir-SEG], [880], [(= test)], [120], [`src.split`, seed 42],
  [LDSD], [470], [(= test)], [118], [`src.split --test 0.2`, seed 42],
  [Roboflow v1], [24 photos → 120], [6], [0 (use LDSD's 118)], [Roboflow split, 5× offline augmentation on train],
  [Synthetic leaves], [48], [(= test)], [12], [`src.split --test 0.2`],
)

#say[I built my own dataset in Roboflow. Taking my own photos of diseased leaves was not possible, so I took 30 real photos from a public CC0 leaf-disease set and outlined every disease spot by hand with Roboflow's polygon tools, about two hours of work. I split them 24 and 6, resized to 256 by 256, and generated a version with flips, 90-degree turns, small rotations and brightness changes, five copies per training photo, 126 images in all. My labels agree with the source dataset's masks at Dice 0.73. Fine-tuned from my polyp weights, FANet gets 0.517 on 118 unseen leaf photos, against 0.467 from random weights, so with little data transfer learning helps.]

// =====================================================================
= Hardware, setup and Kaggle <sec-kaggle>

== The laptop
- *GPU*: NVIDIA GeForce RTX 5050 Laptop GPU, 8 GB (Blackwell). Needs a CUDA 12.8 build of PyTorch (`torch 2.11.0+cu128` in the notebook). Virtual environment `~/.venvs/dlproject`.
- At 256×256, batch 8 uses about 4 GB; an epoch takes 35 to 55 s in fp32 (the GPU slows down near 89 °C). At 512×512 only batch 4 fits in 8 GB, so the 512 runs went to Kaggle.

== Why Kaggle
Kaggle gives free GPUs (a *T4* or a *P100*, 16 GB each), about 30 GPU-hours a week, 12 hours per session, and *two sessions at once*. That let us run the ablation and the 512×512 runs in parallel with laptop work, and at 512×512 the 16 GB card is needed. The T4 is only fast in fp16 (Tensor Cores), so `--amp` matters most there.

== How `kaggle/offload.sh` works
```bash
# push <name> <gpu> "<train args>" <eval rounds>
kaggle/offload.sh push kvasir-nofb t4 "--epochs 200 --batch 8 --no-feedback" 1
kaggle/offload.sh status kvasir-nofb
kaggle/offload.sh pull kvasir-nofb          # -> runs/kvasir_nofb/
```
+ *push*: zips the current `src/` and uploads it as a new version of a private Kaggle dataset (code); fills `kaggle/run_template.py` with the training arguments; pushes it as a *private script notebook* with GPU on and internet off, using two private datasets: the code and our exact Kvasir-SEG copy with *our* `train.txt` / `test.txt` (so the 120 test images are the same as on the laptop). The CLI exits 0 even when Kaggle refuses a push (e.g. the 2-session limit), so the script checks the message.
+ The notebook runs `src.train` then `src.evaluate --iters N` and leaves `runs/<name>/` in the output.
+ *pull*: downloads the output into `runs/<name>/` and keeps the Kaggle log as `kaggle.log`.

== Which run ran where, and how long
#table(columns: (auto, auto, auto, auto),
  [Run], [Where], [Epochs], [Total time (sum of `log.csv` seconds)],
  [`kvasir` (aligned)], [laptop, fp32], [116], [1.5 h],
  [`kvasir_official` (main)], [laptop, fp32], [147], [1.7 h],
  [`kvasir_nofb`], [Kaggle T4, fp32], [116], [1.7 h],
  [`kvasir512` (aligned)], [Kaggle (log: Tesla T4), fp32], [100], [5.5 h],
  [`kvasir512-official`], [Kaggle T4, AMP], [100], [2.9 h],
  [LDSD fine-tune / scratch], [laptop, AMP], [60 / 60], [about 0.35 h each],
  [Roboflow runs], [laptop, AMP], [47 to 100], [2 to 7 minutes each],
)
The Kaggle logs show two Tesla T4 cards (15 GB each) attached; our code uses one.

== Trained weights
Model-only checkpoints with a model card on Hugging Face: `huggingface.co/Ckorion/fanet-polyp-leaf-from-scratch` (Kvasir 256, LDSD-470 fine-tuned, Roboflow fine-tuned, Roboflow scratch).

// =====================================================================
= The deck, slide by slide <sec-deck>

19 slides, built by `node presentation/build_deck.js` from the CSVs in `runs/` (so the numbers on the slides are read from the files, not typed). Target: 12 to 15 minutes. For each slide: what is on it, and what to say.

#slide(1, "Title", [title "Polyp Segmentation with FANet", subtitle (IEEE TNNLS 2023, from scratch on Kvasir-SEG, transfer to plant disease spotting), name and roll number, a Kvasir image with its mask.],
  [Good morning ma'am. My project is polyp segmentation with FANet, a feedback attention network from IEEE TNNLS 2023. I implemented it from scratch in PyTorch, trained it on the paper's own dataset Kvasir-SEG, and transferred it to leaf disease spots using my own Roboflow dataset.])
#slide(2, "Outline", [five numbered parts in the order of the PPT brief: Problem Statement, Proposed System, Dataset Used, Result Analysis, Future Scope, one line each.],
  [My talk has five parts, in the order of the brief: the problem, the proposed system, the datasets, the result analysis and the future scope.])
#slide(3, "One in four adenomas is missed", [26% miss rate (Zhao et al. 2019); −3% cancer risk per +1% detection rate (Corley et al. 2014); why a pixel mask; hard cases; "decision support, not diagnosis".],
  [Colorectal cancer starts as a polyp. In back-to-back colonoscopies about a quarter of adenomas are missed, and every 1% more detection lowers later cancer risk by about 3%. A model that outlines the polyp pixel by pixel can be a second pair of eyes. It is decision support only.])
#slide(4, "Segmentation labels every pixel", [classification vs detection vs segmentation; image, ground-truth mask, overlay; binary task, threshold 0.5; polyps cover 14% of a test image.],
  [The brief says segmentation or detection, not classification. My output is a 0/1 mask for every pixel. The detection view is a box around each connected blob of the mask. Polyps cover only 14% of the image, so the classes are imbalanced.])
#slide(5, "FANet remembers its last prediction", [paper citation and DOI; 7 datasets, we reproduce Kvasir-SEG; three ideas: mask memory across epochs, hard attention at every stage, refinement at test time.],
  [FANet has three ideas: it keeps the mask it predicted for each training image, it uses that mask as hard attention in a MixPool block in every encoder and decoder stage, and at test time it refines its own mask for up to 10 rounds. Ground truth is never fed in; the memory starts from an Otsu threshold.])
#slide(6, "Architecture", [encoder 1-4 and decoder 1-4 boxes with channels and sizes, skip connections, previous mask into every block; inside the blocks; 7,720,266 parameters.],
  [It is a U-Net that also takes the previous mask. Each encoder has two residual blocks, a MixPool and max pooling; each decoder has a transposed convolution, the skip connection, two residual blocks and a MixPool. The previous mask is max-pooled into every MixPool and concatenated before the last 1×1 conv. 7.72 million parameters.])
#slide(7, "MixPool", [the MixPool diagram (fmask head, previous mask max-pooled, F OR M, masked half and unmasked half, concat); why two halves; the fmask finding.],
  [A small head guesses a mask from the features; the previous mask is max-pooled to the same size; their OR is the attention. One half of the features only sees the attended region, the other half sees everything, so a wrong mask cannot erase the polyp. I found that the > 0.5 threshold has no gradient, so 982,088 parameters, 13%, never train.])
#slide(8, "Feedback loop and refinement", [four steps: Start (Otsu), Predict, Stage, Commit if loss improved; augmentation (memory not moved); test-time refinement; an Otsu example; Otsu marks 60%, polyps 14%.],
  [Before epoch 1 every memory is an Otsu mask. Each prediction is staged, and only if the loss improves does it become the memory, so the memory comes from the best model so far. At test time I start from Otsu and feed the prediction back for 10 rounds. Otsu marks 60% of the image while polyps are 14%, so it is a poor start.])
#slide(9, "Written from scratch", [table of the `src/` files with what they do and their line counts; "Not used": pretrained weights, torchvision.models, segmentation_models_pytorch, the authors' repo; "Also built": Roboflow converter, Kaggle offload, the deck generator.],
  [Everything is written from PyTorch primitives: conv, batch norm, transposed conv, pooling, Adam. No pretrained weights or model libraries; the authors' code was only read to check details. I also wrote the Roboflow converter, the Kaggle offload script and the deck generator.])
#slide(10, "Setup", [Kvasir-SEG facts; 880/120, seed 42; a table comparing paper, authors' code and this project (input, batch/epochs, optimiser, loss, augmentation, test, hardware).],
  [Kvasir-SEG has 1000 images with doctor-drawn masks. I use the paper's 880/120 split ratio with seed 42. The paper trains at 512 for 100 epochs; the authors' code uses 256, batch 2, up to 500 epochs. I train at 256 with batch 8 on my laptop and at 512 on Kaggle. Like the authors' code, the checkpoint is chosen on the test images, which is slightly optimistic.])
#slide(11, "Own dataset: 30 leaf photos in Roboflow", [grid of the 30 labelled photos; how it was built (task kept, domain changed; LDSD CC0 photos; hand labels, about 2 hours; Semantic Segmentation project); public link.],
  [Polyp images need a hospital, so I kept the same task and moved to leaf disease spots. The photos are public, CC0, because taking my own was not possible; the labels are mine, drawn by hand. I chose a Semantic Segmentation project because a detection project stores only boxes and FANet needs pixel masks.])
#slide(12, "Roboflow, step by step", [four of my screenshots: labelling by hand, the 30 jobs, resize to 256, augmentation; then split 24/6/0, version v1 (126 images), export, convert.],
  [These are my screenshots from 7 November: labelling each spot with Smart Polygon and Polygon, one job per photo, resizing to 256 by 256, and the augmentations. Then I split 24 and 6, generated version 1 with 126 images, exported semantic masks and converted them with my script.])
#slide(13, "Version v1", [screenshot of the generated version; why these settings; offline vs online augmentation.],
  [No Roboflow test split, because my test set is LDSD's 118 photos that are never trained on. Stretch to 256 because that is the training size. Flips and turns because a leaf has no natural up; brightness for different light. Five copies only on train, so validation stays real. Roboflow's copies are offline; my code also augments online every epoch.])
#slide(14, "Results on the 120 test images", [the results table (paper, official protocol, round 1, empty start, 512, no feedback, aligned) and the ablation and detection notes.],
  [Under the paper's protocol I get 0.842 against 0.880. Round 1 alone is 0.615, so refinement adds a lot. From an empty start the same weights get 0.900. At 512 I get 0.831, so resolution is not the gap. The honest key row: without feedback the network gets 0.883, so in my runs the memory adds little. The detection view finds 80% of polyp boxes at IoU 0.5.])
#slide(15, "Refinement chart", [line chart of test Dice per round: Otsu start (0.615 → 0.842), empty start (0.829 → 0.900), paper 512 as a reference line; refinement strips.],
  [Each round feeds the previous mask back in. From Otsu the first mask is far too big, and every round trims it. Starting from an empty mask the model climbs from 0.829 to 0.900. Most of the gain comes in the first few rounds.])
#slide(16, "Finding: aligned memory teaches copying", [bar chart of one-pass Dice from five starting masks, aligned run vs official run; four bullet points.],
  [My first run rotated the memory with the image, which looked like a fix. The model then copied its memory: given nothing, recall fell to 0.41; given everything, precision fell to 0.27. In the authors' code two-thirds of samples have a misaligned memory, so the model must check it. With that, an empty start works: 0.83 against 0.52.])
#slide(17, "Real leaves: labels and transfer", [my label vs LDSD's on two photos; 0.73 agreement; the results table on 118 LDSD photos; three bullets.],
  [My labels agree with LDSD's masks at 0.73; most misses are definitions, like LDSD marking a whole yellow leaf. Without fine-tuning the polyp model finds almost nothing: a domain gap. With only 24 photos, starting from the polyp weights helps: 0.517 against 0.467. I used a constant learning rate because with 6 validation photos the usual schedule cut it too early.])
#slide(18, "Future scope", [three cards. More and richer own data: more Roboflow photos, several classes (softmax output, multi-channel memory). Closer to the paper: full protocol with several seeds for the 0.038 gap, other polyp datasets such as CVC-ClinicDB, a separate validation split. Towards real use: previous video frame as the memory, train the fmask soft gate, faster inference.],
  [Each next step answers a limit I found. First, more labelled leaf photos, since 24 training photos are the main limit. Then the paper's full protocol with several seeds, to see if the 0.038 gap is real, and its other datasets. For real use, video is a natural fit: the previous frame's mask is a free memory.])
#slide(19, "Conclusion", [one-line summary; Works / Limits / Next columns.],
  [FANet is reproduced from scratch: 0.842 with the paper's protocol, 0.900 from an empty start. What works: the full model, refinement (+0.23 from Otsu), the copying finding, boxes from masks, and my Roboflow dataset. Limits: feedback adds little in my ablation, 512 is no better, one dataset of seven, and the checkpoint is chosen on the test images. Next: more labelled leaf photos, a trainable soft fmask, and video, where the previous frame is a natural feedback input.])

// =====================================================================
= The report, section by section <sec-report>

The submitted report (`docs/report.pdf`, 10 pages, dated 7 November 2026). What each section says, so you can point to it.

#table(columns: (auto, 1fr),
  [Section], [What it says (and what to be ready for)],
  [Title page + abstract], [Title "Polyp Segmentation for Colorectal Cancer Screening using FANet", subtitle "with transfer to plant-disease spot segmentation on an own Roboflow dataset". Abstract: 0.842 (paper 0.880), 0.900 empty start, 512 gives 0.831, no-feedback 0.883, unaligned memory is a regulariser, Roboflow set (30 photos, 24/6, 5×), labels agree at 0.730, leaves 0.517 vs 0.467.],
  [1 Introduction], [Polyps, 1-in-4 miss rate [10], −3% per +1% detection [9]; the brief; requirement table.],
  [2 Background], [Semantic segmentation, U-Net, residual block, SE, hard attention, Otsu.],
  [3 The base paper], [Feedback memory; 3.1 architecture diagram (E1-E4, D1-D4, previous mask in red), 7,720,266 parameters; 3.2 MixPool in six steps; 3.3 training rule and test-time refinement.],
  [4 Implementation], [Plain PyTorch, no pretrained weights; file table; deviations: batch 8, ≤ 200 epochs with early stop 40, tensor memory, BCE on logits; checkpoint chosen on test images (stated).],
  [5 Experimental setup], [Kvasir-SEG 880/120 with a fixed seed; 256 (and 512); Adam 1e-4, plateau ×0.1 patience 5, batch 8; RTX 5050 + Kaggle; stopped at epoch 147, best 107; per-image metrics averaged.],
  [6 Results on Kvasir-SEG], [Main table; gap 0.038; resolution ruled out; refinement figure (0.615 → 0.842); strips. 6.1 detection view (0.685 / 0.800, mean IoU 0.881; 0.836 / 0.896). 6.2 findings: feedback adds little (0.883); unaligned memory is a regulariser (probe 0.517/0.383 vs 0.828/0.518); 982,088 fmask parameters never train.],
  [7 Own dataset in Roboflow], [7.1 motivation, LDSD 470/118, 30-photo pick; 7.2 Roboflow steps (project type, labelling rule, version v1, export, converter) + screenshots; 7.3 label agreement 0.730 (median 0.781, range 0.09-0.96); 7.4 leaf results table and the constant-lr explanation.],
  [8 Limitations], [Single runs (0.01-0.02 is noise); checkpoint on test images (Roboflow on 6 val photos); one of seven datasets, split may differ; own dataset small, photos public, labels ours; not clinical.],
  [9 Conclusion and future work], [Summary; future: more labelled leaf photos, soft fmask gate, repeated seeds, video.],
  [10 Deliverables], [Submission package: 01 presentation, 02 notebook, 03 Roboflow dataset (zip, 11 screenshots, agreement CSV), 04 report, 05 code (+ results CSVs); weights published separately.],
  [References], [13: FANet, Kvasir-SEG, U-Net, ResNet, SENet, Otsu, Adam, BatchNorm, Corley (NEJM 2014), Zhao (Gastroenterology 2019), PlantDoc, LDSD, Roboflow docs.],
)

// =====================================================================
= Viva bank <sec-viva>

Short answers in simple words. Say them out loud. The hard "trap" questions are in the last group.

== A. The paper
#qa[What is the name of your paper and where was it published?][FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation, by Tomar et al., IEEE Transactions on Neural Networks and Learning Systems, vol. 34, no. 11, 2023 (online 2022).]
#qa[Why does it fit the brief?][IEEE journal, within 5 years, a segmentation CNN, and more advanced than a plain U-Net (memory, MixPool, test-time refinement).]
#qa[What problem does the paper point out?][Networks see each image many times in training but throw away their earlier predictions. FANet uses them.]
#qa[What is FANet's main idea in one sentence?][Remember the last predicted mask for each image and feed it back as hard attention in every block; at test time, refine the mask by feeding it back several times.]
#qa[What is the "memory"?][One binary mask per image: the model's earlier prediction for that image (Otsu at the start).]
#qa[Where does the first mask come from?][Otsu thresholding of the blurred grey image. Classical, no learning.]
#qa[When is the memory updated?][Only when the validation loss improves, so it always comes from the best model so far.]
#qa[What is iterative refinement?][At test time: start from Otsu, predict, put the prediction back as the memory, predict again; 10 rounds.]
#qa[On how many datasets did the paper test?][Seven: Kvasir-SEG, CVC-ClinicDB, DRIVE, CHASE-DB1, 2018 Data Science Bowl, ISIC 2018, EM. I reproduced Kvasir-SEG.]
#qa[What does the paper report on Kvasir-SEG?][Dice 0.8803, mIoU 0.8153, recall 0.9058, precision 0.9005, at 512×512; 68.18 FPS on a GTX 1050 Ti.]
#qa[What does the paper's ablation show?][Without MixPool (baseline B1) Dice is 0.8516, so they claim about +0.03 from their block.]

== B. Architecture
#qa[Draw the architecture.][Four encoder blocks (32, 64, 128, 256 channels), four decoder blocks back to 16 channels, skip connections between same-size stages, the previous mask into every block, concat with the previous mask, 1×1 conv to one logit map.]
#qa[What is inside an encoder block?][Two residual blocks, a MixPool, then 2×2 max pooling. The skip is taken before MixPool.]
#qa[What is inside a decoder block?][Transposed conv to double the size, concat the skip, two residual blocks, a MixPool.]
#qa[Explain MixPool step by step.][fmask head guesses a mask (> 0.5); the previous mask is max-pooled to the feature size; attention = fmask OR previous mask; masked features through one conv, unmasked features through another; concatenate.]
#qa[Why max-pool the previous mask and not average-pool it?][Max keeps a cell at 1 if any pixel in it was 1, so small polyps survive the shrinking. Averaging would fade them.]
#qa[Why does MixPool keep an unmasked half?][So a wrong mask cannot destroy information. The network learns how much to trust each half.]
#qa[What is the residual block?][Two 3×3 conv + BN on the main path, a 1×1 conv + BN + SE shortcut, add, ReLU. It learns a correction and keeps gradients flowing.]
#qa[What does squeeze-and-excitation do?][Learns one weight per channel from the globally averaged features and rescales the channels: channel attention.]
#qa[What is odd about SE here?][The official code sets reduction equal to the channel count, so the hidden layer has one unit. I copied it to stay faithful.]
#qa[How many parameters?][7,720,266. Most are in E4 and D1 (256 channels).]
#qa[What is the output shape?][1×256×256 logits per image; sigmoid and > 0.5 give the mask.]
#qa[Why transposed convolution, not a plain resize?][It is learned upsampling: the network learns how to fill in detail.]
#qa[Why is the previous mask concatenated again before the head?][So the last layer can also use the hint directly; that is how the official model is built.]

== C. Training
#qa[What loss did you use and why?][0.5·BCE + 0.5·Dice. BCE gives smooth per-pixel gradients; Dice handles the imbalance (polyps 14%) and matches the metric.]
#qa[Why `binary_cross_entropy_with_logits`?][Same value as sigmoid + BCE but numerically safer: no log of zero.]
#qa[Which optimiser and learning rate?][Adam, 1e-4 (5e-5 for fine-tuning).]
#qa[What learning-rate schedule?][ReduceLROnPlateau: ×0.1 after 5 epochs without improvement. In the final run it cut at epochs 79, 85, 91, 113. Constant rate for the Roboflow runs.]
#qa[Batch size and epochs?][Batch 8, up to 200 epochs, early stop after 40 without improvement. Final run: 147 epochs, best epoch 107.]
#qa[What augmentation?][The authors' recipe: rotate ±35°, horizontal and vertical flips, each with probability 0.3, plus cut-out holes on the image. The memory mask is not moved.]
#qa[Why not move the memory with the image?][I tried it (aligned). The model then copied its memory and failed from Otsu (0.684). Leaving it misaligned forces the model to check the memory against the image.]
#qa[What fraction of samples have a misaligned memory?][About two-thirds: 1 − 0.7³ ≈ 0.66.]
#qa[What is AMP and did you use it?][Mixed precision: fp16 forward pass with a GradScaler, loss in fp32. About 1.8× faster per batch on my laptop (146 vs 259 ms). Used for the 512 run on Kaggle and the leaf runs; the main 256 run was fp32.]
#qa[Why does the dataset return an index?][So each image finds its memory slot; it allows shuffling. The official code kept a fixed order.]
#qa[How long did training take?][The main run: 147 epochs, about 42 s each on the RTX 5050, about 1.7 hours.]
#qa[Which checkpoint is used?][The one with the lowest validation loss (`best.pt`), epoch 107 for the main run.]

== D. Metrics
#qa[What is Dice?][Overlap: 2TP / (2TP + FP + FN). 1 is perfect, 0 is no overlap. It equals F1.]
#qa[What is IoU and how does it relate to Dice?][TP / (TP + FP + FN), stricter. Per image, IoU = Dice / (2 − Dice).]
#qa[Why not accuracy?][Polyps are 14% of the image, so an empty prediction already gets about 86% accuracy but Dice 0.]
#qa[Precision vs recall here?][Precision: of what I marked, how much is polyp. Recall: of the real polyp, how much I found. Recall matters most clinically.]
#qa[What is F2?][An F-score that weights recall more than precision: 5PR / (4P + R).]
#qa[Are metrics per image or over all pixels?][Per image, then averaged over the 120 images, as the authors' test script does.]
#qa[What is mIoU?][IoU averaged over the test images.]
#qa[How do you score the detection view?][Boxes around connected blobs (≥ 20 px), matched to true boxes greedily at IoU ≥ 0.5; box precision 0.685, box recall 0.800 (official protocol).]

== E. Results
#qa[What is your main result?][Dice 0.842, mIoU 0.779 with the paper's protocol on 120 test images, against the paper's 0.880.]
#qa[What is 0.900?][The same weights, but the refinement starts from an empty mask instead of Otsu. Our variant of the test procedure, reported separately.]
#qa[What did the ablation show?][Without feedback (memory always zeros) the same network gets 0.883. So the feedback adds little in my reproduction.]
#qa[How much does refinement help?][From Otsu: 0.615 after round 1, 0.842 after round 10 (+0.23). From empty: 0.829 → 0.900.]
#qa[Why is round 1 from Otsu so low?][Otsu marks about 60% of the image, so the first prediction is far too big (recall 0.965, precision 0.530). Each round trims it.]
#qa[What did the 512 run give?][0.831 with the paper's protocol. Not better than 256, so resolution is not the gap.]
#qa[What is your most interesting finding?][The authors' misaligned memory acts as a regulariser: aligning it made the model copy its memory.]
#qa[What is the speed?][About 87 images per second on my RTX 5050 at 256×256.]
#qa[Show me a failure case.][In the strips, round 1 from Otsu marks bright glare and wall; tiny or flat polyps and glare are the hard cases.]

== F. Custom dataset
#qa[What is your own dataset?][30 real diseased-leaf photos, every disease spot labelled by hand by me in Roboflow, split 24/6, resized to 256, augmented 5× on train: 126 images.]
#qa[Why leaves?][Colonoscopy images cannot be collected by a student. Same task (irregular blobs on a textured surface), different domain; it also tests transfer.]
#qa[Where do the photos come from?][LDSD, a public CC0 Kaggle set of 588 real photos from PlantDoc. I did not take them; the labels are mine.]
#qa[How did you pick the 30 photos?][A seeded pick from LDSD's 470 training photos: at least 300 px, disease covering 3 to 50%. None of them is in the 118 test photos.]
#qa[Which Roboflow tools did you use?][Smart Polygon (SAM-assisted) and Polygon, about 2 hours for all 30.]
#qa[Why a Semantic Segmentation project?][A detection project stores only boxes; FANet learns from pixel masks.]
#qa[What augmentations and why?][Flips, 90° turns, ±15° rotation (a leaf has no natural up), ±15% brightness (different light), 5 copies per training photo, train only.]
#qa[Why no Roboflow test split?][My test set is LDSD's 118 photos, never used in training, and scored with LDSD's own masks.]
#qa[How do you know your labels are good?][LDSD has masks for the same 30 photos: mean Dice 0.730, median 0.781. The big misses are definition differences, e.g. LDSD marking a whole yellow leaf.]
#qa[What was the export format, and what did you change?][Semantic Segmentation Masks: masks hold class numbers 0/1, not 0/255. My converter makes non-zero foreground and keeps Roboflow's train/valid split.]
#qa[What is the result on leaves?][0.517 on 118 LDSD photos fine-tuned from polyp weights, 0.467 from random weights.]
#qa[Why constant learning rate?][With 6 validation photos the loss is noisy and the plateau rule cut the rate too early (best epoch 7). The rule was fixed before seeing test scores.]

== G. Implementation and code
#qa[Where is MixPool in your code?][`src/blocks.py`, class `MixPool`, forward at lines 109 to 116.]
#qa[Where is the memory?][`src/memory.py`, class `MaskMemory`: `get`, `stage`, `commit`, `write`; Otsu at lines 17 to 36.]
#qa[Where is the training loop?][`src/train.py`: `run_epoch` (54 to 111) and the epoch loop in `main` (177 to 217).]
#qa[Where is the refinement loop?][`src/evaluate.py`, lines 95 to 120; `--start zeros` at 82 to 84.]
#qa[Where is the memory committed?][`src/train.py:187-190`: if the validation loss improved, both memories commit.]
#qa[How do you run training and testing?][`python -m src.train --data data/Kvasir-SEG --out runs/kvasir_official`; `python -m src.evaluate --ckpt runs/kvasir_official/best.pt --data data/Kvasir-SEG --split test --iters 10`.]
#qa[How does the no-feedback flag work?][`MaskMemory(feedback=False)` fills the memory with zeros and `stage` does nothing, so the model never sees a previous mask. `evaluate.py` reads the flag from the checkpoint.]
#qa[What bug did you find and fix?][`load_mask` kept pixels above 127, which made class-index masks (Roboflow, LDSD) completely empty. Fixed on 31 Oct: indices if max ≤ 10, otherwise half the max. Kvasir results unchanged (polyp fraction 0.1423 before and after).]
#qa[How did you deviate from the official code?][Batch 8 not 2, ≤ 200 epochs with early stop not 500, memory as a tensor indexed by image, BCE on logits, runs on CUDA/MPS/CPU.]
#qa[How are the deck numbers produced?][`presentation/build_deck.js` reads `results.csv`, `memory_probe.csv` and `log.csv` from `runs/`, so nothing is typed by hand.]

== H. General deep-learning theory
#qa[What is a CNN and why use it for images?][A network of convolution layers: small filters slid over the image. Local connections and weight sharing give few parameters and find a pattern anywhere.]
#qa[What do padding and stride do?][Padding adds border pixels to control size; stride is the step. Output = floor((n + 2p − k)/s) + 1; 3×3 with p = 1, s = 1 keeps the size.]
#qa[What is a receptive field?][The input area that affects one output pixel; it grows with depth and with pooling.]
#qa[What does batch normalisation do?][Normalises each channel over the batch, then a learned scale and shift; faster, more stable training.]
#qa[Why ReLU?][Non-linearity, cheap, does not saturate for positive values; without non-linearity layers collapse into one linear map.]
#qa[What is backpropagation?][The chain rule applied backwards through the network to get the gradient of the loss for every weight.]
#qa[What is overfitting and how did you fight it?][Fitting training data but not new data. Augmentation, batch norm, early stopping, and the misaligned memory acting as a regulariser. No dropout layers are used.]
#qa[What is transfer learning?][Reusing weights learned on one task to start another; fine-tuning continues training them, usually with a smaller learning rate.]
#qa[What is the difference between semantic and instance segmentation?][Semantic gives a class per pixel; instance separates individual objects of the same class.]
#qa[What are skip connections in U-Net for?][They bring high-resolution encoder features to the decoder so edges stay sharp.]
#qa[What is attention? Soft vs hard?][Weighting inputs by importance. Soft uses learned weights in [0, 1] and is differentiable; hard uses a 0/1 mask.]
#qa[Why a validation set?][To choose the checkpoint and settings without touching the test set, so the test score is unbiased.]
#qa[What is an epoch, a batch, an iteration?][Epoch: one pass over all training images. Batch: images processed together. Iteration: one update step on one batch.]
#qa[Why sigmoid and not softmax at the output?][Binary task with one output channel; sigmoid gives the probability of "polyp" per pixel.]

== I. Trap questions (answer honestly)
#qa[Why is your number lower than the paper's?][0.842 vs 0.880 under the same protocol. Not resolution: my 512 run is 0.831. Likely: batch 8 instead of 2, a different random test split, single runs without seed averaging. My ablation also suggests the Otsu start costs points.]
#qa[Why is the 512 run not better?][Same 100 epochs, smaller batch (4), mixed precision, and one run only; with its own memory it reached 0.879, close to the paper, but from the Otsu start it got 0.831. So the input size is not what we are missing. Its empty-start test was not done.]
#qa[What happens if you remove the feedback?][0.883: better than FANet from Otsu (0.842) and 0.017 below the empty start (0.900). In my runs the feedback adds little.]
#qa[So is the paper wrong?][I cannot say that from one run. The paper reports +0.03 from MixPool. My ablation is different (it keeps MixPool with zero memory, trained with older augmentation), runs once, and 0.01 to 0.02 is within noise. My honest conclusion: I could not reproduce a clear gain from the feedback.]
#qa[Is this really detection?][It is segmentation. The detection view draws a box around each connected blob and scores it at IoU ≥ 0.5. There is no detector head and no confidence, so no mAP.]
#qa[Is this from scratch?][Yes in the brief's sense: every layer from PyTorch primitives (Conv2d, BatchNorm2d, ConvTranspose2d, Linear, pooling); my own data loader, augmentation, loss, metrics, Otsu, connected components, training and evaluation; no pretrained weights, no model zoo, no segmentation library. The architecture is the paper's, and I read the authors' code to check details.]
#qa[Did you use the test set as validation?][For Kvasir, yes, exactly like the authors' code (their validation set is the 120 test images), so the numbers are comparable but slightly optimistic. I state it in the report. The Roboflow runs are clean: checkpoint on 6 Roboflow validation photos, test on 118 LDSD photos never seen.]
#qa[Isn't feeding your own prediction back cheating?][No. Ground truth is never an input. The memory holds only Otsu or the model's own predictions, and the same happens at test time.]
#qa[Then why is 0.900 not your headline?][It changes the test procedure, which I chose after seeing results. The paper's protocol starts from Otsu, so the fair reproduction number is 0.842.]
#qa[Did you take the leaf photos yourself?][No. They are public CC0 photos from LDSD. The hand labels in Roboflow are mine. Ma'am's Roboflow instruction allowed taking a separate image set.]
#qa[0.517 is low. Is the model bad?][Leaves are harder (many tiny spots, cluttered photos), I trained on only 24 photos, and the test masks are LDSD's while my labels follow a slightly different definition (agreement 0.730). With 470 photos the same model gets about 0.68.]
#qa[Why does the polyp model get 0.010 on leaves?][Domain gap: it learned polyps, not leaf spots. Refinement makes it worse because each round shrinks its small, uncertain masks to nothing.]
#qa[Why did refinement help Kvasir but not every leaf model?][On Kvasir the start (Otsu) is too big and rounds trim it. On leaves from an empty start the fine-tuned model peaks around round 5 and then drifts slightly; the effect is small.]
#qa[Why does the learning curve show 0.908 but you report 0.842?][During training the test images use their own memory (the model's earlier predictions). The paper's test starts from Otsu. Same weights, different start.]
#qa[Did 13% of parameters really never train? How do you know?][A backward pass leaves `grad = None` for 48 tensors, 982,088 values, all in the fmask heads, because `> 0.5` has no gradient. The notebook prints it.]
#qa[Were all runs on the same test images?][Yes. Kaggle runs used a private copy of our Kvasir folder with our own `train.txt` / `test.txt`.]
#qa[Why batch 8 when the authors use 2?][To use the GPU better and fit the time. It is one candidate cause of the gap: batch norm statistics and the number of updates differ.]
#qa[Did you use AI tools?][Answer truthfully. A fair way to put it: "I used AI assistance for parts of the code and documentation; I have read and checked every part, I ran every experiment, and I can explain and modify any line." Never claim something you did not do.]
#qa[Is your result statistically reliable?][Each setting was trained once with seed 42, so differences of 0.01 to 0.02 Dice are within run-to-run noise. Repeated seeds are future work.]

// =====================================================================
= Inconsistencies you should know about <sec-incons>

Checked line by line. None of them changes a headline number, but ma'am might notice. For each: what is true (from the logs) and what to say.

#table(columns: (auto, 1fr, 1fr),
  [\#], [What differs], [The truth and what to say],
  [1], [Paper precision: slide 14 shows *0.900*; report and project book show *0.901*.], [The paper's value is 0.9005; the deck rounds down, the report rounds up. "0.9005, rounding."],
  [2], [470-photo LDSD from scratch (Otsu start): README says *0.679*; report, deck and book say *0.678*.], [The CSV value is 0.67846, so *0.678* is right. The README rounding is off.],
  [3], [README says the first (aligned) 512 run used a *Kaggle P100*; the report says "Kaggle T4/P100".], [The Kaggle log of that run shows *Tesla T4* cards. All three Kaggle runs ran on T4s. Say "Kaggle T4".],
  [4], [README says the official 512 run's "best epoch 77".], [Epoch 77 had the highest test Dice, but `best.pt` is chosen by lowest loss: *epoch 80*. Its numbers (0.831) are from epoch 80.],
  [5], [Report §7.4 and slide 17: with the default schedule "the rate was cut ... and both models scored about 0.04 lower".], [True for the fine-tuned run (cuts at 13, 19, 25, 31; best epoch 7; early-stopped at 47). The first scratch run never had its rate cut (60 epochs at 1e-4, best 55); its re-run gain comes from 100 vs 60 epochs.],
  [6], [Slide 8: "cut-out holes on image and ground truth".], [Rotation and flips move image and ground truth; cut-out is applied to the *image only* (`src/train.py:82`).],
  [7], [Notebook text and project book say the final model was trained with `--amp`.], [The checkpoint's stored arguments show no AMP: the main run (19 Oct) predates the flag. AMP was used for the 512-official, LDSD and Roboflow runs.],
  [8], [Report §8 says checkpoints were chosen on test images for Kvasir and on 6 val photos for Roboflow.], [Also true but unstated: the 470-photo LDSD runs and the synthetic-leaf runs had no val split either, so they selected on their test sets too (`train.py:147`). Only the Roboflow runs are fully clean.],
  [9], [Report's "no feedback" row is listed as a plain ablation.], [It was trained with the older aligned-style augmentation (flips, 90° turns, brightness), not ±35° rotations (README notes this). Mention it if pushed.],
  [10], [Empty start round 1: slide 15 says *0.829* (from `evaluate.py`); slide 16 / report say *0.828* / 0.83 (from `memory_probe.py`).], [Two scripts, tiny numerical difference (0.8292 vs 0.8284); same for Otsu 0.6148 vs 0.6151. Not a real discrepancy.],
  [11], [Slide 9 line counts (e.g. `blocks.py` 117, `train.py` 224).], [`wc -l` gives one less (116, 223): the deck counts the empty line after the final newline. Harmless.],
  [12], [Report says the 256 model runs at "about 87 images/s"; project book says "about 88".], [87.3 (Otsu start) and 88.4 (empty start) in `results.csv`. Both fine.],
)

*Facts that could not be verified from the repo* (do not volunteer them as certain):
- Which polyp checkpoint `runs/leaf_before` (synthetic-leaf zero-shot, 0.474) used: no arguments are stored for an evaluation. README §9.3 shows `runs/kvasir/best.pt`, while the fine-tuned synthetic run started from `runs/kvasir_official/best.pt`.
- The script that picked the 30 Roboflow photos is not in the repo; only the resulting list and the rule (≥ 300 px, 3 to 50% disease, seeded) are documented.
- The paper's full Table IX (other ablation rows) and its exact training details beyond those listed here are not stored in the repo (no paper PDF). Ma'am's answers to the questions in the project book (e.g. whether public photos are acceptable) are not recorded.
- The 2-hour labelling time and the Roboflow free-plan 5× limit come from the docs, not from a log.

// =====================================================================
= Cheat sheet <sec-cheat>
#{
set text(8.5pt)
set par(justify: false, leading: 0.5em)
grid(columns: (1fr, 1fr), gutter: 10pt,
[
  #text(font: "Inter", weight: "bold", size: 9.5pt)[Kvasir-SEG, 120 test images]
  #table(columns: (1fr, auto, auto), inset: 3pt,
    [Setting], [Dice], [mIoU],
    [Paper (512)], [0.880], [0.815],
    [Paper B1, no MixPool], [0.852], [0.773],
    [*Ours, paper protocol*], [*0.842*], [*0.779*],
    [Ours, round 1 (Otsu)], [0.615], [0.512],
    [Ours, empty start], [0.900], [0.841],
    [No feedback], [0.883], [0.817],
    [Ours, 512 official], [0.831], [0.758],
    [Aligned (first run)], [0.684], [0.589],
    [Aligned 512], [0.504], [0.400],
  )
  Ours: recall 0.934, precision 0.835, F2 0.868. Boxes 0.685 / 0.800 (empty 0.836 / 0.896). About 87 img/s.

  #text(font: "Inter", weight: "bold", size: 9.5pt)[Memory probe (one pass, Dice)]
  #table(columns: (1fr, auto, auto), inset: 3pt,
    [Start], [Aligned], [Official],
    [Otsu], [0.536], [0.615],
    [zeros], [0.517], [0.828],
    [ones], [0.383], [0.518],
    [own memory], [0.848], [0.908],
    [ground truth], [0.958], [0.935],
  )
  #text(font: "Inter", weight: "bold", size: 9.5pt)[Leaves, 118 LDSD test photos (Otsu / empty)]
  #table(columns: (1fr, auto), inset: 3pt,
    [No fine-tuning], [0.010 / 0.004],
    [*Roboflow 24, polyp weights*], [*0.517 / 0.520*],
    [Roboflow 24, random weights], [0.467 / 0.461],
    [First runs (ft / scratch)], [0.472 / 0.434],
    [LDSD 470, polyp weights], [0.670 / 0.681],
    [LDSD 470, random weights], [0.678 / 0.667],
    [Synthetic (before → after)], [0.474 → 0.984],
  )
],
[
  #text(font: "Inter", weight: "bold", size: 9.5pt)[Model and training]
  - 7,720,266 params; fmask 982,088 (12.7%, 48 tensors) never train.
  - 40.5 GFLOPs per 256² image. Widths 32-64-128-256; D4 16 ch; head 17 → 1.
  - Loss 0.5·BCE + 0.5·Dice. Adam 1e-4. Plateau ×0.1, patience 5. Batch 8. Early stop 40.
  - Final run: 147 epochs, best 107, laptop fp32, about 1.7 h.
  - Aug: rotate ±35°, h/v flip (p 0.3 each), cut-out on image; memory not moved (≈ 2/3 misaligned).
  - Otsu marks 59.6%, polyps 14.2%.
  - Gap to paper 0.038. Refinement from Otsu +0.23. Feedback vs no feedback: +0.017 at best.

  #text(font: "Inter", weight: "bold", size: 9.5pt)[Data]
  - Kvasir-SEG 1000 → 880 / 120, seed 42, 256².
  - LDSD 588 → 470 / 118 (CC0, PlantDoc photos).
  - Roboflow: 30 photos → 24 / 6 / 0; ×5 → 120 + 6 = 126. Stretch 256², flips, 90°, ±15°, ±15% brightness. Agreement 0.730 (median 0.781).

  #text(font: "Inter", weight: "bold", size: 9.5pt)[Hardware]
  - RTX 5050 laptop 8 GB (main 256 runs, leaf runs).
  - Kaggle T4 16 GB (no-feedback, both 512 runs), `kaggle/offload.sh`.

  #text(font: "Inter", weight: "bold", size: 9.5pt)[File map (`src/`)]
  - `blocks.py`: SE, residual, *MixPool* 109-116
  - `model.py`: encoder 27, decoder 41, FANet 56-88
  - `memory.py`: Otsu 17-36, memory 39-83
  - `losses.py` 14-29 · `dataset.py` 59-113 · `split.py`
  - `augment.py`: official 78-99
  - `train.py`: step 54-111, commit 187-190
  - `evaluate.py`: refinement 95-120
  - `metrics.py`: Dice 27-45, boxes 68-149
  - `memory_probe.py` · `roboflow_to_masks.py`
])
v(4pt)
text(font: "Inter", weight: "bold", size: 9.5pt)[Commands (from the repo root)]
show raw.where(block: true): it => block(fill: luma(243), inset: 6pt, radius: 3pt, width: 100%, text(7.6pt, it))
```bash
python -m src.model                                         # shapes + 7,720,266
python -m src.split --data data/Kvasir-SEG                  # 880 / 120, seed 42
python -m src.train --data data/Kvasir-SEG --out runs/kvasir_official [--amp]
python -m src.train --data data/Kvasir-SEG --out runs/kvasir_nofb --no-feedback
python -m src.evaluate --ckpt runs/kvasir_official/best.pt --data data/Kvasir-SEG \
    --split test --iters 10 [--start zeros]
python -m src.memory_probe --ckpt runs/kvasir_official/best.pt --data data/Kvasir-SEG
kaggle/offload.sh push|status|pull <name> [t4|p100 "<train args>" <rounds>]
python -m src.roboflow_to_masks --src <export> --out dataset/custom/roboflow_leaf \
    --compare data/LDSD/data/data
python -m src.train --data dataset/custom/roboflow_leaf \
    --out runs/roboflow_leaf_constlr --init runs/kvasir_official/best.pt \
    --epochs 100 --early-stop 0 \
    --lr-patience 0 --lr 5e-5 --amp
node presentation/build_deck.js                 # rebuild the deck
```
}
