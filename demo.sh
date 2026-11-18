#!/usr/bin/env bash
# Live inference demo for the lab exam. Runs from the repo root.
#
#   ./demo.sh polyp 4            4 random Kvasir-SEG test images (with the doctor's mask)
#   ./demo.sh leaf 4             4 random LDSD leaf test photos (model fine-tuned on my Roboflow labels)
#   ./demo.sh folder <dir> [polyp|leaf]   any images you bring, no ground truth
#   ./demo.sh test               all 120 Kvasir-SEG test images: reproduces Dice 0.842 (about 2 min on the GPU)
#
# Output: one strip per image in /tmp/fanet_demo/result/strips/, opened automatically:
#   image | ground truth (if any) | Otsu start | round 1 | round 2 | ... | round 10
set -euo pipefail
cd "$(dirname "$0")"
PY="${PY:-$HOME/.venvs/dlproject/bin/python}"
OUT=/tmp/fanet_demo
rm -rf "$OUT"; mkdir -p "$OUT"

ckpt_for() { [ "$1" = leaf ] && echo runs/roboflow_leaf_constlr/best.pt || echo runs/kvasir_official/best.pt; }

case "${1:-polyp}" in
  polyp|leaf)
    kind=$1; n=${2:-4}
    [ "$kind" = leaf ] && src=data/LDSD/data/data || src=data/Kvasir-SEG
    mini="$OUT/data"; mkdir -p "$mini"
    ln -s "$PWD/$src/images" "$mini/images"; ln -s "$PWD/$src/masks" "$mini/masks"
    shuf -n "$n" "$src/test.txt" > "$mini/test.txt"
    "$PY" -m src.evaluate --ckpt "$(ckpt_for "$kind")" --data "$mini" --split test \
          --iters 10 --strips "$n" --out "$OUT/result" ;;
  test)
    "$PY" -m src.evaluate --ckpt runs/kvasir_official/best.pt --data data/Kvasir-SEG --split test \
          --iters 10 --strips 6 --out "$OUT/result" ;;
  folder)
    "$PY" -m src.evaluate --ckpt "$(ckpt_for "${3:-polyp}")" --images "$2" --iters 10 --out "$OUT/result" ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac

echo; echo "Dice after each refinement round (only with ground truth):"
cut -d, -f1,3 "$OUT/result/results.csv" | column -t -s,
[ -n "${NO_OPEN:-}" ] || xdg-open "$OUT/result/strips" >/dev/null 2>&1 &
