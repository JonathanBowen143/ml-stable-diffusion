# Local Stable Diffusion Notes

This workspace is the direct Apple repository:

`https://github.com/apple/ml-stable-diffusion.git`

The local setup has two ready Core ML model paths:

`models/coreml-stable-diffusion-v1-4_original_compiled/original/compiled`

`models/current-sdxl`

`models/current-sdxl` points to Apple's mixed-bit palettized SDXL base compiled resources from `apple/coreml-stable-diffusion-mixed-bit-palettization` on Hugging Face. It is the current preferred model path because it is newer than v1.4 and materially smaller than raw SDXL.

Use this local control script:

```zsh
cd "/Users/jonathanbowen/Documents/Apple ML Stable Diffusion"
local-tools/sdctl status
local-tools/sdctl models
local-tools/sdctl smoke
local-tools/sdctl generate --model sdxl --steps 30 "a simple product photo of a clean desk on an iMac"
```

Install the stable iMac command:

```zsh
cd "/Users/jonathanbowen/Documents/Apple ML Stable Diffusion"
./script/install_command.sh
```

After installation, `sdctl` is available from any folder through `~/.local/bin`:

```zsh
sdctl status
sdctl models
sdctl smoke
```

Stable Diffusion is useful for image generation and image-to-image transformation. It is not the right tool for OCR, screenshot reading, document reading, or visual question answering. For reading images on this Mac, Apple Vision or a vision-language model is the right lane.
