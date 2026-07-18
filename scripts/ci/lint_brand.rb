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
# Recalibrated 2026-07-15 (colophon): the glossary's banned list shrank to pure
# marketing hype (an audit showed 70 of 72 sincere-looking warnings were the
# word "just" — everyday hedge words now live in glossary `watch_words`, which
# this lint deliberately does NOT scan), and the satire heuristic below widened
# (scare quotes, ALL-CAPS delivery, infomercial boilerplate). Both changes exist
# to keep the paid tier-2 reviewer asleep unless a hype word looks genuinely
# sincere — which on this site should be rare and worth a human's attention.
#
# Code is stripped before scanning, so `synergy` in a shell snippet is ignored.
# Output also drives the tier-2 gate: if any candidate is satire_suspected=false
# (a likely sincere violation), CI runs the reviewer. Stdlib only.
#   ruby scripts/ci/lint_brand.rb
# =============================================================================
require_relative '_lib'
require 'set'

glossary = (LH.yload(LH.read(File.join(LH::ROOT, '_data', 'brand', 'glossary.yml'))) rescue {})
glossary = {} unless glossary.is_a?(Hash)
BANNED = (glossary['banned_when_sincere'] || []).map(&:to_s)
AVOID  = (glossary['avoid_phrases'] || []).map(&:to_s)

# Since #337 all news content (hacks/tools/field-notes) is one collection under
# pages/_posts/<section>/, so a recursive glob covers what the four flat dirs did.
DIRS = %w[pages/_posts pages/_docs]
findings = []

# --- PR scoping --------------------------------------------------------------
# Brand is a CONTENT check: a branch can only introduce voice problems in the
# prose IT changed, never in the repo's pre-existing backlog. So on any non-main
# branch the scan narrows to the changed content files (issue #93) — so a PR is
# never shown, nor the paid tier-2 reviewer ever woken, for `just`/`10x` already
# living in files the PR didn't touch. Resolution order:
#   1. An explicit changed-file list from CI: LH_BRAND_CHANGED_FILES (set on EVERY
#      PR by pipeline.yml) or LH_CHANGED_FILES (the content-PR whole-report scope).
#      Value is a path to a newline list, or an inline whitespace/comma list.
#   2. LH_BRAND_SCOPE_ALL truthy => force the full-repo scan (push to main, the
#      nightly sweep, and the weekly brand-sweep that must see every warning).
#   3. Auto: on a non-main git branch, diff against the base (LH_BASE_REF, else
#      origin/main, else main) and scope to those files — so a LOCAL harness run
#      on a feature branch behaves like CI with no extra flags. Any git failure,
#      a detached HEAD, or main itself => nil (full repo, the safe default).
def lh_clean_paths(text)
  text.to_s.split(/\r?\n/).map { |p| p.strip.sub(%r{\A\./}, '') }.reject(&:empty?)
end

def lh_parse_list(raw)
  # `raw` is a path to a newline-delimited list file (what CI writes) OR an inline
  # whitespace/comma list. A content path (…/_hacks/x.md) is NEVER read as a list
  # file — it scopes to that single file — so passing one file path directly works
  # instead of silently scanning its prose as a list of changed files.
  listfile = File.file?(raw) && !raw.match?(%r{\A(?:\./)?pages/_\w+/.+\.md\z})
  lh_clean_paths(listfile ? File.read(raw, encoding: 'UTF-8') : raw.gsub(/[\s,]+/, "\n"))
end

def lh_truthy?(val)
  %w[1 true yes on].include?(val.to_s.strip.downcase)
end

# Run git with array args (no shell). core.quotepath=false keeps non-ASCII paths
# verbatim (not octal-escaped + double-quoted), so they equal LH.rel's UTF-8 output
# and actually match SCOPE; the result is forced to UTF-8 so .split never raises on
# a runner whose default external encoding is US-ASCII. Returns stdout, else nil.
def lh_git(*args)
  out = IO.popen(['git', '-c', 'core.quotepath=false', *args], err: File::NULL, &:read)
  return nil unless $?.success?
  out.to_s.dup.force_encoding('UTF-8')
end

# The branch's changed CONTENT, scoped like CI's PR diff but resolved locally so a
# harness run on a feature branch needs no flags. Covers committed (base...HEAD)
# PLUS the working tree (uncommitted edits + untracked files), so the file you are
# authoring is checked before you commit. main / detached HEAD / any git failure
# => nil (full repo, the safe default).
def lh_auto_scope
  branch = lh_git('rev-parse', '--abbrev-ref', 'HEAD').to_s.strip
  return nil if branch.empty? || branch == 'HEAD' || branch == 'main'
  base = ENV['LH_BASE_REF'].to_s.strip
  base = 'origin/main' if base.empty?
  base = 'main' unless lh_git('rev-parse', '--verify', '--quiet', base)
  return nil unless lh_git('rev-parse', '--verify', '--quiet', base)
  committed = lh_git('diff', '--name-only', "#{base}...HEAD")
  return nil if committed.nil?                          # git failed => fail safe to full repo
  uncommitted = lh_git('diff', '--name-only', 'HEAD')  # tracked, unstaged + staged
  untracked   = lh_git('ls-files', '--others', '--exclude-standard')
  lh_clean_paths(committed) | lh_clean_paths(uncommitted) | lh_clean_paths(untracked)
end

def lh_scope
  raw = ENV['LH_BRAND_CHANGED_FILES'].to_s.strip
  raw = ENV['LH_CHANGED_FILES'].to_s.strip if raw.empty?
  return lh_parse_list(raw) unless raw.empty?
  return nil if lh_truthy?(ENV['LH_BRAND_SCOPE_ALL'])
  lh_auto_scope
