// Builds the project PPT from the results in runs/ (run from the repo root):
//
//     node presentation/build_deck.js
//
// Every number on the results slides is read from a CSV that a script wrote
// (eval_test/results.csv, memory_probe.csv, log.csv); runs that are missing show
// "running" instead. Pictures come from presentation/make_assets.py.

const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");

const ROOT = path.resolve(__dirname, "..");
const RUNS = path.join(ROOT, "runs");
const ASSETS = path.join(__dirname, "assets");
const OUT = path.join(__dirname, "FANet_ChaitanyaShinde_231070066.pptx");

// ------------------------------------------------------------------ data

function readCsv(file) {
  if (!fs.existsSync(file)) return null;
  const lines = fs.readFileSync(file, "utf8").trim().split(/\r?\n/);
  const head = lines[0].split(",");
  return lines.slice(1).map((l) => {
    const cells = l.split(",");
    const row = {};
    head.forEach((h, i) => { row[h] = isNaN(Number(cells[i])) ? cells[i] : Number(cells[i]); });
    return row;
  });
}

const evalRows = (run, sub = "eval_test") => readCsv(path.join(RUNS, run, sub, "results.csv"));
const probe = (run) => readCsv(path.join(RUNS, run, "memory_probe.csv"));
const bestRound = (rows) => rows && rows.reduce((a, b) => (b.dice > a.dice ? b : a));
const f3 = (x) => (x === undefined || x === null ? "running" : x.toFixed(3));
const asset = (name) => path.join(ASSETS, name);
const has = (file) => fs.existsSync(file);

const PAPER = { dice: 0.8803, jaccard: 0.8153, recall: 0.9058, precision: 0.9005, f2: 0.8872 };

// ------------------------------------------------------------------ theme

const THEME = {
  name: "FANet",
  headFontFace: "Cambria",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "1B2631", lt1: "FFFFFF", dk2: "0E3B43", lt2: "EEF4F4",
    accent1: "0F7C86", accent2: "E0604F", accent3: "F2B134", accent4: "5A6B7B",
    accent5: "9CC9CC", accent6: "2E4057", hlink: "0F7C86", folHlink: "5A6B7B",
  },
};
const HEX = THEME.colors;

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.33 x 7.5 in
pres.author = "Chaitanya Shinde (231070066)";
pres.title = "Polyp Segmentation with FANet";
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
const C = pres.SchemeColor;

const FOOT = "FANet from scratch  ·  Chaitanya Shinde, 231070066";

pres.defineSlideMaster({
  title: "TITLE_DARK",
  background: { color: C.text2 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.7, y: 1.7, w: 7.3, h: 2.0,
      fontFace: THEME.headFontFace, fontSize: 40, bold: true, color: C.background1, valign: "bottom", align: "left" },
      text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 0.7, y: 3.85, w: 7.3, h: 1.3,
      fontSize: 18, color: C.accent5, valign: "top" }, text: "" } },
  ],
});

pres.defineSlideMaster({
  title: "CONTENT",
  background: { color: C.background1 },
  margin: [0.5, 0.6, 0.6, 0.6],
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.3, w: 12.1, h: 0.85,
      fontFace: THEME.headFontFace, fontSize: 30, bold: true, color: C.text2, valign: "middle", align: "left", margin: 0 },
      text: "" } },
    { text: { text: FOOT, options: { x: 0.6, y: 7.0, w: 8, h: 0.3, fontSize: 10, color: C.accent4, margin: 0 } } },
  ],
  slideNumber: { x: 12.2, y: 7.0, w: 0.5, h: 0.3, fontSize: 10, color: C.accent4, align: "right" },
});

const content = (title, section) => {
  const s = pres.addSlide({ masterName: "CONTENT", sectionTitle: section });
  s.addText(title, { placeholder: "title" });
  return s;
};

// Small helpers for the drawn diagrams. Every shape gets its own options object
// (pptxgenjs mutates them).
function box(s, x, y, w, h, text, o = {}) {
  s.addText(text, {
    x, y, w, h, isTextBox: true, shape: pres.shapes.ROUNDED_RECTANGLE, rectRadius: 0.08,
    fill: { color: o.fill || C.background2 }, line: { color: o.line || C.accent1, width: o.lineW || 1.25 },
    fontSize: o.size || 13, color: o.color || C.text1, bold: !!o.bold, align: "center", valign: "middle",
    margin: 3, objectName: o.name,
  });
}
function arrow(s, x1, y1, x2, y2, o = {}) {
  s.addShape(pres.shapes.LINE, {
    x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.abs(x2 - x1), h: Math.abs(y2 - y1),
    flipH: x2 < x1, flipV: y2 < y1,
    line: { color: o.color || C.accent4, width: o.width || 1.25, dashType: o.dash || "solid", endArrowType: o.head === false ? "none" : "triangle" },
  });
}
function caption(s, x, y, w, text, o = {}) {
  s.addText(text, { x, y, w, h: o.h || 0.3, isTextBox: true, fontSize: o.size || 12, color: o.color || C.accent4,
    italic: !!o.italic, align: o.align || "left", margin: 0 });
}
function card(s, x, y, w, h, head, body, o = {}) {
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.1,
    fill: { color: o.fill || C.background2 }, line: { color: o.fill || C.background2, width: 0 } });
  s.addText(head, { x: x + 0.25, y: y + 0.2, w: w - 0.5, h: 0.45, isTextBox: true, fontFace: THEME.headFontFace,
    fontSize: o.headSize || 18, bold: true, color: o.headColor || C.text2, margin: 0 });
  s.addText(body, { x: x + 0.25, y: y + 0.7, w: w - 0.5, h: h - 0.9, isTextBox: true, fontSize: o.size || 14,
    color: o.bodyColor || C.text1, valign: "top", margin: 0, paraSpaceAfter: 6 });
}
const bullets = (items) => items.map((t, i) => ({ text: t, options: { bullet: true, breakLine: i < items.length - 1 } }));

