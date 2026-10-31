// FANet project book: everything needed to understand and present the project.
// Compile from the repo root (figures live in presentation/):
//   typst compile --root . docs/project_book.typ docs/project_book.pdf
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#set document(title: "FANet from scratch: the project book", author: "Chaitanya Shinde")
#set page(paper: "a4", margin: (x: 2cm, y: 2cm), numbering: "1")
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 10.5pt)
#set par(justify: true)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => { pagebreak(weak: true); it }
#show raw.where(block: true): it => block(fill: luma(244), inset: 8pt, radius: 3pt, width: 100%, it)
#show raw.where(block: false): it => box(fill: luma(240), inset: (x: 2pt), outset: (y: 2pt), radius: 2pt, it)
#show figure.caption: set text(size: 9pt)

#let accent = rgb("#1f6f78")
#let key(body) = block(fill: rgb("#e6f2f3"), inset: 9pt, radius: 3pt, width: 100%)[*Remember.* #body]
#let say(body) = block(fill: rgb("#fff5e0"), inset: 9pt, radius: 3pt, width: 100%)[*Say it like this.* _ #body _]
#let warn(body) = block(stroke: (left: 2pt + rgb("#e0604f")), inset: (left: 9pt, y: 4pt), body)
#let check(..items) = block(breakable: false, stroke: 0.6pt + accent, inset: 9pt, radius: 3pt, width: 100%)[
  *Check yourself* (answer out loud before moving on)
  #enum(..items)
]
#let fig(path, cap, w: 100%) = figure(image(path, width: w), caption: cap)

#align(center)[
  #v(3cm)
  #text(24pt, weight: "bold")[FANet from scratch]
  #v(2pt)
  #text(14pt)[Polyp segmentation with a Feedback Attention Network, \ with transfer to plant-disease spotting]
  #v(1cm)
  #text(12pt)[*The project book*: theory, paper, code, results, own dataset, presentation]
  #v(1cm)
  Chaitanya Shinde · 231070066 \
  B.Tech Computer Engineering, Sem VII · Deep Learning mini-project, 2026–27
  #v(0.5cm)
  Written 31 Oct 2026 · repo `DLproject`, after the audit of the same day
  #v(2cm)
  #block(width: 85%, inset: 10pt, stroke: 0.6pt + accent, radius: 3pt)[
    #set align(left)
    *How to read this.* Front to back, once. Every chapter starts from zero and ends with questions: answer them *out loud* before going on. If you only have two hours before Tuesday, read @ch-onepage, @ch-problem, @ch-paper, @ch-arch, @ch-results and @ch-tuesday, in that order.

    *Boxes.* #box(fill: rgb("#e6f2f3"), inset: 2pt)[blue] = the fact to remember; #box(fill: rgb("#fff5e0"), inset: 2pt)[yellow] = a sentence you can say in the presentation as it is.
  ]
]

#pagebreak()
#outline(depth: 2, indent: 1em)

// =====================================================================
= The project on one page <ch-onepage>

*What.* I implemented, from scratch in PyTorch, the deep-learning model of an IEEE paper: *FANet, a Feedback Attention Network* (Tomar et al., IEEE Transactions on Neural Networks and Learning Systems, 2023). It *segments* medical images: for every pixel of a colonoscopy photo it decides "polyp" or "not polyp".

*Why.* Polyps are growths in the colon that can turn into colorectal cancer. Doctors miss some of them during colonoscopy. A model that outlines polyps can act as a second pair of eyes.

*The one new idea of FANet.* A normal network forgets what it predicted for an image last time. FANet *remembers*: it stores its previous mask for every image and feeds it back in as a second input, using it as *hard attention* ("look here") inside every block. At test time this allows *iterative refinement*: predict, feed the prediction back, predict again.

*Data.* Kvasir-SEG: 1000 colonoscopy images with hand-drawn polyp masks, the paper's own dataset; 880 for training, 120 for testing, as in the paper.

*Results* (Dice: 1 = perfect overlap, 0 = none):

#table(columns: (auto, auto), stroke: 0.4pt, inset: 5pt,
  [*Setting (120 test images)*], [*Dice*],
  [Paper's FANet (512×512)], [0.880],
  [*My FANet, paper's test protocol* (256×256)], [*0.842*],
  [My FANet, refinement started from an empty mask], [0.900],
  [My network with the feedback switched off (ablation)], [0.883],
  [My FANet at 512×512], [0.831],
)

*What I found.* I reproduced the method to within 0.04 Dice. My experiments show the feedback memory helps less than the paper claims, and that part of the paper's attention block never learns (§#link(<sec-findings>)[8.4]).

*Own dataset.* Real photos of diseased leaves, labelled by hand in *Roboflow* and augmented there (flips, rotations); the polyp model is fine-tuned on them. Same task (find irregular blobs on a textured surface), different domain.

#say[My project implements FANet, an IEEE TNNLS 2023 paper, from scratch for polyp segmentation in colonoscopy images. Its idea is to feed the network's own previous prediction back in as attention, and to refine the mask over several rounds at test time. On the paper's dataset, Kvasir-SEG, I get a Dice of 0.842 with the paper's protocol, against 0.880 in the paper, and 0.900 with a better starting mask. I also built my own leaf-disease dataset in Roboflow and transferred the model to it.]

// =====================================================================
= The problem we are solving <ch-problem>

== Colorectal cancer and polyps
- *Colorectal cancer* (cancer of the colon and rectum) is among the most common and most deadly cancers in the world.
- Most cases start as a *polyp*: a small growth on the inner wall of the colon. Some polyps (called *adenomas*) slowly turn into cancer over years. If a polyp is removed early, that cancer never happens.
- Polyps are found by *colonoscopy*: a doctor moves a camera on a flexible tube through the colon, watches the video and removes the polyps they see.

== Why a computer should help
- Doctors miss polyps. Tandem studies (two colonoscopies on the same patient) find that roughly *one adenoma in four* is missed (meta-analysis by Zhao et al., _Gastroenterology_ 2019).
- Finding more of them matters: each *1% rise in a doctor's adenoma detection rate* goes with about a *3% lower risk* of later cancer (Corley et al., _NEJM_ 2014).
- Polyps are hard to see: they vary in size, shape and colour, can be flat and the same colour as the wall, and the video has glare, bubbles, blur and instruments.

== Why segmentation, not classification
#table(columns: (auto, auto, auto), stroke: 0.4pt, inset: 5pt,
  [*Task*], [*Output for one image*], [*Example*],
  [Classification], [one label], ["polyp present"],
  [Detection], [boxes + labels], [a rectangle around the polyp],
  [Semantic segmentation], [one label *per pixel*], [a mask: 1 = polyp, 0 = background],
)
A mask says *where* the polyp is, *how big* it is and *where its edges are*: what a doctor needs for removal. From a mask we can also draw boxes (detection), so segmentation gives both.

#fig("../presentation/assets/kvasir_example.png", [A Kvasir-SEG image, its ground-truth mask (drawn by experts), and the mask laid over the image.])

#warn[*Framing.* This is decision support and a proof of concept, never a diagnosis tool. Say so if asked about clinical use.]

