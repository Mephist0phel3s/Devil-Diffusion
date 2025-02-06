{ variant ? "NVIDIA" }:

let pkgs = import <nixpkgs> { };
    python = pkgs.python312Full;
    pythonPackages = python.pkgs;
in import ./impl.nix { inherit pkgs variant; }





