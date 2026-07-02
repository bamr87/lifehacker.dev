#!/usr/bin/env ruby
# =============================================================================
# scripts/triage/harvest_ideas.rb — recover the backlog ideas PRs leave behind
# -----------------------------------------------------------------------------
# The content flow tells every grow run: do NOT append follow-up ideas to
# _data/backlog.yml (append collisions); list them in the PR description under
# `## Backlog ideas` and triage promotes the good ones later. This script is
# the "later": it scans recently MERGED `auto:content` PR descriptions for that
# heading, extracts the bullet ideas, dedupes them against the current backlog
# (and against each other), and prints ready-to-review candidates.
#
# DETERMINISTIC MECHANICS, HUMAN/AGENT JUDGMENT: it never writes the backlog.
# The triage agent reviews the candidates, assigns kind/priority/voice to the
# good ones, and adds them to _data/backlog.yml in its own PR (serialized, so
# no append races). Without this harvest the ideas die in merged PR bodies —
# the growth loop's exhaust was never fed back into its fuel tank.
#
#   ruby scripts/triage/harvest_ideas.rb                  # markdown candidates
#   ruby scripts/triage/harvest_ideas.rb --json
#   ruby scripts/triage/harvest_ideas.rb --limit 30
#   ruby scripts/triage/harvest_ideas.rb --self-test      # no gh; parser + dedup
#
# Read-only: shells to `gh` for PR bodies, reads the backlog, prints. Stdlib only.
# =============================================================================
require 'json'
require 'yaml'

module HarvestIdeas
  module_function

  BACKLOG = File.expand_path('../../_data/backlog.yml', __dir__)
  HEADING = /^##+\s*backlog ideas\s*$/i

  # Pull the bullet lines out of a PR body's `## Backlog ideas` section.
  def parse_ideas(body)
    lines = body.to_s.lines.map(&:rstrip)
    start = lines.index { |l| l.match?(HEADING) }
    return [] unless start
    out = []
    lines[(start + 1)..].each do |l|
      break if l.match?(/^#+\s/)                    # next heading ends the section
      m = l.match(/^\s*[-*]\s+(.+)$/)
      out << m[1].strip if m && !m[1].strip.empty?
    end
    out
  end

  # Title-normalization for dedup: case/punctuation/whitespace-insensitive.
  def normalize(title)
    title.downcase.gsub(/`[^`]*`/) { |c| c.delete('`') }
         .gsub(/[^a-z0-9 ]/, ' ').squeeze(' ').strip
  end

  # ideas: [{ 'pr' =>, 'idea' => }] ; backlog_titles: existing titles.
  # -> deduped candidates, first-seen wins.
  def dedupe(ideas, backlog_titles)
    known = backlog_titles.map { |t| normalize(t) }
    seen = {}
    ideas.reject do |i|
      key = normalize(i['idea'])
      dup = key.empty? || known.include?(key) || seen[key]
      seen[key] = true
      dup
    end
  end

  def gather(limit)
    raw = `gh pr list --state merged --label auto:content --limit #{limit.to_i} --json number,body 2>/dev/null`
    prs = raw.strip.empty? ? [] : (JSON.parse(raw) rescue [])
    prs.flat_map { |p| parse_ideas(p['body']).map { |i| { 'pr' => p['number'], 'idea' => i } } }
  end

  def backlog_titles(path = BACKLOG)
    return [] unless File.exist?(path)
    ((YAML.safe_load(File.read(path)) || {})['backlog'] || []).map { |i| i['title'].to_s }
  rescue Psych::SyntaxError
    []
  end

  def render_markdown(cands)
    return "No unharvested backlog ideas in recently merged content PRs.\n" if cands.empty?
    o = +"## Harvested backlog-idea candidates (#{cands.size})\n\n"
    o << "Review each; promote the good ones into `_data/backlog.yml` with a proper\n" \
         "`id`, `kind`, `voice`, and `priority` — and drop the rest. Never auto-add.\n\n"
    cands.each { |c| o << "- #{c['idea']}  _(from PR ##{c['pr']})_\n" }
    o
  end

  def self_test
    body = <<~MD
      Some summary.

      ## Backlog ideas
      - A hack about `trap` cleanup patterns
      * Tool review: hyperfine, the benchmark timer
      -
      ## Testing
      - not an idea (different section)
    MD
    ideas = parse_ideas(body)
    pool = ideas.map { |i| { 'pr' => 7, 'idea' => i } } +
           [{ 'pr' => 8, 'idea' => 'A HACK about trap cleanup patterns!' },   # dup of #1, case/punct
            { 'pr' => 9, 'idea' => 'zoxide review' }]
    cands = dedupe(pool, ['Zoxide review'])                                   # already in backlog
    checks = {
      'parses bullets'  => [ideas.size, 2],
      'star bullet'     => [ideas[1], 'Tool review: hyperfine, the benchmark timer'],
      'stops at heading' => [ideas.none? { |i| i.include?('not an idea') }, true],
      'no heading -> none' => [parse_ideas('no section here'), []],
      'dedup cross-pr'  => [cands.count { |c| normalize(c['idea']).include?('trap cleanup') }, 1],
      'dedup vs backlog' => [cands.none? { |c| c['idea'] == 'zoxide review' }, true],
      'survivors'       => [cands.size, 2]
    }
    failed = checks.reject { |_, (g, w)| g == w }
    if failed.empty?
      puts "harvest_ideas self-test: #{checks.size}/#{checks.size} PASS"
      true
    else
      failed.each { |name, (g, w)| puts "FAIL #{name}: got #{g.inspect}, want #{w.inspect}" }
      false
    end
  end
end

if $PROGRAM_NAME == __FILE__
  opts = { limit: 30, fmt: :markdown }
  i = 0
  while i < ARGV.size
    case ARGV[i]
    when '--self-test' then exit(HarvestIdeas.self_test ? 0 : 1)
    when '--limit'     then opts[:limit] = ARGV[i += 1].to_i
    when '--json'      then opts[:fmt] = :json
    end
    i += 1
  end

  cands = HarvestIdeas.dedupe(HarvestIdeas.gather(opts[:limit]), HarvestIdeas.backlog_titles)
  puts(opts[:fmt] == :json ? JSON.pretty_generate(cands) : HarvestIdeas.render_markdown(cands))
end
