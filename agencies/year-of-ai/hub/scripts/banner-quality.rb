#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# banner-quality.rb — the weekly banner watcher (ADR-0008 D6, Phase 3).
# =============================================================================
# Reads the hub's banner ledger (telemetry/banners.jsonl — banner/v1 records the
# grow tick's Illustrate step and the backfill write, appended by
# telemetry-ledger.yml) over the trailing `preview.watch.window_days`, and
# compares it with the floors in lineage/policy.yml `preview.watch`:
#
#   mean critic `overall`            >= min_mean_overall
#   committed-clean % (strict lint,  >= min_committed_clean_pct
#   a `local` fallback counts clean)
#
# Writes a Markdown digest and a JSON verdict {flag, reasons, totals, repos,
# banners[]}. Read-only; site-quality-scan.yml's `banners` job renders the
# listed banners into a contact sheet and keeps one "Banner quality" issue.
#
#   ruby scripts/banner-quality.rb --summary /tmp/banners.md --json /tmp/banners.json
# Ruby stdlib only.

require 'json'
require 'yaml'
require 'optparse'
require 'time'
require_relative 'lib/banners'

ROOT = File.expand_path('..', __dir__)
opts = { ledger: File.join(ROOT, 'telemetry', 'banners.jsonl'), now: Time.now.utc }
OptionParser.new do |o|
  o.banner = 'usage: ruby scripts/banner-quality.rb [--summary FILE] [--json FILE]'
  o.on('--summary FILE', 'Markdown digest') { |v| opts[:summary] = v }
  o.on('--json FILE', 'JSON verdict') { |v| opts[:json] = v }
  o.on('--ledger FILE', 'banner ledger (default telemetry/banners.jsonl)') { |v| opts[:ledger] = v }
  o.on('--now ISO8601', 'evaluate as of this time (tests)') { |v| opts[:now] = Time.parse(v).utc }
end.parse!

policy = (YAML.load_file(File.join(ROOT, 'lineage', 'policy.yml')) rescue {}) || {}
watch = (policy['preview'] || {})['watch'] || {}
days = (watch['window_days'] || 7).to_i
min_overall = (watch['min_mean_overall'] || 6.5).to_f
min_clean = (watch['min_committed_clean_pct'] || 95).to_f

window = Banners.recent(Banners.load_records(opts[:ledger]), days: days, now: opts[:now])
totals = Banners.stats(window)
repos = window.group_by { |r| r['repo'].to_s }.map { |repo, rows| [repo, Banners.stats(rows)] }.to_h

reasons = []
if totals['mean_overall'] && totals['mean_overall'] < min_overall
  reasons << "mean critic overall #{totals['mean_overall']} < #{min_overall}"
end
if totals['committed_clean_pct'] && totals['committed_clean_pct'] < min_clean
  reasons << "committed-clean #{totals['committed_clean_pct']}% < #{min_clean}%"
end

verdict = {
  'schema' => 'banner-quality/v1',
  'as_of' => opts[:now].iso8601, 'window_days' => days,
  'floors' => { 'min_mean_overall' => min_overall, 'min_committed_clean_pct' => min_clean },
  'flag' => !reasons.empty?, 'reasons' => reasons,
  'totals' => totals, 'repos' => repos,
  'banners' => window.map { |r| { 'repo' => r['repo'], 'banner' => r['banner'], 'article' => r['article'] } }
}

fmt = ->(v) { v.nil? ? '—' : v.to_s }
md = []
md << "## 🖼️ Banner quality — trailing #{days} days"
md << ''
if window.empty?
  md << "_No banners were committed in the window (the grow tick may be paused, or every tick predates the loop's telemetry)._"
else
  status = reasons.empty? ? "✅ within floors (mean overall ≥ #{min_overall}, committed-clean ≥ #{min_clean}%)" : "❌ #{reasons.join('; ')}"
  md << "**#{status}**"
  md << ''
  md << '| Repo | Banners | Critiqued | Mean overall | Thumbnail holds | Committed clean | Fallback | Cost (list) |'
  md << '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |'
  repos.sort.each do |repo, s|
    md << "| #{repo} | #{s['banners']} | #{s['critiqued']} | #{fmt.call(s['mean_overall'])} | #{fmt.call(s['thumbnail_holds_pct'])}% | #{fmt.call(s['committed_clean_pct'])}% | #{fmt.call(s['fallback_pct'])}% | $#{s['cost_usd']} |"
  end
  md << "| **all** | **#{totals['banners']}** | **#{totals['critiqued']}** | **#{fmt.call(totals['mean_overall'])}** | **#{fmt.call(totals['thumbnail_holds_pct'])}%** | **#{fmt.call(totals['committed_clean_pct'])}%** | **#{fmt.call(totals['fallback_pct'])}%** | **$#{totals['cost_usd']}** |"
  worst = window.select { |r| r['critic'] }.sort_by { |r| r['critic']['overall'].to_f }.first(5)
  unless worst.empty?
    md << ''
    md << 'Lowest-scored this window:'
    md << ''
    worst.each do |r|
      md << "- `#{r['repo']}/#{File.basename(r['banner'].to_s)}` — #{r['critic']['overall']}: #{r['critic']['next_change'].to_s.gsub(/\s+/, ' ')[0, 160]}"
    end
  end
end
md << ''

File.write(opts[:summary], md.join("\n")) if opts[:summary]
File.write(opts[:json], JSON.pretty_generate(verdict) + "\n") if opts[:json]
puts md.join("\n") unless opts[:summary]
exit 0