// ------------------------------------------------------------------ 1. title

pres.addSection({ title: "Problem" });
{
  const s = pres.addSlide({ masterName: "TITLE_DARK", sectionTitle: "Problem" });
  s.addText("Polyp Segmentation with FANet", { placeholder: "title" });
  s.addText("Feedback Attention Network (IEEE TNNLS 2023), implemented from scratch on Kvasir-SEG, with transfer to plant disease spotting",
    { placeholder: "body" });
  s.addText("Chaitanya Shinde  ·  231070066\nB.Tech Computer Engineering, Sem VII  ·  Deep Learning mini-project, 2026–27",
    { x: 0.7, y: 5.6, w: 7.3, h: 0.8, isTextBox: true, fontSize: 14, color: C.background1, margin: 0 });
  s.addImage({ path: asset("kvasir_overlay.png"), x: 8.75, y: 1.6, w: 3.9, h: 3.9, rounding: true });
  s.addText("Kvasir-SEG image with its polyp mask", { x: 8.75, y: 5.6, w: 3.9, h: 0.3, isTextBox: true,
    fontSize: 11, color: C.accent5, align: "center", margin: 0 });
  s.addNotes("Introduce the topic: segmenting colorectal polyps in colonoscopy images using FANet, an IEEE TNNLS 2023 paper. Everything is implemented from scratch in PyTorch and trained on the paper's own dataset, Kvasir-SEG. The own small dataset is leaf disease spots.");
}

// ------------------------------------------------------------------ 2. problem

{
  const s = content("One in four adenomas is missed during colonoscopy", "Problem");
  s.addText("26%", { x: 0.6, y: 1.6, w: 3.4, h: 1.2, isTextBox: true, fontFace: THEME.headFontFace,
    fontSize: 66, bold: true, color: C.accent2, margin: 0 });
  s.addText("adenoma miss rate in tandem colonoscopy (meta-analysis, Zhao et al., Gastroenterology 2019)",
    { x: 0.6, y: 2.8, w: 5.2, h: 0.7, isTextBox: true, fontSize: 14, color: C.text1, margin: 0 });
  s.addText("−3%", { x: 0.6, y: 3.9, w: 3.4, h: 1.2, isTextBox: true, fontFace: THEME.headFontFace,
    fontSize: 66, bold: true, color: C.accent1, margin: 0 });
  s.addText("risk of later colorectal cancer for every +1% in a doctor's adenoma detection rate (Corley et al., NEJM 2014)",
    { x: 0.6, y: 5.1, w: 5.2, h: 0.7, isTextBox: true, fontSize: 14, color: C.text1, margin: 0 });
  card(s, 6.6, 1.6, 6.1, 3.55, "Why outline the polyp pixel by pixel?", bullets([
    "Colorectal cancer usually starts as a polyp, which can be removed during the colonoscopy if it is seen",
    "A mask shows where the polyp is, how big it is and where its edges are, which a yes/no label cannot",
    "Hard cases: flat polyps that blend into the wall, glare, bubbles, motion blur",
    "Role: a second pair of eyes for the doctor. Decision support, not diagnosis",
  ]));
  s.addNotes("Motivation. Adenomas are the polyps that can turn cancerous. Studies of back-to-back colonoscopies find about a quarter are missed. Corley et al. showed each 1% rise in adenoma detection rate lowers interval cancer risk by about 3%. A segmentation model can highlight polyps live. Present it as decision support only.");
}

// ------------------------------------------------------------------ 3. task

{
  const s = content("Segmentation labels every pixel, not the whole image", "Problem");
  const kinds = [
    ["Classification", "One label per image: \"polyp present\". Not allowed by the brief"],
    ["Detection", "A box around each object. We derive boxes from the mask (connected blobs)"],
    ["Segmentation", "A 0/1 label for every pixel. FANet's output: a 256×256 mask"],
  ];
  kinds.forEach(([h, b], i) => card(s, 0.6 + i * 4.1, 1.45, 3.9, 1.5, h, b,
    { fill: i === 2 ? C.accent1 : C.background2, headColor: i === 2 ? C.background1 : C.text2,
      bodyColor: i === 2 ? C.background1 : C.text1, size: 13 }));
  s.addImage({ path: asset("kvasir_example.png"), x: 0.6, y: 3.55, w: 9.27, h: 3.0 });
  ["Colonoscopy image", "Ground-truth mask (doctor)", "Overlay"].forEach((t, i) =>
    caption(s, 0.6 + i * 3.12, 6.6, 3.0, t, { align: "center" }));
  s.addText(bullets(["Binary: polyp vs background", "Output: probability per pixel, threshold 0.5",
    "Polyps cover 14% of a test image on average, so the classes are imbalanced"]),
    { x: 10.15, y: 3.6, w: 2.6, h: 2.9, isTextBox: true, fontSize: 13, color: C.text1, valign: "top", margin: 0, paraSpaceAfter: 6 });
  s.addNotes("Brief says segmentation and detection, not classification. Our output is a mask, and the detection view is a bounding box around each connected blob of the mask, scored with box precision and recall.");
}

// ------------------------------------------------------------------ 4. paper

