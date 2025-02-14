{ variant ? "NONE" }:

let
  pkgs = import <nixpkgs> { };
  hardware_deps = with pkgs;
    if variant == "CUDA" then [
      cudatoolkit
      linuxPackages.nvidia_x11
      xorg.libXi
      xorg.libXmu
      freeglut
      xorg.libXext
      xorg.libX11
      xorg.libXv
      xorg.libXrandr
      zlib

      # for xformers
      gcc
    ] else if variant == "ROCM" then [
      rocmPackages.rocm-runtime
      rocmPackages.rocm-smi
#      rocmPackages.hipblas
#      rocmPackages.roctracer
#      python312Packages.torchWithoutCuda
      pciutils
    ] else if variant == "CPU" then [
    ] else throw "You need to specify which variant you want: CPU, ROCm, or CUDA.";

in pkgs.mkShell rec {
  # Name of the shell
  name = "Devil-Diffusion-WebUI";

  # Build dependencies
  buildInputs = with pkgs;
    hardware_deps ++ [
      git # The program instantly crashes if git is not present, even if everything is already downloaded
      python312Full
      zstd
      git-lfs
      # python312Packages.torch               ### python version supersedes, fix later
          ### Apparently torch fucking needs CUDA for some god damn reason despite the test machine being an AMD machine without any CUDA cores.
                                             #### Repo fucking breaks with this enabled. Fix later.
      # python312Packages.pip                 ### See reason above.
      # python312Packages.einops
      # python312Packages.psutil
      # python312Packages.safetensors         ### im not 100% this is borked, but its normally best to enable this alongside torch and pip, buuut they are also fucked so its a moot point. Fix later.

      # python312Packages.torchWithRocm       ### AMD ROCM v6 in the nixpkg repo is marked broken due to an unbuilt dependency, notably HIP. Working on this on the side.
      # python312Packages.torchaudio
      # python312Packages.torchvision
      gperftools                              #### WARNING::: Needed for memory management, disable at your own risk.
      stdenv.cc.cc.lib
      stdenv.cc
      ncurses5
      binutils
      gitRepo gnupg autoconf curl
      procps gnumake util-linux m4 gperf unzip
      libGLU libGL
      glib
    ];

  # Custom shell hook for setting up environment
  shellHook = ''

    SOURCE_DATE_EPOCH=$(date +%s)
    export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${LD_LIBRARY_PATH}"
    VENV=venv
    TMP=tmp
    export VARIANT="${variant}"

    export black='\033[0;30m'
    export red='\033[0;31m'
    export green='\033[0;32m'
    export yellow='\033[0;33m'
    export blue='\033[0;34m'
    export purple='\033[0;35m'
    export cyan='\033[0;36m'
    export white='\033[0;37m'
    # Background
    export on_black='\033[40m'
    export on_red='\033[41m'
    export on_green='\033[42m'
    export on_yellow='\033[43m'
    export on_blue='\033[44m'
    export on_purple='\033[45m'
    export on_cyan='\033[46m'
    export on_white='\033[47m'
    export BIYellow='\033[1;93m'
    export UGreen='\033[4;32m'


    # Create virtual environment if it doesn't exist
    if test ! -d $VENV; then
      python3.12 -m venv $VENV
    fi
    source ./$VENV/bin/activate
    export PYTHONPATH=`pwd`/$VENV/${pkgs.python312Full.sitePackages}/:$PYTHONPATH
    cd ..
    GitRoot="$PWD"

        if [ ! -f $GitRoot/src/devil_scripts/FIRSTRUN.flag ]; then
            touch $GitRoot/src/devil_scripts/FIRSTRUN.flag
            bash -c "printf '\n First time execution detected. Standby comrade....'"
            sleep 3
            cp -r $GitRoot/src/models $GitRoot/data/
            cp -r $GitRoot/src/input $GitRoot/data/
            cp -r $GitRoot/src/output $GitRoot/data/
            cp -r $GitRoot/src/temp $GitRoot/data/
            cp -r $GitRoot/src/custom_nodes $GitRoot/data/
            cd $GitRoot
        fi
          case "$VARIANT" in
      "ROCM")
        cd $GitRoot/src/

        pip install torch torchvision torchaudio \
          --index-url https://download.pytorch.org/whl/rocm6.2.4
        pip install -r requirements.txt
        pip install open-clip-torch
        ;;
      "CUDA")
        cd $GitRoot/src/
        pip install torch torchvision torchaudio \
          --extra-index-url https://download.pytorch.org/whl/cu126
        pip install -r requirements.txt
        pip install open-clip-torch
          ;;
      esac



############# Custom nodes

        if [ ! -d $GitRoot/data/custom_nodes/ComfyUI-Manager ]; then
            git clone  https://github.com/ltdrdata/ComfyUI-Manager $GitRoot/data/custom_nodes/ComfyUI-Manager
        else
           cd $GitRoot/data/custom_nodes/ComfyUI-Manager
           git pull https://github.com/ltdrdata/ComfyUI-Manager
           cd $GitRoot
        fi
	
	if [ ! -d $GitRoot/data/custom_nodes/ComfyUI_mittimiLoadText ]; then
		cd $GitRoot/data/custom_nodes/
		git clone https://github.com/mittimi/ComfyUI_mittimiLoadText
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

        if [ ! -d $GitRoot/data/custom_nodes/ComfyUI-Image-Saver ]; then
          cd $GitRoot/data/custom_nodes
          git clone https://github.com/alexopus/ComfyUI-Image-Saver.git
          cd ComfyUI-Image-Saver
          pip install -r requirements.txt
          cd $GitRoot
        fi

