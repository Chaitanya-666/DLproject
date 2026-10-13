# Datasets

Large data is not committed (see `.gitignore`). Only `custom/` lives in git.

## Kvasir-SEG (the paper's dataset)

- Page: https://datasets.simula.no/kvasir-seg/
- Direct zip (about 46 MB): https://datasets.simula.no/downloads/kvasir-seg.zip
- Kaggle: search "Kvasir-SEG" under *Add Data*; several uploads exist. Any copy with `images/` and `masks/` folders of 1000 files each works.

```bash
mkdir -p data && cd data
wget https://datasets.simula.no/downloads/kvasir-seg.zip
unzip -q kvasir-seg.zip          # -> data/Kvasir-SEG/{images,masks,kavsir_bboxes.json}
cd .. && python -m src.split --data data/Kvasir-SEG     # writes train.txt (880) / test.txt (120)
```

On Kaggle the input folder is read-only, so copy it first:
`cp -r /kaggle/input/<name>/Kvasir-SEG /kaggle/working/` and then run the split there.

## custom/

Your own small dataset for the PPT. See the README's "Your own dataset" section.

```
custom/
  synthetic_leaf/   made by: python -m src.make_synthetic procedural --out dataset/custom/synthetic_leaf --n 60
  leaf/             your phone photos + Labelme masks (python -m src.labelme_to_masks ...)
```
