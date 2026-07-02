#!/usr/bin/env ruby
# =============================================================================
# scripts/devops/verify_improvements.rb — did the loop's last changes work?
# -----------------------------------------------------------------------------
# The deterministic half of the loop's memory. loop_metrics.rb measures the
# window; this script reads the improvements ledger (_data/fleet/improvements.yml)
# and, for every `pending` entry, compares the entry's `metric` (a dotted path
# into the loop-metrics JSON) against its recorded `baseline`:
#
#   moved the better way  -> suggest `verified`
#   moved the worse way   -> suggest `regressed` (fix/revert is the next run's
#                            top candidate)
#   unchanged / no data   -> stays `pending` (inconclusive)
#
# READ-ONLY: it prints verdicts; the loop-tuner agent flips the statuses in its
# PR, so ledger changes reach main through the same human gate as everything.
#
#   ruby scripts/devops/verify_improvements.rb --metrics test-results/loop-metrics.json
#   ruby scripts/devops/verify_improvements.rb --json
#   ruby scripts/devops/verify_improvements.rb --self-test
#
# Exit codes: 0 on report (even with regressions — the report IS the product),
# 1 on a malformed ledger or failed self-test, so CI catches schema rot early.
# =============================================================================
require 'json'
require 'yaml'
require 'date'

module VerifyImprovements
  module_function

  LEDGER  = File.expand_path('../../_data/fleet/improvements.yml', __dir__)
  STATUSES = %w[pending verified regressed abandoned].freeze
  REQUIRED = %w[id date metric baseline direction status note].freeze

  def dig_path(h, path)
    path.split('.').reduce(h) { |acc, k| acc.is_a?(Hash) ? acc[k] : nil }
  end

  # Ledger entries carry unquoted YAML dates (the documented schema), so Date
  # must be permitted. -> Array of entries, or nil if unreadable / wrong shape.
  def load_entries(path)
    doc = YAML.safe_load(File.read(path), permitted_classes: [Date, Time]) || {}
    entries = doc['improvements']
    entries.is_a?(Array) ? entries : nil
  rescue Errno::ENOENT, Psych::Exception
    nil
  end

  # -> [errors] ; empty means the ledger is well-formed. Malformed entries are
  # reported as schema errors, never raised — the audit runs this.
  def validate(entries)
    errs = []
    seen = {}
    entries.each_with_index do |e, i|
      unless e.is_a?(Hash)
        errs << "entry #{i}: not a map (got #{e.class})"
        next
      end
      REQUIRED.each { |k| errs << "entry #{i} (#{e['id'] || '?'}): missing `#{k}`" unless e.key?(k) }
      errs << "entry #{i} (#{e['id']}): duplicate id" if e['id'] && seen[e['id']]
      seen[e['id']] = true
      errs << "entry #{i} (#{e['id']}): status `#{e['status']}` not in #{STATUSES.join('|')}" unless STATUSES.include?(e['status'].to_s)
      errs << "entry #{i} (#{e['id']}): direction `#{e['direction']}` not down|up" unless %w[down up].include?(e['direction'].to_s)
      errs << "entry #{i} (#{e['id']}): baseline is not a number" unless e['baseline'].is_a?(Numeric)
    end
    errs
  end

  # -> { 'id', 'metric', 'baseline', 'now', 'verdict', 'detail' }
  def verdict(entry, metrics)
    now = dig_path(metrics, entry['metric'].to_s)
    base = entry['baseline']
    v, detail =
      if !now.is_a?(Numeric)
        ['pending', 'metric absent in the current window — keep pending']
      else
        up = entry['direction'].to_s == 'up'
        if (up && now > base) || (!up && now < base)
          ['verified', "moved #{base} -> #{now} (#{entry['direction']} is better)"]
        elsif now == base
          ['pending', "unchanged at #{base} — keep pending"]
        else
          ['regressed', "moved #{base} -> #{now}, against direction `#{entry['direction']}`"]
        end
      end
    { 'id' => entry['id'], 'metric' => entry['metric'], 'baseline' => base,
      'now' => now, 'verdict' => v, 'detail' => detail }
  end

  def report(entries, metrics)
    pending = entries.select { |e| e['status'].to_s == 'pending' }
    { 'pending' => pending.size,
      'verdicts' => pending.map { |e| verdict(e, metrics) },
      'counts' => entries.group_by { |e| e['status'].to_s }.transform_values(&:size) }
  end

  def render_markdown(rep)
    o = +"## Improvements-ledger verification\n\n"
    o << "Ledger: #{rep['counts'].map { |k, v| "#{v} #{k}" }.join(' · ')}\n\n" unless rep['counts'].empty?
    if rep['verdicts'].empty?
      o << "No `pending` entries — nothing to verify this run.\n"
    else
      o << "| id | metric | baseline | now | verdict |\n|---|---|---|---|---|\n"
      rep['verdicts'].each do |v|
        o << "| #{v['id']} | `#{v['metric']}` | #{v['baseline']} | #{v['now'] || '—'} | **#{v['verdict']}** — #{v['detail']} |\n"
      end
      o << "\nFlip each entry's `status` accordingly in the loop-tuner PR; a `regressed` entry is the run's top candidate.\n"
    end
    o
  end

  def self_test
    metrics = { 'runs' => { 'fail_rate' => 10.0, 'slowest_median_sec' => 200 },
                'content_prs' => { 'escalation_rate' => 20.0 } }
    entries = [
      { 'id' => 'a', 'date' => 'd', 'metric' => 'runs.fail_rate', 'baseline' => 25.0,
        'direction' => 'down', 'status' => 'pending', 'note' => 'n' },          # 25 -> 10 down = verified
      { 'id' => 'b', 'date' => 'd', 'metric' => 'runs.slowest_median_sec', 'baseline' => 150,
        'direction' => 'down', 'status' => 'pending', 'note' => 'n' },          # 150 -> 200 down = regressed
      { 'id' => 'c', 'date' => 'd', 'metric' => 'content_prs.escalation_rate', 'baseline' => 20.0,
        'direction' => 'down', 'status' => 'pending', 'note' => 'n' },          # unchanged = pending
      { 'id' => 'e', 'date' => 'd', 'metric' => 'auto_fix.nope', 'baseline' => 1,
        'direction' => 'down', 'status' => 'pending', 'note' => 'n' },          # absent = pending
      { 'id' => 'f', 'date' => 'd', 'metric' => 'runs.fail_rate', 'baseline' => 5.0,
        'direction' => 'up', 'status' => 'verified', 'note' => 'n' }            # not pending: skipped
    ]
    rep = report(entries, metrics)
    got = rep['verdicts'].to_h { |v| [v['id'], v['verdict']] }
    checks = {
      'verified'      => [got['a'], 'verified'],
      'regressed'     => [got['b'], 'regressed'],
      'unchanged'     => [got['c'], 'pending'],
      'absent metric' => [got['e'], 'pending'],
      'skips settled' => [got.key?('f'), false],
      'pending count' => [rep['pending'], 4],
      'valid ledger'  => [validate(entries), []],
      'bad status'    => [validate([entries[0].merge('status' => 'nope')]).any? { |e| e.include?('status') }, true],
      'dup id'        => [validate([entries[0], entries[0]]).any? { |e| e.include?('duplicate') }, true],
      'bad baseline'  => [validate([entries[0].merge('baseline' => 'x')]).any? { |e| e.include?('baseline') }, true],
      'non-map entry' => [validate(['oops', entries[0]]).any? { |e| e.include?('not a map') }, true],
      'yaml Date ok'  => [validate([entries[0].merge('date' => Date.new(2026, 7, 1))]), []]
    }
    failed = checks.reject { |_, (g, w)| g == w }
    if failed.empty?
      puts "verify_improvements self-test: #{checks.size}/#{checks.size} PASS"
      true
    else
      failed.each { |name, (g, w)| puts "FAIL #{name}: got #{g.inspect}, want #{w.inspect}" }
      false
    end
  end