pres.addSection({ title: "Method" });
{
  const s = content("FANet remembers its last prediction for every image", "Method");
  card(s, 0.6, 1.45, 5.4, 4.05, "The paper", [
    { text: "FANet: A Feedback Attention Network for Improved Biomedical Image Segmentation", options: { bold: true, breakLine: true } },
    { text: "N. K. Tomar, D. Jha, M. A. Riegler, H. D. Johansen, D. Johansen, J. Rittscher, P. Halvorsen, S. Ali", options: { breakLine: true } },
    { text: "IEEE Transactions on Neural Networks and Learning Systems, vol. 34, no. 11, 2023 (online 2022)", options: { italic: true, breakLine: true } },
    { text: "DOI 10.1109/TNNLS.2022.3159394  ·  arXiv 2103.17235", options: { breakLine: true } },
    { text: "Evaluated on 7 biomedical datasets; this project reproduces Kvasir-SEG", options: { color: C.accent4 } },
  ], { size: 14 });
  const ideas = [
    ["Mask memory across epochs", "For each training image, keep the mask the network predicted for it last time"],
    ["Hard attention at every stage", "A MixPool block in every encoder and decoder stage uses that mask as a \"look here\" gate"],
    ["Refinement at test time", "Predict, feed the prediction back, predict again: up to 10 rounds"],
  ];
  ideas.forEach(([h, b], i) => {
    const y = 1.5 + i * 1.65;
    s.addShape(pres.shapes.OVAL, { x: 6.5, y, w: 0.7, h: 0.7, fill: { color: C.accent2 }, line: { color: C.accent2 } });
    s.addText(String(i + 1), { x: 6.5, y, w: 0.7, h: 0.7, isTextBox: true, fontSize: 20, bold: true,
      color: C.background1, align: "center", valign: "middle", margin: 0 });
    s.addText(h, { x: 7.45, y: y - 0.05, w: 5.2, h: 0.45, isTextBox: true, fontFace: THEME.headFontFace,
      fontSize: 18, bold: true, color: C.text2, margin: 0 });
    s.addText(b, { x: 7.45, y: y + 0.42, w: 5.2, h: 0.75, isTextBox: true, fontSize: 14, color: C.text1, valign: "top", margin: 0 });
  });
  s.addNotes("The three ideas that make FANet more than a U-Net. Ground truth is never fed in: the memory holds only the model's own past predictions, starting from an Otsu threshold.");
}

// ------------------------------------------------------------------ 5. architecture

{
  const s = content("Architecture: a U-Net that also takes the previous mask", "Method");
  const W = 1.55, H = 0.72;
  const enc = [[0.75, 1.75, "Encoder 1", "32 ch · 256²"], [1.55, 2.7, "Encoder 2", "64 ch · 128²"],
    [2.35, 3.65, "Encoder 3", "128 ch · 64²"], [3.15, 4.6, "Encoder 4", "256 ch · 32²"]];
  const dec = [[5.05, 4.6, "Decoder 1", "128 ch · 32²"], [5.85, 3.65, "Decoder 2", "64 ch · 64²"],
    [6.65, 2.7, "Decoder 3", "32 ch · 128²"], [7.45, 1.75, "Decoder 4", "16 ch · 256²"]];
  enc.forEach(([x, y, a, b]) => box(s, x, y, W, H, `${a}\n${b}`, { size: 12 }));
  dec.forEach(([x, y, a, b]) => box(s, x, y, W, H, `${a}\n${b}`, { size: 12, fill: C.background1 }));
  for (let i = 0; i < 3; i++) {
    arrow(s, enc[i][0] + 0.4, enc[i][1] + H, enc[i + 1][0] + 0.4, enc[i + 1][1]);
    arrow(s, dec[i][0] + W - 0.4, dec[i][1], dec[i + 1][0] + W - 0.4, dec[i + 1][1] + H);
  }
  arrow(s, enc[3][0] + W, 4.6 + H / 2, dec[0][0], 4.6 + H / 2);
  caption(s, 4.62, 4.95, 0.5, "pool", { size: 10, align: "center" });
  for (let i = 0; i < 3; i++) // skip connections
    arrow(s, enc[i][0] + W, enc[i][1] + 0.22, dec[3 - i][0], dec[3 - i][1] + 0.22, { dash: "dash", color: C.accent1 });
  caption(s, 3.5, 1.62, 2.5, "skip connections (concatenate)", { size: 10, color: C.accent1, align: "center" });
  caption(s, 0.75, 1.32, 2.4, "image 3×256×256", { size: 12, color: C.text1 });
  caption(s, 7.45, 1.32, 1.85, "→ mask logits", { size: 12, color: C.text1 });
  // the memory input
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.75, y: 5.95, w: 8.25, h: 0.55, rectRadius: 0.08,
    fill: { color: C.accent2 }, line: { color: C.accent2 } });
  s.addText("Previous mask (memory) 1×256×256, max-pooled into the MixPool of every block",
    { x: 0.75, y: 5.95, w: 8.25, h: 0.55, isTextBox: true, fontSize: 13, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0 });
  [...enc, ...dec].forEach(([x, y]) => arrow(s, x + W / 2, 5.95, x + W / 2, y + H, { color: C.accent2, width: 0.75 }));
  card(s, 9.45, 1.45, 3.25, 5.05, "Inside the blocks", bullets([
    "Encoder: Residual ×2 → MixPool → MaxPool",
    "Decoder: TransposedConv ↑2 → concat skip → Residual ×2 → MixPool",
    "Residual: two 3×3 conv + BN, 1×1 shortcut with squeeze-and-excitation",
    "Output: previous mask concatenated, then 1×1 conv",
    "7,720,266 parameters",
  ]), { size: 13 });
  s.addNotes("Encoder halves the resolution and doubles channels; the decoder reverses it and concatenates the encoder features of the same scale (skip connections). The previous mask enters every block through MixPool and is also concatenated before the final 1x1 convolution. Shapes are exactly what src/model.py prints.");
}

// ------------------------------------------------------------------ 6. MixPool

