#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/build/python-runtime"
EXTRAS="${MARKITDOWN_EXTRAS:-docx,pdf,pptx,xlsx,xls,outlook}"

select_python() {
  if [ -n "${PYTHON_BIN:-}" ]; then
    echo "$PYTHON_BIN"
    return 0
  fi

  for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then
        echo "$candidate"
        return 0
      fi
    fi
  done

  return 1
}

SELECTED_PYTHON="$(select_python || true)"

if [ -z "$SELECTED_PYTHON" ]; then
  echo "Python 3.10 or newer is required to build the bundled runtime." >&2
  echo "Install one first, for example: brew install python@3.12" >&2
  exit 1
fi

rm -rf "$RUNTIME_DIR"
mkdir -p "$(dirname "$RUNTIME_DIR")"

"$SELECTED_PYTHON" -m venv --copies "$RUNTIME_DIR"
"$RUNTIME_DIR/bin/python" -m pip install --upgrade pip
"$RUNTIME_DIR/bin/python" -m pip install "$REPOSITORY_ROOT/packages/markitdown[$EXTRAS]"

cat > "$RUNTIME_DIR/runtime-info.txt" <<INFO
Python: $("$RUNTIME_DIR/bin/python" --version 2>&1)
markitdown extras: $EXTRAS
source: $REPOSITORY_ROOT/packages/markitdown
INFO

echo "Bundled Python runtime is ready: $RUNTIME_DIR"
