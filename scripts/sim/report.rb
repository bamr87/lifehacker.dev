#!/usr/bin/env ruby
# =============================================================================
# scripts/sim/report.rb — the pipeline's monitoring/reporting surface
# -----------------------------------------------------------------------------
# Renders a single markdown report from whatever the run produced — the harness
# gate, the triage queue, and the fleet's plan for the current state. The
# pipeline pipes this into $GITHUB_STEP_SUMMARY so every Actions run shows a live
# health dashboard; locally it just prints. Read-only; degrades gracefully when a
# stage's output is missing.
#   ruby scripts/sim/report.rb [open_prs]
# =============================================================================
require_relative '../triage/_lib'
require_relative '../fleet/plan'

def jload(p)
  File.exist?(p) ? (JSON.parse(LH.read(p)) rescue nil) : nil
end

def yload(p)
  File.exist?(p) ? (LH.yload(LH.read(p)) rescue nil) : nil
end

harness = jload(File.join(LH::ROOT, 'test-results', 'summary.json'))
queue   = jload(File.join(LH::ROOT, '_data', 'health', 'queue.json')) || []
backlog = ((yload(File.join(LH::ROOT, '_data', 'backlog.yml')) || {})['backlog']) || []
caps    = yload(File.join(LH::ROOT, '_data', 'fleet', 'budget.yml')) || {}
open_prs = (ARGV[0] || 0).to_i

out = +"## lifehacker.dev pipeline report\n\n"

# --- Test harness ------------------------------------------------------------
out << "### 1 · Test harness\n\n"
if harness
  gate = harness['gate'] == 'pass' ? '✅ PASS' : '❌ FAIL'
  out << "**Gate: #{gate}** — #{harness['error_count']} error, #{harness['warning_count']} warning, "\
         "#{harness['info_count']} info across #{(harness['by_check'] || {}).size} checks.\n\n"
  unless (harness['by_check'] || {}).empty?
    out << "| check | findings |\n|---|---|\n"
    harness['by_check'].sort.each { |k, v| out << "| #{k} | #{v} |\n" }
    out << "\n"
  end
else
  out << "_No harness summary (build may have failed before aggregate)._\n\n"
end

# --- Triage queue ------------------------------------------------------------
out << "### 2 · Triage queue\n\n"
if queue.empty?
  out << "_Queue empty — nothing to fix._\n\n"
else
  bySev = queue.each_with_object(Hash.new(0)) { |i, h| h[i['severity']] += 1 }
  out << "**#{queue.size}** item(s): #{bySev.sort.map { |k, v| "#{k}×#{v}" }.join(' · ')}\n\n"
  out << "| score | sev | type | where | route |\n|---|---|---|---|---|\n"
  queue.first(8).each do |i|
    where = (i['url_path'] && !i['url_path'].empty?) ? i['url_path'] : i['file']
    out << "| #{i['score']} | #{i['severity']} | #{i['type']} | `#{where}` | #{i['route']} |\n"
  end
  out << "\n"
end

# --- Fleet plan for the current state ----------------------------------------
out << "### 3 · Fleet dispatch plan\n\n"
plan = Fleet::Plan.compute(queue: queue, backlog: backlog, open_prs: open_prs, caps: caps)
d = plan[:decision]
out << "Observed: #{plan[:obs]}\n\n"
out << "**Decision: #{d[:mode]}** — grow #{d[:slots][:grow]}, fix #{d[:slots][:fix]}. #{d[:reason]}\n\n"
if plan[:dispatched].empty?
  out << "_Would dispatch nothing this cycle._\n"
else
  out << "Would dispatch:\n"
  plan[:dispatched].each { |x| out << "- `#{x[:role]}` ← #{x[:target]} — #{x[:desc][0, 60]}\n" }
end

puts out
