"""Small reproducible semantic evaluation, synthetic text only; provider opt-in required."""

import argparse
import json
import time
from datetime import UTC, date, datetime
from pathlib import Path

from app.core.config import get_settings
from app.core.errors import ApiError
from app.integrations.gemini import PROMPT_VERSION, Gemini

CASES = [
    ("negation", "Siang makan ayam kecap. Sore kembung, tapi nggak mual dan nggak muntah."),
    ("only_negative", "Jam 16:30 tidak mual dan tidak muntah. Tidak ada makanan yang saya catat."),
    ("exact_times", "Hari ini makan nasi jam 12:15. Mulai kembung jam 16:30."),
    (
        "ambiguous",
        "Siang makan ayam pakai saus gelap yang saya tidak tahu isinya. "
        "Porsinya tidak tahu. Sore agak kembung.",
    ),
]


def evaluate(settings):
    results = []
    for name, story in CASES:
        start = time.monotonic()
        try:
            content, usage = Gemini(settings).generate(
                "journal_to_draft",
                reference_date=date(2026, 11, 14),
                timezone="Asia/Jakarta",
                text=story,
            )
            symptoms = {x.code: x for x in content.symptoms}
            checks = {
                "schema_valid": True,
                "times_unconfirmed": all(
                    x.time is None or not x.time.confirmed
                    for x in [*content.foods, *content.symptoms]
                ),
            }
            if name in ("negation", "only_negative"):
                checks["negation_preserved"] = all(
                    code in symptoms and not symptoms[code].present
                    for code in ("nausea", "vomiting")
                )
            if name in ("negation", "ambiguous"):
                checks["bloating_present"] = "bloating" in symptoms and symptoms["bloating"].present
            if name == "exact_times":
                checks["separate_clock_times"] = bool(
                    content.foods
                    and content.foods[0].time
                    and content.foods[0].time.occurred_at
                    and content.foods[0].time.occurred_at.hour == 12
                    and content.foods[0].time.occurred_at.minute == 15
                    and "bloating" in symptoms
                    and symptoms["bloating"].time.occurred_at
                    and symptoms["bloating"].time.occurred_at.hour == 16
                    and symptoms["bloating"].time.occurred_at.minute == 30
                )
            if name == "ambiguous":
                checks["portion_not_invented"] = all(
                    x.quantity is None for food in content.foods for x in food.ingredients
                )
            results.append(
                {
                    "case": name,
                    "checks": checks,
                    "passed": all(checks.values()),
                    "usage": usage,
                    "latency_ms": round((time.monotonic() - start) * 1000),
                }
            )
        except ApiError as error:
            results.append({"case": name, "passed": False, "error_code": error.code})
    return {
        "evaluated_at": datetime.now(UTC).isoformat(),
        "model": settings.gemini_model,
        "prompt_version": PROMPT_VERSION,
        "synthetic_only": True,
        "limitations": "Four NLP cases; not a clinical benchmark or photo/device evaluation.",
        "results": results,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--live", action="store_true", help="Permit four real provider calls")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if not args.live:
        parser.error("Use --live to explicitly permit provider requests")
    report = evaluate(get_settings())
    encoded = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    print(encoded)
    raise SystemExit(0 if all(row["passed"] for row in report["results"]) else 1)
