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
#
# PR scoping: set LH_CHANGED_FILES (a path to a newline-separated changed-file
# list, or an inline list) and the COMMENT + GATE narrow to findings on those
# files — plus global findings (build/drift) — so a content PR isn't drowned in or
# blocked by pre-existing findings elsewhere. findings.jsonl stays the COMPLETE
# repo scan. Unset (nightly, triage, push) => full report. The pipeline sets it
# only for content-only PRs.
#   ruby scripts/ci/aggregate.rb
#   LH_CHANGED_FILES=changed.txt ruby scripts/ci/aggregate.rb   # scoped
# =============================================================================
require_relative '_lib'
require 'time'
require 'set'

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

# --- optional PR scoping -----------------------------------------------------
# When CI sets LH_CHANGED_FILES (a path to a newline-separated changed-file list,
# or an inline whitespace/comma list), the PR COMMENT and the GATE are scoped to
# findings that belong to those files — so a content PR is neither drowned in nor
# blocked by pre-existing findings on files it never touched. Global findings
# (no file: build/drift) always count. htmlproofer keys findings by the BUILT
# _site/ path, not the source .md, so a changed collection item is also matched
# by its slug appearing as a path segment of the finding's file. With the env
# unset (nightly, triage, push to main), nothing is scoped — the full report stands.
# findings.jsonl below stays COMPLETE either way; only what humans see and the gate change.
def lh_changed_list
  raw = ENV['LH_CHANGED_FILES'].to_s.strip
  return [] if raw.empty?
  (File.file?(raw) ? File.read(raw, encoding: 'UTF-8').split(/\r?\n/) : raw.split(/[\s,]+/))
    .map(&:strip).reject(&:empty?)
end

changed       = lh_changed_list
scoped        = !changed.empty?
changed_paths = changed.map { |p| p.sub(%r{\A\./}, '') }.to_set
# Distinctive slugs of changed collection items; skip generic top-level page names
# (index, blog, …) whose slug would over-match every page's _site output.
GENERIC_SLUGS = %w[index blog hacks tools news field-notes categories tags contact search sitemap 404 about].freeze
changed_slugs = changed_paths.map { |p|
  next nil unless p =~ %r{\Apages/_[a-z]+/(.+)\.md\z}
  slug = File.basename(Regexp.last_match(1)).sub(/\A\d{4}-\d{2}-\d{2}-/, '')
  GENERIC_SLUGS.include?(slug) ? nil : slug
}.compact.to_set

in_scope = lambda do |f|
  return true unless scoped
  file = f['file'].to_s.sub(%r{\A\./}, '')
  return true if file.empty?                  # global finding (build / drift)
  return true if changed_paths.include?(file) # source-path finding (frontmatter / brand / prime-directive)
  changed_slugs.any? { |s| file =~ %r{(\A|/)#{Regexp.escape(s)}(/|\.|\z)} } # _site/ finding (htmlproofer)
end

shown  = scoped ? findings.select { |f| in_scope.call(f) } : findings
hidden = findings.size - shown.size

# --- findings.jsonl (the contract) -------------------------------------------
Dir.mkdir(LH::RESULTS) unless Dir.exist?(LH::RESULTS)
File.open(File.join(LH::RESULTS, 'findings.jsonl'), 'w') do |io|
  findings.each { |f| io.puts(JSON.generate(f)) }
end

# --- summary.json ------------------------------------------------------------
# Counts + gate are over the SHOWN set (scoped to the PR when LH_CHANGED_FILES is
# set, else the whole repo). repo_total/hidden expose the full picture for context.
by_sev   = Hash.new(0)
by_check = Hash.new(0)
by_route = Hash.new(0)
shown.each do |f|
  by_sev[f['severity']]   += 1
  by_check[f['check_id']] += 1
  by_route[f['route_to']] += 1
end
errors = by_sev['error']
summary = {
  'generated_at'   => Time.now.utc.iso8601,
  'scoped'         => scoped,
  'error_count'    => errors,
  'warning_count'  => by_sev['warning'],
  'info_count'     => by_sev['info'],
  'total'          => shown.size,
  'repo_total'     => findings.size,
  'hidden_other_files' => hidden,
  'by_check'       => by_check,
  'by_route'       => by_route,
  'prime_directive_candidates' => shown.count { |f| f['prime_directive_candidate'] },
  'gate'           => errors.zero? ? 'pass' : 'fail'
}
File.write(File.join(LH::RESULTS, 'summary.json'), JSON.pretty_generate(summary))

# --- sticky PR comment -------------------------------------------------------
def row(f)
  loc = f['file'].to_s.empty? ? '—' : "`#{f['file']}#{f['line'] ? ":#{f['line']}" : ''}`"
  "| #{f['severity']} | #{f['check_id']} | #{loc} | #{f['rule']} | #{f['evidence'].to_s.gsub('|', '\\|')[0, 120]} |"
end

verdict = errors.zero? ? 'PASS' : 'FAIL'
blocking = shown.select { |f| f['severity'] == 'error' }
notable  = shown.select { |f| f['severity'] == 'warning' }

lines = []
lines << '<!-- lh-test-report -->'
lines << '## lifehacker.dev test harness'
lines << ''
lines << "**Gate: #{verdict}** — #{errors} error, #{by_sev['warning']} warning, #{by_sev['info']} info across #{by_check.size} checks."
if scoped
  lines << ''
  lines << "_Scoped to this PR's #{changed_paths.size} changed file(s); #{hidden} finding(s) on other files hidden (see the `findings.jsonl` artifact for the full repo scan)._"
end
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

scope_note = scoped ? "shown #{shown.size}/#{findings.size} (scoped to #{changed_paths.size} PR file(s))" : "#{findings.size} findings"
puts "[aggregate] #{scope_note} — gate #{verdict} (#{errors} error)"
exit(errors.zero? ? 0 : 1)
