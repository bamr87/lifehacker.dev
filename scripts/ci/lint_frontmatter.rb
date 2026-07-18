#!/usr/bin/env ruby
# =============================================================================
# lint_frontmatter.rb — per-collection front-matter schema validator
# -----------------------------------------------------------------------------
# Enforces, per collection, the keys the grow-lifehacker SKILL.md templates
# promise. Errors block the merge gate; style nits (a too-long SEO description)
# are warnings so the gate stays green on existing content while still steering
# future drafts. Stdlib only. Run: ruby scripts/ci/lint_frontmatter.rb
# =============================================================================
require_relative '_lib'

authors = (LH.yload(LH.read(File.join(LH::ROOT, '_data', 'authors.yml'))) rescue {})
AUTHOR_KEYS = authors.is_a?(Hash) ? authors.keys.map(&:to_s) : []

# dir, section kind, and the category each item must carry. Since issue #337 the
# hacks/tools/field-notes are all `posts` under pages/_posts/<section>/, so the
# section is identified by the required `categories:[<category>]`, not a
# `collection:` key, and every item obeys the dated-post filename rule.
SPECS = [
  { dir: 'pages/_posts/hacks',       kind: 'hacks',       category: 'Hacks' },
  { dir: 'pages/_posts/tools',       kind: 'tools',       category: 'Tools' },
  { dir: 'pages/_posts/field-notes', kind: 'field-notes', category: 'Field Notes' },
  { dir: 'pages/_docs',              kind: 'docs', lenient: true }
]

COMMON = %w[title description date author excerpt tags] # hacks/tools/posts
findings = []

def present?(v)
  return false if v.nil?
  return !v.empty? if v.respond_to?(:empty?)
  true
end

SPECS.each do |spec|
  Dir.glob(File.join(LH::ROOT, spec[:dir], '*.md')).sort.each do |path|
    fm, = LH.parse(path)
    rel = LH.rel(path)

    unless fm
      findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                             rule: 'no-front-matter', file: rel,
                             evidence: 'file has no parseable YAML front matter')
      next
    end

    required = spec[:lenient] ? %w[title description] : COMMON
    required.each do |k|
      next if present?(fm[k])
      findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                             rule: "missing-key:#{k}", file: rel,
                             evidence: "required key `#{k}` is missing or empty")
    end

    # description length: SEO soft cap, warn-only (existing content runs ~170).
    if present?(fm['description']) && fm['description'].to_s.length > 160
      findings << LH.finding(check_id: 'frontmatter', severity: 'warning',
                             rule: 'description-too-long', file: rel,
                             evidence: "#{fm['description'].to_s.length} chars (SEO cap is 160)")
    end

    # author must be a known persona key.
    if present?(fm['author']) && !AUTHOR_KEYS.include?(fm['author'].to_s)
      findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                             rule: 'unknown-author', file: rel,
                             evidence: "author `#{fm['author']}` is not a key in _data/authors.yml")
    end

    # tags must be a non-empty array (skip for lenient docs).
    unless spec[:lenient]
      unless fm['tags'].is_a?(Array) && !fm['tags'].empty?
        findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                               rule: 'tags-not-array', file: rel,
                               evidence: 'tags must be a non-empty array')
      end
    end

    # date: parseable and not in the future (no show_drafts in production).
    if present?(fm['date'])
      d = fm['date'].is_a?(Date) ? fm['date'] : (Date.parse(fm['date'].to_s) rescue nil)
      if d.nil?
        findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                               rule: 'invalid-date', file: rel,
                               evidence: "date `#{fm['date']}` is not parseable")
      elsif d > Date.today
        findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                               rule: 'future-date', file: rel,
                               evidence: "date #{d} is in the future")
      end
    end

    unless spec[:lenient]
      # Every news item declares its section via `categories:[<category>]`.
      cats = fm['categories']
      unless cats.is_a?(Array) && cats.map(&:to_s).include?(spec[:category])
        findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                               rule: 'wrong-section-category', file: rel,
                               evidence: "must list `#{spec[:category]}` in categories, got #{cats.inspect}")
      end

      # Tools still lead with a verdict.
      if spec[:kind] == 'tools' && !present?(fm['verdict'])
        findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                               rule: 'missing-key:verdict', file: rel,
                               evidence: 'a tool review must carry a non-empty verdict')
      end

      # All sections are posts now: dated filename that matches the front matter.
      base = File.basename(path)
      if base =~ /\A(\d{4})-(\d{2})-(\d{2})-/
        fdate = (Date.new($1.to_i, $2.to_i, $3.to_i) rescue nil)
        d = fm['date'].is_a?(Date) ? fm['date'] : (Date.parse(fm['date'].to_s) rescue nil)
        if fdate && d && fdate != d
          findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                                 rule: 'filename-date-mismatch', file: rel,
                                 evidence: "filename date #{fdate} != front-matter date #{d}")
        end
      else
        findings << LH.finding(check_id: 'frontmatter', severity: 'error',
                               rule: 'bad-post-filename', file: rel,
                               evidence: 'post filename must start with YYYY-MM-DD-')
      end
    end
  end
end

errs = LH.write('frontmatter', findings)
exit(errs.zero? ? 0 : 1)
