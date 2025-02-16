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

    while IFS='=' read -r option value; do
        if [[ -z "$option" || "$option" == \#* ]]; then
            continue
        fi
        case "$option" in
            "first-run")
                if [[ "$value" -eq 0 ]]; then
                    echo "First build detected, standby."
                    build-devil
                    extension-pull
                    lfs-pull
                    sed -i 's/^first-run=0$/first-run=1/' "$flag"
                fi
                ;;
            "lfs-pull")
                if [[ "$value" -eq 0 ]]; then
                    lfs-pull
                  else
                    printf "skip lfs-pull"
                  sed -i 's/^lfs-pull=0$/lfs-pull=1/' "$flag"
                fi
                ;;
            *)
                echo "Unknown option"
                ;;
        esac
    done < "$flag"
}
lfs-pull() {
    local flag="$GitRoot/devil.flag"
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
        A|a) echo "Pulling Devil Pony v1.3, standby."
        huggingface-cli download Mephist0phel3s/Devil-Diffusion \
        --include Devil_Pony_v1.3.safetensors \
        --local-dir $checkpoints/
        ;;

        B|b) echo "Pulling Devil Cartoon v1.1, standby"
        huggingface-cli download Mephist0phel3s/Devil-Diffusion \
        --include Devil_Cartoon_v1.1-beta_00001_.safetensors \
        --local-dir $checkpoints/
        ;;
        C|c) echo "Pulling both Devil Cartoon v1.1 and Pony v1.3, standby"
        huggingface-cli download Mephist0phel3s/Devil-Diffusion \
        --include Devil_Cartoon_v1.1-beta_00001_.safetensors \
        --include Devil_Pony_v1.3.safetensors \
        --local-dir $checkpoints/
        ;;
        D|d) echo "None, add your own to data/models/checkpoints"
        ;;

        *) echo "Invalid selection, defaulting to A, standby."
        ;;
    esac
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

        #### Env set for run
        PYTORCH_TUNABLEOP_ENABLED=0 TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=0 \
        python main.py --listen 127.0.0.1 --auto-launch --port 8666 --base-directory $GitRoot/data \
        --use-pytorch-cross-attention --cpu-vae --disable-xformers
          ;;
      "CUDA")
        cd $GitRoot/src/

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
#  devilish-print "This is red text on yellow background with bold" "red" "yellow" "bold"
#  devilish-print "Building Devil Diffusion for CUDA based machine." "red" "yellow" "bold"

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
#  devilish-print "Spawning python virtual env and prepping env for runtime" "yellow" "black" ""
    cd $SrcRoot
    SOURCE_DATE_EPOCH=$(date +%s)
    if [ ! -d $SrcRoot/venv ]; then
      python3.12 -m venv venv
    fi
    source $SrcRoot/venv/bin/activate
    export PYTHONPATH=$SrcRoot/venv/${pkgs.python312Full.sitePackages}/:$PYTHONPATH
    cd $GitRoot
}

export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${LD_LIBRARY_PATH}"
export VARIANT="${variant}"
SrcRoot="$PWD"
cd ..
GitRoot="$PWD"
checkpoints=$GitRoot/data/models/checkpoints
cd $GitRoot
spawn-venv
flags
run-devil

  '';
  postShellHook = ''ln -sf ${pkgs.python312Full.sitePackages}/* ./venv/lib/python3.12/site-packages'';
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
  CUDA_PATH = pkgs.lib.optionalString (variant == "CUDA") pkgs.cudatoolkit;
  ROCM_PATH = pkgs.lib.optionalString ( variant == "ROCM") pkgs.rocmPackages.rocm-smi;
  EXTRA_LDFLAGS = pkgs.lib.optionalString (variant == "CUDA") "-L${pkgs.linuxPackages.nvidia_x11}/lib";
}
