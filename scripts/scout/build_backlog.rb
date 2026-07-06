#!/usr/bin/env ruby
# =============================================================================
# build_backlog.rb — turn content-scout topic proposals into backlog entries
# -----------------------------------------------------------------------------
# The scout reads a sister site (it-journey.dev) and writes topic PROPOSALS to
# _data/scout/ideas.jsonl. This script is the mechanical half: it validates each
# proposal (Scout.normalize — drops anything with no source_url), dedups it three
# ways, assigns the next free SRC-### id, and APPENDS on-voice `status: todo`
# entries to _data/backlog.yml — the exact list the content-factory /
# grow-lifehacker already pick from. The loop closes: the scout notices
# it-journey covers Kubernetes contexts and lifehacker has no k8s hack; that
# becomes a backlog item (carrying the source URL); the factory writes it and a
# human (or auto-merge) ships it.
#
# THREE dedup nets, so a topic never lands twice:
#   1. fingerprint already in the backlog (re-running never re-adds a topic),
#   2. a near-duplicate TITLE already in the backlog (even a human-written one),
#   3. a near-duplicate title already PUBLISHED under pages/ (already covered).
#
# DRY-RUN BY DEFAULT (prints what it would add). Pass --apply to write the file.
# --max-add caps how many ideas land per run (default 3 — scout is backfill, not
# a firehose; a starved lane gets topped up, it never floods).
#
#   ruby scripts/scout/build_backlog.rb [--apply] [--max-add N]
#
# Stdlib only; we render YAML by hand (append-only) so we never reflow or reorder
# the human-curated entries above. No endless-method defs.
# =============================================================================
require_relative '_lib'

APPLY   = ARGV.include?('--apply')
MAX_ADD = (ARGV[ARGV.index('--max-add') + 1].to_i if ARGV.include?('--max-add')) || 3

unless File.exist?(Scout::IDEAS)
  puts "[build_backlog] no proposals at #{LH.rel(Scout::IDEAS)} — nothing to add."
  exit 0
end

raw = LH.read(Scout::IDEAS).each_line.map { |l| JSON.parse(l) rescue nil }.compact
proposals = Scout.dedup(raw.map { |o| Scout.normalize(o) }.compact)

doc   = LH.yload(LH.read(Scout::BACKLOG)) || {}
items = doc['backlog'] || []

known_fps       = Scout.known_fingerprints(items)
known_titles    = Scout.known_title_tokens(items)
published_titles = Scout.published_title_tokens

dropped = Hash.new(0)
to_add  = []
proposals.each do |f|
  break if to_add.size >= MAX_ADD
  tok = Scout.title_token(f['title'])
  if known_fps.include?(f['fingerprint'])
    dropped[:fingerprint] += 1; next
  end
  if known_titles.include?(tok)
    dropped[:backlog_title] += 1; next
  end
  if published_titles.include?(tok)
    dropped[:published] += 1; next
  end
  e = Scout.backlog_entry(f)
  e['id'] = Scout.next_src_id(items + to_add)
  to_add << e
  known_fps << f['fingerprint']
  known_titles << tok
end

skipped = proposals.size - to_add.size
puts "[build_backlog] mode=#{APPLY ? 'APPLY' : 'dry-run'}  proposals=#{proposals.size}  new=#{to_add.size} (cap #{MAX_ADD})  skipped=#{skipped}"
unless dropped.empty?
  puts "  skipped: " + dropped.map { |k, v| "#{k}=#{v}" }.join('  ')
end
to_add.each { |e| puts "  + #{e['id']} (#{e['kind']}) #{e['title']}  <- #{e['source_url']}  [fp #{e['fingerprint']}]" }

if to_add.empty?
  puts "  nothing new to add."
  exit 0
end

block = "\n  # --- content-scout topic ideas (auto-appended; humans may edit/reprioritize) ---\n" +
        "  # Each carries the source it-journey.dev page it was inspired by; grow-lifehacker\n" +
        "  # links that page in the published piece. Default P3 — human items outrank these.\n" +
        to_add.map { |e| Scout.render(e) }.join("\n") + "\n"

if APPLY
  # Append inside the top-level `backlog:` list. The file ends with the last
  # entry; appending at EOF keeps it a valid sequence under `backlog:`.
  # .gitattributes marks backlog.yml merge=union, so parallel appends don't
  # hard-conflict (union keeps both) — but this script is serialized by the
  # workflow's concurrency group, so it never races itself.
  File.open(Scout::BACKLOG, 'a') { |io| io.write(block) }
  puts "  wrote #{to_add.size} entries to #{LH.rel(Scout::BACKLOG)}"
else
  puts "\n  WOULD APPEND:\n#{block}"
end
