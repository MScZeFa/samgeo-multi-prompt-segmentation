# SamGeo Multi-Prompt Merge (Notebook)

Segment georeferenced RGB imagery with **multiple text prompts** (e.g. `house`, `garage`, `building`) and merge all detections into **one final mask + one vector layer**.

This repository ships a single, well-documented Jupyter Notebook that:
- runs **multi-prompt segmentation per tile** and unions the results
- stitches tiles back to a full-resolution mask
- exports:
  - `*_union_mask.tif` (GeoTIFF, 0/255)
  - `*_union.gpkg` (GeoPackage, layer `objects`)

---

## Requirements

- Windows 10/11
- **VS Code** (Python + Jupyter extensions)
- **Python 3.10+**
- Optional for GPU mode:
  - NVIDIA GPU + recent driver
  - CUDA-capable PyTorch build (installed by `setup.ps1`)

Notes:
- On first run, `SamGeo3` may download model weights from Hugging Face (internet required).

---

## Quickstart (PowerShell)

```powershell
# 1) Create venv + install dependencies (auto-detect GPU/CPU)
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Mode auto

# 2) Start Jupyter and open the notebook
powershell -ExecutionPolicy Bypass -File .\run.ps1
```

Then open **`sam_geo_multi_prompt_merge.ipynb`** and run cells top-to-bottom.

---

## GPU vs CPU

You can force the runtime mode during setup:

```powershell
# CPU-only (portable, slower)
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Mode cpu

# GPU (faster; default CUDA wheel channel can be changed)
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Mode gpu -CudaChannel cu126
```

Inside the notebook you can also control execution via:

```python
DEVICE_PREFERENCE = "auto"  # "auto" | "cpu" | "cuda"
```

---

## Notebook configuration

Edit these variables near the top:

- `IMAGE_PATH` – path to an **RGB GeoTIFF** (bands 1–3)
- `OUT_DIR` – output folder
- `PROMPTS_RAW` – comma-separated prompts, e.g. `building,house,garage`
- `TILE_SIZE`, `OVERLAP` – performance/quality trade-off
- `MIN_AREA_M2` – vector cleanup threshold (most meaningful with projected CRS)

The notebook normalizes prompts (German → English mapping and cleanup), so inputs like `Gebäude` become `building`.

---

## Outputs

In `OUT_DIR`:

- `*_union_mask.tif`  
  Binary mask (0/255), same georeferencing as the input image.

- `*_union.gpkg` (layer `objects`)  
  Polygons from the union mask. Attributes:
  - `id`
  - `area_m2` (most meaningful with projected CRS)
  - `perimeter_m`
  - `prompts` (the prompt set used)

---

## Troubleshooting

### 1) RasterIO / Fiona / GeoPandas install errors (Windows)
If pip wheels fail in your environment, use conda-forge instead:
```powershell
conda create -n samgeo python=3.11 -y
conda activate samgeo
conda install -c conda-forge rasterio geopandas fiona pyproj -y
pip install -r requirements.txt
```

### 2) GPU not used
- Ensure `nvidia-smi` works
- Re-run setup in GPU mode:
```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Mode gpu -CudaChannel cu126
```
- In the notebook set `DEVICE_PREFERENCE = "cuda"` (only if CUDA is actually available)

### 3) Very large images
Increase `TILE_SIZE` only if you have enough VRAM/RAM; otherwise lower it and/or increase `OVERLAP`.

---

## License

MIT (see `LICENSE`).
