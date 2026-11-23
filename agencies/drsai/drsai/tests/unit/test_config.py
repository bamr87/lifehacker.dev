"""Unit tests for configuration."""

import os
import pytest

from drsai.core.config import Config, LLMProvider, get_config


class TestConfig:
    """Tests for Config class."""

    def test_default_values(self):
        """Test default configuration values."""
        config = Config()

        assert config.llm_provider == LLMProvider.OPENAI
        assert config.openai_model == "gpt-4o"
        assert config.max_tokens == 2000
        assert config.temperature == 0.8
        assert config.meter_compliance_target == 0.98
        assert config.meter_compliance_minimum == 0.95
        assert config.max_regeneration_attempts == 3

    def test_custom_values(self):
        """Test custom configuration values."""
        config = Config(
            llm_provider=LLMProvider.ANTHROPIC,
            max_tokens=1500,
            temperature=0.5,
            meter_compliance_target=0.95,
        )

        assert config.llm_provider == LLMProvider.ANTHROPIC
        assert config.max_tokens == 1500
        assert config.temperature == 0.5
        assert config.meter_compliance_target == 0.95

    def test_from_env_defaults(self, monkeypatch):
        """Test loading from environment with defaults."""
        # Clear ALL relevant env vars that might be set in .env or environment
        env_vars_to_clear = [
            "DRSAI_LLM_PROVIDER",
            "OPENAI_API_KEY",
            "ANTHROPIC_API_KEY",
            "XAI_API_KEY",
            "DRSAI_MAX_TOKENS",
            "DRSAI_TEMPERATURE",
        ]
        for var in env_vars_to_clear:
            monkeypatch.delenv(var, raising=False)

        # Prevent load_dotenv from reading .env file
        monkeypatch.setattr("drsai.core.config.load_dotenv", lambda *args, **kwargs: None)

        # Clear config cache
        get_config.cache_clear()

        config = Config.from_env()

        assert config.llm_provider == LLMProvider.OPENAI

    def test_from_env_custom(self, monkeypatch):
        """Test loading from environment with custom values."""
        monkeypatch.setenv("DRSAI_LLM_PROVIDER", "anthropic")
        monkeypatch.setenv("DRSAI_MAX_TOKENS", "1000")
        monkeypatch.setenv("DRSAI_TEMPERATURE", "0.5")

        # Clear cache
        get_config.cache_clear()

        config = Config.from_env()

        assert config.llm_provider == LLMProvider.ANTHROPIC
        assert config.max_tokens == 1000
        assert config.temperature == 0.5


class TestLLMProvider:
    """Tests for LLMProvider enum."""

    def test_provider_values(self):
        """Test provider enum values."""
        assert LLMProvider.OPENAI.value == "openai"
        assert LLMProvider.ANTHROPIC.value == "anthropic"
        assert LLMProvider.MOCK.value == "mock"

    def test_provider_from_string(self):
        """Test creating provider from string."""
        assert LLMProvider("openai") == LLMProvider.OPENAI
        assert LLMProvider("anthropic") == LLMProvider.ANTHROPIC
        assert LLMProvider("mock") == LLMProvider.MOCK

    def test_provider_invalid(self):
        """Test invalid provider raises error."""
        with pytest.raises(ValueError):
            LLMProvider("invalid")
