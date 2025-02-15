function checkGit {
    try {
        # Check if Git is installed
        git --version
        $gitInstalled = $true
    } catch {
        $gitInstalled = $false
    }

    if (-not $gitInstalled) {
        Set-Location $tmp
        curl -L -o Git-2.48.1-64-bit.exe https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/Git-2.48.1-64-bit.exe
        $installerPath = %cd%"\Git-2.48.1-64-bit.exe"
        # Run the installer in silent mode with specified installation directory
        Start-Process -FilePath $installerPath -ArgumentList "/SILENT", "/NORESTART", "/DIR=C:\Program Files\Git" -Wait -NoNewWindow

        # Install Git LFS after installing Git
        Write-Host "Installing Git LFS..."
        Start-Process -FilePath "git" -ArgumentList "lfs install" -Wait
    } else {
        Write-Host "Git is already installed. Proceeding with the next steps."

        try {
            # Check if Git LFS is installed
            git lfs version
            Write-Host "Git LFS is already installed."
        } catch {
            Write-Host "Git LFS is not installed. Installing Git LFS..."
            Start-Process -FilePath "git" -ArgumentList "lfs install" -Wait
        }
    }
}
function checkPython {
    try {
        $pythonVersion = "python --version"
        if ($pythonVersion -match "Python 3.12") {
            Write-Host "Python 3.12 is already installed. Proceeding with the next steps."
        } else {
                Set-Location $GitRoot
                .\python-3.12.8.exe /passive InstallAllUsers=0 PrependPath=0 SimpleInstall=1 Include_test=0 -Wait
            }
        }
    }

    # Check if virtual environment exists, if not, create and activate it
    if (-not (Test-Path -Path $VENV)) {
        Write-Host "Virtual environment not found. Creating new virtual environment..."
        $SOURCE_DATE_EPOCH = (Get-Date -UFormat %s)
        python -m venv $VENV
        Set-Location -Path $VENV
        . .\Scripts\Activate.ps1
        $env:PYTHONPATH = (Get-Location).Path + "\" + $VENV + "\" + $pkgs.python312Full.sitePackages + "\" + ":" + $env:PYTHONPATH
        Set-Location -Path $GitRoot
    } else {
        Write-Host "Virtual environment already exists. Activating..."
        Set-Location -Path $VENV
        . .\Scripts\Activate.ps1
        Set-Location -Path $GitRoot
    }
}