== The dataset: Kvasir-SEG
- *1000 colonoscopy images*, each with a polyp mask drawn by doctors and checked by a gastroenterologist. From Vestre Viken hospitals in Norway, published by Jha et al. (MMM 2020) at Simula.
- Image sizes vary (from 332×487 to 1920×1072); we resize everything to 256×256 (and 512×512 in one run).
- Split, as in the paper: *880 training, 120 test* images (fixed random seed, `src/split.py`).
- On our test images the polyp covers on average *14.2%* of the picture: most pixels are background. That imbalance shapes our choice of loss and metric (@ch-train).

#check(
  [Why is a pixel mask more useful to a doctor than a yes/no label?],
  [What are the three kinds of visual task, and what does each output?],
  [How many images does Kvasir-SEG have, and how are they split?],
  [Why does it matter that polyps cover only about 14% of the image?],
)

// =====================================================================
= Deep-learning basics you need <ch-basics>

This chapter is the theory behind every line of the code. Skip what you already know.

== An image is a tensor
A colour image of height $H$ and width $W$ is a 3-D array of numbers: *3 × H × W* (red, green, blue channels), each value in $[0, 1]$ after dividing by 255. A batch of $B$ images is a 4-D tensor *B × 3 × H × W*. Our masks are *B × 1 × H × W* with values 0 or 1.

== How a network learns
1. *Forward pass:* the network turns the input into a prediction.
2. *Loss:* one number saying how wrong the prediction is (lower is better).
3. *Backward pass (backpropagation):* the chain rule computes the *gradient* of the loss with respect to every weight: which direction makes the loss smaller.
4. *Optimiser step:* every weight moves a little against its gradient. Plain gradient descent: $w <- w - eta (partial L) / (partial w)$, with *learning rate* $eta$.
5. Repeat over many *batches*; one pass over all training images is an *epoch*.

*Adam* (the optimiser we use) is gradient descent with two improvements: it keeps a running average of the gradient (momentum, smooths noise) and of its square (gives each weight its own step size). It is the default choice for most networks. Our learning rate is $10^(-4)$.

*Learning-rate schedule.* `ReduceLROnPlateau`: if the validation loss has not improved for 5 epochs, divide the learning rate by 10. Big steps first, fine steps later.

== Convolution
A *convolution* slides a small filter (here 3×3) over the image. At each position it multiplies the filter's weights with the pixels under it and adds them up: one output number. A filter that has learned "vertical edge" outputs large numbers where there is a vertical edge. A layer has many filters; each produces one output *channel* (feature map).

- *Output size:* for input size $n$, kernel $k$, padding $p$, stride $s$: $ n_"out" = floor((n + 2p - k) / s) + 1 $. Our 3×3 convs use $p = 1$, $s = 1$, so the size stays the same: $(256 + 2 - 3)/1 + 1 = 256$.
- *Parameters:* a conv from $C_"in"$ to $C_"out"$ channels with a $k times k$ kernel has $k dot k dot C_"in" dot C_"out" + C_"out"$ weights (the last term is one bias per filter). Example from our model, the first conv (3 → 32 channels): $3 dot 3 dot 3 dot 32 + 32 = 896$. Our code reports exactly 896.
- *Why convolution and not a fully connected layer?* The same filter is reused at every position (*weight sharing*), so far fewer parameters, and a pattern is recognised wherever it appears (*translation equivariance*).
- *Receptive field:* each layer sees a 3×3 neighbourhood of the previous one, so deeper layers "see" larger parts of the image. Pooling grows it faster.

== The other layers in our model
- *Batch normalisation* (`BatchNorm2d`): for each channel, subtract the batch mean and divide by the batch standard deviation, then scale and shift with two learned numbers. Keeps values in a good range, so training is faster and more stable.
- *ReLU:* $max(0, x)$. The non-linearity: without it, stacked layers would collapse into one linear map.
- *Max pooling 2×2:* keep the largest of every 2×2 block. Halves height and width. Cheaper, and each later pixel sees a wider area.
- *Transposed convolution* (kernel 4, stride 2, padding 1): learned *upsampling*, doubles height and width. Output size $(n - 1) dot 2 - 2 dot 1 + 4 = 2n$.
- *1×1 convolution:* mixes channels at each pixel without looking at neighbours. Used to change the number of channels and as the final output layer.
- *Sigmoid:* $sigma(z) = 1 / (1 + e^(-z))$ squashes any number into $(0, 1)$, read as a probability. The raw number before the sigmoid is called a *logit*. A probability above 0.5 becomes 1 in the mask.

== Training, validation, test, overfitting
- The *training set* is used to change the weights; the *test set* is only used to measure. If the model does well on training images but badly on new ones, it *overfits* (memorised instead of learned).
- *Data augmentation* fights overfitting: random flips, rotations, brightness changes and cut-out holes create new-looking training images for free. The mask must get the *same* geometric change as the image.

#check(
  [Compute the output size of a 3×3 conv with padding 1 on a 64×64 input. And of a 2×2 max-pool?],
  [How many parameters does a 3×3 conv from 32 to 64 channels have? (Answer: 18,496.)],
  [What does the sigmoid do, and what is a logit?],
  [What is the difference between an epoch and a batch?],
  [Why must a flip be applied to both the image and its mask?],
)

// =====================================================================
= Segmentation networks: U-Net, residual blocks, attention <ch-seg>

== Encoder–decoder (the U-Net shape)
A segmentation network must output a mask the *same size* as the input. The standard design (U-Net, Ronneberger et al., 2015) has two halves:
- *Encoder:* convolutions + pooling. Resolution goes down (256 → 128 → 64 → 32 → 16), channels go up (32 → 256). It learns *what* is in the image.
- *Decoder:* upsampling + convolutions. Resolution goes back up to 256. It learns *where* exactly.
- *Skip connections:* the decoder at each scale also receives the encoder's features of the same scale (concatenated). Pooling throws away fine detail; skips bring it back, so edges are sharp.

#figure(
  diagram(spacing: (3.5mm, 2.5mm), node-stroke: 0.6pt, node-corner-radius: 2pt, node-shape: rect,
    node((0,0), [input 256²], stroke: none),
    node((1,0), [enc 1 \ 256²], fill: rgb("#dcecef")),
    node((2,1), [enc 2 \ 128²], fill: rgb("#dcecef")),
    node((3,2), [enc 3 \ 64²], fill: rgb("#dcecef")),
    node((4,3), [enc 4 \ 32²], fill: rgb("#dcecef")),
    node((5,4), [bottom \ 16²], fill: rgb("#f3e3c8")),
    node((6,3), [dec 1 \ 32²], fill: rgb("#e8f3dc")),
    node((7,2), [dec 2 \ 64²], fill: rgb("#e8f3dc")),
    node((8,1), [dec 3 \ 128²], fill: rgb("#e8f3dc")),
    node((9,0), [dec 4 \ 256²], fill: rgb("#e8f3dc")),
    node((10,0), [mask 256²], stroke: none),
    edge((0,0), (1,0), "-|>"), edge((1,0), (2,1), "-|>", [pool]), edge((2,1), (3,2), "-|>"),
    edge((3,2), (4,3), "-|>"), edge((4,3), (5,4), "-|>"), edge((5,4), (6,3), "-|>", [up]),
    edge((6,3), (7,2), "-|>"), edge((7,2), (8,1), "-|>"), edge((8,1), (9,0), "-|>"), edge((9,0), (10,0), "-|>"),
    edge((1,0), (9,0), "--|>", [skip]), edge((2,1), (8,1), "--|>"),
    edge((3,2), (7,2), "--|>"), edge((4,3), (6,3), "--|>"),
  ),
  caption: [The U shape: encoder down, decoder up, skip connections across (dashed).],
)

