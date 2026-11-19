// Formal project report (the document submitted to the faculty).
// Compile from the repo root:  typst compile --root . docs/report.typ docs/report.pdf

#set document(title: "FANet from scratch: project report", author: "Chaitanya Shinde")
#set page(paper: "a4", margin: (x: 2.2cm, y: 2.2cm), numbering: "1",
  header: context { if counter(page).get().first() > 1 [#set text(8.5pt, fill: luma(110)); FANet from scratch #h(1fr) Chaitanya Shinde, 231070066] })
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 11pt)
#set par(justify: true, leading: 0.62em)
#set heading(numbering: "1.1")
#show heading.where(level: 1): set block(above: 1.4em, below: 0.8em)
#show raw.where(block: true): it => block(fill: luma(244), inset: 8pt, radius: 3pt, width: 100%, it)
#show figure.caption: set text(size: 9.5pt)
#show table.cell.where(y: 0): set text(weight: "bold")
#let fig(path, cap, w: 100%) = figure(image(path, width: w), caption: cap)

#align(center)[
  #v(2.2cm)
  #text(13pt)[Deep Learning Mini-Project Report]
  #v(0.6cm)
  #text(22pt, weight: "bold")[Polyp Segmentation for Colorectal Cancer Screening \ using FANet (Feedback Attention Network)]
  #v(0.3cm)
  #text(14pt)[with transfer to plant-disease spot segmentation on an own Roboflow dataset]
  #v(1.6cm)
  #table(columns: (auto, auto), stroke: none, align: (right, left), inset: 4pt,
    [Student:], [*Chaitanya Shinde*],
    [Roll number:], [231070066],
    [Programme:], [B.Tech Computer Engineering, Semester VII, 2026–27],
    [Course:], [Deep Learning],
    [Base paper:], [N. K. Tomar et al., "FANet: A Feedback Attention Network for \ Improved Biomedical Image Segmentation," _IEEE Transactions on \ Neural Networks and Learning Systems_, vol. 34, no. 11, 2023],
    [Date:], [18 November 2026],
  )
  #v(1.6cm)
  #block(width: 88%, inset: 12pt, stroke: 0.6pt + luma(160), radius: 3pt)[
    #set align(left)
    #set par(justify: true)
    *Abstract.* We implement FANet, a feedback-attention encoder–decoder for biomedical image segmentation, from scratch in PyTorch (no pretrained weights, no model libraries) and reproduce it on the paper's dataset, Kvasir-SEG. Under the paper's test protocol (ten rounds of iterative refinement starting from an Otsu mask) our model reaches a Dice coefficient of *0.842* at 256×256, against 0.880 reported at 512×512; starting the refinement from an empty mask gives *0.900*. Additional experiments show that a 512×512 run does not close the gap (0.831), that a no-feedback ablation reaches 0.883, and that the official code's unaligned memory acts as a regulariser. For the own-dataset requirement we built a semantic-segmentation dataset in Roboflow: 30 real leaf photos whose disease spots were labelled by hand, split 24/6 and augmented five times. The hand labels agree with the source dataset's masks at Dice 0.730. Fine-tuned from the polyp weights, FANet reaches Dice *0.517* on 118 held-out leaf photos, against 0.467 when trained from random weights. For the lab's dataset rule we also built a 4-class detection set in Roboflow: 220 tomato-leaf photos, hand-drawn boxes, 572 images after augmentation.
  ]
]

#pagebreak()
#outline(depth: 2, indent: 1em)
#pagebreak()

= Introduction
Colorectal cancer usually begins as a polyp on the inner wall of the colon. Polyps found during a colonoscopy can be removed, but a meta-analysis of tandem colonoscopies reports that about one in four adenomas is missed [10], and each 1% increase in a doctor's adenoma detection rate lowers the later cancer risk by about 3% [9]. A model that outlines polyps pixel by pixel in the camera image can act as a second pair of eyes.

