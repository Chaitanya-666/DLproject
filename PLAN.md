# Plan (v3, updated 19 Oct 2026)

**Locked topic:** FANet (Tomar et al., IEEE TNNLS 2023) on Kvasir-SEG. Registered 13 Oct, row 29 of the sheet.
Everything about the paper, the code and how to run it is in [README.md](README.md).

History: v1 CondInst ([docs/v1-condinst-plan.md](docs/v1-condinst-plan.md)) was infeasible on one GPU. v2 picked ColonSegNet (IEEE Access 2021), dropped on 13 Oct because March 2021 is outside a strict 5-year window.

## Checklist

- [x] Topic registered
- [x] Code scaffold: model, memory, data, loss, metrics, train, evaluate, own-dataset tools (smoke-tested on CPU)
- [x] Synthetic own dataset (`dataset/custom/synthetic_leaf`, 60 samples)
- [x] Paper's Kvasir-SEG numbers copied into README §10 (Table II/IX); split confirmed as 880 / 120 (Table I)
- [ ] Read the paper's method section yourself (§III) so you can explain it in the viva
- [x] First full run, 256×256, `--memory-aug aligned` (laptop, 19 Oct): only 0.684 from the official Otsu start; the model copies its memory (README §5.4)
- [x] Final run, 256×256, `--memory-aug official` (laptop, 19 Oct): **Dice 0.842** (paper protocol, Otsu start, 10 rounds), **0.900** from an empty start; paper 0.880
- [x] Kaggle offload set up (`kaggle/offload.sh`, private datasets for code and data; no GitHub token needed)
- [ ] 512×512 / 100 epochs: aligned version running on Kaggle P100; official version to push when a Kaggle slot frees
- [x] Evaluate with 10 refinement rounds; memory probe (`src/memory_probe.py`)
- [ ] Ablation without feedback (`--no-feedback`, Kaggle T4, running)
- [x] Synthetic leaf transfer from the final model: Dice 0.474 → 0.984 after fine-tuning
- [ ] Own photos: 40–60 leaf-spot photos, Labelme, convert, fine-tune (needs you)
- [x] Results table (README §10) + figures
- [x] PPT: 14 slides, `presentation/FANet_ChaitanyaShinde_231070066.pptx`, built by `node presentation/build_deck.js` from the result CSVs
- [ ] Rehearse: walk through the code and the deck, viva answers (README §12). By Sat 31 Oct

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
