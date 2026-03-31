"""
Routing rules for provider selection and task classification.
"""

SCRAPING_KEYWORDS = {
    "url", "website", "web page", "webpage",
    "job offer", "job posting", "career page",
    "company page", "linkedin", "scrape", "scraping",
    "extract from", "research company", "search the web",
    "find sources", "markdown"
}

def requires_scraping(question: str) -> bool:
    """Return True if scraping keywords appear in the question."""
    q = question.lower()
    return any(kw in q for kw in SCRAPING_KEYWORDS)

def guess_preferred_provider(
    *,
    question: str,
    prefer_mcp: bool,
    openai_ready: bool,
    mcp_ready: bool
) -> str:
    """Select provider based on readiness and preference."""
    if prefer_mcp and mcp_ready:
        return "openai_agents"
    if openai_ready:
        return "openai"
    if mcp_ready:
        return "openai_agents"
    return "openai"
