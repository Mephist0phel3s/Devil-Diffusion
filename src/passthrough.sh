    SOURCE_DATE_EPOCH=$(date +%s)
    export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${LD_LIBRARY_PATH}"
    VENV=venv
    TMP=tmp
    export VARIANT="${variant}"
    export RED='\033[0;31m'
    export NC='\033[0m'
    export GREEN='\033[0;32m'


    # Create virtual environment if it doesn't exist
    if test ! -d $VENV; then
      python3.12 -m venv $VENV
    fi
    source ./$VENV/bin/activate
    export PYTHONPATH=`pwd`/$VENV/${pkgs.python312Full.sitePackages}/:$PYTHONPATH
    cd ..
    GitRoot="$PWD"

        if [ ! -f devil_scripts/FIRSTRUN.flag ]; then
            touch devil_scripts/FIRSTRUN.flag
            echo -e "First time execution detected. Standby comrade..."
            mkdir -p models $GitRoot/data/
            mkdir -p input $GitRoot/data/
            mkdir -p output $GitRoot/data/
            mkdir -p temp $GitRoot/data/
            mkdir -p custom_nodes $GitRoot/data/

            cp -r $GitRoot/src/models $GitRoot/data/
            cp -r $GitRoot/src/input $GitRoot/data/
            cp -r $GitRoot/src/output $GitRoot/data/
            cp -r $GitRoot/src/temp $GitRoot/data/
            cp -r $GitRoot/src/custom_nodes $GitRoot/data/
            cd $GitRoot
        fi



############# Custom nodes

        if [ ! -d $GitRoot/data/custom_nodes/ComfyUI-Manager ]; then
            git clone  https://github.com/ltdrdata/ComfyUI-Manager $GitRoot/data/custom_nodes/ComfyUI-Manager
        else
           cd $GitRoot/data/custom_nodes/ComfyUI-Manager
           git pull https://github.com/ltdrdata/ComfyUI-Manager
           cd $GitRoot
        fi

        if [ ! -d $GitRoot/data/custom_nodes/ComfyUI-Crystools ]; then
            git clone -b AMD https://github.com/crystian/ComfyUI-Crystools.git $GitRoot/data/custom_nodes/ComfyUI-Crystools
            cd $GitRoot/data/custom_nodes/ComfyUI-Crystools
            pip install -r requirements.txt
            cd $GitRoot
          else
            cd $GitRoot/data/custom_nodes/ComfyUI-Crystools
            git pull https://github.com/crystian/ComfyUI-Crystools.git
            cd $GitRoot
        fi


        if [ ! -d $GitRoot/data/custom_nodes/ComfyUI-Easy-Use ]; then
            git clone https://github.com/yolain/ComfyUI-Easy-Use $GitRoot/data/custom_nodes/ComfyUI-Easy-Use
            cd $GitRoot/data/custom_nodes/ComfyUI-Easy-Use
            pip install -r requirements.txt
            cd $GitRoot
         else
            cd $GitRoot/data/custom_nodes/ComfyUI-Easy-Use
            git pull
            pip install -r requirements.txt
            cd $GitRoot
        fi

