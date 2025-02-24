#!/run/current-system/sw/bin/bash
cd src
nix-shell --argstr variant ROCM-LP # ROCm