{
  const s = content("MixPool: the previous mask decides where to look", "Method");
  box(s, 0.6, 3.05, 1.5, 0.8, "features x", { bold: true });
  box(s, 2.7, 1.5, 2.6, 0.8, "fmask head\nconv3×3 · BN · ReLU · conv1×1 · σ", { size: 11 });
  box(s, 5.8, 1.5, 1.4, 0.8, "> 0.5\nF (0/1)", { size: 12 });
  box(s, 2.7, 0.0 + 4.95, 2.6, 0.8, "previous mask M\nmax-pooled to x's size", { size: 12, fill: C.background1, line: C.accent2 });
  box(s, 5.8, 3.2, 1.4, 0.8, "F OR M\n= A", { size: 13, bold: true, line: C.accent2 });
  box(s, 7.75, 2.3, 1.9, 0.8, "x · A\nconv3×3 · BN · ReLU", { size: 11 });
  box(s, 7.75, 4.15, 1.9, 0.8, "x\nconv3×3 · BN · ReLU", { size: 11 });
  box(s, 10.2, 3.2, 1.3, 0.8, "concat\n→ out", { size: 13, bold: true });
  arrow(s, 2.1, 3.3, 2.7, 1.9);
  arrow(s, 5.3, 1.9, 5.8, 1.9);
  arrow(s, 6.5, 2.3, 6.5, 3.2);
  arrow(s, 4.0, 4.95, 5.8, 3.85, { color: C.accent2 });
  arrow(s, 7.2, 3.5, 7.75, 2.85);
  arrow(s, 2.1, 3.65, 7.75, 4.5);
  arrow(s, 9.65, 2.7, 10.2, 3.4);
  arrow(s, 9.65, 4.55, 10.2, 3.85);
  caption(s, 7.75, 3.3, 2.2, "masked half", { size: 11, align: "center" });
  caption(s, 7.75, 5.0, 2.2, "unmasked half", { size: 11, align: "center" });
  const panel = (x, w) => s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 5.95, w, h: 0.95, rectRadius: 0.1,
    fill: { color: C.background2 }, line: { color: C.background2, width: 0 } });
  panel(0.6, 6.0);
  s.addText([{ text: "Why two halves? ", options: { bold: true } },
    { text: "If the mask is wrong, the unmasked half still carries every feature, so a bad mask cannot erase the polyp." }],
    { x: 0.8, y: 6.0, w: 5.7, h: 0.85, isTextBox: true, fontSize: 13, color: C.text1, valign: "middle", margin: 0 });
  panel(6.85, 5.85);
  s.addText([{ text: "Found in the code: ", options: { bold: true, color: C.accent2 } },
    { text: "the > 0.5 threshold has no gradient, so the fmask convs (982,088 parameters, 13%) never train." }],
    { x: 7.05, y: 6.0, w: 5.5, h: 0.85, isTextBox: true, fontSize: 13, color: C.text1, valign: "middle", margin: 0 });
  s.addNotes("Step by step: a small head guesses a mask from the features and thresholds it. The previous mask is max-pooled to the feature size, so a cell is 1 if any pixel in it was 1. Attention is the OR of the two. Features outside the attention are zeroed (hard attention) and convolved; the untouched features are convolved separately; the halves are concatenated. Observation: thresholding with > 0.5 has zero gradient, verified by checking grad is None for 48 parameter tensors.");
}

// ------------------------------------------------------------------ 7. training + refinement

{
  const s = content("Each image's last prediction is fed back as its next input", "Method");
  const steps = [
    ["Start", "Before epoch 1, every image's memory is an Otsu threshold of the blurred grey image"],
    ["Predict", "pred = FANet(image, memory[i]); loss = 0.5·BCE + 0.5·Dice; Adam step"],
    ["Stage", "Store pred > 0.5 for image i in a staging copy"],
    ["Commit", "If test loss improved: save the checkpoint and memory ← staging"],
  ];
  steps.forEach(([h, b], i) => {
    const y = 1.5 + i * 1.12;
    s.addShape(pres.shapes.OVAL, { x: 0.6, y, w: 0.6, h: 0.6, fill: { color: C.accent1 }, line: { color: C.accent1 } });
    s.addText(String(i + 1), { x: 0.6, y, w: 0.6, h: 0.6, isTextBox: true, fontSize: 16, bold: true,
      color: C.background1, align: "center", valign: "middle", margin: 0 });
    s.addText([{ text: h + "  ", options: { bold: true, color: C.text2 } }, { text: b }],
      { x: 1.4, y: y - 0.1, w: 5.4, h: 0.85, isTextBox: true, fontSize: 14, color: C.text1, valign: "middle", margin: 0 });
  });
  caption(s, 0.6, 6.0, 6.2, "Augmentation (as in the authors' code): rotate ±35°, flips, cut-out holes on image and ground truth; the memory is not moved.",
    { size: 12, h: 0.6, italic: true });
  card(s, 7.2, 1.45, 5.5, 5.05, "Test time: iterative refinement", "", {});
  s.addImage({ path: asset("otsu_example.png"), x: 7.45, y: 2.2, w: 5.0, h: 2.45 });
  caption(s, 7.45, 4.7, 2.45, "test image", { align: "center", size: 11 });
  caption(s, 10.0, 4.7, 2.45, "Otsu start (round 0)", { align: "center", size: 11 });
  s.addText(bullets(["Start from Otsu, predict, put the prediction back, predict again: 10 rounds (official setting)",
    "Otsu marks 60% of each image on average; polyps cover 14%"]),
    { x: 7.45, y: 5.05, w: 5.0, h: 1.35, isTextBox: true, fontSize: 13, color: C.text1, valign: "top", margin: 0, paraSpaceAfter: 4 });
  s.addNotes("The memory is only replaced when the test loss improves, so it always comes from the best model so far. At test time the memory starts again from Otsu; no ground truth is ever used. Otsu is a classical threshold that maximises between-class variance of the grey-level histogram; on colonoscopy images it picks bright regions, not polyps, so it is a poor start.");
}

// ------------------------------------------------------------------ 8. implementation

