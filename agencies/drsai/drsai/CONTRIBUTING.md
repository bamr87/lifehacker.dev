# Contributing to DrSAI

Thank you for your interest in contributing to DrSAI! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites

- Python 3.10 or higher
- pip (or pipx for isolated installation)
- Git

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/drsai/drsai.git
   cd drsai/drsai
   ```

2. **Create a virtual environment:**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install in development mode:**
   ```bash
   pip install -e ".[dev]"
   ```

4. **Download NLTK data:**
   ```bash
   python -c "import nltk; nltk.download('cmudict')"
   ```

5. **Install pre-commit hooks (optional but recommended):**
   ```bash
   pip install pre-commit
   pre-commit install
   ```

## Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=drsai --cov-report=term-missing

# Run specific test file
pytest tests/unit/test_scansion.py

# Run with verbose output
pytest -v
```

## Code Style

We use the following tools for code quality:

- **Ruff** for linting
- **Black** for formatting
- **MyPy** for type checking

```bash
# Run linting
ruff check src/

# Run formatting check
black --check src/ tests/

# Apply formatting
black src/ tests/

# Run type checking
mypy src/drsai/
```

## Project Structure

```
drsai/
├── src/drsai/          # Source code
│   ├── cli.py          # CLI entry point
│   ├── commands/       # Command handlers
│   ├── core/           # LLM client, prompts, config
│   ├── validation/     # Scansion engine, rhyme checker
│   ├── utils/          # Formatting, errors
│   └── models/         # Pydantic schemas
├── tests/              # Test suite
│   ├── unit/           # Unit tests
│   ├── integration/    # Integration tests
│   ├── e2e/            # End-to-end tests
│   └── fixtures/       # Test fixtures and corpus
├── pyproject.toml      # Package configuration
└── README.md
```

## Adding New Features

### 1. Create a feature branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Write tests first (TDD encouraged)

Add tests to the appropriate directory:
- `tests/unit/` for isolated function tests
- `tests/integration/` for component integration
- `tests/e2e/` for CLI command tests

### 3. Implement the feature

Follow existing code patterns and conventions.

### 4. Update documentation

- Update README.md if adding user-facing features
- Add docstrings to new functions/classes
- Update IMPLEMENTATION_PLAN.md if relevant

### 5. Submit a Pull Request

- Ensure all tests pass
- Ensure linting passes
- Write a clear PR description

## Adding Test Corpus Cases

To add new input/output examples for functional testing:

1. Add input file (if any) to repo root or `tests/fixtures/inputs/`
2. Add expected output file
3. Create a new `CorpusCase` in `tests/fixtures/corpus_cases.py`
4. Add routing rule in `tests/conftest.py` if needed

See `tests/fixtures/README.md` for details.

## Commit Messages

Use clear, descriptive commit messages:

```
feat: Add story mode generation
fix: Correct syllable counting for compound words
test: Add corpus test for explanation mode
docs: Update README with new CLI options
```

## Pull Request Process

1. Update any relevant documentation
2. Add tests for new functionality
3. Ensure CI passes (tests, linting, type checking)
4. Request review from maintainers
5. Address feedback and iterate

## Code of Conduct

Be kind, respectful, and constructive. We're all here to build something whimsical and wonderful!

## Questions?

Open an issue or reach out to the maintainers.

---

*"Oh, the thinks you can think when DrSAI is around!"*


