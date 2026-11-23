# DrSAI MVP Implementation Plan

## Document Control

| Field | Value |
|-------|-------|
| Document | DrSAI MVP Implementation Plan |
| Based On | PRD v0.2 |
| Status | Draft |
| Version | v1.3 |
| Created | 2025-12-28 |
| Updated | 2025-12-28 |
| Target Phase | Alpha (Q1 2026) |

---

## Executive Summary

This implementation plan outlines the technical approach, architecture, and development phases for building the DrSAI MVP (Alpha phase). The MVP focuses on delivering P0 features: CLI command interface, Poem mode, and Explanation mode, with a foundation for Story mode and Illustration prompts (P1) in Beta.

**MVP Goal:** Deliver a working CLI tool that generates authentic Dr. Seuss-style content with ≥98% meter compliance and <12s latency (P99).

**Scope Alignment Note:** The HTTP API described in `PRD.md` is **planned for Beta**. Alpha ships **CLI-first**, but we keep internal request/response schemas compatible with the future API.

---

## Table of Contents

- [0. Decisions & Open Questions (Alpha Gating)](#0-decisions--open-questions-alpha-gating)
- [1. MVP Scope](#1-mvp-scope)
- [2. Technology Stack](#2-technology-stack)
- [3. System Architecture](#3-system-architecture)
- [4. Development Phases](#4-development-phases)
- [5. Component Breakdown](#5-component-breakdown)
- [6. Implementation Tasks](#6-implementation-tasks)
- [7. Testing Strategy](#7-testing-strategy)
- [8. Deployment Plan](#8-deployment-plan)
- [9. Risk Mitigation](#9-risk-mitigation)
- [10. Timeline & Milestones](#10-timeline--milestones)
- [11. Next Steps (Post-MVP)](#11-next-steps-post-mvp)
- [12. Success Metrics](#12-success-metrics)
- [13. Appendix](#13-appendix)
- [14. Changelog](#14-changelog)
- [15. Current Implementation Status](#15-current-implementation-status)
- [16. Prompt Engineering Reference](#16-prompt-engineering-reference)
- [17. Scansion Engine Technical Details](#17-scansion-engine-technical-details)
- [18. Troubleshooting Guide](#18-troubleshooting-guide)
- [19. API Design Preview (Beta)](#19-api-design-preview-beta)

---

## 0. Decisions & Open Questions (Alpha Gating)

### 0.1 Decisions (Make These Explicit Up Front)

- **CLI framework**: Use **Typer** (Click-based) for type hints and clean help UX.
- **Packaging**: Support `pip install drsai` and recommend `pipx install drsai` for isolation. Defer Homebrew formula until after Alpha unless demanded by users.
- **LLM provider strategy (Alpha)**: Ship with a **provider abstraction** supporting at least one hosted LLM (OpenAI or Anthropic) and a “mock provider” for tests.
- **Quality gate behavior**: Enforce meter via **regeneration loop**, not manual editing (details below).
- **All-ages safety policy**: If topic is disallowed/sensitive, **rewrite the prompt** to be gentle/hopeful; never produce graphic content.

### 0.2 Open Questions (Must Resolve Before Alpha Build Starts)

- **Meter definition**: What counts as “anapestic tetrameter compliance” (allowed substitutions, punctuation, feminine endings)?
- **If meter <98%**: Do we **retry**, **warn and return**, or **error out**? (Recommended policy below.)
- **Safety policy**: What topics are “too dark” and what rewriting is acceptable?
- **Legal**: Confirm guidance on “style emulation” language and what we can claim in marketing/docs.

### 0.3 Recommended Meter Gate Policy (Concrete, Implementable)

- **Attempt budget**: Up to **N=3** generations for the requested output.
- **Accept**: If compliance ≥0.98, return normally.
- **Degraded accept**: If best compliance is in [0.95, 0.98), return best output with a **warning** and include `meter_score`.
- **Fail**: If best compliance <0.95, return a clear error (and suggest fewer lines / different topic).

## 1. MVP Scope

### 1.1 In-Scope Features (Alpha MVP)

| Feature | Priority | Description | Acceptance Criteria |
|---------|----------|-------------|-------------------|
| **CLI Command** | P0 | `drsai "topic"` command | Installs via `pip` (recommend `pipx`), executes in <12s, supports --mode flag |
| **Poem Mode** | P0 | Generate 16-48 line poems | ≥98% anapestic tetrameter, valid rhymes, clear moral |
| **Explanation Mode** | P0 | Rhyming explanations | 6-year-old understands, includes moral |
| **Meter Validation** | P0 | Scansion engine | Validates ≥98% compliance, flags warnings |
| **Error Handling** | P0 | Input validation & error messages | Handles empty input, invalid modes, timeouts |

### 1.2 Out-of-Scope (Deferred to Beta/1.0)

- Story mode (P1 - Beta)
- Illustration prompts (P1 - Beta)
- API endpoints (Beta)
- Read-aloud audio (P2 - 1.0)
- Recursive mode (P2 - 1.0)
- Web UI (P3 - Future)

### 1.3 MVP Success Criteria

- [ ] `drsai "explain recursion" --mode poem` produces valid Seuss poem
- [ ] Meter compliance ≥98% (automated validation)
- [ ] CLI works on macOS, Linux, Windows
- [ ] Generation latency P99 <12 seconds
- [ ] User study: N=20, ≥90% smile rate

---

## 2. Technology Stack

### 2.1 Core Technologies

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **Language** | Python 3.10+ | Rich ecosystem, LLM libraries, CLI tools |
| **CLI Framework** | Typer | Type-friendly CLI built on Click |
| **LLM Integration** | OpenAI API / Anthropic API / Local Ollama | Start with API, migrate to fine-tuned model |
| **Meter Validation** | Custom scansion engine (NLTK + custom logic) | Need precise anapestic tetrameter detection |
| **Package Manager** | Poetry or setuptools | Dependency management, packaging |
| **Testing** | pytest | Standard Python testing framework |
| **CI/CD** | GitHub Actions | Automated testing and releases |

### 2.2 Model Strategy (Phased Approach)

**Phase 1 (MVP):** Use existing LLM APIs with prompt engineering
- **Primary:** OpenAI or Anthropic (configurable)
- **Fallback (optional):** Local Ollama with Llama 3.x if latency/cost demands it
- **Rationale:** Faster to market, validate product-market fit before fine-tuning

**Phase 2 (Post-MVP):** Fine-tuned Llama-3.2-Seuss-70B
- Train on 44 Dr. Seuss books (after legal review)
- Deploy via cloud inference (Replicate, Together AI, or self-hosted)

### 2.3 Dependencies

```python
# Core dependencies
typer>=0.12.0          # CLI framework (Click-based)
openai>=1.0.0         # LLM API client
anthropic>=0.7.0      # Alternative LLM API
nltk>=3.8             # Natural language processing
pydantic>=2.0         # Data validation
python-dotenv>=1.0    # Environment variables
requests>=2.31        # HTTP client
tqdm>=4.66            # Progress bars

# Development dependencies
pytest>=7.4           # Testing
black>=23.0           # Code formatting
mypy>=1.5             # Type checking
ruff>=0.1             # Linting
```

---

## 3. System Architecture

### 3.1 High-Level Architecture

```
┌─────────────────┐
│   CLI (drsai)   │
│   User Input    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Command Parser │
│     (Typer)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Content Engine │
│  - Mode Router  │
│  - Prompt Builder│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   LLM Client    │
│  (OpenAI/Claude)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Meter Validator │
│ (Scansion Engine)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Output Formatter│
│  (Terminal/JSON) │
└─────────────────┘
```

### 3.2 Component Architecture

```
drsai/
├── drsai/
│   ├── __init__.py
│   ├── cli.py                 # CLI entry point
│   ├── commands/
│   │   ├── __init__.py
│   │   ├── poem.py            # Poem mode handler
│   │   ├── explain.py         # Explanation mode handler
│   │   └── base.py            # Base command class
│   ├── core/
│   │   ├── __init__.py
│   │   ├── llm_client.py      # LLM API wrapper
│   │   ├── prompt_builder.py  # Seuss-style prompt construction
│   │   └── config.py           # Configuration management
│   ├── validation/
│   │   ├── __init__.py
│   │   ├── scansion.py        # Meter validation engine
│   │   ├── rhyme_checker.py   # Rhyme validation
│   │   └── quality_checker.py # Overall quality metrics
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── formatting.py      # Output formatting
│   │   └── errors.py           # Error handling
│   └── models/
│       ├── __init__.py
│       └── schemas.py          # Pydantic models
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── pyproject.toml
├── README.md
└── .env.example
```

---

## 4. Development Phases

### Phase 1: Foundation (Weeks 1-2)
**Goal:** Set up project structure, CLI skeleton, basic LLM integration

**Deliverables:**
- Project structure and dependencies
- CLI command framework (`drsai --help` works)
- Basic LLM client integration
- Environment configuration
- Unit test framework

**Success Criteria:**
- `drsai "test"` executes without errors
- LLM API call succeeds
- Basic output displayed

### Phase 2: Core Generation (Weeks 3-4)
**Goal:** Implement poem and explanation modes with prompt engineering

**Deliverables:**
- Poem mode implementation
- Explanation mode implementation
- Prompt templates for Seuss style
- Basic output formatting

**Success Criteria:**
- `drsai "explain recursion" --mode poem` generates poem
- `drsai "explain recursion" --mode explain` generates explanation
- Output is readable and Seuss-like (manual review)

### Phase 3: Meter Validation (Weeks 5-6)
**Goal:** Build scansion engine to validate anapestic tetrameter

**Deliverables:**
- Scansion engine implementation
- Meter validation logic
- Rhyme detection
- Quality scoring system

**Success Criteria:**
- Meter compliance calculated for generated content
- ≥95% compliance on test samples (target: ≥98%)
- Warnings displayed for low compliance

### Phase 4: Polish & Testing (Weeks 7-8)
**Goal:** Error handling, edge cases, performance optimization

**Deliverables:**
- Comprehensive error handling
- Input validation
- Performance optimization (caching, timeouts)
- Integration and E2E tests
- Documentation

**Success Criteria:**
- All edge cases handled gracefully
- P99 latency <12 seconds
- Test coverage ≥80%
- User documentation complete

### Phase 5: Alpha Release (Week 9)
**Goal:** Package, distribute, and validate with users

**Deliverables:**
- PyPI package (`pip install drsai`)
- Installation documentation
- User study (N=20)
- Feedback collection

**Success Criteria:**
- `pip install drsai` works
- User study shows ≥90% smile rate
- Ready for Beta phase

---

## 5. Component Breakdown

### 5.1 CLI Module (`drsai/cli.py`)

**Responsibilities:**
- Parse command-line arguments
- Route to appropriate command handler
- Display help and usage
- Handle global flags (--verbose, --output)

**Key Functions:**
```python
import typer
from typing import Optional

app = typer.Typer(add_completion=False)

@app.command()
def main(
    topic: str,
    mode: str = typer.Option("poem", "--mode", help="poem | explain"),
    lines: int = typer.Option(32, "--lines", help="Poem lines (16-48)"),
    age: Optional[int] = typer.Option(None, "--age", help="Target age for explain mode"),
):
    """Generate Dr. Seuss-style content."""
    ...

if __name__ == "__main__":
    app()
```

### 5.2 LLM Client (`drsai/core/llm_client.py`)

**Responsibilities:**
- Abstract LLM API calls (OpenAI, Anthropic, Ollama)
- Handle retries and timeouts
- Manage API keys and configuration
- Stream responses (optional)

**Key Classes:**
```python
class LLMClient:
    def generate(self, prompt: str, max_tokens: int, temperature: float) -> str
    def generate_with_retry(self, prompt: str, max_retries: int = 3) -> str
```

### 5.3 Prompt Builder (`drsai/core/prompt_builder.py`)

**Responsibilities:**
- Construct Seuss-style prompts
- Include meter requirements in prompt
- Adapt prompts for different modes
- Include examples and constraints

**Key Functions:**
```python
def build_poem_prompt(topic: str, lines: int) -> str
def build_explanation_prompt(topic: str, age: int = None) -> str
```

**Example Prompt Template:**
```
You are Dr. Seuss. Write a poem about {topic} that:
- Uses anapestic tetrameter (da-da-DUM da-da-DUM da-da-DUM da-da-DUM)
- Contains wild, creative rhymes
- Includes invented creatures or places
- Ends with a clear moral or lesson
- Is exactly {lines} lines long
- Is suitable for all ages (ages 5-95)

Write the poem now:
```

### 5.4 Scansion Engine (`drsai/validation/scansion.py`)

**Responsibilities:**
- Analyze lines for anapestic tetrameter
- Calculate meter compliance percentage
- Identify lines that don't match meter
- Provide feedback for improvement

**Key Functions:**
```python
def scan_line(line: str) -> List[Foot]
def validate_meter(lines: List[str]) -> MeterScore
def calculate_compliance(lines: List[str]) -> float
```

**Algorithm:**
1. Tokenize line into words
2. Get syllable counts for each word (using NLTK)
3. Identify stressed/unstressed syllables
4. Match against anapestic pattern (UU-UU-UU-UU-)
5. Calculate compliance percentage

### 5.5 Quality Checker (`drsai/validation/quality_checker.py`)

**Responsibilities:**
- Validate rhyme schemes
- Check for invented words/creatures
- Ensure moral/lesson present
- Overall quality score

**Key Functions:**
```python
def check_rhymes(lines: List[str]) -> RhymeScore
def check_invented_words(text: str) -> bool
def check_moral(text: str) -> bool
def calculate_quality_score(text: str) -> QualityScore
```

---

## 6. Implementation Tasks

### 6.1 Task Breakdown (Detailed)

#### Sprint 1: Foundation (Weeks 1-2)

| Task ID | Task | Owner | Est. Hours | Dependencies |
|---------|------|-------|------------|--------------|
| T1.1 | Set up project structure (Poetry/setuptools) | Eng | 4 | - |
| T1.2 | Create CLI skeleton with Typer | Eng | 8 | T1.1 |
| T1.3 | Implement LLM client (OpenAI API) | Eng | 8 | T1.1 |
| T1.4 | Set up environment configuration (.env) | Eng | 2 | T1.1 |
| T1.5 | Create basic prompt templates | Eng | 4 | T1.3 |
| T1.6 | Set up pytest testing framework | Eng | 4 | T1.1 |
| T1.7 | Write unit tests for CLI parsing | Eng | 4 | T1.2 |
| **Total** | | | **34 hours** | |

#### Sprint 2: Core Generation (Weeks 3-4)

| Task ID | Task | Owner | Est. Hours | Dependencies |
|---------|------|-------|------------|--------------|
| T2.1 | Implement poem mode handler | Eng | 12 | T1.2, T1.5 |
| T2.2 | Implement explanation mode handler | Eng | 12 | T1.2, T1.5 |
| T2.3 | Refine prompt templates (iterative) | Eng | 8 | T2.1, T2.2 |
| T2.4 | Add output formatting (terminal) | Eng | 4 | T2.1, T2.2 |
| T2.5 | Implement error handling (timeouts, API errors) | Eng | 6 | T1.3 |
| T2.6 | Write integration tests for modes | Eng | 8 | T2.1, T2.2 |
| **Total** | | | **50 hours** | |

#### Sprint 3: Meter Validation (Weeks 5-6)

| Task ID | Task | Owner | Est. Hours | Dependencies |
|---------|------|-------|------------|--------------|
| T3.1 | Research scansion libraries/algorithms | Eng | 8 | - |
| T3.2 | Implement syllable counting (NLTK) | Eng | 6 | T3.1 |
| T3.3 | Implement stress pattern detection | Eng | 12 | T3.2 |
| T3.4 | Build anapestic tetrameter validator | Eng | 16 | T3.3 |
| T3.5 | Implement meter compliance calculator | Eng | 6 | T3.4 |
| T3.6 | Add rhyme detection logic | Eng | 8 | T3.2 |
| T3.7 | Integrate validation into generation pipeline | Eng | 6 | T3.5, T2.1 |
| T3.8 | Write tests for scansion engine | Eng | 8 | T3.4 |
| **Total** | | | **70 hours** | |

#### Sprint 4: Polish & Testing (Weeks 7-8)

| Task ID | Task | Owner | Est. Hours | Dependencies |
|---------|------|-------|------------|--------------|
| T4.1 | Implement input validation (empty, length, mode) | Eng | 6 | T1.2 |
| T4.2 | Add comprehensive error messages | Eng | 4 | T4.1 |
| T4.3 | Implement caching for common topics | Eng | 8 | T1.3 |
| T4.4 | Optimize prompt length for latency | Eng | 4 | T2.3 |
| T4.5 | Add progress indicators (tqdm) | Eng | 2 | T2.1 |
| T4.6 | Write E2E tests | Eng | 12 | T2.1, T2.2, T3.7 |
| T4.7 | Performance testing (latency targets) | Eng | 8 | T4.3 |
| T4.8 | Write user documentation (README) | Eng | 8 | T1.2 |
| T4.9 | Code review and refactoring | Eng | 8 | T4.6 |
| **Total** | | | **60 hours** | |

#### Sprint 5: Alpha Release (Week 9)

| Task ID | Task | Owner | Est. Hours | Dependencies |
|---------|------|-------|------------|--------------|
| T5.1 | Package for PyPI (setup.py/pyproject.toml) | Eng | 6 | T4.8 |
| T5.2 | Test installation on macOS, Linux, Windows | Eng | 4 | T5.1 |
| T5.3 | Create installation guide | Eng | 4 | T5.1 |
| T5.4 | Conduct user study (N=20) | Product | 16 | T5.2 |
| T5.5 | Collect and analyze feedback | Product | 8 | T5.4 |
| T5.6 | Fix critical bugs from user study | Eng | 8 | T5.5 |
| **Total** | | | **46 hours** | |

**Total Estimated Hours: 260 hours (~6.5 weeks for 1 engineer, or ~3 weeks for 2 engineers)**

---

## 7. Testing Strategy

### 7.1 Test Pyramid

```
        /\
       /E2E\         10% (Critical paths)
      /────\
     /Integ\         30% (Component integration)
    /───────\
   /  Unit  \        60% (Individual functions)
  /───────────\
```

### 7.2 Unit Tests

**Scansion Engine:**
- `test_scan_line()` - Validates single line scanning
- `test_anapestic_pattern()` - Validates meter pattern matching
- `test_calculate_compliance()` - Validates compliance calculation
- `test_rhyme_detection()` - Validates rhyme detection

**LLM Client:**
- `test_api_call()` - Validates API integration
- `test_retry_logic()` - Validates retry on failure
- `test_timeout()` - Validates timeout handling

**Prompt Builder:**
- `test_poem_prompt()` - Validates poem prompt construction
- `test_explanation_prompt()` - Validates explanation prompt
- `test_prompt_includes_constraints()` - Validates constraints included

**CLI:**
- `test_parse_arguments()` - Validates argument parsing
- `test_mode_validation()` - Validates mode flag
- `test_error_messages()` - Validates error handling

### 7.3 Integration Tests

- `test_poem_generation_end_to_end()` - Full poem generation flow
- `test_explanation_generation_end_to_end()` - Full explanation flow
- `test_meter_validation_integration()` - Meter validation in pipeline
- `test_error_handling_integration()` - Error handling across components

### 7.4 E2E Tests

- `test_cli_poem_command()` - `drsai "topic" --mode poem` works
- `test_cli_explanation_command()` - `drsai "topic" --mode explain` works
- `test_cli_error_cases()` - Invalid inputs handled correctly
- `test_cli_performance()` - Latency <12s (P99)

### 7.5 Test Data

**Sample Topics for Testing:**
- Simple: "cats", "rainbows", "friendship"
- Complex: "quantum computing", "recursion", "photosynthesis"
- Edge cases: Empty string, very long topic, special characters

**Expected Test Coverage:** ≥80% (unit + integration)

### 7.6 Corpus-Based Functional Testing

We maintain a structured corpus of **input/output pairs** for deterministic functional tests. These allow us to:
- Validate the full pipeline without live LLM calls (mock provider returns golden outputs)
- Regression-test quality metrics (meter, rhymes, moral extraction)
- Ensure CLI `--file` flag works correctly with real markdown files

**Corpus Structure:**

| Case ID | Input File | Expected Output | Mode | Assertions |
|---------|------------|-----------------|------|------------|
| `newsletter_transform` | `Family newsletter.md` | `newsletter_seuss.md` | poem | Exact match, has moral, meter ≥0.5 |
| `reena_poem` | (inline "Reena + Nubi") | `reena_poem.md` | poem | Exact match, moral contains "kindness" |

**Location:** `tests/fixtures/corpus_cases.py`

**How It Works:**
1. `conftest.py` monkeypatches `MockLLMClient.generate()` to route based on prompt content
2. If prompt contains corpus-case trigger text → return the golden output file
3. Integration tests parametrize over `CASES` and assert exact content match + quality metadata
4. E2E tests run the CLI with `--file` and `--provider mock`, then assert expected output appears

**Adding New Corpus Cases:**
1. Add input markdown file to repo root (or `tests/fixtures/inputs/`)
2. Add expected output markdown file
3. Create a new `CorpusCase` entry in `tests/fixtures/corpus_cases.py`
4. Add routing rule in `conftest.py` if prompt-matching logic needs adjustment

---

## 8. Deployment Plan

### 8.1 Packaging

**PyPI Package Structure:**
```
drsai/
├── drsai/
│   └── [source code]
├── tests/
├── pyproject.toml
├── README.md
└── LICENSE
```

**pyproject.toml Configuration:**
```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "drsai"
version = "0.1.0"
description = "Generate Dr. Seuss-style content"
requires-python = ">=3.10"
dependencies = [...]
```

### 8.2 Distribution

**Release Process:**
1. Version bump in `pyproject.toml`
2. Run tests (`pytest`)
3. Build package (`python -m build`)
4. Upload to PyPI (`twine upload dist/*`)
5. Tag release in Git
6. Update documentation

**Installation:**
```bash
pip install drsai
```

### 8.3 CI/CD Pipeline (GitHub Actions)

**Workflow:**
1. **On PR:** Run tests, linting, type checking
2. **On Merge to Main:** Run full test suite
3. **On Tag:** Build and publish to PyPI

**YAML Example:**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
      - run: pip install -e .[dev]
      - run: pytest
      - run: black --check .
      - run: mypy drsai
```

---

## 9. Risk Mitigation

### 9.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **LLM API latency >12s** | Medium | High | Implement caching, use faster models, optimize prompts |
| **Meter compliance <98%** | High | High | Start with prompt engineering, iterate on scansion, post-process if needed |
| **Scansion engine inaccurate** | Medium | High | Use multiple libraries, manual validation, iterative improvement |
| **API costs too high** | Low | Medium | Monitor usage, implement rate limiting, consider local models |

### 9.2 Product Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Output not Seuss-like enough** | Medium | High | Iterate on prompts, collect user feedback, fine-tune model post-MVP |
| **Users don't understand output** | Low | Medium | Always include clear moral, test with target age groups |
| **Copyright concerns** | Medium | High | Legal review before launch, transformative fair-use approach |

### 9.3 Mitigation Strategies

**For Meter Compliance:**
1. **Phase 1:** Prompt engineering with explicit meter instructions
2. **Phase 2:** Post-processing to fix meter violations
3. **Phase 3:** Fine-tuned model trained on Seuss books

**For Latency:**
1. Implement response caching for common topics
2. Use faster models (GPT-3.5-turbo vs GPT-4)
3. Optimize prompt length
4. Consider local models (Ollama) for faster inference

**For Quality:**
1. Iterative prompt refinement based on output samples
2. Manual review of 100+ generated samples
3. User feedback loop (Alpha user study)
4. Fine-tuning post-MVP

---

## 10. Timeline & Milestones

### 10.1 High-Level Timeline

```
Week 1-2:  Foundation        [████████░░░░░░░░░░░░]
Week 3-4:  Core Generation  [░░░░░░░░████████░░░░]
Week 5-6:  Meter Validation [░░░░░░░░░░░░░░██████]
Week 7-8:  Polish & Testing [░░░░░░░░░░░░░░░░░░░░]
Week 9:    Alpha Release    [░░░░░░░░░░░░░░░░░░░░]
```

**Total Duration:** 9 weeks (2.25 months)

### 10.2 Key Milestones

| Milestone | Week | Deliverable | Success Criteria |
|-----------|------|-------------|------------------|
| **M1: Project Setup** | 2 | CLI skeleton, LLM integration | `drsai --help` works, API calls succeed |
| **M2: Core Features** | 4 | Poem + Explanation modes | Both modes generate readable output |
| **M3: Meter Validation** | 6 | Scansion engine | ≥95% compliance on test samples |
| **M4: MVP Complete** | 8 | Full feature set, tests, docs | All acceptance criteria met |
| **M5: Alpha Release** | 9 | PyPI package, user study | ≥90% smile rate, ready for Beta |

### 10.3 Dependencies & Blockers

**Critical Path:**
1. LLM API integration (blocks all generation)
2. Scansion engine (blocks quality validation)
3. Meter compliance ≥98% (blocks Alpha release)

**Parallel Work:**
- CLI development can proceed in parallel with LLM integration
- Testing can be written alongside feature development
- Documentation can be written incrementally

---

## 11. Next Steps (Post-MVP)

### 11.1 Beta Phase (Q2 2026)

**Features to Add:**
- Story mode (500-800 words)
- Illustration prompts (3-5 per generation)
- API endpoints (REST API)
- Rate limiting
- Enhanced error handling

**Estimated Effort:** 6-8 weeks

### 11.2 1.0 Release (Q3 2026)

**Features to Add:**
- Read-aloud audio (ElevenLabs integration)
- Recursive mode
- Fine-tuned Llama-3.2-Seuss-70B model
- Performance optimizations
- Public launch

**Estimated Effort:** 8-10 weeks

---

## 12. Success Metrics

### 12.1 Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Meter compliance | ≥98% | Automated scansion validation |
| Generation latency (P99) | <12 seconds | End-to-end timing |
| Test coverage | ≥80% | pytest coverage report |
| CLI installation success | 100% | Test on macOS, Linux, Windows |

### 12.2 Product Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| User smile rate | ≥90% | User study (N=20) |
| Content quality (manual review) | ≥8/10 | Expert review of 50 samples |
| Error rate | <1% | Error tracking |

---

## 13. Appendix

### 13.1 Example Prompts

**Poem Prompt:**
```
You are Dr. Seuss. Write a {lines}-line poem about "{topic}" that:
- Uses anapestic tetrameter (da-da-DUM da-da-DUM da-da-DUM da-da-DUM)
- Contains wild, creative rhymes
- Includes invented creatures or places
- Ends with a clear moral or lesson
- Is suitable for all ages (ages 5-95)

Example structure:
Line 1: da-da-DUM da-da-DUM da-da-DUM da-da-DUM
Line 2: da-da-DUM da-da-DUM da-da-DUM da-da-DUM
...

Write the poem now:
```

**Explanation Prompt:**
```
You are Dr. Seuss. Explain "{topic}" in a rhyming, whimsical way that:
- Uses anapestic tetrameter
- A {age}-year-old can understand
- Uses analogies and invented creatures to simplify complex ideas
- Ends with a clear moral or lesson
- Is fun and memorable

Write the explanation now:
```

### 13.2 Scansion Algorithm Pseudocode

```python
def scan_line(line: str) -> List[Foot]:
    words = tokenize(line)
    syllables = []
    for word in words:
        syllable_count = count_syllables(word)
        stress_pattern = get_stress_pattern(word)
        syllables.extend(stress_pattern)
    
    feet = []
    i = 0
    while i < len(syllables) - 2:
        if syllables[i] == 'U' and syllables[i+1] == 'U' and syllables[i+2] == '/':
            feet.append(Anapest())
            i += 3
        else:
            # Handle variations
            i += 1
    
    return feet

def validate_anapestic_tetrameter(feet: List[Foot]) -> bool:
    return len(feet) == 4 and all(isinstance(f, Anapest) for f in feet)
```

### 13.3 File Structure (Detailed)

```
drsai/
├── drsai/
│   ├── __init__.py
│   ├── cli.py
│   ├── commands/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── poem.py
│   │   └── explain.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── llm_client.py
│   │   ├── prompt_builder.py
│   │   └── config.py
│   ├── validation/
│   │   ├── __init__.py
│   │   ├── scansion.py
│   │   ├── rhyme_checker.py
│   │   └── quality_checker.py
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── formatting.py
│   │   └── errors.py
│   └── models/
│       ├── __init__.py
│       └── schemas.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py                # Shared fixtures + mock LLM router
│   ├── fixtures/
│   │   ├── README.md              # How to add new corpus cases
│   │   └── corpus_cases.py        # CorpusCase definitions
│   ├── unit/
│   │   ├── test_scansion.py
│   │   ├── test_llm_client.py
│   │   ├── test_prompt_builder.py
│   │   ├── test_rhyme_checker.py
│   │   ├── test_schemas.py
│   │   ├── test_config.py
│   │   └── test_cli.py
│   ├── integration/
│   │   ├── test_generation.py     # Includes corpus-based tests
│   │   └── test_explanation_generation.py
│   └── e2e/
│       └── test_cli.py            # Includes file-based CLI tests
├── pyproject.toml
├── README.md
├── .env.example
├── .gitignore
└── LICENSE
```

### 13.4 Test Fixtures Structure

```
tests/
├── __init__.py
├── conftest.py                    # Shared fixtures + mock LLM router
├── fixtures/
│   ├── README.md                  # How to add new corpus cases
│   ├── corpus_cases.py            # CorpusCase definitions
│   └── inputs/                    # (optional) dedicated input files
├── unit/
│   ├── test_scansion.py
│   ├── test_rhyme_checker.py
│   ├── test_prompt_builder.py
│   ├── test_config.py
│   └── test_schemas.py
├── integration/
│   ├── test_generation.py         # Includes corpus-based parametrized tests
│   └── ...
└── e2e/
    └── test_cli.py                # Includes file-based CLI tests
```

**Key Fixtures (from `conftest.py`):**

| Fixture | Scope | Purpose |
|---------|-------|---------|
| `mock_config` | function | Config with `LLMProvider.MOCK` for deterministic tests |
| `sample_seuss_content` | function | Default mock poem for basic tests |
| `corpus_case` | parametrize | Iterates over `CASES` from `corpus_cases.py` |
| `_patch_mock_llm_for_corpus` | session (autouse) | Routes mock LLM to golden outputs based on prompt |

### 13.5 CI/CD Workflow (Detailed)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        python-version: ["3.10", "3.11", "3.12"]

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install dependencies
        run: |
          pip install -e ".[dev]"

      - name: Run linting
        run: |
          ruff check .
          black --check .

      - name: Run type checking
        run: |
          mypy drsai

      - name: Run tests with coverage
        run: |
          pytest --cov=drsai --cov-report=xml -q

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage.xml

  publish:
    needs: test
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Build package
        run: |
          pip install build
          python -m build

      - name: Publish to PyPI
        uses: pypa/gh-action-pypi-publish@release/v1
        with:
          password: ${{ secrets.PYPI_API_TOKEN }}
```

### 13.6 Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | Yes (if using OpenAI) | — | OpenAI API key |
| `ANTHROPIC_API_KEY` | Yes (if using Anthropic) | — | Anthropic API key |
| `XAI_API_KEY` | Yes (if using xAI) | — | xAI/Grok API key |
| `DRSAI_LLM_PROVIDER` | No | `openai` | LLM provider: `openai`, `anthropic`, `xai`, `mock` |
| `DRSAI_MODEL` | No | `gpt-4o` | Model name for selected provider |
| `DRSAI_TIMEOUT` | No | `30` | API timeout in seconds |
| `DRSAI_MAX_TOKENS` | No | `2048` | Max tokens for generation |
| `DRSAI_TEMPERATURE` | No | `0.8` | Generation temperature (0.0-1.0) |
| `DRSAI_VERBOSE` | No | `false` | Enable verbose logging |

---

## 14. Changelog

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| v1.0 | 2025-12-28 | Initial implementation plan | AI Assistant |
| v1.1 | 2025-12-28 | Added Section 0 (Decisions & Open Questions), meter gate policy, Typer CLI example, aligned with PRD v0.2 | AI Assistant |
| v1.2 | 2025-12-28 | Added Section 7.6 (Corpus-Based Functional Testing), Section 13.4-13.6 (Test Fixtures, CI/CD, Env Vars), Section 14 (Changelog) | AI Assistant |
| v1.3 | 2025-12-28 | Added Sections 15-19 (Implementation Status, Prompt Engineering, Scansion Details, Troubleshooting, API Preview) | AI Assistant |

---

## 15. Current Implementation Status

This section tracks what has been built versus what remains to be implemented.

### 15.1 Component Status Matrix

| Component | Status | File(s) | Notes |
|-----------|--------|---------|-------|
| **CLI Entry Point** | ✅ Complete | `cli.py` | Typer-based, supports all flags |
| **Poem Mode** | ✅ Complete | `commands/generate.py` | 16-48 lines, meter validation |
| **Explanation Mode** | ✅ Complete | `commands/generate.py` | Age-adaptive prompts |
| **Story Mode** | ✅ Complete | `commands/generate.py` | Short (500w) / Long (800w) |
| **LLM Client** | ✅ Complete | `core/llm_client.py` | OpenAI, Anthropic, xAI, Mock |
| **Prompt Builder** | ✅ Complete | `core/prompt_builder.py` | All modes + illustration prompts |
| **Scansion Engine** | ✅ Complete | `validation/scansion.py` | NLTK + pronouncing + heuristics |
| **Rhyme Checker** | ✅ Complete | `validation/rhyme_checker.py` | CMU dict + phonetic matching |
| **Quality Checker** | ✅ Complete | `validation/quality_checker.py` | Meter + rhymes + moral detection |
| **Pydantic Schemas** | ✅ Complete | `models/schemas.py` | Request/Response models |
| **Error Handling** | ✅ Complete | `utils/errors.py` | Custom exceptions |
| **Output Formatting** | ✅ Complete | `utils/formatting.py` | Rich terminal output |
| **Configuration** | ✅ Complete | `core/config.py` | Env vars + defaults |
| **File Input (`--file`)** | ✅ Complete | `cli.py` | Markdown file support |
| **Unit Tests** | ✅ Complete | `tests/unit/` | Scansion, rhymes, prompts, config |
| **Integration Tests** | ✅ Complete | `tests/integration/` | Corpus-based tests |
| **E2E Tests** | ✅ Complete | `tests/e2e/` | CLI command tests |
| **HTTP API** | ⏳ Planned (Beta) | — | FastAPI endpoints |
| **Read-Aloud Audio** | ⏳ Planned (1.0) | — | ElevenLabs integration |
| **Recursive Mode** | ⏳ Planned (1.0) | — | Meta-Seuss generation |

### 15.2 Feature Completeness by Mode

| Mode | Generation | Validation | Illustration Prompts | File Input |
|------|------------|------------|---------------------|------------|
| Poem | ✅ | ✅ | ✅ | ✅ |
| Explain | ✅ | ✅ | ✅ | ✅ |
| Story | ✅ | ✅ | ✅ | ✅ |

### 15.3 Alpha Readiness Checklist

- [x] `drsai "topic"` executes successfully
- [x] `drsai --file input.md` reads markdown files
- [x] All three modes (poem, explain, story) work
- [x] Meter validation with regeneration loop
- [x] Illustration prompts generated
- [x] Quality metrics in verbose output
- [x] Multi-provider support (OpenAI, Anthropic, xAI, Mock)
- [x] Error handling for all edge cases
- [x] Unit tests passing
- [x] Integration tests with corpus fixtures
- [x] E2E tests with mock provider
- [ ] Performance testing (latency <12s)
- [ ] User study (N=20)
- [ ] PyPI publication

---

## 16. Prompt Engineering Reference

This section documents the actual prompts used in the implementation for reference and iteration.

### 16.1 System Persona (Shared)

```
You are Dr. Seuss (Theodor Seuss Geisel), the beloved children's author.
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
- "Oh the thinks you can think if you only try" (da-da-DUM da-da-DUM da-da-DUM da-da-DUM)
```

### 16.2 Poem Mode Prompt

```
{SEUSS_PERSONA}

Write a {lines}-line poem about: "{topic}"

Requirements:
1. EVERY line must follow anapestic tetrameter (da-da-DUM da-da-DUM da-da-DUM da-da-DUM)
2. Use AABB or AABBCCDD rhyme scheme (couplets)
3. Include at least one invented creature, place, or whimsical word
4. End with a clear, uplifting moral or lesson
5. Make it memorable, fun, and suitable for all ages
6. Each line should be its own line (use line breaks)

Write exactly {lines} lines. Begin the poem now:
```

### 16.3 Explanation Mode Prompt

```
{SEUSS_PERSONA}

Explain the following topic in a rhyming, whimsical way: "{topic}"

Requirements:
1. Use anapestic tetrameter throughout (da-da-DUM da-da-DUM da-da-DUM da-da-DUM)
2. {age_guidance}Make it understandable and memorable
3. Use analogies, invented creatures, or whimsical comparisons to simplify complex ideas
4. Create rhyming couplets (AABB pattern)
5. End with a clear moral or key takeaway
6. Keep it fun, positive, and engaging
7. Aim for 16-24 lines

Explain "{topic}" in Seuss style now:
```

**Age Guidance Variants:**
- Age ≤8: "Use very simple words and concepts a young child would understand."
- Age ≤12: "Use concepts appropriate for an elementary school student."
- Age ≤16: "Use concepts appropriate for a middle/high school student."
- Age >16: "You can use more sophisticated vocabulary while keeping it fun."

### 16.4 Story Mode Prompt

```
{SEUSS_PERSONA}

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

Write the story now:
```

### 16.5 Illustration Prompt Template

```
Whimsical Dr. Seuss-style illustration: {scene_description}

Style: Bright primary colors, exaggerated proportions, curved and fantastical shapes, 
hand-drawn quality with bold outlines, playful and magical atmosphere, 
reminiscent of classic Dr. Seuss book illustrations.

No text in the image. Child-friendly, joyful mood.
```

### 16.6 Prompt Iteration Log

| Date | Change | Rationale | Result |
|------|--------|-----------|--------|
| 2025-12-28 | Added explicit "CRITICAL" meter instruction | LLMs were inconsistent with meter | Improved compliance ~10% |
| 2025-12-28 | Added example perfect lines | Concrete examples help LLMs | More consistent rhythm |
| 2025-12-28 | Added "Count your syllables carefully" | Encourage self-checking | Slight improvement |

---

## 17. Scansion Engine Technical Details

This section documents how the meter validation engine works.

### 17.1 Algorithm Overview

```
1. TOKENIZE: Split content into lines, lines into words
2. SYLLABIFY: Count syllables per word (CMU dict → pronouncing → heuristic)
3. STRESS: Determine stress pattern per word (U = unstressed, / = stressed)
4. FEET: Identify metrical feet (anapest = UU/, iamb = U/, trochee = /U)
5. SCORE: Calculate compliance based on anapest count and pattern quality
6. AGGREGATE: Average line compliance → content compliance
```

### 17.2 Syllable Counting Strategy

| Priority | Method | Source | Accuracy |
|----------|--------|--------|----------|
| 1 | CMU Pronouncing Dictionary | NLTK `cmudict` | ~98% for common words |
| 2 | Pronouncing Library | `pronouncing` package | ~95% |
| 3 | Heuristic (vowel clusters) | Custom logic | ~80% |

**Heuristic Rules:**
- Count vowel clusters (aeiouy)
- Subtract 1 for silent 'e' at end
- Add 1 for '-le' endings after consonant
- Minimum 1 syllable per word

### 17.3 Stress Pattern Detection

```python
# CMU dictionary format: phonemes with stress markers (0, 1, 2)
# 0 = no stress, 1 = primary stress, 2 = secondary stress
# We map: 0 → U (unstressed), 1/2 → / (stressed)

# Example: "computer" → K AH0 M P Y UW1 T ER0
#                     → U / U (3 syllables: unstressed, stressed, unstressed)
```

### 17.4 Anapestic Tetrameter Validation

**Perfect Pattern:** `UU/UU/UU/UU/` (12 syllables, 4 anapests)

**Acceptable Variations:**
- 9-13 syllables (real poetry varies)
- Iambs (U/) can substitute for anapests
- Line can start with stressed syllable (anacrusis)

**Scoring:**
- 4+ anapests → 100%
- 3 anapests + iamb → ~90%
- 2 anapests + iambs → ~70%
- Fewer → proportionally lower

### 17.5 Line Compliance Threshold

```
is_anapestic = compliance_score >= 0.80
```

### 17.6 Content Compliance Calculation

```python
content_compliance = compliant_lines / total_lines

# Thresholds (from config):
is_acceptable = compliance >= 0.98  # Target
is_degraded = 0.95 <= compliance < 0.98  # Warning
is_failed = compliance < 0.95  # Error
```

---

## 18. Troubleshooting Guide

### 18.1 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `ModuleNotFoundError: pydantic` | Dependencies not installed | `pip install drsai` or `pip install -e ".[dev]"` |
| `ConfigurationError: API key not found` | Missing environment variable | Set `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `XAI_API_KEY` |
| `GenerationError: timeout` | LLM API slow | Increase `DRSAI_TIMEOUT` or use faster model |
| Meter compliance too low | LLM not following instructions | Try different topic, shorter lines, or different provider |
| `LookupError: cmudict` | NLTK data not downloaded | Run `python -c "import nltk; nltk.download('cmudict')"` |
| CLI not found after install | Not in PATH | Use `pipx install drsai` or add `~/.local/bin` to PATH |

### 18.2 Debugging Commands

```bash
# Check installation
drsai --version

# Test with mock provider (no API key needed)
drsai generate "testing" --provider mock

# Verbose output with metrics
drsai generate "recursion" --verbose

# Validate existing text
drsai validate "The cat in the hat sat on a mat"

# Check environment
python -c "from drsai.core.config import Config; print(Config.from_env())"
```

### 18.3 Performance Optimization

| Symptom | Cause | Fix |
|---------|-------|-----|
| Slow first run | NLTK downloads cmudict | Pre-download: `nltk.download('cmudict')` |
| Slow generation | Large model or complex topic | Use `gpt-4o-mini` or simplify topic |
| Multiple retries | Low meter compliance | Improve prompt or accept degraded output |
| High API costs | Many regenerations | Lower `max_regeneration_attempts` in config |

### 18.4 Error Codes Reference

| Code | Meaning | Action |
|------|---------|--------|
| `CONFIGURATION_ERROR` | Missing or invalid config | Check environment variables |
| `GENERATION_ERROR` | LLM API failed | Retry or check API status |
| `GENERATION_TIMEOUT` | Request exceeded timeout | Increase timeout or use faster model |
| `VALIDATION_ERROR` | Invalid input | Check topic length, mode, etc. |
| `INVALID_MODE` | Unknown generation mode | Use `poem`, `explain`, or `story` |
| `FILE_NOT_FOUND` | `--file` path invalid | Check file path exists |
| `RATE_LIMITED` | Too many API requests | Wait and retry |

---

## 19. API Design Preview (Beta)

This section previews the HTTP API planned for Beta. The internal schemas (`GenerationRequest`, `GenerationResponse`) are already designed for API compatibility.

### 19.1 Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/v1/generate/poem` | Generate Seuss poem |
| POST | `/v1/generate/explain` | Generate rhyming explanation |
| POST | `/v1/generate/story` | Generate Seuss story |
| POST | `/v1/validate` | Validate text for meter |
| GET | `/v1/health` | Health check |

### 19.2 Request/Response Schema (Already Implemented)

**GenerationRequest:**
```python
class GenerationRequest(BaseModel):
    topic: str                    # 1-10000 chars
    mode: GenerationMode          # poem | explain | story
    lines: int = 32               # 16-48 (poem mode)
    age: Optional[int] = None     # 5-95 (explain mode)
    length: str = "short"         # short | long (story mode)
```

**GenerationResponse:**
```python
class GenerationResponse(BaseModel):
    content: str                  # Generated text
    mode: GenerationMode          # Mode used
    meter_score: float            # 0.0-1.0 compliance
    quality: Optional[QualityScore]
    warning: Optional[str]        # If degraded
    moral: Optional[str]          # Extracted moral
    illustration_prompts: list[str]
    generation_attempts: int      # Retry count
```

### 19.3 Example API Flow (Preview)

```bash
# Generate poem
curl -X POST http://localhost:8000/v1/generate/poem \
  -H "Content-Type: application/json" \
  -d '{"topic": "recursion", "lines": 24}'

# Response
{
  "content": "The code that calls itself, oh my!...",
  "mode": "poem",
  "meter_score": 0.98,
  "quality": {...},
  "moral": "With patience and loops, you'll see the way!",
  "illustration_prompts": [...],
  "generation_attempts": 1
}
```

### 19.4 API Implementation Tasks (Beta Backlog)

| Task | Priority | Est. Hours |
|------|----------|------------|
| Set up FastAPI project structure | P1 | 4 |
| Implement `/v1/generate/*` endpoints | P1 | 8 |
| Implement `/v1/validate` endpoint | P1 | 4 |
| Add request validation middleware | P1 | 4 |
| Add rate limiting (IP-based) | P1 | 6 |
| Add API key authentication | P2 | 8 |
| Add OpenAPI documentation | P1 | 2 |
| Write API integration tests | P1 | 8 |
| Deploy to cloud (AWS/GCP) | P1 | 8 |
| **Total** | | **52 hours** |

---

## Conclusion

This implementation plan provides a clear roadmap for building the DrSAI MVP. The phased approach allows for iterative development, risk mitigation, and validation at each stage. The focus on P0 features (CLI, Poem mode, Explanation mode) ensures we deliver core value quickly while building a foundation for future enhancements.

**Key Success Factors:**
1. Start with prompt engineering (faster than fine-tuning)
2. Build scansion engine early (critical for quality)
3. Iterate based on user feedback (Alpha user study)
4. Optimize for latency from the start (caching, model selection)

**Next Action:** Begin Phase 1 (Foundation) - Set up project structure and CLI skeleton.

---

*"Oh, the thinks you can think when DrSAI is around!"*

**Ship it.**

