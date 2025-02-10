#!/run/current-system/sw/bin/bash
cd src
nix-shell --argstr variant CUDA # CUDA
