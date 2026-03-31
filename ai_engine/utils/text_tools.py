"""
Text normalization utilities.
"""

from __future__ import annotations
from typing import Optional

def clean_text(value: Optional[str]) -> str:
    if not value:
        return ""
    return "\n".join(
        line.strip() for line in value.strip().splitlines()
        if line.strip()
    )

def truncate(value: str, limit: int = 500) -> str:
    if len(value) <= limit:
        return value
    return value[:limit].rstrip() + "..."
