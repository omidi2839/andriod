#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from urllib.parse import urlparse
import os
u=os.environ['ALMAS_API_BASE']; p=urlparse(u)
if p.scheme!='https' or not p.hostname or p.username or p.password or p.query or p.fragment or any(c.isspace() for c in u):
    raise SystemExit('ALMAS_API_BASE must be a valid HTTPS base URL without credentials, query or fragment')
PY
