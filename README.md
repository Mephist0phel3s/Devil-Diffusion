Devil Diffusion v2.0 is now available.
V2 changes, short version:
Fixed bug where the extensions werent installing correclty and needed to be repaired after initial build. Extensions now install and activate on first boot as intended.
Fixed a bug where in the Workflows that are supposed to be included in the release werent populating in the UI.

Still an issue with the Welcome workflow not populating on first boot, for now just open the workflows tab on the UI once it spawns and select the Welcome-Devil-Diffusion workflow to get up and running immeditiately.

If you are struglingg with getting the workflow to load, please submit a bug report to the issues of this repo.
Heres a hard link to the welcome json + img with embed data. Both should be drag + drop.

json: https://github.com/Mephist0phel3s/Devil-Diffusion/blob/163f1471b5a964a196ef12f02665192ddcd50ba7/user/default/workflows/Welcome-Devil-Diffusion-v1.2.4.json

img: https://github.com/Mephist0phel3s/Devil-Diffusion/blob/3101e5287cc4fcb5b671b6e6c95118276e54ca15/output/Welcome_00000.png


The included workflow is a simplified layout with 2 Lora nodes ready to be populated with a pack. Will include screenshots soon as well as a Welcome Walkthrough on how Devil Diffusion differs from its parent repos.
The welcome workflow includes a unified prompt box in green for positive and red for negative, as well as enable/disable/bypass switches in a dedicated panel for turning Lora's on or off, as well as clipping positive and negative prompt individually. 
The workflow also includes a custom KSampler tuned to work specifically with the Devil Pony v1.3 model that comes preinstalled, all built and lovingly sculpted by yours truly.
More workflows will be available in future releases.

***RUNNING DEVIL***.

Quite simple actually, for those of you already running a nixified system or NixOS as your main OS, you simply need only pull the main repo or get one of the release tarballs available >> https://github.com/Mephist0phel3s/Devil-Diffusion/releases/tag/Devil-Difusion-v2-Unified and then run:

```
./devil-AMD.sh    #### For AMD GPU's
./devil-NVIDIA.sh #### For NVIDIA GPU's 
```
The initial pull and build will take a bit, but when its done Devil will automatically spawn a new window with your default browser and Devil Diffusion loaded and ready to generate out of the box.


Those of you not running nix or nixos, heres a one-liner that will do both at once, and this should work on ANY nixified Linux system out of the box.
AMD:
```
sudo sh <(curl -L https://nixos.org/nix/install) --daemon && wget https://github.com/Mephist0phel3s/Devil-Diffusion/archive/refs/tags/Devil-Difusion-v2-Unified.tar.gz ; tar -xf Devil-Difusion-v2-Unified.tar.gz && cd Devil-Diffusion-Devil-Difusion-v2-Unified/ ; ./devil-AMD.sh
```
NVIDIA:
```
sudo sh <(curl -L https://nixos.org/nix/install) --daemon && wget https://github.com/Mephist0phel3s/Devil-Diffusion/archive/refs/tags/Devil-Difusion-v2-Unified.tar.gz ; tar -xf Devil-Difusion-v2-Unified.tar.gz && cd Devil-Diffusion-Devil-Difusion-v2-Unified/ ; ./devil-NVIDIA.sh
```


NOTE::: Windows users in particular, you will need wsl enabled, any off the shelf linux distro will probably work but if you are enabling it for the first time i'd suggest using NixOS instead of Ubuntu or something else. 
It work best since this is a nix expression we are using to build Devil Diffusion.
Instructions for enabling WSL can be found here >> https://learn.microsoft.com/en-us/windows/wsl/install
I will add a more comprehensive install guide in the near future when i've had time to sit down and do a full pull and build on a windows machine.

NOTICE::: 
This repo contains an automatic install and pull script for a base model, VAE, and CLIP Vision as well as a few extensions preinstalled to get you working immediately. I may include more in the future as time develops, as the main goal of this repo is to be a feature complete out of the box diffusion model thats ready to generate good images immediately after install. 
Currently the pull phase eats about 14~gb of bandwidth.

NOTICE::: ive not written a script to bypass this yet but it will be available in the future. For now though, if you wish to skip and use your own models or drops in for the UI, run:
AMD:::
```
$ nix-shell -p binutils stdenv.cc.cc.lib stdenv python312Full
$ touch devil_scripts/FIRSTRUN.flag && pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2 ; pip install -r requirements.txt ; pip install open-clip-torch
```
NVIDIA:::
```
$ nix-shell -p binutils stdenv.cc.cc.lib stdenv python312Full

$ touch devil_scripts/FIRSTRUN.flag && pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu126 ; pip install -r requirements.txt ; pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu126
```

***NOTE***
    You need to run the commands after each $ sequentially, theres no one-liner solution for this yet but im working on it.


then run your `NVIDIA` or `AMD` script and it will install the UI bare bones without pulling down preconfigured models.
More models are available for free download @ https://civitai.com && https://huggingface.co/

After, you can continue to just use the NVIDIA or AMD script to spawn the server without needing to run the prior command again.

For my NixOS bros, add a desktopfile to your main config at /etc/nixos/configuration.nix under system packages for AMD like:
```
  (pkgs.writeShellApplication {
    name = "Devil-Diffusion";
      runtimeInputs = [pkgs.bash];
      text = ''cd /home/<user>/path.to.source.dir/ && ./devil-AMD.sh'';})



   (pkgs.makeDesktopItem {
      name = "Devil Diffusion";
      exec = "Devil-Diffusion";
      icon = "/home/<user>/path.to.source.dir/devil-diffusion-icon.png";

      desktopName = "Devil Diffusion";
      categories = [ "Development" ];
      terminal = true;

    })
```

and for NVIDIA like:
```
  (pkgs.writeShellApplication {
    name = "Devil-Diffusion";
      runtimeInputs = [pkgs.bash];
      text = ''cd /home/<user>/path.to.source.dir/ && ./devil-NVIDIA.sh'';})



   (pkgs.makeDesktopItem {
      name = "Devil Diffusion";
      exec = "Devil-Diffusion";
      icon = "/home/<user>/path.to.source.dir/devil-diffusion-icon.png";

      desktopName = "Devil Diffusion";
      categories = [ "Development" ];
      terminal = true;

    })
```

and run a rebuild after, once done your new desktop file will be available and pointing to the src directory to run nix-shell direct from desktop. 

Now that the intros are out of the way, you can find the Model srcs here >> https://civitai.com/models/1184251/devil-pony-v1 & >> https://huggingface.co/Mephist0phel3s/Devil-Diffusion/tree/main

![Devil Diffusion Mascot - Eve](https://github.com/Mephist0phel3s/Devil-Diffusion/blob/c380efa0a776e74ea43632be844ef1e36ada0c50/devil-diffusion-icon.png)

Here soon i will be writing up full README markdowns and putting them in the Doc folder that will contain tips, example imgs and workflows, and how to overcome obstacles you will certainly encounter if you are just starting out like i was not too long ago. 
But for now i will sub in things i find online that are immensely helpful on their own here on the top level of the README.

Tips for generation:
Camera Angles and Visual Story Telling.

  https://civitai.com/articles/3296/mastering-camera-angles-in-visual-storytelling-a-quick-guide

 Devil Diffusion supports generating images at the following dimensions:

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

