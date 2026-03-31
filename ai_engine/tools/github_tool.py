from __future__ import annotations
from typing import Dict, Any
from app.ai_engine.tools.base_tool import BaseTool
from app.ai_engine.providers.mcphost_client import MCPHostClient

class GitHubTool(BaseTool):
    """GitHub operations via MCP."""
    name = "github"

    def __init__(self, client: MCPHostClient):
        self._client = client

    def execute(self, *, operation: str, repo: str | None = None, path: str | None = None,
                query: str | None = None, **kwargs: Any) -> Dict[str, Any]:
        args = {
            "operation": operation,
            "repo": repo,
            "path": path,
            "query": query,
            **kwargs,
        }
        return self._client.call_tool_sync("github_client", args)
