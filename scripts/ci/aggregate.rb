#!/usr/bin/env ruby
# =============================================================================
# aggregate.rb — collapse every check into the ONE frozen contract
# -----------------------------------------------------------------------------
# Reads each check's test-results/<check>.json, stamps a stable fingerprint on
# every finding, and writes:
#   * test-results/findings.jsonl  — one finding per line. THE contract PR2
#     (triage) dedups against and PR3 (dispatch) ranks from. Do not reshape
#     these fields without bumping every consumer.
#   * test-results/summary.json    — rolled-up totals.
#   * test-results/comment.md      — the sticky PR comment body.
#
# Fingerprint = sha1(check_id | downcased-path | rule)[0,12]. Line numbers are
# deliberately EXCLUDED so an issue stays the same identity when a file shifts
# by a few lines. PR1 owns this so dedup is stable before PR2 ever reads it.
#
# Exit code: 1 if any finding is severity:error (fails the merge gate), else 0.
#   ruby scripts/ci/aggregate.rb
# =============================================================================
require_relative '_lib'
require 'time'

CHECK_FILES = %w[frontmatter drift brand prime-directive htmlproofer build]
SEV_ORDER = { 'error' => 0, 'warning' => 1, 'info' => 2 }.freeze

findings = []
CHECK_FILES.each do |name|
  path = File.join(LH::RESULTS, "#{name}.json")
  next unless File.exist?(path)
  data = (JSON.parse(File.read(path, encoding: 'UTF-8')) rescue [])
  next unless data.is_a?(Array)
  data.each do |f|
    next unless f.is_a?(Hash) && f['check_id']
    fp = Digest::SHA1.hexdigest("#{f['check_id']}|#{f['file'].to_s.downcase}|#{f['rule']}")[0, 12]
    findings << f.merge('fingerprint' => fp)
  end
end

findings.sort_by! { |f| [SEV_ORDER[f['severity']] || 9, f['check_id'].to_s, f['file'].to_s, f['line'] || 0] }

# --- findings.jsonl (the contract) -------------------------------------------
Dir.mkdir(LH::RESULTS) unless Dir.exist?(LH::RESULTS)
File.open(File.join(LH::RESULTS, 'findings.jsonl'), 'w') do |io|
  findings.each { |f| io.puts(JSON.generate(f)) }
end

# --- summary.json ------------------------------------------------------------
by_sev   = Hash.new(0)
by_check = Hash.new(0)
by_route = Hash.new(0)
findings.each do |f|
  by_sev[f['severity']]   += 1
  by_check[f['check_id']] += 1
  by_route[f['route_to']] += 1
end
errors = by_sev['error']
summary = {
  'generated_at'   => Time.now.utc.iso8601,
  'error_count'    => errors,
  'warning_count'  => by_sev['warning'],
  'info_count'     => by_sev['info'],
  'total'          => findings.size,
  'by_check'       => by_check,
  'by_route'       => by_route,
  'prime_directive_candidates' => findings.count { |f| f['prime_directive_candidate'] },
  'gate'           => errors.zero? ? 'pass' : 'fail'
}
File.write(File.join(LH::RESULTS, 'summary.json'), JSON.pretty_generate(summary))

# --- sticky PR comment -------------------------------------------------------
def row(f)
  loc = f['file'].to_s.empty? ? '—' : "`#{f['file']}#{f['line'] ? ":#{f['line']}" : ''}`"
  "| #{f['severity']} | #{f['check_id']} | #{loc} | #{f['rule']} | #{f['evidence'].to_s.gsub('|', '\\|')[0, 120]} |"
end

verdict = errors.zero? ? 'PASS' : 'FAIL'
blocking = findings.select { |f| f['severity'] == 'error' }
notable  = findings.select { |f| f['severity'] == 'warning' }

lines = []
lines << '<!-- lh-test-report -->'
lines << '## lifehacker.dev test harness'
lines << ''
lines << "**Gate: #{verdict}** — #{errors} error, #{by_sev['warning']} warning, #{by_sev['info']} info across #{by_check.size} checks."
lines << ''
unless blocking.empty?
  lines << '### Blocking (must fix to merge)'
  lines << '| sev | check | where | rule | evidence |'
  lines << '|---|---|---|---|---|'
  blocking.first(25).each { |f| lines << row(f) }
  lines << ''
end
unless notable.empty?
  lines << "<details><summary>#{notable.size} warnings (non-blocking)</summary>"
  lines << ''
  lines << '| sev | check | where | rule | evidence |'
  lines << '|---|---|---|---|---|'
  notable.first(50).each { |f| lines << row(f) }
  lines << '</details>'
  lines << ''
end
pdc = summary['prime_directive_candidates']
lines << "Prime Directive: #{pdc} command block(s) flagged as Field Note candidate(s)." if pdc > 0
lines << ''
lines << '_Opened by CI · a human merges. The full machine-readable report is the `findings.jsonl` artifact._'
File.write(File.join(LH::RESULTS, 'comment.md'), lines.join("\n") + "\n")

puts "[aggregate] #{findings.size} findings — gate #{verdict} (#{errors} error)"
exit(errors.zero? ? 0 : 1)