The faculty brief asks for an individual project on object segmentation or detection (not classification) using a CNN: implement a recent IEEE paper (at most five years old) from scratch on the paper's own dataset, build a small own dataset in Roboflow, and present the work as a PPT and a notebook. This report covers all four parts.

#table(columns: (auto, 1fr), stroke: 0.4pt, inset: 6pt,
  [Requirement], [How it is met],
  [Segmentation / detection, CNN], [FANet outputs a 0/1 mask for every pixel; boxes around the predicted blobs give a detection view (@sec-detect).],
  [IEEE paper, last 5 years], [IEEE TNNLS, vol. 34, no. 11, 2023 (online 2022).],
  [Implemented from scratch], [Every layer, the loss, training loop, metrics and refinement written with plain PyTorch primitives (@sec-impl).],
  [Paper's dataset], [Kvasir-SEG, the paper's 880/120 split ratio (@sec-setup).],
  [Own dataset in Roboflow], [30 real leaf photos labelled by hand, versioned and augmented in Roboflow (@sec-own); plus a 4-class detection set of 220 hand-boxed tomato-leaf photos for the lab rule.],
  [PPT and notebook], [20-slide deck and an executed Jupyter notebook (@sec-deliv).],
)

= Background
*Semantic segmentation* assigns a class to every pixel. For polyps it is binary: polyp or background. Most medical segmentation networks follow the *U-Net* shape [3]: an encoder that halves the resolution and doubles the channels at each stage, a decoder that upsamples back, and skip connections that copy encoder features to the decoder at the same scale so fine edges are not lost.

FANet's blocks use three standard ideas. A *residual block* [4] adds a learned correction to its input, which keeps gradients flowing in deep networks. *Squeeze-and-excitation* [5] learns one weight per channel from globally pooled features (channel attention). *Hard attention* multiplies features by a 0/1 mask, so the next layer only sees the attended region.

*Otsu's method* [6] picks the grey-level threshold that best separates an image into dark and bright pixels. FANet uses it to make a rough first mask.

= The base paper: FANet
FANet [1] adds a *feedback memory* to a U-Net-style network. For every training image the network keeps the mask it predicted in an earlier epoch and feeds it back in as a second input, where it acts as attention inside every encoder and decoder block. At test time the same idea becomes *iterative refinement*: the network's own output is fed back as the next input mask for several rounds. The paper reports Dice 0.880 on Kvasir-SEG, against 0.852 for the same network without its MixPool attention blocks.

== Architecture
#fig("../presentation/figures/diagram_architecture.png", [FANet as implemented in `src/model.py`, drawn in the style of the paper's Fig. 2(c). Bottom row: encoder; top row: decoder, read right to left; dashed: skip connections (concatenated); red: the previous mask from the memory, which enters all eight MixPool blocks and the output head. Shapes are channels × height × width for a 256×256 input. The pictures are a real test image, its Otsu start mask and the final predicted mask.])
Each *encoder block* is two residual blocks (with squeeze-and-excitation), a MixPool block and 2×2 max pooling. Each *decoder block* upsamples by a transposed convolution, concatenates the skip features, and applies two residual blocks and a MixPool block. The last decoder output is concatenated with the previous mask and a 1×1 convolution gives one channel of logits. The model has 7,720,266 parameters.

