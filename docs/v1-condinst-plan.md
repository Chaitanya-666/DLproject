# Deep Learning Individual Project: Advanced Object Segmentation & Detection

> **Superseded 2026-10-12:** the CondInst plan below is not feasible. Current plan: see [PLAN.md](../PLAN.md).

**Course:** Deep Learning (Semester VII) — Final Year B.Tech Computer Engineering  
**Student:** Chaitanya Shinde (Reg No: 231070066)  
**Academic Year:** 2026–2027  

---

## 1. Project Requirements & Faculty Brief Breakdown

Based on the classroom instructions (transcribed from lab requirements):

```text
INDIVIDUAL PROJECT
TOPIC: OBJECT SEGMENTATION AND DETECTION (NOT CLASSIFICATION, CNN KA USE CHHAIYE AESA TOPIC)
GOOGLE SE IEEE KA PAPER IMPLEMENT KARNA HAI FROM SCRATCH
PPT BHI PREPARE KARNI HAI
TOPIC THODA ADVANCED, LAST 5 YEAR KA PAPER LO (2020–2025/2026)
DATASET KE LIYE USE RESEARCH PAPER KA DATASET USE KARO
PPT KE WAQT KE LIYE SMALL DATASET BANANA HAI (ALSO BATANA HAI KE KAISE GENERATE KIYA DATASET)
```

### Core Constraints Matrix:
| Parameter | Institutional Requirement | Architectural Strategy |
| :--- | :--- | :--- |
| **Project Type** | Individual Project | Dedicated implementation by Chaitanya Shinde (231070066) |
| **Domain Scope** | Object Detection & Segmentation | Strictly prohibited from simple classification; must perform simultaneous localization, bounding box regression, and pixel-level mask segmentation. |
| **Architecture Engine** | Convolutional Neural Network (CNN) | Must use CNN backbone (e.g. ResNet/ResNeXt with Feature Pyramid Networks) and convolutional mask/detection heads. |
| **Literature Standard** | IEEE Research Paper (Last 5 Years: 2020–2025) | High-impact IEEE TPAMI, IEEE TCYB, or IEEE CVPR/ICCV paper implementing modern instance/semantic segmentation. |
| **Implementation Standard** | From Scratch (`from scratch`) | Explicit modular implementation of backbone, neck (FPN), detection head, and mask branch in PyTorch without high-level one-line abstractions. |
| **Primary Dataset** | Research Paper Benchmark Dataset | Standard benchmark used in the published paper (e.g. MS COCO subsplit, Pascal VOC, or KVASIR-SEG / Cityscapes). |
| **Demo / Defense Dataset** | Custom Small Synthesized/Annotated Dataset | Generate a small domain-specific dataset (50–200 samples) with full annotation methodology and data augmentation pipeline for live viva demonstration. |
| **Deliverables** | Implementation + PPT Presentation | Modular codebase, Jupyter benchmark notebook, trained checkpoints, quantitative evaluation suite, and slide deck. |

---

## 2. Recommended IEEE Research Papers (2020–2025)

## 2. Selected IEEE TPAMI Papers (2021–2023) & Trade-off Analysis

### Option 1 (Top Recommendation): CondInst — Dynamic Conditional Convolutions for Detection & Instance Segmentation
* **Official IEEE Title:** *Instance and Panoptic Segmentation Using Conditional Convolutions*
* **Publication:** **IEEE Transactions on Pattern Analysis and Machine Intelligence (TPAMI)**, Vol. 45, No. 1, pp. 669–680, January 2023.
* **DOI:** `10.1109/TPAMI.2022.3145407`
* **Authors:** Zhi Tian, Bowen Zhang, Hao Chen, Chunhua Shen
* **Core Architecture:**
  - **Backbone:** ResNet-50 (Pure CNN, directly ported from our Lab 07 from-scratch implementation).
  - **Neck:** Feature Pyramid Network (FPN with levels $P_3, P_4, P_5$).
  - **Head:** Fully Convolutional One-Stage (FCOS) anchor-free detector predicting bounding box offsets, classification logits, and dynamic mask kernel parameters ($\theta$).
  - **Mask Branch:** Dynamic 3-layer convolutional mask network taking relative coordinates and dynamic weights.
* **Why it fits all 7 constraints:**
  - **Zero Anchor Headaches:** Completely eliminates anchor clustering, matching, and IoU heuristics.
  - **Zero RoIAlign Complexity:** Replaces RoIPool/RoIAlign with dynamic filter generation, preserving full spatial resolution.
  - **True Multi-Task:** Simultaneously outputs Class, Bounding Box, and Instance Mask.
  - **Published in 2023:** High-impact IEEE TPAMI publication well within the 5-year window.

