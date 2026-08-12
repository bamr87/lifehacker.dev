#!/usr/bin/env ruby
# =============================================================================
# merge_backlog.rb — item-aware 3-way merge driver for `_data/backlog.yml`
# -----------------------------------------------------------------------------
# WHY THIS EXISTS. `_data/backlog.yml` used to be marked `merge=union`, because
# every parallel content run appends a fresh item to the end of the same file
# and two runs branched off the same `main` reliably collide on those tail lines.
# Union resolves an append/append collision by keeping BOTH sides' lines, which
# is right when the two appends are genuinely disjoint blocks of text.
#
# THEY ARE NOT ALWAYS DISJOINT. Union is LINE-based, and two backlog items
# written by the same persona share byte-identical middle lines:
#
#     voice: threat-model-everything
#     author: cass
#     priority: P2
#     status: done
#
# The diff aligns those four lines as common context, which splits one clean
# append/append hunk into several small ones — and the union of THOSE interleaves
# the two items instead of stacking them. Observed on PR #453: the incoming
# item lost its `voice/author/priority/status` and its `published:` line was
# stranded inside the PREVIOUS item's mapping, producing a duplicate `published`
# key. Psych keeps the last duplicate silently, so the file still parses and the
# damage only surfaces in `lint_artifacts.rb`. Union also happily stacks two
# items that claim the SAME id, which is a collision, not a merge.
#
# WHAT THIS DOES INSTEAD. Segment each version into the header plus one atomic
# BLOCK per backlog item (an item's `- id:` line, its keys, and the rationale
# comment block immediately above it), then 3-way merge at the BLOCK level keyed
# by item id. Blocks are raw line arrays, never re-serialized YAML, so comments,
# ordering, and formatting survive byte-for-byte. Because a block is atomic, two
# items can never be spliced into each other no matter how many lines they share.
#
# A genuine collision — both sides adding the SAME id with different content, or
# both editing one item differently — exits non-zero, which git reports as a
# conflict. `auto-update.yml` then leaves the branch untouched and labels the PR
# `needs-human`, rather than pushing a silently-mangled file.
#
# Git merge-driver contract: `%O %A %B` (base, ours, theirs). The result is
# written to %A. Exit 0 = merged, non-zero = conflict.
# Registered by `.github/workflows/auto-update.yml`; see `.gitattributes`.
# Stdlib only. Run: ruby scripts/ci/merge_backlog.rb <base> <ours> <theirs>
# =============================================================================

ITEM_RE = /\A\s*-\s+id:\s*(\S+)/.freeze
# A lead-in is the run of COMMENT lines directly above an item — the rationale
# block agents write when they add it. It travels with that item.
#
# The walk-back deliberately stops at a blank line rather than absorbing it. A
# blank absorbed into the NEXT item's lead-in would leave the PREVIOUS item's
# block looking edited (it lost its trailing blank) on the side that appended,
# and every append would then read as an edit-vs-edit conflict on the last item.
# Blank lines stay with the block above them; `norm` below makes the comparison
# insensitive to them so an append that adds a separator is still a clean append.
LEADIN_RE = /\A\s*#/.freeze

# Block identity for 3-way comparison, ignoring trailing blank lines. Output
# always uses the chosen side's RAW lines, so an untouched file round-trips
# byte-for-byte and a merge never reflows whitespace it wasn't asked to touch.
def norm(lines)
  out = lines.dup
  out.pop while out.last && out.last.strip.empty?
  out
end

