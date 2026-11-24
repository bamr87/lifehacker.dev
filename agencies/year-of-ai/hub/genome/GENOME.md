# GENOME — the DNA of the whole organizational model

This directory is the **genome**: the abstracted, concept-agnostic DNA of the entire `year-of-ai` model — its architecture, workflows, scripts, framework, policy, templates, and self-improvement design — packaged so the *whole machine* can be **replanted in a new GitHub org for a new concept** (countries, chemical elements, philosophers, …) by filling one small manifest, **without reinventing the wheel**. And it is kept honest by a routine-sync gate so it can't rot into a stale snapshot.

> The per-member `lineage/seeds/<id>.md` is the DNA of *one knowledge base*.
> **This genome is the DNA of the organization that grows them.**

## 1 · The concept delta — one manifest

Everything concept-specific is isolated into a single human-filled file, [`genome.yml`](genome.yml) (validated by [`schema.json`](schema.json)). To plant the model for a new concept you change ~9 required fields; everything else transplants unchanged. See [`genome.example.countries.yml`](genome.example.countries.yml) for a complete *"countries"* fill — the proof that the model carries DNA, not instance.

| Block | What it sets (examples: `year-of-ai` → `countries`) |
|---|---|
| `identity` | org, hub repo/domain, theme repo, bot email — `year-of-ai` → `world-atlas` |
| `branding` | site title/tagline, founder, preview-image style, chat assistant — `Year of AI` → `World Atlas` |
| `lexicon` | what one member is called + how an id becomes its subject — `the year {member}` → `the country {member}` |
| `taxonomy` | strategy (`temporal`/`enumerable`/`hierarchical`) + the 4–8 default categories |
| `lifecycle` | the first member, the slug rule, the succession rule, consolidation naming |
| `cadence` | growth cron + replant/consolidate thresholds |
| `growth` | `web_sources: false` → the org generates from the model's **own knowledge**, no web (plant strips `WebFetch`/`WebSearch` + flags the prompt) — e.g. `ai-world-view` (the AI's *own* world view) |
| `analytics`/`social`/`comments` | owner-specific ids — **default empty; never inherited** |

## 2 · What the genome contains — the 4-tier transplant map

Every concept-bearing asset of the model is classified in [`manifest.yml`](manifest.yml). Four tiers:

- **`transplant`** — concept-**agnostic**, copied byte-for-byte. The whole agent framework (`lineage/framework/**` skills/prompts/agents), the hub scripts (`lib/hub.rb`, `sync-*`, `content-review`, `docs-warden`, the fleet's `normalize-front-matter-dates` publish-gate/repair tool, `sync-member-metadata` registry→GitHub-metadata sync, and the banner set of ADR-0008 — `lib/banners.rb` (policy→engine flags, era palettes, telemetry stats), `audit-banners.rb`, `banner-quality.rb`, `reillustrate.rb` and the 10-line `generate-preview-images.sh` engine locator; the illustration loop itself lives in the zer0-image-generator gem, never in the genome), the `.claude` adapter set, the theme-data files, the chat-proxy worker, the legal pages, and the read-only CI gates — including `.github/workflows/build-validation.yml`, the pre-merge Jekyll build check, which is deliberately **not** in `default_plant_exclude`: it needs nothing a fresh plant lacks (a `_config.yml`, a `Gemfile`, some pages), so every new org gets a build gate from its first commit. *Must contain no concept literal* (the verify gate enforces this).
- **`template`** — carries concept literals, tokenized via the `tokens:` literal→`{{TOKEN}}` map at plant time: `_config.yml`, `_data/hub.yml`, `policy.yml`, the orchestration/grow/plant workflows (including `plant-lineage.yml`, the ADR-0007 auto-spawn), the provisioner + planter.
- **`override`** — a templated copy that overlays an otherwise-agnostic file (e.g. the repo-template `CLAUDE.md`, and the four framework files that carry the bot email or hub name).
- **`regenerate`** — concept *narrative* re-authored for the new concept by a genesis agent, not gsub'd (the hub's `pages/*.md`, the org profile README at `templates/org-profile/`, and per-member seeds — a blind find/replace would mangle SVG labels and prose).

