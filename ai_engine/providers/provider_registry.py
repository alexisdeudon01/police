from typing import Dict
from ai_engine.providers.base_provider import BaseLLMProvider

class ProviderRegistry:
    """Global registry for LLM providers."""
    _providers: Dict[str, BaseLLMProvider] = {}

    @classmethod
    def register(cls, provider: BaseLLMProvider) -> None:
        cls._providers[provider.name] = provider

    @classmethod
    def get(cls, name: str) -> BaseLLMProvider | None:
        return cls._providers.get(name)

    @classmethod
    def all(cls) -> Dict[str, BaseLLMProvider]:
        return dict(cls._providers)