#figure(
  table(columns: (auto, 1fr, auto, auto, auto), stroke: 0.4pt, inset: 4.5pt, align: (left, left, center, right, right),
    table.header([*Stage*], [*Layers (channels in→out)*], [*Output*], [*Parameters*], [*fmask*]),
    [E1], [SE-Res 3→32, SE-Res 32→32, MixPool, MaxPool 2×2], [32×128²], [48,993], [9,345],
    [E2], [SE-Res 32→64, SE-Res 64→64, MixPool, MaxPool], [64×64²], [210,753], [37,121],
    [E3], [SE-Res 64→128, SE-Res 128→128, MixPool, MaxPool], [128×32²], [839,297], [147,969],
    [E4], [SE-Res 128→256, SE-Res 256→256, MixPool, MaxPool], [256×16²], [3,349,761], [590,849],
    [D1], [TConv 4×4/2, concat s4 (512), SE-Res 512→128, SE-Res, MixPool], [128×32²], [2,461,569], [147,969],
    [D2], [TConv, concat s3 (256), SE-Res 256→64, SE-Res, MixPool], [64×64²], [616,385], [37,121],
    [D3], [TConv, concat s2 (128), SE-Res 128→32, SE-Res, MixPool], [32×128²], [154,593], [9,345],
    [D4], [TConv, concat s1 (64), SE-Res 64→16, SE-Res, MixPool], [16×256²], [38,897], [2,369],
    [Head], [concat previous mask (17), 1×1 conv, sigmoid], [1×256²], [18], [0],
    [*Total*], [], [], [*7,720,266*], [*982,088 (12.7%)*],
  ),
  caption: [Shapes and parameter counts per stage, measured on the model with forward hooks. E4 and D1, the two lowest-resolution stages, hold 75% of the weights. The last column is the part that never trains (@sec-mixpool).],
) <tab-layers>

== MixPool: the feedback-attention block <sec-mixpool>
For features $x$ of size $C times h times w$ and the previous mask $M$:
+ a small convolutional head predicts a mask $F$ from $x$, thresholded at 0.5;
+ $M$ is max-pooled to $h times w$, so a cell is on if any pixel in it was on (small polyps survive);
+ the attention map is $A = F or M$;
+ the *masked half* $x dot A$ passes through conv–BN–ReLU to $C slash 2$ channels;
+ the *plain half* $x$ passes through its own conv–BN–ReLU to $C slash 2$ channels;
+ the two halves are concatenated.
The plain half guarantees that a wrong previous mask cannot destroy the prediction; the network learns how much to trust each half.

#fig("../presentation/figures/diagram_blocks.png", [(a) SE-Residual block: two 3×3 convolutions with batch norm on the main path, a 1×1 convolution, batch norm and squeeze-and-excitation on the shortcut, added and passed through ReLU; the inset shows the squeeze-and-excitation steps. (b) MixPool block: the thresholded fmask and the max-pooled previous mask are combined with OR into the attention map $A$; one half of the channels sees only $F times A$, the other half sees all of $F$.])

== Training with a feedback memory, and testing with refinement
Before the first epoch the memory holds the Otsu mask of every training image. In each epoch, image $i$ is passed with `memory[i]`, the loss ($0.5 dot "BCE" + 0.5 dot "Dice"$) is minimised with Adam, and the thresholded prediction is staged. Only when the validation loss improves does the staged copy replace the memory, so the memory always comes from the best model so far. The ground truth is never an input.

At test time the memory starts from Otsu and the network is run ten times, each round feeding its thresholded output back in. Metrics are recorded after every round.

#fig("../presentation/figures/diagram_loop.png", [Top: one training epoch. The hint for each image is looked up in the memory by its index (so shuffling is safe) and is not rotated with the image; predictions are staged and committed only when the validation loss improves. Bottom: testing with frozen weights; each round's mask is written back as the next round's hint. Bars: test Dice after each round of the main run.])

= Implementation <sec-impl>
Everything is written in PyTorch from basic layers (`Conv2d`, `BatchNorm2d`, `ConvTranspose2d`, pooling, `Linear`). No pretrained weights, no `torchvision.models`, no segmentation libraries. The authors' public code was read only to check details.

#table(columns: (auto, 1fr), stroke: 0.4pt, inset: 5pt,
  [File (`src/`)], [Contents],
  [`blocks.py`], [squeeze-and-excitation, residual block, MixPool],
  [`model.py`], [encoder and decoder blocks, FANet],
  [`memory.py`], [per-image mask memory, Otsu threshold],
  [`dataset.py`, `augment.py`], [loading images and masks; rotation ±35°, flips, cut-out written in torch],
  [`losses.py`, `metrics.py`], [0.5·BCE + 0.5·Dice; Dice, IoU, precision, recall, F2, boxes from blobs],
  [`train.py`, `evaluate.py`], [feedback training loop with early stopping; test-time refinement, example strips, FPS],
  [`memory_probe.py`], [how much the model relies on its memory (@sec-findings)],
  [`roboflow_to_masks.py`], [converts the Roboflow export and scores hand labels against reference masks],
)

