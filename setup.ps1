param(
  [ValidateSet("auto","cpu","gpu")]
  [string]$Mode = "auto",

  # PyTorch wheel channel for GPU builds (examples: cu118, cu121, cu124, cu126, cu128)
  [string]$CudaChannel = "cu126",

  [string]$VenvPath = ".venv",

  [switch]$SkipJupyter
)

$ErrorActionPreference = "Stop"

function Resolve-PythonCmd {
  if (Get-Command py -ErrorAction SilentlyContinue) { return "py" }
  if (Get-Command python -ErrorAction SilentlyContinue) { return "python" }
  throw "Python not found. Install Python 3.10+ and ensure it is on PATH."
}

function Assert-PythonVersion($pyCmd) {
  $ver = & $pyCmd -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"
  $parts = $ver.Split(".") | ForEach-Object { [int]$_ }
  if ($parts[0] -lt 3 -or ($parts[0] -eq 3 -and $parts[1] -lt 10)) {
    throw "Python $ver detected. Required: Python 3.10+."
  }
}

function Detect-HasNvidiaGpu {
  $cmd = Get-Command nvidia-smi -ErrorAction SilentlyContinue
  if (-not $cmd) { return $false }
  try {
    & nvidia-smi | Out-Null
    return $true
  } catch {
    return $false
  }
}

$py = Resolve-PythonCmd
Assert-PythonVersion $py

# Decide mode if auto
if ($Mode -eq "auto") {
  if (Detect-HasNvidiaGpu) { $Mode = "gpu" } else { $Mode = "cpu" }
}
Write-Host "Mode: $Mode"

# Create venv if missing
if (-not (Test-Path $VenvPath)) {
  Write-Host "Creating venv at $VenvPath ..."
  if ($py -eq "py") {
    & py -3 -m venv $VenvPath
  } else {
    & python -m venv $VenvPath
  }
}

# Activate venv
$activate = Join-Path $VenvPath "Scripts\Activate.ps1"
if (-not (Test-Path $activate)) { throw "Activation script not found: $activate" }
. $activate

python -m pip install --upgrade pip setuptools wheel

# Install PyTorch (CPU/GPU)
if ($Mode -eq "cpu") {
  Write-Host "Installing PyTorch (CPU) ..."
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
} elseif ($Mode -eq "gpu") {
  Write-Host "Installing PyTorch (GPU, $CudaChannel) ..."
  pip install torch torchvision torchaudio --index-url ("https://download.pytorch.org/whl/" + $CudaChannel)
} else {
  throw "Invalid Mode: $Mode"
}

# Install project requirements
Write-Host "Installing requirements.txt ..."
pip install -r requirements.txt

if (-not $SkipJupyter) {
  Write-Host "Installing JupyterLab ..."
  pip install jupyterlab
}

# Quick verification
python - << 'PY'
import torch
print("torch:", torch.__version__)
print("cuda available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("gpu:", torch.cuda.get_device_name(0))
PY

Write-Host "Setup completed."
