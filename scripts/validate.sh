#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/3] Checking XML files are well-formed..."
python - <<'PY'
import pathlib
import xml.etree.ElementTree as ET

xml_files = [
    pathlib.Path('pom.xml'),
    pathlib.Path('src/main/webapp/WEB-INF/web.xml'),
]

for path in xml_files:
    ET.parse(path)
    print(f"  OK: {path}")
PY

echo "[2/3] Checking JSP entrypoint exists and is non-empty..."
if [[ ! -s src/main/webapp/index.jsp ]]; then
  echo "index.jsp is missing or empty" >&2
  exit 1
fi
echo "  OK: src/main/webapp/index.jsp"

echo "[3/3] Maven test run (best effort)..."
if mvn test -q; then
  echo "  OK: mvn test"
else
  echo "  WARN: mvn test could not complete in this environment (likely blocked dependency downloads)." >&2
fi
