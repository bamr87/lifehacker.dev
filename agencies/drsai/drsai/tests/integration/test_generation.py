"""Integration tests for content generation."""

import pytest

from drsai.commands.generate import GenerateCommand, generate
from drsai.core.config import Config, LLMProvider
from drsai.models.schemas import GenerationMode
from ..fixtures.corpus_cases import CASES


class TestGenerateCommand:
    """Integration tests for GenerateCommand."""

    @pytest.fixture
    def mock_config(self):
        """Create a mock configuration for testing."""
        return Config(
            llm_provider=LLMProvider.MOCK,
            max_regeneration_attempts=1,
        )

    def test_generate_poem(self, mock_config):
        """Test generating a poem."""
        command = GenerateCommand(mock_config)
        response = command.execute(
            topic="recursion",
            mode=GenerationMode.POEM,
            lines=32,
        )

        assert response.content is not None
        assert len(response.content) > 0
        assert response.mode == GenerationMode.POEM
        assert 0 <= response.meter_score <= 1.0

    @pytest.mark.parametrize("case", CASES, ids=lambda c: c.id)
    def test_generate_against_fixture_corpus(self, mock_config, case):
        """Functional test: run generation pipeline against the example corpus."""
        command = GenerateCommand(mock_config)

        if case.input_file is not None:
            # Mirror CLI --file behavior for integration-level testing
            file_text = case.input_file.read_text(encoding="utf-8")
            topic = f"Transform this content into Dr. Seuss style:\n\n{file_text}"
        else:
            assert case.topic is not None
            topic = case.topic

        response = command.execute(
            topic=topic,
            mode=GenerationMode(case.mode),
            lines=32,
            age=8,
            length="short",
        )

        expected = case.expected_output_text().strip()
        assert response.content.strip() == expected

        if case.expected_moral_contains:
            assert response.moral is not None
            assert case.expected_moral_contains.lower() in response.moral.lower()
        assert response.quality is not None
        assert response.quality.has_moral is True

    def test_generate_explanation(self, mock_config):
        """Test generating an explanation."""
        command = GenerateCommand(mock_config)
        response = command.execute(
            topic="quantum computing",
            mode=GenerationMode.EXPLAIN,
            age=8,
        )

        assert response.content is not None
        assert response.mode == GenerationMode.EXPLAIN

    def test_generate_story(self, mock_config):
        """Test generating a story."""
        command = GenerateCommand(mock_config)
        response = command.execute(
            topic="sharing",
            mode=GenerationMode.STORY,
            length="short",
        )

        assert response.content is not None
        assert response.mode == GenerationMode.STORY

    def test_response_includes_quality(self, mock_config):
        """Test that response includes quality metrics."""
        command = GenerateCommand(mock_config)
        response = command.execute(
            topic="testing",
            mode=GenerationMode.POEM,
        )

        assert response.quality is not None
        assert response.quality.meter_score is not None

    def test_response_includes_illustration_prompts(self, mock_config):
        """Test that response includes illustration prompts."""
        command = GenerateCommand(mock_config)
        response = command.execute(
            topic="adventure",
            mode=GenerationMode.POEM,
        )

        assert response.illustration_prompts is not None
        # May or may not have prompts depending on content


class TestGenerateFunction:
    """Tests for the generate convenience function."""

    @pytest.fixture
    def mock_config(self):
        """Create a mock configuration for testing."""
        return Config(
            llm_provider=LLMProvider.MOCK,
            max_regeneration_attempts=1,
        )

    def test_generate_poem_function(self, mock_config):
        """Test generate function for poem mode."""
        response = generate(
            topic="coding",
            mode="poem",
            lines=24,
            config=mock_config,
        )

        assert response.content is not None
        assert response.mode == GenerationMode.POEM

    def test_generate_explain_function(self, mock_config):
        """Test generate function for explain mode."""
        response = generate(
            topic="gravity",
            mode="explain",
            age=6,
            config=mock_config,
        )

        assert response.content is not None
        assert response.mode == GenerationMode.EXPLAIN

    def test_generate_story_function(self, mock_config):
        """Test generate function for story mode."""
        response = generate(
            topic="friendship",
            mode="story",
            length="long",
            config=mock_config,
        )

        assert response.content is not None
        assert response.mode == GenerationMode.STORY
