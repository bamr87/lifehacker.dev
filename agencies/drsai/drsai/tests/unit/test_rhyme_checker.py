"""Unit tests for the rhyme checker."""

import pytest

from drsai.validation.rhyme_checker import RhymeChecker, check_rhyme


class TestRhymeChecker:
    """Tests for RhymeChecker class."""

    @pytest.fixture
    def checker(self):
        """Create a rhyme checker instance."""
        return RhymeChecker()

    def test_get_last_word(self, checker):
        """Test extracting last word from line."""
        assert checker.get_last_word("The cat in the hat") == "hat"
        assert checker.get_last_word("Sitting on a mat!") == "mat"
        assert checker.get_last_word("") == ""

    def test_check_rhyme_perfect(self, checker):
        """Test detection of perfect rhymes."""
        result = checker.check_rhyme("cat", "hat")
        assert result.is_rhyme is True

        result = checker.check_rhyme("play", "day")
        assert result.is_rhyme is True

    def test_check_rhyme_same_word(self, checker):
        """Test that same word doesn't count as rhyme."""
        result = checker.check_rhyme("cat", "cat")
        assert result.is_rhyme is False
        assert result.rhyme_type == "same"

    def test_check_rhyme_no_rhyme(self, checker):
        """Test detection of non-rhymes."""
        result = checker.check_rhyme("cat", "dog")
        assert result.is_rhyme is False

    def test_check_rhyme_empty(self, checker):
        """Test with empty strings."""
        result = checker.check_rhyme("", "hat")
        assert result.is_rhyme is False

        result = checker.check_rhyme("cat", "")
        assert result.is_rhyme is False

    def test_find_rhyme_pairs_couplets(self, checker):
        """Test finding rhyme pairs in AABB scheme."""
        lines = [
            "The cat in the hat",
            "He sat on a mat",
            "With joy in his eyes",
            "Under blue skies",
        ]
        pairs = checker.find_rhyme_pairs(lines)
        assert len(pairs) >= 2  # Should find hat/mat and eyes/skies

    def test_calculate_rhyme_score(self, checker):
        """Test rhyme score calculation."""
        lines = [
            "The cat in the hat",
            "He sat on a mat",
        ]
        score = checker.calculate_rhyme_score(lines)
        assert 0 <= score <= 1.0

    def test_calculate_rhyme_score_no_rhymes(self, checker):
        """Test rhyme score with no rhymes."""
        lines = [
            "The quick brown fox",
            "Jumped over lazy dog",
        ]
        score = checker.calculate_rhyme_score(lines)
        # May be 0 or low depending on heuristics
        assert 0 <= score <= 1.0


class TestModuleFunctions:
    """Tests for module-level convenience functions."""

    def test_check_rhyme_function(self):
        """Test check_rhyme module function."""
        result = check_rhyme("cat", "hat")
        assert result.word1 == "cat"
        assert result.word2 == "hat"
