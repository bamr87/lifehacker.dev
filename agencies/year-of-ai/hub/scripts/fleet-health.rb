#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# fleet-health.rb — the fleet health digest engine (ADR-0003 fleet-health-watch).
# =============================================================================
# Reads the evolution ledger (telemetry/evolution.jsonl, filled by the
# telemetry-ledger collector) + the lineage roster, and computes a daily health
# digest: error rate, cost trend, per-repo last-grow, and STALLS (a member that
# hasn't grown recently). Read-only; the workflow decides whether to file an issue.
# This closes the OBSERVE→DETECT loop over the keystone's data. Ruby stdlib only.
#
#   ruby scripts/fleet-health.rb --summary /tmp/health.md --json /tmp/health.json
# Writes the Markdown digest + a JSON {flags: N, …}; flags>0 ⇒ something to report.

require 'json'
require 'yaml'
require 'time'

ROOT   = File.expand_path('..', __dir__)
LEDGER = File.join(ROOT, 'telemetry', 'evolution.jsonl')
LIN    = File.join(ROOT, '_data', 'lineage.yml')

opts = {}
ARGV.each_with_index { |a, i| opts[:summary] = ARGV[i + 1] if a == '--summary'; opts[:json] = ARGV[i + 1] if a == '--json' }

now = Time.now.utc
recs = []
if File.exist?(LEDGER)
  File.foreach(LEDGER) do |line|
    line = line.strip
    next if line.empty?

    begin
      recs << JSON.parse(line)
    rescue StandardError
      next
    end
  end
end

def started_at(r)
  Time.parse(r['started'].to_s)
rescue StandardError
  nil
end

within = ->(r, days) { (t = started_at(r)) && (now - t) <= days * 86_400 }
recent7  = recs.select { |r| within.call(r, 7) }
recent1  = recs.select { |r| within.call(r, 1) }
errors7  = recent7.select { |r| r['is_error'] == true || (r['conclusion'] && r['conclusion'] != 'success') }
cost7    = recent7.sum { |r| (r['cost_usd'] || 0).to_f }
tok7     = recent7.sum { |r| (r['output_tokens'] || 0).to_i }
avg_cost = recent7.empty? ? 0 : cost7 / recent7.size

# per-repo last grow
last_by = {}
recs.each do |r|
  t = started_at(r)
  next unless t && r['repo'] && !r['repo'].to_s.empty?

  last_by[r['repo']] = t if last_by[r['repo']].nil? || t > last_by[r['repo']]
end

members = ((YAML.load_file(LIN)['members'] rescue []) || []).map { |m| m['name'] }.compact
# A stall = a member that HAS grown (has a ledger record) but not in >2 days. A
# member with no record yet is "not-yet-observed" (the ledger is young) — reported
# but NOT flagged, so a freshly-deployed collector doesn't false-alarm on history.
stalls = members.select { |m| (t = last_by[m]) && (now - t) > 2 * 86_400 }
unseen = members.reject { |m| last_by.key?(m) }

flags = errors7.size + stalls.size

# ---- digest -----------------------------------------------------------------
md = +"## 🩺 Fleet Health — #{now.strftime('%Y-%m-%d %H:%M UTC')}\n\n"
if recs.empty?
  md << "_No evolution-ledger records yet (telemetry/evolution.jsonl) — the collector populates it on each grow tick._\n"
else
  md << "**Last 7d:** #{recent7.size} grow run(s) · #{errors7.size} error(s) · " \
        "$#{format('%.2f', cost7)} (avg $#{format('%.3f', avg_cost)}/run) · #{tok7} output tokens. " \
        "**24h:** #{recent1.size} run(s). **Ledger:** #{recs.size} total.\n\n"
  md << "⚠️ **Stalled (grew before, none in >2 days):** #{stalls.sort.join(', ')}\n\n" unless stalls.empty?
  md << "ℹ️ _Not yet in the ledger (young collector): #{unseen.sort.join(', ')}._\n\n" unless unseen.empty?
  unless errors7.empty?
    md << "❌ **Errors (last 7d):**\n\n| Run | Repo | Conclusion | is_error |\n|---|---|---|---|\n"
    errors7.first(15).each { |r| md << "| #{r['run_id']} | #{r['repo']} | #{r['conclusion']} | #{r['is_error']} |\n" }
    md << "\n"
  end
  md << "**Per-member last grow:**\n\n| Member | Last grow | Days ago |\n|---|---|---|\n"
  members.sort.each do |m|
    t = last_by[m]
    md << "| #{m} | #{t ? t.strftime('%Y-%m-%d') : '—'} | #{t ? ((now - t) / 86_400).round(1) : 'never'} |\n"
  end
  md << "\n_Read-only digest; this watcher reports, it does not re-dispatch or remediate._\n"
end

puts md
File.write(opts[:summary], md) if opts[:summary]
File.write(opts[:json], JSON.generate(flags: flags, errors_7d: errors7.size, stalls: stalls, unseen: unseen.size, runs_7d: recent7.size, cost_7d: cost7.round(4))) if opts[:json]
