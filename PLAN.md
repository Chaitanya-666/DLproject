# Plan (v3, 13 Oct 2026)

**Locked topic:** FANet (Tomar et al., IEEE TNNLS 2023) on Kvasir-SEG. Registered 13 Oct, row 29 of the sheet.
Everything about the paper, the code and how to run it is in [README.md](README.md).

History: v1 CondInst ([docs/v1-condinst-plan.md](docs/v1-condinst-plan.md)) was infeasible on one GPU. v2 picked ColonSegNet (IEEE Access 2021), dropped on 13 Oct because March 2021 is outside a strict 5-year window.

## Checklist

- [x] Topic registered
- [x] Code scaffold: model, memory, data, loss, metrics, train, evaluate, own-dataset tools (smoke-tested on CPU)
- [x] Synthetic own dataset (`dataset/custom/synthetic_leaf`, 60 samples)
- [ ] Read the paper's method + experiments; copy its Kvasir-SEG numbers into README §10; confirm the split protocol
- [ ] Kaggle: GitHub token secret, sanity run, full training run (target: baseline Dice by Sun 18 Oct)
- [ ] Evaluate with 10 refinement rounds; ablation without feedback
- [ ] Own photos: 40–60 leaf-spot photos, Labelme, convert, fine-tune
- [ ] Results table + figures
- [ ] PPT (~12 slides, outline in README §11), rehearse viva answers (README §12). Done by Sat 31 Oct

## Timeline

| When | What | Hours |
|---|---|---|
| Wed 14 – Fri 16 Oct | Read paper; Kaggle notebook running; sanity run | 2–3 |
| Sat 17 – Sun 18 Oct | Full training; baseline Dice | 3–4 (mostly waiting) |
| Mon 19 – Sun 25 Oct (DL viva week) | Evaluation, ablation, own dataset, fine-tune | 5–6 |
| Mon 26 – Sat 31 Oct | PPT, figures, rehearsal | 5 |
| 1 – 7 Nov | Buffer before Diwali | — |

## Questions still open for ma'am

- Is a synthetic (script-generated) dataset acceptable for the "own dataset", or must it be photos we collected? (Plan covers both.)
- Is segmentation alone enough, or should the detection view (boxes from masks) be shown too? (Implemented either way.)
