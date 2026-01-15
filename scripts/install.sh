#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

target_dir="${1:-}"
profile="${2:-docker}"

if [[ -z "$target_dir" ]]; then
  echo "Usage: $0 <target-project-dir> [docker|local]" >&2
  exit 1
fi

case "$profile" in
  docker) overlay_file="mcp.docker.opencode.jsonc" ;;
  local) overlay_file="mcp.local.opencode.jsonc" ;;
  *)
    echo "Unknown profile: $profile (use docker or local)" >&2
    exit 1
    ;;
esac

mkdir -p "$target_dir"

ln -sfn "$repo_dir/opencode/base.opencode.jsonc" "$target_dir/opencode.jsonc"
ln -sfn "$repo_dir/opencode/$overlay_file" "$target_dir/opencode.mcp.jsonc"
ln -sfn "$repo_dir/oh-my-opencode/oh-my-opencode.json" "$target_dir/oh-my-opencode.json"

echo "Linked OpenCode configs into $target_dir"
