from abc import ABC, abstractmethod
from typing import Any, Dict

class BaseTool(ABC):
    """Abstract MCP tool."""

    name: str

    @abstractmethod
    def execute(self, **kwargs: Any) -> Dict[str, Any]:
        """Execute tool with arguments."""
        raise NotImplementedError
