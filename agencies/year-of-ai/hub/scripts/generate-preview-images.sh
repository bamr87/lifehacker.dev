#!/usr/bin/env bash
# generate-preview-images — run the zer0-image-generator engine on THIS site
# (the hub's own pages). Member repos are illustrated by the grow tick itself
# (grow-lineage.yml "Illustrate" step, ADR-0008). All behaviour — the
# `provider: auto` ladder, the claude illustration loop, _config.yml
# `preview_images:` — lives in the engine; this is only a locator.
#
#   ./scripts/generate-preview-images.sh --list-missing
#   ./scripts/generate-preview-images.sh -f pages/hub.md --force --verbose
set -euo pipefail
engine="${ZER0_IMAGE_ENGINE:-$(gem contents zer0-image-generator 2>/dev/null | grep -m1 'preview_generator\.py$' || true)}"
[ -n "$engine" ] || { echo "[ERROR] engine not found — gem install zer0-image-generator (or set ZER0_IMAGE_ENGINE)" >&2; exit 1; }
cd "$(dirname "$0")/.."
exec python3 "$engine" "$@"
