#!/usr/bin/env ruby
# =============================================================================
# scripts/retro/collect_merged.rb — capture merged-branch metadata for the quest forge
# -----------------------------------------------------------------------------
# The last stage of the retrospective chain: once a thread's retrospective is
# published, this systematically captures the metadata of the merged branches that
# built it — PR number, title, branch, squash-merge commit SHA, merge date, size,
# and labels — so the quest-forge agent can derive an it-journey.dev quest from it
# (see docs/RETROSPECTIVE-HOOK.md → Quest forge).
#
#   ruby scripts/retro/collect_merged.rb                 # all merged PRs, as JSON
#   ruby scripts/retro/collect_merged.rb --since 2026-06-23   # merged on/after a date
#   ruby scripts/retro/collect_merged.rb --markdown      # a ready-to-embed table
#
# Pure metadata: it shells out to `gh` (read-only) and prints; it files nothing.
# =============================================================================
require 'json'

since = nil
fmt   = :json
ARGV.each_with_index do |a, i|
  since = ARGV[i + 1] if a == '--since'
  fmt   = :markdown if a == '--markdown'
end

raw = `gh pr list --state merged --limit 200 --json number,title,headRefName,mergeCommit,mergedAt,additions,deletions,labels,url 2>/dev/null`
abort 'collect_merged: `gh pr list` failed (no gh / not in a repo?)' if raw.strip.empty?

prs = (JSON.parse(raw) rescue [])
prs = prs.select { |p| p['mergedAt'].to_s >= since } if since
prs = prs.sort_by { |p| p['number'] }

rows = prs.map do |p|
  {
    'pr'        => p['number'],
    'title'     => p['title'],
    'branch'    => p['headRefName'],
    'merge_sha' => p.dig('mergeCommit', 'oid'),
    'merged_at' => p['mergedAt'].to_s[0, 10],
    'additions' => p['additions'],
    'deletions' => p['deletions'],
    'labels'    => (p['labels'] || []).map { |l| l['name'] },
    'url'       => p['url']
  }
end

if fmt == :markdown
  puts "| PR | Merge commit | Date | Δ | Branch | Title |"
  puts "|---|---|---|---|---|---|"
  rows.each do |r|
    sha = r['merge_sha'].to_s[0, 9]
    puts "| ##{r['pr']} | `#{sha}` | #{r['merged_at']} | +#{r['additions']}/-#{r['deletions']} | `#{r['branch']}` | #{r['title']} |"
  end
  tot_a = rows.sum { |r| r['additions'].to_i }
  tot_d = rows.sum { |r| r['deletions'].to_i }
  puts "\n**#{rows.size} merged branches · +#{tot_a} / -#{tot_d} lines**"
else
  puts JSON.pretty_generate(
    'count'      => rows.size,
    'additions'  => rows.sum { |r| r['additions'].to_i },
    'deletions'  => rows.sum { |r| r['deletions'].to_i },
    'branches'   => rows
  )
end
