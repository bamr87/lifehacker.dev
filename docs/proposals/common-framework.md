# One framework for content sites and AI harnesses

**Status:** proposal + first implementation round (2026-09-08). **Scope:** the eleven repos in the fleet workspace — lifehacker.dev, it-journey, zer0-mistakes, bash-365.com, ai-world-view.github.io, irony-works, gitorio, zer0-CMS, zer0-image-generator, aieo, SCHEMA — reviewed on 2026-09-06 by six parallel surveys (AI runner, content verification, agent guidance, CI workflows, preview images, repo baseline). This document records what the surveys found, names one canonical home per layer, writes down the conventions, and lists the pull-request series that moves the fleet there. It is a plan the owner can accept in pieces; every step leaves its repo better on its own.

## The short version

The common framework already exists — in two places — and most of the drift is in the layers those two places never seeded.

| Layer | Canonical home today | Mechanism | State on 2026-09-06 |
| --- | --- | --- | --- |
| Repo baseline (README, LICENSE, CI caller, `.editorconfig`, agent context) | `bamr87/bamr87` hub — `_data/standards.yml`, `specs/` (UPS 1.0), `templates/<kit>/` | `tools/fanout.sh` (byte-compare `--upgrade`), `standardize-fanout.yml` | Adopted; 20 repos are byte-identical `standard-ci` callers |
| `@claude` mention handler, `.claude/settings.json`, shared guardrails, agent-auditor | hub `templates/agent-context/` v0.4.0 | same fan-out | 4 shapes of `claude.yml` in the fleet; guardrails doc in 2 repos, 3 shapes |
| One-paragraph-per-line prose gate | hub `templates/prose/` v0.3.0 (self-healing) + vendored `tools/unwrap-prose.py` | `fanout.sh --kit prose` | `unwrap-prose.py` identical in 7 repos; the workflow in 5 shapes (4 repos still on the check-only 0.2.0) |
| Theme coupling (pin bumps, overrides audit) | `zer0-mistakes/templates/consumer/` + `_data/consumers.yml` + `propagate.rb` | `propagate-theme.yml` dispatch | Zero of five consumers carry the receiving workflow — the dispatch lands nowhere |
| **The AI runner** (`scripts/ai/run.sh`, `_data/ai.yml`, `.github/actions/claude-run`) | none — three forks (lifehacker → it-journey → zer0-mistakes) | hand copy | it-journey exits 0 on a dead credential; zer0-mistakes exits 0 on install failure; only lifehacker meters |
| **Content verification** (frontmatter, brand/voice, findings) | none — four validators, four brand linters in three languages | hand copy | Only lifehacker emits a machine-readable `findings.jsonl`; ai-world-view's copy of `content-review.rb` had drifted from the canonical one |
| **Fleet inventory** (`fleet.manifest.yml`, spec `fleet/v1`) | `bamr87/wtd` (`wtd fleet adopt`) | run by hand | 2 of 10 AI-running repos had one; the tool did not detect the composite `claude-run` harness |
| Preview / cover images | `zer0-image-generator` (engine, providers, Claude review loop) | gem + CLI | 5 generations of `generate-preview-images.sh` / `preview_generator.py` across 4 repos; lifehacker's Trace Bloom is a separate, better offline generator |

So the target is not a new framework. It is: (1) promote the three unseeded layers into kits with the same discipline the hub already uses (a `VERSION`, an `archive/`, byte-compare adoption), (2) finish adopting the kits that exist, and (3) write the conventions down once.

## What the surveys found

### AI runner — three dialects, two of them unsafe

| Implementation | Auth | Exit on a dead credential | Metering | Turn cap |
| --- | --- | --- | --- | --- |
| lifehacker.dev `scripts/ai/run.sh` + `claude-run` | OAuth-first, enforced (`env -u ANTHROPIC_API_KEY`) | **1**, with the reason and an operator hint | JSONL per call, sticky PR comment, nightly ledger | none |
| it-journey `scripts/ai/run.sh` | OAuth-first by comment only; both keys reach the CLI | **0** (a revoked token yields green runs forever) | none | none |
| zer0-mistakes `claude-run/action.yml` | OAuth-first, enforced | **0** on install failure; `--output-format text` discards usage | none | none |
| bash-365.com (claude-code-action inline) | both credentials passed unconditionally | n/a | none | 40 |
| irony-works `engine/lib.mjs` | CLI → API fallback | throws, falls back | per-run JSON with `billed:` | n/a |

