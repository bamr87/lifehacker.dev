"""LLM client abstraction for DrSAI."""

import time
from abc import ABC, abstractmethod
from typing import Optional

from drsai.core.config import Config, LLMProvider, get_config
from drsai.utils.errors import ConfigurationError, DrSAIError, GenerationError


class BaseLLMClient(ABC):
    """Abstract base class for LLM clients."""

    def __init__(self, config: Config):
        self.config = config

    @abstractmethod
    def generate(self, prompt: str, max_tokens: Optional[int] = None) -> str:
        """Generate content from the given prompt."""
        pass

    def generate_with_retry(
        self, prompt: str, max_retries: int = 3, max_tokens: Optional[int] = None
    ) -> str:
        """Generate content with retry logic on failure."""
        last_error: Optional[Exception] = None

        for attempt in range(max_retries):
            try:
                return self.generate(prompt, max_tokens)
            except DrSAIError:
                raise  # Don't retry our own errors
            except Exception as e:
                last_error = e
                if attempt < max_retries - 1:
                    time.sleep(2**attempt)  # Exponential backoff
                continue

        raise GenerationError(f"Generation failed after {max_retries} attempts: {last_error}")


class OpenAIClient(BaseLLMClient):
    """OpenAI API client."""

    def __init__(self, config: Config):
        super().__init__(config)
        if not config.openai_api_key:
            raise ConfigurationError(
                "OpenAI API key not found. Set OPENAI_API_KEY environment variable."
            )
        try:
            import openai

            self.client = openai.OpenAI(
                api_key=config.openai_api_key, timeout=config.timeout_seconds
            )
        except ImportError:
            raise ConfigurationError("OpenAI package not installed. Run: pip install openai")

    def generate(self, prompt: str, max_tokens: Optional[int] = None) -> str:
        """Generate content using OpenAI API."""
        try:
            response = self.client.chat.completions.create(
                model=self.config.openai_model,
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are Dr. Seuss, the beloved children's author. "
                            "You write in anapestic tetrameter with wild rhymes, "
                            "invented words, and whimsical creatures. "
                            "Your content is always joyful, memorable, and ends with a moral."
                        ),
                    },
                    {"role": "user", "content": prompt},
                ],
                max_tokens=max_tokens or self.config.max_tokens,
                temperature=self.config.temperature,
            )
            content = response.choices[0].message.content
            if content is None:
                raise GenerationError("OpenAI returned empty content")
            return content.strip()
        except Exception as e:
            if "timeout" in str(e).lower():
                raise GenerationError(
                    f"OpenAI request timed out after {self.config.timeout_seconds}s"
                )
            raise GenerationError(f"OpenAI generation failed: {e}")


class AnthropicClient(BaseLLMClient):
    """Anthropic Claude API client."""

    def __init__(self, config: Config):
        super().__init__(config)
        if not config.anthropic_api_key:
            raise ConfigurationError(
                "Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable."
            )
        try:
            import anthropic

            self.client = anthropic.Anthropic(
                api_key=config.anthropic_api_key, timeout=config.timeout_seconds
            )
        except ImportError:
            raise ConfigurationError("Anthropic package not installed. Run: pip install anthropic")

    def generate(self, prompt: str, max_tokens: Optional[int] = None) -> str:
        """Generate content using Anthropic API."""
        try:
            response = self.client.messages.create(
                model=self.config.anthropic_model,
                max_tokens=max_tokens or self.config.max_tokens,
                system=(
                    "You are Dr. Seuss, the beloved children's author. "
                    "You write in anapestic tetrameter with wild rhymes, "
                    "invented words, and whimsical creatures. "
                    "Your content is always joyful, memorable, and ends with a moral."
                ),
                messages=[{"role": "user", "content": prompt}],
            )
            # Current Claude models can return thinking blocks before the text,
            # so read the reply by block type rather than by position.
            content = "".join(
                block.text for block in response.content if getattr(block, "type", None) == "text"
            )
            return content.strip()
        except Exception as e:
            if "timeout" in str(e).lower():
                raise GenerationError(
                    f"Anthropic request timed out after {self.config.timeout_seconds}s"
                )
            raise GenerationError(f"Anthropic generation failed: {e}")