end

if $PROGRAM_NAME == __FILE__
  opts = { metrics: 'test-results/loop-metrics.json', ledger: VerifyImprovements::LEDGER, fmt: :markdown }
  i = 0
  while i < ARGV.size
    case ARGV[i]
    when '--self-test' then exit(VerifyImprovements.self_test ? 0 : 1)
    when '--metrics'   then opts[:metrics] = ARGV[i += 1]
    when '--ledger'    then opts[:ledger] = ARGV[i += 1]
    when '--json'      then opts[:fmt] = :json
    end
    i += 1
  end

  entries = VerifyImprovements.load_entries(opts[:ledger])
  abort "verify_improvements: cannot read ledger #{opts[:ledger]} (missing, unparseable, or `improvements` is not a list)" if entries.nil?
  errs = VerifyImprovements.validate(entries)
  unless errs.empty?
    errs.each { |e| warn "ledger error: #{e}" }
    abort "verify_improvements: #{errs.size} ledger schema error(s) — fix _data/fleet/improvements.yml"
  end
  metrics = File.exist?(opts[:metrics]) ? (JSON.parse(File.read(opts[:metrics])) rescue {}) : {}
  rep = VerifyImprovements.report(entries, metrics)
  puts(opts[:fmt] == :json ? JSON.pretty_generate(rep) : VerifyImprovements.render_markdown(rep))
end
