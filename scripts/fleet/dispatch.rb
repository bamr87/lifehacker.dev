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
require_relative 'lease'

APPLY = ARGV.include?('--apply')

# --- Kill switch (hard gate) -------------------------------------------------
unless ENV['FLEET_ENABLED'].to_s == 'true'
  puts '[dispatch] FLEET_ENABLED is not "true" — dispatcher idle. This is the kill switch; exiting 0.'
  exit 0
end

caps = LH.yload(LH.read(File.join(LH::ROOT, '_data', 'fleet', 'budget.yml'))) || {}
ttl  = (caps['lease_ttl_minutes'] || 60).to_i

def jload(path)
  File.exist?(path) ? (JSON.parse(LH.read(path)) rescue []) : []
end

def gh_open_pr_count
  out = `gh pr list --state open --json number 2>/dev/null`
  $?.success? ? (JSON.parse(out).size rescue 0) : 0
end

# In --apply this is where a role agent is launched in its own git worktree:
#   claude -p "/<skill> <target>" --allowedTools ... --permission-mode acceptEdits
# It is printed (not exec'd) here so the dispatch decision is auditable and the
# heavy, API-key-bearing spawn is wired explicitly in fleet-dispatch.yml.
def spawn_cmd(skill, target, desc)
  "claude -p #{("/" + skill + " " + target).inspect}  # #{desc[0, 60]}"
end

# --- Observe -----------------------------------------------------------------
queue   = jload(File.join(LH::ROOT, '_data', 'health', 'queue.json'))
backlog = ((LH.yload(LH.read(File.join(LH::ROOT, '_data', 'backlog.yml'))) || {})['backlog'] rescue []) || []

sev1     = queue.count { |i| i['severity'] == 'sev1' }
sev2     = queue.count { |i| i['severity'] == 'sev2' }
fixable  = queue.select { |i| i['route'] == 'local' && %w[sev1 sev2 sev3].include?(i['severity']) }
                .sort_by { |i| -i['score'].to_f }
growable = backlog.select { |b| b['status'].to_s == 'todo' }

obs = { sev1: sev1, sev2: sev2, open_prs: gh_open_pr_count,
        growth_available: growable.size, fix_available: fixable.size }

# --- Decide ------------------------------------------------------------------
plan = Fleet::Policy.decide(obs, caps)

# --- Act ---------------------------------------------------------------------
# Fixers first (priority), then growers fill remaining slots. Lease only on --apply.
dispatched = []
fixable.first(plan[:slots][:fix]).each do |item|
  if APPLY
    next unless Fleet::Lease.claim(item['fingerprint'], 'bugfix', ttl)
  end
  dispatched << { role: 'fleet-bugfix', target: item['fingerprint'], desc: item['title'].to_s }
end
growable.first(plan[:slots][:grow]).each do |b|
  if APPLY
    next unless Fleet::Lease.claim(b['id'], 'grower', ttl)
  end
  dispatched << { role: 'grow-lifehacker', target: b['id'].to_s, desc: b['title'].to_s }
end

# --- Persist state (only when acting) ----------------------------------------
if APPLY
  sf = File.join(LH::ROOT, '_data', 'fleet', 'state.yml')
  st = (LH.yload(LH.read(sf)) rescue {}) || {}
  st['cycles']        = (st['cycles'] || 0) + 1
  st['last_run']      = Time.now.utc.iso8601
  st['last_decision'] = plan[:reason]
  File.write(sf, st.to_yaml)
end

# --- Report ------------------------------------------------------------------
puts "[dispatch] observe: #{obs}"
puts "[dispatch] decide:  #{plan[:mode]}  grow=#{plan[:slots][:grow]} fix=#{plan[:slots][:fix]}"
puts "[dispatch]          #{plan[:reason]}"
puts "[dispatch] act:     mode=#{APPLY ? 'APPLY (leased + spawning)' : 'plan-only'} — #{dispatched.size} agent(s)"
dispatched.each do |d|
  puts "  #{d[:role]}  <- #{d[:target]}"
  puts "      #{spawn_cmd(d[:role], d[:target], d[:desc])}"
end
puts '  (nothing to dispatch — queue clean or capped)' if dispatched.empty?
