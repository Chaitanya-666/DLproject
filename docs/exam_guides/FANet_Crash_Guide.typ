// FANet crash guide: condensed from FANet_OneShot_Guide.typ (same sources, repo state ce2194e).
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#set document(title: "FANet crash guide", author: "Chaitanya Shinde")
#set page(paper: "a4", margin: (x: 2cm, y: 1.9cm), numbering: "1",
  header: context { if counter(page).get().first() > 1 [
    #set text(8pt, fill: luma(120)); FANet crash guide #h(1fr) Chaitanya Shinde, 231070066 ] })
#set text(font: ("Libertinus Serif", "New Computer Modern"), size: 11pt, lang: "en")
#set par(justify: false, leading: 0.55em)
#set heading(numbering: "1.")
#show heading: set text(font: "Inter", weight: "bold")
#show heading.where(level: 1): set text(13pt, fill: rgb("#0e3b43"))
#show heading.where(level: 1): it => { if counter(heading).get().first() > 1 { pagebreak(weak: true) }; it; v(0.2em) }
#show heading.where(level: 2): set text(10.5pt, fill: rgb("#14545e"))
#show raw.where(block: true): it => block(fill: luma(243), inset: 6pt, radius: 3pt, width: 100%, text(8pt, it))
#show raw.where(block: false): it => text(font: "DejaVu Sans Mono", size: 8.3pt, fill: rgb("#14545e"), it.text)
#set table(stroke: 0.4pt + luma(165), inset: 4pt)
#show table.cell.where(y: 0): set text(weight: "bold")

#let callout(title, bg, accent, body) = block(width: 100%, fill: bg, stroke: (left: 3pt + accent),
  inset: (x: 9pt, y: 6pt), radius: 2pt, above: 0.6em, below: 0.6em)[
  #text(font: "Inter", size: 8pt, weight: "bold", fill: accent)[#upper(title)] \ #body]
#let say(body) = callout("Say this to ma'am", rgb("#fff6e2"), rgb("#b9790a"), body)
#let trap(body) = callout("Careful", rgb("#fdeceb"), rgb("#c0392b"), body)
#let qn = counter("qn")
#let qa(q, a) = { qn.step(); block(breakable: false, above: 0.42em, below: 0.42em)[*Q#context qn.display(). #q* #a] }

// =====================================================================
#align(center)[
  #text(8.5pt, font: "Inter", fill: luma(90))[DEEP LEARNING LAB ESE · THU 19 NOV 2026 · LAB 1B]\
  #text(19pt, font: "Inter", weight: "bold", fill: rgb("#0e3b43"))[FANet: the crash guide] \
  #text(10.5pt)[Chaitanya Shinde · Roll no. 231070066 · B.Tech Computer Engineering, Sem VII, 2026-27] \
  #text(8.5pt, fill: luma(100))[Condensed from the 46-page one-shot guide. Every number comes from the repo's `runs/` CSVs, the report and the deck.]
]

= Page 1: pitch, brief, key numbers
#say[My project is polyp segmentation for colorectal cancer screening. I implemented the IEEE TNNLS 2023 paper *FANet, a Feedback Attention Network*, from scratch in PyTorch, with no pretrained weights and no model libraries. FANet is a U-Net-style CNN that remembers the mask it predicted for each image and feeds it back as hard attention inside every block; at test time it refines its own mask over ten rounds. On the paper's dataset, Kvasir-SEG, I get Dice *0.842* with the paper's protocol, against *0.880* in the paper, and *0.900* when refinement starts from an empty mask. Without feedback the same network gets *0.883*, so in my reproduction the feedback adds little. For my own dataset I labelled 30 real leaf photos by hand in Roboflow and fine-tuned the polyp model: *0.517* Dice on 118 unseen leaf photos, against *0.467* from random weights.]

#table(columns: (auto, 1fr),
  [Brief asks], [How you meet it],
  [Segmentation / detection, CNN, not classification], [A 0/1 mask for every pixel; boxes around predicted blobs give a detection view. Fully convolutional.],
  [IEEE paper, last 5 years, fairly advanced], [IEEE TNNLS vol. 34, no. 11, 2023 (online 2022). Memory + MixPool + test-time refinement, more than a plain U-Net.],
  [From scratch], [Every layer, loss, metric, Otsu, connected components, training and evaluation written with plain PyTorch / NumPy.],
  [Paper's dataset], [Kvasir-SEG, the paper's 880/120 ratio.],
  [Own small dataset (in Roboflow), explained], [30 public leaf photos, labelled by you in Roboflow, split 24/6, augmented 5× = 126 images. Plus the lab's detection set: 220 tomato-leaf photos, 4 classes, your boxes, 3× → 572 images.],
  [PPT], [20 slides, plus a 11-page report and an executed notebook.],
)

#grid(columns: (1fr, 1fr), gutter: 10pt,
[
  *Key numbers*
  - Parameters: *7,720,266*; fmask heads *982,088* (12.7%) never train.
  - Kvasir-SEG: 1000 images, *880 train / 120 test*, seed 42, 256×256.
  - *Ours 0.842* (mIoU 0.779) vs *paper 0.880* (mIoU 0.815). Gap 0.038.
  - Empty start: *0.900*. Round 1 from Otsu: 0.615.
  - No-feedback ablation: *0.883*.
  - 512×512 run (paper's size, 100 epochs): *0.831*.
  - Paper's own B1 (no MixPool): 0.852.
],
[
  *Leaves (118 LDSD test photos, Otsu / empty start)*
  - Roboflow 24 photos, from polyp weights: *0.517 / 0.520*.
  - Same, from random weights: *0.467 / 0.461*.
  - LDSD 470 photos: 0.670 / 0.681 (fine-tuned), 0.678 / 0.667 (scratch).
  - Polyp model, no fine-tuning: 0.010 / 0.004.
  - Label agreement with LDSD masks: *0.730*.
  - LDSD 588 → 470 / 118. Roboflow 30 → 24 / 6 → 126.

  *Kaggle (free T4 GPUs):* no-feedback ablation, aligned 512 run, official 512 run. Everything else on the RTX 5050 laptop (8 GB).
])

// =====================================================================
= FANet in one page
#table(columns: (auto, 1fr, 1fr),
  [Piece], [What it is], [Why (one line)],
  [Memory], [For every image, the 0/1 mask the network predicted for it earlier.], [A network sees each image 100+ times but normally forgets its earlier answers.],
  [Otsu start], [Before epoch 1 (and at test time) the memory is an Otsu threshold of the blurred grey image.], [Something must exist before any prediction; Otsu needs no learning. (But it marks 59.6% of an image vs 14.2% polyp, a poor start.)],
  [Feedback attention], [The memory goes into a MixPool block in every encoder and decoder stage, and is concatenated before the output conv.], ["Look here" hints at every scale.],
  [MixPool], [fmask head guesses a mask (> 0.5); memory max-pooled to feature size; attention = fmask OR memory; masked features → conv; unmasked features → conv; concat.], [Hard attention, but the unmasked half means a wrong mask cannot erase the polyp. Max-pool keeps small polyps.],
  [Update rule], [Predictions go to a staging copy; the memory is replaced only when the validation loss improves.], [The memory always comes from the best model so far.],
  [Iterative rounds], [Test time: start from Otsu, predict, feed the prediction back, 10 rounds.], [Each round can trim or fix the last mask.],
  [Loss], [0.5·BCE + 0.5·Dice loss.], [BCE: smooth per-pixel gradients. Dice: handles the imbalance (polyp 14%).],
  [Metrics], [Per-image Dice = 2TP/(2TP+FP+FN), IoU = TP/(TP+FP+FN), precision, recall, F2; averaged over images.], [Accuracy is useless here: an empty mask gets about 86%.],
)

