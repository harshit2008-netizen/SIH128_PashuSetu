"""Write parity fixtures for the phone's LSD model (spec 11.4).

Run from ml/ (needs the TensorFlow extra, installed with `uv sync --extra verify`):
    uv run --extra verify python src/verify_tflite.py --n 5

Picks a few photos from the untouched test split, runs them through the exact
TensorFlow pipeline train.py used (decode -> central square -> resize -> TFLite),
and writes what the phone must reproduce:
- mobile/test/fixtures/parity/<name>.<ext>        the photo itself (CC0 dataset)
- mobile/test/fixtures/parity/<name>.decoded.png  TensorFlow's decoded pixels (lossless), to test the resize alone
- mobile/test/fixtures/parity/<name>.tensor.png   the 224x224 model input, rounded to bytes
- mobile/test/fixtures/parity_fixtures.json       expected probabilities per photo
- mobile/integration_test/parity_fixtures.g.dart  the same, embedded for the on-phone test
The host test checks the Dart preprocessing against the .tensor.png files; the
on-phone test runs the real model and checks each probability within 0.02.
"""

import argparse
import base64
import csv
import hashlib
import json
import random
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ML = Path(__file__).resolve().parents[1]
REPO = ML.parent
sys.path.insert(0, str(ML / "kaggle" / "lsd_image_classifier"))
import train  # noqa: E402

DATA = ML / "data" / "raw" / "lsd"
MANIFEST = ML / "artifacts" / "lsd_v1" / "split_manifest.csv"
FIXTURES = REPO / "mobile" / "test" / "fixtures"
DART_OUT = REPO / "mobile" / "integration_test" / "parity_fixtures.g.dart"
MAX_BYTES = 60_000  # keeps the embedded Dart file small


def local_path(manifest_path: str) -> Path:
    """Kaggle mounts the dataset under /kaggle/input/...; locally it is ml/data/raw/lsd."""
    return DATA / manifest_path[manifest_path.index("Cows datasets"):]


def pick(n: int, seed: int) -> list[dict]:
    """Test-split photos, both labels, including one landscape and one smaller than
    the model input, so the crop and the upscale paths are both exercised."""
    rows = [r for r in csv.DictReader(MANIFEST.open(encoding="utf-8")) if r["split"] == "test"]
    rng = random.Random(seed)
    rng.shuffle(rows)
    candidates = []
    for row in rows:
        path = local_path(row["path"])
        if path.exists() and path.stat().st_size <= MAX_BYTES:
            with Image.open(path) as image:
                candidates.append({**row, "local": path, "size": image.size})
    chosen = []

    def take(test):
        match = next((c for c in candidates if test(c) and c not in chosen), None)
        if match:
            chosen.append(match)

    take(lambda c: c["label"] == "lsd" and c["size"][0] > c["size"][1])       # landscape
    take(lambda c: c["label"] == "healthy" and min(c["size"]) < train.IMAGE_SIZE)  # needs upscaling
    while len(chosen) < n:
        label = "lsd" if sum(c["label"] == "lsd" for c in chosen) < (n + 1) // 2 else "healthy"
        before = len(chosen)
        take(lambda c, label=label: c["label"] == label)
        if len(chosen) == before:
            break
    return chosen


def reference(tflite_path: Path, photo: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """(decoded pixels, model input 224x224x3 float32, output probabilities) exactly as train.py evaluated."""
    import tensorflow as tf

    image = tf.io.decode_image(tf.io.read_file(str(photo)), channels=3, expand_animations=False)
    tensor = train.center_square(image).numpy().astype(np.float32)
    interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
    interpreter.allocate_tensors()
    interpreter.set_tensor(interpreter.get_input_details()[0]["index"], tensor[None])
    interpreter.invoke()
    return image.numpy(), tensor, interpreter.get_tensor(interpreter.get_output_details()[0]["index"])[0]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default=str(REPO / "mobile" / "assets" / "models" / "lsd_classifier.tflite"))
    parser.add_argument("--n", type=int, default=5)
    parser.add_argument("--seed", type=int, default=train.SEED)
    args = parser.parse_args()
    model = Path(args.model)

    out_dir = FIXTURES / "parity"
    shutil.rmtree(out_dir, ignore_errors=True)
    out_dir.mkdir(parents=True)
    fixtures = []
    for index, row in enumerate(pick(args.n, args.seed), start=1):
        name = f"{row['label']}_{index}"
        photo = out_dir / f"{name}{row['local'].suffix.lower()}"
        shutil.copyfile(row["local"], photo)
        decoded, tensor, probs = reference(model, photo)
        Image.fromarray(decoded).save(out_dir / f"{name}.decoded.png")
        Image.fromarray(np.clip(np.rint(tensor), 0, 255).astype(np.uint8)).save(out_dir / f"{name}.tensor.png")
        fixtures.append({"file": f"parity/{photo.name}", "tensor_png": f"parity/{name}.tensor.png", "decoded_png": f"parity/{name}.decoded.png",
                         "label": row["label"], "source": row["path"][row["path"].index("Cows datasets"):],
                         "width": row["size"][0], "height": row["size"][1],
                         "expected": {label: round(float(p), 6) for label, p in zip(train.LABELS, probs, strict=True)}})
        print(f"{photo.name}: {row['size'][0]}x{row['size'][1]} -> {fixtures[-1]['expected']}")

    document = {"model_sha256": hashlib.sha256(model.read_bytes()).hexdigest(), "labels": train.LABELS,
                "tolerance": 0.02, "fixtures": fixtures}
    (FIXTURES / "parity_fixtures.json").write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")

    lines = ["// GENERATED by ml/src/verify_tflite.py. Do not edit by hand.",
             "// Photos from the CC0 CowHealth-6K test split, with the probabilities the",
             "// TensorFlow reference pipeline gives. The on-phone parity test uses these.",
             "",
             f"const parityModelSha256 = '{document['model_sha256']}';",
             "",
             "const parityFixtures = <({String name, String base64, double lsd, double healthy})>["]
    for fixture in fixtures:
        encoded = base64.b64encode((FIXTURES / fixture["file"]).read_bytes()).decode()
        lines.append(f"  (name: '{Path(fixture['file']).name}', lsd: {fixture['expected']['lsd']}, "
                     f"healthy: {fixture['expected']['healthy']},")
        lines.append(f"   base64: '{encoded}'),")
    lines.append("];")
    DART_OUT.parent.mkdir(exist_ok=True)
    DART_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print(f"Wrote {len(fixtures)} fixtures to {FIXTURES} and {DART_OUT}")


if __name__ == "__main__":
    main()
