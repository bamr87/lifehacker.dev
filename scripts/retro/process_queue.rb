#!/usr/bin/env ruby
# =============================================================================
# scripts/retro/process_queue.rb — the retrospective queue reader (deterministic)
# -----------------------------------------------------------------------------
# The SessionEnd hook (.claude/hooks/retrospective-enqueue.rb) appends finished
# threads to .claude/retrospectives/queue.jsonl. This is the deterministic edge the
# session-retrospective agent leans on, so it never has to reason about queue
# bookkeeping:
#   ruby scripts/retro/process_queue.rb --list                  # pending threads (default)
#   ruby scripts/retro/process_queue.rb --next                  # one pending thread, as JSON
#   ruby scripts/retro/process_queue.rb --mark SID SLUG [TITLE] # record as published
#
# "Pending" = present in the queue, not yet in the published ledger
# (_data/retrospectives.yml). Stdlib only.
# =============================================================================
require 'json'
require 'yaml'
require 'time'

ROOT   = File.expand_path('../..', __dir__)
QUEUE  = File.join(ROOT, '.claude', 'retrospectives', 'queue.jsonl')
LEDGER = File.join(ROOT, '_data', 'retrospectives.yml')

# `to_yaml` only serializes the data, so a naive rewrite drops the ledger's
# self-documenting comment header. Preserve whatever leading comment block the
# file already has; fall back to this canonical header if it's missing.
LEDGER_HEADER = <<~HEADER
  # =============================================================================
  # _data/retrospectives.yml — the published-retrospectives ledger
  # -----------------------------------------------------------------------------
  # The durable index of which Claude Code threads have been written up as Field
  # Notes on the site. The SessionEnd hook queues every finished thread
  # (.claude/retrospectives/queue.jsonl — local + gitignored); when the
  # session-retrospective agent publishes one, it appends here via:
  #   ruby scripts/retro/process_queue.rb --mark <session_id> <post-slug> "<title>"
  # A thread listed here is considered done and is not re-proposed.
  # See docs/RETROSPECTIVE-HOOK.md.
  # =============================================================================
HEADER

# The leading comment block of the current ledger, or the canonical header if the
# file has none (e.g. it was previously rewritten without one).
def ledger_header
  if File.exist?(LEDGER)
    # Force UTF-8: the header comment contains an em-dash, and under a US-ASCII
    # default external encoding (Ruby 2.6 locally) the regex would raise on it.
    lead = File.read(LEDGER, encoding: 'UTF-8')[/\A(?:[ \t]*#[^\n]*\n|[ \t]*\n)*/].to_s
    return lead unless lead.strip.empty?
  end
  LEDGER_HEADER
end

# Write the ledger data back WITHOUT clobbering the comment header.
def write_ledger(data)
  File.write(LEDGER, ledger_header + data.to_yaml.sub(/\A---\n/, ''))
end

def queue_entries
  return [] unless File.exist?(QUEUE)
  File.foreach(QUEUE).map { |ln| JSON.parse(ln) rescue nil }.compact
end

def ledger
  return { 'retrospectives' => [] } unless File.exist?(LEDGER)
  (YAML.load_file(LEDGER) rescue nil) || { 'retrospectives' => [] }
end

def published_ids
  (ledger['retrospectives'] || []).map { |r| r['session_id'] }.compact
end

# Newest-first, deduped by session_id, minus anything already published.
def pending
  done = published_ids
  seen = {}
  queue_entries.each { |e| seen[e['session_id']] = e }
  seen.values.reject { |e| done.include?(e['session_id']) }
      .sort_by { |e| e['queued_at'].to_s }.reverse
end

cmd = ARGV[0] || '--list'
case cmd
when '--list'
  rows = pending
  if rows.empty?
    puts 'No pending retrospectives. (queue is clear)'
  else
    puts "#{rows.size} pending retrospective(s):"
    rows.each { |e| puts "  #{e['session_id'].to_s[0, 12]}  queued #{e['queued_at']}  #{e['transcript_path']}" }
  end
when '--next'
  e = pending.first
  if e.nil?
    warn 'No pending retrospectives.'
    exit 1
  end
  puts JSON.pretty_generate(e)
when '--mark'
  sid, slug, title = ARGV[1], ARGV[2], ARGV[3]
  abort 'usage: --mark SESSION_ID POST_SLUG [TITLE]' if sid.to_s.empty? || slug.to_s.empty?
  data = ledger
  data['retrospectives'] ||= []
  if data['retrospectives'].any? { |r| r['session_id'] == sid }
    warn "already in ledger: #{sid}"
    exit 0
  end
  data['retrospectives'] << {
    'session_id' => sid,
    'post'       => slug,
    'title'      => title.to_s,
    'published'  => Time.now.utc.strftime('%Y-%m-%d')
  }
  write_ledger(data)
  puts "recorded #{sid.to_s[0, 12]} → #{slug}"
else
  abort "unknown command: #{cmd} (use --list | --next | --mark)"
end
