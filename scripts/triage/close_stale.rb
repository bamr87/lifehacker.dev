#!/usr/bin/env ruby
# =============================================================================
# close_stale.rb — close bot-filed issues whose findings stopped reproducing
# -----------------------------------------------------------------------------
# The tracker used to be append-only: file_issues.rb finds-or-files (and
# reopens on regression) but never closes, so a finding fixed by a merged PR —
# or retired by a policy change like the 2026-07-15 glossary recalibration —
# left a zombie issue open forever. Worse, the issue factory kept re-analyzing
# the zombies: a work order built on retired findings can never produce a fix
# PR, so every fixer run re-derived "obsolete, recommend closing" as a comment
# nobody acted on (issue #173 collected five of them). This script is the
# missing half of the loop:
#
#   * finding issues — OPEN, carrying our `triage-fp:` marker, fingerprint no
#     longer maps to an actionable finding -> close (reason: not planned).
#     A regression reopens it automatically (file_issues.rb's reopen path).
#   * work orders — OPEN, labeled factory:work-order, every member closed
#     -> close (the batch is shipped or void; either way it's consumed).
#
# It closes ONLY what the automation owns: an issue without the fingerprint
# marker (any human-authored issue) is untouchable — same promise as the
# filer. Fail-safe: refuses to sweep when the findings are degraded (broken
# build, unproofed _site), because a fingerprint that vanished for lack of a
# check run is not a fingerprint that stopped reproducing.
#
# DRY-RUN BY DEFAULT (prints the gh commands). Pass --apply to execute. The
# MAX_CLOSE cap bounds one run's blast radius; the rest close next run.
#
#   ruby scripts/triage/close_stale.rb [--apply] [--max-close N]
# =============================================================================
require 'shellwords'
require_relative '_lib'

APPLY     = ARGV.include?('--apply')
MAX_CLOSE = (ARGV[ARGV.index('--max-close') + 1].to_i if ARGV.include?('--max-close')) || 40

src = [File.join(LH::ROOT, 'test-results', 'findings.jsonl'),
       File.join(Triage::HEALTH, 'findings.jsonl')].find { |p| File.exist?(p) }
abort '[close_stale] no findings.jsonl found (run the test harness first)' unless src
findings = LH.read(src).each_line.map { |l| JSON.parse(l) rescue nil }.compact

ok, reason = Triage.sweep_safe?(findings)
abort "[close_stale] refusing to sweep: #{reason}" unless ok

def sh(cmd)
  out = `#{cmd} 2>&1`
  [out.strip, $?.success?]
end

# Run a mutating gh command (or just print it in dry-run). Read-only gh calls
# go through sh() directly — a dry run still plans from real state when it can.
def gh(args, apply)
  cmd = "gh #{args}"
  unless apply
    puts "  DRY-RUN: #{cmd}"
    return ['', true]
  end
  sh(cmd)
end

# This repo only: the repo-scoped token can't close upstream, and the theme
# repo's issue hygiene is its own maintainer's call.
out, listed = sh("gh issue list --repo #{Triage::THIS_REPO} --state open --limit 500 --json number,title,body,labels")
unless listed
  msg = "[close_stale] gh issue list failed: #{out[0, 200]}"
  APPLY ? abort(msg) : (warn "#{msg} — dry-run has nothing to plan from"; exit 0)
end
open_issues = (JSON.parse(out) rescue []).map do |i|
  { number: i['number'], title: i['title'].to_s, body: i['body'],
    labels: (i['labels'] || []).map { |l| l.is_a?(Hash) ? l['name'] : l.to_s } }
end

live  = Triage.live_fingerprints(findings)
stale = Triage.sweep_stale_findings(open_issues, live)

closed  = []
deferred = []
note = 'Auto-closed by the triage sweep: the current harness run no longer reports ' \
       'this finding (fixed, moved, or the rule was retired). If it regresses, ' \
       'the next triage run reopens this issue automatically.'
stale.each do |i|
  if closed.size >= MAX_CLOSE
    deferred << "##{i[:number]} #{i[:title][0, 60]}"
    next
  end
  gh("issue close #{i[:number]} --repo #{Triage::THIS_REPO} --reason 'not planned' --comment #{Shellwords.escape(note)}", APPLY)
  closed << "##{i[:number]} (finding gone)"
end

# Work orders: resolve member states with bounded lookups — members this run is
# closing count as closed already, the rest are asked read-only (so the dry-run
# plan shows the full cascade an apply run would produce).
orders       = open_issues.select { |i| i[:labels].include?(Triage::ORDER_LABEL) }
would_close  = stale.first(MAX_CLOSE).map { |i| i[:number] }.to_set
member_state = {}
orders.flat_map { |o| Triage.member_numbers(o[:body]) }.uniq.each do |n|
  if would_close.include?(n)
    member_state[n] = 'CLOSED'
  else
    state, k = sh("gh issue view #{n} --repo #{Triage::THIS_REPO} --json state --jq .state")
    member_state[n] = k ? state : 'UNKNOWN'
  end
end

order_note = 'Auto-closed by the triage sweep: every member issue of this work order ' \
             'is closed, so there is nothing left for the fix line to consume.'
Triage.sweep_finished_orders(orders, member_state).each do |o|
  if closed.size >= MAX_CLOSE
    deferred << "##{o[:number]} #{o[:title][0, 60]}"
    next
  end
  gh("issue close #{o[:number]} --repo #{Triage::THIS_REPO} --reason 'not planned' --comment #{Shellwords.escape(order_note)}", APPLY)
  closed << "##{o[:number]} (work order consumed)"
end

puts "\n[close_stale] mode=#{APPLY ? 'APPLY' : 'dry-run'}  open=#{open_issues.size}  " \
     "live-fps=#{live.size}  closed=#{closed.size} (cap #{MAX_CLOSE})  deferred=#{deferred.size}"
closed.first(30).each { |l| puts "  closed #{l}" }
unless deferred.empty?
  puts "  deferred (cap reached, next run): #{deferred.size}"
  deferred.first(5).each { |t| puts "    - #{t}" }
end