== Residual block
#figure(
  diagram(spacing: (6mm, 6mm), node-stroke: 0.6pt, node-corner-radius: 2pt,
    node((0,0), [x], stroke: none),
    node((1,0), [conv 3×3 → BN → ReLU]), node((2,0), [conv 3×3 → BN]),
    node((3,0), [$+$], shape: circle), node((4,0), [ReLU]), node((5,0), [out], stroke: none),
    node((2,1), [shortcut: conv 1×1 → BN → SE]),
    edge((0,0), (1,0), "-|>"), edge((1,0), (2,0), "-|>"), edge((2,0), (3,0), "-|>"),
    edge((3,0), (4,0), "-|>"), edge((4,0), (5,0), "-|>"),
    edge((0,0), (0,1), (2,1), "-|>"), edge((2,1), (3,1), (3,0), "-|>"),
  ),
  caption: [Residual block (He et al., ResNet 2016), as used in FANet.],
)
The block learns a *correction* to its input instead of a whole new mapping: output = ReLU(main path + shortcut). The shortcut gives gradients a direct road back, so deep networks train well. The 1×1 conv on the shortcut makes the channel counts equal so the two paths can be added.

== Squeeze-and-excitation (SE): channel attention
For a feature map with $C$ channels (Hu et al., SENet 2018):
1. *Squeeze:* average each channel over all pixels → $C$ numbers.
2. *Excite:* a tiny two-layer network + sigmoid → $C$ weights in $(0, 1)$.
3. Multiply each channel by its weight.
The network learns, per image, which channels to boost and which to damp. In FANet the SE sits on the residual block's shortcut and its hidden layer has *exactly one unit* (the official code sets the reduction ratio equal to the channel count). We copied that to stay faithful.

== Attention: soft and hard
*Attention* means weighting parts of the input by importance.
- *Soft attention:* multiply by learned weights between 0 and 1 (SE is soft attention over channels). Differentiable, so it learns by backprop.
- *Hard attention:* multiply by a 0/1 mask: keep these pixels, zero the rest. The 0/1 step has no useful gradient.
FANet's MixPool block uses *hard spatial attention* driven by the previous mask (@ch-arch).

#check(
  [What does the encoder learn, and what does the decoder learn?],
  [What problem do skip connections solve?],
  [Why does a residual block need a 1×1 conv on its shortcut?],
  [SE is attention over what: pixels or channels? Soft or hard?],
)

// =====================================================================
= The base paper <ch-paper>

#table(columns: (auto, 1fr), stroke: 0.4pt, inset: 5pt,
  [*Title*], [FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation],
  [*Authors*], [Nikhil Kumar Tomar, Debesh Jha, Michael A. Riegler, Håvard D. Johansen, Dag Johansen, Jens Rittscher, Pål Halvorsen, Sharib Ali],
  [*Venue*], [*IEEE Transactions on Neural Networks and Learning Systems* (TNNLS), vol. 34, no. 11, 2023 (online March 2022). A top IEEE journal.],
  [*DOI*], [10.1109/TNNLS.2022.3159394 · arXiv 2103.17235 · code: github.com/nikhilroxtomar/FANet],
  [*Fits the brief*], [IEEE, within 5 years, segmentation (+ detection view), CNN, "fairly advanced" (not a plain U-Net)],
)

== The problem the paper sees
"Existing methods do not use the information from different learning epochs effectively." During training a network sees each image once per epoch, i.e. 100+ times, but each time it starts from scratch: its earlier prediction for that image is thrown away.

== The paper's idea
- Keep a *memory*: for every training image, the mask the network predicted for it in an earlier epoch.
- Feed it back as a second input, and use it as *hard attention* in every encoder and decoder block (the *MixPool* block).
- At test time, do the same in a loop: *iterative refinement*. Start from a rough mask, predict, feed the prediction back, predict again (10 rounds in the official code).

== What they evaluated
Seven biomedical datasets: Kvasir-SEG and CVC-ClinicDB (polyps), DRIVE and CHASE-DB1 (retinal vessels), 2018 Data Science Bowl (cell nuclei), ISIC 2018 (skin lesions), EM (cell membranes). *We reproduce Kvasir-SEG only*, the dataset the brief asks for.

Their Kvasir-SEG numbers (Tables II and IX): *Dice 0.8803, mIoU 0.8153, recall 0.9058, precision 0.9005*, at 512×512 input. Their ablation without MixPool (baseline B1): Dice 0.8516. So they claim the feedback idea is worth about +0.03 Dice.

#say[The paper's observation is that a network sees each image a hundred times during training but forgets its earlier predictions. FANet keeps the previous prediction for every image and feeds it back as attention, and at test time it uses the same mechanism to refine its mask over several rounds.]

#check(
  [Name the paper, the journal and the year. Why does it fit the brief?],
  [In one sentence, what does FANet remember, and what does it use the memory for?],
  [What is iterative refinement?],
  [What Dice does the paper report on Kvasir-SEG, and what does its ablation show?],
)

// =====================================================================
= FANet's architecture, block by block <ch-arch>

== The whole network
Two inputs: the *image* (3×256×256) and the *previous mask* (1×256×256, 0/1). One output: *logits* (1×256×256); sigmoid → probability → threshold 0.5 → mask.

#figure(
  diagram(spacing: (6mm, 7mm), node-stroke: 0.6pt, node-corner-radius: 2pt,
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
  caption: [FANet. The previous mask (red) goes into every encoder (E) and decoder (D) block, and is also concatenated before the output layer. Dashed: skip connections.],
)

- *Encoder block E:* ResidualBlock → ResidualBlock → *MixPool* → MaxPool 2×2.
- *Decoder block D:* transposed conv (×2 up) → concatenate the skip → ResidualBlock → ResidualBlock → *MixPool*.
- *Head:* the last decoder output (16 channels) is concatenated with the previous mask (1 channel) → 17 channels → 1×1 conv → 1 channel of logits.

== Shapes, traced for one 256×256 image
Exactly what `src/model.py` produces (check: `python -m src.model`).

#table(columns: (auto, auto, auto, auto), stroke: 0.4pt, inset: 5pt,
  [*Stage*], [*Output*], [*Skip passed on*], [*Parameters*],
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
Read the pattern: every encoder halves the size and doubles the channels; every decoder doubles the size and halves the channels. Most parameters sit at the bottom (E4, D1), where there are 256 channels: a 3×3 conv's cost grows with $C_"in" times C_"out"$.

