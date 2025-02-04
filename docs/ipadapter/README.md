---
tags:
- text-to-image
- stable-diffusion
license: apache-2.0
language:
- en
library_name: diffusers
---

# IP-Adapter Model Card


<div align="center">

[**Project Page**](https://ip-adapter.github.io) **|** [**Paper (ArXiv)**](https://arxiv.org/abs/2308.06721) **|** [**Code**](https://github.com/tencent-ailab/IP-Adapter)
</div>

---


## Introduction

we present IP-Adapter, an effective and lightweight adapter to achieve image prompt capability for the pre-trained text-to-image diffusion models. An IP-Adapter with only 22M parameters can achieve comparable or even better performance to a fine-tuned image prompt model. IP-Adapter can be generalized not only to other custom models fine-tuned from the same base model, but also to controllable generation using existing controllable tools. Moreover, the image prompt can also work well with the text prompt to accomplish multimodal image generation.

![arch](./fig1.png)

## Models

### Image Encoder
- [models/image_encoder](https://huggingface.co/h94/IP-Adapter/tree/main/models/image_encoder): [OpenCLIP-ViT-H-14](https://huggingface.co/laion/CLIP-ViT-H-14-laion2B-s32B-b79K) with 632.08M parameter
- [sdxl_models/image_encoder](https://huggingface.co/h94/IP-Adapter/tree/main/sdxl_models/image_encoder): [OpenCLIP-ViT-bigG-14](https://huggingface.co/laion/CLIP-ViT-bigG-14-laion2B-39B-b160k) with 1844.9M parameter

More information can be found [here](https://laion.ai/blog/giant-openclip/)

### IP-Adapter for SD 1.5
- [ip-adapter_sd15.bin](https://huggingface.co/h94/IP-Adapter/blob/main/models/ip-adapter_sd15.bin): use global image embedding from OpenCLIP-ViT-H-14 as condition
- [ip-adapter_sd15_light.bin](https://huggingface.co/h94/IP-Adapter/blob/main/models/ip-adapter_sd15_light.bin): same as ip-adapter_sd15, but more compatible with text prompt
- [ip-adapter-plus_sd15.bin](https://huggingface.co/h94/IP-Adapter/blob/main/models/ip-adapter-plus_sd15.bin): use patch image embeddings from OpenCLIP-ViT-H-14 as condition, closer to the reference image than ip-adapter_sd15
- [ip-adapter-plus-face_sd15.bin](https://huggingface.co/h94/IP-Adapter/blob/main/models/ip-adapter-plus-face_sd15.bin): same as ip-adapter-plus_sd15, but use cropped face image as condition

### IP-Adapter for SDXL 1.0
- [ip-adapter_sdxl.bin](https://huggingface.co/h94/IP-Adapter/blob/main/sdxl_models/ip-adapter_sdxl.bin): use global image embedding from OpenCLIP-ViT-bigG-14 as condition
- [ip-adapter_sdxl_vit-h.bin](https://huggingface.co/h94/IP-Adapter/blob/main/sdxl_models/ip-adapter_sdxl_vit-h.bin): same as ip-adapter_sdxl, but use OpenCLIP-ViT-H-14
- [ip-adapter-plus_sdxl_vit-h.bin](https://huggingface.co/h94/IP-Adapter/blob/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.bin): use patch image embeddings from OpenCLIP-ViT-H-14 as condition, closer to the reference image than ip-adapter_xl and ip-adapter_sdxl_vit-h
- [ip-adapter-plus-face_sdxl_vit-h.bin](https://huggingface.co/h94/IP-Adapter/blob/main/sdxl_models/ip-adapter-plus-face_sdxl_vit-h.bin): same as ip-adapter-plus_sdxl_vit-h, but use cropped face image as condition
