# Local Run Loop

This workspace is Apple's Core ML Stable Diffusion package with local compiled model resources already present under `models/`.

Use the project script for the Codex app and terminal smoke checks:

```bash
./script/build_and_run.sh --verify
```

Install the stable iMac command:

```bash
./script/install_command.sh
```

After installation, `sdctl` is available from any folder through `~/.local/bin`:

```bash
sdctl status
sdctl models
sdctl smoke
```

The default verification runs the `smoke` preset. It uses the local Stable Diffusion v1.4 compiled resources, `cpuAndGPU`, 2 diffusion steps, seed `42`, one image, and writes output to a timestamped folder under:

```text
dist/runs/
```

The smoke run includes `--disable-safety` because a 2-step low-quality image can be rejected by the safety checker even when the pipeline is healthy. Use normal safety settings for real generation runs.

List available presets:

```bash
./script/build_and_run.sh --list-presets
```

Run a business preset:

```bash
./script/build_and_run.sh --preset primerica-social
./script/build_and_run.sh --preset loan-factory-social
./script/build_and_run.sh --preset exp-real-estate-social
```

Every preset run writes:

```text
dist/runs/YYYYMMDDTHHMMSSZ-preset-name/
```

The run folder contains the generated PNG, `run.log`, and `run-manifest.txt` with the prompt, negative prompt, seed, model path, step count, compute units, safety policy, command, and output list.

Run raw `StableDiffusionSample` arguments after `--`:

```bash
./script/build_and_run.sh -- "a clean financial education poster, blue and white, simple vector style" \
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

Preset files live under `presets/`. Business presets intentionally avoid exact logos, regulated copy, readable text, fine print, or people. Use generated images as draft backgrounds or concept art, then add compliant text and brand assets through normal design tools.
