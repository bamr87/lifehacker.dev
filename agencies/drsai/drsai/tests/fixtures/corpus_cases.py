"""Structured functional test corpus for DrSAI.

These cases intentionally use the repo-root markdown files as examples:
- Family newsletter.md (input prose/context)
- newsletter_seuss.md (expected transformed output example)
- reena_poem.md (expected poem output example)

We keep them in the repo root because they are also useful as human-readable demos.
The tests reference them via paths resolved from this file location.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Literal, Optional

Mode = Literal["poem", "explain", "story"]


def repo_root() -> Path:
    """Get the repo root directory where example markdown files live.

    Path: drsai/tests/fixtures/corpus_cases.py
    parents[0] = fixtures/
    parents[1] = tests/
    parents[2] = drsai/ (package)
    parents[3] = drsai/ (repo root with markdown files)
    """
    return Path(__file__).resolve().parents[3]


@dataclass(frozen=True)
class CorpusCase:
    """A deterministic functional test case."""

    id: str
    mode: Mode
    topic: Optional[str]
    input_file: Optional[Path]
    expected_output_file: Path
    expected_moral_contains: Optional[str] = None

    def expected_output_text(self) -> str:
        return self.expected_output_file.read_text(encoding="utf-8")


ROOT = repo_root()

# Repo-root example files (as requested)
FAMILY_NEWSLETTER = ROOT / "Family newsletter.md"
NEWSLETTER_SEUSS = ROOT / "newsletter_seuss.md"
REENA_POEM = ROOT / "reena_poem.md"


CASES: list[CorpusCase] = [
    CorpusCase(
        id="family_newsletter_to_poem",
        mode="poem",
        topic=None,
        input_file=FAMILY_NEWSLETTER,
        expected_output_file=NEWSLETTER_SEUSS,
        expected_moral_contains="moral",
    ),
    CorpusCase(
        id="reena_poem_topic",
        mode="poem",
        topic="Write a Seuss-style poem about Reena, daycare, and Nubi the cat.",
        input_file=None,
        expected_output_file=REENA_POEM,
        expected_moral_contains="Moral:",
    ),
]


def validate_corpus_files_exist() -> None:
    """Fail fast if any corpus files are missing."""
    missing: list[str] = []
    for p in [FAMILY_NEWSLETTER, NEWSLETTER_SEUSS, REENA_POEM]:
        if not p.exists():
            missing.append(str(p))
    if missing:
        raise FileNotFoundError(f"Missing corpus files: {', '.join(missing)}")
