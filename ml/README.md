# ml/ — LSD image model and data work

- `kaggle/lsd_image_classifier/` holds `train.py` and the Kaggle kernel metadata. It trains on a Kaggle GPU and exports TFLite (Phase 6).
- `src/` holds helper scripts: dataset inspection, dedupe/split, TFLite export and parity check.
- `data/` holds downloaded datasets. It is **gitignored**, so never commit raw data.
- `artifacts/` holds downloaded kernel outputs. It is gitignored, except the model card.
- `reports/` holds real metrics (`*.json`) and plots from actual training runs. These are committed.
- `DATA_SOURCES.md` lists every dataset with its URL, licence, size and use (Phase 6).

Rule: any accuracy number shown in the app or docs must be read from `reports/*.json`. Never type one in by hand.
The Kaggle token lives in `~/.kaggle/`. Never print it, copy it or commit it.
