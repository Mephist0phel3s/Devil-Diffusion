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
      git
      python312Full
      python312Packages.huggingface-hub
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

  shellHook = ''
flags() {
    local flag="$GitRoot/devil.flag"

    if [[ ! -f "$flag" ]]; then
        echo "Flag file '$flag' not found!"
        return 1
    fi

    # Read the file line by line
    while IFS='=' read -r option value; do
        # Ignore lines that are empty or comments
        if [[ -z "$option" || "$option" == \#* ]]; then
            continue
        fi

        # Check if the option is enabled (value = 1)
        case "$option" in
            "first-run")
                if [[ "$value" -eq 0 ]]; then
                    echo "First build detected, standby."
                    build-devil
                    extension-pull
                    lfs-pull
                    sed -i 's/^first-run=0$/first-run=1/' "$flag"
                    run-devil
                  else
                    run-devil
                fi
                ;;
            "lfs-pull")
                if [[ "$value" -eq 0 ]]; then
                    printf ""
                    lfs-pull
                ;;
            *)
                echo "Unknown option: $option"
                ;;
        esac
    done < "$flag"
}
lfs-pull() {
    local TIMEOUT=20
    local choice
    echo "Choose an option:"
    echo "A: Download default Devil Pony v1.3"
    echo "B: Download Devil Cartoon v1.1"
    echo "C: Download both"
    echo "D: Download none (add your own)"
    echo -e "Choice is the essence of Chaos!\n Make your choice, chaos seed."
    (
        sleep $TIMEOUT
        kill -s SIGTERM $$
    ) &
    read -t $TIMEOUT -p "Your choice: " choice
    if [[ -z "$choice" ]]; then
        echo "No input received, defaulting to Download default"
        choice="A"
    fi
    case "$choice" in
        A|a) echo "Pulling Devil Pony v1.3, standby." && \
        huggingface-cli download Mephist0phel3s/Devil-Diffusion \
        --include Devil_Pony_v1.3.safetensors \
        --local-dir $PWD/ ;;

        B|b) echo "Pulling Devil Cartoon v1.1, standby" && \
        huggingface-cli download Mephist0phel3s/Devil-Diffusion \
        --include Devil_Cartoon_v1.1-beta_00001_.safetensors
        --local-dir $PWD/ ;;
        C|c) echo "Pulling both Devil Cartoon v1.1 and Pony v1.3, standby" && \
        huggingface-cli download Mephist0phel3s/Devil-Diffusion \
        --include Devil_Cartoon_v1.1-beta_00001_.safetensors \
        --include Devil_Pony_v1.3.safetensors \
        --local-dir $PWD/ ;;
        D|d) echo "None, add your own to data/models/checkpoints";;

        *) echo "Invalid selection, defaulting to A, standby.";;
    esac
fi
}
extension-pull() {
cd $GitRoot
          git submodule update --init --recursive
          nodes=$GitRoot/data/custom_nodes

          cd $nodes/ComfyUI-Manager
          git checkout 3.9.4

          cd $nodes/ComfyUI-Crystools
          git checkout AMD
          pip install -r $GitRoot/data/custom_nodes/ComfyUI-Crystools/requirements.txt

          cd $nodes/ComfyUI_mittimiLoadText
          git checkout main

          cd $nodes/ComfyUI-Image-Saver
          git checkout v1.4.0
          pip install -r $GitRoot/data/custom_nodes/ComfyUI-Image-Saver/requirements.txt

          cd $nodes/ComfyUI-Easy-Use
          git checkout v1.2.7
          pip install -r $GitRoot/data/custom_nodes/ComfyUI-Easy-Use/requirements.txt

case "$VARIANT" in
      "ROCM")
            cd $GitRoot/data/custom_nodes/ComfyUI-Crystools
            git checkout AMD
            pip install -r $GitRoot/data/custom_nodes/ComfyUI-Crystools/requirements.txt
            cd $GitRoot
            ;;
      "CUDA")
        cd $nodes/ComfyUI-Crystools
        git checkout 1.9.3
        pip install -r $GitRoot/data/custom_nodes/ComfyUI-Crystools/requirements.txt
      ;;
esac

}
run-devil() {
    cd "$GitRoot/src"
    case "$VARIANT" in
      "ROCM")
        cd $GitRoot/src/

       devilish-print "Thank you for using Devil Diffusion" "Red" "blue" "bold"
        #### Env set for run
        PYTORCH_TUNABLEOP_ENABLED=0 TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=0 \
        python main.py --listen 127.0.0.1 --auto-launch --port 8666 --base-directory $GitRoot/data \
        --use-pytorch-cross-attention --cpu-vae --disable-xformers
          ;;
      "CUDA")
        cd $GitRoot/src/
         devilish-print "Thank you for using Devil Diffusion" "Red" "blue" "bold"

        NIXPKGS_ALLOW_UNFREE=1 \
        python main.py \
        --listen 127.0.0.1 --auto-launch --port 8666 --base-directory $GitRoot/data --cuda-malloc
          ;;
      "CPU")
        echo "Running first run script for CPU..."
          ;;
        *)
        echo "Unknown variant: $VARIANT. Please specify a valid variant."
        exit 1
          ;;
    esac
}
build-devil() {
    case "$VARIANT" in
      "ROCM")
        cd $GitRoot/src/
  devilish-print "This is red text on yellow background with bold" "red" "yellow" "bold"
  devilish-print "Building Devil Diffusion for CUDA based machine." "red" "yellow" "bold"

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
}
spawn-venv() {
  devilish-print "Spawning python virtual env and prepping env for runtime" "yellow" "black" ""
    cd $SrcRoot
    SOURCE_DATE_EPOCH=$(date +%s)
    if test ! -d $SrcRoot/venv; then
      python3.12 -m venv venv
    fi
    source $SrcRoot/venv/bin/activate
    export PYTHONPATH=$SrcRoot/venv/${pkgs.python312Full.sitePackages}/:$PYTHONPATH
    cd $GitRoot
}
#!/bin/bash