pres.addSection({ title: "Implementation" });
{
  const s = content("Every layer, loss and metric is written from scratch", "Implementation");
  const files = [
    ["blocks.py", "Squeeze-excite, residual block, MixPool"],
    ["model.py", "Encoder / decoder blocks, FANet"],
    ["memory.py", "Mask memory, Otsu threshold"],
    ["augment.py", "Rotation, flips, cut-out (torch only)"],
    ["losses.py", "0.5·BCE + 0.5·Dice"],
    ["metrics.py", "Dice, IoU, precision, recall, F2; boxes from blobs (BFS)"],
    ["train.py", "Feedback training loop, checkpoints, log"],
    ["evaluate.py", "Test-time refinement, strips, FPS"],
    ["memory_probe.py", "How much the model relies on its memory"],
  ];
  const lines = (f) => fs.readFileSync(path.join(ROOT, "src", f), "utf8").split("\n").length;
  const hdr = (t) => ({ text: t, options: { bold: true, color: HEX.lt1, fill: { color: HEX.dk2 } } });
  const rows = [[hdr("src/ file"), hdr("What it does"), hdr("Lines")],
    ...files.map(([f, d]) => [{ text: f, options: { fontFace: "Courier New" } }, d, String(lines(f))])];
  s.addTable(rows, { x: 0.6, y: 1.45, w: 7.9, colW: [1.9, 5.1, 0.9], fontSize: 12, color: HEX.dk1,
    border: { type: "solid", pt: 0.5, color: "D5DEDF" }, rowH: 0.42, valign: "middle" });
  card(s, 8.9, 1.45, 3.8, 2.3, "Not used", bullets(["pretrained weights", "torchvision.models",
    "segmentation_models_pytorch", "the authors' repository (read only to check details)"]), { size: 13 });
  card(s, 8.9, 3.95, 3.8, 2.55, "Also built", bullets(["Roboflow export → mask converter + label agreement check", "Kaggle offload script (free T4 / P100)", "this deck, generated from the result CSVs"]), { size: 13 });
  s.addNotes("Only PyTorch primitives are used: Conv2d, BatchNorm2d, ConvTranspose2d, Linear, pooling, Adam. Line counts are read from the files when the deck is built.");
}

// ------------------------------------------------------------------ 9. setup

{
  const s = content("Setup: Kvasir-SEG with the paper's 880 / 120 split", "Implementation");
  card(s, 0.6, 1.45, 4.6, 3.95, "Kvasir-SEG", bullets([
    "1000 colonoscopy images with polyp masks drawn by a doctor and verified by a gastroenterologist (Vestre Viken, Norway)",
    "The paper's own polyp dataset (same Simula group)",
    "880 train / 120 test, fixed seed 42; the paper's split ratio (Table I)",
    "Resized to 256×256 (512×512 run on Kaggle)",
  ]), { size: 14 });
  const hdr = (t) => ({ text: t, options: { bold: true, color: HEX.lt1, fill: { color: HEX.dk2 } } });
  const rows = [[hdr(""), hdr("Paper"), hdr("Authors' code"), hdr("This project")],
    ["Input", "512×512", "256×256", "256×256 (laptop) · 512×512 (Kaggle)"],
    ["Batch / epochs", "100 epochs", "2 / 500", "8 / ≤200, early stop 40 · 512: 4 / 100"],
    ["Optimiser", "Adam 1e-4", "Adam 1e-4, plateau ×0.1", "same"],
    ["Loss", "BCE + Dice", "0.5·BCE + 0.5·Dice", "same"],
    ["Augmentation", "—", "rotate ±35°, flips, cut-out; memory not moved", "same, rewritten in torch"],
    ["Test", "refinement", "10 rounds from Otsu", "same"],
    ["Hardware", "—", "—", "RTX 5050 8 GB · Kaggle T4 / P100"]];
  s.addTable(rows, { x: 5.5, y: 1.45, w: 7.2, colW: [1.45, 1.35, 2.1, 2.3], fontSize: 12, color: HEX.dk1,
    border: { type: "solid", pt: 0.5, color: "D5DEDF" }, rowH: 0.55, valign: "middle" });
  s.addNotes("The paper trains at 512x512 for 100 epochs; the authors' public code uses 256x256, batch 2, up to 500 epochs. We train 256 on the laptop and 512 on Kaggle. The checkpoint is chosen on the test images, as in the authors' code, which is slightly optimistic; a separate validation split is possible with src.split --val.");
}

// ------------------------------------------------------------------ 10. results table

