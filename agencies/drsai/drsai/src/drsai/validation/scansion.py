"""Scansion engine for anapestic tetrameter validation.

Anapestic tetrameter: Four anapestic feet per line.
Each anapest = two unstressed syllables + one stressed syllable (da-da-DUM).
Pattern: UU/ UU/ UU/ UU/ (where U = unstressed, / = stressed)

This module validates that generated content follows this meter.
"""

import re
import string
from dataclasses import dataclass
from typing import Optional

from drsai.models.schemas import MeterScore

# Try to import nltk for syllable counting, fall back to simple heuristic
try:
    import nltk
    from nltk.corpus import cmudict

    # Ensure CMU dictionary is available
    try:
        _CMU_DICT = cmudict.dict()
    except LookupError:
        nltk.download("cmudict", quiet=True)
        _CMU_DICT = cmudict.dict()
    HAS_NLTK = True
except (ImportError, LookupError):
    _CMU_DICT = {}
    HAS_NLTK = False

# Try to import pronouncing as alternative
try:
    import pronouncing

    HAS_PRONOUNCING = True
except ImportError:
    HAS_PRONOUNCING = False


@dataclass
class Foot:
    """Represents a metrical foot."""

    pattern: str  # e.g., "UU/" for anapest
    syllables: list[str]


@dataclass
class LineAnalysis:
    """Analysis of a single line's meter."""

    line: str
    syllable_count: int
    stress_pattern: str
    feet: list[Foot]
    is_anapestic: bool
    compliance_score: float


