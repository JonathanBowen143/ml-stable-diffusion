#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="StableDiffusionSample"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRESETS_DIR="$ROOT_DIR/presets"
DEFAULT_PRESET="smoke"
PRESET="$DEFAULT_PRESET"
OUTPUT_ROOT_OVERRIDE=""
RAW_ARGS=()

if [[ "$MODE" == "run" || "$MODE" == "--debug" || "$MODE" == "debug" || "$MODE" == "--logs" || "$MODE" == "logs" || "$MODE" == "--telemetry" || "$MODE" == "telemetry" || "$MODE" == "--verify" || "$MODE" == "verify" || "$MODE" == "--help" || "$MODE" == "help" || "$MODE" == "--list-presets" || "$MODE" == "list-presets" ]]; then
  shift || true
else
  MODE="run"
fi

usage() {
  cat <<USAGE
usage: $0 [run|--verify|--debug|--logs|--telemetry|--help|--list-presets] [options]

script options:
  --preset <name>         Run a named preset from presets/<name>.env. Default: $DEFAULT_PRESET
  --output-root <path>    Override preset output root. Default comes from preset.
  --                      Pass remaining arguments directly to StableDiffusionSample.

examples:
  $0 --verify
  $0 run --preset primerica-social
  $0 --list-presets
  $0 -- "a blue icon" --resource-path models/coreml-stable-diffusion-v1-4_original_compiled/original/compiled --output-path dist/custom
USAGE
}

list_presets() {
  find "$PRESETS_DIR" -maxdepth 1 -type f -name '*.env' -print | sort | while IFS= read -r preset_path; do
    preset_name="$(basename "$preset_path" .env)"
    preset_description=""
    # shellcheck disable=SC1090
    source "$preset_path"
    printf '%-24s %s\n' "$preset_name" "${PRESET_DESCRIPTION:-}"
  done
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --preset)
      [[ "$#" -ge 2 ]] || { echo "Missing value for --preset" >&2; exit 2; }
      PRESET="$2"
      shift 2
      ;;
    --preset=*)
      PRESET="${1#--preset=}"
      shift
      ;;
    --output-root)
      [[ "$#" -ge 2 ]] || { echo "Missing value for --output-root" >&2; exit 2; }
      OUTPUT_ROOT_OVERRIDE="$2"
      shift 2
      ;;
    --output-root=*)
      OUTPUT_ROOT_OVERRIDE="${1#--output-root=}"
      shift
      ;;
    --list-presets|list-presets)
      MODE="--list-presets"
      shift
      ;;
    --)
      shift
      RAW_ARGS=("$@")
      break
      ;;
    *)
      RAW_ARGS=("$@")
      break
      ;;
  esac
done

if [[ "$MODE" == "--list-presets" || "$MODE" == "list-presets" ]]; then
  list_presets
  exit 0
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --product "$APP_NAME"
APP_BINARY="$(swift build --show-bin-path)/$APP_NAME"

absolute_path() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$ROOT_DIR" "$path"
  fi
}

load_preset() {
  local preset_path="$PRESETS_DIR/$PRESET.env"
  if [[ ! -f "$preset_path" ]]; then
    echo "Unknown preset: $PRESET" >&2
    echo "Available presets:" >&2
    list_presets >&2
    exit 2
  fi

  PRESET_NAME="$PRESET"
  PRESET_DESCRIPTION=""
  PROMPT=""
  NEGATIVE_PROMPT=""
  RESOURCE_PATH=""
  OUTPUT_ROOT="dist/runs"
  STEP_COUNT=20
  SEED=42
  IMAGE_COUNT=1
  COMPUTE_UNITS="cpuAndGPU"
  SCHEDULER="pndm"
  RNG="numpy"
  DISABLE_SAFETY=0
  REDUCE_MEMORY=0
  XL=0
  SD3=0
  EXTRA_ARGS=()

  # shellcheck disable=SC1090
  source "$preset_path"

  [[ -n "$PROMPT" ]] || { echo "Preset $PRESET is missing PROMPT" >&2; exit 2; }
  [[ -n "$RESOURCE_PATH" ]] || { echo "Preset $PRESET is missing RESOURCE_PATH" >&2; exit 2; }

  RESOURCE_PATH="$(absolute_path "$RESOURCE_PATH")"
  if [[ -n "$OUTPUT_ROOT_OVERRIDE" ]]; then
    OUTPUT_ROOT="$OUTPUT_ROOT_OVERRIDE"
  fi
  OUTPUT_ROOT="$(absolute_path "$OUTPUT_ROOT")"

  if [[ ! -d "$RESOURCE_PATH" ]]; then
    echo "Missing model resources for preset $PRESET: $RESOURCE_PATH" >&2
    exit 1
  fi
}

timestamp_utc() {
  date -u '+%Y%m%dT%H%M%SZ'
}

