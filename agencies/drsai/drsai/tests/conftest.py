"""Pytest configuration and fixtures for DrSAI tests."""

import pytest

from drsai.core.config import Config, LLMProvider, get_config


@pytest.fixture(autouse=True)
def reset_config_cache():
    """Reset the config cache before each test."""
    get_config.cache_clear()
    yield
    get_config.cache_clear()


@pytest.fixture(autouse=True)
def mock_llm_corpus_router(monkeypatch):
    """Route MockLLMClient outputs to our example corpus for deterministic functional tests.

    This keeps tests stable while still exercising the full generation pipeline
    (prompt building -> LLM client -> meter + quality -> response formatting).
    """
    from drsai.core.llm_client import MockLLMClient

    # Local import to avoid import-order surprises
    from .fixtures.corpus_cases import (
        FAMILY_NEWSLETTER,
        NEWSLETTER_SEUSS,
        REENA_POEM,
        validate_corpus_files_exist,
    )

    validate_corpus_files_exist()

    family_text = FAMILY_NEWSLETTER.read_text(encoding="utf-8")
    newsletter_out = NEWSLETTER_SEUSS.read_text(encoding="utf-8").strip()
    reena_out = REENA_POEM.read_text(encoding="utf-8").strip()

    original_generate = MockLLMClient.generate

    def routed_generate(self, prompt: str, max_tokens=None) -> str:  # type: ignore[override]
        # Case: CLI --file on Family newsletter.md (prompt includes the file content)
        if family_text[:50] in prompt or "## Highlights 2025" in prompt:
            return newsletter_out

        # Case: Reena poem example (prompt includes name markers)
        if "Reena" in prompt and "Nubi" in prompt:
            return reena_out

        # Default mock behavior for all other prompts
        return original_generate(self, prompt, max_tokens)

    monkeypatch.setattr(MockLLMClient, "generate", routed_generate)
    yield


@pytest.fixture
def mock_config():
    """Create a mock configuration for testing."""
    return Config(
        llm_provider=LLMProvider.MOCK,
        max_regeneration_attempts=1,
        meter_compliance_target=0.98,
        meter_compliance_minimum=0.95,
    )


@pytest.fixture
def sample_seuss_content():
    """Sample Seuss-style content for testing."""
    return """The Cat in the Code sat debugging all day,
With functions and loops in a whimsical way.
He typed and he tested with digital glee,
"These bugs," said the Cat, "will not get the best of me!"

He found a null pointer, oh what a fright!
But fixed it with logic, so clever and bright.
The moral, dear friends, as you sit at your screen:
Debug with a smile, keep your code nice and clean!"""


@pytest.fixture
def sample_prose():
    """Sample prose (non-Seuss) content for testing."""
    return """This is a regular paragraph of prose.
It does not follow any particular meter.
The sentences are just normal English.
There is no rhyme scheme here at all."""
