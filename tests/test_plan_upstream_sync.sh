#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

source ./scripts/plan_upstream_sync.sh

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$expected" != "$actual" ]]; then
    fail "$message: expected '$expected', got '$actual'"
  fi
}

assert_status() {
  local expected="$1"
  local old_sha="$2"
  local old_version="$3"
  local commits="$4"

  plan_sync "$old_sha" "$old_version" "$commits"
  assert_eq "$expected" "${PLAN_STATUS-}" "unexpected plan status"
}

test_parse_version() {
  local version

  version="$(parse_version $'cmake_minimum_required(VERSION 3.10)\nproject(TelegramBotApi VERSION 9.6 LANGUAGES CXX)\n')"
  assert_eq "9.6" "$version" "parse_version should read the project version"
}

test_parse_version_fails_without_project_line() {
  if parse_version $'project(OtherProject VERSION 1.0 LANGUAGES CXX)\n' >/dev/null 2>&1; then
    fail "parse_version should fail when TelegramBotApi project line is absent"
  fi
}

test_no_upstream_movement_is_noop() {
  assert_status "noop" "old" "9.5" ""
  assert_eq "old" "${PLAN_NEW_SHA-}" "noop plan should keep old sha"
  assert_eq "" "${PLAN_RELEASE_SHA-}" "noop plan should not set release sha"
  assert_eq "" "${PLAN_RELEASE_VERSION-}" "noop plan should not set release version"
}

test_upstream_movement_without_version_change_advances_only() {
  assert_status "advance" "old" "9.5" $'a1 9.5\nb2 9.5'
  assert_eq "b2" "${PLAN_NEW_SHA-}" "advance plan should target head sha"
  assert_eq "" "${PLAN_RELEASE_SHA-}" "advance plan should not set release sha"
  assert_eq "" "${PLAN_RELEASE_VERSION-}" "advance plan should not set release version"
}

test_single_version_change_releases_and_advances() {
  assert_status "release" "old" "9.5" $'a1 9.5\nb2 9.6\nc3 9.6'
  assert_eq "c3" "${PLAN_NEW_SHA-}" "release plan should target latest head sha"
  assert_eq "b2" "${PLAN_RELEASE_SHA-}" "release plan should tag the version bump sha"
  assert_eq "9.6" "${PLAN_RELEASE_VERSION-}" "release plan should expose release version"
}

test_multiple_version_changes_keep_newest_only() {
  assert_status "release" "old" "9.4" $'a1 9.4\nb2 9.5\nc3 9.5\nd4 9.6\ne5 9.6'
  assert_eq "e5" "${PLAN_NEW_SHA-}" "release plan should end at newest head sha"
  assert_eq "d4" "${PLAN_RELEASE_SHA-}" "release plan should use newest version bump sha"
  assert_eq "9.6" "${PLAN_RELEASE_VERSION-}" "release plan should expose newest version"
}

test_release_commit_can_also_be_head() {
  assert_status "release" "old" "9.5" $'a1 9.5\nb2 9.6'
  assert_eq "b2" "${PLAN_NEW_SHA-}" "release head plan should target head sha"
  assert_eq "b2" "${PLAN_RELEASE_SHA-}" "release head plan should tag head sha"
}

main() {
  test_parse_version
  test_parse_version_fails_without_project_line
  test_no_upstream_movement_is_noop
  test_upstream_movement_without_version_change_advances_only
  test_single_version_change_releases_and_advances
  test_multiple_version_changes_keep_newest_only
  test_release_commit_can_also_be_head
  echo "All shell sync planner tests passed"
}

main "$@"
