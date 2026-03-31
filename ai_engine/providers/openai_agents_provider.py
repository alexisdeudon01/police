from __future__ import annotations
import json
from typing import Any, Dict
from ai_engine.providers.base_provider import BaseLLMProvider
from ai_engine.tools.tool_registry import ToolRegistry

class OpenAIAgentsProvider(BaseLLMProvider):

    def __init__(self, *, agent_client, model="gpt-4.1-preview"):
        self._client = agent_client
        self._model = model

    @property
    def name(self): return "openai_agents"

    @property
    def is_ready(self): return bool(self._client)

    def generate_text(self, *, prompt, system_instruction=None, **_):
        full = f"{system_instruction}\n{prompt}" if system_instruction else prompt
        return {"provider": self.name, "result": self._client.run_agent(prompt=full)}

    def extract_structured(self, *, content, instructions, target_schema=None):
        prompt = instructions + "\n\nContent:\n" + content
        if target_schema:
            prompt += "\nExpected Schema:\n" + json.dumps(target_schema)
        return {"provider": self.name, "result": self._client.run_agent(prompt=prompt)}

    def run_tool(self, *, tool_name, tool_args):
        tool = ToolRegistry.get(tool_name)
        if not tool:
            raise ValueError(f"Unknown tool {tool_name}")
        return tool.execute(**tool_args)

    def describe_capabilities(self):
        return {
            "provider": self.name,
            "ready": self.is_ready,
            "model": self._model,
            "supports_tools": True,
            "tools": list(ToolRegistry.all().keys())
        }
