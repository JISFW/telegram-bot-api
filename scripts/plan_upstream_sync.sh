#!/usr/bin/env bash

set -euo pipefail

parse_version() {
  local contents="${1-}"
  local version

  version="$(printf '%s\n' "$contents" | sed -nE 's/.*project\(TelegramBotApi VERSION ([0-9]+\.[0-9]+).*/\1/p' | head -n 1)"
  if [[ -z "$version" ]]; then
    echo "Unable to parse TelegramBotApi version from CMakeLists.txt" >&2
    return 1
  fi

  printf '%s\n' "$version"
}

plan_sync() {
  local old_sha="$1"
  local old_version="$2"
  local commits_text="${3-}"
  local current_version="$old_version"
  local line sha version

  PLAN_STATUS="noop"
  PLAN_OLD_SHA="$old_sha"
  PLAN_NEW_SHA="$old_sha"
  PLAN_RELEASE_SHA=""
  PLAN_RELEASE_VERSION=""

  if [[ -z "$commits_text" ]]; then
    return 0
  fi

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue

    sha="${line%% *}"
    version="${line#* }"

    PLAN_NEW_SHA="$sha"
    if [[ "$version" != "$current_version" ]]; then
      PLAN_STATUS="release"
      PLAN_RELEASE_SHA="$sha"
      PLAN_RELEASE_VERSION="$version"
      current_version="$version"
    fi
  done <<< "$commits_text"

  if [[ "$PLAN_STATUS" != "release" ]]; then
    PLAN_STATUS="advance"
  fi
}

version_at_commit() {
  local repo_path="$1"
  local sha="$2"
  local contents

  contents="$(git -C "$repo_path" show "${sha}:CMakeLists.txt")"
  parse_version "$contents"
}

collect_commit_versions() {
  local repo_path="$1"
  local old_sha="$2"
  local new_sha="$3"
  local sha version

  git -C "$repo_path" rev-list --reverse "${old_sha}..${new_sha}" | while IFS= read -r sha; do
    [[ -n "$sha" ]] || continue
    version="$(version_at_commit "$repo_path" "$sha")"
    printf '%s %s\n' "$sha" "$version"
  done
}

write_plan_output() {
  local output_path="$1"

  {
    printf 'status=%s\n' "$PLAN_STATUS"
    printf 'old_sha=%s\n' "$PLAN_OLD_SHA"
    printf 'new_sha=%s\n' "$PLAN_NEW_SHA"
    printf 'release_sha=%s\n' "$PLAN_RELEASE_SHA"
    printf 'release_version=%s\n' "$PLAN_RELEASE_VERSION"
  } >> "$output_path"
}

print_plan() {
  printf 'status=%s\n' "$PLAN_STATUS"
  printf 'old_sha=%s\n' "$PLAN_OLD_SHA"
  printf 'new_sha=%s\n' "$PLAN_NEW_SHA"
  printf 'release_sha=%s\n' "$PLAN_RELEASE_SHA"
  printf 'release_version=%s\n' "$PLAN_RELEASE_VERSION"
}

usage() {
  cat <<'EOF'
Usage:
  scripts/plan_upstream_sync.sh --repo-path <path> --old-sha <sha> --new-sha <sha> [--github-output <path>]
EOF
}

main() {
  local repo_path=""
  local old_sha=""
  local new_sha=""
  local github_output=""
  local old_version commit_versions

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo-path)
        repo_path="$2"
        shift 2
        ;;
      --old-sha)
        old_sha="$2"
        shift 2
        ;;
      --new-sha)
        new_sha="$2"
        shift 2
        ;;
      --github-output)
        github_output="$2"
        shift 2
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$repo_path" || -z "$old_sha" || -z "$new_sha" ]]; then
    usage >&2
    return 1
  fi

  old_version="$(version_at_commit "$repo_path" "$old_sha")"
  if [[ "$old_sha" == "$new_sha" ]]; then
    plan_sync "$old_sha" "$old_version" ""
  else
    commit_versions="$(collect_commit_versions "$repo_path" "$old_sha" "$new_sha")"
    plan_sync "$old_sha" "$old_version" "$commit_versions"
  fi

  print_plan
  if [[ -n "$github_output" ]]; then
    write_plan_output "$github_output"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
