"""
High-level orchestration service.
"""

from __future__ import annotations
from typing import Any, Dict, Optional

from ai_engine.orchestration.planner import OrchestrationPlanner
from ai_engine.orchestration.executor import OrchestrationExecutor, ExecuteOptions
from ai_engine.orchestration.orchestration_models import ExecutionResult
from ai_engine.providers.provider_registry import ProviderRegistry

class OrchestrationService:

    def __init__(self):
        openai_ready = bool(ProviderRegistry.get("openai"))
        agents_ready = bool(ProviderRegistry.get("openai_agents"))
        self._planner = OrchestrationPlanner(openai_ready=openai_ready, agents_ready=agents_ready)
        self._executor = OrchestrationExecutor()

    def orchestrate(self, *, question: str, context=None,
                    preferred_operation=None, mcp_server_configs=None) -> ExecutionResult:
        plan = self._planner.plan(
            question=question,
            context=context,
            preferred_operation=preferred_operation
        )
        options = ExecuteOptions(mcp_server_configs=mcp_server_configs)
        return self._executor.execute(plan, options)
