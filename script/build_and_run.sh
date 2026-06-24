#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="StableDiffusionSample"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_RESOURCE_PATH="$ROOT_DIR/models/coreml-stable-diffusion-v1-4_original_compiled/original/compiled"
DEFAULT_OUTPUT_PATH="$ROOT_DIR/dist/stable-diffusion-smoke"
DEFAULT_PROMPT="a clean blue square app icon with white OCR letters"

if [[ "$MODE" == "run" || "$MODE" == "--debug" || "$MODE" == "debug" || "$MODE" == "--logs" || "$MODE" == "logs" || "$MODE" == "--telemetry" || "$MODE" == "telemetry" || "$MODE" == "--verify" || "$MODE" == "verify" || "$MODE" == "--help" || "$MODE" == "help" ]]; then
  shift || true
else
  MODE="run"
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --product "$APP_NAME"
APP_BINARY="$(swift build --show-bin-path)/$APP_NAME"

default_args=(
  "$DEFAULT_PROMPT"
  --resource-path "$DEFAULT_RESOURCE_PATH"
  --output-path "$DEFAULT_OUTPUT_PATH"
  --step-count 2
  --seed 42
  --image-count 1
  --compute-units cpuAndGPU
  --disable-safety
)

run_app() {
  if [[ "$#" -eq 0 ]]; then
    if [[ ! -d "$DEFAULT_RESOURCE_PATH" ]]; then
      echo "Missing model resources: $DEFAULT_RESOURCE_PATH" >&2
      exit 1
    fi
    mkdir -p "$DEFAULT_OUTPUT_PATH"
    "$APP_BINARY" "${default_args[@]}"
  else
    "$APP_BINARY" "$@"
  fi
}

case "$MODE" in
  run)
    run_app "$@"
    ;;
  --debug|debug)
    if [[ "$#" -eq 0 ]]; then
      lldb -- "$APP_BINARY" "${default_args[@]}"
    else
      lldb -- "$APP_BINARY" "$@"
    fi
    ;;
  --logs|logs)
    run_app "$@" &
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    run_app "$@" &
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    if [[ "$#" -ne 0 ]]; then
      echo "usage: $0 --verify" >&2
      exit 2
    fi
    rm -rf "$DEFAULT_OUTPUT_PATH"
    mkdir -p "$DEFAULT_OUTPUT_PATH"
    run_app
    png_count="$(find "$DEFAULT_OUTPUT_PATH" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')"
    if [[ "$png_count" -lt 1 ]]; then
      echo "Stable Diffusion verification failed: no PNG was written to $DEFAULT_OUTPUT_PATH" >&2
      exit 1
    fi
    find "$DEFAULT_OUTPUT_PATH" -maxdepth 1 -type f -name '*.png' -print
    ;;
  --help|help)
    "$APP_BINARY" --help
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--help] [StableDiffusionSample args...]" >&2
    exit 2
    ;;
esac
