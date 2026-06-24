#!/usr/bin/env ruby
# =============================================================================
# build_backlog.rb — turn explorer "gap/idea" findings into backlog entries
# -----------------------------------------------------------------------------
# A MISSING thing is not a bug — it is a proposal. Instead of filing an issue
# (which would flood the triage queue with wishlist noise), the explorer's
# content-gap / idea findings become `status: todo` entries in _data/backlog.yml,
# the exact list grow-lifehacker already reads. The loop closes itself: the
# explorer notices "expert readers have nowhere to go after the git-alias hack",
# that becomes a backlog item, grow-lifehacker writes it, and a human merges it.
#
# Dedup is by FINGERPRINT, not by title: every explorer entry carries the
# finding's `fingerprint` in a comment-free YAML field, so re-running never adds
# a second copy of the same gap. New ids are EXP-### (next free), so they never
# collide with the human HACK-/TOOL-/DOC- series.
#
# DRY-RUN BY DEFAULT (prints what it would add). Pass --apply to write the file.
# A --max-add cap bounds how many ideas land per run.
#
#   ruby scripts/explorer/build_backlog.rb [--apply] [--max-add N]
#
# Stdlib only; we render YAML by hand (append-only) so we never reflow or reorder
# the human-curated entries above. No endless-method defs.
# =============================================================================
require_relative '_lib'

APPLY   = ARGV.include?('--apply')
MAX_ADD = (ARGV[ARGV.index('--max-add') + 1].to_i if ARGV.include?('--max-add')) || 5
BACKLOG = File.join(Explorer::ROOT, '_data', 'backlog.yml')

abort "no findings at #{Explorer::FINDINGS}" unless File.exist?(Explorer::FINDINGS)
raw      = LH.read(Explorer::FINDINGS).each_line.map { |l| JSON.parse(l) rescue nil }.compact
findings = Explorer.dedup(raw.map { |o| Explorer.normalize(o) })
ideas    = Explorer.backlog_ideas(findings)

doc = LH.yload(LH.read(BACKLOG)) || {}
items = doc['backlog'] || []

# Every fingerprint already represented (explorer-sourced entries carry it).
known_fps = items.map { |i| i['fingerprint'] }.compact.to_set rescue
            items.map { |i| i['fingerprint'] }.compact

def next_exp_id(items)
  used = items.map { |i| i['id'].to_s }.grep(/\AEXP-(\d+)\z/) { $1.to_i }
  n = (used.max || 0) + 1
  format('EXP-%03d', n)
end

require 'set'
known = items.map { |i| i['fingerprint'] }.compact.to_set
to_add = []
ideas.each do |f|
  next if known.include?(f['fingerprint'])
  break if to_add.size >= MAX_ADD
  e = Explorer.backlog_entry(f)
  e['id'] = next_exp_id(items + to_add)
  to_add << e
  known << f['fingerprint']
end

# Render new entries as YAML we APPEND (never rewrite the curated block above).
def render(e)
  lines = []
  lines << "  - id: #{e['id']}"
  lines << "    kind: #{e['kind']}"
  lines << "    title: #{e['title'].inspect}"
  lines << "    brief: #{e['brief'].to_s.empty? ? '"(from a live-site observation)"' : e['brief'].inspect}"
  lines << "    voice: #{e['voice']}"
  lines << "    priority: #{e['priority']}"
  lines << "    status: #{e['status']}"
  lines << "    source: #{e['source']}"
  lines << "    fingerprint: #{e['fingerprint']}"
  lines << "    seen_on: #{e['seen_on']}"
  lines << "    personas: [#{Array(e['personas']).join(', ')}]"
  lines.join("\n")
end

puts "[build_backlog] mode=#{APPLY ? 'APPLY' : 'dry-run'}  gap_findings=#{ideas.size}  new=#{to_add.size} (cap #{MAX_ADD})  already_known=#{ideas.size - to_add.size}"
to_add.each { |e| puts "  + #{e['id']} (#{e['kind']}) #{e['title']}  [fp #{e['fingerprint']}]" }

if to_add.empty?
  puts "  nothing new to add."
  exit 0
end

block = "\n  # --- site-explorer findings (auto-appended; humans may edit/repriotize) ---\n" +
        to_add.map { |e| render(e) }.join("\n") + "\n"

if APPLY
  # Append inside the top-level `backlog:` list. The file ends with the last
  # entry; appending at EOF keeps it a valid sequence under `backlog:`.
  File.open(BACKLOG, 'a') { |io| io.write(block) }
  puts "  wrote #{to_add.size} entries to #{LH.rel(BACKLOG)}"
else
  puts "\n  WOULD APPEND:\n#{block}"
end
