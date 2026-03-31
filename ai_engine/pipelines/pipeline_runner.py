"""
Pipeline runner.
"""

from __future__ import annotations
from typing import Any, Dict
from app.ai_engine.pipelines.base_pipeline import Pipeline

class PipelineRunner:

    def run(self, pipeline: Pipeline, input_data: Dict[str, Any]) -> Dict[str, Any]:
        data = dict(input_data)

        for step in pipeline.steps:
            try:
                output = step.run(data)
                if not isinstance(output, dict):
                    raise ValueError(f"Step '{step.name}' returned non-dict.")
                data.update(output)
            except Exception as exc:
                data["error"] = str(exc)
                data["failed_step"] = step.name
                break

        return {pipeline.output_key(): data}
