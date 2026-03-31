from __future__ import annotations
from typing import Dict, Any
from app.ai_engine.tools.base_tool import BaseTool
from app.ai_engine.providers.mcphost_client import MCPHostClient

class PostgresTool(BaseTool):
    """SQL querying wrapper via MCP."""
    name = "postgres"

    def __init__(self, client: MCPHostClient):
        self._client = client

    def execute(self, *, sql: str, parameters: Dict[str, Any] | None = None) -> Dict[str, Any]:
        args = {"sql": sql, "parameters": parameters or {}}
        return self._client.call_tool_sync("postgres_client", args)
