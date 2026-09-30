# ml/ — LSD image model and data work

- `kaggle/lsd_image_classifier/` holds `train.py` and the Kaggle kernel metadata. It trains on a Kaggle GPU and exports TFLite (Phase 6).
- `src/` holds helper scripts: dataset inspection, dedupe/split, TFLite export and parity check.
- `data/` holds downloaded datasets. It is **gitignored**, so never commit raw data.
- `artifacts/` holds downloaded kernel outputs. It is gitignored, except the model card.
- `reports/` holds real metrics (`*.json`) and plots from actual training runs. These are committed.
- `DATA_SOURCES.md` lists every dataset with its URL, licence, size and use (Phase 6).

Rule: any accuracy number shown in the app or docs must be read from `reports/*.json`. Never type one in by hand.
The Kaggle token lives in `~/.kaggle/`. Never print it, copy it or commit it.

## How to train on Kaggle (repeat a run)

One-time setup:
1. Verify your phone on Kaggle, create an API token, and save it as `~/.kaggle/kaggle.json`.
2. Install the Kaggle tool with `uv tool install kaggle`.

Then, from the repo root in Git Bash:
```bash
export PYTHONUTF8=1                                   # Windows: the log download fails without it
kaggle datasets download -d drtawfikrrahman/cowhealth-6k-cow-disease-detection -p ml/data/raw/lsd --unzip
cd ml && uv run python src/inspect_dataset.py && cd ..   # writes reports/dataset_inspection.md
kaggle kernels push -p ml/kaggle/lsd_image_classifier --accelerator NvidiaTeslaT4
kaggle kernels status harshitjain2008/pashusetu-lsd-classifier      # repeat until COMPLETE (about 5 min)
kaggle kernels output harshitjain2008/pashusetu-lsd-classifier -p ml/artifacts/lsd_v1
cp ml/artifacts/lsd_v1/metrics.json ml/reports/lsd_metrics.json
cp ml/artifacts/lsd_v1/{lsd_model_card.json,confusion_matrix.png,misclassified.png} ml/reports/
cp ml/artifacts/lsd_v1/{lsd_classifier.tflite,lsd_labels.txt,lsd_model_card.json} mobile/assets/models/
```
If the status says ERROR, the reason is at the end of `ml/artifacts/lsd_v1/pashusetu-lsd-classifier.log`.
A new team member must change `id` in `kaggle/lsd_image_classifier/kernel-metadata.json` to their own Kaggle username.
