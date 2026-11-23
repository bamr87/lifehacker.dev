# frozen_string_literal: true

# =============================================================================
# scripts/lib/banners.rb — the banner side of ADR-0008, shared by every caller.
# =============================================================================
# One place for the three things the grow tick, the telemetry collector, the
# lineage ledger, the weekly watcher and the backfill must agree on:
#
#   - how lineage/policy.yml `preview:` becomes engine arguments (and which era
#     palette a member gets) — `engine_args`, `palette_for`;
#   - how banner/v1 telemetry records (the engine's `--telemetry` output) read
#     as quality — `load_records`, `stats`, `member_quality`;
#   - where the engine is and whether it has the loop — `find_engine`,
#     `loop_engine?`.
#
# Ruby stdlib only, 2.6-compatible (scripts/audit-banners.rb and
# scripts/reillustrate.rb also run on a laptop's system Ruby).

require 'json'
require 'open3'
require 'time'

module Banners
  # The engine flags that only exist from the illustration-loop release on.
  LOOP_FLAG = '--style-card'

  module_function

  # ---- policy → engine ---------------------------------------------------------

  # The era palette for a member: the first `palettes:` entry whose `members:`
  # names it, or whose `years: "1776-1778"` range contains it (members of a
  # year lineage are named by their year). nil when nothing matches — the
  # style card's own palette guidance applies then.
  def palette_for(member, palettes)
    Array(palettes).each do |entry|
      next unless entry.is_a?(Hash)

      tokens = Array(entry['tokens']).map(&:to_s)
      next if tokens.empty?
      return tokens if Array(entry['members']).map(&:to_s).include?(member.to_s)

      range = entry['years'].to_s[/\A\s*(\d+)\s*-\s*(\d+)\s*\z/] && [$1.to_i, $2.to_i]
      return tokens if range && member.to_s =~ /\A\d+\z/ && member.to_i.between?(*range)
    end
    nil
  end

  # Engine argv for the illustration loop from lineage/policy.yml `preview:`.
  # Targeting (`--changed`, `-f`), provider and output format are the caller's;
  # this is the art direction and the loop's knobs. `loop: false` returns the
  # subset a pre-loop engine (<= 0.9) accepts.
  def engine_args(preview, member: nil, loop: true)
    p = preview || {}
    args = []
    args += ['--model', p['model'].to_s] unless p['model'].to_s.empty?
    args += ['--style', p['style'].to_s] unless p['style'].to_s.empty?
    args += ['--output-dir', (p['output_dir'] || 'assets/images/previews').to_s]
    return args unless loop

    args += ['--style-card', p['style_card'].to_s] unless p['style_card'].to_s.empty?
    palette = palette_for(member, p['palettes'])
    args += ['--palette', palette.join(',')] if palette
    args += ['--rounds', Integer(p['rounds']).to_s] unless p['rounds'].nil?
    args += ['--min-score', Float(p['min_score']).to_s] unless p['min_score'].nil?
    unless p['require_thumbnail'].nil?
      args << (p['require_thumbnail'] ? '--require-thumbnail' : '--no-require-thumbnail')
    end
    args += ['--svg-text', p['text'].to_s] unless p['text'].to_s.empty?
    args += ['--look-rasterizer', p['look_rasterizer'].to_s] unless p['look_rasterizer'].to_s.empty?
    args += ['--budget-usd', Float(p['cost_cap_usd_per_tick']).to_s] unless p['cost_cap_usd_per_tick'].nil?
    args
  end

  # ---- engine ------------------------------------------------------------------

  def find_engine(explicit = nil)
    return explicit if explicit && File.file?(explicit)

    env = ENV['ZER0_IMAGE_ENGINE']
    return env if env && File.file?(env)

    out, _err, status = Open3.capture3('gem', 'contents', 'zer0-image-generator')
    return nil unless status.success?

    out.lines.map(&:strip).find { |l| l.end_with?('preview_generator.py') }
  rescue SystemCallError
    nil
  end

  def loop_engine?(engine)
    out, _err, _status = Open3.capture3('python3', engine, '--help')
    out.include?(LOOP_FLAG)
  rescue SystemCallError
    false
  end

  # ---- telemetry ---------------------------------------------------------------

  # banner/v1 records from a JSONL file; malformed lines are skipped, never fatal.
  def load_records(path)
    return [] unless path && File.file?(path)

    File.foreach(path).map do |line|
      begin
        rec = JSON.parse(line)
        rec.is_a?(Hash) && rec['schema'].to_s.start_with?('banner/') ? rec : nil
      rescue JSON::ParserError
        nil
      end
    end.compact
  end

  def round1(value)
    value.nil? ? nil : value.round(1)
  end

  # Quality of a set of committed banners. `committed_clean` counts a `local`
  # fallback as clean — that art is strict-clean by construction, and the
  # fallback rate is reported on its own so it is never hidden inside it.
  def stats(records)
    n = records.length
    critiqued = records.map { |r| r['critic'] }.compact
    pct = ->(k) { n.zero? ? nil : (100.0 * k / n).round(1) }
    {
      'banners' => n,
      'critiqued' => critiqued.length,
      'mean_overall' => critiqued.empty? ? nil : (critiqued.sum { |c| c['overall'].to_f } / critiqued.length).round(2),
      'thumbnail_holds_pct' => critiqued.empty? ? nil : (100.0 * critiqued.count { |c| c['thumbnail_holds'] } / critiqued.length).round(1),
      'committed_clean_pct' => pct.call(records.count { |r| r['fallback'] || (r['lint'] && r['lint']['clean']) }),
      'fallback_pct' => pct.call(records.count { |r| r['fallback'] }),
      'cost_usd' => records.map { |r| r['cost_usd'] }.compact.sum.round(4)
    }
  end

  # Per-member quality over each member's LAST `last` records (by timestamp) —
  # a count window, not a clock window, so _data/lineage.yml stays deterministic
  # for an unchanged ledger.
  def member_quality(records, last: 20)
    records.group_by { |r| r['repo'].to_s }.reject { |repo, _| repo.empty? }.map do |repo, rows|
      window = rows.sort_by { |r| r['ts'].to_s }.last(last)
      [repo, stats(window).merge('window' => window.length, 'last_ts' => window.last['ts'])]
    end.to_h
  end

  # Records inside the trailing `days` before `now` (the weekly watcher's window).
  def recent(records, days:, now: Time.now.utc)
    cutoff = now - days * 86_400
    records.select do |r|
      begin
        Time.parse(r['ts'].to_s) >= cutoff
      rescue ArgumentError
        false
      end
    end
  end
end
