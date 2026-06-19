#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RTK_BIN=${RTK_BIN:-"$ROOT/target/debug/rtk"}

if [[ ! -x "$RTK_BIN" ]]; then
    echo "rtk binary not found at $RTK_BIN; run cargo build first" >&2
    exit 1
fi

cd "$ROOT"

assert_contains() {
    local case_name=$1
    local output=$2
    local expected=$3
    if [[ "$output" != *"$expected"* ]]; then
        echo "FAIL: $case_name did not contain: $expected" >&2
        echo "$output" >&2
        exit 1
    fi
}

assert_not_contains() {
    local case_name=$1
    local output=$2
    local unexpected=$3
    if [[ "$output" == *"$unexpected"* ]]; then
        echo "FAIL: $case_name unexpectedly contained: $unexpected" >&2
        echo "$output" >&2
        exit 1
    fi
}

run_rtk_pytest() {
    local __output_var=$1
    local __status_var=$2
    shift 2

    local captured
    local exit_status
    set +e
    captured=$("$RTK_BIN" pytest "$@" 2>&1)
    exit_status=$?
    set -e

    printf -v "$__output_var" '%s' "$captured"
    printf -v "$__status_var" '%s' "$exit_status"
}

echo "Compatibility environment: $(python --version 2>&1), $(python -m pytest --version)"

run_rtk_pytest output status tests/fixtures/.pytest-cases/all_pass
[[ $status -eq 0 ]] || { echo "FAIL: all-pass directory exited $status" >&2; exit 1; }
assert_contains "all-pass directory" "$output" "Pytest: 2 passed"
assert_not_contains "all-pass directory" "$output" "No tests collected"

run_rtk_pytest output status --continue-on-collection-errors \
    tests/fixtures/.pytest-cases/partial_import_error
[[ $status -eq 1 ]] || { echo "FAIL: mixed directory exited $status, expected 1" >&2; exit 1; }
assert_contains "mixed directory" "$output" "1 failed, 1 error"
assert_contains "mixed directory" "$output" "test_loadable_failure_is_reported"
assert_contains "mixed directory" "$output" "case_missing_dependency.py"
assert_contains "mixed directory" "$output" "rtk_missing_dependency_partial"

run_rtk_pytest output status tests/fixtures/.pytest-cases/all_import_errors
[[ $status -eq 2 ]] || { echo "FAIL: all-import-error directory exited $status, expected 2" >&2; exit 1; }
assert_not_contains "all-import-error directory" "$output" "No tests collected"
assert_contains "all-import-error directory" "$output" "2 errors"
assert_contains "all-import-error directory" "$output" "case_missing_dependency_one.py"
assert_contains "all-import-error directory" "$output" "rtk_missing_dependency_two"

run_rtk_pytest output status tests/fixtures/.pytest-cases/loader_import_error
[[ $status -eq 4 ]] || { echo "FAIL: loader-import-error directory exited $status, expected 4" >&2; exit 1; }
assert_not_contains "loader-import-error directory" "$output" "No tests collected"
assert_contains "loader-import-error directory" "$output" "Pytest: collection failed"
assert_contains "loader-import-error directory" "$output" "conftest.py"
assert_contains "loader-import-error directory" "$output" "rtk_missing_core_loader_dependency"

run_rtk_pytest output status tests/fixtures/.pytest-cases/transitive_import_error
[[ $status -eq 2 ]] || { echo "FAIL: transitive-import-error directory exited $status, expected 2" >&2; exit 1; }
assert_contains "transitive-import-error directory" "$output" "sample_package/inner.py"
assert_contains "transitive-import-error directory" "$output" "rtk_missing_transitive_dependency"

run_rtk_pytest output status tests/fixtures/.pytest-cases/setup_error
[[ $status -eq 1 ]] || { echo "FAIL: setup-error directory exited $status, expected 1" >&2; exit 1; }
assert_contains "setup-error directory" "$output" "Errors:"
assert_not_contains "setup-error directory" "$output" "Collection errors:"
assert_contains "setup-error directory" "$output" "ERROR at setup"
assert_contains "setup-error directory" "$output" "rtk_missing_setup_dependency"

echo "pytest compatibility scenarios passed"