*Deviations from the official code.* Batch 8 instead of 2 and at most 200 epochs with early stopping (patience 40) instead of 500, to fit the available time; the memory is a tensor indexed by image instead of run-length strings; BCE is computed on logits for numerical stability. As in the authors' code, the Kvasir-SEG checkpoint is selected on the test images, which is slightly optimistic; we state this wherever the numbers appear.

= Experimental setup <sec-setup>
*Dataset.* Kvasir-SEG [2]: 1000 colonoscopy images with polyp masks drawn by doctors. Split 880 train / 120 test with a fixed seed, the paper's ratio. Images resized to 256×256 (the size used in the authors' code; the paper's text uses 512×512, which we also run).

#fig("../presentation/figures/diagram_pipeline.png", [Data and scoring pipeline. Masks are resized with nearest neighbour so they stay 0/1, and cleaned with a half-of-maximum threshold because Kvasir's JPEG masks carry compression noise. Scores are computed per image and then averaged; boxes come from connected blobs of each mask.])

#fig("../presentation/assets/kvasir_example.png", [A Kvasir-SEG image, its ground-truth mask drawn by doctors, and the mask overlaid.], w: 70%)

*Training.* Adam, learning rate $10^(-4)$, ReduceLROnPlateau (factor 0.1, patience 5), batch 8, official augmentation. Hardware: RTX 5050 laptop GPU (8 GB); extra runs on Kaggle T4/P100. The final run stopped at epoch 147; the best checkpoint is from epoch 107.

*Metrics.* Per-image Dice, IoU (Jaccard), precision, recall and F2, averaged over the test images as in the authors' test script.

