"""
Executes the routing plan.
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Dict

from ai_engine.providers.provider_registry import ProviderRegistry
from ai_engine.tools.tool_registry import ToolRegistry
from ai_engine.orchestration.orchestration_models import ExecutionStage, ExecutionResult

@dataclass(slots=True)
class ExecuteOptions:
    mcp_server_configs: Dict[str, Any] | None = None

class OrchestrationExecutor:

    def execute(self, plan, options=None) -> ExecutionResult:
        stages = []
        provider = ProviderRegistry.get(plan.provider)

        if not provider or not provider.is_ready:
            error = f"Provider '{plan.provider}' unavailable."
            stages.append(ExecutionStage(stage="execute", status="error", detail=error))
            return ExecutionResult(source={"provider": plan.provider}, stages=stages, result={"error": error})

        try:
            stages.append(ExecutionStage(stage="plan", status="ok", detail=plan.reason))

            if plan.action == "scrape":
                tool = ToolRegistry.get("scraper")
                if not tool:
                    raise RuntimeError("Scraper tool unavailable.")
                result = tool.execute(url=plan.question, user_prompt="Extract structured content")
            else:
                result = provider.generate_text(prompt=plan.question)

            stages.append(ExecutionStage(stage="execute", status="success"))
            return ExecutionResult(source={"provider": provider.name}, stages=stages, result=result)

        except Exception as exc:
            stages.append(ExecutionStage(stage="execute", status="error", detail=str(exc)))
            return ExecutionResult(
                source={"provider": plan.provider},
                stages=stages,
                result={"error": str(exc)}
            )
