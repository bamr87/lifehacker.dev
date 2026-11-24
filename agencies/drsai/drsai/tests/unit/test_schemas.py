"""Unit tests for Pydantic schemas."""

import pytest
from pydantic import ValidationError

from drsai.models.schemas import (
    GenerationMode,
    GenerationRequest,
    GenerationResponse,
    MeterScore,
    QualityScore,
)


class TestGenerationMode:
    """Tests for GenerationMode enum."""

    def test_mode_values(self):
        """Test mode enum values."""
        assert GenerationMode.POEM.value == "poem"
        assert GenerationMode.EXPLAIN.value == "explain"
        assert GenerationMode.STORY.value == "story"

    def test_mode_from_string(self):
        """Test creating mode from string."""
        assert GenerationMode("poem") == GenerationMode.POEM
        assert GenerationMode("explain") == GenerationMode.EXPLAIN
        assert GenerationMode("story") == GenerationMode.STORY


class TestMeterScore:
    """Tests for MeterScore model."""

    def test_valid_score(self):
        """Test creating valid meter score."""
        score = MeterScore(
            compliance=0.98,
            total_lines=10,
            compliant_lines=9,
            violations=["Line 5 had bad meter"],
            is_acceptable=True,
            is_degraded=False,
        )

        assert score.compliance == 0.98
        assert score.total_lines == 10
        assert score.is_acceptable is True

    def test_compliance_bounds(self):
        """Test compliance value bounds."""
        with pytest.raises(ValidationError):
            MeterScore(compliance=1.5, total_lines=10, compliant_lines=10)

        with pytest.raises(ValidationError):
            MeterScore(compliance=-0.1, total_lines=10, compliant_lines=10)

    def test_default_values(self):
        """Test default values."""
        score = MeterScore(compliance=0.5, total_lines=10, compliant_lines=5)

        assert score.violations == []
        assert score.is_acceptable is False
        assert score.is_degraded is False


class TestGenerationRequest:
    """Tests for GenerationRequest model."""

    def test_valid_request(self):
        """Test creating valid request."""
        request = GenerationRequest(
            topic="recursion",
            mode=GenerationMode.POEM,
            lines=24,
        )

        assert request.topic == "recursion"
        assert request.mode == GenerationMode.POEM
        assert request.lines == 24

    def test_default_values(self):
        """Test default values."""
        request = GenerationRequest(topic="test")

        assert request.mode == GenerationMode.POEM
        assert request.lines == 32
        assert request.age is None
        assert request.length == "short"

    def test_topic_too_long(self):
        """Test topic length validation."""
        with pytest.raises(ValidationError):
            GenerationRequest(topic="x" * 10001)

    def test_topic_empty(self):
        """Test empty topic validation."""
        with pytest.raises(ValidationError):
            GenerationRequest(topic="")

    def test_lines_bounds(self):
        """Test lines value bounds."""
        with pytest.raises(ValidationError):
            GenerationRequest(topic="test", lines=15)

        with pytest.raises(ValidationError):
            GenerationRequest(topic="test", lines=49)


class TestGenerationResponse:
    """Tests for GenerationResponse model."""

    def test_valid_response(self):
        """Test creating valid response."""
        response = GenerationResponse(
            content="The cat in the hat...",
            mode=GenerationMode.POEM,
            meter_score=0.98,
        )

        assert response.content == "The cat in the hat..."
        assert response.mode == GenerationMode.POEM
        assert response.meter_score == 0.98

    def test_default_values(self):
        """Test default values."""
        response = GenerationResponse(
            content="test",
            mode=GenerationMode.POEM,
            meter_score=0.95,
        )

        assert response.quality is None
        assert response.warning is None
        assert response.moral is None
        assert response.illustration_prompts == []
        assert response.generation_attempts == 1

    def test_with_warning(self):
        """Test response with warning."""
        response = GenerationResponse(
            content="test",
            mode=GenerationMode.POEM,
            meter_score=0.95,
            warning="Meter compliance below target",
        )

        assert response.warning == "Meter compliance below target"
