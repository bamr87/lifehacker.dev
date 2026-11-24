"""Overall quality checking for DrSAI content."""

import re
from typing import Optional

from drsai.models.schemas import QualityScore
from drsai.validation.rhyme_checker import RhymeChecker
from drsai.validation.scansion import validate_meter


class QualityChecker:
    """Check overall quality of generated Seuss content."""

    # Keywords that suggest a moral/lesson
    MORAL_KEYWORDS = [
        "moral",
        "lesson",
        "remember",
        "always",
        "never forget",
        "so you see",
        "and that's why",
        "the truth is",
        "in the end",
        "what we learn",
        "important",
        "matters most",
        "heart",
        "kindness",
        "love",
        "friend",
        "together",
        "believe",
        "try",
        "dream",
        "hope",
        "joy",
        "share",
        "care",
    ]

    # Keywords suggesting invented/whimsical words
    WHIMSY_PATTERNS = [
        r"\b[A-Z][a-z]*-[A-Z][a-z]*\b",  # Hyphenated names like "Snicker-Snack"
        r"\b[A-Z][a-z]*ville\b",  # -ville places
        r"\b[A-Z][a-z]*land\b",  # -land places
        r"\b[A-Z][a-z]*ish\b",  # -ish adjectives
        r"\b[A-Z][a-z]*oo\b",  # -oo endings (like "Who")
        r"\b[A-Z][a-z]*ax\b",  # -ax endings (like "Lorax")
    ]

    def __init__(self):
        """Initialize the quality checker."""
        self.rhyme_checker = RhymeChecker()

    def check_has_moral(self, content: str) -> bool:
        """Check if content contains a moral or lesson."""
        content_lower = content.lower()

        # Check for moral keywords
        for keyword in self.MORAL_KEYWORDS:
            if keyword in content_lower:
                return True

        # Check if last few lines seem conclusive
        lines = [line.strip() for line in content.split("\n") if line.strip()]
        if lines:
            last_lines = " ".join(lines[-3:]).lower()
            # Look for concluding phrases
            concluding_phrases = [
                "and so",
                "that's the",
                "you'll find",
                "remember this",
                "never forget",
                "always be",
                "the end",
                "from this day",
            ]
            for phrase in concluding_phrases:
                if phrase in last_lines:
                    return True

        return False

    def check_has_whimsy(self, content: str) -> bool:
        """Check if content has invented/whimsical elements."""
        for pattern in self.WHIMSY_PATTERNS:
            if re.search(pattern, content):
                return True
        return False

    def extract_moral(self, content: str) -> Optional[str]:
        """Try to extract the moral from content."""
        lines = [line.strip() for line in content.split("\n") if line.strip()]

        if not lines:
            return None

        # Check last few lines for moral-like statements
        for line in reversed(lines[-5:]):
            line_lower = line.lower()
            for keyword in ["moral", "lesson", "remember", "always", "never forget"]:
                if keyword in line_lower:
                    return line

        # Return last line as potential moral
        return lines[-1] if lines else None

    def check_quality(self, content: str) -> QualityScore:
        """Perform comprehensive quality check."""
        lines = [line.strip() for line in content.split("\n") if line.strip()]

        # Check meter
        meter_score = validate_meter(content)

        # Check rhymes
        rhyme_pairs = self.rhyme_checker.find_rhyme_pairs(lines)
        has_rhymes = len(rhyme_pairs) >= len(lines) // 4  # At least 1/4 of expected pairs

        # Check for moral
        has_moral = self.check_has_moral(content)

        return QualityScore(
            meter_score=meter_score,
            has_rhymes=has_rhymes,
            has_moral=has_moral,
            rhyme_pairs=[(w1, w2) for w1, w2, _, _ in rhyme_pairs[:10]],
        )

    def is_acceptable(self, content: str, config_target: float = 0.98) -> bool:
        """Check if content meets minimum quality requirements."""
        quality = self.check_quality(content)
        return quality.meter_score.compliance >= config_target and quality.has_rhymes

    def get_improvement_suggestions(self, content: str) -> list[str]:
        """Get suggestions for improving content quality."""
        suggestions = []
        quality = self.check_quality(content)

        if quality.meter_score.compliance < 0.98:
            suggestions.append(
                f"Meter compliance is {quality.meter_score.compliance:.0%}. "
                f"Aim for ≥98% anapestic tetrameter."
            )
            if quality.meter_score.violations:
                suggestions.append(
                    f"Problem lines: {', '.join(quality.meter_score.violations[:3])}"
                )

        if not quality.has_rhymes:
            suggestions.append("Add more rhyming couplets (AABB scheme).")

        if not quality.has_moral:
            suggestions.append("End with a clear moral or lesson.")

        return suggestions