############################## Cloning the models

    echo "Cloning Devil-Diffusion base model + VAE, CLIP vision."
    echo -e "NOTE::: Devilv1.3 base model comes with VAE baked in.n/VAE on the side is a clone of the baked in VAE for ease of access for certain nodes, some nodes really REALLY want a specified VAE for some reason ive yet to figure out."

    sleep 1
    tmp="$GitRoot/data/tmp"
    mkdir -p tmp
        if [ ! -d $tmp/Devil-Diffusion || echo -e "Depending on your network speed, this may be a good time to go to the bathroom or grab coffee. \nFirst execution takes a bit to pull and build initially."
        echo -e "NOTICE: This start script will not run again unless you wipe this entire directory. \nThis script can be bypassed in future installs by first running n/touch devil-scripts/FIRSTRUN.flag before running the nix-shell." ]; then
            git-lfs clone https://huggingface.co/Mephist0phel3s/Devil-Diffusion $tmp/Devil-Diffusion
              else
            git-lfs pull https://huggingface.co/Mephist0phel3s/Devil-Diffusion $tmp/Devil-Diffusion
        fi

        if [ ! -d $tmp/IP-Adapter ]; then
            git-lfs clone https://huggingface.co/h94/IP-Adapter $tmp/IP-Adapter
        else
            git-lfs pull https://huggingface.co/h94/IP-Adapter $tmp/IP-Adapter
        fi


            mkdir -p $GitRoot/docs/ipadapter
            mkdir -p $GitRoot/data/models/ipadapter
            cp $tmp/Devil-Diffusion/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors $GitRoot/data/models/clip_vision
            cp $tmp/Devil-Diffusion/CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors $GitRoot/data/models/clip_vision
            cp $tmp/Devil-Diffusion/Devil_Pony_v1.3.safetensors $GitRoot/data/models/checkpoints
            cp $tmp/Devil-Diffusion/Devil_VAE.safetensors $GitRoot/data/models/vae
            cp -r $tmp/IP-Adapter/models/* $GitRoot/data/models/ipadapter
            cp -r $tmp/IP-Adapter/sdxl_models/* $GitRoot/data/models/ipadapter
            cp $tmp/IP-Adapter/README.md $GitRoot/docs/ipadapter/README.md
            wget https://github.com/Mephist0phel3s/hipBLASLt/archive/refs/tags/rocm-6.0.2.tar.gz
            tar -xf rocm-6.0.2.tar.gz
            rm rocm-6.0.2.tar.gz
            cd hipBLASLt-rocm-6.0.2
            ./install -idc
            cd $GitRoot/src



    case "$VARIANT" in
      "ROCM")
        cd $GitRoot/src/
        wget https://github.com/Mephist0phel3s/hipBLASLt/archive/refs/tags/rocm-6.0.2.tar.gz
        tar -xf rocm-6.0.2.tar.gz
        rm rocm-6.0.2.tar.gz
        cd hipBLASLt-rocm-6.0.2
        ./install -idc
        cd $GitRoot/src
        echo "Running first run script for AMD/ROCm..."


        echo "The reason i decided to implement auto install model functionality is because they were a pain in the ass to find, i suffered so you dont have to"
        echo "Executing first run script"


        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2
        pip install -r requirements.txt
        pip install open-clip-torch

        bash -c 'printf "$GREEN you for using $REDDevil-Diffusion."'
        bash -c NIXPKGS_ALLOW_UNFREE=1 PYTORCH_TUNABLEOP_ENABLED=1 TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1 python main.py --listen 127.0.0.1 --auto-launch --port 8666 --base-directory ../data \
                           --use-pytorch-cross-attention --disable-cuda-malloc
          ;;
      "CUDA")
        echo "Running first run script for NVIDIA/CUDA..."
        echo -e "Depending on your network speed, this may be a good time to go to the bathroom or grab coffee. First execution takes a bit to pull and build initially."
        echo -e "NOTICE::: This start script will not run again unless you wipe this entire directory. \nThis script can be bypassed in future installs by first running touch devil-scripts/FIRSTRUN.flag before running the nix-shell."
        echo "The reason i decided to implement auto install model functionality is because they were a pain in the ass to find, i suffered so you dont have to"
        echo "Executing first run script"
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2
        pip install -r requirements.txt
        pip install open-clip-torch
        bash -c 'printf "$GREEN you for using $REDDevil-Diffusion."'
        NIXPKGS_ALLOW_UNFREE=1 python main.py --listen 127.0.0.1 --auto-launch --port 8666 --base-directory ../data \
                       --cuda-malloc
          ;;

      "CPU")
        echo "Running first run script for CPU..."
          ;;
        *)
        echo "Unknown variant: $VARIANT. Please specify a valid variant."
        exit 1
          ;;
    esac