end
SCOPE = lh_scope
warn "[brand] scope: #{SCOPE ? "#{SCOPE.size} changed file(s)" : 'full repo'}" # observable: a bare re-run on a PR branch auto-scopes; this makes that visible

# --- accept-ledger -----------------------------------------------------------
# Reviewed banned-when-sincere hits that are legitimately fine (a literal "just a
# moment ago", a flagged satire bit tier-1 missed) live in _data/brand/accepted.yml
# keyed by the finding's `accept_key`. A matching hit is recorded as INFO instead
# of a warning, so it stays auditable in findings.jsonl but never blocks, never
# nags in the PR report, and never wakes the paid tier-2 reviewer. The key hashes
# the LINE TEXT, so editing the sentence re-opens it for review — we accept a
# specific sentence, never blanket-license a word.
def lh_accepted_keys
  path = File.join(LH::ROOT, '_data', 'brand', 'accepted.yml')
  return Set.new unless File.file?(path)
  data = (LH.yload(LH.read(path)) rescue nil)
  list = data.is_a?(Hash) ? data['accepted'] : nil
  return Set.new unless list.is_a?(Array)
  # downcase: accept_key is lowercase hex, so a human typing an uppercase key in
  # the ledger should still match (hex case carries no meaning, no false matches).
  list.map { |e| (e.is_a?(Hash) ? e['key'] : e).to_s.strip.downcase }.reject(&:empty?).to_set
end
ACCEPTED = lh_accepted_keys

def accept_key(rel, word, line)
  Digest::SHA1.hexdigest("#{rel}|#{word.downcase}|#{line.strip}")[0, 12]
end

# Heuristic: is this line obviously a flagged satire bit (so a banned word here
# is the joke, not a violation)? Widened 2026-07-15 to match the more generous
# satire license in voice.yml: blockquotes, trademark gags, emphasis, scare
# quotes around the word itself, ALL-CAPS delivery, repeated exclamation, and
# the standard infomercial boilerplate all read as "clearly a bit" — they go
# straight to info instead of waking the paid tier-2 reviewer.
SATIRE_MARKERS = /testimonial|infomercial|but wait|certified n00b|as seen on|act now|limited time|money-back|operators are standing by|results may vary|patent pending|side effects may include|satisfaction guaranteed|free trial|fine print/i

def satire_line?(line, word = nil)
  l = line.strip
  return true if l.start_with?('>')                  # blockquote — the fake-infomercial voice
  return true if l.include?('™') || l.include?('®')  # trademark gag
  return true if l =~ /\*[^*]*\*/                    # *emphasis* around the bit
  return true if l =~ SATIRE_MARKERS
  return true if l.count('!') >= 2                   # nobody is sincerely that excited
  if word
    q = Regexp.escape(word)
    return true if l =~ /["“”'‘’]#{q}["“”'‘’]/i      # scare quotes around the word itself
    up = word.upcase
    return true if up != word && l.include?(up)      # ALL-CAPS delivery (SEAMLESS. 10X.)
  end
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
  Dir.glob(File.join(LH::ROOT, dir, '**', '*.md')).sort.each do |path|
    next if SCOPE && !SCOPE.include?(LH.rel(path))
    _fm, body = LH.parse(path)
    rel = LH.rel(path)

    each_prose_line(body) do |line, no|
      stripped_inline = line.gsub(/`[^`]*`/, ' ') # ignore inline code spans

      BANNED.each do |word|
        next unless stripped_inline =~ /\b#{Regexp.escape(word)}\b/i
        satire   = satire_line?(line, word)
        key      = accept_key(rel, word, line)
        accepted = ACCEPTED.include?(key)
        # accepted (human-reviewed, fine) and satire-suspected hits are INFO, never
        # a warning — so neither blocks, nags, nor wakes tier 2. Only a straight,
        # un-accepted hit stays a `warning` for the reviewer/sweep to adjudicate.
        prefix = accepted ? '[accepted] ' : (satire ? '[satire?] ' : '')
        findings << LH.finding(
          check_id: 'brand',
          severity: (accepted || satire) ? 'info' : 'warning', # never 'error' — tier 2 decides
          rule: "banned-when-sincere:#{word}",
          file: rel, line: no,
          evidence: "#{prefix}#{line.strip[0, 140]}",
          route_to: 'local'
        ).merge('accept_key' => key)
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

# Ledger hygiene: on a full-repo scan, flag accept-ledger entries that no longer
# match any line (the prose was edited or deleted) so stale accepts don't pile up
# silently — the weekly brand-sweep can then prune them. Skipped on a PR-scoped run
# (which legitimately sees only a slice, so "unseen" wouldn't mean "stale").
if SCOPE.nil? && !ACCEPTED.empty?
  orphans = ACCEPTED - findings.map { |f| f['accept_key'] }.compact
  warn "[brand] #{orphans.size} accept-ledger entr(y/ies) match nothing now (stale?): #{orphans.first(10).join(', ')}" unless orphans.empty?
end

# Signal for the workflow: does tier 2 (the paid Claude reviewer) need to run?
# Only when there's a likely-sincere banned-word candidate to adjudicate.
ambiguous = findings.any? { |f| f['rule'].start_with?('banned-when-sincere:') && f['severity'] == 'warning' }
File.write(File.join(LH::RESULTS, 'brand-needs-review'), ambiguous ? 'true' : 'false')
puts "[brand] tier-2 review needed: #{ambiguous}"

exit(errs.zero? ? 0 : 1)