#figure(
  diagram(spacing: (4.6mm, 6mm), node-stroke: 0.6pt, node-corner-radius: 2pt,
    node((0,0), [image \ 3×256²], stroke: none),
    node((1,0), [E1], fill: rgb("#dcecef")), node((2,0), [E2], fill: rgb("#dcecef")),
    node((3,0), [E3], fill: rgb("#dcecef")), node((4,0), [E4], fill: rgb("#dcecef")),
    node((5,0), [D1], fill: rgb("#e8f3dc")), node((6,0), [D2], fill: rgb("#e8f3dc")),
    node((7,0), [D3], fill: rgb("#e8f3dc")), node((8,0), [D4], fill: rgb("#e8f3dc")),
    node((9,0), [concat \ + 1×1 conv]), node((10,0), [logits \ 1×256²], stroke: none),
    edge((0,0), (1,0), "-|>"), edge((1,0), (2,0), "-|>"), edge((2,0), (3,0), "-|>"), edge((3,0), (4,0), "-|>"),
    edge((4,0), (5,0), "-|>"), edge((5,0), (6,0), "-|>"), edge((6,0), (7,0), "-|>"), edge((7,0), (8,0), "-|>"),
    edge((8,0), (9,0), "-|>"), edge((9,0), (10,0), "-|>"),
    edge((4,0), (4,-0.8), (5,-0.8), (5,0), "--|>"), edge((3,0), (3,-1.1), (6,-1.1), (6,0), "--|>"),
    edge((2,0), (2,-1.4), (7,-1.4), (7,0), "--|>"), edge((1,0), (1,-1.7), (8,-1.7), (8,0), "--|>", [skips], label-pos: 0.5),
    node((0,1.2), [previous mask], stroke: none, fill: rgb("#fde8e4")),
    edge((0,1.2), (9,1.2), (9,0), "-|>", stroke: rgb("#c0392b")),
    edge((1,1.2), (1,0), "-|>", stroke: rgb("#c0392b")), edge((2,1.2), (2,0), "-|>", stroke: rgb("#c0392b")),
    edge((3,1.2), (3,0), "-|>", stroke: rgb("#c0392b")), edge((4,1.2), (4,0), "-|>", stroke: rgb("#c0392b")),
    edge((5,1.2), (5,0), "-|>", stroke: rgb("#c0392b")), edge((6,1.2), (6,0), "-|>", stroke: rgb("#c0392b")),
    edge((7,1.2), (7,0), "-|>", stroke: rgb("#c0392b")), edge((8,1.2), (8,0), "-|>", stroke: rgb("#c0392b")),
  ),
  caption: [Encoder E = Residual ×2 → MixPool → MaxPool (channels 32, 64, 128, 256; size halves). Decoder D = TransposedConv ×2 up → concat skip → Residual ×2 → MixPool (back to 16 ch at 256²). Residual block = two 3×3 conv + BN, shortcut 1×1 conv + BN + squeeze-and-excitation.],
)

