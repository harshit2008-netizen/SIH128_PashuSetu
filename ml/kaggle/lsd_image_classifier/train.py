"""Train the LSD photo classifier (spec 11.3) and export it for the phone.

Runs on a Kaggle GPU (pushed with `kaggle kernels push`), on Colab, or on a
laptop CPU:
    python train.py --data-dir /kaggle/input --out-dir /kaggle/working
    python train.py --data-dir ../../data/raw/lsd --out-dir ../../artifacts/local --epochs-stage1 5 --epochs-stage2 5

Steps: find class folders -> drop broken files -> remove near-duplicates ->
group-aware 70/15/15 split -> MobileNetV3Small fine-tune in two stages ->
test metrics -> TFLite export -> re-check the TFLite model -> write outputs.

Only numpy, Pillow and scipy are imported at the top, so `ml/src/inspect_dataset.py`
can reuse the folder mapping and duplicate logic on a laptop without TensorFlow.
TensorFlow is imported inside the training functions.
"""

import argparse
import csv
import json
import os
import random
import re
from collections import Counter, defaultdict
from datetime import UTC, datetime
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.fft import dctn

LABELS = ["healthy", "lsd"]  # model output order: index 1 is LSD
IMAGE_SIZE = 224
BATCH_SIZE = 32
SEED = 42
UNCLEAR_THRESHOLD = 0.60  # below this top probability the app says "photo unclear"

# Folder name -> label. Anything else (foot-and-mouth, mastitis, ...) is ignored,
# because this model only answers "lumps of LSD or healthy skin".
CLASS_PATTERNS = [(re.compile(r"lump", re.I), "lsd"), (re.compile(r"health|normal", re.I), "healthy")]
# Folders inside another disease's folder (e.g. Mastitis/normal teats) are not skin photos: skip them.
OTHER_DISEASE = re.compile(r"foot.?(and.?)?mouth|fmd|mastitis|pox|ringworm|dermatophil", re.I)
IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

# Perceptual-hash distances (out of 64 bits).
DUPLICATE_DISTANCE = 4   # same photo (resized, recompressed, lightly edited): keep one
GROUP_DISTANCE = 10      # very similar photos (crops, flips of one scene): keep in the same split


# ---------- data discovery ----------

def label_for_folder(relative: Path) -> str | None:
    if any(OTHER_DISEASE.search(part) for part in relative.parts):
        return None
    for pattern, label in CLASS_PATTERNS:
        if pattern.search(relative.name):
            return label
    return None


def find_images(data_dir: Path) -> tuple[list[dict], list[str]]:
    """Every image under a folder whose name maps to a label, plus notes on what was skipped."""
    items, notes = [], []
    for folder in sorted(p for p in data_dir.rglob("*") if p.is_dir()):
        files = [f for f in sorted(folder.iterdir()) if f.suffix.lower() in IMAGE_SUFFIXES]
        if not files:
            continue
        label = label_for_folder(folder.relative_to(data_dir))
        if label is None:
            notes.append(f"ignored folder '{folder.relative_to(data_dir)}' ({len(files)} images): not LSD or healthy")
            continue
        for f in files:
            if OTHER_DISEASE.search(f.name):
                notes.append(f"dropped '{f.relative_to(data_dir)}': file name names another disease")
                continue
            items.append({"path": f, "label": label, "source": folder.relative_to(data_dir).as_posix()})
    found = {i["label"] for i in items}
    if found != set(LABELS):
        raise SystemExit(f"Expected folders for {LABELS}, found {sorted(found)} under {data_dir}. Check CLASS_PATTERNS.")
    return items, notes


# ---------- perceptual hash + duplicates ----------

def phash(image: Image.Image) -> int:
    """64-bit DCT hash: low frequencies of a 32x32 grey image compared with their median."""
    grey = np.asarray(image.convert("L").resize((32, 32), Image.Resampling.LANCZOS), dtype=np.float64)
    low = dctn(grey, norm="ortho")[:8, :8].flatten()
    bits = low[1:] > np.median(low[1:])  # skip the DC term, it is just brightness
    return int("".join("1" if b else "0" for b in bits), 2)


def hash_images(items: list[dict]) -> tuple[list[dict], list[dict]]:
    """Adds hash and size to each readable image; returns (ok, broken)."""
    ok, broken = [], []
    for item in items:
        try:
            with Image.open(item["path"]) as image:
                image.load()
                item["size"] = image.size
                item["hash"] = phash(image)
            ok.append(item)
        except Exception as error:  # a broken file must not stop the run
            broken.append({**item, "error": str(error)[:80]})
    return ok, broken


