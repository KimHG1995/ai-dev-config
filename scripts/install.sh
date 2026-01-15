#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

copy_mode="false"
force_mode="false"

usage() {
  echo "사용법: $0 [--copy] [--force] <프로젝트-디렉터리> [docker|local]" >&2
}

warn_overwrite() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    echo "주의: 기존 파일이 있어 덮어씁니다: $path" >&2
    return 0
  fi
  return 1
}

ensure_not_dir() {
  local path="$1"
  if [[ -d "$path" && ! -L "$path" ]]; then
    echo "오류: 대상 경로가 디렉터리입니다. 파일로 변경 후 다시 실행하세요: $path" >&2
    exit 1
  fi
}

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --copy) copy_mode="true" ;;
    --force) force_mode="true" ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "알 수 없는 옵션: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

target_dir="${1:-}"
profile="${2:-docker}"

if [[ -z "$target_dir" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$target_dir" ]]; then
  echo "대상 디렉터리가 없습니다: $target_dir" >&2
  echo "먼저 생성(예: git clone) 후 다시 실행하세요." >&2
  exit 1
fi

if [[ ! -w "$target_dir" ]]; then
  echo "오류: 대상 디렉터리에 쓰기 권한이 없습니다: $target_dir" >&2
  exit 1
fi

if [[ ! -d "$target_dir/.git" && "$force_mode" != "true" ]]; then
  echo "오류: $target_dir 에서 .git을 찾지 못했습니다 (프로젝트 루트가 맞나요?)" >&2
  echo "--force 옵션으로 강제 진행할 수 있습니다." >&2
  exit 1
elif [[ ! -d "$target_dir/.git" ]]; then
  echo "경고: $target_dir 에서 .git을 찾지 못했습니다 (강제 진행)." >&2
fi

case "$profile" in
  docker) compiled_file="$repo_dir/opencode/compiled/docker.opencode.json" ;;
  local)  compiled_file="$repo_dir/opencode/compiled/local.opencode.json" ;;
  *)
    echo "알 수 없는 프로파일: $profile (docker 또는 local)" >&2
    usage
    exit 1
    ;;
esac

if [[ ! -f "$compiled_file" ]]; then
  echo "컴파일된 설정을 찾을 수 없습니다: $compiled_file" >&2
  echo "build-config 실행 중..." >&2
  mkdir -p "$repo_dir/opencode/compiled"
  if ! command -v node >/dev/null 2>&1; then
    echo "오류: PATH에서 node를 찾을 수 없습니다. Node.js를 설치하거나 다른 환경에서 compiled를 생성하세요." >&2
    exit 1
  fi
  if ! node "$repo_dir/scripts/build-config.mjs"; then
    echo "오류: build-config 실행 실패. 문제를 해결하고 다시 실행하세요." >&2
    exit 1
  fi
fi

if [[ ! -f "$compiled_file" ]]; then
  echo "컴파일된 설정을 찾을 수 없습니다: $compiled_file" >&2
  echo "build-config가 생성해야 하는 경로: $compiled_file" >&2
  echo "기대 파일: opencode/compiled/docker.opencode.json, opencode/compiled/local.opencode.json" >&2
  echo "먼저 compiled 설정을 생성하세요: $repo_dir/opencode/compiled/" >&2
  exit 1
fi

ensure_not_dir "$target_dir/opencode.json"
ensure_not_dir "$target_dir/oh-my-opencode.json"

link_mode="link"
if [[ "$copy_mode" == "true" ]]; then
  link_mode="copy"
  warn_overwrite "$target_dir/opencode.json"
  warn_overwrite "$target_dir/oh-my-opencode.json"
  cp -f "$compiled_file" "$target_dir/opencode.json"
  cp -f "$repo_dir/oh-my-opencode/oh-my-opencode.json" "$target_dir/oh-my-opencode.json"
else
  warn_overwrite "$target_dir/opencode.json"
  warn_overwrite "$target_dir/oh-my-opencode.json"
  if ln -sfn "$compiled_file" "$target_dir/opencode.json" && \
     ln -sfn "$repo_dir/oh-my-opencode/oh-my-opencode.json" "$target_dir/oh-my-opencode.json"; then
    link_mode="link"
  else
    echo "경고: 심볼릭 링크 생성 실패, 복사 모드로 전환합니다." >&2
    rm -f "$target_dir/opencode.json" "$target_dir/oh-my-opencode.json" || true
    link_mode="copy"
    cp -f "$compiled_file" "$target_dir/opencode.json"
    cp -f "$repo_dir/oh-my-opencode/oh-my-opencode.json" "$target_dir/oh-my-opencode.json"
  fi
fi

echo "OpenCode 설정을 $target_dir 에 연결했습니다"
echo "- 모드: $link_mode"
echo "- opencode.json -> $compiled_file"
echo "- oh-my-opencode.json -> $repo_dir/oh-my-opencode/oh-my-opencode.json"
