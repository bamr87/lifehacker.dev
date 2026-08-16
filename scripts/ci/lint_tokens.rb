#!/usr/bin/env ruby
# =============================================================================
# lint_tokens.rb — catch the "presence is not validity" token trap in workflows
# -----------------------------------------------------------------------------
# `${{ secrets.SOME_TOKEN || github.token }}` looks like a graceful fallback and
# is not one. `||` in a GitHub Actions expression returns the first NON-FALSY
# operand, and an expired or revoked PAT is a perfectly non-empty string — so it
# wins the `||`, `github.token` is never reached, and the degrade-to-a-human
# path the comment above it usually promises is unreachable. An expired secret
# ends up strictly worse than no secret.
#
# That cost this repo 11 consecutive days of silent content-scout failures
# (2026-07-25 -> 08-04): each run bought ~10 minutes of agent browse, pushed a
# branch, then 401'd on `gh pr create`, leaving an orphan `scout/*` ref and no
# PR. One expiry took out four workflows at once. See bamr87/bamr87#53.
#
# The fix is a preflight that PROBES the token before trusting it:
# `.github/actions/resolve-gh-token` (see content-scout.yml for the worked
# example, and scripts/ci/test_resolve_gh_token.sh for its tests).
#
# --- Why this check is staged rather than a flat error -----------------------
# 12 workflows carried the trap when this check was written. Turning them all
# red at once would block every PR in the repo, including their own fixes. So:
#
#   * a workflow NOT in MIGRATING below            -> error   (blocks the gate)
#   * a workflow in MIGRATING                      -> warning (tracked debt)
#
# The point of that split is that the trap cannot be ADDED anywhere new, or
# reintroduced into a workflow already cleaned up, while the known backlog stays
# visible on every run instead of living in a PR description nobody re-reads.
#
# When you migrate a workflow, DELETE its line from MIGRATING in the same PR.
# The list is meant to shrink to empty, at which point this whole branch can go.
#
# Severity note for `token:` (actions/checkout) occurrences: same bad idiom, but
# it fails FAST and loudly (`could not read Username`) at step one rather than
# silently mid-run, and fixing it needs the probe to run BEFORE checkout — which
# a local composite action cannot do. Tracked, not conflated.
#
# Stdlib only. Run: ruby scripts/ci/lint_tokens.rb
# =============================================================================
require 'json'
require_relative '_lib'

WORKFLOWS = File.join(LH::ROOT, '.github', 'workflows')

# `${{ secrets.X || github.token }}`, tolerant of spacing and of a chain
# (quest-forge.yml uses `secrets.A || secrets.B || github.token`).
TRAP = /\$\{\{\s*secrets\.[A-Z0-9_]+(?:\s*\|\|\s*secrets\.[A-Z0-9_]+)*\s*\|\|\s*(?:github\.token|secrets\.GITHUB_TOKEN)\s*\}\}/

# Pre-existing occurrences as of bamr87/bamr87#53. Shrink this; never grow it.
# content-scout.yml is deliberately ABSENT — it is migrated, so a regression
# there is an error, not tracked debt.
MIGRATING = %w[
  agent-review.yml
  auto-fix.yml
  auto-update.yml
  brand-sweep.yml
  content-factory.yml
  fleet-dispatch.yml
  loop-tuner.yml
  pipeline.yml
  quest-forge.yml
  triage.yml
  weekly-epic.yml
  wire-scout.yml
].freeze

findings = []

Dir.glob(File.join(WORKFLOWS, '*.yml')).sort.each do |path|
  base = File.basename(path)
  rel  = ".github/workflows/#{base}"
  known = MIGRATING.include?(base)

  File.read(path, encoding: 'UTF-8').each_line.with_index(1) do |line, no|
    next if line =~ /\A\s*#/          # a comment ABOUT the trap is not the trap
    next unless line =~ TRAP

    gh_token = line =~ /\bGH_TOKEN\s*:/
    surface  = gh_token ? 'GH_TOKEN' : 'token:'
    rule     = gh_token ? 'gh-token-presence-fallback' : 'checkout-token-presence-fallback'

    evidence =
      if gh_token
        "#{surface} uses `secrets.X || github.token`, which cannot see an expired PAT — every `gh` call in this job 401s with no fallback, late and silently. Replace with ./.github/actions/resolve-gh-token (worked example: content-scout.yml)."
      else
        "#{surface} uses `secrets.X || github.token`. Fails fast (`could not read Username`) rather than silently, but it is the same trap; fixing it needs the probe to run before checkout."
      end
    evidence += ' [tracked pre-existing occurrence — remove from MIGRATING when fixed]' if known

    findings << LH.finding(
      check_id: 'tokens',
      severity: known ? 'warning' : 'error',
      rule: rule,
      file: rel,
      line: no,
      evidence: evidence,
      route_to: 'local'
    )
  end
end

# A stale ledger entry is its own bug: it silently downgrades a future
# regression in that file from error to warning.
MIGRATING.each do |base|
  path = File.join(WORKFLOWS, base)
  next unless File.exist?(path)
  next if File.read(path, encoding: 'UTF-8').each_line.any? { |l| l !~ /\A\s*#/ && l =~ TRAP }

  findings << LH.finding(
    check_id: 'tokens',
    severity: 'error',
    rule: 'stale-migration-entry',
    file: 'scripts/ci/lint_tokens.rb',
    evidence: "#{base} no longer carries the token trap — delete it from MIGRATING so a regression there is an error again.",
    route_to: 'local'
  )
end

exit LH.write('tokens', findings).zero? ? 0 : 1