Every other Claude call site (gitorio's compiler, aieo's `claude_cli.py`, ai-world-view's `grow-lineage.yml`, zer0-CMS's optional agent SDK, zer0-image-generator's client) is a legitimate different shape (a compiler, a scoring provider, an SDK) and is out of scope for the runner kit; their conventions are covered by the standard below.

### Guidance layer

Agent files use three frontmatter dialects (lifehacker: folded `description`, no `model`; it-journey: one-line `description`, numbered `## How you work`; zer0-mistakes: `USE WHEN / DO NOT USE FOR` routing grammar, `model:` pins, a `kit:` stamp). Skills are uniform (`name` + `description`). Duplicated roles are forks-by-adaptation, not syncs: `content-reviewer` ×3, `agent-auditor`/`agent-reviewer` ×3, `issue-triager`+`issue-resolver` ×2, `theme-scout` ×2, while `quest-forge` ×2 and `content-curator` ×2 are different jobs sharing a name. The hub's position (kit VERSION 0.4.0) is right: agents, skills, hooks and commands stay repo-local; the two sanctioned shared artifacts are the guardrails doc and the agent-auditor.

### Workflows

Forty-plus AI lanes across the fleet. Conventions are consistent where lifehacker.dev set them (opt-in `<LANE>_ENABLED` variable evaluated in a `gate` job before checkout; `concurrency` with `cancel-in-progress: false` for writers; top-level `contents: read`) and absent where a repo grew its lanes alone: no kill switch on bash-365's three scheduled lanes, zer0-mistakes' `ui-audit`/`ci-self-repair`/`ai-content-review`, gitorio's three compiled factories, and ai-world-view's lineage lanes; no `concurrency` on irony-works' or zer0-image-generator's `claude.yml`; no repo pins actions by SHA; only 5 of 11 have Dependabot for `github-actions`. The safest auto-merge lane is it-journey's `content-auto-merge.yml` (live label re-read, per-policy allow-globs, self-excluding checks poll, freshness hand-off); the only bounded retry loop is lifehacker's `auto-fix.yml` (`MAX_ATTEMPTS: 3`).

### Content verification

Frontmatter: four rule sets, four enforcers (lifehacker Ruby, it-journey Python with a duplicate Ruby port, bash-365 Python, zer0-mistakes a data-driven `frontmatter_schema.yml` + Ruby). Brand voice: lifehacker's `_data/brand/*.yml` is a *sincerity policy* with an accept-ledger; it-journey's is a *lexicon* (casing map + discouraged words, section-scoped); bash-365 keeps rules in prose instructions with regex lints; zer0-mistakes scores rather than lints. Only the `voice.yml > profiles.<name>` block is near-isomorphic between lifehacker and it-journey. The findings contract (`{check_id, severity, file, line, rule, evidence, route_to, fingerprint}` in `findings.jsonl`) exists only in lifehacker.

### Preview images

`zer0-image-generator` is the canonical engine (Python oracle + byte-pinned Ruby port, five providers, Claude art-direction and vision review, gem + CLI + Rails panel). zer0-mistakes carries its pre-extraction ancestor (`scripts/lib/preview_generator.py`, 333 lines drifted); it-journey and year-of-ai carry copies two generations older; bash-365 and it-journey carry 1,100-line bash monoliths; `rasterize-svg.js` is byte-identical in three repos and dead in one. lifehacker's Trace Bloom does what the engine's `local` provider does not (headline typography, safe-band layout, article-derived art, a 10-rule gate, a constrained Claude illustration layer) and belongs upstream as a named deterministic style once a `banner_styles.yml` registry exists. All four sites read `preview:`; standardize on it.

## The conventions (write once, cite everywhere)

1. **Kill switch.** Every autonomous AI lane is gated by an opt-in repository variable `<LANE>_ENABLED == 'true'`, ANDed with credential presence, evaluated before checkout; a manual `workflow_dispatch` may bypass it. A `@claude` mention handler is never autonomous. Reference: `lifehacker.dev/.github/workflows/content-scout.yml`.
2. **Auth.** `CLAUDE_CODE_OAUTH_TOKEN` first; `ANTHROPIC_API_KEY` only when the OAuth token is empty (`${{ secrets.CLAUDE_CODE_OAUTH_TOKEN == '' && secrets.ANTHROPIC_API_KEY || '' }}` for claude-code-action; `env -u` in the runner). A call that was attempted and failed exits non-zero.
3. **Concurrency.** Every workflow declares a group; `cancel-in-progress: false` for anything that writes, `true` only for read-only PR checks.
4. **Permissions.** Top-level `contents: read`; write scopes per job; `timeout-minutes` set; no workflow ends in a bare push to a protected branch; `needs:` over `workflow_run`.
5. **Bot guard.** Route on `github.event.pull_request.user.login`, never `github.actor`; any `pull_request_target` lane that writes requires `head.repo.full_name == github.repository`.
6. **Labels.** `auto:content` (content-only, auto-mergeable), `auto:issue`, `source/<bot>`, and `needs-human` as the universal escape hatch every lane honours.
7. **Loop-breaker.** Bounded retries counted from a sentinel comment; escalation adds `needs-human` and removes `auto:content`.
8. **Inventory.** Every repo with an AI lane carries `fleet.manifest.yml` (`fleet/v1`); `wtd fleet audit` holds it to rules 1–3.
9. **Guardrails.** Every agent cites `.claude/skills/_shared/quarantine.md` (hub shape: quarantine, honesty, merge discipline) in one line instead of restating it.
10. **Kits are byte-identical.** A shared file carries a `kit:` stamp or is byte-compared against its template; a drifted copy is a repo passing a different gate from everyone else.

## The kits

### `ai-runner` (new — this round)

Source of truth: `lifehacker.dev/scripts/ai/` (see its README). Files: `run.sh`, `.github/actions/claude-run/action.yml` (mandatory, byte-identical); `usage.rb`, `usage_report.rb`, `api_call.rb`, `_data/ai_pricing.yml`, `scripts/ci/test_ai_runner.sh` (optional companions the runner probes for). Canonical env names `AI_MODEL`, `AI_FORCE_API`, `AI_MAX_TURNS`, `AI_USAGE_DIR` replace the `LH_AI_*` / `ITJ_AI_*` / `ZER0_AI_*` prefixes that were the single largest source of copy drift. `.prose-excludes` lets a repo exclude machine-authored paths from the post-run unwrap. Next step: promote it to `bamr87/bamr87 templates/ai-runner/` with a `VERSION` and `archive/`, so `fanout.sh --upgrade` keeps the three copies in lockstep.

### `content-lint` (proposed)

Adopt zer0-mistakes' data-driven `frontmatter_schema.yml` shape as the shared frontmatter contract (per-collection `required`/`optional`/`layout.allowed`, plus a `severity:` per rule so lifehacker keeps "description too long" a warning while bash-365 keeps it an error). Keep lifehacker's Ruby `lint_brand.rb` as the brand engine and widen its data schema with it-journey's `preferred:` casing map (the one rule with no false-positive risk) and optional section profiles; keep `accepted.yml` everywhere (bash-365 and it-journey currently pay for its absence with blanket `--warn-only`). Make `findings.jsonl` the shared report contract and turn zer0-mistakes' `content-review.rb` into the scoring tier on top of it rather than a fourth linter.

### `fleet-manifest` (this round)

`wtd fleet adopt` gains detection of the composite runner (`uses: ./.github/actions/claude-run`, `scripts/ai/run.sh`) — without it, it-journey derived 7 lanes instead of 15 and lifehacker 4 instead of 17. Every AI-running repo in the workspace gets a `fleet.manifest.yml` this round (`provenance: derived`; owners upgrade to `declared` after review).

### `preview-images` (proposed)

Delete the drifted copies (zer0-mistakes `scripts/lib/preview_generator.py` and its wrappers, it-journey's bash monolith and Python copy, bash-365's monolith, the three `_plugins/preview_image_generator.rb` forks, the duplicate `rasterize-svg.js`) in favour of the gem; port Trace Bloom into `lib/zer0_image_generator/svg/generators/` behind a new `banner_styles.yml`; fold lifehacker's xAI OAuth-first chain into the gem's providers; standardize on the `preview:` key and lint `header.og_image` + `preview:` on one article.

### `workflow-kit` (proposed)

Reusable workflows in one place (the hub or `bamr87/.github`): `claude-mention` (fold lifehacker's metering behind an input), `markdown-oneline` (the self-healing shape), `lint-workflows` (it-journey's changed-files scope), `codeql` (zer0-mistakes' path scoping), `auto-merge` (it-journey's `content-auto-merge.yml` with the policy table as inputs), `dependabot-auto-merge` (it-journey's `user.login` guard). Composite actions: `claude-run` (the kit), an `ai-gate` step (the eight-line gate copied into ~25 workflows), `resolve-gh-token`. Version reusable workflows by tag, not `@main`.

## The pull-request series

### Round 1 — this proposal's PRs (all branch `chore/harmonize-framework`, human merges)

| Repo | Change |
| --- | --- |
| lifehacker.dev | `ai-runner` kit source (generalized runner, canonical env, `--model`/`--max-turns`, optional companions, tests 7→10 cases); `claude-run` action inputs; `claude.yml` kit stamp; guardrails doc to hub 0.4.0 shape; `.claude/settings.json` hub baseline; `fleet-dispatch.yml` prompt pointed at the current preview scripts; `fleet.manifest.yml` regenerated (4 → 17 lanes); this document |
| it-journey | adopt the kit byte-identically (fixes the exit-0-on-dead-credential and dual-credential bugs, adds metering); `ITJ_AI_*` → `AI_*`; `.prose-excludes`; prose gate 0.3.0; `claude.yml` stamp; guardrails doc + one-line citations; settings baseline; `fleet.manifest.yml` (15 lanes); Fleet context |
| zer0-mistakes | adopt the kit (replaces the direct-CLI action; fixes exit-0 on install failure); settings baseline; `_data/consumers.yml` corrections (ai-world-view is floating; bash-365.com added); `fleet.manifest.yml`; Fleet context |
| bash-365.com | `*_ENABLED` switches on the three scheduled lanes (dispatch bypasses); OAuth-first auth expression; `checkout@v7`; `claude.yml` from the kit; guardrails doc; `fleet.manifest.yml` |
| ai-world-view.github.io | `content-review.rb` synced to canonical (its copy lacked the bare-URL fixpoint fix; the config files and README/CLAUDE.md had landed upstream since the survey); scheduled lanes armed behind `ORCHESTRATE_ENABLED` / `SECRET_EXPIRY_WATCH_ENABLED`; `fleet.manifest.yml`; settings baseline; README license text corrected (no LICENSE file exists) |
| irony-works | `concurrency` on germinate / alanis-gate; `fleet.manifest.yml` with the engine's `writable_paths` and metering; Fleet context |
| zer0-CMS, aieo | prose gate 0.3.0; `fleet.manifest.yml`; Standard deviations / Fleet context |
| zer0-image-generator | prose gate 0.3.0 (its `claude.yml` had reached kit 0.4.0 upstream since the survey); `fleet.manifest.yml` |

Not touched this round, on purpose: gitorio's `factory--*.yml` (generated files — the kill switch belongs in the compiler as `gate.enablement`), the year-of-ai and bashconsultants clones, and every content file.

### Round 2 — the hub

`templates/ai-runner/` (VERSION 0.1.0 + archive), `templates/prose/` 0.4.0 (the workflow reads `.prose-excludes`), a `fleet-manifest` artifact in the agent-context kit, the `community` kit the UPS gap list already names (SECURITY/CONTRIBUTING/CODEOWNERS/dependabot/labels), and `wtd`'s composite-harness detection upstream.

### Round 3 — consolidation

`content-lint` kit adoption in lifehacker → it-journey → bash-365; the preview-image deletions and the Trace Bloom port; zer0-mistakes retires `templates/agents/` (a second agent-context seeder) and lands the consumer kit in all five sites; gitorio adds `gate.enablement` to the deployed factories; `agent-reviewer` in lifehacker renamed `agent-auditor` to match the kit.

## Decisions for the owner

1. **Where the `ai-runner` kit lives long-term** — the hub's `templates/` (fits the fan-out discipline) or lifehacker.dev (where it is tested by a real fleet). Recommendation: hub `templates/`, with lifehacker as the reference implementation.
2. **Brand lint language** — Ruby (matches the harness and zer0-mistakes) means it-journey and bash-365 swap language; both currently print rather than gate, so the swap costs little. Recommendation: Ruby.
3. **SCHEMA.md adoption** — narrowly (it-journey, zer0-mistakes), not fleet-wide; the schema chain pays for itself only in sprawling trees.
4. **Kill switches default OFF on bash-365's live lanes** — the round-1 PR turns three running lanes off until three variables are set. That is the convention; the PR body lists the commands.
