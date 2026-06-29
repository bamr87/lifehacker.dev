#!/usr/bin/env ruby
# =============================================================================
# lint_brand.rb — tier 1 brand/voice lint (deterministic, no model)
# -----------------------------------------------------------------------------
# Reads _data/brand/glossary.yml and scans content bodies. The twist: the
# "banned_when_sincere" words are only banned when used SINCERELY — inside a
# flagged satire bit they are the punchline. So this tier is high-recall and
# deliberately does NOT block on them: it emits each hit as a *candidate* with a
# `satire_suspected` guess, and the tier-2 Claude reviewer (brand-reviewer.md)
# adjudicates the ambiguous ones. The only hard failure here is an `avoid_phrase`
# (a weasel phrase), which is wrong in any register.
#
# Code is stripped before scanning, so `leverage` in a shell snippet is ignored.
# Output also drives the tier-2 gate: if any candidate is satire_suspected=false
# (a likely sincere violation), CI runs the reviewer. Stdlib only.
#   ruby scripts/ci/lint_brand.rb
# =============================================================================
require_relative '_lib'

glossary = (LH.yload(LH.read(File.join(LH::ROOT, '_data', 'brand', 'glossary.yml'))) rescue {})
glossary = {} unless glossary.is_a?(Hash)
BANNED = (glossary['banned_when_sincere'] || []).map(&:to_s)
AVOID  = (glossary['avoid_phrases'] || []).map(&:to_s)

DIRS = %w[pages/_hacks pages/_tools pages/_posts pages/_docs]
findings = []

# Optional PR scoping: when LH_CHANGED_FILES is set (a path to a newline-separated
# changed-file list, or an inline list), only scan the changed content files — so
# the candidates AND the tier-2 `brand-needs-review` trigger reflect THIS PR, not
# the whole repo. That keeps the paid brand-reviewer fast and on-topic (it only
# adjudicates words the PR actually introduced). Unset (nightly, push) => scan all.
def lh_scope
  raw = ENV['LH_CHANGED_FILES'].to_s.strip
  return nil if raw.empty?
  (File.file?(raw) ? File.read(raw, encoding: 'UTF-8').split(/\r?\n/) : raw.split(/[\s,]+/))
    .map { |p| p.strip.sub(%r{\A\./}, '') }.reject(&:empty?)
end
SCOPE = lh_scope

# Heuristic: is this line obviously a flagged satire bit (so a banned word here
# is the joke, not a violation)? Blockquote, trademark gag, emphasis, or an
# explicit testimonial/scare-quote marker.
def satire_line?(line)
  l = line.strip
  return true if l.start_with?('>')            # blockquote — the fake-infomercial voice
  return true if l.include?('™')               # trademark gag
  return true if l =~ /\*[^*]*\*/              # *emphasis* around the bit
  return true if l =~ /testimonial|infomercial|but wait|certified n00b/i
  false
end

def each_prose_line(body)
  in_fence = false
  body.each_line.with_index(1) do |line, no|
    if line.strip.start_with?('```')
      in_fence = !in_fence
      next
    end
    next if in_fence
    yield line, no
  end
end

DIRS.each do |dir|
  Dir.glob(File.join(LH::ROOT, dir, '*.md')).sort.each do |path|
    next if SCOPE && !SCOPE.include?(LH.rel(path))
    _fm, body = LH.parse(path)
    rel = LH.rel(path)

    each_prose_line(body) do |line, no|
      stripped_inline = line.gsub(/`[^`]*`/, ' ') # ignore inline code spans
      satire = satire_line?(line)

      BANNED.each do |word|
        next unless stripped_inline =~ /\b#{Regexp.escape(word)}\b/i
        findings << LH.finding(
          check_id: 'brand',
          severity: satire ? 'info' : 'warning', # never 'error' — tier 2 decides
          rule: "banned-when-sincere:#{word}",
          file: rel, line: no,
          evidence: "#{satire ? '[satire?] ' : ''}#{line.strip[0, 140]}",
          route_to: 'local'
        )
      end

      AVOID.each do |phrase|
        next unless stripped_inline.downcase.include?(phrase.downcase)
        findings << LH.finding(
          check_id: 'brand', severity: 'error',
          rule: 'avoid-phrase', file: rel, line: no,
          evidence: "weasel phrase \"#{phrase}\": #{line.strip[0, 140]}"
        )
      end
    end
  end
end

errs = LH.write('brand', findings)

# Signal for the workflow: does tier 2 (the paid Claude reviewer) need to run?
# Only when there's a likely-sincere banned-word candidate to adjudicate.
ambiguous = findings.any? { |f| f['rule'].start_with?('banned-when-sincere:') && f['severity'] == 'warning' }
File.write(File.join(LH::RESULTS, 'brand-needs-review'), ambiguous ? 'true' : 'false')
puts "[brand] tier-2 review needed: #{ambiguous}"

exit(errs.zero? ? 0 : 1)
