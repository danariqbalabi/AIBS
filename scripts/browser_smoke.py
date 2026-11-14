"""Headless release smoke against local API, using a fresh isolated anonymous subject."""

import json
import os
import re
import subprocess
import tempfile
import time
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
        deadline = time.monotonic() + 180
        while not page.get_by_role("button", name="Profil", exact=True).count():
            if time.monotonic() > deadline:
                raise AssertionError("Dashboard sections did not become ready")
            retry = page.get_by_role("button", name="Coba lagi", exact=True)
            if retry.count(): retry.click()
            page.wait_for_timeout(500)
        check("isolated anonymous demo reaches authenticated dashboard")
        if os.environ.get("AIBS_TEST_OFFLINE_ONLY") != "1":
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
        if os.environ.get("AIBS_TEST_OFFLINE") == "1":
            def reveal(text):
                locator = page.get_by_text(text, exact=True).or_(page.get_by_role("button", name=re.compile("^" + re.escape(text)))).or_(page.get_by_role("checkbox", name=text, exact=True))
                page.mouse.move(195, 400)
                for _ in range(15):
                    if locator.count() and locator.first.is_visible():
                        return locator.first
                    page.mouse.wheel(0, 250)
                    page.wait_for_timeout(150)
                raise AssertionError("Could not reveal " + text)

            page.get_by_role("button", name="Profil", exact=True).click()
            reveal("Data offline").click()
            page.locator('[role="switch"], [role="checkbox"]').first.click()
            page.wait_for_function("async () => (await caches.keys()).some(n => n.startsWith('aibs-shell-'))", timeout=120000)
            page.wait_for_function("() => navigator.serviceWorker.controller?.state === 'activated'", timeout=120000)
            check("opt-in prepares the static offline shell and account snapshot")
            page.context.set_offline(True)
            page.reload(wait_until="networkidle", timeout=120000)
            semantics()
            page.get_by_text("Offline", exact=False).first.wait_for(timeout=120000)
            check("offline reload restores the same identity and cached history")
            page.get_by_role("button", name="Tambah catatan", exact=True).click()
            page.get_by_role("button", name=re.compile("Catat makan")).click()
            page.get_by_role("textbox", name="Nama makanan", exact=True).click()
            page.keyboard.type("Synthetic offline draft")
            page.get_by_role("button", name="Tutup", exact=True).click()
            page.get_by_role("button", name="Simpan draft", exact=True).click()
            page.get_by_role("button", name="Profil", exact=True).click()
            reveal("Data offline").click()
            reveal("Draft makan").wait_for()
            check("meal draft persists locally while disconnected")
            page.context.set_offline(False)
            reveal("Draft makan").click()
            page.get_by_role("checkbox", name="Sudah dimakan", exact=True).click()
            reveal("Waktu sudah ditinjau").click()
            with page.expect_response(lambda r: r.url.endswith("/commit") and r.status == 200, timeout=120000) as offline_commit:
                reveal("Tinjau & kirim").click()
            check("reviewed offline draft commits online without automatic logging")
            saved_ids = offline_commit.value.json()["food_event_ids"]
            assert len(saved_ids) == 1
            commit_url = offline_commit.value.url
            api_base = commit_url.split("/api/v1/")[0]
            bearer = offline_commit.value.request.header_value("authorization")
            result = page.request.get(api_base + "/api/v1/events?limit=100", headers={"Authorization": bearer})
            assert result.status == 200
            saved = [row for row in result.json()["items"] if row["kind"] == "food" and row["payload"]["name"] == "Synthetic offline draft"]
            assert len(saved) == 1 and saved[0]["id"] == saved_ids[0]
            page.get_by_role("button", name=re.compile("^Draft makan")).wait_for(state="detached")
            check("server contains exactly one saved meal and local draft is removed")

            page.screenshot(path=str(ROOT / "docs/evidence/offline-sync.png"))
        completed = True
    finally:
        if not completed:
            try:
                print(page.evaluate("() => Object.keys(localStorage).filter(k=>k.includes('aibs.offline')).map(k=>{let v=JSON.parse(localStorage[k]); if(typeof v==='string') v=JSON.parse(v); return {enabled:v.enabled===true,profile:!!v.profile,snapshot:!!v.snapshot,drafts:(v.drafts||[]).length}})"), flush=True)
            except Exception:
                pass
            page.screenshot(path=str(Path(tempfile.gettempdir()) / "aibs-offline-failure.png"))
            (Path(tempfile.gettempdir()) / "aibs-offline-aria.txt").write_text(page.locator("body").aria_snapshot(), encoding="utf-8")
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
engine=create_engine(s.database_url.get_secret_value(),hide_parameters=True,connect_args={'connect_timeout':10, 'options':'-c statement_timeout=30000 -c lock_timeout=5000'})
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
        result_path = OUTPUT if completed else OUTPUT.with_name("offline-smoke-incomplete.json")
        result_path.write_text(
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
