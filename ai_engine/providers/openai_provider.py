from __future__ import annotations
import json, os
from typing import Any, Dict, Optional
from openai import OpenAI
from ai_engine.providers.base_provider import BaseLLMProvider

class OpenAIProvider(BaseLLMProvider):

    def __init__(self, *, api_key=None, model=None, temperature=None, timeout=None):
        self._api_key = api_key or os.getenv("OPENAI_API_KEY")
        self._model = model or os.getenv("OPENAI_MODEL") or "gpt-4o-mini"
        self._temperature = temperature or float(os.getenv("OPENAI_TEMPERATURE", 0))
        self._timeout = timeout or float(os.getenv("OPENAI_TIMEOUT", 60))
        self._client = OpenAI(api_key=self._api_key, timeout=self._timeout)

    @property
    def name(self): return "openai"

    @property
    def is_ready(self): return bool(self._api_key)

    def generate_text(self, *, prompt, system_instruction=None,
                      model=None, temperature=None, max_tokens=None, metadata=None):
        messages = []
        if system_instruction:
            messages.append({"role": "system", "content": system_instruction})
        messages.append({"role": "user", "content": prompt})
        response = self._client.chat.completions.create(
            model=model or self._model,
            messages=messages,
            temperature=self._temperature if temperature is None else temperature,
            max_tokens=max_tokens,
        )
        text = response.choices[0].message.content or ""
        return {
            "provider": self.name,
            "model": model or self._model,
            "text": text,
            "usage": self._extract_usage(response),
        }

    def extract_structured(self, *, content, instructions, target_schema=None):
        schema_hint = f"\nSchema:\n{json.dumps(target_schema, indent=2)}" if target_schema else ""
        prompt = f"{instructions}{schema_hint}\n\nContent:\n{content}"
        response = self._client.chat.completions.create(
            model=self._model,
            messages=[
                {"role": "system", "content": "Return ONLY valid JSON."},
                {"role": "user", "content": prompt},
            ],
            temperature=0,
            response_format={"type": "json_object"},
        )
        text = response.choices[0].message.content or ""
        return {
            "provider": self.name,
            "model": self._model,
            "parsed": self._try_parse_json(text),
            "text": text,
            "usage": self._extract_usage(response),
        }

    @staticmethod
    def _extract_usage(response):
        usage = getattr(response, "usage", None)
        if not usage:
            return {}
        mapping = {
            "prompt_tokens":"input_tokens",
            "completion_tokens":"output_tokens",
            "total_tokens":"total_tokens"
        }
        return {new: getattr(usage, old, None) for old, new in mapping.items()}

    @staticmethod
    def _try_parse_json(value):
        try: return json.loads(value.strip())
        except: return None

    def describe_capabilities(self):
        return {
            "provider": self.name,
            "ready": self.is_ready,
            "model": self._model,
            "supports_tools": False,
            "operations": ["generate_text","extract_structured"]
        }
