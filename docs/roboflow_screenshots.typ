// Roboflow dataset screenshots for the Classroom submission.
// Build (from the repo root): typst compile --root . docs/roboflow_screenshots.typ out.pdf
#set document(title: "Roboflow Dataset Screenshots", author: "Chaitanya Shinde")
#set page(paper: "a4", margin: (x: 1.6cm, y: 1.5cm),
  footer: context [#set text(8pt, fill: luma(110)); 231070066 · Chaitanya Shinde · Roboflow dataset screenshots #h(1fr) #counter(page).display("1 / 1", both: true)])
#set text(font: "Libertinus Serif", size: 10.5pt)
#set par(justify: true)
#show heading.where(level: 1): set text(15pt)
#show figure.caption: set text(9pt)
#set figure(numbering: none)
#show link: set text(fill: rgb("#1f4fb4"))

#let A = "../presentation/assets/"
#let shot(path, cap, h: auto, w: auto) = figure(
  box(stroke: 0.5pt + luma(170), image(A + path, height: h, width: w)),
  caption: cap, gap: 6pt)

#align(center)[
  #text(18pt, weight: "bold")[Roboflow Dataset Screenshots] \
  #v(2pt)
  #text(11pt)[Deep Learning Mini-Project · FANet (IEEE TNNLS 2023) from scratch] \
  #text(10.5pt)[Chaitanya Shinde · Reg. No. 231070066 · B.Tech Computer Engineering, Sem VII (2026–27)]
]
#v(6pt)

Two datasets were built by hand on Roboflow (workspace `chaitanyadl`, account ck Orion2); both are public on Roboflow Universe.

#table(columns: (auto, 1fr, 1fr), inset: 5pt, stroke: 0.5pt + luma(170),
  table.header([], [*A. Tomato leaf disease (detection)*], [*B. Leaf disease spots (segmentation)*]),
  [Purpose], [Lab rule: ≥ 200 annotated images, ≥ 4 classes], [Own small dataset for FANet (fine-tuning and transfer)],
  [Photos], [220 tomato-leaf photos (PlantVillage), 55 per class], [30 real leaf photos (LDSD, CC0)],
  [Classes], [`bacterial_spot`, `early_blight`, `healthy`, `late_blight`], [disease spot vs background],
  [Labels], [233 bounding boxes, drawn by hand (0 images unlabelled)], [277 polygons, drawn by hand (0 images unlabelled)],
  [Version v1], [split 176 / 22 / 22; resize 640×640; flips, ±15° rotation, ±15% brightness; 3× → *572 images*], [split 24 / 6; resize 256×256; flips, 90° rotations, ±15° rotation, ±15% brightness; 5× → *126 images*],
  [Export], [YOLOv8], [Semantic Segmentation Masks],
  [Created], [18 Nov 2026], [7 Nov 2026],
  [Link], [#link("https://universe.roboflow.com/chaitanyadl/tomato-leaf-disease-det/dataset/1")[universe.roboflow.com/chaitanyadl/tomato-leaf-disease-det]], [#link("https://universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne")[universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne]],
)

#v(4pt)
#grid(columns: (1.55fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_extra/00_workspace_projects.png", [W1. Workspace `chaitanyadl`: the two projects (Object Detection, 220 images; Semantic Segmentation, 30 images), both public.]),
  shot("roboflow_extra/workspace_activity.png", [W2. Workspace activity: version v1 exported as YOLOv8 (572 images) and dataset analytics generated.]),
)

#pagebreak()
= A. Tomato leaf disease: Object Detection dataset (4 classes, 220 images)

#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_extra/det_01_analytics.png", [A1. Dataset analytics: 220 images, 233 annotations, 0 missing annotations; boxes per class: late_blight 67, bacterial_spot 56, healthy 55, early_blight 55.], h: 11.5cm),
  shot("roboflow_extra/det_02_annotate_board.png", [A2. Annotate board: all 220 annotation jobs done and added to the dataset (none unassigned or in progress).], h: 11.5cm),
)
#v(4pt)
#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_det/dataset_220.png", [A3. Dataset view with annotations shown.], h: 9cm),
  shot("roboflow_det/editor_bacterial_spot.png", [A4. Annotation editor: a box drawn by hand, class `bacterial_spot`.], h: 9cm),
)

