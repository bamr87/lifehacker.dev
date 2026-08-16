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

# A check that is not listed here writes its JSON and is then silently dropped:
# it never reaches findings.jsonl, the PR comment, or the gate. Adding a lint to
# run-all.sh is therefore only half the wiring — add it here too, or it runs for
# nobody. (`preview` was added with scripts/ci/lint_preview.rb.)
# EVERY check that writes a <name>.json must be listed here, or its findings are
# discarded. run-all.sh runs each lint with `|| true` (deliberate — one failing
# check must not hide the others), so the gate is decided SOLELY by what lands in
# findings.jsonl. A check missing from this list therefore runs, prints, exits
# non-zero, and changes nothing: not the gate, not the PR report, not the triage
# queue, not what fleet-bugfix can see and repair.
#
# `artifacts` and `agents` were both missing, so the duplicate-backlog-id guard,
# the duplicate-data-key guard, and the dangling-agent-ref guard were all
# decorative — including, embarrassingly, one added in #441 with a commit message
# claiming it gated. `oneline` is new (lint_oneline.rb). If you add a check, add
# it here in the same commit; there is no other wire.
CHECK_FILES = %w[frontmatter drift brand prime-directive preview htmlproofer build
                 artifacts agents oneline wire tokens]
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
GENERIC_SLUGS = %w[index blog hacks tools news field-notes wire categories tags contact search sitemap 404 about].freeze
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
# How many rows each section prints before deferring to the artifact. Whenever a
# cap bites, the comment SAYS so (see the `capped` note below) — a silently
# truncated list reads as "that's all of them", which is how a 1,786-error report
# can look like a 25-error one.
BLOCKING_ROWS = 25
WARNING_ROWS  = 50
EVIDENCE_MAX  = 120

def loc_of(f)
  f['file'].to_s.empty? ? '—' : "`#{f['file']}#{f['line'] ? ":#{f['line']}" : ''}`"
end

# One table cell from arbitrary finding evidence. Order matters: squash, then
# TRUNCATE, then escape. Escaping first lets the cut land between a backslash and
# the pipe it escapes, leaving a trailing `\` that eats the cell's own closing
# delimiter and smears the row across the table. The ellipsis is the tell that
# there is more — without it a mid-word cut reads as the evidence itself.
def cell(text)
  s = text.to_s.gsub(/\s+/, ' ').strip
  s = "#{s[0, EVIDENCE_MAX - 1]}…" if s.length > EVIDENCE_MAX
  s.gsub('|', '\\|')
end

def row(f)
  "| #{f['severity']} | #{f['check_id']} | #{loc_of(f)} | #{f['rule']} | #{cell(f['evidence'])} |"
end

# "showing N of M" whenever a section printed fewer rows than it has findings.
def capped(shown_rows, total)
  return nil if total <= shown_rows
  "_Showing #{shown_rows} of #{total}; the rest are in the `findings.jsonl` artifact._"
end

verdict = errors.zero? ? 'PASS' : 'FAIL'
blocking = shown.select { |f| f['severity'] == 'error' }
notable  = shown.select { |f| f['severity'] == 'warning' }
quiet    = shown.select { |f| f['severity'] == 'info' }

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
  blocking.first(BLOCKING_ROWS).each { |f| lines << row(f) }
  if (note = capped(BLOCKING_ROWS, blocking.size))
    lines << ''
    lines << note
  end
  lines << ''
end
unless notable.empty?
  lines << "<details><summary>#{notable.size} warning(s) (non-blocking)</summary>"
  lines << ''
  lines << '| sev | check | where | rule | evidence |'
  lines << '|---|---|---|---|---|'
  notable.first(WARNING_ROWS).each { |f| lines << row(f) }
  if (note = capped(WARNING_ROWS, notable.size))
    lines << ''
    lines << note
  end
  lines << '</details>'
  lines << ''
end
# Info findings were counted in the header and then shown NOWHERE, so "58 info"
# was a number with no way to see what it stood for short of downloading the
# artifact. They are context rather than defects (an unverifiable command block,
# a deliberately ignored theme link), and they repeat heavily — 56 of one rule is
# routine — so a row each would bury the warnings above. Group by check+rule with
# a count and one example instead: same information, two rows instead of 58.
unless quiet.empty?
  groups = quiet.group_by { |f| [f['check_id'], f['rule']] }
                .sort_by { |_, fs| -fs.size }
  lines << "<details><summary>#{quiet.size} info (context, nothing to fix)</summary>"
  lines << ''
  lines << '| count | check | rule | example |'
  lines << '|---|---|---|---|'
  groups.each { |(check, rule), fs| lines << "| #{fs.size} | #{check} | #{rule} | #{loc_of(fs.first)} |" }
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
