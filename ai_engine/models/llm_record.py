"""
LLM interaction record models.
"""

from __future__ import annotations
from typing import Any, Dict, Optional
from pydantic import BaseModel

class TokenUsage(BaseModel):
    input_tokens: Optional[int] = None
    output_tokens: Optional[int] = None
    total_tokens: Optional[int] = None

class LLMRecord(BaseModel):
    provider: str
    model: str
    prompt: str
    response_text: str
    usage: Optional[TokenUsage] = None
    metadata: Dict[str, Any] = {}
