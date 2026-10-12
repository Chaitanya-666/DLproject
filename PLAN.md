# DL Mini-Project Plan (v2, 2026-10-12)

Replaces the CondInst plan in [`docs/v1-condinst-plan.md`](docs/v1-condinst-plan.md), which is not feasible (see "Why not CondInst" below).

## The brief (from [`brief/finalProjectDeepLearning.jpeg`](brief/finalProjectDeepLearning.jpeg))

- Individual project. Topic: object segmentation and detection, **not classification**, must use a **CNN**.
- Implement an **IEEE paper** found on Google, **from scratch**.
- Paper should be fairly advanced and from the **last 5 years**.
- Use the **paper's own dataset**.
- For the PPT, make a **small dataset of your own** and explain **how you generated it**.
- Prepare a **PPT**.
- Update (2026-10-12): allowed domains are detection, segmentation, LSTM.

## Recommended paper (detection + segmentation)

**Jha et al., "Real-Time Polyp Detection, Localization and Segmentation in Colonoscopy Using Deep Learning"**,
IEEE Access, vol. 9, pp. 40496–40510, 2021. DOI 10.1109/ACCESS.2021.3063716. arXiv 2011.07631.

- Proposes **ColonSegNet**, a small CNN encoder–decoder (a few million parameters). Writing it from scratch in PyTorch is about 150–250 lines.
- Dataset: **Kvasir-SEG**, 1000 colonoscopy images with pixel masks *and* bounding boxes (the paper's own dataset). About 50 MB, so it fits easily on Kaggle or Colab.
- Covers both tasks: segmentation (mask) and detection/localization (box). Reported: Dice 0.8206 for segmentation; AP 0.80 / mIoU 0.81 for detection and localization; about 180 FPS.
- Risk: published 2021, which is right at the edge of "last 5 years". **Ask ma'am before registering.**

## Fallback if ma'am says 2021 is too old (segmentation)

**Tomar, Jha et al., "FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation"**,
IEEE Transactions on Neural Networks and Learning Systems, vol. 34, no. 11, 2023 (online 2022). arXiv 2103.17235.

- CNN encoder–decoder that feeds the previous epoch's predicted mask back in as attention.
- Uses small public biomedical datasets, including colon polyps. Check in the paper which polyp set it uses (likely Kvasir-SEG, so the same data pipeline would work).
- Segmentation only. Bounding boxes can be derived from the masks if detection is also required.
- Switching between the two papers is cheap, because the dataset, loader, metrics and PPT structure stay the same.

## What "from scratch" means here

Write the model, dataset loader, loss functions, training loop and metrics yourself in PyTorch (`nn.Conv2d`, `nn.BatchNorm2d` and similar building blocks). No `segmentation_models_pytorch`, no `torchvision.models.detection`, no copying the authors' repository. Read their code only to check details.

## Compute: Kaggle (free T4, about 30 GPU-hours a week)

- 1000 images at 256×256 (or 512×512), about 880/120 train/test split as in the paper.
- Expected time: under 1 minute per epoch on a T4; 100–200 epochs, so 1–3 hours in total. Fits in one Kaggle session.

## Your own small dataset (for the PPT)

Medical images can't be collected at home, so use the same *task* on a different subject:
1. Take 40–60 phone photos of **leaves with spots or diseased patches** (or weeds in soil, which links to the AgriAgent domain).
2. Annotate them in **Labelme** or **CVAT** with polygon masks, then export binary masks plus bounding boxes in Kvasir-SEG's format.
3. Resize to 256×256; augment (flips, rotation, colour jitter). Split 80/20 with no overlap between train and test.
4. Fine-tune the Kvasir-trained model on it and show before/after predictions.
5. In the PPT, show how many images you took, the annotation tool, the time it took, the class/size statistics, and the augmentation steps.

## Deliverables

- `src/`: `model.py` (ColonSegNet), `dataset.py`, `losses.py` (BCE + Dice), `train.py`, `metrics.py` (Dice, mIoU, precision, recall, box IoU / AP from masks).
- A Kaggle notebook that trains and evaluates, plus a table comparing your numbers with the paper's.
- `dataset/custom/`: images, masks and a generation write-up.
- `presentation/`: PPT of about 10–12 slides.

## Timeline

| When | What | Hours |
|---|---|---|
| Tue 13 Oct | Ask ma'am: 2021 paper OK? Detection + segmentation both needed, or one? Register the topic. | — |
| Wed 14 – Fri 16 Oct | Read the paper (method + experiments). Add Kvasir-SEG to a Kaggle notebook. | 2 |
| Sat 17 – Sun 18 Oct | Write dataset loader, model, losses and training loop; first training run. **Target: baseline Dice by Sunday.** | 6–8 |
| Mon 19 – Sun 25 Oct (DL viva week) | Metrics plus boxes from masks; compare with the paper. Take and annotate the custom photos (about 3 h). Fine-tune. | 6 |
| Mon 26 – Sat 31 Oct | PPT, result figures, rehearse explaining the code. **Project complete by Sat 31 Oct.** | 5 |
| 1 – 7 Nov | Buffer before Diwali. | — |

Realistic answer to "by when?": a **trained baseline by Sun 18 Oct**, the **full project (results + custom dataset + PPT) by the last week of October**. The whole project in this week alone is not realistic alongside the CPAD quiz, the DL Lab 1–2 evaluation and DL viva prep.

## Why not CondInst (the v1 plan)

- Its benchmark is COCO (118k images). The authors trained on 8 GPUs with an ImageNet-pretrained ResNet-50. A Kaggle T4 can't reproduce it in weeks, so there would be no meaningful results.
- The Lab07 ResNet-50 was trained on CIFAR-10 only, so it's not usable as a detection backbone.
- The PDF in `papers/` is the ECCV 2020 arXiv version. The TPAMI 2023 details in the v1 plan could not be verified online.
- FCOS heads, target assignment, dynamic mask heads and their losses are far too much for an individual project with this timeline.

## LSTM option (only if ma'am allows a non-CNN topic)

The newly listed LSTM domain would let you build on Lab05b. But the original brief says a CNN is required and asks for detection/segmentation, so treat this as a last resort and confirm first.
