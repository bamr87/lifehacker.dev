#!/usr/bin/env ruby
# =============================================================================
# check_drift.rb — catch the hand-authored artifacts that rot as content grows
# -----------------------------------------------------------------------------
# This repo can't run the theme's index/sitemap plugins on GitHub Pages, so
# search.json and parts of sitemap.md are hand-authored and drift away from the
# real collections. This check is the tripwire. It also asserts every backlog
# item flipped to `done` actually points at a page that exists.
#
# It resolves URLs from SOURCE front matter (so it runs anywhere, no build
# needed) and, when a built _site/ is present (CI, after build.sh), additionally
# confirms the generated HTML exists. Stdlib only.
#   ruby scripts/ci/check_drift.rb
# =============================================================================
require_relative '_lib'

SITE = File.join(LH::ROOT, '_site')
site_built = Dir.exist?(SITE)
findings = []

def norm(u)
  u = u.to_s.strip
  return u if u.empty?
  u = "/#{u}" unless u.start_with?('/')
  # Leave file-style URLs (search.json, sitemap.xml) alone; slash-terminate dirs.
  u += '/' unless u.end_with?('/') || u =~ /\.[a-z0-9]+\z/i
  u
end

# Compute a page's URL: explicit front-matter permalink wins, else the
# collection's permalink pattern from _config.yml.
def url_for(fm, path, coll)
  return norm(fm['permalink']) if fm && fm['permalink']
  name = File.basename(path, '.md')
  case coll
  when 'posts'
    name =~ /\A(\d{4})-(\d{2})-(\d{2})-(.+)\z/ ? "/posts/#{$1}/#{$2}/#{$3}/#{$4}/" : nil
  when 'hacks' then "/hacks/#{name}/"
  when 'tools' then "/tools/#{name}/"
  when 'about' then "/about/#{name}/"
  when 'docs'  then "/docs/#{name}/"
  else "/#{name}/"
  end
end

# --- Build the set of URLs the site actually publishes (from source) ---------
urls = {} # normalized url => repo-relative source file
{
  'pages/_hacks' => 'hacks', 'pages/_tools' => 'tools', 'pages/_posts' => 'posts',
  'pages/_docs' => 'docs', 'pages/_about' => 'about'
}.each do |dir, coll|
  Dir.glob(File.join(LH::ROOT, dir, '*.md')).each do |f|
    fm, = LH.parse(f)
    u = url_for(fm, f, coll)
    urls[norm(u)] = LH.rel(f) if u
  end
end
# Top-level pages that declare an explicit permalink (search.md, index.md, ...).
Dir.glob(File.join(LH::ROOT, '*.{md,html}')).each do |f|
  fm, = LH.parse(f)
  urls[norm(fm['permalink'])] = LH.rel(f) if fm && fm['permalink']
end

# Does the built site contain this URL as a real page?
def site_has?(site, url)
  return true unless Dir.exist?(site)
  candidates = []
  if url.end_with?('/')
    candidates << File.join(site, url, 'index.html')
  else
    candidates << File.join(site, url)
  end
  candidates.any? { |p| File.exist?(p) }
end

# A URL resolves if it's a known source page AND (when built) the HTML exists.
def resolves?(url, urls, site, site_built)
  return false unless urls.key?(url)
  return true unless site_built
  site_has?(site, url)
end

# --- 1. Backlog integrity ----------------------------------------------------
backlog = (LH.yload(LH.read(File.join(LH::ROOT, '_data', 'backlog.yml'))) rescue {})
items = backlog.is_a?(Hash) ? (backlog['backlog'] || []) : []
items.each do |it|
  next unless it.is_a?(Hash) && it['status'].to_s == 'done'
  id  = it['id'] || '(no id)'
  pub = it['published'].to_s
  if pub.empty?
    findings << LH.finding(check_id: 'drift', severity: 'error',
                           rule: 'backlog-done-without-published', file: '_data/backlog.yml',
                           evidence: "#{id} is status:done but has no `published:` path")
  elsif !resolves?(norm(pub), urls, SITE, site_built)
    findings << LH.finding(check_id: 'drift', severity: 'error',
                           rule: 'backlog-published-deadlink', file: '_data/backlog.yml',
                           evidence: "#{id} published: #{pub} resolves to no page")
  end
end

# --- 2. Sitemap hand-authored "About & Docs" list ----------------------------
# The Hacks/Tools/Field-Notes sections are Liquid-generated and self-heal; only
# the hand-authored <ul> under "## About" can rot. Check those links resolve.
sitemap = (LH.read(File.join(LH::ROOT, 'sitemap.md')) rescue '')
about_block = sitemap[/^##\s*About.*\z/m].to_s
about_block.scan(/href="([^"]+)"/).flatten.each do |href|
  next if href.include?('{')          # Liquid-templated (self-healing) — not hand-authored drift
  next unless href.start_with?('/')   # skip external / anchors
  u = norm(href)
  next if resolves?(u, urls, SITE, site_built)
  findings << LH.finding(check_id: 'drift', severity: 'error',
                         rule: 'sitemap-deadlink', file: 'sitemap.md',
                         evidence: "hand-authored sitemap link #{href} resolves to no page")
end

# --- 3. search.json was actually generated (only checkable post-build) -------
if site_built
  sj = File.join(SITE, 'search.json')
  if !File.exist?(sj)
    findings << LH.finding(check_id: 'drift', severity: 'error',
                           rule: 'search-json-missing', file: 'search.json',
                           evidence: '_site/search.json was not generated by the build')
  elsif File.read(sj, encoding: 'UTF-8').strip.length < 3
    findings << LH.finding(check_id: 'drift', severity: 'error',
                           rule: 'search-json-empty', file: 'search.json',
                           evidence: '_site/search.json built empty — the search layout produced no index')
  end
else
  findings << LH.finding(check_id: 'drift', severity: 'info',
                         rule: 'search-json-unchecked', file: 'search.json',
                         evidence: 'no _site/ present; search.json content not verified (build first)')
end

errs = LH.write('drift', findings)
exit(errs.zero? ? 0 : 1)
