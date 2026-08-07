# CLAUDE.md

Guidance for AI coding agents (Claude Code, Copilot, Cursor) working in **lifehacker.dev**.

**lifehacker.dev** is a satirical-but-actually-working Jekyll site ("Surviving life, one byte at a time") on the `bamr87/zer0-mistakes` remote theme — ~200 posts across three news sections (Hacks / Tools / Field Notes under `pages/_posts/<section>/`) plus `pages/_docs/`, published by an autonomous Claude Code fleet and merged by a human. The repo **is** the CMS: brand, backlog, ledgers, and health all live in-tree as data files. Its sister sites are it-journey.dev (the game — same theme, opposite temperament) and bash-365.com (BASH Consulting). "Done" here means: the test harness is green, the content is on-voice per `_data/brand/`, and a human merges the PR — agents never merge.

## Read-by-task

| Task | Read first |
|---|---|
| Operating the autopilot / guardrails | `AUTOPILOT.md` (the operator's guide — the repo is the CMS) |
| System design / findings contracts | `docs/ARCHITECTURE.md` (Test → Report → Balance; `findings.jsonl` / `queue.json` are frozen contracts) |
| Workflows + enable switches | `docs/CICD.md` (every AI loop is OFF until its `*_ENABLED` repo variable is set) |
| Brand / voice / satire rules | `_data/brand/{identity,voice,glossary,accepted}.yml` — the Prime Directive lives in `identity.yml` |
| Preview banners / cover art | `docs/PREVIEW-IMAGES.md` (the framework) + `docs/TRACE-BLOOM.md` (the aesthetic); tokens in `_data/preview/design.json` |
| Author personas & byline rotation | `_data/authors.yml` (amr, claude, cass, edge) + `scripts/fleet/authors.rb` |
| A specific agent role or skill | `.claude/agents/*.md`, `.claude/skills/*/SKILL.md` |

## Stack & commands

```bash
bundle install              # deps (github-pages + remote theme; lockfile is committed on purpose)
scripts/preview.sh          # local preview: overlay onto a theme clone + docker compose up → http://localhost:4000
scripts/ci/run-all.sh       # full test harness (Pages safe-mode build + frontmatter/brand/drift/link lints → test-results/findings.jsonl)
scripts/ci/build.sh         # just the Pages-parity build (safe mode, _plugins stripped)
python3 tools/unwrap-prose.py --check   # one-paragraph-per-line gate (markdown-oneline.yml)
node scripts/preview/generate.mjs -f <article.md>   # cover art (Trace Bloom; offline, zero-dep)
```

The harness scripts are the same ones CI runs (`pipeline.yml`, required check = `verify`); run them before opening a PR. Frontmatter required keys: `title description date author excerpt tags` (`preview:` is warn-only). Posts pin explicit permalinks (`/hacks/:slug/`, `/tools/:slug/`) — the old collections were folded into `posts` in issue #337, so never "fix" a permalink to match the collection default.

## Conventions

- Conventional Commits: `type(scope): description` (`feat`/`fix`/`docs`/`refactor`/`test`/`chore`/`ci`).
- Default branch is `main` — branch from it and open a PR; never push to it directly.
- README-First, README-Last: read the nearest `README.md` before changing a
  directory, and update it after.
- Don't suppress type errors (`as any`, `@ts-ignore`, `# type: ignore`) or
  leave empty exception handlers.
- Brand voice is enforced in tiers: deterministic `scripts/ci/lint_brand.rb` (only `avoid_phrases` hard-fail), then the `brand-reviewer` agent judges satire-vs-sincere; adjudicated uses go in `_data/brand/accepted.yml` — don't rewrite prose just to silence a `satire_suspected` warning.
- Theme bugs go upstream to `bamr87/zer0-mistakes`, never patched around locally.

## Fleet context

This repo is one of ~40 managed by the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87) (registry: `_data/projects.yml`; tiered baseline: `docs/STANDARDS.md`). It is vendored there as a git submodule: commit and push changes **here** first — the hub only bumps its pointer afterwards. Shared CI, release, schema, and agent kits are seeded from the hub's `templates/`; prefer adopting those over hand-rolling equivalents.
