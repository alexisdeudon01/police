"""
Models for orchestration execution.
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

@dataclass(slots=True)
class ExecutionStage:
    stage: str
    status: str
    detail: Optional[str] = None

@dataclass(slots=True)
class ExecutionResult:
    source: Dict[str, Any]
    stages: List[ExecutionStage]
    result: Dict[str, Any]