== MixPool: the heart of FANet <sec-mixpool>
#figure(
  diagram(spacing: (4mm, 5mm), node-stroke: 0.6pt, node-corner-radius: 2pt,
    node((0,1), [$x$], stroke: none),
    node((1,0), [fmask head: conv3×3-BN-ReLU \ conv1×1-sigmoid, then > 0.5]),
    node((1,1.2), [previous mask M \ max-pooled to x's size], fill: rgb("#fde8e4")),
    node((2,0.6), [OR → attention A (0/1)]),
    node((3,0.6), [x · A → conv3×3-BN-ReLU \ (masked half)]),
    node((3,2), [x → conv3×3-BN-ReLU \ (plain half)]),
    node((4,1.3), [concat]), node((5,1.3), [out], stroke: none),
    edge((0,1), (1,0), "-|>"), edge((1,0), (2,0.6), "-|>"), edge((1,1.2), (2,0.6), "-|>"),
    edge((2,0.6), (3,0.6), "-|>"), edge((0,1), (0,2), (3,2), "-|>"),
    edge((3,0.6), (4,1.3), "-|>"), edge((3,2), (4,1.3), "-|>"), edge((4,1.3), (5,1.3), "-|>"),
  ),
  caption: [The MixPool block (`src/blocks.py`, class `MixPool`).],
)

Step by step, for features $x$ of size $C times h times w$ and the previous mask $M$ at full size:
1. *fmask:* a small conv head guesses a mask from $x$ itself; it is thresholded at 0.5 → $F in {0,1}^(h times w)$.
2. *Shrink the previous mask:* $M$ is max-pooled down to $h times w$. A cell is 1 if *any* pixel inside it was 1, so small polyps survive the shrinking.
3. *Attention* $A = F or M$ (logical OR): a pixel is attended if either the current features or the previous mask point at it.
4. *Masked half:* $x dot A$ (features outside $A$ set to zero) → conv 3×3 → BN → ReLU, giving $C/2$ channels.
5. *Plain half:* the *unmasked* $x$ → its own conv 3×3 → BN → ReLU, another $C/2$ channels.
6. Concatenate the halves → $C$ channels out.

#key[*Why two halves?* If the previous mask is wrong (e.g. the rough first guess), the plain half still carries all the information, so a bad mask cannot destroy the prediction. The network learns how much to trust each half.]

== How the first mask is made: Otsu's method
Before the network has predicted anything, each memory slot is filled with a classical guess, no learning involved (`src/memory.py`):
1. Convert the image to grey, blur it slightly (removes noise).
2. *Otsu's threshold:* try every grey level $t$ from 0 to 255; split the pixels into "darker than $t$" and "brighter than $t$"; pick the $t$ that makes the two groups as *different as possible*, i.e. maximises the *between-class variance* $ sigma_B^2(t) = omega_0(t) omega_1(t) (mu_0(t) - mu_1(t))^2 $ where $omega$ are the two groups' pixel fractions and $mu$ their mean grey levels.
3. Pixels brighter than $t$ become 1.

#fig("../presentation/assets/otsu_example.png", [A Kvasir image and its Otsu mask. Otsu picks *bright* regions (glare, lit wall), not polyps.], w: 70%)

On our 120 test images, Otsu marks *59.6%* of each image while polyps cover *14.2%*. It is a poor starting mask; this matters for our results (@ch-results).

#check(
  [Draw FANet from memory: the blocks, where the previous mask goes, where the skips go.],
  [Trace the shape of a 256×256 image through E1 and E2.],
  [List the six steps of MixPool. Why is the previous mask max-pooled and not averaged?],
  [What does the plain half protect against?],
  [What does Otsu's method maximise? Why is its mask bad for polyps?],
)

// =====================================================================
= Training and testing <ch-train>

== The training loop with feedback
#figure(
  diagram(spacing: (4mm, 6mm), node-stroke: 0.6pt, node-corner-radius: 2pt,
    node((0,0), [memory = Otsu masks \ (before epoch 1)], fill: rgb("#fde8e4")),
    node((1,0), [batch: image, truth, \ memory[i]]),
    node((2,0), [FANet(image, memory[i]) \ → logits]),
    node((3,0), [loss = 0.5 BCE + 0.5 Dice \ backprop, Adam step]),
    node((3,1), [staged[i] = prediction > 0.5]),
    node((1,1), [end of epoch: if validation \ loss improved → save model, \ memory ← staged], fill: rgb("#fde8e4")),
    edge((0,0), (1,0), "-|>"), edge((1,0), (2,0), "-|>"), edge((2,0), (3,0), "-|>"),
    edge((3,0), (3,1), "-|>"), edge((3,1), (1,1), "-|>"), edge((1,1), (1,0), "-|>", [next epoch]),
  ),
  caption: [One epoch of FANet training (`src/train.py`).],
)
- Each training image $i$ is fed together with `memory[i]`: Otsu in epoch 1, the model's own earlier prediction later.
- Predictions are first written to a *staging* copy. Only if the validation loss improved does the staging copy become the memory (and the checkpoint is saved). So the memory always comes from the *best model so far*: a bad epoch cannot poison the next epoch's input. This is the official code's rule.
- *Ground truth is never an input.* The memory only ever holds Otsu or the model's own predictions. (A favourite viva question: "isn't this cheating?" No.)

== The loss: BCE + Dice
Let $p_j$ be the predicted probability for pixel $j$ and $g_j in {0,1}$ the truth.
- *Binary cross-entropy:* $"BCE" = -1/N sum_j [g_j log p_j + (1 - g_j) log(1 - p_j)]$. Judges every pixel on its own; smooth, stable gradients; but dominated by the many background pixels.
- *Dice loss:* $1 - (2 sum_j p_j g_j + 1) / (sum_j p_j + sum_j g_j + 1)$. Measures the overlap of the whole predicted region with the true region, so a small polyp still counts.
- We use $0.5 dot "BCE" + 0.5 dot "Dice"$, as the official code does: stable gradients from BCE, and a target that matches the evaluation metric from Dice.

== Augmentation, the official way
Rotate by up to ±35°, flip horizontally, flip vertically (each with probability 0.3), plus cut-out holes. The image and its ground truth move together. *The memory mask does not move* (official behaviour). That looks like a bug: the memory then disagrees with the rotated image. We found it is actually useful (@sec-findings, finding 2).

== Hyper-parameters
#table(columns: (auto, auto, auto), stroke: 0.4pt, inset: 5pt,
  [], [*Official code*], [*Ours (final run)*],
  [Input size], [256×256 (paper text: 512)], [256×256 (and one 512 run)],
  [Batch size], [2], [8],
  [Optimiser, lr], [Adam, $10^(-4)$], [Adam, $10^(-4)$],
  [LR schedule], [ReduceLROnPlateau, patience 5], [same],
  [Epochs], [up to 500 (paper: 100)], [up to 200, stop after 40 without improvement (stopped at 147, best 107)],
  [Hardware], [GTX 1050 Ti], [RTX 5050 laptop GPU; Kaggle T4/P100 for extra runs],
)

== Testing: iterative refinement
```
memory[i] = Otsu(test image i)
repeat 10 times:
    prediction = FANet(image, memory[i]);  memory[i] = prediction > 0.5;  record the metrics
```
`src/evaluate.py` reports the metrics after *every* round (`results.csv`), so we can see how much refinement helps.

== Metrics
Per image, count pixels: *TP* (predicted polyp, truly polyp), *FP* (predicted polyp, truly background), *FN* (missed polyp), *TN* (correct background). Then average over the 120 test images, as the official script does.