Anything not in a tier is `ignore`d (instance content, generated data, build output, binaries — including this repo's own top-level docs: `README.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `CHANGELOG.md`).

A **default plant lands a clean, minimal growing org** — only the growth engine (`orchestrate` + `grow-lineage` + `hub-sync`) and the site. The mature self-improvement fleet (monitors, reviewers, `genome-sync`, …) is listed in `manifest.yml`'s `default_plant_exclude` and added with `plant.rb --with-fleet` once the org has the context those workflows need (a populated ledger, members, PRs). That includes the weekly `site-quality-scan.yml` (with its report-only `.github/site-quality.yml`, which always travels): it scans every member's live URL through the bamr87 hub's reusable `site-quality.yml@v2`, so it needs members. plant.rb also **authors a starter `pages/home.md`** from the manifest so every plant has a live homepage, and honors `growth.web_sources: false` for a no-web org.

## 3 · Plant runbook — standing up a new org

The two **irreducibly human** steps are one-time: **(a)** create the GitHub org (no API), and **(b)** mint + set the three secrets (`CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_API_KEY`, `LIFECYCLE_PAT` — sensitive credentials only a human can mint; `gh secret set` can upload but not create them). Everything else is automatable by the planter (`bin/plant.rb`, staged — see §5):

1. **(human)** Create the org `world-atlas`.
2. Fill `genome.yml` for the concept (human *intent*, ~9 fields — draftable by a genesis-org prompt).
3. Render: copy `transplant/` + `org-site/` verbatim, render `template/` + `override/` through the manifest, into a fresh hub-repo tree. *(render raises on any unresolved `{{TOKEN}}` — the completeness gate.)*
4. Create `world-atlas/world-atlas.github.io`, push, enable Pages (reuses `provision-org-sites.rb`).
5. **(human)** Set the three org secrets.
6. Write `lineage/seeds/<first_member>.md` from the manifest, refresh the ledger, and plant + grow the first member (reuses `plant-lineage.rb` + the grow tick).
7. Regenerate the hub narrative pages for the concept; the daily orchestrate cron takes over — the new org now grows, spawns, and self-improves on its own.

## 4 · Routine sync — the genome cannot rot

A bootstrap kit that drifts from reality is worse than none. The genome is kept truthful by [`bin/verify.rb`](bin/verify.rb), wired into CI (`.github/workflows/genome-sync.yml`) so a model change that isn't reflected in the genome turns the build **red**:

- **drift gate** — every tracked file is classified by `manifest.yml`; a file that is neither classified nor ignored *and carries a concept literal* fails: *"the model grew a limb the genome doesn't track."*
- **leak gate** — every `transplant:` file must be concept-agnostic; a literal hiding in a "verbatim" file fails.

```
$ ruby genome/bin/verify.rb
  ✓ genome in sync: every concept-bearing tracked file is classified, no leaks.
```

Future (staged): a `genome-sync` agent in the [self-improvement fleet](../lineage/decisions/ADR-0003-self-improving-agent-fleet.md) that doesn't just *detect* drift but *re-abstracts* the change into the genome and opens a PR.

## 5 · Status — what's built vs staged

**Built now:** the abstraction contract — `genome.yml` + `schema.json` + `genome.example.countries.yml` (the *countries* proof) + `manifest.yml` (the 4-tier inventory) + `bin/verify.rb` (the routine-sync gate, green against the live repo) + the `genome-sync` CI workflow + [`bin/render.rb`](bin/render.rb) (the token-substitution engine — derives the full `{{TOKEN}}` map from `genome.yml`, raises on any unresolved token; `--selftest` renders one template to both the `year-of-ai` and `countries` values, proving the abstraction).

[`bin/plant.rb`](bin/plant.rb) **(dry-run)** assembles a complete, rendered hub tree for any concept by reading the live repo per `manifest.yml` (transplant copied, template/override transformed via `render.rb`'s token map) into `./_planted/<org>/`, with a leak report. Verified for *countries*: `_config.yml`, `_data/hub.yml`, and the growth workflows all correctly become `world-atlas` / `World Atlas` / `bot@world-atlas.org` — **zero residual structural source literals**. Bare unit-noun substitution is deliberately avoided (it would corrupt Jekyll date config like `:year` / `year-month-day`); the unit-noun is handled via curated exact phrases (`manifest.yml`'s `phrase_tokens:` — now also covering `every {unit}`, `{unit}'s`, `{unit}-repo`, and the `<{unit}>` bracket-placeholder form found by the `ai-world-view` plant), the instance member list is pruned (members self-register), and Jekyll date placeholders are preserved. `cr_year` (`_config.yml`) and the `LICENSE` copyright line are handled by their own exact-scoped substitution pairs (a bare 4-digit `gsub` would corrupt unrelated numbers) — both are now classified in `manifest.yml` (`LICENSE` as `override`, `.gitignore`/`search.json` as `transplant`) so a plant carries them automatically instead of silently dropping them. `CHAT_ASSISTANT_NAME` is substitution-guarded against colliding with the `zer0-mistakes` theme's own brand name (a bare `"Zer0"` is a substring of `"Zer0-Mistakes"`; an unguarded gsub renamed the theme itself in `_data/authors.yml` and the chat-proxy wrangler template on the first real plant). The only remaining residue is a handful of **cosmetic** `year` mentions in workflow *comments* and doc placeholders (e.g. `lineage/seeds/<year>.md`) — no config value or behavior; the narrative pages are in the `regenerate` tier. Running plant from the canonical hub means **no duplicate payload is committed** — the live repo is the source, so the genome can't drift from a stale copy.

`plant.rb --apply --confirm <org>` is **built**: with the two-key confirm + a membership guard (refuses any account you can't create repos in), it authors member #1's seed from the manifest, `gh repo create`s the hub, pushes the assembled tree, and enables Pages. The **two irreducibly-human steps remain**: creating the GitHub org (no API exists) and minting + setting the three secrets. Once those are done, one `--apply` stands up the live, growing new-concept org.

**Staged (next):** the genesis branch that gives member #1 its seed §2–7 from a first grow tick.
