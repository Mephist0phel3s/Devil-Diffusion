
Use latest stable release pkg at >> https://github.com/Mephist0phel3s/Devil-Diffusion/releases/tag/AMDv1.2

if you prefer a one liner to download the correct AMD release, use this:
```
wget https://github.com/Mephist0phel3s/Devil-Diffusion/releases/tag/AMDv1.2
```
 

If you already have nix pkg manager installed, or are running NixOS, you should only need to pull down a release tarball, cd in, and nix-shell. The rest happens automatically. 
A new window with the running UI will spawn when the server is done building.

Those of you not running nix or nixos, heres a one-liner that will do both at once.
```
sudo sh <(curl -L https://nixos.org/nix/install) --daemon && wget https://github.com/Mephist0phel3s/Devil-Diffusion/archive/refs/tags/AMDv1.2.tar.gz ; tar -xf AMDv1.2.tar.gz.1 && rm AMDv1.2.tar.gz.1 ; cd Devil-Diffusion-AMDv1.2  && nix-shell
```
and this will do the same thing. 

NOTE::: Windows users in particular, you will need wsl enabled, any off the shelf linux distro will probably work but if you are enabling it for the first time i'd suggest using NixOS instead of Ubuntu or something else. 
It work best since this is a nix expression we are using to build Devil Diffusion.
Instructions for enabling WSL can be found here >> https://learn.microsoft.com/en-us/windows/wsl/install
I will add a more comprehensive install guide in the near future when i've had time to sit down and do a full pull and build on a windows machine.

NOTICE::: 
This repo contains an automatic install and pull script for a base model, VAE, and CLIP Vision as well as a few extensions preinstalled to get you working immediately. I may include more in the future as time develops, as the main goal of this repo is to be a feature complete out of the box diffusion model thats ready to generate good images immediately after install. 
Currently the pull phase eats about 14~gb of bandwidth.

NOTICE::: ive not written a script to bypass this yet but it will be available in the future. For now though, if you wish to skip and use your own models or drops in for the UI, run:
`touch devil_scripts/FIRSTRUN.flag && pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2 ; pip install -r requirements.txt ; pip install open-clip-torch ; nix-shell` and it will install the UI bare bones without pulling down preconfigured models.
After, you can continue to just use `nix-shell` to spawn the server without needingg to run the prior command again.

For my NixOS bros, add a desktopfile to your main config at /etc/nixos/configuration.nix under system packages like:
```
  (pkgs.writeShellApplication {
    name = "Devil-Diffusion";
      runtimeInputs = [pkgs.bash];
      text = ''cd /home/<user>/path.to.source.dir/ && nix-shell'';})



   (pkgs.makeDesktopItem {
      name = "Devil Diffusion";
      exec = "Devil-Diffusion";
      icon = "/home/<user>/path.to.source.dir/devil-diffusion-icon.png";

      desktopName = "Devil Diffusion AMD";
      categories = [ "Development" ];
      terminal = true;

    })
```
and run a rebuild after, once done your new desktop file will be available and pointing to the src directory to run nix-shell direct from desktop. 

Now that the intros are out of the way, you can find the Model srcs here >> https://civitai.com/models/1184251/devil-pony-v1 & >> https://huggingface.co/Mephist0phel3s/Devil-Diffusion/tree/main

![Devil Diffusion Mascot - Eve](https://github.com/Mephist0phel3s/Devil-Diffusion/blob/c380efa0a776e74ea43632be844ef1e36ada0c50/devil-diffusion-icon.png)


 stable-diffusion-xl supports generating images at the following dimensions:

    1024 x 1024

    1152 x 896

    896 x 1152

    1216 x 832

    832 x 1216

    1344 x 768

    768 x 1344

    1536 x 640

    640 x 1536

For completeness’s sake, these are the resolutions supported by clipdrop.co:

    768 x 1344: Vertical (9:16)

    915 x 1144: Portrait (4:5)

    1024 x 1024: square 1:1

    1182 x 886: Photo (4:3)

    1254 x 836: Landscape (3:2)

    1365 x 768: Widescreen (16:9)

    1564 x 670: Cinematic (21:9)


