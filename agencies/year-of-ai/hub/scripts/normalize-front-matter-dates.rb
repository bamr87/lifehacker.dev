#!/usr/bin/env ruby
# frozen_string_literal: true

# normalize-front-matter-dates.rb — make every Markdown front-matter `date:`
# a single plain ISO date (YYYY-MM-DD).
#
# Why: Jekyll's datetime parse in the theme's root layout rejects values like
# `date: "1777–1778"` (an en-dash range), which fails the member's WHOLE Pages
# build — this took the member repo 1777 offline from 2026-06-30 to 2026-07-06.
# Bare years (`date: 1777`) don't fail the build but parse as epoch seconds and
# render as 1970 dates. Model passes occasionally write both forms, so
# grow-lineage.yml runs this with --fix before every publish, and it doubles as
# the one-shot repair tool for existing member content.
#
# Rules (deterministic):
#   ISO range  "1777-12-19 / 1778-06-19" -> start date 1777-12-19
#   year range "1777–1778"               -> 1777-01-01
#   bare year  1777 / "1777"             -> 1777-01-01
#   prose      "October 4, 1777"         -> 1777-10-04
#   quoted ISO "1777-11-15"              -> unquoted 1777-11-15
# Anything else that Ruby's Date.iso8601 cannot parse is reported as UNFIXABLE.
#
# Usage:
#   ruby scripts/normalize-front-matter-dates.rb [--check|--fix] [DIR]
#     --check  (default) report offenders, write nothing; exit 1 if any found
#     --fix    rewrite offenders in place; exit 0 when all dates end up ISO,
#              exit 2 if unfixable values remain (callers must not publish)
#
# Only files whose front matter block (leading `---` fence) contains a `date:`
# key are touched; repo plumbing (.git/, .github/, .claude/, telemetry/,
# node_modules/, vendor/) and the staged seed.md are skipped.

require "date"

mode = ARGV.delete("--fix") ? :fix : :check
ARGV.delete("--check")
root = ARGV.shift || "."

SKIP = %r{(^|/)(\.git|\.github|\.claude|telemetry|node_modules|vendor)/}
DASHES = /[–—-]/ # en dash, em dash, hyphen
MONTHS = Date::MONTHNAMES

def normalize(val)
  case val
  when /\A\d{4}-\d{2}-\d{2}\z/ then val
  when %r{\A(\d{4}-\d{2}-\d{2})\s*(/|#{DASHES})\s*\d{4}} then Regexp.last_match(1)
  when /\A(\d{4})\s*#{DASHES}\s*\d{4}\z/ then "#{Regexp.last_match(1)}-01-01"
  when /\A(\d{4})\z/ then "#{Regexp.last_match(1)}-01-01"
  when /\A([A-Z][a-z]+)\s+(\d{1,2}),?\s+(\d{4})\z/
    m = MONTHS.index(Regexp.last_match(1))
    m && format("%04d-%02d-%02d", Regexp.last_match(3).to_i, m, Regexp.last_match(2).to_i)
  end
end

fixed = []
unfixable = []
# Jekyll builds both extensions (markdown_ext default), so the publish gate
# must cover both — a bad date in a .markdown file fails a Pages build just
# as hard as one in a .md file.
Dir.glob(File.join(root, "**", "*.{md,markdown}")).sort.each do |f|
  next if f.match?(SKIP) || File.basename(f) == "seed.md"

  text = File.read(f, encoding: "utf-8")
  next unless text =~ /\A---\n(.*?\n)---\n/m

  front = Regexp.last_match(1)
  next unless front =~ /^date:[ \t]*(.+?)[ \t]*$/

  raw = Regexp.last_match(1)
  val = raw.gsub(/["']/, "").strip
  new = normalize(val)
  if new.nil? || !(Date.iso8601(new) rescue nil)
    unfixable << "#{f}: date: #{raw}"
    next
  end
  next if new == raw # already plain ISO

  fixed << "#{f}: #{raw} -> #{new}"
  next unless mode == :fix

  # Replace only within the front matter block.
  head, rest = text.split(/\n---\n/, 2)
  File.write(f, "#{head.sub(/^date:[ \t]*.+$/) { "date: #{new}" }}\n---\n#{rest}")
end

label = mode == :fix ? "fixed" : "would fix"
fixed.each { |l| puts "#{label}: #{l}" }
unfixable.each { |l| warn "UNFIXABLE: #{l}" }
puts "#{fixed.size} #{label}, #{unfixable.size} unfixable"

exit 2 unless unfixable.empty?
exit 1 if mode == :check && !fixed.empty?
