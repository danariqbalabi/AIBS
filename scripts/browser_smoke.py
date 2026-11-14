"""Headless release smoke against local API, using a fresh isolated anonymous subject."""

import json
import os
import re
import subprocess
import tempfile
from datetime import UTC, datetime
from pathlib import Path
from urllib.parse import urlparse

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
BASE = os.environ.get("AIBS_SMOKE_WEB", "http://127.0.0.1:5180")
OUTPUT = ROOT / "docs/evidence/browser-smoke.json"
created = []
requests = []
checks = []
completed = False
source = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
with sync_playwright() as runtime:
    browser = runtime.chromium.launch(
        executable_path=os.environ.get(
            "AIBS_CHROME", r"C:\Program Files\Google\Chrome\Application\chrome.exe"
        ),
        headless=True,
    )
    page = browser.new_page(viewport={"width": 390, "height": 844})
    page.set_default_timeout(60000)

    def response(result):
        path = urlparse(result.url).path
        if path.startswith("/api/v1/"):
            requests.append(
                {"method": result.request.method, "path": path, "status": result.status}
            )
        if path == "/auth/v1/signup" and result.status == 200:
            user = result.json().get("user", {})
            if user.get("is_anonymous") is True:
                created.append(user["id"])

    page.on("response", response)

    def semantics():
        placeholder = page.locator("flt-semantics-placeholder")
        placeholder.wait_for(state="attached")
        placeholder.evaluate("(element) => element.click()")

    def check(label):
        checks.append(label)
        print("PASS", label, flush=True)

    try:
        page.goto(BASE, wait_until="networkidle", timeout=120000)
        semantics()
        page.get_by_role("button", name="Coba Demo", exact=True).click()
        with page.expect_response(
            lambda r: "/api/v1/dashboard" in r.url and r.status == 200, timeout=120000
        ):
            page.get_by_role("button", name=re.compile("Nadia")).click()
        check("isolated anonymous demo reaches authenticated dashboard")
        with page.expect_response(
            lambda r: "/api/v1/dashboard" in r.url and r.status == 200, timeout=120000
        ):
            page.reload(wait_until="networkidle", timeout=120000)
        semantics()
        check("release browser reload restores the existing session")
        page.get_by_role("button", name="Tambah catatan", exact=True).click()
        page.get_by_role("button", name=re.compile("Catat makan")).click()
        page.get_by_role("textbox", name="Nama makanan", exact=True).click()
        page.keyboard.type("Synthetic readiness meal", delay=30)
        page.get_by_role("button", name="Simpan", exact=True).click()
        page.screenshot(path=str(Path(tempfile.gettempdir()) / "aibs-readiness-time.png"))
        page.get_by_role("checkbox", name=re.compile("Waktu sudah ditinjau")).click()
        with page.expect_response(
            lambda r: r.url.endswith("/commit") and r.status == 200, timeout=120000
        ) as meal_commit:
            page.get_by_role("button", name="Konfirmasi sudah dimakan", exact=True).click()
        check("manual meal review commits through the real backend")
        food_id = meal_commit.value.json()["food_event_ids"][0]
        page.get_by_role("button", name="Ada keluhan", exact=True).click()
        page.get_by_text("Kembung", exact=True).click()
        with page.expect_request(
            lambda r: r.url.endswith("/api/v1/drafts") and r.method == "POST"
        ) as symptom_draft, page.expect_response(
            lambda r: r.url.endswith("/commit") and r.status == 200, timeout=120000
        ):
            page.get_by_role("button", name="Simpan", exact=True).click()
        linked_id = symptom_draft.value.post_data_json["content"]["symptoms"][0]["linked_food_event_id"]
        assert linked_id == food_id
        check("symptom prompt links to the exact saved meal through the backend")
        with page.expect_response(
            lambda r: "/api/v1/events" in r.url and r.status == 200, timeout=120000
        ):
            page.reload(wait_until="networkidle", timeout=120000)
        semantics()
        page.get_by_role("button", name="Jurnal", exact=True).click()
        page.get_by_text("Synthetic readiness meal", exact=False).first.wait_for()
        check("saved meal remains visible in journal after reload")
        screenshot = ROOT / "docs/evidence/browser-journal.png"
        page.screenshot(path=str(screenshot))
        completed = True
    finally:
        browser.close()
        # Only the anonymous UUIDs created by this run are eligible for cleanup.
        assert len(created) <= 3
        if created:
            cleanup = """
import sys,json,httpx
from uuid import UUID
from sqlalchemy import create_engine,delete
from app.core.config import get_settings
from app.models import Base
ids=[UUID(x) for x in json.load(sys.stdin)]
assert 0 < len(ids) <= 3
s=get_settings()
engine=create_engine(s.database_url.get_secret_value(),hide_parameters=True,connect_args={'connect_timeout':10})
with engine.begin() as c:
 for table in reversed(Base.metadata.sorted_tables):
  if 'owner_id' in table.c: c.execute(delete(table).where(table.c.owner_id.in_(ids)))
engine.dispose()
key=s.supabase_service_role_key.get_secret_value()
headers={'apikey':key}
if not key.startswith('sb_secret_'):headers['Authorization']='Bearer '+key
with httpx.Client(timeout=30) as c:
 for owner in ids:
  r=c.delete(str(s.supabase_url).rstrip('/')+'/auth/v1/admin/users/'+str(owner),headers=headers)
  assert r.status_code in (200,204)
print('Cleaned only browser-run synthetic subjects.')
"""
            result = subprocess.run(
                [str(ROOT / "backend/.venv/Scripts/python.exe"), "-B", "-c", cleanup],
                cwd=ROOT / "backend",
                input=json.dumps(created),
                capture_output=True,
                text=True,
            )
            if result.returncode:
                # Preserve only UUIDs for an explicit retry, never sessions or credentials.
                (Path(tempfile.gettempdir()) / "aibs-readiness-cleanup-ids.json").write_text(
                    json.dumps(created)
                )
                raise RuntimeError(
                    "Synthetic subject cleanup needs retry; UUIDs retained in temp file"
                )
            print(result.stdout.strip(), flush=True)
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(
            json.dumps(
                {
                    "web": BASE,
                    "tested_at": datetime.now(UTC).isoformat(),
                    "source_commit": source,
                    "completed": completed,
                    "viewport": "390x844",
                    "checks": checks,
                    "requests": requests,
                    "synthetic_cleanup": True,
                },
                indent=2,
            )
            + "\n"
        )
