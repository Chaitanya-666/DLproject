// Roboflow dataset screenshots for the Classroom submission.
// Build: typst compile --root .. docs/roboflow_screenshots.typ   (from the repo root: --root .)
#set document(title: "Roboflow Dataset Screenshots", author: "Chaitanya Shinde")
#set page(paper: "a4", margin: (x: 1.6cm, y: 1.5cm),
  footer: context [#set text(8pt, fill: luma(110)); 231070066 · Chaitanya Shinde · Roboflow dataset screenshots #h(1fr) #counter(page).display("1 / 1", both: true)])
#set text(font: "Libertinus Serif", size: 10.5pt)
#set par(justify: true)
#show heading.where(level: 1): set text(15pt)
#show heading.where(level: 2): set text(12pt)
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

Two datasets were built by hand on Roboflow (workspace `chaitanyadl`, both public on Roboflow Universe):

#table(columns: (auto, 1fr, 1fr), inset: 5pt, stroke: 0.5pt + luma(170),
  table.header([], [*A. Tomato leaf disease (detection)*], [*B. Leaf disease spots (segmentation)*]),
  [Purpose], [Lab rule: ≥ 200 annotated images, ≥ 4 classes], [Own small dataset for FANet (fine-tuning and transfer)],
  [Photos], [220 tomato-leaf photos (PlantVillage), 55 per class], [30 real leaf photos (LDSD, CC0)],
  [Classes], [`bacterial_spot`, `early_blight`, `healthy`, `late_blight`], [disease spot vs background],
  [Labels], [233 bounding boxes, drawn by hand], [polygons (Polygon / Smart Polygon), drawn by hand],
  [Version v1], [split 176 / 22 / 22; resize 640×640; flips, ±15° rotation, ±15% brightness; 3× → *572 images*], [split 24 / 6; resize 256×256; flips, 90° rotations, ±15° rotation, ±15% brightness; 5× → *126 images*],
  [Export], [YOLOv8], [Semantic Segmentation Masks],
  [Link], [#link("https://universe.roboflow.com/chaitanyadl/tomato-leaf-disease-det/dataset/1")[universe.roboflow.com/chaitanyadl/tomato-leaf-disease-det]], [#link("https://universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne")[universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne]],
)

= A. Tomato leaf disease: Object Detection dataset (4 classes, 220 images)

#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_det/dataset_220.png", [A1. Dataset view: 220 images, annotations shown.], h: 9.2cm),
  shot("roboflow_det/editor_bacterial_spot.png", [A2. Annotation editor: a bounding box drawn by hand, class `bacterial_spot`.], h: 9.2cm),
)
#v(4pt)
#shot("roboflow_det/dataset_bacterial_spot.png", [A3. Class `bacterial_spot` (filtered): 55 labelled images.], w: 100%)

#pagebreak()
#grid(columns: (1fr, 1fr), gutter: 10pt,
  shot("roboflow_det/dataset_early_blight.png", [A4. Class `early_blight`: 55 images.]),
  shot("roboflow_det/dataset_healthy.png", [A5. Class `healthy`: 55 images.]),
)
#v(6pt)
#grid(columns: (1fr, 1fr), gutter: 10pt,
  shot("roboflow_det/dataset_late_blight.png", [A6. Class `late_blight`: 55 images.]),
  shot("roboflow_det/export_yolov8.png", [A7. Export of version v1 in YOLOv8 format.]),
)

#pagebreak()
#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_det/version_split.png", [A8. Version v1, train / valid / test split: 176 / 22 / 22.], h: 10.5cm),
  shot("roboflow_det/version_preprocessing.png", [A9. Preprocessing: Auto-Orient, resize to 640×640.], h: 10.5cm),
)
#v(6pt)
#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow_det/version_augmentation.png", [A10. Augmentation: flips, ±15° rotation, ±15% brightness (3× on train).], h: 10.5cm),
  shot("roboflow_det/version_v1_572.png", [A11. Generated version v1: 572 images.], h: 10.5cm),
)

#pagebreak()
= B. Leaf disease spots: Semantic Segmentation dataset (FANet's own dataset)

#shot("roboflow/01_dataset_grid_30_labelled.png", [B1. Dataset view: all 30 photos labelled by hand.], w: 100%)
#v(4pt)
#shot("roboflow/02_annotate_board_30_jobs.png", [B2. Annotate board: 30 annotation jobs, all done.], w: 100%)

#pagebreak()
#grid(columns: (1fr, 1fr), gutter: 10pt, align: bottom,
  shot("roboflow/03_annotation_editor.png", [B3. Annotation editor: disease spots outlined with Polygon / Smart Polygon.], h: 10cm),
  shot("roboflow/04_labelled_example_00097.png", [B4. A finished label (photo leaf_00097).], h: 10cm),
)
#v(6pt)
#shot("roboflow/05_resize_256_stretch.png", [B5. Preprocessing: resize (stretch) to 256×256.], w: 100%)

#pagebreak()
#shot("roboflow/06_version_split_preprocessing.png", [B6. Version v1: split 24 / 6 and preprocessing.], w: 100%)
#v(4pt)
#shot("roboflow/07_aug_flip.png", [B7. Augmentation: horizontal and vertical flips.], w: 100%)

#pagebreak()
#shot("roboflow/08_aug_rotate90.png", [B8. Augmentation: 90° rotations (clockwise, counter-clockwise, upside down).], w: 100%)
#v(4pt)
#shot("roboflow/09_aug_brightness.png", [B9. Augmentation: brightness ±15%.], w: 100%)

#pagebreak()
#shot("roboflow/10_aug_summary.png", [B10. Augmentation summary: 5× outputs per training image.], w: 100%)
#v(4pt)
#shot("roboflow/11_version_v1_126_images.png", [B11. Generated version v1: 126 images (120 train + 6 valid).], w: 100%)
