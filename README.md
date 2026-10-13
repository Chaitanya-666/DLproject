# DL Mini-Project: CNN Detection + Segmentation

Individual Deep Learning mini-project (B.Tech Computer Engineering, Sem VII, 2026–27).
Chaitanya Shinde, 231070066.

**Brief:** implement a recent (last 5 years) IEEE paper on object detection / segmentation with a CNN, from scratch, on the paper's own dataset, plus a small self-made dataset and a PPT. Photo of the brief: [`brief/finalProjectDeepLearning.jpeg`](brief/finalProjectDeepLearning.jpeg).

**Status (2026-10-12):** planning. Topic not registered yet.

- Primary candidate: Jha et al., *Real-Time Polyp Detection, Localization and Segmentation in Colonoscopy Using Deep Learning*, IEEE Access 9 (2021). ColonSegNet on Kvasir-SEG.
- Fallback: Tomar, Jha et al., *FANet*, IEEE TNNLS 34(11) (2023).

Full plan and timeline: [`PLAN.md`](PLAN.md). The earlier CondInst plan (dropped as infeasible) is kept in [`docs/v1-condinst-plan.md`](docs/v1-condinst-plan.md).

## Layout

| Path | Contents |
|---|---|
| `src/` | PyTorch code: `model.py`, `dataset.py`, `losses.py`, `metrics.py`, `train.py` |
| `notebooks/` | Kaggle training / evaluation notebooks |
| `dataset/` | Data download notes; `custom/` holds the self-made dataset (images, masks, write-up) |
| `papers/` | References to the papers (PDFs are not committed) |
| `presentation/` | Final PPT |
| `docs/` | Notes and earlier plans |
| `brief/` | The faculty brief |
