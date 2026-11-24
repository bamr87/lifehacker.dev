#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# genome/bin/verify.rb — the routine-sync / anti-drift gate.
# =============================================================================
# Makes "the genome reflects the current model" verifiable and enforceable so the
# DNA cannot silently rot into a stale snapshot. Two checks, both run against the
# LIVE hub repo (no network):
#
#   --check (default): every tracked file in the repo is classified by
#     genome/manifest.yml (transplant | template | override | regenerate | ignore).
#     A file that is NEITHER classified NOR ignored AND carries a concept literal
#     (the org/brand/founder strings) FAILS — "the model grew a limb the genome
#     doesn't track."
#
#   --leaks: every `transplant:` file must be concept-AGNOSTIC. A transplant file
#     that contains a concept literal is misclassified (belongs in template/
#     override) and FAILS — "a literal is hiding in a verbatim file."
#
# Exit non-zero on any failure. Wire into CI (genome-sync) so a model change that
# isn't reflected in the genome turns the build red. Run both by default.
# =============================================================================

require 'yaml'
require 'set'

ROOT     = File.expand_path('../..', __dir__)
MANIFEST = File.join(__dir__, '..', 'manifest.yml')

man = YAML.load_file(MANIFEST)
literals = (man['tokens'] || []).map { |t| t['literal'] }

# Strong concept literals that unambiguously mark a file as concept-bearing.
# (Bare "year" is intentionally excluded — too noisy; the org/brand/founder
# strings are the reliable signal of a leaked or unclassified concept file.)
STRONG = [
  'year-of-ai', 'Year of AI', 'Amr Abdel-Motaleb',
  'amr.abdel@gmail.com', 'noreply@anthropic.com', '/Users/bamr87'
].freeze
STRONG_RE = Regexp.union(STRONG)

def glob_match?(path, pattern)
  if pattern.end_with?('/**')
    path.start_with?(pattern[0..-3]) # 'dir/**' -> prefix 'dir/'
  else
    File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
  end
end

def covered?(path, patterns)
  patterns.any? { |p| glob_match?(path, p) }
end

tiers = %w[transplant template override regenerate ignore].to_h { |k| [k, man[k] || []] }

Dir.chdir(ROOT)
files = `git ls-files`.split("\n").reject(&:empty?)

unclassified = []
leaks        = []
counts       = Hash.new(0)

files.each do |f|
  # Most-specific tiers (which list explicit files) win over the broad-glob tiers
  # (transplant `dir/**`, ignore), so a framework file carved into override is not
  # also leak-scanned as transplant.
  tier = %w[override template regenerate transplant ignore].find { |t| covered?(f, tiers[t]) }
  counts[tier || 'UNCLASSIFIED'] += 1

  # Drift gate: an unclassified, concept-bearing file means the genome is out of date.
  if tier.nil?
    next unless File.file?(f)
    body = File.read(f, encoding: 'utf-8', invalid: :replace, undef: :replace) rescue ''
    unclassified << f if body.match?(STRONG_RE)
  end

  # Leak gate: a transplant file must contain NO concept literal.
  if tier == 'transplant' && File.file?(f)
    body = File.read(f, encoding: 'utf-8', invalid: :replace, undef: :replace) rescue ''
    hit = STRONG.find { |lit| body.include?(lit) }
    leaks << "#{f}  (contains #{hit.inspect})" if hit
  end
end

puts '── genome verify ───────────────────────────────────────────'
puts "  tracked files: #{files.size}"
%w[transplant template override regenerate ignore UNCLASSIFIED].each do |t|
  puts "    #{t.ljust(12)} #{counts[t]}" if counts[t].positive?
end
puts "  token literals: #{literals.size}"

ok = true
unless unclassified.empty?
  ok = false
  puts "\n  ✗ UNCLASSIFIED concept-bearing files (genome out of sync — classify in manifest.yml):"
  unclassified.sort.each { |f| puts "      #{f}" }
end
unless leaks.empty?
  ok = false
  puts "\n  ✗ LEAKS — transplant files that carry a concept literal (move to template/override):"
  leaks.sort.each { |f| puts "      #{f}" }
end

if ok
  puts "\n  ✓ genome in sync: every concept-bearing tracked file is classified, no leaks in the transplant tier."
  exit 0
else
  puts "\n  Genome is out of sync with the model. Update genome/manifest.yml (and re-run)."
  exit 1
end