############# Cloning the models

    echo "Cloning Devil-Diffusion base model + VAE, and CLIP vision."
    echo -e "NOTE::: Devilv1.3 base model comes with VAE baked in.n/VAE on the side is a clone of the baked in VAE for ease of access for certain nodes, some nodes really REALLY want a specified VAE for some reason ive yet to figure out."
    sleep 5
    tmp="$GitRoot/data/tmp"
    mkdir -p $tmp
    echo "$PWD"
    #exit 1
        if [ ! -d $tmp/Devil-Diffusion ]; then
        bash -c "printf '\nThank you for using Devil-Diffusion.'"
        bash -c "printf '\nWARNING::: Depending on your network speed, this may be a good time to go to the bathroom or grab coffee. \nFirst execution takes a bit to pull and build initially.'"
        bash -c "printf '\nNOTICE: This start script will not run again unless you wipe this entire directory. \necho -e "\033[4mThis script can be bypassed in future installs by first running n/touch devil-scripts/FIRSTRUN.flag before running the nix-shell.\033[m"'"
        sleep 5
            git-lfs clone https://huggingface.co/Mephist0phel3s/Devil-Diffusion $tmp/Devil-Diffusion
              else
            git-lfs pull https://huggingface.co/Mephist0phel3s/Devil-Diffusion $tmp/Devil-Diffusion
        fi
####NOTICE::: ive decided to exlude IPA for now as its not commonly used enough to justify the upfront bandwidth cost to user for now.
#        if [ ! -d $tmp/IP-Adapter ]; then
#            git-lfs clone https://huggingface.co/h94/IP-Adapter $tmp/IP-Adapter
#        else
#            git-lfs pull https://huggingface.co/h94/IP-Adapter $tmp/IP-Adapter
#            ipa=$tmp/IP-Adapter && export ipa=$tmp/IP-Adapter
#        fi


# Create directories
mkdir -p "$GitRoot/docs/ipadapter"
ipa=$GitRoot/data/models/ipadapter
models=$GitRoot/data/models

if [ ! -f $GitRoot/src/devil_scripts/models.flag ]; then
   touch $GitRoot/src/devil_scripts/models.flag
   rsync -av --progress \
      "$tmp/Devil-Diffusion/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors" "$models/clip_vision" 
   rsync -av --progress \
      "$tmp/Devil-Diffusion/CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors" "$models/clip_vision" 
   rsync -av --progress \
      "$tmp/Devil-Diffusion/Devil_Pony_v1.3.safetensors" "$models/checkpoints" 
   rsync -av --progress \
      "$tmp/Devil-Diffusion/Devil_VAE.safetensors" "$models/vae" 


####NOTICE::: I've decided to exlcude IPA for now, as its not a commonly enough used node to justify bandwidth expense.
#   rsync -av --progress \
#      "$tmp/IP-Adapter/README.md" "$GitRoot/docs/ipadapter/README.md"
#   mkdir -p $ipa

#   rsync -av --progress \
#      "$tmp/IP-Adapter/models" "$ipa/" 
#   rsync -av --progress \
#      "$tmp/IP-Adapter/sdxl_models" "$ipa/"


fi
    cd "$GitRoot/src"



    case "$VARIANT" in
      "ROCM")
        cd $GitRoot/src/

       bash -c "printf '\n$green Thank you for using Devil-Diffusion. $nc'"

        PYTORCH_TUNABLEOP_ENABLED=0 TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=0 \

        python main.py --listen 127.0.0.1 --auto-launch --port 8666 --base-directory $GitRoot/data \
                       --use-pytorch-cross-attention --cpu-vae --disable-xformers
          ;;
      "CUDA")
        cd $GitRoot/src/
       bash -c "printf '\n$green Thank you for using \033[31mDevil-Diffusion.\033[0m\n'"

        NIXPKGS_ALLOW_UNFREE=1 python main.py  --listen 127.0.0.1 --auto-launch --port 8666 --base-directory $GitRoot/data \
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



  '';

  # Post shell hook to set Python environment properly
  postShellHook = ''
    ln -sf ${pkgs.python312Full.sitePackages}/* ./venv/lib/python3.12/site-packages
  '';

  # Environment variables
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
  CUDA_PATH = pkgs.lib.optionalString (variant == "CUDA") pkgs.cudatoolkit;
  ROCM_PATH= pkgs.lib.optionalString ( variant == "ROCM") pkgs.rocmPackages.rocm-smi;
  EXTRA_LDFLAGS = pkgs.lib.optionalString (variant == "CUDA") "-L${pkgs.linuxPackages.nvidia_x11}/lib";
}
