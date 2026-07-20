#!/usr/bin/env ruby
# =============================================================================
# scripts/fleet/authors.rb — the per-section AI-author rotation authority
# -----------------------------------------------------------------------------
# The content picker (fleet/plan.rb) and the content factory choose WHAT to write
# by lane/priority/status — never by WHO writes it. So an item with no explicit
# `author:` always defaulted to `claude`, and the declared AI personas (`cass`,
# `edge`) went unused despite having full voice profiles and agent files. See the
# field note /posts/2026/07/17/two-more-voices-used-them-once/.
#
# This module closes that gap with quota-based routing: for a given section it
# tallies how many pieces each AI persona has already written there and assigns
# the LEAST-USED one (ties broken by ring order). That corrects the historical
# imbalance first, then settles into an even round-robin — every AI author gets
# a turn in every section. It is pure + deterministic (no cursor to persist, so
# no cross-workflow drift and no merge conflicts): the answer is a function of
# the committed posts on disk, so the content-factory legs and the fleet
# dispatcher compute the same rotation without sharing mutable state.
#
# The ring is DATA-DRIVEN: any `_data/authors.yml` entry with a `voice:` key
# joins the rotation (the human `amr` and the `default` alias have none, so they
# are excluded). An entry can opt out with `rotate: false`.
#
#   ruby scripts/fleet/authors.rb --section hack   # -> prints the next author key
#   ruby scripts/fleet/authors.rb --table          # -> per-section counts + pick
# =============================================================================
require_relative '../ci/_lib'

module Fleet
  module Authors
    module_function

    # kind/section aliases -> the posts directory that section lives in.
    SECTION_DIRS = {
      'hack'        => 'pages/_posts/hacks',
      'hacks'       => 'pages/_posts/hacks',
      'tool'        => 'pages/_posts/tools',
      'tools'       => 'pages/_posts/tools',
      'post'        => 'pages/_posts/field-notes',
      'posts'       => 'pages/_posts/field-notes',
      'field-note'  => 'pages/_posts/field-notes',
      'field-notes' => 'pages/_posts/field-notes',
      'doc'         => 'pages/_docs',
      'docs'        => 'pages/_docs'
    }.freeze

    # Fallback ring if _data/authors.yml can't be read for some reason. The real
    # ring is derived from the file (below); this only guards a broken checkout.
    DEFAULT_RING = %w[claude cass edge].freeze

    # The AI personas eligible for rotation, in a STABLE order (authors.yml is
    # insertion-ordered, so the ring order — hence the tie-break — is stable).
    # Eligible = has a `voice:` profile AND is not opted out with `rotate: false`.
    def ring
      data = (LH.yload(LH.read(File.join(LH::ROOT, '_data', 'authors.yml'))) rescue nil)
      return DEFAULT_RING unless data.is_a?(Hash)
      r = data.each_with_object([]) do |(key, meta), acc|
        next unless meta.is_a?(Hash)
        next unless present?(meta['voice'])
        next if meta['rotate'] == false
        acc << key.to_s
      end
      r.empty? ? DEFAULT_RING : r
    end

    # The directories a section spans. A known kind -> its one dir; an unknown
    # section -> every section (so a stray call still rotates on global counts
    # instead of blindly returning the first author every time).
    def dirs_for(section)
      dir = SECTION_DIRS[section.to_s.strip.downcase]
      dir ? [dir] : SECTION_DIRS.values.uniq
    end

    # { author_key => pieces_that_author_has_in_this_section }, seeded to 0 for
    # every ring member so a persona with none is a real 0 (the least-used pick),
    # not a missing key. Only ring authors are tallied — human/one-off bylines
    # don't perturb the AI rotation.
    def counts_for(section, ring_keys = ring)
      counts = ring_keys.each_with_object({}) { |a, h| h[a] = 0 }
      dirs_for(section).each do |rel_dir|
        Dir.glob(File.join(LH::ROOT, rel_dir, '*.md')).each do |path|
          fm, = LH.parse(path)
          author = fm && fm['author'].to_s
          counts[author] += 1 if author && counts.key?(author)
        end
      end
      counts
    end

    # Pure: least-used author wins; ties broken by ring order (earliest wins).
    # Once the counts equalize this becomes a strict round-robin through the ring.
    def assign(counts, ring_keys = ring)
      return nil if ring_keys.empty?
      ring_keys.min_by { |a| [counts[a].to_i, ring_keys.index(a)] }
    end

    # The rotation decision for a section: the least-used AI persona there.
    def next_author(section)
      r = ring
      assign(counts_for(section, r), r)
    end

    def present?(v)
      return false if v.nil?
      return !v.strip.empty? if v.respond_to?(:strip)
      true
    end

    # -- CLI ------------------------------------------------------------------
    def run(argv)
      if argv.include?('--table') || argv.include?('--all') || argv.empty?
        r = ring
        puts "AI author rotation ring (from _data/authors.yml): #{r.join(', ')}"
        puts
        %w[hacks tools field-notes docs].each do |section|
          counts = counts_for(section, r)
          pick   = assign(counts, r)
          tally  = r.map { |a| "#{a}=#{counts[a]}" }.join('  ')
          puts format('  %-12s next: %-8s  (%s)', section, pick, tally)
        end
        return 0
      end

      i = argv.index('--section')
      section = i ? argv[i + 1] : nil
      unless section
        warn 'usage: authors.rb --section <hack|tool|post|doc>   (or --table)'
        return 2
      end
      pick = next_author(section)
      if pick.nil?
        warn "[authors] no AI personas eligible for rotation in _data/authors.yml"
        return 1
      end
      puts pick
      0
    end
  end
end

exit(Fleet::Authors.run(ARGV)) if $PROGRAM_NAME == __FILE__
