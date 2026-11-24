"""Generation command for DrSAI."""

from typing import Optional

from drsai.commands.base import BaseCommand
from drsai.core.config import Config
from drsai.core.llm_client import LLMClient
from drsai.core.prompt_builder import PromptBuilder
from drsai.models.schemas import (
    GenerationMode,
    GenerationRequest,
    GenerationResponse,
)
from drsai.validation.quality_checker import QualityChecker
from drsai.validation.scansion import validate_meter


class GenerateCommand(BaseCommand):
    """Command for generating Seuss-style content."""

    def __init__(self, config: Optional[Config] = None):
        super().__init__(config)
        self.llm_client = LLMClient(self.config)
        self.quality_checker = QualityChecker()

    def execute(
        self,
        topic: str,
        mode: GenerationMode = GenerationMode.POEM,
        lines: int = 32,
        age: Optional[int] = None,
        length: str = "short",
    ) -> GenerationResponse:
        """Execute the generation command.

        Implements the meter gate policy:
        - Attempt up to N=3 generations
        - Accept if compliance >= 0.98
        - Degraded accept if compliance in [0.95, 0.98)
        - Fail if best compliance < 0.95
        """
        request = GenerationRequest(
            topic=topic,
            mode=mode,
            lines=lines,
            age=age,
            length=length,
        )

        best_content: Optional[str] = None
        best_score = 0.0
        attempts = 0

        # Generate with retry loop for meter compliance
        for attempt in range(self.config.max_regeneration_attempts):
            attempts = attempt + 1

            # Build prompt based on mode
            prompt = PromptBuilder.build_prompt(
                topic=request.topic,
                mode=request.mode,
                lines=request.lines,
                age=request.age,
                length=request.length,
            )

            # Generate content
            content = self.llm_client.generate_with_retry(prompt, max_retries=2)

            # Validate meter
            meter_score = validate_meter(content)

            # Track best attempt
            if meter_score.compliance > best_score or best_content is None:
                best_score = meter_score.compliance
                best_content = content

            # Check if acceptable
            if meter_score.compliance >= self.config.meter_compliance_target:
                # Perfect compliance - return immediately
                return self._build_response(
                    content=content,
                    mode=mode,
                    meter_score=meter_score.compliance,
                    attempts=attempts,
                )

        # Use best attempt if we have one
        if best_content is None:
            raise RuntimeError("No content generated after all attempts")

        # Check if degraded acceptable
        if best_score >= self.config.meter_compliance_minimum:
            # Degraded accept with warning
            return self._build_response(
                content=best_content,
                mode=mode,
                meter_score=best_score,
                attempts=attempts,
                warning=(
                    f"Meter compliance ({best_score:.0%}) is below target "
                    f"({self.config.meter_compliance_target:.0%}). "
                    "Content may not have perfect Seuss rhythm."
                ),
            )

        # Below minimum - still return but with stronger warning
        return self._build_response(
            content=best_content,
            mode=mode,
            meter_score=best_score,
            attempts=attempts,
            warning=(
                f"⚠️ Meter compliance ({best_score:.0%}) is below minimum "
                f"({self.config.meter_compliance_minimum:.0%}). "
                "Content rhythm may not match Dr. Seuss style. "
                "Try a simpler topic or shorter length."
            ),
        )

    def _build_response(
        self,
        content: str,
        mode: GenerationMode,
        meter_score: float,
        attempts: int,
        warning: Optional[str] = None,
    ) -> GenerationResponse:
        """Build the generation response."""
        # Get full quality check
        quality = self.quality_checker.check_quality(content)

        # Extract moral
        moral = self.quality_checker.extract_moral(content)

        # Generate illustration prompts
        illustration_prompts = PromptBuilder.extract_illustration_scenes(content)

        return GenerationResponse(
            content=content,
            mode=mode,
            meter_score=meter_score,
            quality=quality,
            warning=warning,
            moral=moral,
            illustration_prompts=illustration_prompts,
            generation_attempts=attempts,
        )


def generate(
    topic: str,
    mode: str = "poem",
    lines: int = 32,
    age: Optional[int] = None,
    length: str = "short",
    config: Optional[Config] = None,
) -> GenerationResponse:
    """Convenience function for generating content.

    Args:
        topic: The topic to generate content about
        mode: Generation mode ('poem', 'explain', 'story')
        lines: Number of lines for poem mode (16-48)
        age: Target age for explanation mode
        length: Story length ('short' or 'long')
        config: Optional configuration override

    Returns:
        GenerationResponse with the generated content
    """
    generation_mode = GenerationMode(mode)
    command = GenerateCommand(config)
    return command.execute(
        topic=topic,
        mode=generation_mode,
        lines=lines,
        age=age,
        length=length,
    )