def _pairs_within(hashes: np.ndarray, max_distance: int) -> list[tuple[int, int]]:
    """Index pairs whose hashes differ in at most max_distance bits."""
    bits = np.unpackbits(hashes.astype(">u8").view(np.uint8).reshape(-1, 8), axis=1).astype(np.uint8)
    pairs = []
    for i in range(len(bits) - 1):
        distance = (bits[i + 1:] != bits[i]).sum(axis=1)
        pairs.extend((i, i + 1 + j) for j in np.flatnonzero(distance <= max_distance))
    return pairs


def _components(n: int, pairs: list[tuple[int, int]]) -> list[int]:
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for a, b in pairs:
        parent[find(a)] = find(b)
    return [find(i) for i in range(n)]


def dedupe_and_group(items: list[dict]) -> tuple[list[dict], dict]:
    """Keep one image per duplicate set, drop sets whose copies disagree on the label,
    and give each kept image a group id for the split."""
    hashes = np.array([i["hash"] for i in items], dtype=np.uint64)
    dup_root = _components(len(items), _pairs_within(hashes, DUPLICATE_DISTANCE))
    sets = defaultdict(list)
    for index, root in enumerate(dup_root):
        sets[root].append(index)
    kept, conflicts, removed = [], 0, 0
    for members in sets.values():
        labels = {items[m]["label"] for m in members}
        if len(labels) > 1:  # the same photo is called LSD in one folder and healthy in another
            conflicts += len(members)
            continue
        kept.append(items[min(members, key=lambda m: str(items[m]["path"]))])
        removed += len(members) - 1
    kept_hashes = np.array([i["hash"] for i in kept], dtype=np.uint64)
    for item, group in zip(kept, _components(len(kept), _pairs_within(kept_hashes, GROUP_DISTANCE)), strict=True):
        item["group"] = group
    stats = {"duplicates_removed": removed, "conflicting_label_images_dropped": conflicts,
             "groups": len({i["group"] for i in kept})}
    return kept, stats


def split_groups(items: list[dict], seed: int = SEED) -> None:
    """70/15/15 per label, whole groups at a time, so near-copies never straddle splits."""
    rng = random.Random(seed)
    for label in LABELS:
        groups = defaultdict(list)
        for item in items:
            if item["label"] == label:
                groups[item["group"]].append(item)
        order = list(groups.values())
        rng.shuffle(order)
        total = sum(len(g) for g in order)
        filled = Counter()
        targets = {"test": 0.15 * total, "val": 0.15 * total}
        for group in order:
            # fill test, then val; everything else trains
            split = next((s for s in ("test", "val") if filled[s] + len(group) / 2 <= targets[s]), "train")
            filled[split] += len(group)
            for item in group:
                item["split"] = split


# ---------- training (TensorFlow from here on) ----------

def center_square(image):
    """Crop the central square, then resize to 224x224 (float32, 0-255).
    The sources differ in shape (640x640 squares vs 275x183 landscapes); squashing
    only some of them would give the model a shortcut. The phone does the same crop."""
    import tensorflow as tf

    shape = tf.shape(image)
    side = tf.minimum(shape[0], shape[1])
    image = tf.image.crop_to_bounding_box(image, (shape[0] - side) // 2, (shape[1] - side) // 2, side, side)
    return tf.image.resize(image, (IMAGE_SIZE, IMAGE_SIZE))


def make_dataset(items, training: bool):
    import tensorflow as tf

    paths = [str(i["path"]) for i in items]
    labels = [LABELS.index(i["label"]) for i in items]

    def load(path, label):
        data = tf.io.read_file(path)
        image = tf.io.decode_image(data, channels=3, expand_animations=False)
        return center_square(image), label

    ds = tf.data.Dataset.from_tensor_slices((paths, labels))
    if training:
        ds = ds.shuffle(len(paths), seed=SEED, reshuffle_each_iteration=True)
    return ds.map(load, num_parallel_calls=tf.data.AUTOTUNE).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)