class XAIClient(BaseLLMClient):
    """xAI (Grok) API client - uses OpenAI-compatible API."""

    XAI_BASE_URL = "https://api.x.ai/v1"

    def __init__(self, config: Config):
        super().__init__(config)
        if not config.xai_api_key:
            raise ConfigurationError("xAI API key not found. Set XAI_API_KEY environment variable.")
        try:
            import openai

            self.client = openai.OpenAI(
                api_key=config.xai_api_key,
                base_url=self.XAI_BASE_URL,
                timeout=config.timeout_seconds,
            )
        except ImportError:
            raise ConfigurationError("OpenAI package not installed. Run: pip install openai")

    def generate(self, prompt: str, max_tokens: Optional[int] = None) -> str:
        """Generate content using xAI API."""
        try:
            response = self.client.chat.completions.create(
                model=self.config.xai_model,
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are Dr. Seuss, the beloved children's author. "
                            "You write in anapestic tetrameter with wild rhymes, "
                            "invented words, and whimsical creatures. "
                            "Your content is always joyful, memorable, and ends with a moral."
                        ),
                    },
                    {"role": "user", "content": prompt},
                ],
                max_tokens=max_tokens or self.config.max_tokens,
                temperature=self.config.temperature,
            )
            content = response.choices[0].message.content
            if content is None:
                raise GenerationError("xAI returned empty content")
            return content.strip()
        except Exception as e:
            if "timeout" in str(e).lower():
                raise GenerationError(f"xAI request timed out after {self.config.timeout_seconds}s")
            raise GenerationError(f"xAI generation failed: {e}")


class MockLLMClient(BaseLLMClient):
    """Mock LLM client for testing."""

    def __init__(self, config: Config):
        super().__init__(config)
        self._mock_response: Optional[str] = None

    def set_mock_response(self, response: str) -> None:
        """Set the mock response to return."""
        self._mock_response = response

    def generate(self, prompt: str, max_tokens: Optional[int] = None) -> str:
        """Return mock content for testing."""
        if self._mock_response:
            return self._mock_response

        # Default mock poem
        return """The Cat in the Code sat debugging all day,
With functions and loops in a whimsical way.
He typed and he tested with digital glee,
"These bugs," said the Cat, "will not get the best of me!"

He found a null pointer, oh what a fright!
But fixed it with logic, so clever and bright.
The moral, dear friends, as you sit at your screen:
Debug with a smile, keep your code nice and clean!"""


class LLMClient:
    """Unified LLM client that delegates to the appropriate provider."""

    def __init__(self, config: Optional[Config] = None):
        self.config = config or get_config()
        self._client = self._create_client()

    def _create_client(self) -> BaseLLMClient:
        """Create the appropriate LLM client based on configuration."""
        if self.config.llm_provider == LLMProvider.OPENAI:
            return OpenAIClient(self.config)
        elif self.config.llm_provider == LLMProvider.ANTHROPIC:
            return AnthropicClient(self.config)
        elif self.config.llm_provider == LLMProvider.XAI:
            return XAIClient(self.config)
        elif self.config.llm_provider == LLMProvider.MOCK:
            return MockLLMClient(self.config)
        else:
            raise ConfigurationError(f"Unknown LLM provider: {self.config.llm_provider}")

    def generate(self, prompt: str, max_tokens: Optional[int] = None) -> str:
        """Generate content from the given prompt."""
        return self._client.generate(prompt, max_tokens)

    def generate_with_retry(
        self, prompt: str, max_retries: int = 3, max_tokens: Optional[int] = None
    ) -> str:
        """Generate content with retry logic on failure."""
        return self._client.generate_with_retry(prompt, max_retries, max_tokens)


def get_llm_client(config: Optional[Config] = None) -> LLMClient:
    """Get an LLM client instance."""
    return LLMClient(config)