class ScansionEngine:
    """Engine for analyzing and validating poetic meter."""

    # Vowel patterns for syllable counting fallback
    VOWELS = "aeiouyAEIOUY"
    VOWEL_PATTERN = re.compile(r"[aeiouy]+", re.IGNORECASE)

    def __init__(self):
        """Initialize the scansion engine."""
        self.cmu_dict = _CMU_DICT

    def count_syllables(self, word: str) -> int:
        """Count syllables in a word."""
        word = word.lower().strip(string.punctuation).strip()
        if not word:
            return 0

        # Try CMU dictionary first
        if HAS_NLTK and word in self.cmu_dict:
            # Count vowel sounds (digits in CMU phonemes indicate stress)
            return len([ph for ph in self.cmu_dict[word][0] if ph[-1].isdigit()])

        # Try pronouncing library
        if HAS_PRONOUNCING:
            phones = pronouncing.phones_for_word(word)
            if phones:
                return pronouncing.syllable_count(phones[0])

        # Fallback: heuristic syllable counting
        return self._heuristic_syllable_count(word)

    def _heuristic_syllable_count(self, word: str) -> int:
        """Heuristic syllable counting for unknown words."""
        word = word.lower()
        count = 0
        prev_is_vowel = False

        for char in word:
            is_vowel = char in self.VOWELS
            if is_vowel and not prev_is_vowel:
                count += 1
            prev_is_vowel = is_vowel

        # Handle silent e
        if word.endswith("e") and count > 1:
            count -= 1

        # Handle -le endings
        if word.endswith("le") and len(word) > 2 and word[-3] not in self.VOWELS:
            count += 1

        return max(1, count)

    def get_stress_pattern(self, word: str) -> str:
        """Get the stress pattern for a word (U = unstressed, / = stressed)."""
        word = word.lower().strip(string.punctuation)
        if not word:
            return ""

        # Try CMU dictionary
        if HAS_NLTK and word in self.cmu_dict:
            phonemes = self.cmu_dict[word][0]
            pattern = ""
            for ph in phonemes:
                if ph[-1].isdigit():
                    stress = int(ph[-1])
                    pattern += "/" if stress > 0 else "U"
            return pattern

        # Try pronouncing library
        if HAS_PRONOUNCING:
            phones = pronouncing.phones_for_word(word)
            if phones:
                stresses = pronouncing.stresses(phones[0])
                return "".join("/" if s in "12" else "U" for s in stresses)

        # Fallback: assume alternating stress starting with unstressed
        syllables = self.count_syllables(word)
        if syllables == 1:
            return "/"  # Single syllables often stressed in context
        return "U/" * (syllables // 2) + ("U" if syllables % 2 else "")

    def analyze_line(self, line: str) -> LineAnalysis:
        """Analyze a line for its metrical structure."""
        # Clean and tokenize
        clean_line = re.sub(r"[^\w\s'-]", "", line)
        words = clean_line.split()

        if not words:
            return LineAnalysis(
                line=line,
                syllable_count=0,
                stress_pattern="",
                feet=[],
                is_anapestic=False,
                compliance_score=0.0,
            )

        # Get stress pattern for entire line
        full_pattern = ""
        for word in words:
            pattern = self.get_stress_pattern(word)
            full_pattern += pattern

        syllable_count = len(full_pattern)

        # Check for anapestic pattern (UU/)
        # Allow some flexibility: iamb (U/) can substitute, trochee (/U) at line start
        feet = self._identify_feet(full_pattern)
        is_anapestic, compliance = self._check_anapestic_tetrameter(full_pattern, feet)

        return LineAnalysis(
            line=line,
            syllable_count=syllable_count,
            stress_pattern=full_pattern,
            feet=feet,
            is_anapestic=is_anapestic,
            compliance_score=compliance,
        )

    def _identify_feet(self, pattern: str) -> list[Foot]:
        """Identify metrical feet in a stress pattern."""
        feet = []
        i = 0

        while i < len(pattern):
            # Try to match anapest (UU/)
            if i + 3 <= len(pattern) and pattern[i : i + 3] == "UU/":
                feet.append(Foot(pattern="UU/", syllables=list(pattern[i : i + 3])))
                i += 3
            # Try to match iamb (U/) - common substitution
            elif i + 2 <= len(pattern) and pattern[i : i + 2] == "U/":
                feet.append(Foot(pattern="U/", syllables=list(pattern[i : i + 2])))
                i += 2
            # Try to match trochee (/U) - sometimes at line start
            elif i + 2 <= len(pattern) and pattern[i : i + 2] == "/U":
                feet.append(Foot(pattern="/U", syllables=list(pattern[i : i + 2])))
                i += 2
            # Single stressed or unstressed
            else:
                feet.append(Foot(pattern=pattern[i], syllables=[pattern[i]]))
                i += 1

        return feet

    def _check_anapestic_tetrameter(self, pattern: str, feet: list[Foot]) -> tuple[bool, float]:
        """Check if a pattern matches anapestic tetrameter.

        Returns (is_valid, compliance_score).

        Perfect anapestic tetrameter: 12 syllables, 4 anapests (UU/ UU/ UU/ UU/)
        We allow some substitutions:
        - Iambs (U/) can substitute for anapests
        - Line can start with stressed syllable (catalexis)
        - 9-13 syllables acceptable (flexibility for real poetry)
        """
        syllable_count = len(pattern)

        # Ideal: 12 syllables for 4 anapests
        # Acceptable: 9-13 syllables (common in real Seuss)
        if syllable_count < 6 or syllable_count > 16:
            return False, 0.0

        # Count proper feet (anapests and acceptable substitutes)
        anapest_count = sum(1 for f in feet if f.pattern == "UU/")
        iamb_count = sum(1 for f in feet if f.pattern == "U/")

        # A line with 3-4 anapests or 3+ anapests + iambs is good
        total_good_feet = anapest_count + (iamb_count * 0.7)  # Iambs count for less

        # Calculate compliance
        # Perfect: 4 anapests = 1.0
        # 3 anapests + 1 iamb = ~0.9
        # etc.
        if anapest_count >= 4:
            compliance = 1.0
        elif anapest_count >= 3:
            compliance = 0.9 + (0.1 * (total_good_feet - 3) / 1)
        elif anapest_count >= 2:
            compliance = 0.7 + (0.2 * (total_good_feet - 2) / 2)
        elif total_good_feet >= 2:
            compliance = 0.5 + (0.2 * total_good_feet / 4)
        else:
            compliance = 0.3 * total_good_feet / 4

        compliance = min(1.0, max(0.0, compliance))
        is_valid = compliance >= 0.8

        return is_valid, compliance

    def validate_content(self, content: str) -> MeterScore:
        """Validate meter compliance for entire content."""
        lines = [line.strip() for line in content.split("\n") if line.strip()]

        if not lines:
            return MeterScore(
                compliance=0.0,
                total_lines=0,
                compliant_lines=0,
                violations=[],
                is_acceptable=False,
                is_degraded=False,
            )

        compliant_count = 0
        violations = []

        for line in lines:
            analysis = self.analyze_line(line)
            if analysis.is_anapestic:
                compliant_count += 1
            else:
                violations.append(f"[{analysis.compliance_score:.0%}] {line[:50]}...")

        compliance = compliant_count / len(lines) if lines else 0.0

        return MeterScore(
            compliance=compliance,
            total_lines=len(lines),
            compliant_lines=compliant_count,
            violations=violations[:10],  # Limit to first 10 violations
            is_acceptable=compliance >= 0.98,
            is_degraded=0.95 <= compliance < 0.98,
        )


# Module-level convenience functions
_engine: Optional[ScansionEngine] = None


def _get_engine() -> ScansionEngine:
    """Get or create the singleton scansion engine."""
    global _engine
    if _engine is None:
        _engine = ScansionEngine()
    return _engine


def scan_line(line: str) -> LineAnalysis:
    """Analyze a single line for meter."""
    return _get_engine().analyze_line(line)


def validate_meter(content: str) -> MeterScore:
    """Validate meter compliance for content."""
    return _get_engine().validate_content(content)
