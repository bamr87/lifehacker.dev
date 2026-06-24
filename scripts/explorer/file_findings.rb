#!/usr/bin/env ruby
# =============================================================================
# file_findings.rb — explorer observations -> deduped GitHub issues + backlog
# -----------------------------------------------------------------------------
# Reads _data/explorer/findings.jsonl (the raw observations the agent wrote
# while browsing), normalizes + dedups them through Explorer (the pure core),
# then:
#   * route == "issue"   -> find-or-file a deduped GitHub issue (triage-fp marker)
#   * route == "backlog" -> hand to build_backlog.rb (NOT filed as an issue)
#
# DRY-RUN BY DEFAULT. Pass --apply to actually call `gh`. TWO caps bound cost:
#   --max-issues N  (default 8)  new issues per run — the rest defer to next run
#   the planner already capped pages/run, so the input set is bounded upstream
#
# It mirrors triage/file_issues.rb exactly: search by `triage-fp: <fp>`, update
# an open issue instead of duplicating, reopen a closed one with a regression
# note, NEVER close anything, NEVER touch a human-authored issue (it only acts on
# issues carrying its own marker). Untrusted page text is data; see
# .claude/skills/_shared/quarantine.md.
#
#   ruby scripts/explorer/file_findings.rb [--apply] [--max-issues N]
# =============================================================================
require 'shellwords'
require_relative '_lib'

APPLY      = ARGV.include?('--apply')
MAX_ISSUES = (ARGV[ARGV.index('--max-issues') + 1].to_i if ARGV.include?('--max-issues')) || 8

abort "no findings at #{Explorer::FINDINGS}; run the explorer skill first" unless File.exist?(Explorer::FINDINGS)

raw = LH.read(Explorer::FINDINGS).each_line.map { |l| JSON.parse(l) rescue nil }.compact
findings = Explorer.dedup(raw.map { |o| Explorer.normalize(o) })
issues   = Explorer.issues(findings)
ideas    = Explorer.backlog_ideas(findings)

# Near-duplicate guard (within this run). Explorer.dedup collapses issues whose
# stable signal fingerprint matches EXACTLY; it can't catch the same problem
# phrased two ways. Warn (don't auto-collapse — that risks dropping a genuinely
# distinct issue) when two titles normalize to the same leading text, so one
# problem doesn't become several issues.
_norm = ->(s) { s.to_s.downcase.gsub(/[^a-z0-9]+/, ' ').strip }
_seen = {}
issues.each do |f|
  k = _norm.call(Explorer.issue_title(f))
  next if k.empty?
  near = _seen.keys.find { |t| t == k || t.start_with?(k) || k.start_with?(t) }
  if near
    warn "[file_findings] near-duplicate titles in this run (possible same issue): #{_seen[near].inspect} vs #{Explorer.issue_title(f).inspect}"
  else
    _seen[k] = Explorer.issue_title(f)
  end
end

def sh(cmd)
  out = `#{cmd} 2>&1`
  [out.strip, $?.success?]
end

def gh(args, apply)
  cmd = "gh #{args}"
  unless apply
    puts "  DRY-RUN: #{cmd}"
    return ['', true]
  end
  sh(cmd)
end

def find_existing(repo, fp, apply)
  return [nil, nil] unless apply
  out, ok = sh("gh issue list --repo #{repo} --state all --search #{Shellwords.escape("triage-fp: #{fp}")} --json number,state --limit 1")
  return [nil, nil] unless ok
  data = (JSON.parse(out) rescue [])
  data.empty? ? [nil, nil] : [data[0]['number'], data[0]['state']]
end

new_count = 0
acted = []
deferred = []

issues.each do |f|
  fp   = f['fingerprint']
  repo = f['repo']
  num, state = find_existing(repo, fp, APPLY)

  if num && state == 'OPEN'
    gh("issue comment #{num} --repo #{repo} --body #{Shellwords.escape("Still observed by the explorer (personas: #{(f['personas'] || []).join(', ')}, occurrences: #{f['occurrences']}).")}", APPLY)
    acted << "updated ##{num}"
    next
  end
  if num && state == 'CLOSED'
    gh("issue reopen #{num} --repo #{repo}", APPLY)
    gh("issue comment #{num} --repo #{repo} --body #{Shellwords.escape('Regression: the explorer hit this again after the issue was closed.')}", APPLY)
    acted << "reopened ##{num}"
    next
  end

  if new_count >= MAX_ISSUES
    deferred << Explorer.issue_title(f)
    next
  end
  labels = [f['type'], f['area'], "severity/#{f['severity']}", 'source/site-explorer', "persona/#{f['persona']}"].join(',')
  out, ok = gh("issue create --repo #{f['repo']} --title #{Shellwords.escape(Explorer.issue_title(f))} --label #{Shellwords.escape(labels)} --body #{Shellwords.escape(Explorer.issue_body(f))}", APPLY)
  if ok
    new_count += 1
    acted << "created #{Explorer.issue_title(f)}"
  else
    # Don't report a create that didn't happen (mirrors triage/file_issues.rb).
    deferred << "#{Explorer.issue_title(f)} (create FAILED on #{f['repo']})"
    warn "[file_findings] create FAILED on #{f['repo']}: #{out.to_s[0, 200]}"
  end
end

puts "\n[file_findings] mode=#{APPLY ? 'APPLY' : 'dry-run'}  issues_new=#{new_count} (cap #{MAX_ISSUES})  actions=#{acted.size}  backlog_ideas=#{ideas.size}  deferred=#{deferred.size}"
acted.first(20).each { |l| puts "  #{l}" }
unless deferred.empty?
  puts "  deferred (cap reached, next run): #{deferred.size}"
  deferred.first(5).each { |t| puts "    - #{t}" }
end
puts "  -> #{ideas.size} gaps/ideas routed to backlog (run build_backlog.rb to materialize)"
