function Check-Git {
    try {
        # Check if Git is available
        git --version
        return $true
    } catch {
        return $false
    }
}
function Check-GitLFS {
    try {
        # Check if Git LFS is available
        git lfs version
        return $true
    } catch {
        return $false
    }
}
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

$modelsflagFile = "$SrcRoot\devil_scripts\models.flag"
$flagContent = "Devil girls are sexy"
$SrcRoot = "$GitRoot\src"
$DataDir = "$GitRoot\data"
$models = "$DataDir\models"
$TMP = "$DataDir\tmp"
$nodes = "$GitRoot\data\custom_nodes"
$VENV = "$SrcRoot\venv"
$SOURCE_DATE_EPOCH = (Get-Date -UFormat %s)
$env:VARIANT = $variant
$tmp = "$GitRoot\data\tmp"
$lfs_vae = "https://huggingface.co/Mephist0phel3s/Devil-Diffusion/resolve/main/Devil_VAE.safetensors"
$lfs_basemodel = "https://huggingface.co/Mephist0phel3s/Devil-Diffusion/resolve/main/Devil_Pony_v1.3.safetensors"
if ($variant -ne $null) {
    Write-Host "Forcing variant: $variant"
    $env:VARIANT = $variant
} else {
    $env:VARIANT = $null
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
$homeDir = [System.Environment]::GetFolderPath('UserProfile')
Set-Location -Path $homeDir
$GitRoot = "$homeDir\Devil-Diffusion"
$currentDir = Get-Location
if ($currentDir.Path -eq $GitRoot) {
    git pull
} elseif (-not (Test-Path -Path $GitRoot)) {
    Set-Location -Path $homeDir
    git clone https://github.com/Mephist0phel3s/Devil-Diffusion.git
} else {
    Set-Location -Path $GitRoot
    git pull
}


if (-not (Test-Path -Path $VENV)) {
    python -m venv $VENV
    Set-Location -Path $VENV
    . .\Scripts\Activate.ps1
    $env:PYTHONPATH = (Get-Location).Path + "\" + $VENV + "\" + $pkgs.python312Full.sitePackages + "\" + ":" + $env:PYTHONPATH
    Set-Location -Path $GitRoot
}

Set-Variant

cd $GitRoot\src
if ($env:VARIANT -eq "ROCM") {
    Write-Host "Installing ROCM-specific dependencies..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2.4
    pip install -r requirements.txt
    pip install open-clip-torch
    Set-Location $GitRoot
} elseif ($env:VARIANT -eq "CUDA") {
    Write-Host "Installing CUDA-specific dependencies..."
    Set-Location $SrcRoot
    pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu126
    pip install -r requirements.txt
    pip install open-clip-torch
    Set-Location $GitRoot
} else {
    Set-Location $SrcRoot
    Write-Host "Running for CPU variant..."
    pip install -r requirements.txt
    Set-Location $GitRoot
}

$FRflagFile = $SrcRoot\devil_scripts\FIRSTRUN.flag
if (-not (Test-Path -Path $FRflagFile )) {
    New-Item -Path $FRflagFile -itemType File
    Set-Content -Path $FRflagFile -Value $flagContent
    Write-Host "First time execution detected. Standby comrade...."
    Start-Sleep -Seconds 3

    Copy-Item -Recurse $GitRoot\src\models $DataDir\models
    Copy-Item -Recurse $GitRoot\src\input $DataDir\input
    Copy-Item -Recurse $GitRoot\src\output $DataDir\output
    Copy-Item -Recurse $GitRoot\src\temp $DataDir\temp
    Copy-Item -Recurse $GitRoot\src\custom_nodes $DataDir\custom_nodes
    Set-Location $nodes

    git clone https://github.com/ltdrdata/ComfyUI-Manager $GitRoot\data\custom_nodes\ComfyUI-Manager

    git clone https://github.com/yolain/ComfyUI-Easy-Use $GitRoot\data\custom_nodes\ComfyUI-Easy-Use
        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Easy-Use
        pip install -r requirements.txt
        Set-Location $nodes

    git clone https://github.com/alexopus/ComfyUI-Image-Saver.git
        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Image-Saver
        pip install -r requirements.txt
        Set-Location $nodes
    git clone https://github.com/mittimi/ComfyUI_mittimiLoadText
        Set-Location $nodes


    if ($env:VARIANT -eq "ROCM") {

            git clone -b AMD https://github.com/crystian/ComfyUI-Crystools.git $GitRoot\data\custom_nodes\ComfyUI-Crystools
            Set-Location $GitRoot\data\custom_nodes\ComfyUI-Crystools
            pip install -r requirements.txt

    }
    elseif ($env:VARIANT -eq "NVIDIA") {
            git clone https://github.com/crystian/ComfyUI-Crystools.git $GitRoot\data\custom_nodes\ComfyUI-Crystools
            Set-Location $GitRoot\data\custom_nodes\ComfyUI-Crystools
            pip install -r requirements.txt
            Set-Location $GitRoot
    }


    Set-Location $GitRoot
} else {
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
            Write-Host "Thank you for using Devil-Diffusion. Starting main.py..."
            python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --use-pytorch-cross-attention --cpu-vae --disable-xformers
        } elseif ($env:VARIANT -eq "CUDA") {
            Set-Location $SrcRoot
            Write-Host "Thank you for using Devil-Diffusion. Starting main.py..."
            python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --use-pytorch-cross-attention --cuda-malloc
        } else {
            Set-Location $SrcRoot
            python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --cpu
        }
}