def build_model(arch: str):
    import tensorflow as tf
    from tensorflow import keras

    augment = keras.Sequential([
        keras.layers.RandomFlip("horizontal"),
        keras.layers.RandomRotation(15 / 360),
        keras.layers.RandomZoom(0.1),
        keras.layers.RandomBrightness(0.2, value_range=(0, 255)),
        keras.layers.RandomContrast(0.2),
    ], name="augment")  # only active while training; a no-op in the exported model
    if arch == "mobilenet_v3_small":
        base = keras.applications.MobileNetV3Small(include_top=False, weights="imagenet", include_preprocessing=True,
                                                  input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3))
    else:
        base = keras.applications.EfficientNetB0(include_top=False, weights="imagenet",
                                                input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3))  # rescales inside too
    inputs = keras.Input((IMAGE_SIZE, IMAGE_SIZE, 3), dtype=tf.float32)
    x = augment(inputs)
    x = base(x, training=False)  # keeps BatchNorm in inference mode even when unfrozen
    x = keras.layers.GlobalAveragePooling2D()(x)
    x = keras.layers.Dropout(0.2)(x)
    outputs = keras.layers.Dense(len(LABELS), activation="softmax")(x)
    return keras.Model(inputs, outputs, name=f"lsd_{arch}"), base


def train(arch: str, train_ds, val_ds, class_weight, epochs1: int, epochs2: int):
    from tensorflow import keras

    model, base = build_model(arch)
    stop = keras.callbacks.EarlyStopping(monitor="val_loss", patience=3, restore_best_weights=True)
    base.trainable = False
    model.compile(keras.optimizers.Adam(1e-3), "sparse_categorical_crossentropy", metrics=["accuracy"])
    h1 = model.fit(train_ds, validation_data=val_ds, epochs=epochs1, class_weight=class_weight, callbacks=[stop], verbose=2)
    # Stage 2: unfreeze the top ~30 layers, keep BatchNorm frozen (small data would wreck its statistics).
    base.trainable = True
    for layer in base.layers[:-30]:
        layer.trainable = False
    for layer in base.layers:
        if isinstance(layer, keras.layers.BatchNormalization):
            layer.trainable = False
    model.compile(keras.optimizers.Adam(1e-5), "sparse_categorical_crossentropy", metrics=["accuracy"])
    h2 = model.fit(train_ds, validation_data=val_ds, epochs=epochs2, class_weight=class_weight, callbacks=[stop], verbose=2)
    history = {k: h1.history[k] + h2.history[k] for k in h1.history}
    return model, history


def predict(model, ds) -> np.ndarray:
    return model.predict(ds, verbose=0)


def metrics_for(y_true: np.ndarray, probs: np.ndarray) -> dict:
    from sklearn.metrics import accuracy_score, confusion_matrix, precision_recall_fscore_support, roc_auc_score

    y_pred = probs.argmax(axis=1)
    precision, recall, f1, _ = precision_recall_fscore_support(y_true, y_pred, labels=[1], average=None, zero_division=0)
    return {
        "accuracy": round(float(accuracy_score(y_true, y_pred)), 4),
        "precision_lsd": round(float(precision[0]), 4),
        "recall_lsd": round(float(recall[0]), 4),
        "f1_lsd": round(float(f1[0]), 4),
        "roc_auc": round(float(roc_auc_score(y_true, probs[:, 1])), 4),
        "confusion_matrix": confusion_matrix(y_true, y_pred, labels=[0, 1]).tolist(),  # rows true, cols predicted
        "n": int(len(y_true)),
    }


def by_source_accuracy(test_items, probs: np.ndarray) -> dict:
    """Accuracy per source folder: a big gap between folders hints the model learned the source."""
    hits = defaultdict(list)
    for item, p in zip(test_items, probs, strict=True):
        hits[item["source"]].append(LABELS[int(p.argmax())] == item["label"])
    return {source: {"n": len(h), "accuracy": round(sum(h) / len(h), 4)} for source, h in sorted(hits.items())}


# Smallest first. Each is kept only if it stays within 1 point of the Keras model on the test split.
TFLITE_OPTIONS = ["dynamic_range_int8", "float16", "float32"]


def export_tflite(model, path: Path, option: str) -> None:
    """A concrete function with a fixed [1,224,224,3] float input converts reliably with Keras 3."""
    import tensorflow as tf

    @tf.function(input_signature=[tf.TensorSpec([1, IMAGE_SIZE, IMAGE_SIZE, 3], tf.float32)])
    def serve(x):
        return model(x, training=False)

    converter = tf.lite.TFLiteConverter.from_concrete_functions([serve.get_concrete_function()], model)
    if option != "float32":
        converter.optimizations = [tf.lite.Optimize.DEFAULT]  # float input either way
    if option == "float16":
        converter.target_spec.supported_types = [tf.float16]
    path.write_bytes(converter.convert())


