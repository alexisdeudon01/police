from typing import Dict
from app.ai_engine.tools.base_tool import BaseTool

class ToolRegistry:
    """Global registry for tool instances."""
    _tools: Dict[str, BaseTool] = {}

    @classmethod
    def register(cls, tool: BaseTool) -> None:
        cls._tools[tool.name] = tool

    @classmethod
    def get(cls, name: str) -> BaseTool | None:
        return cls._tools.get(name)

    @classmethod
    def all(cls):
        return dict(cls._tools)
