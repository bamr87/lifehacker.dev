#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# reillustrate.rb — the banner backfill (ADR-0008 Phase 4).
# =============================================================================
# Works the banner backlog worst-first, a few per day, OUTSIDE the grow tick's
# budget. Two modes:
#
#   --plan   read _reports/banners-baseline.json (scripts/audit-banners.rb) and
#            the hub ledger telemetry/banners.jsonl, and print the next
#            `preview.backfill.per_run` banners to redo, grouped by member, as
#            JSON [{repo, articles: [...]}]. A banner counts as DONE once the
#            loop has re-illustrated its article after the baseline (any
#            ledger record for it, newer than the baseline) — so the backlog
#            only shrinks, and the job stops itself when it is empty.
#   --run    in a member checkout, run the engine's illustration loop on the
#            given articles (`--force`, policy args + the member's era
#            palette), appending banner/v1 records to telemetry/banners.jsonl.
#            reillustrate.yml calls this; it never commits or pushes itself.
#
# Worst first: lint errors (dangling refs, rasters, unparseable) → a critic
# score at or below `preview.backfill.max_score` or a `local` fallback → banners
# that fail strict lint only on <text> (the loop's text→paths fixes those, so
# they are cheapest and come last).
#
#   ruby scripts/reillustrate.rb --plan
#   ruby scripts/reillustrate.rb --run --repo 2008 --checkout /tmp/2008 \
#        --articles _posts/x/a.md,_posts/y/b.md --telemetry /tmp/tick.jsonl
# Ruby stdlib only, 2.6-compatible.

require 'json'
require 'yaml'
require 'optparse'
require 'time'
require_relative 'lib/banners'

ROOT = File.expand_path('..', __dir__)
MAX_ATTEMPTS = 3
opts = {
  baseline: File.join(ROOT, '_reports', 'banners-baseline.json'),
  ledger: File.join(ROOT, 'telemetry', 'banners.jsonl'),
  articles: []
}
OptionParser.new do |o|
  o.banner = 'usage: ruby scripts/reillustrate.rb (--plan | --run --repo R --checkout DIR --articles A,B) [options]'
  o.on('--plan', 'print the next backfill batch as JSON') { opts[:mode] = :plan }
  o.on('--run', 'illustrate --articles in --checkout') { opts[:mode] = :run }
  o.on('--per-run N', Integer, 'batch size (default policy preview.backfill.per_run)') { |v| opts[:per_run] = v }
  o.on('--baseline FILE', 'audit JSON (default _reports/banners-baseline.json)') { |v| opts[:baseline] = v }
  o.on('--ledger FILE', 'banner ledger (default telemetry/banners.jsonl)') { |v| opts[:ledger] = v }
  o.on('--repo NAME', 'member repo (--run)') { |v| opts[:repo] = v }
  o.on('--checkout DIR', 'member checkout (--run)') { |v| opts[:checkout] = v }
  o.on('--articles LIST', 'comma-separated article paths relative to the checkout (--run)') { |v| opts[:articles] = v.split(',').map(&:strip).reject(&:empty?) }
  o.on('--engine PATH', 'preview_generator.py (default: $ZER0_IMAGE_ENGINE, then the gem)') { |v| opts[:engine] = v }
  o.on('--telemetry FILE', 'banner/v1 records for this run (--run)') { |v| opts[:telemetry] = v }
end.parse!

policy = (YAML.load_file(File.join(ROOT, 'lineage', 'policy.yml')) rescue {}) || {}
preview = policy['preview'] || {}
backfill = preview['backfill'] || {}
per_run = (opts[:per_run] || backfill['per_run'] || 6).to_i
max_score = (backfill['max_score'] || 6).to_f

# ---- plan --------------------------------------------------------------------
def severity(lint, critic, fallback, max_score)
  lint ||= {}
  return 0 if lint['fatal'] || !Array(lint['errors']).empty?
  return 1 if fallback || (critic && critic['overall'].to_f <= max_score)
  return 2 if lint.key?('clean') && !lint['clean']

  nil
end