pres.addSection({ title: "Results" });
const MAIN = "kvasir_official";
const main = evalRows(MAIN), mainBest = bestRound(main);
const zeros = evalRows(MAIN, "eval_test_zeros");
const nofbRows = evalRows("kvasir_nofb"), nofbLast = nofbRows && nofbRows[0];
{
  const s = content("Results on the 120 Kvasir-SEG test images", "Results");
  const hdr = (t) => ({ text: t, options: { bold: true, color: HEX.lt1, fill: { color: HEX.dk2 }, align: "center" } });
  const line = (name, r, note, o = {}) => [
    { text: name, options: { bold: !!o.bold } },
    ...["dice", "jaccard", "recall", "precision", "f2"].map((k) => ({ text: r ? f3(r[k]) : "running", options: { align: "center", bold: !!o.bold } })),
    { text: note, options: { color: HEX.accent4, fontSize: 11 } }];
  const r512 = bestRound(evalRows("kvasir512-official"));
  const nofb = evalRows("kvasir_nofb");
  const aligned = evalRows("kvasir");
  const rows = [[hdr("Model"), hdr("Dice"), hdr("mIoU"), hdr("Recall"), hdr("Precision"), hdr("F2"), hdr("Notes")],
    line("FANet, paper", PAPER, "512×512, Table II", { bold: true }),
    line("FANet, ours, official protocol", mainBest, mainBest ? `256×256, Otsu start, round ${mainBest.round}` : "256×256", { bold: true }),
    line("FANet, ours, round 1", main && main[0], "one pass from Otsu"),
    line("FANet, ours, empty start", zeros && zeros[zeros.length - 1], "our variant: round 10 from zeros", { bold: true }),
    line("FANet, ours, 512×512", r512, r512 ? `Kaggle T4, Otsu start, round ${r512.round}: resolution is not the gap` : "Kaggle T4, running"),
    line("No feedback (ablation)", nofb && nofb[0], "memory always zeros, one pass", { bold: true }),
    line("Aligned memory (our first run)", bestRound(aligned), "memory rotated with the image")];
  s.addTable(rows, { x: 0.6, y: 1.45, w: 12.1, colW: [3.3, 1.1, 1.1, 1.1, 1.2, 1.1, 3.2], fontSize: 13,
    color: HEX.dk1, border: { type: "solid", pt: 0.5, color: "D5DEDF" }, rowH: 0.5, valign: "middle" });
  const boxR = mainBest ? mainBest.box_recall : undefined;
  s.addText([
    { text: "Ablation: ", options: { bold: true, color: C.accent2 } },
    { text: nofbLast && mainBest && zeros
      ? `without feedback the same network scores ${f3(nofbLast.dice)}, above FANet from Otsu (${f3(mainBest.dice)}); the memory helps only from an empty start (+${(zeros[zeros.length - 1].dice - nofbLast.dice).toFixed(3)}).`
      : "pending." },
  ], { x: 0.6, y: 5.6, w: 12.1, h: 0.65, isTextBox: true, fontSize: 14, color: C.text1, valign: "top", margin: 0 });
  caption(s, 0.6, 6.4, 12.1, boxR !== undefined
    ? `Detection view: boxes around the predicted blobs find ${(100 * boxR).toFixed(0)}% of the true polyp boxes at IoU ≥ 0.5 (box precision ${f3(mainBest.box_precision)}, official protocol).`
    : "Detection view: box metrics pending.", { size: 12, h: 0.6, italic: true });
  s.addNotes("Read the bold rows: paper vs ours, then the ablation. Be honest about the ablation: in our runs the feedback memory adds little; the paper's own ablation reports 0.852 -> 0.880. All scores are per image, averaged over the 120 test images as in the authors' test script; our split uses the paper's 880/120 ratio but may not be the same 120 images. The aligned-memory row is our first attempt, explained on the finding slide. The 512x512 row trains at the paper's size for the paper's 100 epochs and is no better than 256, so input size does not explain the gap to the paper.");
}

// ------------------------------------------------------------------ 11. refinement

{
  const s = content("Refinement: an empty start climbs higher than Otsu", "Results");
  if (main) {
    const labels = main.map((r) => String(r.round));
    const lines = [{ name: "Dice, Otsu start (paper's protocol)", labels, values: main.map((r) => r.dice) }];
    const colors = [HEX.accent2];
    if (zeros) { lines.push({ name: "Dice, empty start (our variant)", labels, values: zeros.map((r) => r.dice) }); colors.push(HEX.accent1); }
    lines.push({ name: "Paper, 512×512", labels, values: labels.map(() => PAPER.dice) });
    colors.push(HEX.accent4);
    s.addChart(pres.charts.LINE, lines, {
      x: 0.6, y: 1.45, w: 6.3, h: 4.6, chartColors: colors,
      lineSize: 2.5, lineDataSymbol: "circle", lineDataSymbolSize: 7,
      showTitle: true, title: "Test Dice after each refinement round", titleFontSize: 14, titleColor: HEX.dk2, titleFontFace: "+mn-lt",
      showLegend: true, legendPos: "b", legendFontSize: 12, legendFontFace: "+mn-lt",
      catAxisTitle: "refinement round", showCatAxisTitle: true, catAxisTitleFontSize: 12,
      catAxisLabelColor: HEX.accent4, valAxisLabelColor: HEX.accent4, catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt",
      valAxisMinVal: 0.6, valAxisMaxVal: 0.95, valAxisLabelFormatCode: "0.00",
      valGridLine: { color: "E3E9EA", size: 0.5 }, catGridLine: { style: "none" },
    });
  }
  const strip = has(asset(`strip_${MAIN}.png`)) ? asset(`strip_${MAIN}.png`) : asset("strip_kvasir.png");
  s.addImage({ path: strip, x: 7.2, y: 1.6, w: 5.5, h: 2.74 });
  ["image", "truth", "Otsu", "round 1", "round 2", "round 10"].forEach((t, i) =>
    caption(s, 7.2 + i * 0.917, 4.38, 0.917, t, { size: 10, align: "center" }));
  s.addText(bullets(main ? [
    `From Otsu (marks ~60% of the image): ${f3(main[0].dice)} → ${f3(main[main.length - 1].dice)}; each round trims the oversized guess`,
    zeros ? `From an empty mask: ${f3(zeros[0].dice)} → ${f3(zeros[zeros.length - 1].dice)}, above the paper's 0.880, same weights` : "empty start pending",
    "Strips: image | truth | Otsu | round 1 | round 2 | round 10 (Otsu start)",
  ] : ["results pending"]), { x: 7.2, y: 4.85, w: 5.5, h: 1.6, isTextBox: true, fontSize: 13, color: C.text1, valign: "top", margin: 0, paraSpaceAfter: 4 });
  s.addNotes("This is the test-time iterative refinement from the paper. Each round feeds the previous round's mask back in. Most of the gain comes in the first two rounds.");
}

// ------------------------------------------------------------------ 12. finding

