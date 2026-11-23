# 🎩 DrSAI – Doctor Seuss Artificial Intelligence

> *Oh, the thinks you can think when DrSAI is around!*

Generate whimsical, rhyming content in the authentic style of Dr. Seuss. DrSAI transforms any topic into memorable poems, explanations, and stories with proper anapestic tetrameter meter and wild rhymes.

## ✨ Features

- **Poem Mode**: Generate 16-48 line Seuss poems with validated meter
- **Explanation Mode**: Transform complex topics into rhyming, kid-friendly explanations
- **Story Mode**: Create 500-800 word Seuss-style stories (Beta)
- **Meter Validation**: Automated scansion engine ensures ≥98% anapestic tetrameter compliance
- **Illustration Prompts**: Get DALL-E/Midjourney-ready prompts for your content
- **Multiple LLM Providers**: Support for OpenAI, Anthropic, and more

## 🚀 Installation

```bash
# Install from PyPI
pip install drsai

# Or use pipx for isolation (recommended)
pipx install drsai
```

## 📖 Quick Start

```bash
# Generate a poem about recursion
drsai generate "explain recursion"

# Explain quantum computing for an 8-year-old
drsai generate "quantum computing" --mode explain --age 8

# Create a story about sharing
drsai generate "the importance of sharing" --mode story --length long

# Generate a 24-line poem
drsai generate "the joy of coding" --mode poem --lines 24

# Validate meter of existing text
drsai validate "The cat in the hat sat on a mat"
```

## 🔧 Configuration

Set your API keys in environment variables or a `.env` file:

```bash
# For OpenAI (default)
export OPENAI_API_KEY=your-key-here

# For Anthropic Claude
export ANTHROPIC_API_KEY=your-key-here
export DRSAI_LLM_PROVIDER=anthropic
```

Or use the mock provider for testing:

```bash
drsai "test topic" --provider mock
```

## 📋 CLI Options

```
Usage: drsai [OPTIONS] COMMAND [ARGS]

Commands:
  generate   Generate Dr. Seuss-style content about any topic
  validate   Validate text for anapestic tetrameter compliance

Generate Options:
  TOPIC               The topic to generate Seuss-style content about [required]
  -m, --mode TEXT     Generation mode: poem, explain, or story [default: poem]
  -l, --lines INT     Number of lines for poem mode (16-48) [default: 32]
  -a, --age INT       Target age for explanation mode (5-95)
  --length TEXT       Story length: short (500 words) or long (800 words)
  -p, --provider TEXT LLM provider: openai, anthropic, or mock
  -v, --verbose       Show detailed output including metrics
  --prompts           Show illustration prompts in output
  -V, --version       Show version and exit
  --help              Show this message and exit
```

## 🎯 Examples

### Poem Mode

```bash
$ drsai generate "the internet"

✨ The Internet ✨

  In cables and waves that go zipping along,
  The Internet hums its electrical song.
  It carries our messages, pictures, and more,
  From this side of the world to that distant shore!
  ...
```

### Explanation Mode

```bash
$ drsai generate "photosynthesis" --mode explain --age 8

  The plants have a trick that they do every day,
  They gobble up sunlight in their own special way!
  With water and air (that's CO2),
  They make their own food—it's amazing but true!
  ...
```

### Story Mode

```bash
$ drsai generate "being kind to others" --mode story --length short
```

## 📊 Meter Validation

DrSAI includes a built-in scansion engine that validates anapestic tetrameter:

```bash
$ drsai validate "The cat in the hat sat on a mat"

📊 Meter Analysis
   Compliance: 100%
   Status: ✅ Acceptable
```

## 🎨 Illustration Prompts

Get DALL-E/Midjourney prompts for your generated content:

```bash
$ drsai generate "a friendly robot" --prompts

🎨 Illustration Prompts:
  1. Whimsical Dr. Seuss-style illustration: A tall robot with springy legs...
  2. ...
```

## 🔌 As a Library

```python
from drsai.commands.generate import generate

# Generate a poem
response = generate("recursion", mode="poem", lines=24)
print(response.content)
print(f"Meter score: {response.meter_score:.0%}")

# Generate an explanation for kids
response = generate("gravity", mode="explain", age=6)
print(response.content)
print(f"Moral: {response.moral}")
```

## 🏗️ Architecture

```
drsai/
├── src/drsai/
│   ├── cli.py              # CLI entry point
│   ├── commands/           # Command handlers
│   ├── core/               # LLM client, prompts, config
│   ├── validation/         # Scansion engine, rhyme checker
│   ├── utils/              # Formatting, errors
│   └── models/             # Pydantic schemas
├── tests/                  # Test suite
├── pyproject.toml
└── README.md
```

## 🧪 Development

```bash
# Clone the repository
git clone https://github.com/drsai/drsai.git
cd drsai

# Install in development mode
pip install -e ".[dev]"

# Run tests
pytest

# Run linting
ruff check .
black --check .
mypy drsai
```

## 📈 Quality Targets

| Metric | Target |
|--------|--------|
| Meter Compliance | ≥98% anapestic tetrameter |
| Latency (P99) | <12 seconds |
| Test Coverage | ≥80% |

## 🗺️ Roadmap

- **Alpha (Current)**: CLI + Poem + Explanation modes
- **Beta**: Story mode + Illustration prompts + API
- **1.0**: Read-aloud audio + Recursive mode

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

Inspired by the whimsical genius of Dr. Seuss (Theodor Seuss Geisel).

---

*"Oh, the thinks you can think when DrSAI is around!  
Reality rhymed. Joy manufactured."*

**Ship it.** 🚀

