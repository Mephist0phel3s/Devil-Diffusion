 #!/bin/bash

echo -e "Depending on your network speed, this may be a good time to go to the bathroom or grab coffee. First execution takes a bit to pull and build initially."
echo "NOTICE::: This start script will not run again unless you wipe this entire directory, this script can be bypassed in future installs by first running n/touch devil-scripts/FIRSTRUN.flag before running the nix-shell."
echo "The reason i decided to implement auto install model functionality is because they were a pain in the ass to find, i suffered so you dont have to"

echo "Executing first run script"

#echo "DEBUG::: where am i? ==" && $PWD
cd ..
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

if [ ! -d ComfyUI-SaveImageWithMetaData ]; then
    git clone https://github.com/nkchocoai/ComfyUI-SaveImageWithMetaData.git
  else
    cd ComfyUI-SaveImageWithMetaData
    git pull https://github.com/nkchocoai/ComfyUI-SaveImageWithMetaData.git
    cd ..
fi


if [ ! -d comfyui-manager ]; then
    git clone  https://github.com/ltdrdata/ComfyUI-Manager
  else
    git pull https://github.com/ltdrdata/ComfyUI-Manager
fi


if [ ! -d ComfyUI-ImageMetadataExtension ];then
    git clone https://github.com/edelvarden/ComfyUI-ImageMetadataExtension.git
  else cd ComfyUI-ImageMetadataExtension
    git pull https://github.com/edelvarden/ComfyUI-ImageMetadataExtension.git && cd ..
fi


if [ ! -d ComfyUI-Crystools ]; then
    git clone -b AMD https://github.com/crystian/ComfyUI-Crystools.git
    cd ComfyUI-Crystools
    pip install -r requirements.txt
    cd ..
fi


if [ ! -d ComfyUI-Easy-Use ]; then
    git clone https://github.com/yolain/ComfyUI-Easy-Use
    cd ComfyUI-Easy-Use
    pip install -r requirements.txt
  else
    cd ComfyUI-Easy-Use && git pull && cd ..
fi


if [ ! -d ComfyUI-YCYY-LoraInfo ]; then
    git clone https://github.com/ycyy/ComfyUI-YCYY-LoraInfo.git
  else
    cd ComfyUI-YCYY-LoraInfo && git pull && cd ..
fi


#### Move back to src dir
cd ../../src
#echo "$PWD"
#exit 1

mkdir -p tmp
cd tmp

echo "Cloning Devil-Diffusion base model + VAE, CLIP vision."
echo -e "NOTE::: Devilv1.3 base model comes with VAE baked in.n/VAE on the side is a clone of the baked in VAE for ease of access for certain nodes, some nodes really REALLY want a specified VAE for some reason ive yet to figure out."
sleep 5

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

echo "$PWD"
exit 1

#echo "Creating model directories for Stable Diffusion core so python and the default SD models that dont really work dont get patched in over Devil."

mkdir -p ../../data/docs/ipadapter
mkdir -p ../../data/models/ipadapter

cp Devil-Diffusion/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors ../../data/models/clip_vision
cp Devil-Diffusion/CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors ../../data/models/clip_vision
cp Devil-Diffusion/Devil_Pony_v1.3.safetensors ../../data/models/checkpoints
cp Devil-Diffusion/Devil_VAE.safetensors ../../data/models/vae
cp -r IP-Adapter/models/* ../../data/models/ipadapter
cp -r IP-Adapter/sdxl_models/* ../../data/models/ipadapter
cp IP-Adapter/README.md ../../data/docs/ipadapter/README.md
cd ..



echo "$PWD"
exit 1

exec bash -c "./devil-AMD.sh"



