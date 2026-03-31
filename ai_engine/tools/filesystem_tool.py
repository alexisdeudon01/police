from __future__ import annotations
from typing import Dict, Any
from ai_engine.tools.base_tool import BaseTool
from ai_engine.providers.mcphost_client import MCPHostClient

class FilesystemTool(BaseTool):
    """Filesystem operations via MCP."""
    name = "filesystem"

    def __init__(self, client: MCPHostClient):
        self._client = client

    def execute(self, *, operation: str, path: str, **kwargs: Any) -> Dict[str, Any]:
        args = {"operation": operation, "path": path, **kwargs}
        return self._client.call_tool_sync("filesystem_client", args)