### Option 2: YOLACT++ — Real-Time Detection & Instance Segmentation
* **Official IEEE Title:** *YOLACT++: Better Real-Time Instance Segmentation*
* **Publication:** **IEEE Transactions on Pattern Analysis and Machine Intelligence (TPAMI)**, Vol. 44, No. 2, pp. 1108–1121, February 2022.
* **DOI:** `10.1109/TPAMI.2020.3014297`
* **Authors:** Daniel Bolya, Chong Zhou, Fanyi Xiao, Yong Jae Lee
* **Core Architecture:**
  - ResNet-50 Backbone + FPN Neck.
  - **Protonet Branch:** Deep convolutional branch producing $k=32$ prototype masks for the entire image.
  - **Prediction Head:** Standard anchor-based conv head predicting bounding box coordinates, class confidence, and $k$ linear mask coefficients.
  - Assembly via matrix multiplication: $\text{Mask} = \sigma(\text{Prototypes} \times \text{Coefficients}^T)$.
* **Trade-off:** Highly visual and intuitive, but anchor generation and anchor-to-ground-truth matching require extra boilerplate code from scratch.

### Option 3: SOLO — Segmenting Objects by Locations
* **Official IEEE Title:** *SOLO: A Simple Framework for Instance Segmentation*
* **Publication:** **IEEE Transactions on Pattern Analysis and Machine Intelligence (TPAMI)**, Vol. 44, No. 11, pp. 8587–8601, November 2022.
* **DOI:** `10.1109/TPAMI.2021.3111116`
* **Authors:** Xinlong Wang, Tao Kong, Chunhua Shen, Yuning Jiang, Lei Li
* **Trade-off:** Divides input into an $S \times S$ grid; each grid cell predicts mask and category. Super clean, but bounding boxes are derived from mask bounding envelopes rather than an explicit box regression head.

---

## 3. Directory Layout & Architecture Plan

```text
project/
├── README.md                      # Project specification, selected paper, & execution plan
├── docs/                          # Architectural derivations, math, loss functions
│   └── architecture_notes.md
├── papers/                        # Downloaded IEEE paper PDF & conference references
├── dataset/                       # Benchmark data loader & custom small dataset generator
│   ├── download_benchmark.py
│   ├── generate_demo_dataset.py   # Synthetic / curated dataset creation script
│   └── annotations/               # JSON/COCO format bounding boxes and polygon masks
├── src/                           # From-scratch PyTorch implementation
│   ├── backbone.py                # ResNet / ConvNet feature extractor
│   ├── fpn.py                     # Feature Pyramid Network (top-down + lateral connections)
│   ├── heads.py                   # Bounding box regression, class scoring, mask prediction
│   ├── loss.py                    # Multi-task loss (CIoU / GIoU + BCE Mask + Focal Loss)
│   ├── train.py                   # Training pipeline with mixed precision & learning rate warmup
│   └── evaluate.py                # mAP@0.5, mAP@0.5:0.95, Mask IoU / Dice evaluator
└── presentation/                  # Slide deck (PPTX) & demonstration figures
    ├── slides.pptx
    └── figures/
```

---

## 4. Custom Demo Dataset Generation Methodology (For PPT Defense)

To satisfy the requirement: *"PPT ke waqt ke liye small dataset banana hai (also batana hai ke kaise generate kiya dataset)"*:

1. **Collection / Capture:**
   - Curate 100–150 focused high-resolution images (e.g. handheld electronic components, lab equipment, or specific tabletop objects) captured under controlled lighting and varied viewpoints.
2. **Annotation Protocol:**
   - Tool: CVAT (Computer Vision Annotation Tool) or Labelme.
   - Format: Standard COCO polygon instances (`[x1, y1, x2, y2, ...]` polygons + bounding box `[x, y, w, h]`).
3. **Synthetic Data Augmentation & Edge Cases:**
   - Scripted geometric transforms (affine scaling, perspective warp, rotation $\pm 25^\circ$).
   - Photometric distortions (Gaussian blur, color jitter, specular glare synthesis).
   - CutMix / Mosaic augmentation to simulate heavy background occlusion and multi-instance clutter.
4. **Defense Talking Points:**
   - Document dataset statistics: distribution of object scales (small, medium, large), class balance, and pixel mask density.
   - Explain train/val split (80/20) and how zero leakage was preserved.

---

## 5. Presentation (PPT) Structure Blueprint

1. **Slide 1: Title & Institutional Metadata** (Student: Chaitanya Shinde 231070066, Topic, Faculty guide).
2. **Slide 2: Motivation & Problem Statement** (Why object segmentation + detection over classification).
3. **Slide 3: IEEE Paper Selection & Key Innovations** (Citation, DOI, architecture diagram from paper).
4. **Slide 4: Overall System Architecture from Scratch** (Backbone, FPN, detection head, mask branch).
5. **Slide 5: Mathematical Formulation & Loss Function** (Multi-task loss: classification, regression, mask).
6. **Slide 6: Benchmark Dataset & Quantitative Performance** (Metrics: mAP, Mask IoU, FPS).
7. **Slide 7: Custom Small Dataset Engineering** (Collection, annotation, polygon extraction, augmentation).
8. **Slide 8: Qualitative Results & Visual Comparisons** (Ground truth vs. predicted masks & bounding boxes).
9. **Slide 9: Ablation Study & Failure Mode Analysis** (Edge cases, occlusions, scale variations).
10. **Slide 10: Conclusion & Future Scope**.
