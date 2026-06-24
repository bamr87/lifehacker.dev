#!/usr/bin/env ruby
# =============================================================================
# build_queue.rb — findings.jsonl -> the ranked, deduplicated work queue
# -----------------------------------------------------------------------------
# Deterministic and side-effect-free (no gh, no network). Reads PR1's
# test-results/findings.jsonl, keeps the actionable findings, dedups by the
# PR1-computed fingerprint, classifies and RICE-scores each, and writes:
#   * _data/health/queue.json   — the ranked queue (PR3's input contract)
#   * _data/health/summary.yml  — rollups for the /docs/health/ dashboard
#   * _data/health/findings.jsonl — a committed snapshot so scheduled jobs with
#                                   no workflow-artifact access can still read it
#
#   ruby scripts/triage/build_queue.rb [path/to/findings.jsonl]
# =============================================================================
require 'time'
require_relative '_lib'

src = ARGV[0] ||
      [File.join(LH::ROOT, 'test-results', 'findings.jsonl'),
       File.join(Triage::HEALTH, 'findings.jsonl')].find { |p| File.exist?(p) }

abort "no findings.jsonl found (run the test harness first)" unless src && File.exist?(src)

findings = LH.read(src).each_line.map { |l| JSON.parse(l) rescue nil }.compact

# Classify, RICE-score, and dedup by fingerprint — the pure ranking the E2E
# simulation also calls, so the CLI and the sim can never diverge.
items = Triage.build(findings)

# --- write the queue ---------------------------------------------------------
Dir.mkdir(Triage::HEALTH) unless Dir.exist?(Triage::HEALTH)
File.write(File.join(Triage::HEALTH, 'queue.json'), JSON.pretty_generate(items) + "\n")

# Committed snapshot of the findings (for artifact-less scheduled runs).
File.write(File.join(Triage::HEALTH, 'findings.jsonl'),
           findings.map { |f| JSON.generate(f) }.join("\n") + "\n")

# --- rollup summary for the dashboard ----------------------------------------
by = lambda { |key| items.each_with_object(Hash.new(0)) { |i, h| h[i[key]] += 1 } }
summary = {
  'generated_at' => (defined?(STAMP) ? STAMP : Time.now.utc.iso8601),
  'queue_size'   => items.size,
  'by_severity'  => by.call('severity'),
  'by_type'      => by.call('type'),
  'by_route'     => by.call('route'),
  'top'          => items.first(10).map { |i| i.slice('severity', 'type', 'title', 'score', 'repo') },
  'analytics_stale' => !!(Triage.analytics['stale']),
  'analytics_generated_at' => Triage.analytics['generated_at']
}
File.write(File.join(Triage::HEALTH, 'summary.yml'), summary.to_yaml)

errs  = items.count { |i| i['severity'] == 'sev1' || i['severity'] == 'sev2' }
puts "[build_queue] #{items.size} queued from #{findings.size} findings "\
     "(#{errs} sev1/2). by_route=#{summary['by_route']}"
items.first(8).each { |i| puts "  #{i['score']}  #{i['severity']}  #{i['route']}  #{i['type']}  #{i['title'][0, 70]}" }
