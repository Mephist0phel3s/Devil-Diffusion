 #!/bin/bash
echo -e "Depending on your network speed, this may be a good time to go to the bathroom or grab coffee. First execution takes a bit to pull and build initially."
echo "NOTICE::: This start script will not run again unless you wipe this entire directory, this script can be bypassed in future installs by first running n/touch devil-scripts/FIRSTRUN.flag before running the nix-shell."
echo "The reason i decided to implement auto install model functionality is because they were a pain in the ass to find, i suffered so you dont have to"

echo "Executing first run script"

mkdir -p models ../data/
mkdir -p input ../data/
mkdir -p output ../data/
mkdir -p temp ../data/
mkdir -p custom_nodes ../data/

cp -r models ../data/
cp -r input ../data/
cp -r output ../data/
cp -r temp ../data/
cp -r custom_nodes ../data/
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2
pip install -r requirements.txt
pip install open-clip-torch

cd ../data/custom_nodes #### MV to custom node dir and check for existing extensions.
echo "$PWD"

if [ ! -d comfyui-manager ]; then
    git clone  https://github.com/ltdrdata/ComfyUI-Manager
  else
    git pull https://github.com/ltdrdata/ComfyUI-Manager
fi

if [ ! -d ComfyUI-Crystools ]; then
    git clone https://github.com/crystian/ComfyUI-Crystools.git
    cd ComfyUI-Crystools
    pip install -r requirements.txt
    cd ..
fi


if [ ! -d ComfyUI-Easy-Use ]; then
    git clone https://github.com/yolain/ComfyUI-Easy-Use
    cd ComfyUI-Easy-Use
    pip install -r requirements.txt
  else
    cd ComfyUI-Easy-Use && git pull && pip install -r requirements.txt && cd ..
fi
cd ../..

echo "Cloning Devil-Diffusion base model + VAE, CLIP vision."
echo -e "NOTE::: Devilv1.3 base model comes with VAE baked in.n/VAE on the side is a clone of the baked in VAE for ease of access for certain nodes, some nodes really REALLY want a specified VAE for some reason ive yet to figure out."
sleep 1
mkdir -p tmp
cd tmp
if [ ! -d Devil-Diffusion ]; then
    git-lfs clone https://huggingface.co/Mephist0phel3s/Devil-Diffusion
  else
    cd Devil-Diffusion  && git pull && cd ..
fi

if [ ! -d IP-Adapter ]; then
    git-lfs clone https://huggingface.co/h94/IP-Adapter
  else
    cd IP-Adapter && git pull && cd ..
fi
cd ..

mkdir -p docs/ipadapter
mkdir -p data/models/ipadapter

cp tmp/Devil-Diffusion/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors models/clip_vision
cp tmp/Devil-Diffusion/CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors models/clip_vision
cp tmp/Devil-Diffusion/Devil_Pony_v1.3.safetensors models/checkpoints
cp tmp/Devil-Diffusion/Devil_VAE.safetensors models/vae
cp -r tmp/IP-Adapter/models/* models/ipadapter
cp -r tmp/IP-Adapter/sdxl_models/* models/ipadapter
cp tmp/IP-Adapter/README.md docs/ipadapter/README.md
echo "$PWD"
cd ..


