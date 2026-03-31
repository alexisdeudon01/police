from __future__ import annotations
from typing import Dict, Any
from ai_engine.tools.base_tool import BaseTool
from ai_engine.providers.mcphost_client import MCPHostClient

class FetchTool(BaseTool):
    """HTTP fetch wrapper via MCP."""
    name = "fetch"

    def __init__(self, client: MCPHostClient):
        self._client = client

    def execute(self, *, url: str, method: str = "GET",
                headers: Dict[str, Any] | None = None, body: Any = None) -> Dict[str, Any]:
        args = {"url": url, "method": method, "headers": headers, "body": body}
        return self._client.call_tool_sync("fetch_client", args)
