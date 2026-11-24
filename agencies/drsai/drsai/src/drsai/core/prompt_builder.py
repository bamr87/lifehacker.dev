"""Prompt construction for Seuss-style content generation."""

from typing import Optional

from drsai.models.schemas import GenerationMode


class PromptBuilder:
    """Builds prompts for Seuss-style content generation."""

    # System context for all generations
    SEUSS_PERSONA = """You are Dr. Seuss (Theodor Seuss Geisel), the beloved children's author.
Your writing style is characterized by:
- Anapestic tetrameter: the rhythm "da-da-DUM da-da-DUM da-da-DUM da-da-DUM"
  (two unstressed syllables followed by one stressed, four times per line)
- Wild, creative rhymes (not just simple end-rhymes)
- Invented words, creatures, and places (like Sneetches, Whos, Lorax)
- Whimsical, exaggerated imagery
- Joyful, playful tone suitable for all ages (5-95)
- Clear moral lessons woven naturally into the narrative
- Repetition and memorable phrases

CRITICAL: Every line MUST follow anapestic tetrameter. Count your syllables carefully!
Example perfect lines:
- "The sun did not shine, it was too wet to play" (da-da-DUM da-da-DUM da-da-DUM da-da-DUM)
- "I do not like green eggs and ham" (da-da-DUM da-da-DUM da-da-DUM)
- "Oh the thinks you can think if you only try" (da-da-DUM da-da-DUM da-da-DUM da-da-DUM)"""

    @classmethod
    def build_poem_prompt(cls, topic: str, lines: int = 32) -> str:
        """Build a prompt for poem generation."""
        return f"""{cls.SEUSS_PERSONA}

Write a {lines}-line poem about: "{topic}"

Requirements:
1. EVERY line must follow anapestic tetrameter (da-da-DUM da-da-DUM da-da-DUM da-da-DUM)
2. Use AABB or AABBCCDD rhyme scheme (couplets)
3. Include at least one invented creature, place, or whimsical word
4. End with a clear, uplifting moral or lesson
5. Make it memorable, fun, and suitable for all ages
6. Each line should be its own line (use line breaks)

Write exactly {lines} lines. Begin the poem now:"""

    @classmethod
    def build_explanation_prompt(cls, topic: str, age: Optional[int] = None) -> str:
        """Build a prompt for rhyming explanation."""
        age_guidance = ""
        if age:
            if age <= 8:
                age_guidance = "Use very simple words and concepts a young child would understand. "
            elif age <= 12:
                age_guidance = "Use concepts appropriate for an elementary school student. "
            elif age <= 16:
                age_guidance = "Use concepts appropriate for a middle/high school student. "
            else:
                age_guidance = "You can use more sophisticated vocabulary while keeping it fun. "

        return f"""{cls.SEUSS_PERSONA}

Explain the following topic in a rhyming, whimsical way: "{topic}"

Requirements:
1. Use anapestic tetrameter throughout (da-da-DUM da-da-DUM da-da-DUM da-da-DUM)
2. {age_guidance}Make it understandable and memorable
3. Use analogies, invented creatures, or whimsical comparisons to simplify complex ideas
4. Create rhyming couplets (AABB pattern)
5. End with a clear moral or key takeaway
6. Keep it fun, positive, and engaging
7. Aim for 16-24 lines

Explain "{topic}" in Seuss style now:"""

    @classmethod
    def build_story_prompt(cls, topic: str, length: str = "short") -> str:
        """Build a prompt for story generation."""
        word_count = 500 if length == "short" else 800

        return f"""{cls.SEUSS_PERSONA}

Write a Seuss-style story about: "{topic}"

Requirements:
1. Use anapestic tetrameter throughout
2. Create a narrative arc: beginning (introduce characters/setting),
   middle (conflict/adventure), end (resolution)
3. Include invented characters, creatures, or places with memorable names
4. Use rhyming couplets (AABB pattern)
5. Target length: approximately {word_count} words
6. End with a clear, uplifting moral or lesson
7. Make it magical, memorable, and suitable for all ages

Write the story now:"""

    @classmethod
    def build_illustration_prompt(cls, scene_description: str) -> str:
        """Build a DALL-E/Midjourney prompt for illustrations."""
        return f"""Whimsical Dr. Seuss-style illustration: {scene_description}

Style: Bright primary colors, exaggerated proportions, curved and fantastical shapes,
hand-drawn quality with bold outlines, playful and magical atmosphere,
reminiscent of classic Dr. Seuss book illustrations.

No text in the image. Child-friendly, joyful mood."""

    @classmethod
    def extract_illustration_scenes(cls, content: str) -> list[str]:
        """Extract key scenes from generated content for illustration prompts."""
        lines = content.strip().split("\n")
        scenes = []

        # Extract interesting visual moments (simple heuristic)
        for i, line in enumerate(lines):
            line_lower = line.lower()
            # Look for lines with visual/action words
            visual_keywords = [
                "sat",
                "stood",
                "ran",
                "flew",
                "jumped",
                "danced",
                "looked",
                "saw",
                "found",
                "made",
                "built",
                "wore",
                "tall",
                "small",
                "big",
                "tiny",
                "colorful",
                "bright",
            ]
            if any(keyword in line_lower for keyword in visual_keywords):
                if len(scenes) < 5:  # Max 5 illustration prompts
                    scenes.append(line.strip())

        # If we didn't find enough, take the first, middle, and last lines
        if len(scenes) < 3 and len(lines) >= 3:
            scenes = [lines[0].strip(), lines[len(lines) // 2].strip(), lines[-1].strip()]

        # Convert scenes to illustration prompts
        return [cls.build_illustration_prompt(scene) for scene in scenes[:5]]

    @classmethod
    def build_prompt(
        cls,
        topic: str,
        mode: GenerationMode,
        lines: int = 32,
        age: Optional[int] = None,
        length: str = "short",
    ) -> str:
        """Build the appropriate prompt based on mode."""
        if mode == GenerationMode.POEM:
            return cls.build_poem_prompt(topic, lines)
        elif mode == GenerationMode.EXPLAIN:
            return cls.build_explanation_prompt(topic, age)
        elif mode == GenerationMode.STORY:
            return cls.build_story_prompt(topic, length)
        else:
            raise ValueError(f"Unknown generation mode: {mode}")
