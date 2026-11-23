# Test Fixtures: Example Corpus

This folder contains a **structured, deterministic test corpus** used for functional testing and quality review.

## Why this exists

DrSAI generation is inherently non-deterministic when using real LLM providers. To keep tests stable, we:

- Run tests with `--provider mock`
- Monkeypatch `MockLLMClient.generate()` during tests to return **known outputs** for known inputs
- Assert downstream behavior (meter scoring, moral extraction, formatting) using **golden example files**

## Example files (repo root)

The functional corpus references these repo-root markdown files (they are also useful demos):

- `Family newsletter.md` — example prose input/context
- `newsletter_seuss.md` — example transformed output (Seuss-style newsletter poem)
- `reena_poem.md` — example poem output

## Where cases are defined

- `corpus_cases.py` defines the corpus cases and resolves paths to the repo root.

To add a new case, add a new markdown example at the repo root (or another stable location) and then add a new `CorpusCase` in `corpus_cases.py`.