#pagebreak()
#shot("roboflow_det/dataset_bacterial_spot.png", [A5. Class `bacterial_spot` (filtered): 55 labelled images.], w: 100%)
#v(4pt)
#grid(columns: (1fr, 1fr), gutter: 10pt,
  shot("roboflow_det/dataset_early_blight.png", [A6. Class `early_blight`: 55 images.]),
  shot("roboflow_det/dataset_healthy.png", [A7. Class `healthy`: 55 images.]),
)
#v(4pt)
#grid(columns: (1fr, 1fr), gutter: 10pt,
  shot("roboflow_det/dataset_late_blight.png", [A8. Class `late_blight`: 55 images.]),
  shot("roboflow_det/export_yolov8.png", [A9. Export of version v1 in YOLOv8 format.]),
)

#pagebreak()
#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_det/version_split.png", [A10. Generating v1: train / valid / test split 176 / 22 / 22.], h: 10.5cm),
  shot("roboflow_det/version_preprocessing.png", [A11. Preprocessing: Auto-Orient, resize to 640×640.], h: 10.5cm),
)
#v(6pt)
#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_det/version_augmentation.png", [A12. Augmentation: flips, ±15° rotation, ±15% brightness (3× on train).], h: 10.5cm),
  shot("roboflow_det/version_v1_572.png", [A13. Generated version v1: 572 images.], h: 10.5cm),
)

#pagebreak()
#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_extra/det_03_version_v1_by_author.png", [A14. Version `tomato-leaf-v1`, created by ck Orion2 on 18 Nov 2026: 572 images, train 528 / valid 22 / test 22.], h: 12cm),
  shot("roboflow_extra/det_04_universe_public.png", [A15. Public page on Roboflow Universe (CC BY 4.0). The fifth "class" listed is Roboflow's project-name placeholder and holds no boxes (A1 shows 4 classes).], h: 12cm),
)

#pagebreak()
= B. Leaf disease spots: Semantic Segmentation dataset (FANet's own dataset)

#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_extra/seg_01_analytics.png", [B1. Dataset analytics: 30 images, 277 polygons drawn by hand (9.2 per image), 0 missing annotations.], h: 9.5cm),
  shot("roboflow_extra/seg_02_universe_public.png", [B2. Public page on Roboflow Universe (CC BY 4.0), with the hand-drawn polygons visible.], h: 9.5cm),
)
#v(4pt)
#shot("roboflow/01_dataset_grid_30_labelled.png", [B3. Dataset view: all 30 photos labelled by hand.], w: 88%)

#pagebreak()
#shot("roboflow/02_annotate_board_30_jobs.png", [B4. Annotate board: 30 annotation jobs, all done.], w: 100%)
#v(4pt)
#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow/03_annotation_editor.png", [B5. Annotation editor: disease spots outlined with Polygon / Smart Polygon.], h: 9.5cm),
  shot("roboflow/04_labelled_example_00097.png", [B6. A finished label (photo leaf_00097).], h: 9.5cm),
)

#pagebreak()
#shot("roboflow/05_resize_256_stretch.png", [B7. Preprocessing: resize (stretch) to 256×256.], w: 100%)
#v(4pt)
#shot("roboflow/06_version_split_preprocessing.png", [B8. Version v1: split 24 / 6 and preprocessing.], w: 100%)

#pagebreak()
#shot("roboflow/07_aug_flip.png", [B9. Augmentation: horizontal and vertical flips.], w: 100%)
#v(4pt)
#shot("roboflow/08_aug_rotate90.png", [B10. Augmentation: 90° rotations (clockwise, counter-clockwise, upside down).], w: 100%)

#pagebreak()
#shot("roboflow/09_aug_brightness.png", [B11. Augmentation: brightness ±15%.], w: 100%)
#v(4pt)
#shot("roboflow/10_aug_summary.png", [B12. Augmentation summary: 5× outputs per training image.], w: 100%)

#pagebreak()
#shot("roboflow/11_version_v1_126_images.png", [B13. Generated version v1: 126 images (120 train + 6 valid).], w: 100%)