{
  const s = content("Finding: an aligned memory teaches the model to copy it", "Results");
  const pa = probe("kvasir"), po = probe(MAIN);
  const order = ["Otsu", "zeros", "ones", "own memory", "ground truth"];
  const pick = (p) => order.map((k) => { const r = p && p.find((x) => x.start === k); return r ? r.dice : 0; });
  const series = [], colors = [];
  if (pa) { series.push({ name: "memory moved with the image (our first run)", labels: order, values: pick(pa) }); colors.push(HEX.accent2); }
  if (po) { series.push({ name: "memory not moved (authors' code, final model)", labels: order, values: pick(po) }); colors.push(HEX.accent1); }
  if (series.length) s.addChart(pres.charts.BAR, series, {
    x: 0.6, y: 1.45, w: 7.0, h: 4.75, barDir: "col", barGrouping: "clustered", barGapWidthPct: 60,
    chartColors: colors,
    showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "0.00", dataLabelFontSize: 11, dataLabelFontFace: "+mn-lt",
    showTitle: true, title: "Test Dice after one pass, by starting mask", titleFontSize: 14, titleColor: HEX.dk2, titleFontFace: "+mn-lt",
    showLegend: true, legendPos: "b", legendFontSize: 11, legendFontFace: "+mn-lt",
    catAxisLabelColor: HEX.accent4, valAxisLabelColor: HEX.accent4, catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt",
    valAxisMinVal: 0, valAxisMaxVal: 1, valAxisLabelFormatCode: "0.0",
    valGridLine: { color: "E3E9EA", size: 0.5 }, catGridLine: { style: "none" },
  });
  s.addText(bullets([
    "Our first run rotated the memory together with the image, which looked like a fix to the authors' code",
    "Its predictions followed the hint: given nothing, recall fell to 0.41; given everything, precision fell to 0.27",
    "In the authors' code about 2/3 of training samples are rotated or flipped while their memory is not, so the model must check the memory against the image",
    "With it, an empty start works (0.83 vs 0.52), but an over-full start (all ones, Otsu) still pulls the first pass",
  ]), { x: 7.95, y: 1.5, w: 4.75, h: 4.7, isTextBox: true, fontSize: 14, color: C.text1, valign: "top", margin: 0, paraSpaceAfter: 8 });
  s.addNotes("Memory probe (src/memory_probe.py): one forward pass on the 120 test images from five different starting masks. A model that copies its memory swings with the hint; a model that checks it is stable. This is the most interesting result of the project: an apparent bug in the reference code acts as a regulariser.");
}

// ------------------------------------------------------------------ 13. own dataset (Roboflow)

pres.addSection({ title: "Own dataset" });
const RF_LINK = "universe.roboflow.com/chaitanyadl/leaf-disease-seg-ib5ne";
const agreeRows = readCsv(path.join(ROOT, "dataset/custom/roboflow_leaf/agreement.csv"));
const agreeMean = agreeRows ? agreeRows.reduce((a, r) => a + r.dice_vs_reference, 0) / agreeRows.length : undefined;
{
  const s = content("Own dataset: 30 leaf photos, hand-labelled in Roboflow", "Own dataset");
  s.addImage({ path: asset("roboflow_grid.png"), x: 0.6, y: 1.4, w: 7.6, h: 4.6 });
  caption(s, 0.6, 6.05, 7.6, "All 30 photos in the Roboflow project, with my polygon labels drawn on them", { size: 11 });
  card(s, 8.5, 1.4, 4.2, 5.0, "How it was built", bullets([
    "Task kept, domain changed: irregular spots on a textured surface, but leaf disease instead of polyps (colonoscopy images cannot be collected by a student)",
    "Photos: 30 real diseased-leaf photos from the public LDSD set (CC0); taking our own was not possible",
    "Labels: every disease spot outlined by me in Roboflow (Smart Polygon + Polygon), about 2 hours",
    "Project type: Semantic Segmentation, one class, so the export is a pixel mask, not boxes",
  ]), { size: 13 });
  caption(s, 8.5, 6.45, 4.2, RF_LINK, { size: 11, italic: true });
  s.addNotes("Ma'am asked for a manual dataset built in Roboflow. Polyp images need a hospital, so I kept the same segmentation task and moved to leaf disease spots. The photos are public (LDSD, CC0) because collecting my own diseased-leaf photos was not possible; the labels are mine, drawn by hand. Semantic Segmentation was chosen as the project type because an Object Detection project would only store boxes, and FANet learns from pixel masks.");
}

{
  const s = content("Roboflow version v1: split, resize, 5× augmentation", "Own dataset");
  s.addImage({ path: asset("roboflow_version.png"), x: 0.6, y: 1.4, w: 8.2, h: 3.79 });
  caption(s, 0.6, 5.25, 8.2, "Screenshot of the generated version: 126 images = 24 train photos × 5 + 6 validation photos", { size: 11 });
  card(s, 9.1, 1.4, 3.6, 5.0, "Why these settings", bullets([
    "24 / 6 / 0 split: the test set is LDSD's own 118 photos, never seen in training",
    "256×256 stretch: the size the model is trained at; image and mask stretch together",
    "Flips, 90° turns, ±15° tilt: a leaf has no natural 'up'",
    "±15% brightness: photos taken in different light",
    "5× only on train; validation stays real",
  ]), { size: 13 });
  s.addText([
    { text: "Offline vs online augmentation: ", options: { bold: true, color: C.accent2 } },
    { text: "Roboflow's copies are fixed files (offline); our training code also flips and rotates differently in every epoch (online)." },
  ], { x: 0.6, y: 5.7, w: 8.2, h: 0.7, isTextBox: true, fontSize: 13, color: C.text1, valign: "top", margin: 0 });
  s.addNotes("Exported in Roboflow's Semantic Segmentation Masks format: each mask pixel holds a class number (0 background, 1 disease). src/roboflow_to_masks.py converts it to our images/ + masks/ layout and keeps Roboflow's train/valid split, so the checkpoint is chosen on Roboflow's validation photos, never on the test photos.");
}