// =====================================================================
= Code map (15 rows, commit ce2194e)
#table(columns: (auto, auto, 1fr),
  [Piece], [File : lines], [What it does],
  [Residual block + SE], [`src/blocks.py:12-64`], [SE (one-unit bottleneck, `:58`), conv-BN-ReLU-conv-BN + shortcut],
  [MixPool forward], [`src/blocks.py:109-116`], [`:110` fmask > 0.5, `:112` max-pool memory, `:113` OR, `:114` masked, `:115` plain, `:116` concat],
  [Encoder, decoder, FANet], [`src/model.py:27-88`], [skip taken before MixPool (`:36`); ConvTranspose2d k4 s2 p1 (`:45`); memory concatenated before the 1×1 head (`:88`)],
  [Otsu], [`src/memory.py:17-36`], [between-class variance from scratch; grey → blur → threshold],
  [Memory], [`src/memory.py:39-83`], [Otsu or zeros init; `get` `:57`, `stage` `:60`, `commit` `:66`, `write` `:70`],
  [Loss], [`src/losses.py:14-29`], [Dice loss (smooth 1) + BCE with logits, 0.5 / 0.5],
  [Dataset + mask rule], [`src/dataset.py:64-113`], [`load_mask` threshold rule; returns (image, mask, index)],
  [Augmentation], [`src/augment.py:78-99`], [official: rotate ±35°, h/v flip, p 0.3 each; memory not moved],
  [Training step], [`src/train.py:54-111`], [memory get `:70`, aug `:72-82`, AMP `:84-88`, Adam `:89-97`, stage `:105`],
  [Val falls back to test], [`src/train.py:147`], [no `val.txt` → the test split selects the checkpoint],
  [Commit + save], [`src/train.py:187-203`], [if val loss improved: commit memories, save `best.pt`],
  [Refinement], [`src/evaluate.py:81-120`], [Otsu or `--start zeros` (`:82-84`); loop `:95-120`; write back `:108`],
  [Metrics + boxes], [`src/metrics.py:27-149`], [per-image Dice/IoU/P/R/F2; BFS blobs, boxes, IoU ≥ 0.5 matching],
  [Memory probe], [`src/memory_probe.py:31-77`], [one pass from five starting masks],
  [Roboflow converter], [`src/roboflow_to_masks.py:48-153`], [export → images/masks, keeps the split, `agreement.csv`],
)

