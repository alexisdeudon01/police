"""
AI Engine error hierarchy.
"""

class AIEngineError(Exception): pass

class ProviderError(AIEngineError): pass

class ToolError(AIEngineError): pass

class PipelineError(AIEngineError): pass

class OrchestrationError(AIEngineError): pass