= Results on Kvasir-SEG <sec-results>
#figure(
  table(columns: (1fr, auto, auto, auto, auto, auto), stroke: 0.4pt, inset: 5pt, align: (left, center, center, center, center, center),
    [Model (120 test images)], [Dice], [mIoU], [Recall], [Precision], [F2],
    [FANet, paper (512×512)], [0.880], [0.815], [0.906], [0.901], [0.887],
    [Paper's baseline without MixPool], [0.852], [0.773], [0.884], [0.871], [0.861],
    [*Ours, paper's protocol* (Otsu start, round 10)], [*0.842*], [*0.779*], [0.934], [0.835], [0.868],
    [Ours, Otsu start, round 1 only], [0.615], [0.512], [0.965], [0.530], [0.729],
    [*Ours, empty start* (round 10)], [*0.900*], [*0.841*], [0.900], [0.935], [0.898],
    [Ours, no feedback (ablation)], [0.883], [0.817], [0.897], [0.915], [0.886],
    [Ours, 512×512, 100 epochs], [0.831], [0.758], [0.917], [0.831], [0.860],
  ),
  caption: [Test results. Our 256×256 model runs at about 87 images/s on the laptop GPU.],
) <tab-main>

Under the paper's protocol our reproduction is 0.038 Dice below the paper. Training at the paper's 512×512 does not close the gap (0.831), so input size is not the cause. Remaining candidates are the batch size (8 instead of 2), a test split that may contain different images, and run-to-run variance, since each setting was trained once.

#fig("../presentation/figures/refinement_rounds.png", [Test metrics after each refinement round, starting from Otsu: Dice rises from 0.615 to 0.842. The empty-start result (0.900) is in @tab-main.], w: 72%)

*Refinement.* Otsu marks about 60% of a colonoscopy image (bright wall and glare) while polyps cover 14%, so the first round is far too large and each round trims it. Starting from an empty mask avoids that and reaches 0.900. This changes the test procedure, not the model, so we report it separately from the reproduction.

#fig("../presentation/assets/strip_kvasir_official.png", [Three test images. Columns: image, ground truth, Otsu start, round 1, round 2, round 10.], w: 85%)

#fig("../presentation/figures/learning_curves.png", [Learning curves of the main run (`runs/kvasir_official/log.csv`): training and test loss (left), and test Dice per epoch with the no-feedback ablation on the same axes (right).], w: 88%)

== Detection view <sec-detect>
Bounding boxes are drawn around each connected blob of the predicted mask and matched to the ground-truth boxes at IoU ≥ 0.5. Under the paper's protocol, box precision is 0.685 and box recall 0.800 (mean matched IoU 0.881); from an empty start, 0.836 and 0.896.

== Findings beyond the paper <sec-findings>
*The feedback adds little in our reproduction.* With the memory fixed at zeros (no feedback), the same network reaches 0.883: above our FANet under the paper's protocol and 0.017 below our best setting. The paper reports a larger gain (0.852 → 0.880) than we could reproduce.

*The unaligned memory acts as a regulariser.* The official code rotates and flips each image but not its memory mask, so for about two-thirds of training samples the memory points at the wrong place. Our first run "fixed" this by moving the memory with the image. That model learned to copy its memory: probed with one pass from different starting masks, it scored 0.517 from an empty mask and 0.383 from an all-ones mask, while the model trained the official way scored 0.828 and 0.518. Forcing the network to check the memory against the image is what makes an empty start work.

#fig("../presentation/assets/report_slide-17.png", [The aligned-memory finding as shown on slide 17: one-pass Dice from different starting masks for the aligned (first) run and the official run.], w: 82%)

*Part of MixPool never trains.* The fmask head is thresholded with a step function, which has zero gradient, so 982,088 parameters (about 13% of the model) keep their random initial values. A soft (sigmoid) gate or a straight-through estimator would fix this.

= Own dataset in Roboflow <sec-own>
== Motivation and source photos
Colonoscopy images cannot be collected by a student, so we kept the *task* (segmenting irregular spots on a textured surface) and changed the *domain* to disease spots on leaves. Taking our own photos of diseased leaves was not possible, so the photos come from the public LDSD leaf-disease set [12] (CC0, real photos from PlantDoc [11]). LDSD was split 470 / 118; the 118 photos are the leaf test set. From the 470 we picked 30 photos with a seeded script (at least 300 px, disease covering 3–50% of the image) and uploaded them to Roboflow *without* their masks.

== Building the dataset in Roboflow
+ *Project:* type Semantic Segmentation (an Object Detection project would store only boxes, while FANet learns from pixel masks), one disease class.
+ *Labelling by hand:* every disease spot on all 30 photos outlined with the Smart Polygon (SAM-assisted) and Polygon tools, about two hours in total. Rule: brown or dead tissue on every leaf in the photo and standalone yellow blotches; thin yellow rims around brown spots excluded.
+ *Version v1:* split 24 train / 6 valid / 0 test; Auto-Orient; resize (stretch) to 256×256; augmentation on the training photos only: horizontal and vertical flips, 90° rotations (clockwise, counter-clockwise, upside down), rotation ±15°, brightness ±15%, five outputs per photo. Total 126 images (120 train, 6 valid).
+ *Export:* Semantic Segmentation Masks format, converted by `src/roboflow_to_masks.py` into our image/mask layout with Roboflow's split preserved.

The dataset is public at #link("https://universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne")[universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne].

#fig("../presentation/assets/roboflow_steps.png", [Screenshots taken while building the dataset: (1) labelling a photo by hand, each layer is one outlined spot; (2) the 30 labelling jobs; (3) resizing to 256×256; (4) the 90° rotation augmentation. All 11 screenshots are in the submission package.])
#fig("../presentation/assets/roboflow_grid.png", [The 30 photos in the Roboflow project with the hand-drawn polygon labels.], w: 92%)
#fig("../presentation/assets/roboflow_version.png", [Version v1 as generated in Roboflow: split, preprocessing and augmentation.], w: 92%)

== Quality of the hand labels
LDSD's own masks for the same 30 photos give an independent check. Mean Dice between our labels and LDSD's is *0.730* (median 0.781, range 0.09–0.96). The largest disagreements are differences of definition rather than careless labels: on one photo LDSD marks a whole yellowed leaf as diseased where we marked only the spots.

#fig("../presentation/assets/roboflow_agreement.png", [Our label (pink) and LDSD's (blue). Top: close agreement (Dice 0.96). Bottom: a definition difference (Dice 0.09).], w: 70%)

== Results on real leaves
All models are tested on the same 118 LDSD photos with LDSD's masks, ten refinement rounds.

#figure(
  table(columns: (1fr, auto, auto), stroke: 0.4pt, inset: 5pt, align: (left, center, center),
    [Model], [Dice, Otsu start], [Dice, empty start],
    [Polyp model, no fine-tuning], [0.010], [0.004],
    [*Our Roboflow set (24 photos ×5), from the polyp weights*], [*0.517*], [*0.520*],
    [*Our Roboflow set, from random weights*], [0.467], [0.461],
    [Our Roboflow set, default lr schedule (fine-tuned / scratch)], [0.472 / 0.434], [0.465 / 0.419],
    [470 LDSD photos, from the polyp weights], [0.670], [0.681],
    [470 LDSD photos, from random weights], [0.678], [0.667],
  ),
  caption: [Transfer to leaf disease spots. The 470-photo rows use LDSD's masks and twenty times more labelled photos; they are a reference, not a competitor.],
)

Without fine-tuning the polyp model finds almost nothing on leaves, a clear domain gap. With only 24 labelled photos, starting from the polyp weights helps (0.517 against 0.467), while with 470 photos it made no difference. Twenty times less data costs about 0.16 Dice.

*Learning-rate schedule.* The Roboflow models are trained for 100 epochs at a constant learning rate. With the default schedule (rate ×0.1 whenever the validation loss stalls for 5 epochs), the 6 noisy validation photos cut the rate to almost zero within 30 epochs and both models scored about 0.04 lower (last row). This choice was fixed before looking at the test scores. Part of the remaining gap is the label definition: the model learns our definition of a spot but is scored against LDSD's, and the two agree only at 0.730.

== Detection dataset for the lab rule
The lab also asks for a Roboflow dataset with at least 200 annotated images and at least 4 classes, for detection or segmentation. FANet is binary, so we built a separate *Object Detection* dataset; FANet stays the main project.
+ *Photos:* 220 tomato-leaf photos from PlantVillage [14], 55 from each of four classes: *bacterial spot, early blight, late blight, healthy*. The class of each photo is PlantVillage's expert label (we took every 15th photo of each class folder).
+ *Annotation:* all 233 bounding boxes drawn by hand in Roboflow: one box around the leaf, and on late blight around the blighted regions.
+ *Version v1:* split 176 train / 22 valid / 22 test; Auto-Orient; resize (stretch) to 640×640; horizontal and vertical flips, rotation ±15°, brightness ±15%, three outputs per training photo. Total 572 images. Exported in YOLOv8 format (one text file per image, one line per box: class, centre x, centre y, width, height, normalised to 0–1).

The dataset is public at #link("https://universe.roboflow.com/chaitanyadl/tomato-leaf-disease-det/dataset/1")[universe.roboflow.com/chaitanyadl/tomato-leaf-disease-det]. Training a detector on it is future work.

#fig("../presentation/assets/roboflow_det_grid.png", [One held-out photo per class from the exported detection dataset, with the hand-drawn box.], w: 55%)
#grid(columns: (1fr, 1fr), gutter: 8pt,
  image("../presentation/assets/roboflow_det/editor_bacterial_spot.png"),
  image("../presentation/assets/roboflow_det/version_v1_572.png"))
