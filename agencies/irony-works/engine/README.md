# The Engine

Five prompts, three scripts, one gate — and a second genus with three prompts and a gate of its own.

## Prompts (`prompts/`)
- **scout.md** — proposes candidate ironies for the cycle's domain
- **scribe.md** — drafts a candidate into the entry schema
- **alanis-gate.md** — the rubric; scores 0–10, verdicts below threshold
- **linker.md** — weaves new entries into the graph with wikilinks
- **gardener.md** — maintenance pass: dedupe, stale links, futures that matured

### The paradox genus (`prompts/paradox/`)
- **scout.md** — proposes candidate paradoxes for the cycle's family: old, new, debated, or hypothetical
- **scribe.md** — drafts a candidate against `vault/templates/paradox.md` (premises, inference, conclusion, collision; kind, standing, hypothesis, fault)
- **epimenides-gate.md** — the rubric: plausibility, validity, collision, cost, specificity; verdicts MERELY-SURPRISING · EQUIVOCATION · TRANSPARENT-FALLACY · DILEMMA · ANOMALY · NOT-EVEN-WRONG

The framework these prompts enforce is `vault/the-anatomy-of-a-paradox.md`.

## Scripts (`scripts/`)
- **lib.mjs** — harness call (Claude Code CLI on OAuth, API-key fallback), config, path guardrails, and `genusOf()` / `parseDomain()`: the lookup that turns a rotation entry into a template, a prompt set, a threshold, and a ledger
- **germinate.mjs** — full cycle: scout → gate → scribe → nursery + compost, for whichever genus the rotation entry names (`history-of-science` is irony; `paradox:time-and-physics` is paradox). `GERMINATE_DOMAIN` overrides the rotation for one run.
- **gate.mjs** — standalone gate for PR checks (used by alanis-gate.yml); routes each file by its `type:` frontmatter and reports notes with nothing to score as UNGATED
- **transplant.mjs** — vault → Jekyll collection (wikilinks → permalinks) for zer0-mistakes publishing
- **preview.mjs** — deterministic hero art, one plate per note
- **usage-ledger.mjs** — rolls the per-run meter into AI_USAGE.md

## Configuration
`seed.config.yml → genera` declares each genus: `template`, `prompts` (scout, scribe, gate — names under `prompts/`), and `gate` (`threshold`, `compost`). `domains` is the rotation; prefix an entry with `paradox:` to grow that genus. Both compost ledgers are in `guardrails.writable`; nothing else is.

## Swapping the harness
`seed.config.yml → harness.provider`. The default (`claude-code`) runs prompts through the Claude Code CLI, which brings its own OAuth credentials — the keychain locally, a `CLAUDE_CODE_OAUTH_TOKEN` secret in CI (generate one with `claude setup-token`). If the CLI is missing or can't authenticate, the engine falls back to the [Claude API](https://docs.claude.com/en/api/overview) with `ANTHROPIC_API_KEY`; set `provider: anthropic` to skip the CLI entirely. The `lifehacker` provider is a stub in `lib.mjs` marked `// HARNESS ADAPTER` — point it at the lifehacker.dev endpoint and env var, and every prompt in this directory flows through it unchanged. Prompts are the contract; the wire is an implementation detail.
