# lsd_v1 review (human notes on the Kaggle run)

Numbers live in `lsd_metrics.json` and `lsd_model_card.json` (written by `train.py` on Kaggle, version 2 of
`harshitjain2008/pashusetu-lsd-classifier`). This file only records what we saw when checking them.

- **Model:** MobileNetV3Small passed the spec's LSD F1 bar on the first try, so EfficientNetB0 was not trained.
- **TFLite export:**
  - Dynamic-range int8 missed the 1-point parity rule by a small margin, so the export fell back to float16.
  - The float16 model gives exactly the same test predictions as the Keras model.
- **Folder overlap:**
  - `Healthycows 2` is entirely a near-copy of `Healthycows 1`, so all healthy photos come from one source after dedupe.
  - Most of `Lumpycows-1` is a copy of `Lumpycows-2`. Without dedupe these copies would have leaked into the test split.
- **Weakest source:** accuracy by source (`test_accuracy_by_source`) is lowest on `Lumpycows-1`, the small web photos.
  The model is less sure on LSD photos that do not look like the `Lumpycows-2` exports.
  This is the source-bias risk from the inspection, and it is visible in the numbers.
- **Mislabelled photos (`misclassified.png`):** some "lsd" photos are not LSD at all (a camel market, a treatment banner, a statue).
  The dataset has label noise, so a few "errors" are the model being right.
- **False LSD calls on healthy animals** are mostly wide farm scenes with several animals.
  The app should ask for a close photo of the skin, and treat the photo only as a supporting sign.
- **Not yet done:** tested on photos from the field in Maharashtra, or reviewed by a vet.