# Split `lines` into [header, blocks]. `header` is everything before the first
# item's lead-in; each block is { id:, lines: } covering the item's lead-in
# comments through the line before the next item's lead-in (EOF for the last).
def segment(lines)
  item_at = []
  lines.each_with_index { |line, i| item_at << i if line =~ ITEM_RE }
  return [lines, []] if item_at.empty?

  starts = item_at.each_with_index.map do |idx, k|
    j = idx
    j -= 1 while j.positive? && lines[j - 1] =~ LEADIN_RE
    # A lead-in can never reach back past the previous item's own line.
    prev_item = k.positive? ? item_at[k - 1] : -1
    [j, prev_item + 1].max
  end

  blocks = item_at.each_with_index.map do |idx, k|
    finish = k + 1 < starts.length ? starts[k + 1] : lines.length
    id = lines[idx][ITEM_RE, 1].to_s.gsub(/\A["']|["']\z/, '')
    { id: id, lines: lines[starts[k]...finish] }
  end

  [lines[0...starts[0]], blocks]
end

def index_by_id(blocks, side)
  by_id = {}
  blocks.each do |b|
    abort("[merge_backlog] #{side} already contains duplicate id `#{b[:id]}` — refusing to merge a file that is already broken") if by_id.key?(b[:id])
    by_id[b[:id]] = b[:lines]
  end
  by_id
end

def conflict!(reason)
  warn "[merge_backlog] CONFLICT: #{reason}"
  exit 1
end

base_path, ours_path, theirs_path = ARGV
abort('usage: merge_backlog.rb <base> <ours> <theirs>') unless base_path && ours_path && theirs_path

# Read as UTF-8 explicitly: the backlog is full of em-dashes and Ruby's default
# US-ASCII external encoding would make the regex matches below raise (same
# reason `_lib.rb`'s `LH.read` pins it). Deliberately dependency-free otherwise —
# a merge driver runs mid-`git merge` and must not rely on the rest of the tree.
def read_lines(path)
  File.read(path, encoding: 'UTF-8').lines
end

base_lines   = read_lines(base_path)
ours_lines   = read_lines(ours_path)
theirs_lines = read_lines(theirs_path)

base_header,   base_blocks   = segment(base_lines)
ours_header,   ours_blocks   = segment(ours_lines)
theirs_header, theirs_blocks = segment(theirs_lines)

base_by   = index_by_id(base_blocks,   'base')
ours_by   = index_by_id(ours_blocks,   'ours')
theirs_by = index_by_id(theirs_blocks, 'theirs')

# The header is the `backlog:` key and the file's preamble — rarely touched, and
# a real 3-way edit of it is a human's call, not this driver's.
header =
  if    ours_header == base_header   then theirs_header
  elsif theirs_header == base_header then ours_header
  elsif ours_header == theirs_header then ours_header
  else  conflict!('both sides edited the file header differently')
  end

merged = []

# Existing items keep base's ordering; a status flip or a `published:` stamp
# lands on exactly one side and is taken verbatim.
base_blocks.each do |b|
  id = b[:id]
  o  = ours_by[id]
  t  = theirs_by[id]

  if o.nil? && t.nil?
    next # removed by both
  elsif o.nil?
    conflict!("item `#{id}` was removed by ours but modified by theirs") unless norm(t) == norm(b[:lines])
    next
  elsif t.nil?
    conflict!("item `#{id}` was removed by theirs but modified by ours") unless norm(o) == norm(b[:lines])
    next
  end

  merged << if    norm(o) == norm(b[:lines]) then t
            elsif norm(t) == norm(b[:lines]) then o
            elsif norm(o) == norm(t)         then o
            else  conflict!("item `#{id}` was edited differently on both sides")
            end
end

# Then each side's fresh appends, ours before theirs, each as one atomic block.
added_ours   = ours_blocks.reject   { |b| base_by.key?(b[:id]) }
added_theirs = theirs_blocks.reject { |b| base_by.key?(b[:id]) }

added_ours.each { |b| merged << b[:lines] }
added_theirs.each do |b|
  if (mine = ours_by[b[:id]]) && !base_by.key?(b[:id])
    # Both sides allocated the SAME new id. Identical content is the same item
    # arriving twice (already emitted above); different content is the id
    # collision that `lint_artifacts.rb` catches downstream — stop here instead.
    next if norm(mine) == norm(b[:lines])

    conflict!("both sides added a DIFFERENT item with id `#{b[:id]}` — the id " \
              'allocator handed one id to two branches; renumber one of them')
  end
  merged << b[:lines]
end

File.write(ours_path, (header + merged.flatten).join, encoding: 'UTF-8')
