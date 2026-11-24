"""Unit tests for the prompt builder."""

import pytest

from drsai.core.prompt_builder import PromptBuilder
from drsai.models.schemas import GenerationMode


class TestPromptBuilder:
    """Tests for PromptBuilder class."""

    def test_build_poem_prompt(self):
        """Test building a poem prompt."""
        prompt = PromptBuilder.build_poem_prompt("recursion", lines=24)

        assert "recursion" in prompt
        assert "24" in prompt
        assert "anapestic tetrameter" in prompt.lower()
        assert "rhyme" in prompt.lower()

    def test_build_poem_prompt_custom_lines(self):
        """Test poem prompt with custom line count."""
        prompt = PromptBuilder.build_poem_prompt("cats", lines=16)
        assert "16" in prompt

        prompt = PromptBuilder.build_poem_prompt("cats", lines=48)
        assert "48" in prompt

    def test_build_explanation_prompt(self):
        """Test building an explanation prompt."""
        prompt = PromptBuilder.build_explanation_prompt("quantum computing")

        assert "quantum computing" in prompt
        assert "anapestic tetrameter" in prompt.lower()

    def test_build_explanation_prompt_with_age(self):
        """Test explanation prompt with age parameter."""
        prompt = PromptBuilder.build_explanation_prompt("gravity", age=6)
        assert "gravity" in prompt
        assert "young child" in prompt.lower() or "simple" in prompt.lower()

        prompt = PromptBuilder.build_explanation_prompt("gravity", age=16)
        assert "gravity" in prompt

    def test_build_story_prompt_short(self):
        """Test building a short story prompt."""
        prompt = PromptBuilder.build_story_prompt("sharing", length="short")

        assert "sharing" in prompt
        assert "500" in prompt

    def test_build_story_prompt_long(self):
        """Test building a long story prompt."""
        prompt = PromptBuilder.build_story_prompt("kindness", length="long")

        assert "kindness" in prompt
        assert "800" in prompt

    def test_build_illustration_prompt(self):
        """Test building an illustration prompt."""
        prompt = PromptBuilder.build_illustration_prompt("A cat wearing a tall striped hat")

        assert "Dr. Seuss" in prompt or "Seuss" in prompt
        assert "cat" in prompt.lower()
        assert "hat" in prompt.lower()

    def test_build_prompt_poem_mode(self):
        """Test build_prompt with poem mode."""
        prompt = PromptBuilder.build_prompt(
            topic="coding",
            mode=GenerationMode.POEM,
            lines=32,
        )
        assert "coding" in prompt
        assert "32" in prompt

    def test_build_prompt_explain_mode(self):
        """Test build_prompt with explain mode."""
        prompt = PromptBuilder.build_prompt(
            topic="photosynthesis",
            mode=GenerationMode.EXPLAIN,
            age=8,
        )
        assert "photosynthesis" in prompt

    def test_build_prompt_story_mode(self):
        """Test build_prompt with story mode."""
        prompt = PromptBuilder.build_prompt(
            topic="friendship",
            mode=GenerationMode.STORY,
            length="long",
        )
        assert "friendship" in prompt
        assert "800" in prompt

    def test_extract_illustration_scenes(self):
        """Test extracting illustration scenes from content."""
        content = """The cat sat on a mat so tall,
He looked around at one and all.
He jumped and danced with glee so bright,
The children laughed with pure delight!"""

        prompts = PromptBuilder.extract_illustration_scenes(content)

        assert len(prompts) >= 1
        assert len(prompts) <= 5
        assert all("Dr. Seuss" in p or "Seuss" in p for p in prompts)
