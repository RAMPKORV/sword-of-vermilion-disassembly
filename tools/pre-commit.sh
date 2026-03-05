#!/bin/sh
# pre-commit hook for Sword of Vermilion disassembly
# Runs all lint checks and the bit-perfect ROM verification before each commit.
#
# Installation (from repo root):
#   cp tools/pre-commit.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# To bypass temporarily (not recommended):
#   git commit --no-verify

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "--- pre-commit: running lint checks ---"
node tools/run_checks.js
LINT_EXIT=$?

if [ $LINT_EXIT -ne 0 ]; then
  echo ""
  echo "pre-commit FAILED: lint checks did not pass."
  echo "Fix the issues above and try again."
  exit 1
fi

echo ""
echo "--- pre-commit: verifying bit-perfect ROM ---"
cmd //c verify.bat
VERIFY_EXIT=$?

if [ $VERIFY_EXIT -ne 0 ]; then
  echo ""
  echo "pre-commit FAILED: ROM is not bit-perfect."
  echo "Fix the build and try again. See docs/debugging_verify_failures.md"
  exit 1
fi

echo ""
echo "pre-commit: all checks passed."
exit 0
