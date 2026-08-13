#!/usr/bin/env ruby
# =============================================================================
# lint_wire.rb — validate the wire desk's config (_data/wire/sources.yml)
# -----------------------------------------------------------------------------
# The wire-scout crawls whatever this file says, on the schedule it says — so a
# typo'd frequency or a misspelled key means a source silently never gets read.
# This check makes the config load-bearing: schema violations are errors that
# block the gate; suspicious-but-harmless shapes warn. It also sanity-parses
# _data/wire/ideas.jsonl, because a corrupt line is otherwise dropped silently
# by build_backlog.rb.
# Stdlib only. Run: ruby scripts/ci/lint_wire.rb
# =============================================================================
require 'json'
require_relative '_lib'

REL   = '_data/wire/sources.yml'
PATH  = File.join(LH::ROOT, '_data', 'wire', 'sources.yml')
IDEAS = File.join(LH::ROOT, '_data', 'wire', 'ideas.jsonl')

KNOWN_SOURCE_KEYS = %w[id name url type trust frequency weekday topics include exclude max_items enabled].freeze
TRUST = %w[primary reputable community rumor].freeze
TYPES = %w[html rss atom].freeze
DAYS  = %w[mon tue wed thu fri sat sun].freeze
FREQS = %w[daily weekdays weekly].freeze

findings = []
err = ->(rule, evidence, file: REL) {
  findings << LH.finding(check_id: 'wire', severity: 'error', rule: rule, file: file, evidence: evidence)
}
wrn = ->(rule, evidence, file: REL) {
  findings << LH.finding(check_id: 'wire', severity: 'warning', rule: rule, file: file, evidence: evidence)
}

cfg = nil
if File.exist?(PATH)
  cfg = (LH.yload(LH.read(PATH)) rescue nil)
  err.call('unparseable-config', 'sources.yml is not valid YAML — the wire desk is flying blind') if cfg.nil?
else
  err.call('missing-config', 'the wire desk has no assignment editor — _data/wire/sources.yml must exist')
end

if cfg.is_a?(Hash)
  err.call('unknown-version', "version must be 1, got #{cfg['version'].inspect}") unless cfg['version'] == 1

  sources = cfg['sources']
  if !sources.is_a?(Array) || sources.empty?
    err.call('no-sources', 'sources: must be a non-empty list — a newsroom with no sources is a blog')
  else
    seen_ids = Hash.new(0)
    sources.each_with_index do |s, i|
      unless s.is_a?(Hash)
        err.call('bad-source', "sources[#{i}] is not a mapping")
        next
      end
      id = s['id'].to_s
      label = id.empty? ? "sources[#{i}]" : "`#{id}`"

      err.call('bad-id', "#{label}: id must be a lowercase slug ([a-z0-9-])") unless id =~ /\A[a-z0-9][a-z0-9-]*\z/
      seen_ids[id] += 1 unless id.empty?
      err.call('missing-name', "#{label}: name is required") if s['name'].to_s.strip.empty?
      unless s['url'].to_s =~ %r{\Ahttps://[^/\s]+\.[^/\s]+}
        err.call('bad-url', "#{label}: url must be https:// with a real host, got #{s['url'].inspect}")
      end
      err.call('bad-type', "#{label}: type must be one of #{TYPES.join('|')}, got #{s['type'].inspect}") if s.key?('type') && !TYPES.include?(s['type'].to_s)
      err.call('bad-trust', "#{label}: trust must be one of #{TRUST.join('|')}, got #{s['trust'].inspect}") if s.key?('trust') && !TRUST.include?(s['trust'].to_s)

      if s.key?('frequency')
        f = s['frequency']
        ok = FREQS.include?(f.to_s) || (f.is_a?(Array) && f.any? && f.all? { |d| DAYS.include?(d.to_s) })
        err.call('bad-frequency', "#{label}: frequency must be #{FREQS.join('|')} or a list of weekdays, got #{f.inspect}") unless ok
      end
      err.call('bad-weekday', "#{label}: weekday must be one of #{DAYS.join('|')}, got #{s['weekday'].inspect}") if s.key?('weekday') && !DAYS.include?(s['weekday'].to_s)
      err.call('bad-max-items', "#{label}: max_items must be 1..10, got #{s['max_items'].inspect}") if s.key?('max_items') && !(1..10).cover?(s['max_items'].to_i)

      # The norway trap: YAML 1.1 parses a bare `on:` key as the boolean true,
      # so a source configured with `on: tue` silently loses its weekday.
      if s.keys.include?(true)
        err.call('yaml-truthy-key', "#{label}: a bare `on:` key parses as boolean true in YAML — write `weekday: #{s[true]}` instead")
      end
      (s.keys.map(&:to_s) - KNOWN_SOURCE_KEYS - ['true']).each do |k|
        wrn.call('unknown-key', "#{label}: `#{k}` is not a recognized source field (typo?) — the planner ignores it")
      end
    end
    seen_ids.select { |_, n| n > 1 }.each_key do |id|
      err.call('duplicate-id', "source id `#{id}` appears #{seen_ids[id]}x — ids must be unique (they name run trails)")
    end
    if sources.all? { |s| s.is_a?(Hash) && s['enabled'] == false }
      wrn.call('all-sources-disabled', 'every source is enabled: false — the wire-scout will plan nothing')
    end
  end

  if (defaults = cfg['defaults']).is_a?(Hash)
    err.call('bad-default-trust', "defaults.trust must be one of #{TRUST.join('|')}") if defaults.key?('trust') && !TRUST.include?(defaults['trust'].to_s)
    err.call('bad-default-frequency', "defaults.frequency must be #{FREQS.join('|')} or a weekday list") if defaults.key?('frequency') && !(FREQS.include?(defaults['frequency'].to_s) || (defaults['frequency'].is_a?(Array) && defaults['frequency'].all? { |d| DAYS.include?(d.to_s) }))
  end

  if (caps = cfg['caps']).is_a?(Hash)
    err.call('bad-recency', "caps.recency_days must be 1..90, got #{caps['recency_days'].inspect}") if caps.key?('recency_days') && !(1..90).cover?(caps['recency_days'].to_i)
    err.call('bad-max-proposals', "caps.max_proposals_per_run must be 1..10, got #{caps['max_proposals_per_run'].inspect}") if caps.key?('max_proposals_per_run') && !(1..10).cover?(caps['max_proposals_per_run'].to_i)
    err.call('bad-wander', "caps.wander_slots must be 0..5, got #{caps['wander_slots'].inspect}") if caps.key?('wander_slots') && !(0..5).cover?(caps['wander_slots'].to_i)
  end
end

# ideas.jsonl: every non-empty line must parse as JSON (a corrupt line would be
# dropped silently downstream — surface it here instead).
if File.exist?(IDEAS)
  LH.read(IDEAS).each_line.with_index(1) do |line, ln|
    next if line.strip.empty?
    begin
      JSON.parse(line)
    rescue StandardError
      findings << LH.finding(check_id: 'wire', severity: 'warning', rule: 'bad-ideas-line',
                             file: '_data/wire/ideas.jsonl', line: ln,
                             evidence: 'line is not valid JSON — build_backlog.rb will drop it silently')
    end
  end
end

errs = LH.write('wire', findings)
exit(errs.zero? ? 0 : 1)