if opts[:mode] == :plan
  baseline = File.file?(opts[:baseline]) ? (JSON.parse(File.read(opts[:baseline])) rescue {}) : {}
  baseline_at = (Time.parse(baseline['generated'].to_s) rescue Time.at(0))
  ledger = Banners.load_records(opts[:ledger])

  candidates = {}
  Array(baseline['banners']).each do |b|
    next unless b['article']

    sev = severity(b['lint'], b['critic'], nil, max_score)
    next unless sev

    candidates["#{b['repo']}:#{b['article']}"] = {
      'repo' => b['repo'], 'article' => b['article'], 'severity' => sev,
      'score' => b['critic'] ? b['critic']['overall'].to_f : nil, 'source' => 'baseline'
    }
  end
  # The live ledger. An article the loop has touched since the baseline is
  # done as far as the baseline is concerned. An article whose LATEST record is
  # a `local` fallback re-enters the queue — but only until it has been tried
  # MAX_ATTEMPTS times; after that it is a human's (the weekly watcher still
  # shows it), so the backfill can never spin on one stubborn banner.
  by_article = ledger.group_by { |r| "#{r['repo']}:#{r['article']}" }
  by_article.each do |key, recs|
    recs = recs.sort_by { |r| r['ts'].to_s }
    newer = recs.any? { |r| (Time.parse(r['ts'].to_s) rescue Time.at(0)) > baseline_at }
    candidates.delete(key) if newer
    latest = recs.last
    next unless latest['fallback'] && recs.length < MAX_ATTEMPTS

    candidates[key] = {
      'repo' => latest['repo'], 'article' => latest['article'],
      'severity' => severity(latest['lint'], latest['critic'], latest['fallback'], max_score) || 1,
      'score' => latest['critic'] && latest['critic']['overall'], 'source' => 'ledger'
    }
  end

  queue = candidates.values.sort_by { |c| [c['severity'], c['score'] || 99, c['repo'].to_s, c['article'].to_s] }
  batch = queue.first(per_run)
  plan = batch.group_by { |c| c['repo'] }.map { |repo, rows| { 'repo' => repo, 'articles' => rows.map { |r| r['article'] } } }
  warn "[reillustrate] backlog #{queue.length} (errors #{queue.count { |c| c['severity'].zero? }}, " \
       "low-score/fallback #{queue.count { |c| c['severity'] == 1 }}, text-only #{queue.count { |c| c['severity'] == 2 }}); " \
       "this batch #{batch.length}"
  warn '[reillustrate] backlog empty — the backfill is done (REILLUSTRATE_ENABLED can be turned off).' if queue.empty?
  puts JSON.generate(plan)
  exit 0
end

# ---- run ---------------------------------------------------------------------
if opts[:mode] == :run
  abort '[reillustrate] --run needs --repo, --checkout and --articles' if opts[:repo].to_s.empty? || opts[:checkout].to_s.empty? || opts[:articles].empty?
  engine = Banners.find_engine(opts[:engine])
  abort '[reillustrate] engine not found (gem install zer0-image-generator)' unless engine
  unless Banners.loop_engine?(engine)
    warn '[reillustrate] the installed engine predates the illustration loop (zer0-image-generator < 0.10) — nothing to do.'
    exit 0
  end
  args = Banners.engine_args(preview, member: opts[:repo])
  env = { 'IMAGE_STYLE_MODIFIERS' => preview['style_modifiers'].to_s }
  failed = 0
  skipped = 0
  opts[:articles].each do |article|
    unless File.file?(File.join(opts[:checkout], article))
      warn "[reillustrate] #{article}: not in the checkout (moved or deleted) — skipped"
      skipped += 1
      next
    end
    cmd = ['python3', engine, '-f', article, '--force', '--provider', 'auto', '--rasterizer', 'none'] + args
    cmd += ['--telemetry', opts[:telemetry]] if opts[:telemetry]
    ok = system(env, *cmd, chdir: opts[:checkout])
    failed += 1 unless ok
  end
  done = opts[:articles].length - failed - skipped
  warn "[reillustrate] #{opts[:repo]}: #{done} re-illustrated, #{failed} failed, #{skipped} skipped"
  exit(failed.zero? ? 0 : 1)
end

warn 'usage: ruby scripts/reillustrate.rb --plan | --run (see --help)'
exit 2