#table(columns: (auto, auto, 1fr), stroke: 0.4pt, inset: 5pt,
  [*Metric*], [*Formula*], [*Meaning*],
  [Dice (F1)], [$2"TP" / (2"TP" + "FP" + "FN")$], [overlap; the headline number],
  [IoU (Jaccard)], [$"TP" / ("TP" + "FP" + "FN")$], [stricter overlap; always ≤ Dice],
  [Precision], [$"TP" / ("TP" + "FP")$], [of what I marked, how much is polyp],
  [Recall], [$"TP" / ("TP" + "FN")$], [of the polyp, how much I found],
  [F2], [$5 P R / (4P + R)$], [like F1 but recall counts more (missing a polyp is worse)],
  [Accuracy], [$("TP" + "TN") / "all"$], [misleading here: mostly background],
)

*Worked example.* A 100-pixel image, polyp = 20 pixels. The model marks 25 pixels, 15 of them on the polyp. TP = 15, FP = 10, FN = 5, TN = 70. Dice = 30/45 = *0.667*; IoU = 15/30 = *0.5*; precision = 15/25 = 0.6; recall = 15/20 = 0.75; accuracy = 85/100 = 0.85. Note how accuracy looks good while the mask is mediocre. An *empty* prediction would score accuracy 0.80 but Dice 0. That is why we use Dice.

== Detection view: boxes from masks
`src/metrics.py` finds each connected blob of the mask (8-connectivity, breadth-first search, written from scratch), draws a box around it, matches predicted boxes to true boxes by IoU ≥ 0.5, and reports box precision and box recall. That answers "where is the detection part?".

#check(
  [Why is the memory only replaced when the validation loss improves?],
  [Is ground truth ever an input to the network? Where would you look to prove it?],
  [Why combine BCE and Dice instead of using one?],
  [Do the worked example yourself with TP = 30, FP = 10, FN = 10. (Dice 0.75, IoU 0.6.)],
  [Why is accuracy a bad metric for polyps?],
)

// =====================================================================
= Our implementation <ch-impl>

== What "from scratch" means here
Every layer is built from plain PyTorch primitives (`nn.Conv2d`, `nn.BatchNorm2d`, `nn.ConvTranspose2d`, ...). The data loader, augmentation, loss, metrics, Otsu, connected components, training loop and evaluation are my own code. *No* pretrained weights, *no* model zoo, *no* segmentation library. The authors' code was only read to check details.

== The files
#table(columns: (auto, 1fr), stroke: 0.4pt, inset: 5pt,
  [`src/blocks.py`], [SqueezeExcite, ResidualBlock, MixPool],
  [`src/model.py`], [EncoderBlock, DecoderBlock, FANet; `python -m src.model` prints shapes and the parameter count],
  [`src/memory.py`], [the feedback memory (`MaskMemory`: get / stage / commit) and Otsu from scratch],
  [`src/dataset.py`], [loads images + masks into RAM, resized; returns (image, mask, *index*)],
  [`src/augment.py`], [the official rotate/flip augmentation, plus an "aligned" variant],
  [`src/losses.py`], [0.5 BCE + 0.5 Dice],
  [`src/metrics.py`], [Dice, IoU, precision, recall, F2, ...; boxes from masks],
  [`src/train.py`], [training loop with feedback; writes `best.pt` and `log.csv`],
  [`src/evaluate.py`], [test with iterative refinement; `results.csv`, picture strips, masks],
  [`src/memory_probe.py`], [one pass from different starting masks (Otsu, zeros, ones, own memory, ground truth)],
  [`src/roboflow_to_masks.py`], [converts a Roboflow export into our images/ + masks/ layout (new, 31 Oct)],
  [`src/make_synthetic.py`], [script-generated leaf-spot images (the first own dataset)],
)

*Why does the dataset return the index?* So each image can find its own slot in the memory. The official code had to keep the loader order fixed for that; returning the index lets us shuffle every epoch.

== Deviations from the official code
#table(columns: (1fr, 1fr, 1fr), stroke: 0.4pt, inset: 5pt,
  [*Official*], [*Ours*], [*Why*],
  [Batch 2, 500 epochs], [Batch 8, up to 200, early stop], [fits our time; GPU used better],
  [Memory as run-length strings, fixed loader order], [memory as a tensor indexed by image], [simpler; allows shuffling],
  [sigmoid + BCE], [BCE on logits], [same value, numerically safer],
  [checkpoint chosen on the test images], [same (comparable to the paper)], [we say so honestly: slightly optimistic],
  [CUDA only], [CUDA, Apple MPS or CPU], [testing on any machine],
)

== How to run it
```fish
cd /mnt/Windows_D/College-work/DLproject
source ~/.venvs/dlproject/bin/activate.fish
python -m src.model                                    # shapes + 7,720,266 parameters
python -m src.split --data data/Kvasir-SEG --test 120   # 880 / 120 split
python -m src.train --data data/Kvasir-SEG --out runs/kvasir_official --amp
python -m src.evaluate --ckpt runs/kvasir_official/best.pt --data data/Kvasir-SEG --iters 10
```
One epoch takes about 24 s on the RTX 5050 with mixed precision (`--amp`), 33 s without.

#check(
  [What exactly is "from scratch" in your project, and what is not?],
  [Which file holds MixPool? The memory? The refinement loop?],
  [Name two deviations from the official code and why you made them.],
)

// =====================================================================
= Results: ours against theirs <ch-results>

== The main table
All rows: the same 120 Kvasir-SEG test images, scores averaged per image, after 10 refinement rounds unless stated. Re-checked on 31 Oct (@ch-audit).

#table(columns: (1fr, auto, auto, auto, auto, auto), stroke: 0.4pt, inset: 4pt,
  [*Kvasir-SEG test (120 images)*], [*Dice*], [*mIoU*], [*Recall*], [*Precision*], [*F2*],
  [FANet, paper (512×512)], [0.880], [0.815], [0.906], [0.901], [0.887],
  [Baseline without MixPool, paper], [0.852], [0.773], [0.884], [0.871], [0.861],
  [*FANet, mine, paper's protocol* (Otsu start)], [*0.842*], [*0.779*], [0.934], [0.835], [0.868],
  [FANet, mine, Otsu start, round 1 only], [0.615], [0.512], [0.965], [0.530], [0.729],
  [*FANet, mine, empty start*], [*0.900*], [*0.841*], [0.900], [0.935], [0.898],
  [*No feedback* (memory always zero)], [*0.883*], [0.817], [0.897], [0.915], [0.886],
  [FANet, mine, 512×512], [0.831], [0.758], [0.917], [0.831], [0.860],
  [First attempt, "aligned" memory augmentation], [0.684], [0.589], [0.958], [0.619], [0.775],
)
Speed: about 88 images per second on the RTX 5050 laptop GPU (paper: 68 on a GTX 1050 Ti). 7.72 M parameters, 40.5 GFLOPs per 256×256 image.

#fig("../presentation/figures/refinement_rounds.png", [Test Dice after each refinement round. From Otsu the first round over-segments (0.615) and refinement slowly trims it to 0.842; from an empty mask it starts at 0.829 and reaches 0.900.], w: 75%)

#fig("../presentation/assets/strip_kvasir_official.png", [Refinement on test images: image | truth | Otsu start | round 1 | round 2 | last round.])

#fig("../presentation/figures/learning_curves.png", [Learning curves of the final run: loss and Dice per epoch, training and test.])

