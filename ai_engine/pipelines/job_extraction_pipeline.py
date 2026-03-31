"""
Job extraction pipeline.
"""

from __future__ import annotations
from typing import Any, Dict

from app.ai_engine.pipelines.base_pipeline import Pipeline, PipelineStep
from app.ai_engine.providers.provider_registry import ProviderRegistry
from app.ai_engine.tools.tool_registry import ToolRegistry

class ScrapeJobStep(PipelineStep):
    name = "scrape_job"

    def run(self, data: Dict[str, Any]) -> Dict[str, Any]:
        url = data.get("url")
        if not url:
            return {}
        tool = ToolRegistry.get("scraper")
        if not tool:
            raise RuntimeError("Scraper tool unavailable.")
        result = tool.execute(url=url, user_prompt="Extract readable job text")
        return {"raw_content": result.get("content", result)}

class ExtractJobFieldsStep(PipelineStep):
    name = "extract_job_fields"

    def run(self, data: Dict[str, Any]) -> Dict[str, Any]:
        text = data.get("raw_content", data.get("text", ""))
        provider = ProviderRegistry.get("openai")
        if not provider or not provider.is_ready:
            raise RuntimeError("OpenAI provider unavailable.")
        instructions = (
            "Extract job metadata: title, company, location, salary, "
            "skills, responsibilities, seniority, contract type."
        )
        result = provider.extract_structured(content=text, instructions=instructions)
        return {"job": result.get("parsed", result)}

class JobExtractionPipeline(Pipeline):

    def build(self):
        return [ScrapeJobStep(), ExtractJobFieldsStep()]

    def output_key(self) -> str:
        return "job_posting"
