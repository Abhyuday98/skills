#!/usr/bin/env bash
# Install the whole headless film toolchain. Idempotent; safe to re-run.
set -euo pipefail

echo "== apt: tmux + ffmpeg"
command -v tmux >/dev/null && command -v ffmpeg >/dev/null || {
  sudo apt-get update -qq && sudo apt-get install -y -qq tmux ffmpeg
}

echo "== asciinema (pipx, falls back to pip --user)"
command -v asciinema >/dev/null || pipx install asciinema 2>/dev/null || pip install --user asciinema

echo "== agg (cast -> gif renderer, single binary)"
if ! command -v agg >/dev/null; then
  ARCH=$(uname -m); case "$ARCH" in aarch64|arm64) A=aarch64;; *) A=x86_64;; esac
  curl -fsSL -o /tmp/agg "https://github.com/asciinema/agg/releases/latest/download/agg-${A}-unknown-linux-gnu"
  chmod +x /tmp/agg && sudo mv /tmp/agg /usr/local/bin/agg
fi

echo "== kokoro-onnx TTS (the good voice; piper was audibly flat)"
python3 -c 'import kokoro_onnx' 2>/dev/null || pip install --user kokoro-onnx soundfile

VOICE_DIR="${VOICE_DIR:-$PWD/voice}"
mkdir -p "$VOICE_DIR"
BASE="https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0"
[ -f "$VOICE_DIR/kokoro-v1.0.onnx" ]  || curl -fsSL -o "$VOICE_DIR/kokoro-v1.0.onnx"  "$BASE/kokoro-v1.0.onnx"
[ -f "$VOICE_DIR/voices-v1.0.bin" ]   || curl -fsSL -o "$VOICE_DIR/voices-v1.0.bin"   "$BASE/voices-v1.0.bin"

echo "== Playwright Chromium (reuse the repo's install when present)"
node -e "require('playwright')" 2>/dev/null || npx --yes playwright install chromium

echo "== sanity"
for t in tmux ffmpeg asciinema agg; do command -v $t >/dev/null && echo "  ok: $t" || echo "  MISSING: $t"; done
python3 - <<'PY'
try:
    import kokoro_onnx, soundfile
    print("  ok: kokoro-onnx + soundfile")
except Exception as e:
    print("  MISSING: kokoro-onnx (", e, ")")
PY
echo "Done. Model files in $VOICE_DIR. Default voice: af_heart at speed 0.95."
