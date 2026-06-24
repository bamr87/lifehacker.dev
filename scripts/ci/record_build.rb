#!/usr/bin/env ruby
# =============================================================================
# record_build.rb — the ONE producer of the sev1 build finding
# -----------------------------------------------------------------------------
# `build` is the only check that classifies to sev1 (the tier policy.rb freezes
# growth on), so it must have exactly one implementation used everywhere — CI,
# triage, nightly, the sim — not an inline heredoc in a single workflow. Given
# the build's exit status, this writes test-results/build.json with the
# canonical finding (or an empty array on success). aggregate.rb already reads
# build.json, so the sev1 then flows through the same findings.jsonl contract on
# every path.
#   ruby scripts/ci/record_build.rb <exit_status>   # 0 = built, non-zero = failed
# =============================================================================
require_relative '_lib'

ok = ARGV[0].to_i.zero?
findings = ok ? [] : [LH.finding(
  check_id: 'build', severity: 'error', rule: 'jekyll-build-failed',
  evidence: 'jekyll build --strict failed in safe mode; see the build step log',
  route_to: 'local'
)]

LH.write('build', findings)
exit 0
