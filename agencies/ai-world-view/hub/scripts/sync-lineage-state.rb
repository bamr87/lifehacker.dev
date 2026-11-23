#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# sync-lineage-state.rb
# =============================================================================
#
# Reads every member's CENTRALIZED seed (lineage/seeds/<name>.md — §8 is the
# Evolution Log, the authoritative tick clock) and writes the hub's lineage
# ledger:
#
#   _data/lineage.yml   — per-repo growth state for the /lineage/ dashboard
#                         and the orchestrator (status, tick clock, edges).
#
# This is the hub's eyes. Under the centralized model (ADR-0001) the seeds live
# in this repo, so the ledger refresh is hub-local; the GitHub API is used only
# to discover org members. It is deterministic for unchanged sources, so the
# scheduled orchestrate workflow only commits real changes. Companion to
# sync-hub-metadata.rb (which counts published content); this one tracks the
# lineage state that drives growth.
#
# Usage:
#   ruby scripts/sync-lineage-state.rb            # refresh _data/lineage.yml
#   ruby scripts/sync-lineage-state.rb --check    # validate output only (CI gate)
#   ruby scripts/sync-lineage-state.rb --dry-run  # print planned writes only
#   ruby scripts/sync-lineage-state.rb --json     # print the ledger as JSON, no write
#
# Requires the `gh` CLI (read scope).
# =============================================================================

require 'optparse'
require 'fileutils'
require 'base64'
require_relative 'lib/hub'

LINEAGE_FILE = File.join(Hub::ROOT, '_data', 'lineage.yml')

# Parse a YAML string, tolerant of the older macOS system Ruby (2.6) whose
# safe_load signature differs from 3.1+.
def parse_yaml(str)
  YAML.safe_load(str, permitted_classes: [Date, Time]) || {}
rescue ArgumentError
  YAML.safe_load(str) || {}
rescue StandardError
  {}
end


# ---------------------------------------------------------------------------
# seed.md §8 (Evolution Log) — the authoritative tick clock.
# Entry headers look like:
#   ### G1-T0 — 2026-06-13 — Genesis
#   ### G1-T1 — 2026-06-14 — Tick 1: Declaration, Wealth of Nations, ...
#   ### G1-T3 — 2026-06-14 — Tick 2: Thomas Paine, Captain Cook, ...
#   ### Replant — 2026-06-14
#   ### Distillation — 2026-06-15
# In the perpetual-growth model the log is never reset — it's a cumulative
# record of every content tick the repo has published.
# ---------------------------------------------------------------------------
ENTRY_RE = /^\#{2,3}\s+(.+?)\s*$/          # h2 or h3 — tolerate level drift in agent-written §8 entries
DATE_RE  = /(\d{4}-\d{2}-\d{2})/
TICK_RE  = /\bTick\s+\d+\s*:/i              # a real content tick ("… — Tick 3: …")
GEN_RE   = /\b(Genesis|Replant)\b/i         # generation boundaries

