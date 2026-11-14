"""Generate a versioned public static-shell manifest after flutter build web."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "build/web"
files = sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file() and
               p.name not in {"offline-assets.js", ".last_build_id", "flutter_service_worker.js"})
digest = hashlib.sha256()
for name in files:
    digest.update(name.encode())
    digest.update((root / name).read_bytes())
(root / "offline-assets.js").write_text(
    "self.AIBS_OFFLINE_VERSION=" + json.dumps(digest.hexdigest()[:20]) + ";\n" +
    "self.AIBS_OFFLINE_ASSETS=" + json.dumps(files) + ";\n", encoding="utf-8")
print("Prepared offline static shell:", len(files), "public assets")
