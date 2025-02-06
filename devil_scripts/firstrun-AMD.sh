 #!/bin/bash

echo -e "Depending on your network speed, this may be a good time to go to the bathroom or grab coffee. First execution takes a bit to pull and build initially."
echo "NOTICE::: This start script will not run again unless you wipe this entire directory, this script can be bypassed in future installs by first running n/touch devil-scripts/FIRSTRUN.flag before running the nix-shell."
echo "The reason i decided to implement auto install model functionality is because they were a pain in the ass to find, i suffered so you dont have to"

echo "Executing first run script"

#echo "DEBUG::: where am i? ==" && $PWD
cd ..
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2
pip install -r requirements.txt
pip install open-clip-torch

git clone https://github.com/yolain/ComfyUI-Easy-Use custom_nodes/ComfyUI-Easy-Use
cd custom_nodes/ComfyUI-Easy-Use
pip install -r requirements.txt
cd ..
cd ..
git clone https://github.com/ltdrdata/ComfyUI-Manager custom_nodes/comfyui-manager
git clone https://github.com/nkchocoai/ComfyUI-SaveImageWithMetaData.git custom_nodes/ComfyUI-SaveImageWithMetaData
git clone https://github.com/edelvarden/ComfyUI-ImageMetadataExtension.git custom_nodes/ComfyUI-ImageMetadataExtension
git clone -b AMD https://github.com/crystian/ComfyUI-Crystools.git custom_nodes/ComfyUI-Crystools
cd custom_nodes/ComfyUI-Crystools
pip install -r requirements.txt
cd ..
cd ..


#### TODO: this ^^^^ block is here because the first run script breaks something else upstream in the pkg bootstrapping process that happens on the comfyui side.
# If the directories for models and such are present, part of the bootstrapping phase gets skipped and the python shell errors out with
#### ERROR::: "FileNotFoundError: [Errno 2] No such file or directory: '/home/jason/Devil-Diffusion/Devil-Diffusion/custom_nodes'"


mkdir -p tmp
cd tmp
echo "Cloning Devil-Diffusion base model + VAE, CLIP vision."
echo -e "NOTE::: Devilv1.3 base model comes with VAE baked in.n/VAE on the side is a clone of the baked in VAE for ease of access for certain nodes, some nodes really REALLY want a specified VAE for some reason ive yet to figure out."
sleep 5

git clone https://huggingface.co/Mephist0phel3s/Devil-Diffusion
git clone https://huggingface.co/h94/IP-Adapter
#echo "Creating model directories for Stable Diffusion core so python and the default SD models that dont really work dont get patched in over Devil."

mkdir -p ../docs/ipadapter
mkdir -p ../models/ipadapter

cp Devil-Diffusion/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors ../models/clip_vision
cp Devil-Diffusion/CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors ../models/clip_vision
cp Devil-Diffusion/Devil_Pony_v1.3.safetensors ../models/checkpoints
cp Devil-Diffusion/Devil_VAE.safetensors ../models/vae
cp -r IP-Adapter/models/* ../models/ipadapter
cp -r IP-Adapter/sdxl_models/* ../models/ipadapter
cp IP-Adapter/README.md ../docs/ipadapter/README.md



echo "where am i >> $PWD"
cd ..
exec bash -c "./devil-AMD.sh"
exit 1

echo "Done. Cleaning up."
#rm -rf tmp/
echo "Done. Launching Nix-Shell, thank you for using Devil-Diffusion." ; sleep 3