def tflite_probs(path: Path, test_items) -> np.ndarray:
    import tensorflow as tf

    interpreter = tf.lite.Interpreter(model_path=str(path))
    interpreter.allocate_tensors()
    inp, out = interpreter.get_input_details()[0], interpreter.get_output_details()[0]
    rows = []
    for images, _ in make_dataset(test_items, training=False).unbatch().batch(1):
        interpreter.set_tensor(inp["index"], images.numpy().astype(np.float32))
        interpreter.invoke()
        rows.append(interpreter.get_tensor(out["index"])[0])
    return np.array(rows)


def save_plots(out: Path, cm: list, test_items, probs: np.ndarray) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(4, 4))
    ax.imshow(cm, cmap="Blues")
    for (r, c), v in np.ndenumerate(np.array(cm)):
        ax.text(c, r, str(v), ha="center", va="center", fontsize=14)
    ax.set_xticks([0, 1], LABELS)
    ax.set_yticks([0, 1], LABELS)
    ax.set_xlabel("predicted")
    ax.set_ylabel("true")
    ax.set_title("Test split")
    fig.tight_layout()
    fig.savefig(out / "confusion_matrix.png", dpi=120)
    plt.close(fig)

    wrong = [(i, p) for i, p in zip(test_items, probs, strict=True) if LABELS[int(p.argmax())] != i["label"]][:24]
    cols = 6
    rows = max(1, (len(wrong) + cols - 1) // cols)
    fig, axes = plt.subplots(rows, cols, figsize=(cols * 2.2, rows * 2.5), squeeze=False)
    for ax in axes.flat:
        ax.axis("off")
    for ax, (item, p) in zip(axes.flat, wrong, strict=False):
        ax.imshow(Image.open(item["path"]).convert("RGB").resize((160, 160)))
        ax.set_title(f"true {item['label']}\nLSD p={p[1]:.2f}", fontsize=8)
    fig.suptitle(f"Misclassified test images ({len(wrong)} shown)")
    fig.tight_layout()
    fig.savefig(out / "misclassified.png", dpi=110)
    plt.close(fig)


# ---------- main ----------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--data-dir", default="/kaggle/input")
    parser.add_argument("--out-dir", default="/kaggle/working")
    parser.add_argument("--epochs-stage1", type=int, default=8)
    parser.add_argument("--epochs-stage2", type=int, default=12)
    args = parser.parse_args()
    data_dir, out = Path(args.data_dir), Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    random.seed(SEED)
    np.random.seed(SEED)

    print("Input tree:")
    for folder in sorted(p for p in data_dir.rglob("*") if p.is_dir()):
        n = sum(1 for f in folder.iterdir() if f.is_file())
        if n:
            print(f"  {folder.relative_to(data_dir)}: {n} files -> {label_for_folder(folder.relative_to(data_dir)) or 'ignored'}")

    items, notes = find_images(data_dir)
    print("\n".join(notes[:40]) + (f"\n  ... {len(notes) - 40} more notes" if len(notes) > 40 else ""))
    items, broken = hash_images(items)
    items, dedupe = dedupe_and_group(items)
    split_groups(items)
    counts = {s: dict(Counter(i["label"] for i in items if i["split"] == s)) for s in ("train", "val", "test")}
    print(f"Broken files: {len(broken)}. Dedupe: {dedupe}. Split counts: {counts}")

    with open(out / "split_manifest.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["path", "label", "split", "group", "source"])
        for i in items:
            writer.writerow([i["path"].relative_to(data_dir).as_posix(), i["label"], i["split"], i["group"], i["source"]])

    import tensorflow as tf

    tf.keras.utils.set_random_seed(SEED)
    print("TensorFlow", tf.__version__, "GPUs:", tf.config.list_physical_devices("GPU"))
    by_split = {s: [i for i in items if i["split"] == s] for s in ("train", "val", "test")}
    train_ds, val_ds, test_ds = (make_dataset(by_split[s], training=(s == "train")) for s in ("train", "val", "test"))
    train_counts = Counter(i["label"] for i in by_split["train"])
    class_weight = {LABELS.index(k): len(by_split["train"]) / (len(LABELS) * v) for k, v in train_counts.items()}
    y_val = np.array([LABELS.index(i["label"]) for i in by_split["val"]])
    y_test = np.array([LABELS.index(i["label"]) for i in by_split["test"]])

    candidates = {}
    for arch in ("mobilenet_v3_small", "efficientnet_b0"):
        model, history = train(arch, train_ds, val_ds, class_weight, args.epochs_stage1, args.epochs_stage2)
        candidates[arch] = {"model": model, "history": history,
                            "val": metrics_for(y_val, predict(model, val_ds)),
                            "test": metrics_for(y_test, predict(model, test_ds))}
        print(arch, "val", candidates[arch]["val"], "test", candidates[arch]["test"])
        if arch == "mobilenet_v3_small" and candidates[arch]["test"]["f1_lsd"] >= 0.85:
            break  # good enough; the spec only tries EfficientNetB0 below 0.85
    chosen = max(candidates, key=lambda a: (candidates[a]["val"]["f1_lsd"], a == "mobilenet_v3_small"))  # chosen on validation
    model = candidates[chosen]["model"]
    test_probs = predict(model, test_ds)

    tflite_path = out / "lsd_classifier.tflite"
    tflite_tries = {}
    for option in TFLITE_OPTIONS:
        export_tflite(model, tflite_path, option)
        tflite_test = metrics_for(y_test, tflite_probs(tflite_path, by_split["test"]))
        gap = abs(tflite_test["accuracy"] - candidates[chosen]["test"]["accuracy"])
        tflite_tries[option] = {"accuracy": tflite_test["accuracy"], "gap": round(gap, 4), "bytes": tflite_path.stat().st_size}
        print(f"TFLite {option}: test accuracy {tflite_test['accuracy']} vs Keras "
              f"{candidates[chosen]['test']['accuracy']} (gap {gap:.4f}), {tflite_path.stat().st_size} bytes")
        if gap <= 0.01:
            tflite_option = option
            break
    else:
        tflite_path.unlink()
        raise SystemExit("No TFLite export stayed within 1 percentage point of the Keras model; not exporting.")

    model.save(out / "model.keras")
    (out / "lsd_labels.txt").write_text("\n".join(LABELS) + "\n", encoding="utf-8")
    save_plots(out, candidates[chosen]["test"]["confusion_matrix"], by_split["test"], test_probs)
    now = datetime.now(UTC).isoformat(timespec="seconds")
    metrics = {
        "model_version": "lsd_v1", "architecture": chosen, "created_at": now, "tensorflow": tf.__version__,
        "test": candidates[chosen]["test"], "val": candidates[chosen]["val"], "tflite_test": tflite_test,
        "tflite_export": {"chosen": tflite_option, "tries": tflite_tries},
        "candidates": {a: {"val": c["val"], "test": c["test"], "epochs": len(c["history"]["loss"])} for a, c in candidates.items()},
        "test_accuracy_by_source": by_source_accuracy(by_split["test"], test_probs),
        "counts": counts, "dedupe": dedupe, "broken_files": len(broken), "dropped_by_name": sum("dropped" in n for n in notes),
    }
    (out / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    card = {
        "model_version": "lsd_v1",
        "architecture": f"{chosen} (ImageNet weights) + global average pooling + dropout 0.2 + dense softmax",
        "input": {"shape": [1, IMAGE_SIZE, IMAGE_SIZE, 3], "dtype": "float32", "value_range": "0-255",
                  "preprocessing_inside_model": True, "resize": "central square crop, then resize to 224x224 (bilinear)"},
        "labels": LABELS,
        "dataset": {"name": "CowHealth-6K: Cow Disease Detection", "kaggle": "drtawfikrrahman/cowhealth-6k-cow-disease-detection",
                    "url": "https://www.kaggle.com/datasets/drtawfikrrahman/cowhealth-6k-cow-disease-detection",
                    "licence": "CC0-1.0", "folders_used": sorted({i["source"] for i in items})},
        "counts_after_dedupe": counts,
        "test_metrics": candidates[chosen]["test"],
        "tflite_test_metrics": tflite_test,
        "tflite_weights": tflite_option,
        "decision_threshold": UNCLEAR_THRESHOLD,
        "date": now,
        "known_limitations": [
            "Photos come from the internet and public repositories, not from field use in Maharashtra.",
            "Not validated by vets on new animals; test metrics are on held-out photos from the same sources.",
            "Healthy and LSD photos partly come from different sources, so the model may react to photo style, not only lumps.",
            "Only cattle/buffalo skin with or without LSD lumps. It says nothing about other diseases; a skin problem that is not LSD may be called LSD or healthy.",
            "A suspicion aid for triage, never a diagnosis. A vet or lab must confirm.",
        ],
    }
    (out / "lsd_model_card.json").write_text(json.dumps(card, indent=2), encoding="utf-8")
    print("Done:", json.dumps(metrics["test"]))


if __name__ == "__main__":
    os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
    main()
