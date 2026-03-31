from __future__ import annotations
from typing import Dict, Any
from app.ai_engine.tools.base_tool import BaseTool
from app.ai_engine.providers.mcphost_client import MCPHostClient

class ScraperTool(BaseTool):
    """Scrapes a URL using the MCP smartscraper tool."""
    name = "scraper"

    def __init__(self, client: MCPHostClient):
        self._client = client

    def execute(self, *, url: str, user_prompt: str, output_schema: Dict[str, Any] | None = None) -> Dict[str, Any]:
        args = {
            "website_url": url,
            "user_prompt": user_prompt,
            "output_schema": output_schema,
        }
        return self._client.call_tool_sync("smartscraper", args)
