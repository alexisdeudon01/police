"""
Orchestration planner.
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Dict, Optional

from app.ai_engine.orchestration.routing_rules import requires_scraping, guess_preferred_provider

@dataclass(slots=True)
class Plan:
    question: str
    provider: str
    action: str
    confidence: float
    reason: str
    context: Dict[str, Any]

class OrchestrationPlanner:
    def __init__(self, *, openai_ready: bool, agents_ready: bool):
        self._openai_ready = openai_ready
        self._agents_ready = agents_ready

    def plan(self, *, question: str, context=None, preferred_operation=None) -> Plan:
        needs_scrape = requires_scraping(question)

        provider = guess_preferred_provider(
            question=question,
            prefer_mcp=needs_scrape,
            openai_ready=self._openai_ready,
            mcp_ready=self._agents_ready
        )

        if preferred_operation:
            action = preferred_operation
            confidence = 0.5
            reason = "User forced operation."
        elif needs_scrape:
            action = "scrape"
            confidence = 0.9
            reason = "Scraping keywords detected."
        else:
            action = "generate_text"
            confidence = 0.8
            reason = "Default LLM use case."

        return Plan(
            question=question,
            provider=provider,
            action=action,
            confidence=confidence,
            reason=reason,
            context=context or {}
        )
