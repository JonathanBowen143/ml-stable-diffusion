# Local Run Loop

This workspace is Apple's Core ML Stable Diffusion package with local compiled model resources already present under `models/`.

Use the project script for the Codex app and terminal smoke checks:

```bash
./script/build_and_run.sh --verify
```

The default verification uses the local Stable Diffusion v1.4 compiled resources, `cpuAndGPU`, 2 diffusion steps, seed `42`, one image, and writes output to:

```text
dist/stable-diffusion-smoke/
```

The smoke run includes `--disable-safety` because a 2-step low-quality image can be rejected by the safety checker even when the pipeline is healthy. Use normal safety settings for real generation runs.

Run a custom prompt with the same local resources:

```bash
./script/build_and_run.sh "a clean financial education poster, blue and white, simple vector style" \
  --resource-path models/coreml-stable-diffusion-v1-4_original_compiled/original/compiled \
  --output-path dist/custom \
  --step-count 20 \
  --seed 42 \
  --image-count 1 \
  --compute-units cpuAndGPU
```

Useful checks:

```bash
swift test
./script/build_and_run.sh --help
```
