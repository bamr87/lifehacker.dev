#!/usr/bin/env ruby
# =============================================================================
# .claude/hooks/retrospective-enqueue.rb — the SessionEnd retrospective hook
# -----------------------------------------------------------------------------
# Fires when a Claude Code session ends (wired in .claude/settings.json). It does
# ONE cheap, non-blocking thing: record the just-finished thread as a retrospective
# candidate, so the session-retrospective agent can later read the transcript and
# publish what the thread learned (see docs/RETROSPECTIVE-HOOK.md).
#
# It does NO AI work and NEVER fails a session: every error is swallowed and it
# always exits 0. It dedupes by session_id (one entry per thread, however many
# times SessionEnd fires). The queue is local + gitignored
# (.claude/retrospectives/queue.jsonl) — ephemeral state, not site content; the
# durable record is _data/retrospectives.yml, written only when a thread is
# actually published.
# =============================================================================
require 'json'
require 'time'
require 'fileutils'

begin
  raw = $stdin.read
  payload = raw.to_s.strip.empty? ? {} : (JSON.parse(raw) rescue {})

  sid        = payload['session_id'].to_s
  transcript = payload['transcript_path'].to_s
  cwd        = payload['cwd'].to_s
  reason     = payload['reason'].to_s
  # Nothing actionable without a session id + a transcript to read back.
  exit 0 if sid.empty? || transcript.empty?

  root  = ENV['CLAUDE_PROJECT_DIR'].to_s.empty? ? Dir.pwd : ENV['CLAUDE_PROJECT_DIR']
  qdir  = File.join(root, '.claude', 'retrospectives')
  qfile = File.join(qdir, 'queue.jsonl')
  FileUtils.mkdir_p(qdir)

  # Dedupe: one entry per thread, no matter how many times SessionEnd fires.
  if File.exist?(qfile)
    seen = File.foreach(qfile).any? { |ln| (JSON.parse(ln)['session_id'] == sid rescue false) }
    exit 0 if seen
  end

  entry = {
    'session_id'      => sid,
    'transcript_path' => transcript,
    'cwd'             => cwd,
    'reason'          => reason,
    'queued_at'       => Time.now.utc.iso8601,
    'status'          => 'pending'
  }
  File.open(qfile, 'a') { |io| io.puts(JSON.generate(entry)) }
rescue => e
  # A retrospective hook must never get in the way of ending a session.
  (warn "[retrospective-enqueue] skipped: #{e.class}: #{e.message}") rescue nil
ensure
  exit 0
end