== How to read the numbers
1. *Reproduction:* under the paper's own test protocol we get *0.842*, 0.038 below the paper's 0.880. That is close for an independent from-scratch implementation.
2. *Not the resolution:* our 512×512 run scores 0.831, no better. So the paper's larger input is not what we are missing.
3. *Likely causes of the gap:* batch 8 instead of 2; the paper's 120 test images may be different ones (the split is random); one training run per setting (no averaging over seeds).
4. *The starting mask matters a lot:* the same weights give 0.900 when refinement starts from an empty mask instead of Otsu. Otsu marks ~60% of the image, so round 1 over-segments. This changes the test procedure, not the model, so we report it separately; the headline stays 0.842.
5. *The ablation is the most important row:* the same network with the feedback switched off gets *0.883*: better than FANet under the paper's protocol (0.842) and only 0.017 below our best FANet setting (0.900). In our reproduction, *the feedback adds little*. The paper reports a larger gain (0.852 → 0.880).

#say[Under the paper's own protocol I get 0.842 against their 0.880. It is not the resolution: my 512 run is no better. The interesting result is the ablation: without the feedback the same network gets 0.883, so in my reproduction the feedback memory adds much less than the paper claims, and the Otsu starting mask actually hurts. Starting from an empty mask instead gives 0.900.]

== What I found while implementing <sec-findings>
*Finding 1: part of MixPool never learns.* The fmask head's output is thresholded with "> 0.5". A step function has zero gradient, so no gradient reaches the convs inside the fmask heads: 48 weight tensors, *982,088 parameters (about 13% of the model) keep their random initial values*. I verified this by running a backward pass and checking which parameters have no gradient (re-checked on 31 Oct). So the fmask is a fixed random gate; the learned part of the attention is the previous mask. A fix would be a straight-through estimator or soft (sigmoid) gating.

*Finding 2: the "misaligned" memory is doing real work.* The official code rotates and flips the image but not its memory mask, so for about two-thirds of training samples the memory points at the wrong place. My first run "fixed" this by moving the memory too ("aligned"). The result: the model learned to *copy its memory*. Fed different starting masks for one pass:

#table(columns: (auto, auto, auto), stroke: 0.4pt, inset: 5pt,
  [*Starting memory (one pass)*], [*Aligned run*], [*Official run (final)*],
  [Otsu], [0.536], [0.615],
  [all zeros], [0.517], [*0.828*],
  [all ones], [0.383], [0.518],
  [its own training-time memory], [0.848], [0.908],
  [ground truth (oracle)], [0.958], [0.935],
)
Give the aligned model nothing and it finds little; give it everything and it marks everything. The misalignment forces the model to check the memory against the image, so it works as a regulariser. That is why the official behaviour is our default.

*Finding 3: Otsu is a poor start for colonoscopy.* It picks bright regions (glare, lit wall), marking 59.6% of the image against 14.2% polyp.

#check(
  [What is your headline Dice and why is it below the paper? Give two reasons that are ruled out or likely.],
  [Where does 0.900 come from, and why is it not your headline number?],
  [What does the no-feedback ablation tell you?],
  [Why does the fmask head never learn? How many parameters is that?],
  [Explain the "copying" problem of the aligned run with the zeros/ones numbers.],
)

// =====================================================================
= Our own dataset, built in Roboflow <ch-roboflow>

== What the faculty asks
"Use Roboflow to construct your own dataset from scratch; if that is not suitable for your project, take a separate image dataset and do flipping, rotating etc. on it, just to show you have used it." Later: "she wants some manual dataset from Roboflow", and a PPT and a notebook.

Colonoscopy images cannot be collected by a student, so a *from-scratch polyp* dataset is impossible. We keep the *task* (segment irregular blobs on a textured surface) and change the *domain* to *disease spots on leaves*. We do both things the faculty mentions: *manual labelling* in Roboflow (the "from scratch" part) and Roboflow *flips and rotations* (the "show you used it" part).

== Where the leaf images come from
*LDSD, Leaf Disease Segmentation Dataset* (Kaggle, Fakhre Alam, 2021, licence CC0 public domain): 588 real photos of diseased leaves (apple scab, apple rust, bell-pepper leaf spot, corn blight, potato early blight, tomato diseases, ...) taken from *PlantDoc* (Singh et al., CoDS-COMAD 2020), each with a mask of the diseased area. The photos are "in the wild": hands, soil, other leaves, stock-photo watermarks.

How we use it:
- *118 LDSD images (20%) are our leaf test set*, scored against LDSD's own masks. Never used for training.
- *30 other LDSD photos are uploaded to Roboflow without their masks*, and *you label the disease spots by hand*. That is the manual dataset. They were picked by a seeded script from the training pool: larger photos (at least 300 px), disease covering 3–50% of the leaf. The list is in `dataset/custom/roboflow_upload_list.txt`; the files are in `data/roboflow_upload/`.
- Because LDSD has its own masks for those 30 photos, we can *measure how good your hand labels are* (Dice between your mask and theirs): a nice extra slide.

#fig("../presentation/assets/leaf_examples.png", [The earlier, script-generated leaf images (first version of the own dataset, @sec-synthetic). The Roboflow set uses real photos instead.])

== Step by step in Roboflow
#warn[On the free plan, Roboflow projects are *public* (they appear on Roboflow Universe). That is fine here: the LDSD photos are CC0. Do not upload personal photos you do not want public.]

+ *Account:* app.roboflow.com → sign up (Google login works) → create a workspace (any name, e.g. "chaitanya-dl").
+ *New project:* "Create New Project" → project type *Semantic Segmentation* (if not offered, choose *Instance Segmentation*; the converter handles both) → name "leaf-disease-spots" → class (annotation group) "disease".
+ *Upload:* drag the whole folder `data/roboflow_upload/` (30 photos) into the upload page → "Save and Continue".
+ *Annotate yourself:* assign the images to yourself → open each image → choose *Smart Polygon* (AI-assisted, runs SAM in the browser: click on a spot, it proposes an outline, adjust it) or the plain *Polygon* tool (click around the spot) → class "disease" → one polygon per spot or patch. Label every visible diseased area, not the healthy leaf. Note the time you spend (expect 1–2 minutes per photo): it goes on the slide.
+ *Add to dataset:* "Add images to Dataset" → split *train 80% / valid 20% / test 0%* (24 / 6 photos). Our real test set is the 118 LDSD images.
+ *Generate a version:* Versions → "Create New Version".
  - Preprocessing: *Auto-Orient* on; *Resize → Stretch to 256×256* (our training size).
  - Augmentation (applied to the *training* images only): *Flip* (horizontal + vertical), *90° Rotate* (clockwise, counter-clockwise, upside down), *Rotation* ±15°, *Brightness* ±15%.
  - Maximum version size: the largest your plan allows (e.g. *3×*: every training photo plus 2 augmented copies, so about 72 training images).
  - "Create".
+ *Screenshots for the PPT:* the annotation screen with a polygon, the dataset page, the version page listing preprocessing and augmentation, and the Health Check page (class balance, image sizes).
+ *Export:* on the version → "Download Dataset" → format *Semantic Segmentation Masks* (for an Instance Segmentation project: *COCO Segmentation*) → "Download zip to computer". Unzip it.
+ *Convert and train* (in the repo):
```fish
python -m src.roboflow_to_masks --src ~/Downloads/<unzipped folder> \
    --out dataset/custom/roboflow_leaf --compare data/LDSD/data/data
python -m src.train --data dataset/custom/roboflow_leaf --out runs/roboflow_leaf \
    --init runs/kvasir_official/best.pt --epochs 60 --lr 5e-5 --amp
python -m src.evaluate --ckpt runs/roboflow_leaf/best.pt --data data/LDSD/data/data --split test \
    --iters 10 --out runs/roboflow_leaf_ldsd/eval_test
```

