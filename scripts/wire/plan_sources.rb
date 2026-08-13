#!/usr/bin/env ruby
# =============================================================================
# plan_sources.rb — decide WHICH configured news sources the wire-scout reads today
# -----------------------------------------------------------------------------
# Unlike the sister-site scout (which seed-shuffles a sitemap), the wire desk
# has an assignment editor: _data/wire/sources.yml declares every source with
# its own frequency, trust tier, filters, and per-run caps. This planner is
# PURE — no network: due-ness is a function of (frequency, UTC date), so a
# given day's plan is deterministic and a flaky run replays identically with
# --date.
#
#   ruby scripts/wire/plan_sources.rb [--date YYYY-MM-DD]
#
# Output: _data/wire/plan.json — the due sources (config folded with defaults)
# plus the desk-wide filters and caps the agent + build step must respect. The
# agent WebFetches each source's listing URL itself, under the quarantine rules
# (.claude/skills/_shared/quarantine.md).
#
# Stdlib only (json, date). No endless-method defs.
# =============================================================================
require 'json'
require 'date'
require_relative '_lib'

date_arg = (ARGV[ARGV.index('--date') + 1] if ARGV.include?('--date'))
DATE = date_arg ? Date.parse(date_arg) : Date.today

cfg = Wire.config
abort "[wire-plan] #{LH.rel(Wire::SOURCES)} is missing or unparseable — nothing to plan" if cfg.empty?

due     = Wire.due_sources(DATE, cfg)
caps    = cfg['caps'].is_a?(Hash) ? cfg['caps'] : {}
filters = cfg['filters'].is_a?(Hash) ? cfg['filters'] : {}

out = {
  'generated_at'          => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
  'date'                  => DATE.to_s,
  'weekday'               => Wire::WEEKDAYS[(DATE.wday - 1) % 7],
  'recency_days'          => (caps['recency_days'].to_i.positive? ? caps['recency_days'].to_i : 14),
  'max_proposals_per_run' => (caps['max_proposals_per_run'].to_i.positive? ? caps['max_proposals_per_run'].to_i : 3),
  'wander_slots'          => (caps.key?('wander_slots') ? caps['wander_slots'].to_i : 1),
  'filters'               => { 'beat' => Array(filters['beat']), 'exclude' => Array(filters['exclude']) },
  'sources'               => due
}

Dir.mkdir(Wire::DATA) unless Dir.exist?(Wire::DATA)
File.write(Wire::PLAN, JSON.pretty_generate(out))
puts "[wire-plan] date=#{DATE} (#{out['weekday']}) due=#{due.size} of #{(cfg['sources'] || []).size} configured"
due.each do |s|
  freq = s['frequency'].is_a?(Array) ? s['frequency'].join(',') : s['frequency']
  puts "  #{s['id']} (#{s['trust']}, #{freq}): #{s['url']} (max #{s['max_items']})"
end
