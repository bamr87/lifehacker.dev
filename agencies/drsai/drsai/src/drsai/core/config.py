"""Configuration management for DrSAI."""

import os
from enum import Enum
from functools import lru_cache
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from pydantic import BaseModel, Field


class LLMProvider(str, Enum):
    """Supported LLM providers."""

    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    XAI = "xai"  # Grok models
    MOCK = "mock"  # For testing


class Config(BaseModel):
    """DrSAI configuration."""

    # LLM Provider settings
    llm_provider: LLMProvider = Field(default=LLMProvider.OPENAI, description="LLM provider to use")
    openai_api_key: Optional[str] = Field(default=None, description="OpenAI API key")
    anthropic_api_key: Optional[str] = Field(default=None, description="Anthropic API key")
    xai_api_key: Optional[str] = Field(default=None, description="xAI API key")

    # Model settings
    openai_model: str = Field(default="gpt-4o", description="OpenAI model to use")
    anthropic_model: str = Field(default="claude-sonnet-5-5", description="Anthropic model to use")
    xai_model: str = Field(default="grok-3-latest", description="xAI Grok model to use")

    # Generation settings
    max_tokens: int = Field(default=2000, description="Max tokens for generation")
    temperature: float = Field(default=0.8, ge=0.0, le=2.0, description="Generation temperature")
    timeout_seconds: int = Field(default=30, description="API request timeout")

    # Quality settings
    meter_compliance_target: float = Field(
        default=0.98, ge=0.0, le=1.0, description="Target meter compliance"
    )
    meter_compliance_minimum: float = Field(
        default=0.95, ge=0.0, le=1.0, description="Minimum acceptable meter compliance"
    )
    max_regeneration_attempts: int = Field(
        default=3, ge=1, le=5, description="Max attempts to meet meter compliance"
    )

    # Output settings
    verbose: bool = Field(default=False, description="Enable verbose output")

    @classmethod
    def from_env(cls, env_file: Optional[Path] = None) -> "Config":
        """Load configuration from environment variables."""
        if env_file and env_file.exists():
            load_dotenv(env_file)
        else:
            load_dotenv()

        provider_str = os.getenv("DRSAI_LLM_PROVIDER", "openai").lower()
        try:
            provider = LLMProvider(provider_str)
        except ValueError:
            provider = LLMProvider.OPENAI

        return cls(
            llm_provider=provider,
            openai_api_key=os.getenv("OPENAI_API_KEY"),
            anthropic_api_key=os.getenv("ANTHROPIC_API_KEY"),
            xai_api_key=os.getenv("XAI_API_KEY"),
            openai_model=os.getenv("DRSAI_OPENAI_MODEL", "gpt-4o"),
            anthropic_model=os.getenv("DRSAI_ANTHROPIC_MODEL", "claude-sonnet-5-5"),
            xai_model=os.getenv("DRSAI_XAI_MODEL", "grok-3-latest"),
            max_tokens=int(os.getenv("DRSAI_MAX_TOKENS", "2000")),
            temperature=float(os.getenv("DRSAI_TEMPERATURE", "0.8")),
            timeout_seconds=int(os.getenv("DRSAI_TIMEOUT", "30")),
            meter_compliance_target=float(os.getenv("DRSAI_METER_TARGET", "0.98")),
            meter_compliance_minimum=float(os.getenv("DRSAI_METER_MINIMUM", "0.95")),
            max_regeneration_attempts=int(os.getenv("DRSAI_MAX_ATTEMPTS", "3")),
            verbose=os.getenv("DRSAI_VERBOSE", "").lower() in ("1", "true", "yes"),
        )


@lru_cache(maxsize=1)
def get_config() -> Config:
    """Get cached configuration instance."""
    return Config.from_env()
