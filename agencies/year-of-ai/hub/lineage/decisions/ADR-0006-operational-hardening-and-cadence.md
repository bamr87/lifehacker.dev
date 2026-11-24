# ADR-0006 — Operational hardening & growth cadence

- **Status**: Accepted (decision 5, theme pinning, SUPERSEDED 2026-08-18)
- **Date**: 2026-07-06
- **Context**: Full review of the hub and the 11-member fleet (three parallel audits: purpose surfaces, hub machinery, org-wide health), triggered by the first real fleet outages.

## What the review found

1. **A member site was down for six days behind green dashboards.** The 2026-06-30 grow tick wrote `date: "1777–1778"` (an en-dash range) into a 1777 front matter; Jekyll's datetime parse fails the *whole* site build. The site served 06-29 content until 07-06. Nothing escalated: grow runs conclude `success` on no-op ticks, and the Pages Deploy Sentinel's cross-repo build check was silently inert (the hub-scoped `github.token` cannot read other repos' Pages builds; the error was masked to a healthy-looking `no-pages`) — so its HTTP-200 check passed against the stale-but-live site.
2. **Platform-side deploy flakes don't recover on their own.** 2008 and 2012 had `actions/deploy-pages` failures ("Deployment failed, try again later") that latched for days; several other members had one-off flakes that happened to self-recover.
3. **Security gaps in the tick.** `actions/checkout` persisted the org-wide `LIFECYCLE_PAT` into `.git/config` while three model passes ran with `Bash + WebFetch/WebSearch` over researched web content (a prompt-injection exfiltration path); `${{ inputs.repo }}` was interpolated raw into `run:` blocks.
4. **Broken fallback gate.** The API-key fallback's "tick produced nothing" check counted the always-present staged files, so `empty` was always false — a silent all-tier no-op never fell back.
5. **Kill-switch gaps.** `grow-lineage.yml` (the actual writer) never read `_data/fleet_pause.yml`; nor did `hub-sync.yml`'s commit.
6. **Cost had no governor.** Every member grew every day (11 × 3-tier passes; telemetry records ~$3.4–4.8 for the *final pass alone* per tick), and `policy.yml`'s `cadence:` block was consumed by nothing.
7. **Theme = single external point of failure.** All 12 sites built against `bamr87/zer0-mistakes` at floating HEAD, a theme that ships several releases a week.
8. **Contradictory dead weight staged into every tick**: the old peer-to-peer `framework/workflows/{grow,learn,telemetry}.yml`, `scripts/lineage.sh`, and the consolidate/replant/genesis prompts + check-lifecycle skill (all forbidden by `policy.yml`'s perpetual-growth doctrine).

## Decisions

1. **Publish gate for front matter** — `scripts/normalize-front-matter-dates.rb` deterministically normalizes `date:` values (range → start date, bare year → `YYYY-01-01`, prose → ISO) and the grow tick refuses to publish anything still unparseable. The same script is the one-shot repair tool for existing member content.
2. **Sentinel measures builds, not just liveness** — it now uses `LIFECYCLE_PAT` for the cross-repo Pages-builds API, treats `errored`, `stuck-building` (>90 min) and `unreadable` as unhealthy, and auto-closes its sticky issue on recovery (matching its sibling watchers).
3. **Tick hardening** — a `gate` job (kill-switch + input validation) fronts `grow-lineage.yml` so even `if: always()` steps cannot run when paused; `persist-credentials: false` keeps the PAT out of the model passes' reach; the fallback gate counts only real content changes and checks `is_error` on every tier, not just the last.
4. **Policy-driven cadence** — `cadence.repos_per_run` (default **4**) with stalest-first selection in `orchestrate.yml`. Every member still grows perpetually; each now ticks roughly every 3 days instead of daily, cutting model spend ~2/3. Set `repos_per_run: 0` to restore grow-everything-daily.
5. **Theme pinning** — ~~`remote_theme` is pinned to a tagged release in the hub's `_config.yml` and in `_data/hub.yml` (`pages.theme_repo`, which the provisioner templates into member configs). Theme bumps become deliberate: update both, then re-roll members with `provision-org-sites.rb`.~~ **SUPERSEDED 2026-08-18 — decision 5 only.** The fleet no longer pins the theme: `remote_theme` is untagged everywhere and every site tracks the theme's latest `main`. In practice the pin did not make bumps deliberate, it made them not happen — the hub sat two minors behind for weeks, and the floating dev config was the only thing in the org that ever built against a current theme. Theme bugs now go upstream instead of being pinned around; the safety net is the `build-validation` PR gate plus `pages-deploy-sentinel` after deploy. The rest of this ADR stands.
6. **Staging trim** — the dead peer-to-peer surfaces are no longer staged into ticks (excluded in the staging step). The files stay in `lineage/framework/` as reference until a future cleanup removes them.
7. **Hub-main push discipline** — every hub-`main` pusher (seed persist, telemetry ledger, orchestrate's ledger commit, hub-sync) retries with rebase; hub-sync also honors the kill-switch.

## Consequences

- Slower per-member growth by design (a policy knob, not a code change, to revert).
- ~~Theme fixes no longer arrive automatically — bumping the pin is a deliberate, reviewable act.~~ **Superseded 2026-08-18** (see decision 5): theme fixes arrive automatically again, and an upstream regression does too.
- The old lifecycle surfaces remain on disk but out of ticks; removing them entirely (and pruning the matching member `.claude` adapter commands) is follow-up work.
- Known residual risks, accepted for now: the seed §8 clock is persisted before the content publish (a failed publish can advance the clock); seeds grow unboundedly and are staged whole into every pass (trimming staged §8 history needs a merge-aware persist step first).
