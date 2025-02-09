{ variant ? "NONE" }:

let
  pkgs = import <nixpkgs> { };

  # Define hardware dependencies based on the variant
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
      pciutils
    ] else if variant == "CPU" then [
    ] else throw "You need to specify which variant you want: CPU, ROCm, or CUDA.";

in pkgs.mkShell rec {
  # Name of the shell
  name = "stable-diffusion-webui";

  # Build dependencies
  buildInputs = with pkgs;
    hardware_deps ++ [
      git # The program instantly crashes if git is not present, even if everything is already downloaded
      python312Full
      ffmpeg_6-full
      rsync
      zstd
      git-lfs
      # python312Packages.torch               ### python version supersedes, fix later
      # python312Packages.torchWithoutCuda    ### Apparently torch fucking needs CUDA for some god damn reason despite the test machine being an AMD machine without any CUDA cores.
                                             #### Repo fucking breaks with this enabled. Fix later.
      # python312Packages.pip                 ### See reason above.
      # python312Packages.einops
      # python312Packages.psutil
      # python312Packages.safetensors         ### im not 100% this is borked, but its normally best to enable this alongside torch and pip, buuut they are also fucked so its a moot point. Fix later.

      # python312Packages.torchWithRocm       ### AMD ROCM v6 in the nixpkg repo is marked broken due to an unbuilt dependency, notably HIP. Working on this on the side.
      # python312Packages.torchaudio
      # python312Packages.torchvision
      gperftools                        #### WARNING::: Needed for memory management, disable at your own risk.
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


    # Create virtual environment if it doesn't exist
    if test ! -d $VENV; then
      python3.12 -m venv $VENV
    fi
    source ./$VENV/bin/activate
    export PYTHONPATH=`pwd`/$VENV/${pkgs.python312Full.sitePackages}/:$PYTHONPATH



    if [ ! -f devil_scripts/FIRSTRUN.flag ]; then
      touch devil_scripts/FIRSTRUN.flag
      echo -e "First time execution detected. Standby comrade..."
      mkdir -p ../data/input
      mkdir -p ../data/temp
      mkdir -p ../data/user
      mkdir -p ../data/custom_nodes
      mkdir -p ../data/models
            # Select the appropriate firstrun script based on the variant
      case "$VARIANT" in
        "ROCM")
          echo "Running first run script for AMD/ROCm..."
          cd devil_scripts && exec ./firstrun-AMD.sh
          ;;
        "CUDA")
          echo "Running first run script for NVIDIA/CUDA..."
          cd devil_scripts && exec ./firstrun-NVIDIA.sh
          ;;
        "CPU")
          echo "Running first run script for CPU..."
          cd devil_scripts && exec ./firstrunCPU.sh
          ;;
        *)
          echo "Unknown variant: $VARIANT. Please specify a valid variant."
          exit 1
          ;;
      esac
    fi
    RED='\033[0;31m'
    NC='\033[0m'
    printf 'Thank you for using $REDDevil-Diffusion.'
    sleep 1

    python main.py --listen 127.0.0.1 --auto-launch --port 8666 --base-directory ../data
  '';

  # Post shell hook to set Python environment properly
  postShellHook = ''
    ln -sf ${pkgs.python312Full.sitePackages}/* ./.venv/lib/python3.12/site-packages
  '';

  # Environment variables
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
  CUDA_PATH = pkgs.lib.optionalString (variant == "CUDA") pkgs.cudatoolkit;
  EXTRA_LDFLAGS = pkgs.lib.optionalString (variant == "CUDA") "-L${pkgs.linuxPackages.nvidia_x11}/lib";
}
