#!/usr/bin/env bash
set -euo pipefail

PUBSPEC="pubspec.yaml"

usage() {
  echo "Usage: $0 {major|minor|patch|set <version>}"
  exit 1
}

current_version() {
  grep '^version:' "$PUBSPEC" | head -1 | awk '{print $2}'
}

bump() {
  local type=$1
  local ver
  ver=$(current_version)
  local major minor build
  major=$(echo "$ver" | cut -d. -f1)
  minor=$(echo "$ver" | cut -d. -f2)
  build=$(echo "$ver" | cut -d. -f3 | cut -d+ -f1)
  local num
  num=$(echo "$ver" | cut -d+ -f2)

  case "$type" in
    major) major=$((major + 1)); minor=0; build=0 ;;
    minor) minor=$((minor + 1)); build=0 ;;
    patch) build=$((build + 1)) ;;
    *) usage ;;
  esac

  local new_ver="$major.$minor.$build+$((num + 1))"
  sed -i "s/^version: .*/version: $new_ver/" "$PUBSPEC"
  echo "Version bumped: $ver → $new_ver"
}

set_version() {
  local new_ver=$1
  local num
  num=$(grep '^version:' "$PUBSPEC" | head -1 | awk '{print $2}' | cut -d+ -f2)
  sed -i "s/^version: .*/version: $new_ver+$((num + 1))/" "$PUBSPEC"
  echo "Version set to: $new_ver+$((num + 1))"
}

case "${1:-}" in
  major|minor|patch) bump "$1" ;;
  set) set_version "${2:?Version required}" ;;
  *) usage ;;
esac
