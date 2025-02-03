{ pkgs, variant, ... }:

let
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

in
pkgs.mkShell rec {
    name = "stable-diffusion-webui";
    buildInputs = with pkgs;
      hardware_deps ++ [
        git # The program instantly crashes if git is not present, even if everything is already downloaded
        python312Full
	zstd
	git-lfs
#	python312Packages.torch
#	python312Packages.torchWithoutCuda
#	python312Packages.pip
#	python312Packages.einops
#	python312Packages.psutil
#	python312Packages.safetensors
#	python312Packages.torchWithRocm
#	python312Packages.torchaudio
#	python312Packages.torchvision
        gperftools
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
    SOURCE_DATE_EPOCH=$(date +%s)
    export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${LD_LIBRARY_PATH}"
    VENV=venv

    if test ! -d $VENV; then
      python3.12 -m venv $VENV
    fi
    source ./$VENV/bin/activate
    export PYTHONPATH=`pwd`/$VENV/${pkgs.python312Full.sitePackages}/:$PYTHONPATH



    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2
    pip install -r requirements.txt
    pip install open-clip-torch
    python main.py --listen 127.0.0.1



'';
  postShellHook = ''
    ln -sf ${pkgs.python312Full.sitePackages}/* ./.venv/lib/python3.12/site-packages
  '';
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
    CUDA_PATH = pkgs.lib.optionalString (variant == "CUDA") pkgs.cudatoolkit;
    EXTRA_LDFLAGS = pkgs.lib.optionalString (variant == "CUDA") "-L${pkgs.linuxPackages.nvidia_x11}/lib";
}
