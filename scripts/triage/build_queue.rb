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

# Keep actionable findings, then dedup by fingerprint (count occurrences).
groups = Hash.new { |h, k| h[k] = [] }
findings.each { |f| groups[f['fingerprint']] << f if Triage.actionable?(f) }

items = groups.map do |fp, fs|
  rep = fs.min_by { |f| { 'error' => 0, 'warning' => 1, 'info' => 2 }[f['severity']] || 3 }
  c = Triage.classify(rep)
  url = Triage.url_for(rep['file'])
  views = Triage.reach_views(url)
  item = {
    'fingerprint' => fp,
    'check_id'    => rep['check_id'],
    'rule'        => rep['rule'],
    'file'        => rep['file'],
    'line'        => rep['line'],
    'evidence'    => rep['evidence'],
    'type'        => c[:type],
    'area'        => c[:area],
    'severity'    => c[:severity],
    'route'       => c[:route],
    'repo'        => c[:repo],
    'url_path'    => url,
    'reach_views' => views,
    'occurrences' => fs.size,
    'score'       => Triage.score(c[:severity], rep['severity'], views, c[:route]),
    'issue_number' => nil,   # filled by file_issues.rb after creation
    'blocked_on'  => nil
  }
  item['title'] = Triage.issue_title(item)
  item
end

items.sort_by! { |i| [-i['score'], i['severity'], i['file'].to_s] }

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
