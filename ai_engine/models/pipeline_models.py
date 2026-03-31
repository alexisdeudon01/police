"""
Pipeline execution models.
"""

from __future__ import annotations
from typing import Any, Dict, List, Optional
from pydantic import BaseModel

class PipelineStepResult(BaseModel):
    name: str
    output: Dict[str, Any]
    success: bool = True
    error: Optional[str] = None

class PipelineExecutionResult(BaseModel):
    pipeline_name: str
    steps: List[PipelineStepResult]
    final_output: Dict[str, Any]
