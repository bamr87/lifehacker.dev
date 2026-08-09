#!/usr/bin/env ruby
# =============================================================================
# lint_oneline.rb — the one-paragraph-per-line rule, as a FINDING
# -----------------------------------------------------------------------------
# The house rule (no soft-wrapped markdown prose) was already enforced, by
# markdown-oneline.yml calling tools/unwrap-prose.py --check. What it was not,
# was a *finding* — and in this repo that is the difference between a rule the
# fleet can heal and a rule that just goes red:
#
#   * run-all.sh is what CLAUDE.md tells every human and agent to run before
#     opening a PR. It did not cover this rule, so "the harness is green" did
#     not mean "CI will be green".
#   * fleet-bugfix (auto-fix.yml) is prompted to read findings.jsonl and fix what
#     it finds. A violation that produces no finding is invisible to it, so
#     nothing ever auto-fixed one — even though the fix is a single deterministic,
#     idempotent command.
#   * the sticky PR report, the triage queue and the health dashboard are all fed
#     from findings.jsonl too, so the rule was absent from every one of them.
#
# That is why PR #412 sat red for four days on a one-command fix. This check puts
# the rule inside the contract; the standalone workflow stays as independent
# enforcement (it is seeded from the bamr87 hub's prose kit, so it is not ours to
# retire).
#
# severity:error deliberately — it is already a hard gate in CI, and telling an
# agent "non-blocking" about something that will certainly block its PR is worse
# than saying nothing.
#
# Stdlib only. Run: ruby scripts/ci/lint_oneline.rb
# =============================================================================
require_relative '_lib'
require 'open3'

TOOL = File.join(LH::ROOT, 'tools', 'unwrap-prose.py')

# Mirror of the exclude list in .github/workflows/markdown-oneline.yml. Keep the
# two in step: if they drift, `run-all.sh` and the workflow disagree about what
# is a violation, which is exactly the local-vs-CI gap this check exists to close.
EXCLUDES = ['(^|/)SCHEMA\.md$', '(^|/)CHANGELOG\.md$'].freeze

def done(findings)
  errs = LH.write('oneline', findings)
  exit(errs.zero? ? 0 : 1)
end

done([LH.finding(check_id: 'oneline', severity: 'info', rule: 'tool-missing',
                 evidence: 'tools/unwrap-prose.py not present; skipped')]) unless File.exist?(TOOL)

cmd = ['python3', TOOL, '--check']
EXCLUDES.each { |e| cmd.push('--exclude', e) }

out, status = begin
  Open3.capture2e(*cmd, chdir: LH::ROOT)
rescue StandardError => e
  # No python3 on the box (or it could not be spawned). Report it rather than
  # passing silently: a check that cannot run has NOT verified anything, and a
  # silent skip is indistinguishable from a clean result in the gate.
  done([LH.finding(check_id: 'oneline', severity: 'warning', rule: 'check-unavailable',
                   evidence: "could not run unwrap-prose.py (#{e.class}: #{e.message}); prose is UNVERIFIED")])
end

# Ask the returned status, never $? — Open3 waits in its own thread, so $? is nil
# in the caller and `$?.success?` raises. (The exact bug the Prime Directive
# runner shipped; see /docs/the-box-with-no-internet/.)
done([]) if status.success?

# --check prints one repo-relative path per offending file, then a blank line and
# an "N file(s) would change." summary. Take the paths; ignore the prose.
files = out.split("\n").map(&:strip).reject(&:empty?)
             .reject { |l| l.end_with?('would change.') || l.start_with?('All markdown prose') }

findings = files.map do |f|
  LH.finding(check_id: 'oneline', severity: 'error', rule: 'wrapped-prose', file: f,
             evidence: 'soft-wrapped markdown prose — the house rule is one paragraph per line. ' \
                       'Fix deterministically: `python3 tools/unwrap-prose.py --write`')
end

# Non-zero exit with no parseable path list means the tool failed in a way we did
# not model (bad flag, traceback). Surface that instead of reporting "clean".
if findings.empty?
  findings << LH.finding(check_id: 'oneline', severity: 'error', rule: 'check-failed',
                         evidence: "unwrap-prose.py --check exited #{status.exitstatus} with no file list: #{out.split("\n").first(3).join(' / ')}")
end

done(findings)
