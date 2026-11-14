#!/usr/bin/env bash
set -euo pipefail

# Only client configuration belongs in the compiled Flutter web bundle.
python3 - <<'PY'
import json
import os
from pathlib import Path
from urllib.parse import urlparse

values = {name: os.environ.get(name, '').strip() for name in (
    'API_BASE_URL', 'SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY'
)}
if any(not value for value in values.values()):
    raise SystemExit('Set API_BASE_URL, SUPABASE_URL, and SUPABASE_PUBLISHABLE_KEY before building')
for name in ('API_BASE_URL', 'SUPABASE_URL'):
    url = urlparse(values[name])
    if url.scheme != 'https' or not url.netloc or url.username or url.password:
        raise SystemExit(f'{name} must be a public HTTPS URL')
if not values['SUPABASE_PUBLISHABLE_KEY'].startswith('sb_publishable_'):
    raise SystemExit('Use a Supabase publishable key, never a server key')
try:
    otp_length = int(os.environ.get('EMAIL_OTP_LENGTH', '8'))
except ValueError:
    raise SystemExit('EMAIL_OTP_LENGTH must be a number between 6 and 10')
if otp_length not in range(6, 11):
    raise SystemExit('EMAIL_OTP_LENGTH must be between 6 and 10')
values['EMAIL_OTP_LENGTH'] = str(otp_length)
Path('.vercel').mkdir(exist_ok=True)
Path('.vercel/aibs-build.json').write_text(json.dumps(values))
PY

if [[ -n "${AIBS_FLUTTER_BIN:-}" ]]; then
  flutter_bin="$AIBS_FLUTTER_BIN"
else
  sdk_dir="$PWD/.vercel/cache/flutter-3.47.7"
  if [[ ! -x "$sdk_dir/bin/flutter" ]]; then
    mkdir -p "$(dirname "$sdk_dir")"
    git clone --depth 1 --branch 3.47.7 https://github.com/flutter/flutter.git "$sdk_dir"
  fi
  flutter_bin="$sdk_dir/bin/flutter"
fi

"$flutter_bin" config --no-analytics
"$flutter_bin" pub get --enforce-lockfile
"$flutter_bin" build web --release --dart-define-from-file=.vercel/aibs-build.json