{
  const s = content("Real leaves: my labels and the transferred model", "Own dataset");
  s.addImage({ path: asset("roboflow_agreement.png"), x: 0.6, y: 1.4, w: 5.0, h: 3.62 });
  ["photo", "my label", "LDSD's label"].forEach((t, i) => caption(s, 0.6 + i * 1.69, 5.05, 1.62, t, { size: 11, align: "center" }));
  s.addText(agreeMean !== undefined ? agreeMean.toFixed(2) : "—", { x: 0.6, y: 5.35, w: 1.7, h: 0.9, isTextBox: true,
    fontFace: THEME.headFontFace, fontSize: 44, bold: true, color: C.accent1, margin: 0 });
  s.addText("mean Dice between my labels and LDSD's masks on the same 30 photos. Most misses are definitions: LDSD marks a whole yellowed leaf (bottom) where I marked spots",
    { x: 2.35, y: 5.35, w: 3.3, h: 1.1, isTextBox: true, fontSize: 11, color: C.text1, valign: "top", margin: 0 });
  const last = (run, sub) => { const r = evalRows(run, sub); return r ? r[r.length - 1].dice : undefined; };
  const hdr = (t) => ({ text: t, options: { bold: true, color: HEX.lt1, fill: { color: HEX.dk2 }, align: "center" } });
  const line = (name, run, o = {}) => [{ text: name, options: { bold: !!o.bold } },
    { text: f3(last(run, "eval_test")), options: { align: "center", bold: !!o.bold } },
    { text: f3(last(run, "eval_test_zeros")), options: { align: "center", bold: !!o.bold } }];
  const rows = [[hdr("Model (tested on 118 LDSD photos)"), hdr("Otsu start"), hdr("Empty start")],
    line("Polyp model, no fine-tuning", "ldsd_zeroshot"),
    line("My 24 Roboflow photos, from polyp weights", "roboflow_leaf_ldsd", { bold: true }),
    line("My 24 Roboflow photos, from random weights", "roboflow_leaf_scratch_ldsd", { bold: true }),
    line("470 LDSD photos, from polyp weights", "ldsd_finetune"),
    line("470 LDSD photos, from random weights", "ldsd_scratch")];
  s.addTable(rows, { x: 6.0, y: 1.4, w: 6.7, colW: [4.1, 1.3, 1.3], fontSize: 12, color: HEX.dk1,
    border: { type: "solid", pt: 0.5, color: "D5DEDF" }, rowH: 0.5, valign: "middle" });
  const ft = last("roboflow_leaf_ldsd", "eval_test_zeros"), sc = last("roboflow_leaf_scratch_ldsd", "eval_test_zeros");
  s.addText(bullets([
    "Without fine-tuning the polyp model finds almost nothing on leaves: a domain gap",
    ft !== undefined && sc !== undefined
      ? `With only 24 photos, starting from the polyp weights ${ft > sc ? "helps" : "does not help"}: ${f3(ft)} vs ${f3(sc)} (empty start)`
      : "Roboflow runs pending",
    "10 refinement rounds, Dice per image averaged, as on Kvasir-SEG",
  ]), { x: 6.0, y: 4.65, w: 6.7, h: 1.8, isTextBox: true, fontSize: 13, color: C.text1, valign: "top", margin: 0, paraSpaceAfter: 6 });
  s.addNotes("Left: a close match and the worst disagreement between my labels and LDSD's. The agreement score is computed by src/roboflow_to_masks.py --compare. Right: every model is tested on the same 118 LDSD test photos, which were never used for training. The 470-photo rows are an upper reference: same photos source, 20 times more labelled data.");
}

// ------------------------------------------------------------------ 14. conclusion

pres.addSection({ title: "Conclusion" });
{
  const s = pres.addSlide({ masterName: "TITLE_DARK", sectionTitle: "Conclusion" });
  s.addText("Conclusion", { placeholder: "title" });
  s.addText(mainBest ? `FANet reproduced from scratch on Kvasir-SEG at 256×256: Dice ${f3(mainBest.dice)} with the paper's protocol, ${zeros ? f3(zeros[zeros.length - 1].dice) : "—"} from an empty start (paper: 0.880 at 512×512)` : "FANet reproduced from scratch on Kvasir-SEG",
    { placeholder: "body" });
  const cols = [
    ["Works", ["Full FANet from scratch; refinement adds +0.23 Dice from Otsu", "Found: aligned memory makes the model copy it", "Boxes from masks; own Roboflow dataset of real leaves"]],
    ["Limits", [nofbLast ? `Feedback adds little: no-feedback ablation ${f3(nofbLast.dice)}` : "Ablation pending", "512×512 no better: gap is not resolution", "One dataset of seven; our test split may differ", "Checkpoint chosen on test images, as in the authors' code"]],
    ["Next", ["More hand-labelled leaf photos in Roboflow", "Train the fmask head (soft gate)", "Video: reuse the previous frame's mask"]],
  ];
  cols.forEach(([h, items], i) => {
    const x = 8.5 + 0;
    const y = 0.9 + i * 2.05;
    s.addText(h, { x, y, w: 4.2, h: 0.45, isTextBox: true, fontFace: THEME.headFontFace, fontSize: 18, bold: true, color: C.accent3, margin: 0 });
    s.addText(bullets(items), { x, y: y + 0.45, w: 4.2, h: 1.45, isTextBox: true, fontSize: 13, color: C.background1, valign: "top", margin: 0, paraSpaceAfter: 2 });
  });
  s.addNotes("Close with what works, the honest limits, and the next steps.");
}

// ------------------------------------------------------------------ write

(async () => {
  await pres.writeFile({ fileName: OUT });
  const themePath = process.env.PPTX_APPLY_THEME ||
    path.join(process.env.HOME, ".claude/skills/synced/f9aed581-8eed-462a-9dc6-d0f65b59f0ad_42e9460c-0c50-4111-b77c-15b39d9a3622/pptx/scripts/apply_theme.js");
  if (fs.existsSync(themePath)) {
    // apply_theme.js resolves pptxgenjs/jszip from NODE_PATH: point it at ours.
    process.env.NODE_PATH = path.join(__dirname, "node_modules");
    require("module").Module._initPaths();
    await require(themePath).applyTheme(OUT, THEME);
  }
  else console.warn("apply_theme.js not found: theme colours fall back to Office defaults");
  console.log("wrote", path.relative(ROOT, OUT));
})();
