from __future__ import annotations
from typing import Dict, Any
from ai_engine.tools.base_tool import BaseTool
from ai_engine.providers.mcphost_client import MCPHostClient

class MarkdownifyTool(BaseTool):
    """Converts webpage content into clean markdown."""
    name = "markdownify"

    def __init__(self, client: MCPHostClient):
        self._client = client

    def execute(self, *, url: str) -> Dict[str, Any]:
        return self._client.call_tool_sync("markdownify", {"website_url": url})