*What the converter does.* Roboflow's semantic export stores, per split folder, `NAME.jpg` and `NAME_mask.png`, where each mask pixel is a *class number* (0 = background, 1 = disease), not 0/255. The converter turns every non-zero class into foreground, writes our `images/` + `masks/` layout, and turns Roboflow's train/valid folders into `train.txt` / `val.txt`. With a valid split, `train.py` picks its checkpoint on Roboflow's valid images, *never on the test images*: cleaner than the paper's protocol.

#say[I built my own dataset in Roboflow: I uploaded 30 real photos of diseased leaves, outlined the disease spots by hand with Roboflow's polygon tools, split them 80/20, and generated a version with flips, 90° rotations, small rotations and brightness changes, which tripled the training images. I exported it as segmentation masks and fine-tuned my polyp model on it.]

== Leaf results <sec-leaf-results>
All on the 118 LDSD test photos, scored against LDSD's masks, 256×256.

#table(columns: (1fr, auto, auto), stroke: 0.4pt, inset: 5pt,
  [*Model*], [*Dice (Otsu start)*], [*Dice (empty start)*],
  [Polyp model, no fine-tuning], [0.010 (round 1: 0.129)], [0.004],
  [Fine-tuned from the polyp weights on 470 LDSD photos (their masks)], [*0.670*], [*0.681*],
  [Trained from random weights on the same 470 photos], [LDSD_SC_OTSU], [LDSD_SC_ZERO],
  [*Fine-tuned on my 30 Roboflow-labelled photos*], [pending], [pending],
)
Scores after 10 refinement rounds. *Reading.* Without fine-tuning the polyp model is useless on leaves (Dice 0.13 after one round), and refinement makes it worse: its masks shrink to almost nothing (0.010 after 10 rounds). That is a *domain gap*: it learned what a polyp looks like, not what a disease spot looks like. Fine-tuning on leaf photos lifts it to *0.67–0.68*. Leaves are harder than polyps: many small scattered spots instead of one blob, cluttered real-world backgrounds, and coarse reference masks. LDSD_SC_NOTE

== The first own dataset: synthetic leaves <sec-synthetic>
Before Roboflow, we generated 60 leaf images by script (`src/make_synthetic.py`): a green ellipse leaf with veins, 1–4 irregular brown spots with a yellow halo, blur, lighting gradient and noise. The masks are exact because we drew the spots. The polyp model scored Dice 0.474 on them before fine-tuning and 0.984 after. Too easy (clean shapes, plain backgrounds), which is why the real photos matter.

#check(
  [Why can't you build a polyp dataset yourself, and what did you do instead?],
  [Where do the leaf photos come from, and what licence do they have?],
  [List the Roboflow steps from upload to export.],
  [Which images does Roboflow augment, and why not the others?],
  [Why does the converter treat mask value 1 as foreground, not 255?],
)

// =====================================================================
= Audit, 31 October 2026 <ch-audit>

Everything below was re-run on the laptop (RTX 5050) on 31 Oct.

#table(columns: (1fr, auto), stroke: 0.4pt, inset: 5pt,
  [*Check*], [*Result*],
  [`python -m src.model`: output shape and parameter count], [1×256×256, 7,720,266 ✓],
  [Re-evaluate the final checkpoint, paper's protocol (10 rounds)], [Dice 0.8422 ✓ (same as README)],
  [Re-evaluate, empty start], [Dice 0.8999 ✓],
  [All result CSVs in `runs/` against the README table], [all match ✓],
  [fmask heads get no gradient], [48 tensors, 982,088 parameters ✓],
  [Flip/rotate augmentation is exactly invertible], [✓],
  [Deck rebuilds from the CSVs (`node presentation/build_deck.js`)], [✓],
  [Study guide compiles], [✓],
  [Ablation and first run stop at the same epoch (116, best 76): a mix-up?], [no: different weights and numbers, a coincidence ✓],
  [*Mask loading for other datasets*], [*bug found and fixed* (below)],
)

*The bug.* `load_mask` kept pixels brighter than 127, which is right for Kvasir (0/255 JPEG masks) but makes masks with *class numbers* (0/1) completely empty. Roboflow's semantic export and LDSD both use class numbers; half of LDSD even uses palette PNGs and the other half red RGB masks. Training on them would have silently learnt "everything is background". Now: the brightest channel is used; masks whose maximum is at most 10 are read as class numbers (non-zero = foreground); others are thresholded at half their maximum. Kvasir masks load exactly as before (mean polyp fraction 0.1423 before and after), so no earlier result changes.

*New since the audit:* `src/roboflow_to_masks.py` (tested on simulated Roboflow exports in both formats), the LDSD download and split (470 / 118), the 30-photo upload set, and the leaf experiments in @sec-leaf-results.

// =====================================================================
= Presenting on Tuesday <ch-tuesday>

== The talk, in 5 minutes
Follow the deck (`presentation/FANet_ChaitanyaShinde_231070066.pptx`). One or two sentences per slide:

+ *Title.* "Polyp segmentation with FANet, an IEEE TNNLS 2023 paper, implemented from scratch, with transfer to plant disease."
+ *Problem.* "Colorectal cancer starts from polyps; doctors miss about one in four adenomas; every 1% more detection lowers cancer risk by about 3%. A model that outlines polyps can help."
+ *Task.* "This is segmentation: a label for every pixel. From the mask I also get boxes, so it covers detection too."
+ *Paper.* "FANet's observation: a network sees each image many times in training but forgets its previous predictions. FANet keeps them and feeds them back."
+ *Architecture.* "A U-shaped encoder–decoder with residual blocks. The previous mask goes into a MixPool block at every stage."
+ *MixPool.* "It combines a mask guessed from the current features with the previous mask, uses it as hard attention on one half of the channels, and keeps the other half unmasked, so a wrong mask cannot destroy the prediction."
+ *Training and refinement.* "The memory starts from Otsu thresholding and is replaced by the model's own predictions whenever validation improves. At test time the prediction is fed back for 10 rounds."
+ *Implementation.* "Everything is written from PyTorch primitives: no pretrained weights, no model libraries. 7.7 million parameters."
+ *Setup.* "Kvasir-SEG, 1000 images, 880/120 split as in the paper; BCE + Dice loss; Adam."
+ *Results.* "0.842 Dice with the paper's protocol against their 0.880; 0.900 from an empty start."
+ *Refinement chart.* "From Otsu the first round over-segments, refinement trims it."
+ *Finding.* "The ablation without feedback gets 0.883, so the feedback adds less than claimed; and 13% of the attention head never trains because of a hard threshold."
+ *Own dataset.* "30 real leaf photos labelled by hand in Roboflow, augmented with flips and rotations, used to fine-tune the polyp model."
+ *Conclusion.* "Faithful reproduction within 0.04 Dice, a critical look at what the feedback really adds, and a working transfer to a new domain."

== If Tuesday is only "explain the topic basics"
Then the first seven slides are the talk. Have this ready in 60 seconds: the problem (polyps, missed in colonoscopy), the task (pixel mask), the paper (name, journal, year), the idea (feedback memory + MixPool + refinement), the dataset (Kvasir-SEG, 1000 images), and the plan for the own dataset (Roboflow leaf spots).

