#!/usr/bin/env ruby
# =============================================================================
# scripts/content/weekly_digest.rb — the prior week's publications, as data
# -----------------------------------------------------------------------------
# The weekly-epic routine (.claude/skills/weekly-epic) retells the week's real
# publications as one Top Story. This script is what keeps that retelling
# HONEST: it lists exactly which articles fall inside the window — from the
# committed front matter, not from anyone's memory — so every deed the bard
# sings can be checked against a line in this file's output, and the figure
# renderer (scripts/media/figures.mjs) draws from the same list. No timestamps,
# no wall-clock leakage: the same window over the same checkout is
# byte-identical forever, so the digest can be committed next to the figures it
# produced and regenerated without noise.
#
#   ruby scripts/content/weekly_digest.rb                    # last 7 days, JSON to stdout
#   ruby scripts/content/weekly_digest.rb --days 7 --until 2026-08-10
#   ruby scripts/content/weekly_digest.rb --out assets/images/figures/<slug>/digest.json
#
# Window: (until - days, until] by front-matter `date:` — a Monday run with
# --until <yesterday> captures exactly the prior Tue..Mon of publications.
# Exit 0 with an empty items[] when the week was silent; the CALLER decides
# whether a silent week is a no-op (it is — no honest epic without deeds).
# Stdlib only. Sections scanned: hacks, tools, field-notes, wire (posts) + docs.
# =============================================================================
require_relative '../ci/_lib'
require 'optparse'

module WeeklyDigest
  module_function

  SECTIONS = [
    { dir: 'pages/_posts/hacks',       section: 'hacks' },
    { dir: 'pages/_posts/tools',       section: 'tools' },
    { dir: 'pages/_posts/field-notes', section: 'field-notes' },
    { dir: 'pages/_posts/wire',        section: 'wire' },
    { dir: 'pages/_docs',              section: 'docs' }
  ].freeze

  DATED = /\A(\d{4}-\d{2}-\d{2})-(.+)\.md\z/.freeze

  # Where the article will render, mirroring _config.yml's permalink rules: an
  # explicit front-matter `permalink:` wins (hacks/tools pin their classic
  # URLs); field notes take the dated posts URL; docs take /docs/:name/.
  def url_for(fm, section, date, slug)
    pl = fm['permalink'].to_s
    return pl unless pl.empty?
    return "/docs/#{slug}/" if section == 'docs'
    "/posts/#{date.strftime('%Y/%m/%d')}/#{slug}/"
  end

  def item_for(path, section, window)
    fm, body = LH.parse(path)
    return nil unless fm.is_a?(Hash)
    base = File.basename(path)
    m = DATED.match(base)
    slug = m ? m[2] : base.sub(/\.md\z/, '')
    date = fm['date'].is_a?(Date) ? fm['date'] : (Date.parse(fm['date'].to_s) rescue nil)
    date ||= m && Date.parse(m[1])
    return nil unless date && date > window[:since_excl] && date <= window[:until]
    prose = LH.strip_code(body.to_s)
    {
      'file'        => LH.rel(path),
      'slug'        => slug,
      'title'       => fm['title'].to_s,
      'description' => fm['description'].to_s,
      'date'        => date.iso8601,
      'section'     => section,
      'author'      => fm['author'].to_s,
      'tags'        => Array(fm['tags']).map(&:to_s),
      'excerpt'     => fm['excerpt'].to_s,
      'verdict'     => fm['verdict'],
      'series'      => fm['series'],
      'source_url'  => fm['source_url'],
      'preview'     => fm['preview'],
      'word_count'  => prose.split(/\s+/).size,
      'url'         => url_for(fm, section, date, slug)
    }.compact
  end

  def build(days:, until_date:)
    window = { until: until_date, since_excl: until_date - days }
    items = SECTIONS.flat_map do |spec|
      Dir.glob(File.join(LH::ROOT, spec[:dir], '*.md')).sort.filter_map do |path|
        item_for(path, spec[:section], window)
      end
    end
    items.sort_by! { |i| [i['date'], i['file']] }
    authors = (LH.yload(LH.read(File.join(LH::ROOT, '_data', 'authors.yml'))) rescue {}) || {}
    by = ->(key) { items.group_by { |i| i[key] }.transform_values(&:size) }
    {
      'window' => { 'since' => (window[:since_excl] + 1).iso8601, 'until' => until_date.iso8601, 'days' => days },
      'counts' => {
        'total'      => items.size,
        'by_section' => by.call('section'),
        'by_author'  => by.call('author').transform_keys { |k| k.to_s.empty? ? '(none)' : k }
      },
      'tags'    => items.flat_map { |i| i['tags'] }.tally.sort_by { |t, n| [-n, t] }.to_h,
      'authors' => items.map { |i| i['author'] }.uniq.sort.each_with_object({}) do |k, h|
        meta = authors[k]
        h[k] = { 'name' => meta && meta['name'], 'voice' => meta && meta['voice'] }.compact
      end,
      'items' => items
    }
  end

  def run(argv)
    days = 7
    until_date = Date.today
    out = nil
    OptionParser.new do |o|
      o.banner = 'usage: weekly_digest.rb [--days N] [--until YYYY-MM-DD] [--out FILE]'
      o.on('--days N', Integer, 'window length in days (default 7)') { |v| days = v }
      o.on('--until DATE', 'inclusive window end (default today)') { |v| until_date = Date.parse(v) }
      o.on('--out FILE', 'write JSON here instead of stdout') { |v| out = v }
    end.parse!(argv)
    abort '[weekly-digest] --days must be 1..21' unless (1..21).cover?(days)

    digest = build(days: days, until_date: until_date)
    json = JSON.pretty_generate(digest) + "\n"
    if out
      FileUtils.mkdir_p(File.dirname(out))
      File.write(out, json)
      warn "[weekly-digest] ✓ #{out} — #{digest['counts']['total']} article(s) in #{digest['window']['since']}..#{digest['window']['until']}"
    else
      puts json
    end
    warn "[weekly-digest] note: the window is EMPTY — a silent week means no epic" if digest['items'].empty?
    0
  end
end

exit(WeeklyDigest.run(ARGV)) if $PROGRAM_NAME == __FILE__
