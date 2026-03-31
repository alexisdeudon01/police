import asyncio
from typing import Any, Dict

class MCPHostClient:
    """Wrapper around local MCP stdio client."""
    def __init__(self, stdio_client_cls):
        self._stdio_cls = stdio_client_cls

    async def call_tool(self, tool_name, args):
        client = self._stdio_cls()
        return await client.call_tool(tool_name, args)

    def call_tool_sync(self, tool_name, args):
        return asyncio.run(self.call_tool(tool_name, args))