#align(center, text(9pt)[Screenshots from Roboflow: drawing a box with the four classes (left); version v1 with 572 images, its split, preprocessing and augmentation (right).])

= Limitations
- Each setting was trained once; differences of 0.01–0.02 Dice are within run-to-run noise.
- The Kvasir-SEG checkpoint was selected on the test images, as in the authors' code (slightly optimistic). The Roboflow models were selected on only 6 validation photos.
- Only one of the paper's seven datasets was used, and our 120 test images may differ from the paper's.
- The own dataset is small (30 photos) and its photos are public, not collected by us; only the labels are our own.
- Research and coursework only; not validated for clinical use.

= Conclusion and future work
FANet was implemented from scratch and reproduced on Kvasir-SEG: Dice 0.842 under the paper's protocol (paper 0.880) and 0.900 with an empty starting mask. The experiments show that resolution does not explain the gap, that the feedback memory contributes less than reported, that the official unaligned memory works as a regulariser, and that 13% of the parameters never train. A semantic-segmentation dataset of 30 hand-labelled leaf photos was built and augmented in Roboflow, and the polyp model transferred to it (0.517 Dice on 118 unseen photos, against 0.467 when trained from scratch). A separate 4-class detection dataset of 220 hand-boxed tomato-leaf photos meets the lab's Roboflow rule.