def parse_evolution_log(seed_text)
  return { ticks_logged: nil, total_entries: 0, generations: 0, last_date: nil, last_entry: nil } unless seed_text

  body    = seed_text[/^##\s*Section\s*8.*\z/m] || seed_text
  headers = body.scan(ENTRY_RE).flatten

  dated  = headers.map { |h| [h, h[DATE_RE, 1]] }.reject { |(_, d)| d.nil? }
  last_h, last_d = dated.last

  {
    ticks_logged:  headers.count { |h| h.match?(TICK_RE) }, # cumulative content ticks
    total_entries: headers.size,                            # all §8 entries (incl. safety-net/distill)
    generations:   headers.count { |h| h.match?(GEN_RE) },  # Genesis + Replant markers
    last_date:     last_d,
    last_entry:    last_h
  }
end

SUBJECT_RE = /^\s*subject:\s*["']?(.+?)["']?\s*$/

# The centralized seed for a member, or nil if there isn't one.
def read_seed(name)
  path = File.join(Hub::ROOT, 'lineage', 'seeds', "#{name}.md")
  File.exist?(path) ? File.read(path, encoding: 'utf-8') : nil
end

# Distill the lineage state the hub needs for one member. The seed now lives in
# the hub (lineage/seeds/<name>.md) rather than in the member repo; it carries
# the concept (§1) and the Evolution Log (§8 — the tick clock).
def inspect_lineage(org, name)
  seed = read_seed(name)
  return nil unless seed # not a lineage member

  subject = (seed[SUBJECT_RE, 1] || Hub.humanize(name)).strip
  log     = parse_evolution_log(seed)

  {
    'name'          => name,
    'repo'          => "#{org}/#{name}",
    'url'           => "https://github.com/#{org}/#{name}",
    'site_url'      => "https://#{org}.github.io/#{name}/",
    'subject'       => subject,
    'status'        => (log[:ticks_logged].to_i.positive? ? 'growing' : 'seeded'),
    'ticks_logged'  => log[:ticks_logged],
    'log_entries'   => log[:total_entries],
    'generations'   => log[:generations],
    'last_activity' => log[:last_date].to_s,
    'last_entry'    => log[:last_entry].to_s
  }
end

def build_ledger(org, repos)
  members = repos.map { |r| inspect_lineage(org, r) }.compact
  {
    'org'        => org,
    'totals'     => {
      'repos'  => members.size,
      'ticks'  => members.sum { |m| (m['ticks_logged'] || 0).to_i }
    },
    'members'    => members
  }
end

def write_generated_yaml(path, data, dry_run:)
  content = Hub::GENERATED_HEADER.gsub('sync-hub-metadata.sh', 'sync-lineage-state.rb') +
            data.to_yaml.sub(/\A---\n/, '')
  if File.exist?(path) && File.read(path, encoding: 'utf-8') == content
    Hub.log_info "unchanged: #{path.sub("#{Hub::ROOT}/", '')}"
  elsif dry_run
    Hub.log_info "DRY: would write #{path.sub("#{Hub::ROOT}/", '')}"
  else
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    Hub.log_info "wrote #{path.sub("#{Hub::ROOT}/", '')}"
  end
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

options = { mode: :sync, dry_run: false }
OptionParser.new do |o|
  o.banner = 'Usage: ruby scripts/sync-lineage-state.rb [--check|--dry-run|--json]'
  o.on('--check',   'validate generated ledger, no writes') { options[:mode] = :check }
  o.on('--dry-run', 'print planned actions without writing') { options[:dry_run] = true }
  o.on('--json',    'print the ledger as JSON and exit')      { options[:mode] = :json }
end.parse!

if options[:mode] == :check
  unless File.exist?(LINEAGE_FILE)
    Hub.log_error "missing #{LINEAGE_FILE.sub("#{Hub::ROOT}/", '')} — run sync-lineage-state.rb"
    exit 1
  end
  data = Hub.load_yaml(LINEAGE_FILE)
  errors = []
  errors << 'lineage ledger: missing members list' unless data.is_a?(Hash) && data['members'].is_a?(Array)
  (data['members'] || []).each do |m|
    errors << "member #{m['name']}: missing repo url" unless m['url'].to_s.start_with?('https://')
  end
  if errors.empty?
    Hub.log_info 'lineage ledger is valid'
    exit 0
  end
  errors.each { |e| Hub.log_error(e) }
  exit 1
end

cfg  = Hub.load_registry
org  = cfg['org']
excl = (cfg['exclude_repos'] || []) +
       [cfg.dig('pages', 'theme_repo').to_s.split('@').first.to_s.split('/').last].compact

repos = Hub.discover_repos(cfg).map { |r| r['name'] }.reject { |n| excl.include?(n) }
Hub.log_info "Reading lifecycle state for #{repos.size} repo(s) in #{org}: #{repos.join(', ')}"

ledger = build_ledger(org, repos)
ledger['members'].each do |m|
  Hub.log_info "  #{m['name']} (#{m['subject']}): #{m['status']} · #{m['ticks_logged']} content ticks · last #{m['last_activity']}"
end

if options[:mode] == :json
  require 'json'
  puts JSON.pretty_generate(ledger)
  exit 0
end

write_generated_yaml(LINEAGE_FILE, ledger, dry_run: options[:dry_run])
Hub.log_info 'Lineage state refresh complete'
