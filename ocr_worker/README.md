# OCR worker

Local child process for the Study Overlay App. Flutter launches this worker as a
managed subprocess and speaks **JSON Lines** over **stdin/stdout**. Logs go to
**stderr** only. The worker never binds a non-loopback network interface.

## Launch (Flutter)

Packaged macOS builds ship a self-contained runtime under:

```text
Studee.app/Contents/Resources/ocr_runtime/python/bin/python3
Studee.app/Contents/Resources/ocr_runtime/paddlex_cache/
Studee.app/Contents/Resources/ocr_worker/main.py
```

End users do **not** need Homebrew, pip, or model downloads.

### Dev machine (repo checkout)

```text
ocr_worker/.venv/bin/python -u ocr_worker/main.py
```

Or via the helper:

```bash
./ocr_worker/run.sh
```

### One-time real OCR setup (developers only)

```bash
cd ocr_worker
./setup_real_ocr.sh
./warmup_models.sh   # downloads PaddleOCR-VL 1.6 into ~/.paddlex/
```

Bake that into a DMG:

```bash
./scripts/prepare_ocr_bundle.sh
./scripts/package_macos_dmg.sh
```

Slim DMG without OCR runtime: `SKIP_OCR_BUNDLE=1 ./scripts/package_macos_dmg.sh`.

Packaged weights live in `Resources/ocr_runtime/paddlex_cache` via
`PADDLE_PDX_CACHE_HOME`. Dev machines still use `~/.paddlex/official_models/`.

Optional faster VLM on Mac: `mlx_vlm.server --port 8111` + `OCR_WORKER_USE_MLX=1`
(not included in the CPU-only app bundle).

Force mock: `OCR_FORCE_MOCK=1` (Flutter) or `OCR_WORKER_FORCE_MOCK=1` (worker).

Flutter should:

1. Prefer bundled `ocr_runtime/python` and set `PADDLE_PDX_CACHE_HOME`.
2. Spawn with `PYTHONUNBUFFERED=1` (or `python -u`).
3. Write one request object per stdin line.
4. Read events until `completed` or `error`.
5. Cancel by writing a `cancel` request for the same `job_id`.

Working directory / `PYTHONPATH` should be `ocr_worker/` so local imports resolve.

## Model resolution

Models are **bundled in the DMG**:

```text
Contents/Resources/ocr_runtime/paddlex_cache/official_models/
  PaddleOCR-VL-1.6/
  PP-DocLayoutV3/
```

Dev stub path (Flutter assets → Application Data) remains:

```text
ApplicationData/models/paddleocr-vl-1.6/
```

Example request:

```json
{
  "protocol_version": 1,
  "job_id": "job_uuid",
  "action": "parse_document",
  "input_path": "/abs/path/source.pdf",
  "output_directory": "/abs/path/source_uuid/ocr",
  "pages": [1, 2],
  "language_hints": ["vi", "en"],
  "quality": "highest",
  "model_dir": "/abs/ApplicationData/models/paddleocr-vl-1.6",
  "force_ocr": false
}
```

`language_hints` default to `["vi", "en"]` (Vietnamese first). Diacritics must be
preserved end-to-end.

If PaddleOCR is not installed, the worker uses a **deterministic mock engine**
labeled `"mock": true`. Force mock with `OCR_WORKER_FORCE_MOCK=1`.

## Actions

| Action | Purpose |
|--------|---------|
| `parse_document` | PDF via PDFium: usable text layer → extract; else render 300–400 DPI → OCR |
| `parse_image` | Single image OCR |
| `cancel` | Cooperative cancel of the active `job_id` |

Optional `force_ocr`: `true` or a list of 1-based page numbers.

## Events (stdout)

```json
{"job_id":"…","type":"progress","page":2,"total_pages":10,"stage":"ocr"}
{"job_id":"…","type":"page_completed","page":2,"result_path":"page_0002.json"}
{"job_id":"…","type":"warning","page":3,"code":"LOW_CONFIDENCE","message":"…"}
{"job_id":"…","type":"completed"}
```
