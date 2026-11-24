"""End-to-end tests for the CLI."""

import re

import pytest
from typer.testing import CliRunner

from drsai.cli import app
from ..fixtures.corpus_cases import FAMILY_NEWSLETTER, NEWSLETTER_SEUSS

runner = CliRunner()


def _normalize(text: str) -> str:
    """Make text comparable across rich Panel wrapping.

    The CLI renders content inside a rich Panel that word-wraps at terminal
    width and adds box-drawing chrome. Since the newsletter corpus moved to
    one-paragraph-per-line markdown, its first "line" is far wider than any
    terminal, so raw substring assertions can never match the rendered
    output. Strip the box-drawing characters and collapse all whitespace so
    assertions compare words in sequence instead of exact wrapping.
    """
    return " ".join(re.sub(r"[─-╿]", " ", text).split())


class TestCLI:
    """End-to-end tests for CLI commands."""

    def test_help(self):
        """Test --help flag."""
        result = runner.invoke(app, ["--help"])

        assert result.exit_code == 0
        assert "DrSAI" in result.stdout
        assert "generate" in result.stdout.lower()

    def test_generate_help(self):
        """Test generate --help flag."""
        result = runner.invoke(app, ["generate", "--help"])

        assert result.exit_code == 0
        assert "topic" in result.stdout.lower()

    def test_version(self):
        """Test --version flag via generate command."""
        result = runner.invoke(app, ["generate", "--version"])

        assert result.exit_code == 0
        assert "DrSAI" in result.stdout or "version" in result.stdout.lower()

    def test_no_args_shows_help(self):
        """Test that no arguments shows help/usage message."""
        result = runner.invoke(app, [])

        # Typer shows usage and returns 0 with no_args_is_help=True
        # (actually returns 2 for missing subcommand in some versions)
        assert result.exit_code in (0, 2)
        assert (
            "drsai" in result.stdout.lower()
            or "generate" in result.stdout.lower()
            or "usage" in result.stdout.lower()
        )

    def test_poem_mode_mock(self):
        """Test poem generation with mock provider."""
        result = runner.invoke(
            app,
            [
                "generate",
                "recursion",
                "--provider",
                "mock",
            ],
        )

        assert result.exit_code == 0
        # Mock provider returns content with "cat" in it
        assert "cat" in result.stdout.lower() or "code" in result.stdout.lower()

    def test_explain_mode_mock(self):
        """Test explanation generation with mock provider."""
        result = runner.invoke(
            app,
            [
                "generate",
                "testing",
                "--mode",
                "explain",
                "--provider",
                "mock",
            ],
        )

        assert result.exit_code == 0

    def test_story_mode_mock(self):
        """Test story generation with mock provider."""
        result = runner.invoke(
            app,
            [
                "generate",
                "adventure",
                "--mode",
                "story",
                "--provider",
                "mock",
            ],
        )

        assert result.exit_code == 0

    def test_generate_from_file_family_newsletter_mock(self):
        """Functional: --file uses Family newsletter.md and returns the newsletter_seuss example."""
        expected = NEWSLETTER_SEUSS.read_text(encoding="utf-8").strip()
        expected_first_line = expected.splitlines()[0].strip()

        result = runner.invoke(
            app,
            [
                "generate",
                "--file",
                str(FAMILY_NEWSLETTER),
                "--mode",
                "poem",
                "--provider",
                "mock",
            ],
        )

        assert result.exit_code == 0
        assert "reading from" in result.stdout.lower()
        assert _normalize(expected_first_line) in _normalize(result.stdout)

    def test_invalid_mode(self):
        """Test invalid mode error."""
        result = runner.invoke(
            app,
            [
                "generate",
                "test",
                "--mode",
                "invalid_mode",
                "--provider",
                "mock",
            ],
        )

        assert result.exit_code == 1
        assert "invalid" in result.stdout.lower()

    def test_verbose_flag(self):
        """Test verbose output."""
        result = runner.invoke(
            app,
            [
                "generate",
                "testing",
                "--provider",
                "mock",
                "--verbose",
            ],
        )

        assert result.exit_code == 0
        # Verbose mode shows metrics
        assert "meter" in result.stdout.lower() or "score" in result.stdout.lower()

    def test_prompts_flag(self):
        """Test --prompts flag."""
        result = runner.invoke(
            app,
            [
                "generate",
                "adventure",
                "--provider",
                "mock",
                "--prompts",
            ],
        )

        assert result.exit_code == 0


class TestCLIValidate:
    """Tests for the validate command."""

    def test_validate_command(self):
        """Test validate command."""
        result = runner.invoke(
            app,
            [
                "validate",
                "The cat in the hat sat on a mat",
            ],
        )

        assert result.exit_code == 0
        assert "meter" in result.stdout.lower() or "compliance" in result.stdout.lower()

    def test_validate_verbose(self):
        """Test validate command with verbose flag."""
        result = runner.invoke(
            app,
            [
                "validate",
                "The cat in the hat sat on a mat",
                "--verbose",
            ],
        )

        assert result.exit_code == 0
        assert "pattern" in result.stdout.lower() or "line" in result.stdout.lower()
