#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"
VENV_DIR="$ROOT_DIR/.venv"

if [ -n "${PYTHON_BIN:-}" ]; then
  SELECTED_PYTHON="$PYTHON_BIN"
else
  SELECTED_PYTHON=""
  for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PY
      then
        SELECTED_PYTHON="$candidate"
        break
      fi
    fi
  done
fi

if [ -z "$SELECTED_PYTHON" ]; then
  echo "Python 3.10 or newer is required for markitdown." >&2
  echo "Install one first, for example: brew install python@3.12" >&2
  exit 1
fi

cd "$ROOT_DIR"

if [ -d "$VENV_DIR" ] && ! "$VENV_DIR/bin/python" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PY
then
  rm -rf "$VENV_DIR"
fi

if [ ! -d "$VENV_DIR" ]; then
  "$SELECTED_PYTHON" -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/python" -m pip install --upgrade pip
"$VENV_DIR/bin/python" -m pip install -e "$REPOSITORY_ROOT/packages/markitdown[all]"

echo "Python environment is ready: $VENV_DIR"
