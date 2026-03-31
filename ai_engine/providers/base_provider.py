from __future__ import annotations
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional

class BaseLLMProvider(ABC):
    """Abstract base class for all LLM providers."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Provider name."""
        raise NotImplementedError

    @property
    @abstractmethod
    def is_ready(self) -> bool:
        """Whether provider is configured."""
        raise NotImplementedError

    @abstractmethod
    def generate_text(self, *, prompt: str,
                      system_instruction: Optional[str] = None,
                      model: Optional[str] = None,
                      temperature: Optional[float] = None,
                      max_tokens: Optional[int] = None,
                      metadata: Optional[Dict[str, Any]] = None
        ) -> Dict[str, Any]:
        """Plain text generation."""
        raise NotImplementedError

    @abstractmethod
    def extract_structured(self, *,
                           content: str,
                           instructions: str,
                           target_schema: Optional[Dict[str, Any]] = None
        ) -> Dict[str, Any]:
        """JSON-mode extraction."""
        raise NotImplementedError

    def run_tool(self, *, tool_name: str, tool_args: Dict[str, Any]) -> Dict[str, Any]:
        """Optional tool execution."""
        raise NotImplementedError(
            f"Provider '{self.name}' does not support tool operations."
        )

    @abstractmethod
    def describe_capabilities(self) -> Dict[str, Any]:
        """Provider capability description."""
        raise NotImplementedError
