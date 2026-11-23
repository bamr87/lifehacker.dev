#!/usr/bin/env ruby
# =============================================================================
# scripts/agencies/promote.rb — publish an agency site as a collection of this site
# -----------------------------------------------------------------------------
# An agency arrives as a whole site tree under agencies/, held but not built
# (docs/adr/0002-agencies.md). Promoting it makes its pages part of
# lifehacker.dev: they move into a Jekyll collection, pages/_<collection>/, and
# are served under the bureau's own path (docs/adr/0003-agencies-as-collections.md).
#
#   ruby scripts/agencies/promote.rb <site path> --pages <dir in the tree> \
#        --collection <name> --url /<name>/ \
#        [--url-from /old/base/] [--author old=new ...] [--images <dir in the tree>]
#
#   <site path>   the site's `path` in _data/agencies.yml (agencies/wargames).
#   --pages       the directory inside the tree that holds its pages; it becomes
#                 pages/_<collection>/ whole, by `git mv`, so history follows.
#   --collection  the collection's name. Declare it in _config.yml yourself
#                 (collections:, defaults:) — this tool does not edit the config,
#                 and scripts/ci/lint_agencies.rb fails until it is declared.
#   --url         the bureau's path on this site, recorded in the registry.
#   --url-from    the URL base the pages carried where they came from. Every
#                 occurrence in the moved pages is rewritten to --url: pinned
#                 permalinks and Liquid links alike.
#   --author      rewrite a front-matter `author:` key to one of this site's
#                 (_data/authors.yml); repeatable.
#   --images      a directory of images inside the tree, moved to
#                 assets/images/<collection>/ by `git mv`.
#
# It runs once per site, and only for a site whose custody is `home`: a mirror
# is still written at its source, and publishing a copy of it here would put the
# same pages on two sites and two write sides. Cut the mirror over first.
#
# What stays in the tree is its back office: guides, licence, tooling, the old
# site configuration. The registry row gains a `published:` block.
#
# Stdlib only, Ruby 2.6+. Run from anywhere; needs `git`.
# =============================================================================
require 'open3'
require 'optparse'
require_relative '../ci/_lib'

REGISTRY = File.join(LH::ROOT, '_data', 'agencies.yml')

def die(msg)
  warn "promote.rb: #{msg}"
  exit 2
end

def git(*args)
  out, err, status = Open3.capture3('git', '-C', LH::ROOT, *args)
  die "git #{args.first(2).join(' ')} failed: #{err.lines.first.to_s.strip}" unless status.success?
  out
end

opts = { authors: {}, date: Date.today.iso8601 }
parser = OptionParser.new do |o|
  o.banner = 'usage: promote.rb <site path> --pages DIR --collection NAME --url /NAME/ [--url-from /old/] [--author old=new] [--images DIR]'
  o.on('--pages DIR')       { |v| opts[:pages] = v.sub(%r{/+\z}, '') }
  o.on('--collection NAME') { |v| opts[:collection] = v }
  o.on('--url URL')         { |v| opts[:url] = v }
  o.on('--url-from URL')    { |v| opts[:url_from] = v }
  o.on('--author PAIR')     { |v| old, new = v.split('=', 2); opts[:authors][old] = new }
  o.on('--images DIR')      { |v| opts[:images] = v.sub(%r{/+\z}, '') }
  o.on('--date DATE')       { |v| opts[:date] = v }
end
parser.parse!
site_path = (ARGV.shift or die parser.banner).sub(%r{/+\z}, '')
%i[pages collection url].each { |k| die "--#{k} is required\n#{parser.banner}" unless opts[k] }
die "--collection #{opts[:collection].inspect}: lower-case letters, digits and hyphens" unless opts[:collection] =~ /\A[a-z0-9][a-z0-9-]*\z/
[opts[:url], opts[:url_from]].compact.each { |u| die "#{u.inspect}: a URL base starts and ends with /" unless u =~ %r{\A/.*/\z} }

registry = LH.yload(LH.read(REGISTRY))
site = (registry['agencies'] || []).flat_map { |a| a['sites'] || [] }.find { |s| s['path'] == site_path }
die "#{site_path} is not registered in _data/agencies.yml" unless site
die "#{site_path} is a mirror: its source is still written. Cut it over (custody: home) before publishing it here." unless site['custody'] == 'home'
die "#{site_path} is already published as the #{site['published']['collection']} collection" if site['published']

authors = LH.yload(LH.read(File.join(LH::ROOT, '_data', 'authors.yml'))) || {}
opts[:authors].each { |old, new| die "--author #{old}=#{new}: #{new.inspect} is not a key in _data/authors.yml" unless authors.key?(new) }

src  = File.join(site_path, opts[:pages])
dest = "pages/_#{opts[:collection]}"
die "#{src} is not a directory" unless Dir.exist?(File.join(LH::ROOT, src))
die "#{dest} already exists" if File.exist?(File.join(LH::ROOT, dest))

git('mv', src, dest)

# Rewrite the old URL base and the author keys, and nothing else: every other
# byte of a page is carried as it was.
pages = Dir.glob(File.join(LH::ROOT, dest, '**', '*.{md,markdown,html}')).sort
urls = bylines = 0
pages.each do |path|
  text = LH.read(path)
  out = text.dup
  if opts[:url_from]
    urls += out.scan(opts[:url_from]).size
    out = out.gsub(opts[:url_from], opts[:url])
  end
  # The byline is rewritten inside the front matter only, never in the body.
  if !opts[:authors].empty? && (m = out.match(/\A(---[ \t]*\r?\n)(.*?\n)(---[ \t]*\r?\n?)/m))
    front = m[2]
    opts[:authors].each do |old, new|
      front = front.sub(/^author:[ \t]*["']?#{Regexp.escape(old)}["']?[ \t]*$/) do
        bylines += 1
        "author: #{new}"
      end
    end
    out = m[1] + front + m[3] + m.post_match
  end
  File.write(path, out) unless out == text
end

images = 0
if opts[:images]
  from = File.join(site_path, opts[:images])
  to   = "assets/images/#{opts[:collection]}"
  die "#{from} is not a directory" unless Dir.exist?(File.join(LH::ROOT, from))
  die "#{to} already exists" if File.exist?(File.join(LH::ROOT, to))
  git('mv', from, to)
  images = Dir.glob(File.join(LH::ROOT, to, '**', '*')).count { |p| File.file?(p) }
end

site['published'] = { 'collection' => opts[:collection], 'url' => opts[:url], 'date' => opts[:date], 'pages' => pages.size }
LH.ywrite(REGISTRY, registry)

puts "#{site_path}: #{pages.size} pages -> #{dest}/, served under #{opts[:url]}"
puts "  rewrote #{urls} occurrences of #{opts[:url_from]} -> #{opts[:url]}" if opts[:url_from]
puts "  rewrote #{bylines} bylines (#{opts[:authors].map { |o, n| "#{o} -> #{n}" }.join(', ')})" unless opts[:authors].empty?
puts "  moved #{images} images -> assets/images/#{opts[:collection]}/" if opts[:images]
puts "Next: declare the #{opts[:collection]} collection and its defaults in _config.yml, then run scripts/ci/lint_agencies.rb."
