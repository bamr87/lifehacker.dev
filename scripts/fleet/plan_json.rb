#!/usr/bin/env ruby
# =============================================================================
# scripts/fleet/plan_json.rb — read-only JSON view of the dispatch decision
# -----------------------------------------------------------------------------
# The dispatcher (dispatch.rb) is the ACTOR: it gates on FLEET_ENABLED, counts
# open PRs via `gh`, leases items, and spawns agents. That makes it unusable as
# a pure *read* — with the kill switch off (the default) it exits before it even
# computes a plan. But the decision itself lives in a pure function,
# Fleet::Plan.compute, already exercised by scripts/sim/simulate.rb.
#
# This is a thin, side-effect-free wrapper the MCP (and any dashboard) can shell
# to answer "what WOULD the dispatcher do right now?" It reproduces dispatch.rb's
# OBSERVE step (queue.json + backlog.yml freshness), calls the same compute, and
# prints the decision as JSON. It NEVER reads FLEET_ENABLED, never touches leases
# or state, and never requires `gh` — the open-PR count is passed in explicitly.
#
#   ruby scripts/fleet/plan_json.rb --open-prs 2      # decide as if 2 PRs are open
#   ruby scripts/fleet/plan_json.rb --open-prs unknown # fail safe: assume the cap
#
# `unknown` (or an omitted count) fails safe to the open-PR cap, so the plan is
# backpressure (dispatch nothing) rather than blindly assuming zero open PRs —
# absence of data must never read as "safe to act", mirroring the queue-freshness
# fail-safe below.
# =============================================================================
require 'json'
require 'time'
require_relative '../ci/_lib'
require_relative 'policy'
require_relative 'plan'
require_relative 'authors'

# --- Parse the explicit open-PR count (no `gh`) ------------------------------
caps    = LH.yload(LH.read(File.join(LH::ROOT, '_data', 'fleet', 'budget.yml'))) || {}
max_prs = caps.dig('caps', 'max_open_prs').to_i

raw_prs = nil
if (i = ARGV.index('--open-prs'))
  raw_prs = ARGV[i + 1]
end
open_prs =
  if raw_prs.nil? || raw_prs.strip.downcase == 'unknown'
    max_prs          # fail safe: an unknown count reads as "at the cap" (backpressure)
  else
    raw_prs.to_i
  end

# --- Observe: queue + backlog + freshness (identical to dispatch.rb) ---------
summary_path = File.join(LH::ROOT, '_data', 'health', 'summary.yml')
max_age      = (caps['queue_max_age_minutes'] || 1440).to_i
fresh = false
if File.exist?(summary_path)
  s   = (LH.yload(LH.read(summary_path)) rescue {}) || {}
  gen = (Time.parse(s['generated_at'].to_s) rescue nil)
  fresh = !gen.nil? && (Time.now.utc - gen) <= max_age * 60
end

def jload(path)
  File.exist?(path) ? (JSON.parse(LH.read(path)) rescue []) : []
end

queue   = jload(File.join(LH::ROOT, '_data', 'health', 'queue.json'))
backlog = ((LH.yload(LH.read(File.join(LH::ROOT, '_data', 'backlog.yml'))) || {})['backlog'] rescue []) || []

# Annotate grow items with their byline exactly as dispatch.rb does, so the JSON
# reflects the real dispatcher (a pure disk read — no state is mutated).
author_for = ->(kind) { Fleet::Authors.next_author(kind) }

result = Fleet::Plan.compute(queue: queue, backlog: backlog, open_prs: open_prs,
                             caps: caps, fresh: fresh, author_for: author_for)

# Stable, machine-readable shape. Symbol keys from compute round-trip to strings
# through JSON.generate; `open_prs_source` records whether the count was given.
out = {
  'observe'  => result[:obs],
  'decision' => result[:decision],
  'dispatched' => result[:dispatched],
  'fresh'    => fresh,
  'open_prs' => open_prs,
  'open_prs_source' => (raw_prs.nil? || raw_prs.strip.downcase == 'unknown') ? 'unknown-assumed-cap' : 'explicit'
}
puts JSON.pretty_generate(out)
