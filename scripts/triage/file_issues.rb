#!/usr/bin/env ruby
# =============================================================================
# file_issues.rb — turn the ranked queue into GitHub issues (dedup + route)
# -----------------------------------------------------------------------------
# Reads _data/health/queue.json and, per item, finds-or-files an issue:
#   * search by the stable `triage-fp:` marker (gh issue list --search)
#   * none open      -> create (routed to the right repo, labeled, scored)
#   * already open    -> comment "still failing" (no duplicate)
#   * previously closed -> reopen with a regression note
# It NEVER closes an issue and NEVER touches a human-authored issue — it only
# acts on issues carrying its own fingerprint marker. The single human gate
# (merge) is unaffected; issues are cheap and a human can close any of them.
#
# DRY-RUN BY DEFAULT (prints the gh commands). Pass --apply to execute. A
# MAX_NEW cap stops a first run from flooding the reviewer with hundreds of
# issues; the rest are reported as deferred (next run files them).
#
#   ruby scripts/triage/file_issues.rb [--apply] [--max-new N]
# =============================================================================
require 'shellwords'
require_relative '_lib'

APPLY   = ARGV.include?('--apply')
MAX_NEW = (ARGV[ARGV.index('--max-new') + 1].to_i if ARGV.include?('--max-new')) || 10

queue = JSON.parse(LH.read(File.join(Triage::HEALTH, 'queue.json')))
abort 'queue.json is empty; run build_queue.rb first' if queue.empty?

def sh(cmd)
  out = `#{cmd} 2>&1`
  [out.strip, $?.success?]
end

# Run a gh command (or just print it in dry-run). Returns [stdout, ok].
def gh(args, apply)
  cmd = "gh #{args}"
  unless apply
    puts "  DRY-RUN: #{cmd}"
    return ['', true]
  end
  sh(cmd)
end

def find_existing(repo, fp, apply)
  return [nil, nil] unless apply # dry-run can't search; assume "would create"
  out, ok = sh("gh issue list --repo #{repo} --state all --search #{Shellwords.escape("triage-fp: #{fp}")} --json number,state --limit 1")
  return [nil, nil] unless ok
  data = (JSON.parse(out) rescue [])
  data.empty? ? [nil, nil] : [data[0]['number'], data[0]['state']]
end

new_count = 0
filed = []
deferred = []

queue.each do |item|
  fp   = item['fingerprint']
  repo = item['repo']
  num, state = find_existing(repo, fp, APPLY)

  if num && state == 'OPEN'
    gh("issue comment #{num} --repo #{repo} --body #{Shellwords.escape("Still failing as of this triage run (occurrences: #{item['occurrences']}, score: #{item['score']}).")}", APPLY)
    filed << "updated ##{num} (#{repo})"
    next
  end

  if num && state == 'CLOSED'
    gh("issue reopen #{num} --repo #{repo}", APPLY)
    gh("issue comment #{num} --repo #{repo} --body #{Shellwords.escape('Regression: this finding reappeared after the issue was closed.')}", APPLY)
    filed << "reopened ##{num} (#{repo})"
    next
  end

  # None exists -> create, respecting the per-run cap.
  if new_count >= MAX_NEW
    deferred << item['title']
    next
  end
  labels = [item['type'], item['area'], "severity/#{item['severity']}", 'source/ci-test'].join(',')
  title  = item['title']
  body   = Triage.issue_body(item)
  out, ok = gh("issue create --repo #{repo} --title #{Shellwords.escape(title)} --label #{Shellwords.escape(labels)} --body #{Shellwords.escape(body)}", APPLY)
  if ok
    new_count += 1
    filed << "created (#{repo}) #{title}"
  else
    # Don't report a create that didn't happen. The repo-scoped token can't write
    # to an external repo (e.g. the upstream theme), so a routed bug would
    # otherwise be silently lost. Defer it (loud) for a human / a PAT-bearing run.
    deferred << "#{title} (create FAILED on #{repo})"
    warn "[file_issues] create FAILED on #{repo}: #{out.to_s[0, 200]}"
  end
end

puts "\n[file_issues] mode=#{APPLY ? 'APPLY' : 'dry-run'}  new=#{new_count} (cap #{MAX_NEW})  actions=#{filed.size}  deferred=#{deferred.size}"
filed.first(20).each { |l| puts "  #{l}" }
unless deferred.empty?
  puts "  deferred (cap reached, next run): #{deferred.size}"
  deferred.first(5).each { |t| puts "    - #{t}" }
end