function cloneDevil {
    $homeDir = [System.Environment]::GetFolderPath('UserProfile')
    Set-Location -Path $homeDir

    $GitRoot = "$homeDir\Devil-Diffusion"
    $SrcRoot = "$GitRoot\src"

    if (-not (Test-Path -Path $GitRoot)) {

        Write-Host "Cloning Devil-Diffusion repository..."
        git clone https://github.com/Mephist0phel3s/Devil-Diffusion
        $GitRoot = "$homeDir\Devil-Diffusion"
        $SrcRoot = "$GitRoot\src"
        Set-Location -Path $GitRoot
    } else {
        Write-Host "Repository exists. Pulling the latest changes..."
        Set-Location -Path $GitRoot
        git pull
    }
}
function setVariant {
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
function runDevil {
        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Manager
            git pull
        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Image-Saver
            git pull
        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Easy-Use
            git pull
        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Crystools
            git pull
        Set-Location $nodes\ComfyUI_mittimiLoadText
            git pull

        if ($env:VARIANT -eq "ROCM") {
            Set-Location $SrcRoot
            Write-Host "Thank you for using Devil-Diffusion."
            python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --use-pytorch-cross-attention --cpu-vae --disable-xformers
        } elseif ($env:VARIANT -eq "CUDA") {
            Set-Location $SrcRoot
            Write-Host "Thank you for using Devil-Diffusion."
            python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --use-pytorch-cross-attention --cpu-vae --cuda-malloc
        }
}
function firstBuild {
    Write-Host "First time execution detected. Standby comrade...."
    Start-Sleep -Seconds 3

    # Copy necessary files
#    Copy-Item -Recurse $GitRoot\src\models $DataDir\models
#    Copy-Item -Recurse $GitRoot\src\input $DataDir\input
#    Copy-Item -Recurse $GitRoot\src\output $DataDir\output
#    Copy-Item -Recurse $GitRoot\src\temp $DataDir\temp
#    Copy-Item -Recurse $GitRoot\src\custom_nodes $DataDir\custom_nodes

    $nodes = "$GitRoot\data\custom_nodes"
    $DataDir = "$GitRoot\data"
    $models = "$DataDir\models"
    $TMP = "$DataDir\tmp"
    $tmp = "$GitRoot\data\tmp"
    $VENV = "$SrcRoot\venv"
    if ($env:VARIANT -eq "ROCM") {
            Set-Location $SrcRoot
            Write-Host "Installing ROCM-specific dependencies..."
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2.4
            pip install -r requirements.txt
            pip install open-clip-torch
            Set-Location $GitRoot
}   elseif ($env:VARIANT -eq "CUDA") {
            Write-Host "Installing CUDA-specific dependencies..."
            Set-Location $SrcRoot
            pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu126
            pip install -r requirements.txt
            pip install open-clip-torch
            Set-Location $GitRoot
}   else {
            Set-Location $SrcRoot
            pip install -r requirements.txt
            Set-Location $GitRoot
}
    Set-Location $nodes

    git clone https://github.com/ltdrdata/ComfyUI-Manager

    if ($env:VARIANT -eq "ROCM") {
            Set-Location $nodes
            git clone -b AMD https://github.com/crystian/ComfyUI-Crystools.git
            Set-Location ComfyUI-Crystools
            pip install -r requirements.txt

        }
    elseif ($env:VARIANT -eq "CUDA") {
            Set-Location $nodes
            git clone https://github.com/crystian/ComfyUI-Crystools.git
            Set-Location ComfyUI-Crystools
            pip install -r requirements.txt
            Set-Location $GitRoot
        }
    Set-Location $nodes
    git clone https://github.com/yolain/ComfyUI-Easy-Use
    Set-Location ComfyUI-Easy-Use
    pip install -r requirements.txt

    Set-Location $nodes

    git clone https://github.com/alexopus/ComfyUI-Image-Saver.git
    Set-Location ComfyUI-Image-Saver
    pip install -r requirements.txt

    Set-Location $nodes
    git clone https://github.com/mittimi/ComfyUI_mittimiLoadText

    Set-Location $GitRoot
}
function modelBuild {
    # Download the VAE model
    Set-Location -Path "$GitRoot\data\models\vae"
    Invoke-WebRequest -Uri https://huggingface.co/Mephist0phel3s/Devil-Diffusion/resolve/main/Devil_VAE.safetensors -OutFile "Devil_VAE.safetensors"

    # Download the base model
    Set-Location -Path "$GitRoot\data\models\checkpoints"
    Invoke-WebRequest -Uri https://huggingface.co/Mephist0phel3s/Devil-Diffusion/resolve/main/Devil_Pony_v1.3.safetensors -OutFile "Devil_Pony_v1.3.safetensors"
}
function buildAll {
    firstBuild
    modelBuild
}
function flags {
    param (
        [string]$flagFile = "$SrcRoot\devil_scripts\win.flag"  # Path to the flag file
    )
    Set-Location $SrcRoot\devil_scripts
    $fileContents = Get-Content -Path $flagFile

    $modelFlag = $fileContents[0].Split('=')[1].Trim()
    $firstRunFlag = $fileContents[1].Split('=')[1].Trim()

    if ($modelFlag -eq "0" -and $firstRunFlag -eq "0") {
        buildAll
        Set-Content -Path $flagFile -Value "model.flag=1`nfirstrun.flag=1"
    } elseif ($modelFlag -eq "1" -and $firstRunFlag -eq "1") {
        Write-Host "Flags are both true. Continuing..."
    } elseif ($modelFlag -eq "0" -and $firstRunFlag -eq "1") {
        modelBuild
        Set-Content -Path $flagFile -Value "model.flag=1`nfirstrun.flag=1"
    } elseif ($modelFlag -eq "1" -and $firstRunFlag -eq "0") {
        firstBuild
        Set-Content -Path $flagFile -Value "model.flag=1`nfirstrun.flag=1"
    } else {
        Write-Host "Unexpected flag values."
    }
}

$flagFile = "$SrcRoot\devil_scripts\models.flag"
$DataDir = "$GitRoot\data"
$models = "$DataDir\models"
$TMP = "$DataDir\tmp"
$tmp = "$GitRoot\data\tmp"
$nodes = "$GitRoot\data\custom_nodes"
$VENV = "$SrcRoot\venv"
$SOURCE_DATE_EPOCH = (Get-Date -UFormat %s)
$env:VARIANT = $variant
if ($variant -ne $null) {
    Write-Host "Forcing variant: $variant"
    $env:VARIANT = $variant
} else {
    $env:VARIANT = setVariant
}
setVariant
checkGit
cloneDevil
checkPython
flags
runDevil




