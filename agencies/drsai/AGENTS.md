# AGENTS.md

Guidance for AI coding agents (Claude Code, Copilot, Cursor) working in **drsai**.

drsai is a children's book platform: a Jekyll site (zer0-mistakes remote theme, `books` collection) publishing AI-written, AI-illustrated picture books on GitHub Pages, plus the Python story engine in `drsai/` and the import/illustration tools in `tools/`. "Done" for site changes means the site builds through zer0-CMS's Jekyll-theme option (`python3 ../../tools/jekyll_theme.py build drsai`, which needs Docker) and the book renders; see `README.md` for the full pipeline. There is no Gemfile: the option pins the theme's tag in the root `workspace.yml` and builds with GitHub Pages' own builder in a container, so no Ruby is installed here.

## Stack & commands

```bash
# install dependencies:
cd drsai && pip install -e ".[dev]"                # story engine

# build the site (Docker; the theme at its pinned tag, GitHub Pages' builder) into _site/:
python3 ../../tools/jekyll_theme.py build drsai

# run tests:
cd drsai && pytest                                  # engine tests
python3 tools/import_dodge_and_reena.py --check     # imported book matches content repo
python3 tools/import_abc_book.py --check            # ABC books match their spec sidecar

# lint:
cd drsai && ruff check src/ && black --check src/ tests/
python3 ../../tools/unwrap-prose.py --check               # markdown one-paragraph-per-line
```

Content rule: `pages/_books/**` is GENERATED — never hand-edit the generated pages. Story books come from the Dodge-and-Reena-Book repo via `tools/import_dodge_and_reena.py`. **ABC books** (`book-abc` layout, the "ABC & Language" series) come from the [zer0-CMS](https://github.com/bamr87/zer0-CMS) ABC wizard, which writes `pages/_books/<slug>/index.md` plus the canonical spec sidecar `_data/abc_books/<slug>.json`; `tools/import_abc_book.py --check` guards the page against its spec. Missing illustrations render via `tools/generate_illustrations.py` (OpenAI Images API, needs `OPENAI_API_KEY`) — it handles story `illustrations:`, book covers, and ABC `alphabet:` plates.

## Conventions

- Conventional Commits: `type(scope): description` (`feat`/`fix`/`docs`/`refactor`/`test`/`chore`/`ci`).
- Default branch is `main` — branch from it and open a PR; never push to it directly.
- README-First, README-Last: read the nearest `README.md` before changing a directory, and update it after.
- Don't suppress type errors (`as any`, `@ts-ignore`, `# type: ignore`) or leave empty exception handlers.

## Fleet context

This repo is one of ~40 managed by the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87) (registry: `_data/projects.yml`; tiered baseline: `docs/STANDARDS.md`). It is vendored there as a git submodule: commit and push changes **here** first — the hub only bumps its pointer afterwards. Shared CI, release, schema, and agent kits are seeded from the hub's `templates/`; prefer adopting those over hand-rolling equivalents.
