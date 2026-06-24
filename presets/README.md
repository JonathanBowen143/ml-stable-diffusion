# Stable Diffusion Presets

Preset files are shell-safe `.env` files loaded by `script/build_and_run.sh`.

Each preset defines the prompt, negative prompt, model resources, step count, seed, output root, compute units, and safety policy for a repeatable local generation run. Generated images and run manifests are written under ignored `dist/runs/`.

List presets:

```bash
./script/build_and_run.sh --list-presets
```

Run one preset:

```bash
./script/build_and_run.sh --preset primerica-social
```

Verify one preset:

```bash
./script/build_and_run.sh --verify --preset smoke
```

Business presets intentionally avoid asking the model to render exact logos, regulated copy, fine print, or readable text. Use generated images as draft backgrounds or concept art, then add compliant text and brand assets through normal design tools.