if (-not (Test-Path -Path "$GitRoot\data\custom_nodes\ComfyUI-Manager")) {
    git clone https://github.com/ltdrdata/ComfyUI-Manager $GitRoot\data\custom_nodes\ComfyUI-Manager
} else {
    Set-Location $GitRoot\data\custom_nodes\ComfyUI-Manager
    git pull https://github.com/ltdrdata/ComfyUI-Manager
    Set-Location $GitRoot
}

if (-not (Test-Path -Path "$GitRoot\data\custom_nodes\ComfyUI_mittimiLoadText")) {
    Set-Location $GitRoot\data\custom_nodes
    git clone https://github.com/mittimi/ComfyUI_mittimiLoadText
    Set-Location $GitRoot
}

#if ($env:VARIANT -eq "ROCM") {
#    if (-not (Test-Path -Path "$GitRoot\data\custom_nodes\ComfyUI-Crystools")) {
#        git clone -b AMD https://github.com/crystian/ComfyUI-Crystools.git $GitRoot\data\custom_nodes\ComfyUI-Crystools
#        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Crystools
#        pip install -r requirements.txt
#        Set-Location $GitRoot
#    } else {
#        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Crystools
#        git pull https://github.com/crystian/ComfyUI-Crystools.git
#        Set-Location $GitRoot
#    }
#} elseif ($env:VARIANT -eq "NVIDIA") {
#    if (-not (Test-Path -Path "$GitRoot\data\custom_nodes\ComfyUI-Crystools")) {
#        git clone https://github.com/crystian/ComfyUI-Crystools.git $GitRoot\data\custom_nodes\ComfyUI-Crystools
#        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Crystools
#        pip install -r requirements.txt
#        Set-Location $GitRoot
#    } else {
#        Set-Location $GitRoot\data\custom_nodes\ComfyUI-Crystools
#        git pull https://github.com/crystian/ComfyUI-Crystools.git
#        Set-Location $GitRoot
#    }
#}
#
#
#if (-not (Test-Path -Path "$GitRoot\data\custom_nodes\ComfyUI-Easy-Use")) {
#    git clone https://github.com/yolain/ComfyUI-Easy-Use $GitRoot\data\custom_nodes\ComfyUI-Easy-Use
#    Set-Location $GitRoot\data\custom_nodes\ComfyUI-Easy-Use
#    pip install -r requirements.txt
#    Set-Location $GitRoot
#} else {
#    Set-Location $GitRoot\data\custom_nodes\ComfyUI-Easy-Use
#    git pull
#    pip install -r requirements.txt
#    Set-Location $GitRoot
#}
#
#if (-not (Test-Path -Path "$GitRoot\data\custom_nodes\ComfyUI-Image-Saver")) {
#    Set-Location $GitRoot\data\custom_nodes
#    git clone https://github.com/alexopus/ComfyUI-Image-Saver.git
#    Set-Location $GitRoot\data\custom_nodes\ComfyUI-Image-Saver
#    pip install -r requirements.txt
#    Set-Location $GitRoot
#}

Write-Host "Cloning Devil-Diffusion base model + VAE, and CLIP vision."
Write-Host "Devil base model comes with VAE baked in. VAE on the side is a clone of the baked in VAE for ease of access for certain nodes, some nodes really REALLY want a specified VAE for some reason ive yet to figure out."
Start-Sleep -Seconds 5

if (-not (Test-Path -Path $modelsflagFile)) {
    New-Item -Path "$modelsflagFile" -ItemType File
    Set-Content -Path $FRflagFile -Value $flagContent
    Set-Location -Path $models\vae
    Invoke-WebRequest -Uri $lfs_vae -OutFile "Devil_VAE.safetensors"
    Set-Location -Path $models\checkpoints
    Invoke-WebRequest -Uri $lfs_basemodel -OutFile "Devil_Pony_v1.3.safetensors"
} else {
    Write-Host "Flag file already exists. Continuing..."
}




cd $GitRoot\src
if ($env:VARIANT -eq "ROCM") {
    Set-Location $SrcRoot
    Write-Host "Thank you for using Devil-Diffusion. Starting main.py..."
    python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --use-pytorch-cross-attention --cpu-vae --disable-xformers
} elseif ($env:VARIANT -eq "CUDA") {
    Set-Location $SrcRoot
    Write-Host "Thank you for using Devil-Diffusion. Starting main.py..."
    python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --use-pytorch-cross-attention --cuda-malloc
} else {
    Set-Location $SrcRoot
    python main.py --listen 127.0.0.1 --port 8666 --base-dir $DataDir --auto-launch --cpu
}

