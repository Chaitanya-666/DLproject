#!/usr/bin/env bash
# Offload a training run to a free Kaggle GPU, and fetch its results.
#
#   kaggle/offload.sh push   <name> <t4|p100> "<train args>" [eval rounds]
#   kaggle/offload.sh status <name>
#   kaggle/offload.sh pull   <name>          # -> runs/<name>/ (best.pt, log.csv, eval_test/)
#
# Kaggle allows 2 GPU batch sessions at once; a third push is refused.
#
# Example (the no-feedback ablation):
#   kaggle/offload.sh push kvasir-nofb t4 "--epochs 200 --batch 8 --no-feedback" 1
#
# What push does: uploads the current src/ as a new version of the private
# dataset <user>/fanet-scratch-code, then pushes a private script notebook
# (kaggle/run_template.py filled in) that trains on <user>/kvasir-seg-fanet-split
# (Kvasir-SEG with our exact train.txt / test.txt) and evaluates on the test split.
# Names may use letters, digits and dashes only (they become Kaggle URLs).
#
# Needs the Kaggle CLI logged in. Set KAGGLE to its path if it is not on PATH.
set -euo pipefail

KAGGLE=${KAGGLE:-$(command -v kaggle || echo ~/.venvs/agriagent/bin/kaggle)}
USER_NAME=$("$KAGGLE" config view | sed -n 's/^- username: //p')
REPO=$(cd "$(dirname "$0")/.." && pwd)
CODE_DATASET="$USER_NAME/fanet-scratch-code"
DATA_DATASET="$USER_NAME/kvasir-seg-fanet-split"

cmd=${1:-}; name=${2:-}
[[ -n "$cmd" && -n "$name" ]] || { sed -n '2,8p' "$0"; exit 1; }
[[ "$name" =~ ^[a-z0-9-]+$ ]] || { echo "name: lowercase letters, digits, dashes only"; exit 1; }
kernel="$USER_NAME/fanet-$name"

case "$cmd" in
push)
    gpu=${3:?give t4 or p100}; args=${4:?give the train arguments}; rounds=${5:-10}
    case "$gpu" in t4) acc=NvidiaTeslaT4 ;; p100) acc=NvidiaTeslaP100 ;; *) echo "gpu: t4 or p100"; exit 1 ;; esac
    tmp=$(mktemp -d)
    # 1. current code as a new dataset version
    mkdir "$tmp/code"
    (cd "$REPO" && zip -qr "$tmp/code/src.zip" src -x '*__pycache__*')
    printf '{"title": "FANet from scratch code", "id": "%s", "licenses": [{"name": "other"}]}\n' \
        "$CODE_DATASET" > "$tmp/code/dataset-metadata.json"
    "$KAGGLE" datasets version -p "$tmp/code" -m "offload $name" -q
    # 2. the notebook
    mkdir "$tmp/kernel"
    sed -e "s|__TRAIN_ARGS__|$args|" -e "s|__EVAL_ITERS__|$rounds|" -e "s|__RUN__|$name|" \
        "$REPO/kaggle/run_template.py" > "$tmp/kernel/run.py"
    cat > "$tmp/kernel/kernel-metadata.json" <<EOF
{"id": "$kernel", "title": "fanet-$name", "code_file": "run.py", "language": "python",
 "kernel_type": "script", "is_private": true, "enable_gpu": true, "enable_internet": false,
 "dataset_sources": ["$DATA_DATASET", "$CODE_DATASET"], "competition_sources": [], "kernel_sources": []}
EOF
    sleep 30   # give the new code version time to finish processing
    # The CLI exits 0 even when the push is refused (e.g. "Maximum batch GPU
    # session count of 2 reached"), so check its message instead.
    out=$("$KAGGLE" kernels push -p "$tmp/kernel" --accelerator "$acc" 2>&1); echo "$out"
    rm -rf "$tmp"
    if grep -qi "error" <<<"$out"; then echo "push FAILED"; exit 1; fi
    echo "running: https://www.kaggle.com/code/$kernel"
    ;;
status)
    "$KAGGLE" kernels status "$kernel"
    ;;
pull)
    tmp=$(mktemp -d)
    "$KAGGLE" kernels output "$kernel" -p "$tmp" -q
    mkdir -p "$REPO/runs"
    for run in "$tmp"/runs/*/; do          # usually one folder, named by the notebook's OUT
        run=$(basename "$run")
        rm -rf "$REPO/runs/$run"
        mv "$tmp/runs/$run" "$REPO/runs/$run"
        cp "$tmp"/*.log "$REPO/runs/$run/kaggle.log" 2>/dev/null || true
        echo "results in runs/$run:"; ls "$REPO/runs/$run"
    done
    rm -rf "$tmp"
    ;;
*)
    sed -n '2,8p' "$0"; exit 1 ;;
esac