== Questions you will probably get
#let qa(q, a) = block(breakable: false, below: 8pt)[*Q: #q* \ #a]

#qa[Why segmentation and not classification?][The output is a label for every pixel: a 256×256 mask, not one label per image.]
#qa[Where is the CNN?][The whole network is convolutional: 3×3 convs in residual blocks, 1×1 convs, transposed convs for upsampling. The only fully connected layers are the tiny SE ones.]
#qa[What is new compared with U-Net?][(1) A memory of the previous prediction per image, fed back as input. (2) MixPool blocks that use it as hard attention at every scale. (3) Iterative refinement at test time.]
#qa[Where does the first mask come from?][Otsu thresholding of the blurred grey image: a classical method, no learning.]
#qa[Isn't feeding your own prediction back cheating?][No. Ground truth is never an input. The memory holds only Otsu or the model's own earlier predictions, and the same happens at test time.]
#qa[What if the previous mask is wrong?][MixPool's plain half sees the unmasked features, so nothing is lost; the network learns how much to trust the masked half.]
#qa[Why update the memory only when validation improves?][So it always comes from the best model so far; a bad epoch cannot poison the next input.]
#qa[Why BCE + Dice?][BCE gives smooth per-pixel gradients but is dominated by background; Dice measures region overlap and handles the imbalance.]
#qa[Why Dice and not accuracy?][Polyps cover ~14% of the image, so predicting nothing already gives ~86% accuracy but Dice 0.]
#qa[Dice vs IoU?][Both measure overlap; IoU = TP/(TP+FP+FN) is stricter. For one image IoU = Dice/(2 − Dice).]
#qa[What does SE do?][Learns a weight per channel from globally averaged features and rescales the channels: channel attention.]
#qa[Why skip connections?][Pooling loses detail; skips bring high-resolution encoder features to the decoder for sharp edges.]
#qa[Why is your Dice lower than the paper's?][0.842 vs 0.880 under the same protocol. Not resolution (512 run: 0.831). Likely batch size 8 vs 2, a different random test split, single runs.]
#qa[What does the feedback actually add?][In my reproduction little: without feedback 0.883, FANet 0.842 (Otsu start) or 0.900 (empty start). The paper reports +0.03.]
#qa[Did you find anything wrong in the paper's design?][The fmask head is thresholded with "> 0.5", which has no gradient, so ~13% of the parameters never train.]
#qa[How do you get detection from segmentation?][Connected blobs of the mask → one box per blob → match to true boxes at IoU ≥ 0.5 → box precision and recall.]
#qa[What did you write yourself?][All of `src/`: model, memory, data, augmentation, loss, metrics, training, evaluation, Otsu, connected components. Only PyTorch primitives; no pretrained weights.]
#qa[How did you make your own dataset?][30 real diseased-leaf photos (from the CC0 LDSD/PlantDoc set) uploaded to Roboflow, disease spots outlined by hand with polygon/Smart Polygon, split 80/20, augmented in Roboflow with flips, 90° rotations, ±15° rotations and brightness, exported as segmentation masks.]
#qa[Why leaves?][Polyp data cannot be collected by a student. Leaf spots are the same kind of task: irregular blobs on a textured surface. It also shows transfer learning.]
#qa[Which images does Roboflow augment?][Only the training split, so validation and test measure performance on real, unaltered images.]
#qa[Limitations?][One medical dataset; possibly a different test split from the paper; still images, not video; checkpoint chosen on the test images as in the official code (slightly optimistic); a proof of concept, not a medical device.]

== If you get stuck
Go back to the one idea: _"The network remembers its previous mask for each image and uses it as attention; at test time it refines its own mask."_ Everything else hangs off that sentence.

// =====================================================================
= Glossary <ch-glossary>
#table(columns: (auto, 1fr), stroke: 0.4pt, inset: 4pt,
  [Adam], [gradient descent with momentum and per-weight step sizes],
  [Ablation], [an experiment that removes one part to measure what it contributes],
  [Augmentation], [random changes (flip, rotate, brightness) that make new training images],
  [Batch normalisation], [normalise each channel over the batch, then learned scale and shift],
  [Dice], [overlap score $2"TP"/(2"TP"+"FP"+"FN")$, 1 = perfect],
  [Epoch], [one pass over all training images],
  [Feedback / memory], [the previous mask stored for each image and fed back as input],
  [Fine-tuning], [continuing training from weights learnt on another dataset],
  [Hard attention], [multiplying features by a 0/1 mask],
  [IoU], [intersection over union, $"TP"/("TP"+"FP"+"FN")$],
  [Iterative refinement], [predict, feed the prediction back, predict again],
  [Logit], [the raw output before the sigmoid],
  [MixPool], [FANet's block: masked half + plain half, mask = fmask OR previous mask],
  [Otsu], [classical threshold that best separates dark and bright pixels],
  [Polyp / adenoma], [growth in the colon / the kind that can become cancer],
  [Residual block], [output = input-path + learned correction],
  [Roboflow], [web tool to upload, label, split, augment and export image datasets],
  [SE], [squeeze-and-excitation: channel attention],
  [Segmentation], [a label for every pixel],
  [Skip connection], [encoder features copied to the decoder at the same scale],
  [Transfer learning], [reusing a model trained on one task for another],
  [Transposed convolution], [learned upsampling],
)

= References
+ N. K. Tomar et al., "FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation," _IEEE Trans. Neural Netw. Learn. Syst._, vol. 34, no. 11, 2023. DOI 10.1109/TNNLS.2022.3159394. arXiv 2103.17235. Code: github.com/nikhilroxtomar/FANet.
+ D. Jha et al., "Kvasir-SEG: A Segmented Polyp Dataset," MMM 2020. arXiv 1911.07069. datasets.simula.no/kvasir-seg.
+ O. Ronneberger, P. Fischer, T. Brox, "U-Net: Convolutional Networks for Biomedical Image Segmentation," MICCAI 2015.
+ K. He et al., "Deep Residual Learning for Image Recognition," CVPR 2016.
+ J. Hu, L. Shen, G. Sun, "Squeeze-and-Excitation Networks," CVPR 2018.
+ N. Otsu, "A Threshold Selection Method from Gray-Level Histograms," _IEEE Trans. SMC_, 1979.
+ D. P. Kingma, J. Ba, "Adam: A Method for Stochastic Optimization," ICLR 2015.
+ S. Ioffe, C. Szegedy, "Batch Normalization," ICML 2015.
+ D. A. Corley et al., "Adenoma Detection Rate and Risk of Colorectal Cancer and Death," _NEJM_, 2014.
+ S. Zhao et al., "Magnitude, Risk Factors, and Factors Associated With Adenoma Miss Rate of Tandem Colonoscopy," _Gastroenterology_, 2019.
+ D. Singh et al., "PlantDoc: A Dataset for Visual Plant Disease Detection," CoDS-COMAD 2020. arXiv 1911.10317.
+ F. Alam, "Leaf disease segmentation dataset" (LDSD), Kaggle, 2021, CC0. kaggle.com/datasets/fakhrealam9537/leaf-disease-segmentation-dataset.
+ Roboflow documentation: dataset versions, image augmentation, exporting data. docs.roboflow.com.
