"""Rhyme checking for DrSAI content."""

import re
import string
from dataclasses import dataclass
from typing import Optional

# Try to import pronouncing for rhyme detection
try:
    import pronouncing

    HAS_PRONOUNCING = True
except ImportError:
    HAS_PRONOUNCING = False


@dataclass
class RhymeResult:
    """Result of rhyme checking."""

    word1: str
    word2: str
    is_rhyme: bool
    rhyme_type: str  # perfect, near, none


class RhymeChecker:
    """Check for rhymes in poetry."""

    # Common rhyme endings for fallback
    RHYME_ENDINGS = {
        "at",
        "an",
        "ay",
        "ow",
        "ee",
        "oo",
        "ight",
        "ing",
        "tion",
        "ness",
        "ment",
        "ful",
        "less",
        "ble",
        "tle",
        "dle",
    }

    def __init__(self):
        """Initialize the rhyme checker."""
        pass

    def get_last_word(self, line: str) -> str:
        """Extract the last word from a line."""
        # Remove punctuation and get last word
        clean = re.sub(r"[^\w\s]", "", line.strip())
        words = clean.split()
        return words[-1].lower() if words else ""

    def check_rhyme(self, word1: str, word2: str) -> RhymeResult:
        """Check if two words rhyme."""
        word1 = word1.lower().strip(string.punctuation)
        word2 = word2.lower().strip(string.punctuation)

        if not word1 or not word2:
            return RhymeResult(word1, word2, False, "none")

        # Same word doesn't count as rhyme
        if word1 == word2:
            return RhymeResult(word1, word2, False, "same")

        # Use pronouncing library if available
        if HAS_PRONOUNCING:
            rhymes1 = set(pronouncing.rhymes(word1))
            if word2 in rhymes1:
                return RhymeResult(word1, word2, True, "perfect")

            rhymes2 = set(pronouncing.rhymes(word2))
            if word1 in rhymes2:
                return RhymeResult(word1, word2, True, "perfect")

        # Fallback: check ending similarity
        if self._check_ending_rhyme(word1, word2):
            return RhymeResult(word1, word2, True, "near")

        return RhymeResult(word1, word2, False, "none")

    def _check_ending_rhyme(self, word1: str, word2: str) -> bool:
        """Check if words rhyme based on endings."""
        # Check last 2-4 characters
        for length in [4, 3, 2]:
            if len(word1) >= length and len(word2) >= length:
                if word1[-length:] == word2[-length:]:
                    return True

        return False

    def find_rhyme_pairs(self, lines: list[str]) -> list[tuple[str, str, int, int]]:
        """Find rhyming pairs in a list of lines.

        Returns list of (word1, word2, line_index1, line_index2).
        """
        pairs = []
        last_words = [(i, self.get_last_word(line)) for i, line in enumerate(lines)]

        # Check consecutive pairs (AABB scheme - most common in Seuss)
        for i in range(0, len(last_words) - 1, 2):
            idx1, word1 = last_words[i]
            idx2, word2 = last_words[i + 1]
            result = self.check_rhyme(word1, word2)
            if result.is_rhyme:
                pairs.append((word1, word2, idx1, idx2))

        # Also check alternating pairs (ABAB scheme)
        for i in range(0, len(last_words) - 2, 2):
            idx1, word1 = last_words[i]
            idx2, word2 = last_words[i + 2]
            result = self.check_rhyme(word1, word2)
            if result.is_rhyme:
                pairs.append((word1, word2, idx1, idx2))

        return pairs

    def calculate_rhyme_score(self, lines: list[str]) -> float:
        """Calculate how well content rhymes (0-1 scale)."""
        if len(lines) < 2:
            return 0.0

        pairs = self.find_rhyme_pairs(lines)
        # In AABB scheme, we expect len(lines)//2 rhyming pairs
        expected_pairs = len(lines) // 2
        actual_pairs = len(pairs)

        return min(1.0, actual_pairs / max(1, expected_pairs))


# Module-level convenience function
_checker: Optional[RhymeChecker] = None


def _get_checker() -> RhymeChecker:
    """Get or create the singleton rhyme checker."""
    global _checker
    if _checker is None:
        _checker = RhymeChecker()
    return _checker


def check_rhyme(word1: str, word2: str) -> RhymeResult:
    """Check if two words rhyme."""
    return _get_checker().check_rhyme(word1, word2)


def find_rhymes(lines: list[str]) -> list[tuple[str, str, int, int]]:
    """Find rhyming pairs in lines."""
    return _get_checker().find_rhyme_pairs(lines)
