"""Provider generation schema; full request/output validation remains in Pydantic."""

from app.schemas.domain import DraftContent


def draft_generation_schema() -> dict:
    """Project the acyclic draft schema onto Gemini's supported generation subset.

    Pydantic's defaults, UUID format, exclusive numeric bounds, and string/array limits
    are useful API validation rules but are not all accepted by the generation service.
    Inline our local references and omit those provider-side hints. Every returned draft
    still passes the original strict model, including quantities, lengths and card limits.
    """
    source = DraftContent.model_json_schema()
    definitions = source.get("$defs", {})
    supported = {
        "type",
        "required",
        "items",
        "enum",
        "anyOf",
        "minimum",
        "maximum",
        "additionalProperties",
        "description",
    }

    def project(node, references=()):
        if isinstance(node, list):
            return [project(item, references) for item in node]
        if not isinstance(node, dict):
            return node
        if "$ref" in node:
            reference = node["$ref"]
            if not reference.startswith("#/$defs/") or reference in references:
                raise ValueError("Draft generation schema requires acyclic local references")
            return project(definitions[reference.rsplit("/", 1)[1]], (*references, reference))
        result = {}
        for key, value in node.items():
            if key == "properties":
                result[key] = {name: project(field, references) for name, field in value.items()}
            elif key == "format" and value in ("date", "date-time"):
                result[key] = value
            elif key in supported:
                result[key] = project(value, references)
        return result

    return project(source)