Future work: more hand-labelled leaf photos, a detector trained on the tomato-leaf set, a trainable soft gate for the fmask head, repeated runs with different seeds, and video, where the previous frame's mask is a natural feedback input.

= Deliverables <sec-deliv>
#block(breakable: false)[#table(columns: (auto, 1fr), stroke: 0.4pt, inset: 5pt,
  [Item], [Location in the submission package],
  [Presentation (20 slides)], [`01_Presentation/` (PPTX and PDF)],
  [Notebook, executed with outputs], [`02_Notebook/FANet_project.ipynb` (and an HTML copy)],
  [Roboflow dataset], [`03_Roboflow_Dataset/`: segmentation export, 11 screenshots of each step, label agreement CSV; `detection_tomato/`: YOLOv8 export and screenshots; public links above],
  [This report], [`04_Report/`],
  [Source code and result tables], [`05_Code/`: `src/`, `README.md` (full documentation and commands), `results/` (every CSV behind the numbers)],
  [Trained weights], [published separately (link in the package README)],
)]

= References
#set text(size: 10pt)
+ N. K. Tomar, D. Jha, M. A. Riegler, H. D. Johansen, D. Johansen, J. Rittscher, P. Halvorsen, S. Ali, "FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation," _IEEE Trans. Neural Netw. Learn. Syst._, vol. 34, no. 11, 2023. DOI 10.1109/TNNLS.2022.3159394.
+ D. Jha et al., "Kvasir-SEG: A Segmented Polyp Dataset," MMM 2020.
+ O. Ronneberger, P. Fischer, T. Brox, "U-Net: Convolutional Networks for Biomedical Image Segmentation," MICCAI 2015.
+ K. He, X. Zhang, S. Ren, J. Sun, "Deep Residual Learning for Image Recognition," CVPR 2016.
+ J. Hu, L. Shen, G. Sun, "Squeeze-and-Excitation Networks," CVPR 2018.
+ N. Otsu, "A Threshold Selection Method from Gray-Level Histograms," _IEEE Trans. SMC_, 1979.
+ D. P. Kingma, J. Ba, "Adam: A Method for Stochastic Optimization," ICLR 2015.
+ S. Ioffe, C. Szegedy, "Batch Normalization," ICML 2015.
+ D. A. Corley et al., "Adenoma Detection Rate and Risk of Colorectal Cancer and Death," _NEJM_, 2014.
+ S. Zhao et al., "Magnitude, Risk Factors, and Factors Associated With Adenoma Miss Rate of Tandem Colonoscopy," _Gastroenterology_, 2019.
+ D. Singh et al., "PlantDoc: A Dataset for Visual Plant Disease Detection," CoDS-COMAD 2020.
+ F. Alam, "Leaf disease segmentation dataset," Kaggle, 2021 (CC0).
+ Roboflow documentation: dataset versions, augmentation and export. docs.roboflow.com.
+ D. P. Hughes, M. Salathé, "An open access repository of images on plant health to enable the development of mobile disease diagnostics," arXiv:1511.08060, 2015 (PlantVillage).
