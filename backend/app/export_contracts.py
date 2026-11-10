"""Run from backend: uv run python -m app.export_contracts."""

import json
from pathlib import Path

from app.schemas import domain


def contracts() -> dict:
    return {
        name: model.model_json_schema()
        for name, model in vars(domain).items()
        if isinstance(model, type)
        and issubclass(model, domain.Contract)
        and model != domain.Contract
    }


if __name__ == "__main__":
    target = Path(__file__).resolve().parents[2] / "docs" / "api" / "contracts.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        json.dumps(contracts(), indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(target)
