"""
JSON utility helpers.
"""

from __future__ import annotations
import json
from typing import Any, Dict, Optional

def try_parse_json(value: str) -> Optional[Dict[str, Any]]:
    if not value or not value.strip():
        return None
    try:
        return json.loads(value.strip())
    except Exception:
        return None

def normalize_json(obj: Any) -> Dict[str, Any]:
    if isinstance(obj, dict):
        return obj
    if isinstance(obj, str):
        parsed = try_parse_json(obj)
        return parsed if parsed is not None else {"value": obj}
    try:
        return json.loads(json.dumps(obj, default=str))
    except Exception:
        return {"value": str(obj)}