# Function to print colored text with background, bold, and underline options
devilish-print() {
    local text="$1"
    local color="$2"
    local bgcolor="$3"
    local style="$4"

    # Define color codes (foreground colors)
    local RESET="\033[0m"
    local BOLD="\033[1m"
    local UNDERLINE="\033[4m"

    # Foreground colors (xterm 16 colors)
    local BLACK="\033[30m"
    local RED="\033[31m"
    local GREEN="\033[32m"
    local YELLOW="\033[33m"
    local BLUE="\033[34m"
    local MAGENTA="\033[35m"
    local CYAN="\033[36m"
    local WHITE="\033[37m"
    local GRAY="\033[90m"
    local LIGHT_RED="\033[91m"
    local LIGHT_GREEN="\033[92m"
    local LIGHT_YELLOW="\033[93m"
    local LIGHT_BLUE="\033[94m"
    local LIGHT_MAGENTA="\033[95m"
    local LIGHT_CYAN="\033[96m"
    local LIGHT_WHITE="\033[97m"

    # Background colors
    local BG_BLACK="\033[40m"
    local BG_RED="\033[41m"
    local BG_GREEN="\033[42m"
    local BG_YELLOW="\033[43m"
    local BG_BLUE="\033[44m"
    local BG_MAGENTA="\033[45m"
    local BG_CYAN="\033[46m"
    local BG_WHITE="\033[47m"
    local BG_GRAY="\033[48;5;8m"    # Using 256-color background gray
    local BG_LIGHT_RED="\033[48;5;9m"
    local BG_LIGHT_GREEN="\033[48;5;10m"
    local BG_LIGHT_YELLOW="\033[48;5;11m"
    local BG_LIGHT_BLUE="\033[48;5;12m"
    local BG_LIGHT_MAGENTA="\033[48;5;13m"
    local BG_LIGHT_CYAN="\033[48;5;14m"
    local BG_LIGHT_WHITE="\033[48;5;15m"

    # Select foreground color based on input
    case "$color" in
        "black")   fg=$BLACK ;;
        "red")     fg=$RED ;;
        "green")   fg=$GREEN ;;
        "yellow")  fg=$YELLOW ;;
        "blue")    fg=$BLUE ;;
        "magenta") fg=$MAGENTA ;;
        "cyan")    fg=$CYAN ;;
        "white")   fg=$WHITE ;;
        "gray")    fg=$GRAY ;;
        "light-red")   fg=$LIGHT_RED ;;
        "light-green") fg=$LIGHT_GREEN ;;
        "light-yellow") fg=$LIGHT_YELLOW ;;
        "light-blue") fg=$LIGHT_BLUE ;;
        "light-magenta") fg=$LIGHT_MAGENTA ;;
        "light-cyan") fg=$LIGHT_CYAN ;;
        "light-white") fg=$LIGHT_WHITE ;;
        *)          fg=$RESET ;;  # Default to no color
    esac

    # Select background color based on input
    case "$bgcolor" in
        "black")   bg=$BG_BLACK ;;
        "red")     bg=$BG_RED ;;
        "green")   bg=$BG_GREEN ;;
        "yellow")  bg=$BG_YELLOW ;;
        "blue")    bg=$BG_BLUE ;;
        "magenta") bg=$BG_MAGENTA ;;
        "cyan")    bg=$BG_CYAN ;;
        "white")   bg=$BG_WHITE ;;
        "gray")    bg=$BG_GRAY ;;
        "light-red")   bg=$BG_LIGHT_RED ;;
        "light-green") bg=$BG_LIGHT_GREEN ;;
        "light-yellow") bg=$BG_LIGHT_YELLOW ;;
        "light-blue") bg=$BG_LIGHT_BLUE ;;
        "light-magenta") bg=$BG_LIGHT_MAGENTA ;;
        "light-cyan") bg=$BG_LIGHT_CYAN ;;
        "light-white") bg=$BG_LIGHT_WHITE ;;
        *)          bg=$RESET ;;  # Default to no background color
    esac

    # Apply style options (bold, underline)
    case "$style" in
        "bold")       style_code=$BOLD ;;
        "underline")  style_code=$UNDERLINE ;;
        *)            style_code=$RESET ;;  # Default to no style
    esac

    # Print the formatted text
     bash -c 'printf "${style_code}${fg}${bg}${text}${RESET}\n"'
}

# Example usage:

export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${LD_LIBRARY_PATH}"
export VARIANT="${variant}"
SrcRoot="$PWD"
cd ..
GitRoot="$PWD"
checkpoints=$GitRoot/data/models/checkpoints
cd $GitRoot
spawn-venv
flags
#build-devil
#extension-pull
#lfs-pull
#run-devil

  '';

  postShellHook = ''
  ln -sf ${pkgs.python312Full.sitePackages}/* ./venv/lib/python3.12/site-packages
  '';

  # Environment variables
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
  CUDA_PATH = pkgs.lib.optionalString (variant == "CUDA") pkgs.cudatoolkit;
  ROCM_PATH = pkgs.lib.optionalString ( variant == "ROCM") pkgs.rocmPackages.rocm-smi;
  EXTRA_LDFLAGS = pkgs.lib.optionalString (variant == "CUDA") "-L${pkgs.linuxPackages.nvidia_x11}/lib";
}
