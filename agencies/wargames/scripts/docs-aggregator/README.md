# Documentation Aggregator

Pipeline for aggregating external documentation. In this repo it mirrors the OverTheWire wargames. It clones external repositories, extracts documentation, transforms it to Jekyll-compatible markdown with provenance frontmatter, and stages the result under `pages/_docs/`. The staged pages are then moved into `overthewire/` (see [Applying a re-sync](#applying-a-re-sync)); the pipeline does not write there itself.

## Quick Start

```bash
# Install dependencies
pip3 install -r scripts/docs-aggregator/requirements.txt

# Run the full pipeline
bash scripts/docs-aggregator/aggregate_docs.sh

# Build Jekyll to verify
bundle exec jekyll build
```

## How It Works

```
docs_config.yml          # Define sources
       │
       ▼
aggregate.py             # Clone repos → extract files → stage to work/
       │
       ▼
transform.py             # Parse → add frontmatter → rewrite links → output
       │
       ▼
pages/_docs/<category>/  # Jekyll-ready pages, staged for review
```

### Pipeline Steps

1. **Aggregate** (`aggregate.py`): Reads `docs_config.yml`, clones repositories to `work/docs-aggregator/repos/`, extracts matching files to `work/docs-aggregator/raw/`, writes a `manifest.yml` for the next step.

2. **Transform** (`transform.py`): Reads the manifest, processes each raw file — parses existing frontmatter, generates frontmatter (title, description, date, categories, tags, `nav_order` and `sidebar_label` for wargames levels, permalink, source attribution), rewrites relative links to GitHub URLs, strips incompatible Jekyll includes, and writes the final output to `pages/_docs/<category>/<source>/`.

3. **Orchestrate** (`aggregate_docs.sh`): Shell wrapper that runs both steps in order with logging, error handling, and cleanup.

## Files

| File | Purpose |
|------|---------|
| `docs_config.yml` | Source repository registry — defines what to aggregate |
| `aggregate.py` | Clone and extract documentation from external repos |
| `transform.py` | Transform raw docs into Jekyll pages with frontmatter |
| `aggregate_docs.sh` | Shell orchestrator for the full pipeline |
| `requirements.txt` | Python dependencies (PyYAML) |

## Configuration

### Adding a New Source

Edit `docs_config.yml` to add a new source repository:

```yaml
sources:
  - name: my-source           # Short ID (used as subdirectory name)
    repo: https://github.com/org/repo
    branch: main              # Branch to clone
    content_paths:            # Directories to extract from
      - docs/
      - guides/
    framework: plain          # jekyll | hugo | mkdocs | plain
    category: my-category     # Target subdir under pages/_docs/
    description: "Description of the source"
    tags:
      - tag1
      - tag2
    license: MIT              # SPDX identifier
    license_url: https://github.com/org/repo/blob/main/LICENSE
    exclude_patterns:         # Globs to skip
      - "*.html"
      - "img/"
    include_extensions:       # File types to include
      - .md
```

### Configuration Fields

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `name` | Yes | — | Short identifier, used as directory name |
| `repo` | Yes | — | Git clone URL |
| `branch` | No | `main` | Branch to checkout |
| `content_paths` | No | `["."]` | Paths within repo to extract |
| `framework` | No | `plain` | Source framework type |
| `category` | Yes | — | Target subdirectory under `_docs/` |
| `description` | No | — | Human-readable description |
| `tags` | No | `[]` | Tags applied to all pages |
| `license` | No | — | SPDX license identifier |
| `license_url` | No | — | URL to license file |
| `exclude_patterns` | No | `[]` | Glob patterns to skip |
| `include_extensions` | No | `[.md]` | File extensions to include |

## Directory Structure

```
scripts/docs-aggregator/     # Pipeline scripts (this directory)
work/docs-aggregator/        # Staging area (not currently in .gitignore; delete after use)
  ├── repos/                 # Cloned repositories
  ├── raw/                   # Extracted raw files
  ├── manifest.yml           # Inter-step metadata
  └── ...                    # Optional artifacts
pages/_docs/                 # Output (staging only; delete after moving pages over)
  └── wargames/              # Category from OverTheWire
      └── overthewire/       # Source-specific content, laid out like overthewire/ in the repo root
```

## Options

### aggregate_docs.sh

```
Usage: aggregate_docs.sh [OPTIONS]

  --config PATH   Path to docs_config.yml
  --clean         Remove work/ staging area before running
  --help          Show help
```

### aggregate.py

```
Usage: aggregate.py [--config path] [--work-dir path]

  --config     Path to docs_config.yml (default: ./docs_config.yml)
  --work-dir   Working directory (default: ../../work/docs-aggregator)
```

### transform.py

```
Usage: transform.py [--work-dir path] [--output-dir path] [--nav-output path]

  --work-dir     Working directory with manifest.yml (default: ../../work/docs-aggregator)
  --output-dir   Output directory (default: ../../pages/_docs)
  --nav-output   Optional path for navigation YAML fragment
```

## Current Sources

| Source | Category | Description |
|--------|----------|-------------|
| [OverTheWire](https://github.com/OverTheWireOrg/OverTheWire-website) | `wargames` | Security wargames — Linux basics to binary exploitation |

## Limitations

- **Markdown only**: Currently processes `.md` files. HTML-to-Markdown conversion is planned.
- **No AI enhancement**: Deterministic transformation only. AI-powered quality scoring is a future feature.
- **Relative links**: Rewritten to point to source repo on GitHub, not resolved locally.
- **Internal links use Liquid**: `normalize_overthewire_links()` rewrites upstream's absolute `/wargames/<game>/…` links to `{{ '/docs/wargames/<game>/…' | relative_url }}` so they resolve under the site's `baseurl`, and `absolutize_relative_images()` points relative `<img src>` at overthewire.org (a bare relative path would 404 here).
- **Dead upstream links**: the Blacksun reading list links to `papers/…` files that 404 on overthewire.org too; they cannot be repointed.
- **Description extraction**: `description` is taken from the first paragraph of the body, which for many level pages is a heading underline such as `Level Goal ----------`. The study guides replace it with a real summary; see [Applying a re-sync](#applying-a-re-sync).

## Sidebar Navigation

- The wargames sidebar is built by the theme's `nav: pages` mode, configured on the `overthewire` scope in `_config.yml`. The pipeline sets no per-page `sidebar`, because one would override the config.
- Each level page gets `nav_order` (its numeric suffix) and `sidebar_label` (`"Level N"`) so levels sort 0, 1, 2, …, 10 and drop the game prefix.
- No navigation data file is committed. `transform.py --nav-output ...` can still be used for ad-hoc debugging, but it is optional.

## Applying a re-sync

The pipeline writes only to `pages/_docs/`. To refresh the site's pages:

1. Run `bash scripts/docs-aggregator/aggregate_docs.sh`.
2. Run `python3 ../../tools/unwrap-prose.py --write pages/_docs/wargames/overthewire`. The repo keeps one paragraph per line (CI enforces it) and fresh upstream text is soft-wrapped.
3. Run `python3 tools/carry-study-guides.py pages/_docs/wargames/overthewire`. The pipeline regenerates each page from upstream, which discards the site's own additions: the **Study guide** section (between the `<!-- study-guide:start -->` and `<!-- study-guide:end -->` markers) and front matter the site owns (`description`, `excerpt`, `title`, `author`, `draft`, `keywords`, the game category, `date`). The tool carries those from the current `overthewire/` page, takes provenance keys (`source_*`, `permalink`, `nav_order`, …) from the fresh page, and keeps `lastmod` when the upstream text did not change. It lists pages it cannot match, such as a level added upstream, which need a guide written for them.
4. Review the upstream changes with `diff -r pages/_docs/wargames/overthewire overthewire`. With no upstream change this is empty, so anything that shows up is a real change.
5. Move the pages over with `cp -R pages/_docs/wargames/overthewire/. overthewire/`.
6. Delete `pages/` and `work/`, then run `bundle exec jekyll build` and `python3 ../../tools/unwrap-prose.py --check`.

## Troubleshooting

**"PyYAML is required"**: Install with `pip3 install pyyaml`

**"Manifest not found"**: Run `aggregate.py` before `transform.py`, or use `aggregate_docs.sh` which runs both.

**Jekyll build fails**: Check that generated frontmatter is valid YAML. Run `python3 -c "import yaml; yaml.safe_load(open('file.md').read().split('---')[1])"` on a problematic file.

---

**Version:** 1.0.0 | **Last Modified:** 2025-01-27