write_manifest() {
  local manifest_path="$1"
  local status="$2"
  shift 2
  local command_args=("$@")

  {
    printf 'timestamp_utc=%s\n' "$RUN_TIMESTAMP"
    printf 'status=%s\n' "$status"
    printf 'preset=%s\n' "$PRESET_NAME"
    printf 'description=%s\n' "$PRESET_DESCRIPTION"
    printf 'resource_path=%s\n' "$RESOURCE_PATH"
    printf 'output_path=%s\n' "$RUN_DIR"
    printf 'prompt=%s\n' "$PROMPT"
    printf 'negative_prompt=%s\n' "$NEGATIVE_PROMPT"
    printf 'step_count=%s\n' "$STEP_COUNT"
    printf 'seed=%s\n' "$SEED"
    printf 'image_count=%s\n' "$IMAGE_COUNT"
    printf 'compute_units=%s\n' "$COMPUTE_UNITS"
    printf 'scheduler=%s\n' "$SCHEDULER"
    printf 'rng=%s\n' "$RNG"
    printf 'disable_safety=%s\n' "$DISABLE_SAFETY"
    printf 'reduce_memory=%s\n' "$REDUCE_MEMORY"
    printf 'xl=%s\n' "$XL"
    printf 'sd3=%s\n' "$SD3"
    printf 'command='
    printf '%q ' "${command_args[@]}"
    printf '\n'
    printf 'outputs=\n'
    find "$RUN_DIR" -maxdepth 1 -type f -name '*.png' -print | sort
  } >"$manifest_path"
}

preset_args=()
RUN_TIMESTAMP=""
RUN_DIR=""

build_preset_args() {
  load_preset
  RUN_TIMESTAMP="$(timestamp_utc)"
  RUN_DIR="$OUTPUT_ROOT/${RUN_TIMESTAMP}-${PRESET_NAME}"
  mkdir -p "$RUN_DIR"

  preset_args=(
    "$PROMPT"
    --resource-path "$RESOURCE_PATH"
    --output-path "$RUN_DIR"
    --step-count "$STEP_COUNT"
    --seed "$SEED"
    --image-count "$IMAGE_COUNT"
    --compute-units "$COMPUTE_UNITS"
    --scheduler "$SCHEDULER"
    --rng "$RNG"
  )

  if [[ -n "$NEGATIVE_PROMPT" ]]; then
    preset_args+=(--negative-prompt "$NEGATIVE_PROMPT")
  fi
  if [[ "$DISABLE_SAFETY" == "1" ]]; then
    preset_args+=(--disable-safety)
  fi
  if [[ "$REDUCE_MEMORY" == "1" ]]; then
    preset_args+=(--reduce-memory)
  fi
  if [[ "$XL" == "1" ]]; then
    preset_args+=(--xl)
  fi
  if [[ "$SD3" == "1" ]]; then
    preset_args+=(--sd3)
  fi
  if [[ "${#EXTRA_ARGS[@]}" -gt 0 ]]; then
    preset_args+=("${EXTRA_ARGS[@]}")
  fi
}

run_preset() {
  build_preset_args
  local manifest_path="$RUN_DIR/run-manifest.txt"
  local command_args=("$APP_BINARY" "${preset_args[@]}")
  write_manifest "$manifest_path" "started" "${command_args[@]}"
  "${command_args[@]}" | tee "$RUN_DIR/run.log"
  write_manifest "$manifest_path" "completed" "${command_args[@]}"
  printf '%s\n' "$RUN_DIR"
}

run_raw() {
  "$APP_BINARY" "${RAW_ARGS[@]}"
}

case "$MODE" in
  run)
    if [[ "${#RAW_ARGS[@]}" -gt 0 ]]; then
      run_raw
    else
      run_preset
    fi
    ;;
  --debug|debug)
    if [[ "${#RAW_ARGS[@]}" -gt 0 ]]; then
      lldb -- "$APP_BINARY" "${RAW_ARGS[@]}"
    else
      build_preset_args
      lldb -- "$APP_BINARY" "${preset_args[@]}"
    fi
    ;;
  --logs|logs)
    if [[ "${#RAW_ARGS[@]}" -gt 0 ]]; then
      run_raw &
    else
      run_preset &
    fi
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    if [[ "${#RAW_ARGS[@]}" -gt 0 ]]; then
      run_raw &
    else
      run_preset &
    fi
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    if [[ "${#RAW_ARGS[@]}" -gt 0 ]]; then
      echo "usage: $0 --verify [--preset <name>] [--output-root <path>]" >&2
      exit 2
    fi
    run_dir="$(run_preset | tail -1)"
    png_count="$(find "$run_dir" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')"
    if [[ "$png_count" -lt 1 ]]; then
      echo "Stable Diffusion verification failed: no PNG was written to $run_dir" >&2
      exit 1
    fi
    find "$run_dir" -maxdepth 1 -type f -name '*.png' -print
    ;;
  --help|help)
    usage
    "$APP_BINARY" --help
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
