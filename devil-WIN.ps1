
# Set non-nested variables
$ZIP_URL = "https://github.com/Mephist0phel3s/Devil-Diffusion/archive/refs/tags/Devil-Diffusion-v2.0.4.1.zip"
$ZIP_FILE = "Devil-Diffusion-v2.0.4.1.zip"



$VENV = "$SrcRoot\venv"
$SOURCE_DATE_EPOCH = (Get-Date -UFormat %s)
$env:VARIANT = $variant

Invoke-WebRequest -Uri $ZIP_URL -OutFile $ZIP_FILE
Expand-Archive -Path $ZIP_FILE -DestinationPath (Get-Location)
Rename-Item -Path "Devil-Diffusion-Devil-Diffusion-v2.0.4.1" -NewName "Devil-Diffusion-v2.0.4.1"
Set-Location -Path "Devil-Diffusion-v2.0.4.1"
$GitRoot = Get-Location
$SrcRoot = "$GitRoot\src"
$DataDir = "$GitRoot\data"
$models = "$DataDir\models"
$TMP = "$DataDir\tmp"
$nodes = "$GitRoot\data\custom_nodes"

# If the -variant flag is set, force the variant
if ($variant -ne $null) {
    Write-Host "Forcing variant: $variant"
    $env:VARIANT = $variant
} else {
    $env:VARIANT = $null
}

# Function to check if Git is installed
function Check-Git {
    try {
        # Check if Git is available
        git --version
        return $true
    } catch {
        return $false
    }
}


# Function to check if Git LFS is installed
function Check-GitLFS {
    try {
        # Check if Git LFS is available
        git lfs version
        return $true
    } catch {
        return $false
    }
}

# If Git is not installed, download and install it along with Git LFS
if (-not (Check-Git)) {
    Write-Host "Git is not installed. Installing Git along with Git LFS..."

    # Get latest download URL for git-for-windows 64-bit exe
    $git_url = "https://api.github.com/repos/git-for-windows/git/releases/latest"
    $asset = Invoke-RestMethod -Method Get -Uri $git_url | % assets | where name -like "*64-bit.exe"

    # Download installer
    $installer = "$env:temp\$($asset.name)"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer

    # Run installer
    $git_install_inf = "<install inf file>"
    $install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF=""$git_install_inf"""
    Start-Process -FilePath $installer -ArgumentList $install_args -Wait

    # Install Git LFS after installing Git
    Write-Host "Installing Git LFS..."
    Start-Process -FilePath "git" -ArgumentList "lfs install" -Wait
} else {
    Write-Host "Git is already installed. Proceeding with the next steps."

    # If Git LFS is not installed, install it
    if (-not (Check-GitLFS)) {
        Write-Host "Git LFS is not installed. Installing Git LFS..."
        Start-Process -FilePath "git" -ArgumentList "lfs install" -Wait
    } else {
        Write-Host "Git LFS is already installed."
    }
}

# Function to check if Python 3.12 is installed
function Check-Python {
    try {
        # Check if Python 3.12 is installed
        $pythonVersion = python --version
        if ($pythonVersion -match "Python 3.12") {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# If Python 3.12 is not installed, use the provided installer
if (-not (Check-Python)) {
    Write-Host "Python 3.12 is not installed. Installing Python 3.12..."

    # Ensure the Python installer is available in $GitRoot
    $pythonInstallerPath = "$GitRoot\python-3.12.8.exe"
    if (Test-Path -Path $pythonInstallerPath) {
        # Run the Python installer from $GitRoot
        Start-Process -FilePath $pythonInstallerPath -ArgumentList "/passive", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait
    } else {
        Write-Host "Python installer not found in $GitRoot. Please ensure python-3.12.8.exe is present."
        exit 1
    }
} else {
    Write-Host "Python 3.12 is already installed. Proceeding with the next steps."
}

# Check if it's the first run
if (-not (Test-Path -Path "$GitRoot\src\devil_scripts\FIRSTRUN.flag")) {
    New-Item -Path "$GitRoot\src\devil_scripts\FIRSTRUN.flag" -ItemType File
    Write-Host "First time execution detected. Standby comrade...."
    Start-Sleep -Seconds 3
    Copy-Item -Recurse "$GitRoot\src\models" "$GitRoot\data\"
    Copy-Item -Recurse "$GitRoot\src\input" "$GitRoot\data\"
    Copy-Item -Recurse "$GitRoot\src\output" "$GitRoot\data\"
    Copy-Item -Recurse "$GitRoot\src\temp" "$GitRoot\data\"
    Copy-Item -Recurse "$GitRoot\src\custom_nodes" "$GitRoot\data\"
    Set-Location $GitRoot
}

# Set the variant based on GPU
function Set-Variant {
    # Check for GPU and set the variant
    $gpuVendor = Get-WmiObject Win32_VideoController | Select-Object -ExpandProperty Description
    if ($gpuVendor -match "NVIDIA") {
        $env:VARIANT = "CUDA"
    } elseif ($gpuVendor -match "AMD") {
        $env:VARIANT = "ROCM"
    } else {
        Write-Host "No discrete GPU detected, using default CPU variant."
        $env:VARIANT = "CPU"
    }
}

Set-Variant

# Install necessary packages and run main.py
cd $GitRoot\src
if ($env:VARIANT -eq "ROCM") {
    Write-Host "Installing ROCM-specific dependencies..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2.4
    pip install -r requirements.txt
    pip install open-clip-torch
    Write-Host "Thank you for using Devil-Diffusion. Starting main.py..."
    python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --use-pytorch-cross-attention --cpu-vae --disable-xformers
} elseif ($env:VARIANT -eq "CUDA") {
    Write-Host "Installing CUDA-specific dependencies..."
    Set-Location $SrcRoot
    pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu126
    pip install -r requirements.txt
    pip install open-clip-torch
    Write-Host "Thank you for using Devil-Diffusion. Starting main.py..."
    python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --use-pytorch-cross-attention --cuda-malloc
} else {
    Set-Location $SrcRoot
    Write-Host "Running for CPU variant..."
    pip install -r requirements.txt
    python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --cpu
}

# Final message

Write-Host "Thank you for using Devil-Diffusion. Starting main.py..."
