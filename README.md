
***RUNNING DEVIL***.

Quite simple actually, for those of you already running a nixified system or NixOS as your main OS, you simply need only pull the main repo or get one of the release tarballs available >> [Devil Diffusion V2.0.3](https://github.com/Mephist0phel3s/Devil-Diffusion/releases/tag/Devil-Diffusion-v2.0.3) and then run:

```
./devil-AMD.sh    #### For AMD GPU's
./devil-NVIDIA.sh #### For NVIDIA GPU's 
```

The Src directory contains a directory called data, inside that is where you will put your checkpoints, lora, etc and get your output. 
I seperated it from the source code for both ease of maintenace on the src itself, and user accessibility.

The initial pull and build will take a bit, but when its done Devil will automatically spawn a new window with your default browser and Devil Diffusion loaded and ready to generate out of the box.

Below instructions were found to not work worth a fuck. Im rethinking my approach and will update this in the near future. when i have something reproducible.
~~Those of you not running nix or nixos, heres a one-liner that will do both at once, and this should work on ANY nixified Linux system out of the box.~~

~~AMD:~~
~~sudo sh <(curl -L https://nixos.org/nix/install) --daemon && wget https://github.com/Mephist0phel3s/Devil-Diffusion/archive/refs/tags/Devil-Difusion-v2-Unified.tar.gz ; tar -xf Devil-Difusion-v2-Unified.tar.gz && cd Devil-Diffusion-Devil-Difusion-v2-Unified/ ; ./devil-AMD.sh~~

~~NVIDIA:~~
~~sudo sh <(curl -L https://nixos.org/nix/install) --daemon && wget https://github.com/Mephist0phel3s/Devil-Diffusion/archive/refs/tags/Devil-Difusion-v2-Unified.tar.gz ; tar -xf Devil-Difusion-v2-Unified.tar.gz && cd Devil-Diffusion-Devil-Difusion-v2-Unified/ ; ./devil-NVIDIA.sh~~

~~NOTE::: Windows users in particular, you will need wsl enabled, any off the shelf linux distro will probably work but if you are enabling it for the first time i'd suggest using NixOS instead of Ubuntu or something else.~~
~~It work best since this is a nix expression we are using to build Devil Diffusion.~~
~~Instructions for enabling WSL can be found here >> https://learn.microsoft.com/en-us/windows/wsl/install~~
~~I will add a more comprehensive install guide in the near future when i've had time to sit down and do a full pull and build on a windows machine.~~

NOTICE::: 
This repo contains an automatic install and pull script for a base model, VAE, and CLIP Vision as well as a few extensions preinstalled to get you working immediately. I may include more in the future as time develops, as the main goal of this repo is to be a feature complete out of the box diffusion model thats ready to generate good images immediately after install. 
Currently the pull phase eats about 14~gb of bandwidth.



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

