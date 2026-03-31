# AI Engine Architecture

## Overview

`ai_engine` is a modular orchestration package that routes user questions to either:
- a language model provider for text generation, or
- a scraping/tooling path for structured extraction workflows.

The architecture is centered around:
- **Orchestration layer** (planning + execution),
- **Provider layer** (LLM providers),
- **Tool layer** (MCP-backed tools),
- **Pipeline layer** (domain-specific extraction pipelines),
- **Models/Utils** (shared data contracts and utility logic).

---

## High-Level Component Diagram

```text
+-------------------------+
|       Client/App        |
|  (calls orchestrate)    |
+-----------+-------------+
            |
            v
+-------------------------------+
| OrchestrationService          |
| - builds Planner + Executor   |
| - checks provider readiness   |
+---------------+---------------+
                |
                v
+-------------------------------+
| OrchestrationPlanner          |
| - requires_scraping()         |
| - guess_preferred_provider()  |
| - outputs Plan                |
+---------------+---------------+
                |
                v
+-------------------------------+
| OrchestrationExecutor         |
| - loads provider from         |
|   ProviderRegistry            |
| - executes action             |
+-------+-----------------------+
        | action = generate_text           action = scrape
        |                                   |
        v                                   v
+---------------------------+      +---------------------------+
| ProviderRegistry          |      | ToolRegistry              |
| -> BaseLLMProvider impls  |      | -> BaseTool impls         |
+-------------+-------------+      +-------------+-------------+
              |                                  |
              v                                  v
+---------------------------+      +---------------------------+
| openai_provider           |      | scraper_tool, fetch_tool, |
| openai_agents_provider    |      | github_tool, filesystem,  |
| mcphost_client            |      | postgres, markdownify     |
+---------------------------+      +---------------------------+

Result path:
Executor -> ExecutionResult (stages + result payload) -> Client/App
```

---

## Package Structure

```text
ai_engine/
  orchestration/
    orchestration_service.py
    planner.py
    executor.py
    routing_rules.py
    orchestration_models.py
  providers/
    base_provider.py
    provider_registry.py
    openai_provider.py
    openai_agents_provider.py
    mcphost_client.py
  tools/
    base_tool.py
    tool_registry.py
    scraper_tool.py
    fetch_tool.py
    github_tool.py
    filesystem_tool.py
    postgres_tool.py
    markdownify_tool.py
  pipelines/
    base_pipeline.py
    pipeline_runner.py
    cv_extraction_pipeline.py
    job_extraction_pipeline.py
  models/
    entities.py
    llm_record.py
    pipeline_models.py
  utils/
    errors.py
    json_tools.py
    text_tools.py
    scraping_keywords.py
```

---

## Execution Flow

1. Caller invokes `OrchestrationService.orchestrate(question=...)`.
2. Service asks planner for a `Plan`:
   - detect scraping intent,
   - select provider,
   - choose action (`scrape` or `generate_text`).
3. Executor validates provider availability via `ProviderRegistry`.
4. Executor dispatches:
   - `generate_text` -> selected provider `.generate_text(...)`
   - `scrape` -> `ToolRegistry.get("scraper").execute(...)`
5. Executor returns `ExecutionResult` with stage-by-stage status and output/error.

---

## Notes

- Registries (`ProviderRegistry`, `ToolRegistry`) are global lookups for runtime components.
- Pipelines are domain-specific workflows that can be orchestrated separately from the core route.
- Current code references imports under `app.ai_engine...`; deployment/runtime should ensure module paths resolve consistently.
