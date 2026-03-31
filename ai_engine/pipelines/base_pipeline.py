"""
Base classes for AI Engine pipelines.
"""

from __future__ import annotations
from abc import ABC, abstractmethod
from typing import Any, Dict, List

class PipelineStep(ABC):
    name: str = "step"

    @abstractmethod
    def run(self, data: Dict[str, Any]) -> Dict[str, Any]:
        raise NotImplementedError

class Pipeline(ABC):

    steps: List[PipelineStep]

    def __init__(self) -> None:
        self.steps = self.build()

    @abstractmethod
    def build(self) -> List[PipelineStep]:
        raise NotImplementedError

    @abstractmethod
    def output_key(self) -> str:
        raise NotImplementedError