// =====================================================================
= Experiments
#{
set text(9.2pt)
table(columns: (auto, 1.25fr, 1.3fr, 0.95fr, 1.4fr),
  [\#], [Run (`runs/`)], [Settings], [Result (Dice)], [Meaning],
  [1], [`kvasir` (aligned memory)], [memory moved with flips/90° turns; 256, batch 8, laptop; best 76/116], [0.684 (train-time 0.844)], [Model copied its memory; led to official mode.],
  [2], [`kvasir_official` (main)], [authors' aug, memory not moved; 256, batch 8, laptop fp32; best 107/147], [*0.842*, round 1 0.615], [Headline reproduction, 0.038 below paper.],
  [3], [same, `eval_test_zeros`], [empty start instead of Otsu], [*0.900*], [Otsu start hurts; test variant only.],
  [4], [memory probe (runs 1, 2)], [one pass from Otsu / zeros / ones / own / truth], [zeros: 0.517 vs 0.828], [Misaligned memory acts as a regulariser.],
  [5], [`kvasir_nofb`], [memory always zeros; Kaggle T4; aligned-style aug; one pass], [*0.883*], [Feedback adds little.],
  [6], [`kvasir512`], [aligned, 512, batch 4, 100 ep, Kaggle T4], [0.504 (train-time 0.827)], [Copying again at 512.],
  [7], [`kvasir512-official`], [official, 512, batch 4, 100 ep, AMP, Kaggle T4; best.pt epoch 80], [*0.831*], [Resolution is not the gap.],
  [8], [`leaf_before`, `leaf`], [60 synthetic leaves 48/12; fine-tune 60 ep lr 5e-5], [0.474 → 0.984], [Too easy; real photos needed.],
  [9], [`ldsd_zeroshot`], [polyp model on 118 LDSD photos], [0.010 / 0.004], [Domain gap.],
  [10], [`ldsd_finetune`], [470 LDSD photos, polyp weights, 60 ep, lr 5e-5], [0.670 / 0.681], [Reference with 20× more labels.],
  [11], [`ldsd_scratch`], [same, random weights, lr 1e-4], [0.678 / 0.667], [With 470 photos transfer makes no difference.],
  [12], [`roboflow_leaf`], [24 photos (×5), polyp weights, plateau lr; best epoch 7, stopped 47], [0.472 / 0.465], [LR cut too early on 6 noisy val photos.],
  [13], [`roboflow_leaf_scratch`], [same, random weights, 60 ep (lr never cut)], [0.434 / 0.419], [Reference for 12.],
  [14], [`roboflow_leaf_constlr`], [constant lr 5e-5, 100 ep; best 89], [*0.517 / 0.520*], [Main leaf result.],
  [15], [`roboflow_leaf_scratch_constlr`], [constant lr 1e-4, 100 ep; best 99], [*0.467 / 0.461*], [Transfer helps with little data (+0.05).],
  [16], [label agreement], [your masks vs LDSD's, same 30 photos], [mean 0.730, median 0.781], [Definition differences, not sloppiness.],
)
}
Leaf rows show Otsu start / empty start on the 118 LDSD test photos.

*Why your results differ from the paper (honest reading).*
+ Under the paper's protocol you are 0.038 below (0.842 vs 0.880). Resolution is ruled out: the 512 run gets 0.831.
+ Remaining candidates: batch 8 instead of 2, a random seed-42 test split that may differ from theirs, and single runs (0.01 to 0.02 is noise).
+ Otsu marks about 60% of the image, so round 1 over-segments; from an empty start the same weights reach 0.900.
+ Without feedback you get 0.883, so feedback is worth at most +0.017; the paper claims +0.03. Your ablation keeps MixPool with zero memory (the paper's B1 removes MixPool), used older augmentation, and 13% of MixPool never trains.
+ Kvasir checkpoints were chosen on the test images, as in the authors' code: comparable, but slightly optimistic.

// =====================================================================
= The custom dataset in half a page
- *Why leaves:* colonoscopy images cannot be collected by a student. Same task (irregular spots on a textured surface), new domain; it also tests transfer learning.
- *Photos are public, not yours:* LDSD (Kaggle, CC0), 588 real photos from PlantDoc, split 470 / 118. The 118 are the leaf test set. 30 photos were picked from the 470 training pool (seeded: at least 300 px, 3 to 50% disease) and uploaded to Roboflow *without* masks. Ma'am's 30 Oct instruction allowed taking a separate image set.
- *Labels are yours:* Roboflow Semantic Segmentation project (a detection project stores only boxes), every spot outlined with Smart Polygon and Polygon, about 2 hours. Rule: brown or dead tissue and standalone yellow blotches; thin yellow rims excluded.
- *Version v1:* split 24 / 6 / 0; Auto-Orient; stretch to 256×256; flips, 90° turns, ±15° rotation, ±15% brightness, 5 copies per training photo → 120 + 6 = *126 images*. Exported as Semantic Segmentation Masks (class numbers 0/1), converted by `src/roboflow_to_masks.py`. Public: `universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne`.
- *Label agreement:* your masks vs LDSD's on the same 30 photos: mean Dice 0.730, median 0.781 (0.96 best, 0.09 worst, where LDSD marked a whole yellow leaf).
- *Results:* 0.517 fine-tuned vs 0.467 from scratch. Transfer helps with 24 photos, not with 470. 20× less data costs about 0.16 Dice.
- *Constant-LR re-run:* with 6 validation photos the plateau schedule cut the rate at epochs 13, 19, 25 (best epoch 7). Both runs were redone with a constant rate for 100 epochs; the rule was fixed before seeing test scores. (The first scratch run never had a cut; its gain came from 100 vs 60 epochs.)

// =====================================================================
= Deck talk track (one line per slide, 20 slides)
#{
set text(10pt)
table(columns: (auto, auto, 1fr),
  [\#], [Slide], [Say],
  [1], [Title], [Polyp segmentation with FANet (IEEE TNNLS 2023), from scratch on Kvasir-SEG, transferred to leaf spots via my Roboflow dataset.],
  table.cell(colspan: 3, fill: luma(232))[*Problem Statement*],
  [2], [Outline], [Five parts in the order of the brief: Problem Statement, Proposed System, Dataset Used, Result Analysis, Future Scope.],
  [3], [Motivation], [About 26% of adenomas are missed; +1% detection lowers cancer risk about 3%; a mask is a second pair of eyes, decision support only.],
  [4], [Task], [Segmentation: a 0/1 label per pixel; boxes come from the mask's blobs; polyps are only 14% of the image.],
  table.cell(colspan: 3, fill: luma(232))[*Proposed System*],
  [5], [Paper], [Three ideas: memory of the last mask, hard attention in every block, refinement at test time; ground truth is never an input.],
  [6], [Architecture], [U-Net with residual blocks; memory into every MixPool and before the 1×1 head; 7,720,266 parameters.],
  [7], [MixPool], [fmask OR memory gates one half, the other half sees everything; the > 0.5 step means 982,088 parameters never train.],
  [8], [Training loop], [Otsu start; predict, stage, commit only if the loss improves; 10 refinement rounds at test; Otsu marks 60%.],
  [9], [From scratch], [Only PyTorch primitives; no pretrained weights or model libraries; also wrote the Roboflow converter, Kaggle offload, deck generator.],
  table.cell(colspan: 3, fill: luma(232))[*Dataset Used*],
  [10], [Setup], [Kvasir 880/120 seed 42; 256 with batch 8 on the laptop, 512 on Kaggle; checkpoint chosen on test images, as in the authors' code.],
  [11], [Own dataset], [Same task, new domain; 30 public CC0 photos, labels drawn by me; Semantic Segmentation project for pixel masks.],
  [12], [Roboflow steps], [My screenshots: hand labelling, 30 jobs, resize 256, augmentations; split 24/6, v1 with 126 images, export, convert.],
  [13], [Version v1], [No Roboflow test split (LDSD's 118 are the test); flips and turns since a leaf has no up; 5× on train only; offline vs online augmentation.],
  [14], [Roboflow detection set], [Lab rule ≥ 200 images, ≥ 4 classes: 220 PlantVillage tomato photos, 55 per class (bacterial spot, early blight, late blight, healthy); my 233 boxes; 176/22/22; 3× → 572; YOLOv8 export.],
  table.cell(colspan: 3, fill: luma(232))[*Result Analysis*],
  [15], [Results], [0.842 vs 0.880; empty start 0.900; 512 gives 0.831; no feedback 0.883, so the memory adds little; boxes find 80% of polyps.],
  [16], [Refinement], [From Otsu 0.615 → 0.842 as rounds trim the oversized mask; from empty 0.829 → 0.900.],
  [17], [Finding], [Aligning the memory made the model copy it (recall 0.41 from nothing); the authors' misalignment is a regulariser (0.83 vs 0.52).],
  [18], [Real leaves], [Labels agree at 0.73; zero-shot finds nothing; 0.517 vs 0.467 with 24 photos; constant LR because 6 val photos made the schedule cut early.],
  table.cell(colspan: 3, fill: luma(232))[*Future Scope*],
  [19], [Future scope], [Each step answers a limit: more Roboflow photos and classes; paper protocol with seeds (0.038 gap), other datasets, clean validation; video frames as memory, soft fmask, faster inference.],
  table.cell(colspan: 3, fill: luma(232))[*Conclusion*],
  [20], [Conclusion], [Reproduced 0.842 / 0.900; limits: feedback adds little, 512 no better, one dataset, test-set selection; next: more labels, soft fmask, video.],
)
}

// =====================================================================
= The 10 inconsistencies (and what to say)
#{
set text(10pt)
table(columns: (auto, 1fr, 1fr),
  [\#], [What differs], [Correct value / what to say],
  [1], [Paper precision: slide 15 shows 0.900, report 0.901.], [Paper value is 0.9005; "just rounding".],
  [2], [LDSD 470 from scratch: README 0.679, report and deck 0.678.], [CSV 0.67846, so 0.678 is right.],
  [3], [README: aligned 512 run on a P100; report "Kaggle T4/P100".], [Kaggle log shows Tesla T4. All Kaggle runs used T4s.],
  [4], [README: official 512 "best epoch 77".], [`best.pt` is epoch 80 (lowest loss); 77 had the highest test Dice. 0.831 is from epoch 80.],
  [5], [Report §7.4 / slide 18: default schedule cut the LR and "both models" scored about 0.04 lower.], [Only the fine-tuned run was cut (13, 19, 25, 31; best 7). The scratch run's gain came from 100 vs 60 epochs.],
  [6], [Slide 8: cut-out on "image and ground truth".], [Rotation and flips move both; cut-out is on the image only (`train.py:82`).],
  [7], [Notebook / project book: main run used `--amp`.], [Stored arguments show no AMP (flag added later). AMP was used for the 512-official, LDSD and Roboflow runs.],
  [8], [Report says test-as-validation for Kvasir only.], [The LDSD-470 and synthetic runs also selected on their test sets. Only the Roboflow runs are clean.],
  [9], [Report's no-feedback row looks like a plain ablation.], [It was trained with the older aligned-style augmentation (flips, 90° turns, brightness), not ±35°.],
  [10], [Small rounding: empty start round 1 is 0.829 (slide 16) vs 0.828 / 0.83 (probe); deck line counts are one more than `wc -l`; FPS 87 vs 88.], [Two scripts and two counting methods; no real discrepancy.],
)
}

// =====================================================================
= Top 50 viva questions
#{
set text(10.2pt)
qa[Paper and venue?][FANet, Tomar et al., IEEE TNNLS vol. 34 no. 11, 2023 (online 2022).]
qa[Main idea?][Remember the last mask per image, feed it back as hard attention in every block, refine at test time.]
qa[First mask?][Otsu threshold of the blurred grey image; no learning.]
qa[When is the memory updated?][Only when the validation loss improves.]
qa[What is iterative refinement?][Predict, feed the mask back, predict again; 10 rounds from Otsu.]
qa[Paper's Kvasir result?][Dice 0.8803, mIoU 0.8153 at 512×512; B1 without MixPool 0.8516.]
qa[Datasets in the paper?][Seven; you reproduced Kvasir-SEG only.]
qa[Encoder block?][Residual ×2, MixPool, max-pool 2×2; skip taken before MixPool.]
qa[Decoder block?][Transposed conv ×2 up, concat skip, Residual ×2, MixPool.]
qa[MixPool steps?][fmask > 0.5; max-pool memory; OR; masked half conv; plain half conv; concat.]
qa[Why max-pool the memory?][A cell stays 1 if any pixel was 1, so small polyps survive.]
qa[Why a plain half?][A wrong mask cannot erase information.]
qa[What is SE?][Channel attention: per-channel weights from averaged features. Here a one-unit bottleneck, copied from the authors.]
qa[Parameters?][7,720,266; most in E4 and D1.]
qa[Odd finding in MixPool?][The > 0.5 step has no gradient: 982,088 parameters (12.7%) never train. Fix: soft gate or straight-through estimator.]
qa[Loss and why?][0.5·BCE + 0.5·Dice: stable gradients plus imbalance handling.]
qa[Why BCE with logits?][Same value, numerically safer.]
qa[Optimiser and schedule?][Adam 1e-4; ReduceLROnPlateau ×0.1, patience 5; early stop 40.]
qa[Batch, epochs?][Batch 8; ran 147 epochs, best 107.]
qa[Augmentation?][Rotate ±35°, h/v flips (p 0.3 each), cut-out on the image; memory not moved.]
qa[Why not move the memory?][Moving it made the model copy its memory (0.684). Misalignment for about 2/3 of samples forces it to check.]
qa[What is AMP?][fp16 forward with a GradScaler, loss in fp32; about 1.8× faster per batch.]
qa[Why return an index from the dataset?][To find each image's memory slot while shuffling.]
qa[Dice formula?][2TP / (2TP + FP + FN); equals F1.]
qa[IoU vs Dice?][IoU = TP / (TP + FP + FN), stricter; per image IoU = Dice / (2 − Dice).]
qa[Why not accuracy?][Polyps are 14% of pixels; an empty mask scores about 86% accuracy, Dice 0.]
qa[Precision vs recall?][Precision: how much of what you marked is polyp. Recall: how much polyp you found; clinically most important.]
qa[Main result?][0.842 Dice, mIoU 0.779, paper's protocol, 120 test images.]
qa[What is 0.900?][Same weights, empty start; a test-procedure variant, so not the headline.]
qa[How much does refinement help?][From Otsu 0.615 → 0.842 (+0.23).]
qa[Why is round 1 low?][Otsu marks 60% of the image, so the first mask is too big (recall 0.965, precision 0.530).]
qa[Most interesting finding?][The authors' misaligned memory acts as a regulariser.]
qa[Speed?][About 87 images/s on the RTX 5050 at 256.]
qa[Own dataset?][30 public leaf photos, labelled by you in Roboflow, 24/6, 5× → 126 images.]
qa[Why a Semantic Segmentation project?][Detection projects store only boxes; FANet needs pixel masks.]
qa[Are your labels good?][Mean Dice 0.730 vs LDSD's masks; big misses are definition differences.]
qa[Leaf result?][0.517 fine-tuned vs 0.467 from scratch on 118 LDSD photos.]
qa[Why constant LR?][6 noisy val photos made the plateau rule cut too early; rule fixed before testing.]
qa[Why Kaggle?][Free 16 GB T4s, two sessions at once; 512 needs more memory than the 8 GB laptop.]
qa[Where is MixPool in code?][`src/blocks.py:109-116`.]
qa[What bug did you fix?][`load_mask` read class-index masks (0/1) as empty; fixed 31 Oct; Kvasir unchanged.]
qa[Overfitting, and how you fought it?][Augmentation, BatchNorm, early stopping, misaligned memory; no dropout layers.]
qa[Transfer learning?][Start from weights trained on another task; fine-tune with a smaller LR (5e-5).]
text(weight: "bold", fill: rgb("#c0392b"))[Traps]
qa[Why lower than the paper?][Not resolution (512 gives 0.831). Batch 8 vs 2, a different random test split, single runs; the Otsu start also costs points.]
qa[Why is the 512 run not better?][Batch 4, AMP, one run; with its own memory it hit 0.879 but 0.831 from Otsu. Its empty-start test was not done.]
qa[Remove the feedback?][0.883: above 0.842 and only 0.017 below 0.900. You could not reproduce a clear gain; your ablation differs from B1 and is a single run.]
qa[Is this really detection?][It is segmentation with a detection view: boxes around blobs at IoU ≥ 0.5 (box P 0.685, R 0.800). No detector head, no mAP.]
qa[Is it from scratch?][Yes: plain PyTorch layers, your own loader, aug, loss, metrics, Otsu, BFS, training, evaluation; no pretrained weights or model libraries. Architecture is the paper's; the authors' code was read to check details.]
qa[Test set used as validation?][For Kvasir yes, exactly as the authors' code: comparable but slightly optimistic, and stated in the report. Roboflow runs are clean (6 val photos, 118 unseen test photos).]
qa[Did you use AI tools?][Answer truthfully, for example: "I used AI assistance for parts of the code and documentation; I checked every part, ran every experiment, and can explain and change any line." Never claim what you did not do.]
}

// =====================================================================
#pagebreak()
= Cheat sheet
#{
set text(8.8pt)
set par(leading: 0.5em)
grid(columns: (1fr, 1fr), gutter: 10pt,
[
  *Kvasir-SEG, 120 test images (Dice / mIoU)*
  #table(columns: (1fr, auto), inset: 3pt,
    [Paper 512], [0.880 / 0.815],
    [Paper B1, no MixPool], [0.852 / 0.773],
    [*Ours, paper protocol*], [*0.842 / 0.779*],
    [Ours, round 1 (Otsu)], [0.615 / 0.512],
    [Ours, empty start], [0.900 / 0.841],
    [No feedback], [0.883 / 0.817],
    [Ours 512 official], [0.831 / 0.758],
    [Aligned 256 / 512], [0.684 / 0.504],
  )
  Recall 0.934, precision 0.835, F2 0.868. Boxes P 0.685, R 0.800. About 87 img/s.

  *Memory probe, one pass (aligned / official)*
  #table(columns: (1fr, auto), inset: 3pt,
    [Otsu], [0.536 / 0.615], [zeros], [0.517 / 0.828], [ones], [0.383 / 0.518],
    [own memory], [0.848 / 0.908], [ground truth], [0.958 / 0.935],
  )
  *Leaves, 118 LDSD photos (Otsu / empty)*
  #table(columns: (1fr, auto), inset: 3pt,
    [No fine-tuning], [0.010 / 0.004],
    [*Roboflow, polyp weights*], [*0.517 / 0.520*],
    [Roboflow, random weights], [0.467 / 0.461],
    [First runs (ft / scratch)], [0.472 / 0.434],
    [LDSD 470, polyp / random], [0.670 / 0.678],
    [Synthetic before → after], [0.474 → 0.984],
  )
],
[
  *Model and training*
  - 7,720,266 params; 982,088 (12.7%) never train.
  - Widths 32-64-128-256; head 17 → 1; 40.5 GFLOPs at 256².
  - 0.5·BCE + 0.5·Dice; Adam 1e-4; plateau ×0.1 p5; batch 8; early stop 40.
  - Main run: 147 epochs, best 107, laptop fp32, about 1.7 h.
  - Aug: ±35°, h/v flips p 0.3, cut-out on image; memory not moved.
  - Otsu marks 59.6%, polyps 14.2%.

  *Data*
  - Kvasir 1000 → 880 / 120 (seed 42), 256².
  - LDSD 588 → 470 / 118 (CC0).
  - Roboflow 30 → 24 / 6 / 0 → 126; agreement 0.730.

  *Hardware*
  - RTX 5050 laptop 8 GB: main 256 runs, leaf runs.
  - Kaggle T4: no-feedback, both 512 runs (`kaggle/offload.sh`).

  *Files:* `blocks.py` MixPool 109-116 · `model.py` 56-88 · `memory.py` Otsu 17-36, memory 39-83 · `losses.py` · `augment.py` 78-99 · `train.py` step 54-111, commit 187-190 · `evaluate.py` 95-120 · `metrics.py` · `memory_probe.py` · `roboflow_to_masks.py`
])
v(4pt)
[*Commands (repo root)*]
```bash
python -m src.model                                       # 7,720,266
python -m src.split --data data/Kvasir-SEG                # 880 / 120
python -m src.train --data data/Kvasir-SEG --out runs/kvasir_official [--amp]
python -m src.train --data data/Kvasir-SEG --out runs/kvasir_nofb --no-feedback
python -m src.evaluate --ckpt runs/kvasir_official/best.pt \
    --data data/Kvasir-SEG --split test --iters 10 [--start zeros]
python -m src.memory_probe --ckpt runs/kvasir_official/best.pt \
    --data data/Kvasir-SEG
python -m src.roboflow_to_masks --src <export> \
    --out dataset/custom/roboflow_leaf --compare data/LDSD/data/data
python -m src.train --data dataset/custom/roboflow_leaf \
    --out runs/roboflow_leaf_constlr --init runs/kvasir_official/best.pt \
    --epochs 100 --early-stop 0 --lr-patience 0 --lr 5e-5 --amp
```
}
