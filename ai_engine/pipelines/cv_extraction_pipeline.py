"""
CV extraction pipeline.
"""

from __future__ import annotations
from typing import Any, Dict
from ai_engine.pipelines.base_pipeline import Pipeline, PipelineStep
from ai_engine.providers.provider_registry import ProviderRegistry

class ExtractCVFieldsStep(PipelineStep):
    name = "extract_cv_fields"

    def run(self, data: Dict[str, Any]) -> Dict[str, Any]:
        text = data.get("text", "")
        provider = ProviderRegistry.get("openai")
        if not provider or not provider.is_ready:
            raise RuntimeError("OpenAI provider unavailable.")
        instructions = (
            "Extract candidate metadata: name, email, phone, skills, "
            "experience, education, languages."
        )
        result = provider.extract_structured(content=text, instructions=instructions)
        return {"candidate": result.get("parsed", result)}

class CVExtractionPipeline(Pipeline):

    def build(self):
        return [ExtractCVFieldsStep()]

    def output_key(self) -> str:
        return "cv"
