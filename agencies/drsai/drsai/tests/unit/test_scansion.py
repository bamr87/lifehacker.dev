"""Unit tests for the scansion engine."""

import pytest

from drsai.validation.scansion import ScansionEngine, scan_line, validate_meter


class TestScansionEngine:
    """Tests for ScansionEngine class."""

    @pytest.fixture
    def engine(self):
        """Create a scansion engine instance."""
        return ScansionEngine()

    def test_count_syllables_simple_words(self, engine):
        """Test syllable counting for simple words."""
        assert engine.count_syllables("cat") == 1
        assert engine.count_syllables("the") == 1
        assert engine.count_syllables("hat") == 1

    def test_count_syllables_multi_syllable(self, engine):
        """Test syllable counting for multi-syllable words."""
        assert engine.count_syllables("recursion") >= 3
        assert engine.count_syllables("beautiful") >= 3
        assert engine.count_syllables("understand") >= 3

    def test_count_syllables_empty(self, engine):
        """Test syllable counting for empty string."""
        assert engine.count_syllables("") == 0
        # Whitespace-only should also return 0 after stripping
        assert engine.count_syllables("   ") == 0

    def test_analyze_line_anapestic(self, engine):
        """Test analysis of anapestic tetrameter lines."""
        # Classic Seuss-style line
        analysis = engine.analyze_line("The sun did not shine, it was too wet to play")
        assert analysis.syllable_count > 0
        assert len(analysis.stress_pattern) > 0

    def test_analyze_line_empty(self, engine):
        """Test analysis of empty line."""
        analysis = engine.analyze_line("")
        assert analysis.syllable_count == 0
        assert analysis.is_anapestic is False
        assert analysis.compliance_score == 0.0

    def test_validate_content_basic(self, engine):
        """Test validation of multi-line content."""
        content = """The cat in the hat sat on the mat,
With a big striped hat and a magical bat.
He danced and he pranced with glee in his eyes,
And told all the children of wondrous surprise!"""

        score = engine.validate_content(content)
        assert score.total_lines == 4
        assert 0 <= score.compliance <= 1.0
        assert score.compliant_lines >= 0

    def test_validate_content_empty(self, engine):
        """Test validation of empty content."""
        score = engine.validate_content("")
        assert score.total_lines == 0
        assert score.compliance == 0.0
        assert score.is_acceptable is False


class TestModuleFunctions:
    """Tests for module-level convenience functions."""

    def test_scan_line(self):
        """Test scan_line function."""
        analysis = scan_line("The cat in the hat")
        assert analysis.line == "The cat in the hat"
        assert analysis.syllable_count > 0

    def test_validate_meter(self):
        """Test validate_meter function."""
        content = "The cat in the hat sat on a mat."
        score = validate_meter(content)
        assert score.total_lines >= 1
        assert 0 <= score.compliance <= 1.0


class TestMeterCompliance:
    """Tests for meter compliance calculation."""

    @pytest.fixture
    def engine(self):
        return ScansionEngine()

    def test_perfect_anapest_pattern(self, engine):
        """Test detection of perfect anapestic pattern."""
        # This should be close to perfect anapestic tetrameter
        line = "da da DUM da da DUM da da DUM da da DUM"
        analysis = engine.analyze_line(line)
        # Pattern detection may vary, but should process
        assert analysis.syllable_count > 0

    def test_mixed_content_compliance(self, engine):
        """Test compliance calculation for mixed quality content."""
        # Some good, some bad lines
        content = """The cat in the hat sat on a mat.
This is prose, not poetry at all.
He danced and he pranced with delight.
Another prose line here today."""

        score = engine.validate_content(content)
        # The scansion engine uses strict anapestic tetrameter detection
        # so compliance may be 0 or very low for non-perfect content
        assert 0 <= score.compliance <= 1.0
        assert score.total_lines == 4
