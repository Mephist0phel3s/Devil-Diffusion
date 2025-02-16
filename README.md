
***RUNNING DEVIL***.


**WINDOWS**
This version is newest, and still under testing and dev but it does build and spawn as expected, some finetuning is needed on my part but it works out of the box:
Grab the exe [here](https://github.com/Mephist0phel3s/Devil-Diffusion/releases/download/Devil-Diffusion-v2.0.4.1/Devil.Diffusion.exe)
or open a normal powershell and run:
```
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Mephist0phel3s/Devil-Diffusion/refs/heads/devil/devil-WIN.ps1").content
```

**NIXOS**
Clone the repo or grab the latest release here:[Devil Release's](https://github.com/Mephist0phel3s/Devil-Diffusion/releases)
CD into the dir containing the repo and run:
```
./devil-AMD.sh    #### For AMD GPU's
./devil-NVIDIA.sh #### For NVIDIA GPU's 
```

**LINUX** (any nixified linux system) 
If you are already nixified, same instructions as above.

If you are not nixified, or dont know what that means, you can read up on Nix as a pkg manager and an OS [here](https://nixos.org/download/)
But the short version is run this with a sudo shell:
```
sudo sh <(curl -L https://nixos.org/nix/install) --daemon
```
and follow the instructions given.

then run:
```
./devil-AMD.sh    #### For AMD GPU's
./devil-NVIDIA.sh #### For NVIDIA GPU's 
```
***A nixify binary is coming soon to do this automatically.***



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

