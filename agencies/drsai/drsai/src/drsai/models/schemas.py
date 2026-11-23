"""Pydantic models and schemas for DrSAI."""

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class GenerationMode(str, Enum):
    """Available generation modes."""

    POEM = "poem"
    EXPLAIN = "explain"
    STORY = "story"  # Beta feature


class MeterScore(BaseModel):
    """Meter validation score."""

    compliance: float = Field(ge=0.0, le=1.0, description="Meter compliance percentage (0-1)")
    total_lines: int = Field(ge=0, description="Total lines analyzed")
    compliant_lines: int = Field(ge=0, description="Lines with valid anapestic tetrameter")
    violations: list[str] = Field(default_factory=list, description="Lines that violate meter")
    is_acceptable: bool = Field(default=False, description="Whether compliance >= 0.98")
    is_degraded: bool = Field(default=False, description="Whether compliance is in [0.95, 0.98)")


class QualityScore(BaseModel):
    """Overall quality score for generated content."""

    meter_score: MeterScore
    has_rhymes: bool = Field(default=False, description="Whether content has valid rhymes")
    has_moral: bool = Field(default=False, description="Whether content ends with moral/lesson")
    rhyme_pairs: list[tuple[str, str]] = Field(
        default_factory=list, description="Detected rhyme pairs"
    )


class GenerationRequest(BaseModel):
    """Request model for content generation."""

    topic: str = Field(
        min_length=1, max_length=10000, description="Topic to generate content about"
    )
    mode: GenerationMode = Field(default=GenerationMode.POEM, description="Generation mode")
    lines: int = Field(default=32, ge=16, le=48, description="Number of lines for poem mode")
    age: Optional[int] = Field(
        default=None, ge=5, le=95, description="Target age for explanation mode"
    )
    length: str = Field(
        default="short", pattern="^(short|long)$", description="Story length (short=500, long=800)"
    )


class GenerationResponse(BaseModel):
    """Response model for generated content."""

    content: str = Field(description="Generated Seuss-style content")
    mode: GenerationMode = Field(description="Generation mode used")
    meter_score: float = Field(ge=0.0, le=1.0, description="Meter compliance score")
    quality: Optional[QualityScore] = Field(default=None, description="Quality metrics")
    warning: Optional[str] = Field(default=None, description="Warning if meter is degraded")
    moral: Optional[str] = Field(default=None, description="Extracted moral/lesson")
    illustration_prompts: list[str] = Field(
        default_factory=list, description="DALL-E/Midjourney prompts"
    )
    generation_attempts: int = Field(default=1, description="Number of generation attempts")


class ErrorResponse(BaseModel):
    """Error response model."""

    error: str = Field(description="Error code")
    message: str = Field(description="Human-readable error message")
    code: Optional[str] = Field(default=None, description="Detailed error code")
    retry_after: Optional[int] = Field(default=None, description="Seconds to wait before retry")
