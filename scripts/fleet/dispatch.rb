#!/usr/bin/env ruby
# =============================================================================
# scripts/fleet/dispatch.rb — the deterministic OODA controller
# -----------------------------------------------------------------------------
# One cycle: OBSERVE (queue.json + backlog.yml + open-PR count) -> ORIENT (tally
# sev1/sev2) -> DECIDE (policy.rb budget split) -> ACT (lease items + spawn the
# role agents). The dispatcher itself opens ZERO PRs and edits ZERO content —
# it only decides and leases; the leased role agents (grow-lifehacker,
# fleet-bugfix, triage-lifehacker) each open exactly one PR a human merges.
#
# Two gates, both honored here:
#   * FLEET_ENABLED (repo variable) must be "true" — the kill switch. The bot
#     token has no admin scope, so it cannot flip this back on.
#   * MAX_OPEN_PRS — the dispatcher never leaves more PRs awaiting the human than
#     the cap, so adding agents drains the queue faster but never floods the gate.
#
# PLAN-ONLY by default (no mutations). --apply claims leases, updates state, and
# spawns agents. Run under concurrency:group=fleet-dispatch so only one is live.
#   ruby scripts/fleet/dispatch.rb [--apply]
# =============================================================================
require 'json'
require 'time'
require_relative '../ci/_lib'
require_relative 'policy'
require_relative 'plan'
require_relative 'lease'
require_relative 'authors'

APPLY = ARGV.include?('--apply')

# --- Kill switch (hard gate) -------------------------------------------------
unless ENV['FLEET_ENABLED'].to_s == 'true'
  puts '[dispatch] FLEET_ENABLED is not "true" — dispatcher idle. This is the kill switch; exiting 0.'
  exit 0
end

caps = LH.yload(LH.read(File.join(LH::ROOT, '_data', 'fleet', 'budget.yml'))) || {}
ttl  = (caps['lease_ttl_minutes'] || 60).to_i

# --- Daily token ceiling (cost kill switch) ----------------------------------
# The spawn step records spend into state.yml.tokens_today; if today's spend has
# already hit the cap, idle this cycle. (The gate is live even before real spawn
# wiring records spend — the knob is honest, not decorative.)
state_path = File.join(LH::ROOT, '_data', 'fleet', 'state.yml')
state      = (LH.yload(LH.read(state_path)) rescue {}) || {}
max_tokens = caps.dig('caps', 'max_daily_tokens').to_i
today      = Time.now.utc.strftime('%Y-%m-%d')
spent_today = state['tokens_date'] == today ? state['tokens_today'].to_i : 0
if max_tokens.positive? && spent_today >= max_tokens
  puts "[dispatch] daily token budget reached (#{spent_today}/#{max_tokens}) — idle until tomorrow."
  exit 0
end

# --- Queue freshness (fail-safe) ---------------------------------------------
# A missing or stale queue must NOT read as "grow". The pipeline regenerates the
# queue immediately before dispatch; a stale committed copy stops the fleet.
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

def gh_open_pr_count
  out = `gh pr list --state open --json number 2>/dev/null`
  $?.success? ? (JSON.parse(out).size rescue 0) : 0
end

# In --apply this is where a role agent is launched in its own git worktree.
# It is printed (not exec'd) here so the dispatch decision is auditable and the
# heavy, auth-bearing spawn is wired explicitly in fleet-dispatch.yml. The printed
# command goes through the universal runner (scripts/ai/run.sh), NOT a raw
# `claude -p`, so model / auth (CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY) /
# fallback stay configured in one place.
def spawn_cmd(skill, target, desc, author = nil)
  prompt = "/#{skill} #{target}"
  # The rotating persona travels IN the prompt so the leased grow agent writes
  # AS that author (byline + voice) even though it only receives the item id.
  prompt += " (write as author: #{author})" if author && !author.empty?
  "bash scripts/ai/run.sh --prompt #{prompt.inspect}  # #{desc[0, 60]}"
end

# --- Observe + Decide (pure) -------------------------------------------------
queue   = jload(File.join(LH::ROOT, '_data', 'health', 'queue.json'))
backlog = ((LH.yload(LH.read(File.join(LH::ROOT, '_data', 'backlog.yml'))) || {})['backlog'] rescue []) || []

# Rotation authority (fleet/authors.rb): quota-based per-section AI-author pick.
# Injected so plan.rb stays pure; only grow items that don't pin an author use it.
author_for = ->(kind) { Fleet::Authors.next_author(kind) }

result     = Fleet::Plan.compute(queue: queue, backlog: backlog, open_prs: gh_open_pr_count, caps: caps, fresh: fresh, author_for: author_for)
obs        = result[:obs]
plan       = result[:decision]
planned    = result[:dispatched]

# --- Act: lease (only on --apply), keeping the won claims --------------------
dispatched = planned.select do |d|
  next true unless APPLY
  role_id = d[:role] == 'grow-lifehacker' ? 'grower' : 'bugfix'
  Fleet::Lease.claim(d[:target], role_id, ttl)
end

# --- Persist state (only when acting) ----------------------------------------
if APPLY
  sf = File.join(LH::ROOT, '_data', 'fleet', 'state.yml')
  st = (LH.yload(LH.read(sf)) rescue {}) || {}
  st['cycles']        = (st['cycles'] || 0) + 1
  st['last_run']      = Time.now.utc.iso8601
  st['last_decision'] = plan[:reason]
  LH.ywrite(sf, st)   # preserve state.yml's comment header (don't round-trip it away)
end

# --- Report ------------------------------------------------------------------
puts "[dispatch] observe: #{obs}"
puts "[dispatch] decide:  #{plan[:mode]}  grow=#{plan[:slots][:grow]} fix=#{plan[:slots][:fix]}"
puts "[dispatch]          #{plan[:reason]}"
puts "[dispatch] act:     mode=#{APPLY ? 'APPLY (leased + spawning)' : 'plan-only'} — #{dispatched.size} agent(s)"
dispatched.each do |d|
  byline = d[:author] ? "  (as #{d[:author]})" : ''
  puts "  #{d[:role]}  <- #{d[:target]}#{byline}"
  puts "      #{spawn_cmd(d[:role], d[:target], d[:desc], d[:author])}"
end
puts '  (nothing to dispatch — queue clean or capped)' if dispatched.empty?

# --- Machine-readable plan for the workflow's spawn matrix --------------------
# The fleet-dispatch workflow reads this `plan` output and runs ONE claude-run
# agent per item (role -> target). Always emitted (even []) so the spawn matrix
# is well-defined; the spawn job itself only runs on --apply. (When the kill
# switch is off the dispatcher exits early above, so no plan is emitted and the
# spawn job is skipped — FLEET_ENABLED transitively gates spawning.)
if (gho = ENV['GITHUB_OUTPUT'])
  plan_items = dispatched.map do |d|
    h = { 'role' => d[:role].to_s, 'target' => d[:target].to_s }
    h['author'] = d[:author].to_s if d[:author] && !d[:author].to_s.empty?
    h
  end
  File.open(gho, 'a') { |io| io.puts "plan=#{JSON.generate(plan_items)}" }
end
