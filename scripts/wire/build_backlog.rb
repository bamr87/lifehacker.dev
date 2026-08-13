#!/usr/bin/env ruby
# =============================================================================
# build_backlog.rb — turn wire-scout dispatch proposals into backlog entries
# -----------------------------------------------------------------------------
# The wire-scout reads the configured news sources (_data/wire/sources.yml) and
# writes dispatch PROPOSALS to _data/wire/ideas.jsonl. This script is the
# mechanical half: it validates each proposal (Wire.normalize — no source_url,
# no dispatch), dedups it three ways, assigns the next free WIRE-### id, and
# APPENDS `kind: wire, author: rhea, status: todo` entries to _data/backlog.yml
# — the exact list the content factory / grow-lifehacker already pick from.
#
# THREE dedup nets (same design as scripts/scout/build_backlog.rb):
#   1. fingerprint already in the backlog (re-running never re-adds a story),
#   2. a near-duplicate TITLE already in the backlog (even a human-written one),
#   3. a near-duplicate title already PUBLISHED on the wire (pages/_posts/wire/).
#
# DRY-RUN BY DEFAULT (prints what it would add). Pass --apply to write the file.
# --max-add caps how many stories land per run (default 3 — the wire is a desk,
# not a firehose; a slow news day is allowed to be slow).
#
#   ruby scripts/wire/build_backlog.rb [--apply] [--max-add N]
#
# Stdlib only; YAML rendered by hand (append-only) so the human-curated entries
# above are never reflowed or reordered. No endless-method defs.
# =============================================================================
require_relative '_lib'

APPLY   = ARGV.include?('--apply')
MAX_ADD = (ARGV[ARGV.index('--max-add') + 1].to_i if ARGV.include?('--max-add')) || 3

unless File.exist?(Wire::IDEAS)
  puts "[wire-backlog] no proposals at #{LH.rel(Wire::IDEAS)} — a slow news day."
  exit 0
end

raw = LH.read(Wire::IDEAS).each_line.map { |l| JSON.parse(l) rescue nil }.compact
proposals = Wire.dedup(raw.map { |o| Wire.normalize(o) }.compact)

doc   = LH.yload(LH.read(Wire::BACKLOG)) || {}
items = doc['backlog'] || []

known_fps        = Wire.known_fingerprints(items)
known_titles     = Wire.known_title_tokens(items)
published_titles = Wire.published_title_tokens

dropped = Hash.new(0)
to_add  = []
proposals.each do |f|
  break if to_add.size >= MAX_ADD
  tok = Wire.title_token(f['title'])
  if known_fps.include?(f['fingerprint'])
    dropped[:fingerprint] += 1; next
  end
  if known_titles.include?(tok)
    dropped[:backlog_title] += 1; next
  end
  if published_titles.include?(tok)
    dropped[:published] += 1; next
  end
  e = Wire.backlog_entry(f)
  e['id'] = Wire.next_wire_id(items + to_add)
  to_add << e
  known_fps << f['fingerprint']
  known_titles << tok
end

skipped = proposals.size - to_add.size
puts "[wire-backlog] mode=#{APPLY ? 'APPLY' : 'dry-run'}  proposals=#{proposals.size}  new=#{to_add.size} (cap #{MAX_ADD})  skipped=#{skipped}"
unless dropped.empty?
  puts '  skipped: ' + dropped.map { |k, v| "#{k}=#{v}" }.join('  ')
end
to_add.each { |e| puts "  + #{e['id']} #{e['title']}  <- #{e['source_url']}  [#{e['priority']}, fp #{e['fingerprint']}]" }

if to_add.empty?
  puts '  nothing new to add.'
  exit 0
end

block = "\n  # --- wire-scout dispatch ideas (auto-appended; humans may edit/reprioritize) ---\n" +
        "  # The model beat, crawled from _data/wire/sources.yml. Every idea pins the story\n" +
        "  # URL it was reported from; the press charter (identity.yml) binds the write-up.\n" +
        to_add.map { |e| Wire.render(e) }.join("\n") + "\n"

if APPLY
  # Append inside the top-level `backlog:` list — same append-only discipline as
  # the content-scout: never rewrite the curated entries above, and the backlog
  # merge driver conflicts on purpose if two branches mint the SAME id.
  File.open(Wire::BACKLOG, 'a') { |io| io.write(block) }
  puts "  wrote #{to_add.size} entries to #{LH.rel(Wire::BACKLOG)}"
else
  puts "\n  WOULD APPEND:\n#{block}"
end
