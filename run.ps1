param(
  [string]$VenvPath = ".venv"
)

$ErrorActionPreference = "Stop"

$activate = Join-Path $VenvPath "Scripts\Activate.ps1"
if (-not (Test-Path $activate)) {
  throw "Venv not found. Run setup.ps1 first."
}
. $activate

# Open the notebook directly
python -m jupyter lab "sam_geo_multi_prompt_merge.ipynb"
