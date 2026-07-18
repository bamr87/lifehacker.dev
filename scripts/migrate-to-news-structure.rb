#!/usr/bin/env ruby
# =============================================================================
# scripts/migrate-to-news-structure.rb — collections -> news sections (issue #337)
# -----------------------------------------------------------------------------
# A deterministic, one-shot migrator adapted from year-of-ai's news migrator.
# It converts the `hacks` and `tools` collections and the flat Field Notes
# (`pages/_posts/*.md`) into the zer0-mistakes theme's news system:
#
#   pages/_hacks/<slug>.md         -> pages/_posts/hacks/<date>-<slug>.md
#   pages/_tools/<slug>.md         -> pages/_posts/tools/<date>-<slug>.md
#   pages/_posts/<date>-<slug>.md  -> pages/_posts/field-notes/<date>-<slug>.md
#
# For every item it: sets `categories:[<Section>]`, normalises the free-form
# `tags` down to the small reused per-section pill vocabulary (see
# news-enrichment.yml), keeps/repairs `preview`, and — for hacks/tools — pins an
# explicit `permalink:` to the item's OLD public URL so nothing 404s. Field
# Notes keep Jekyll's default dated posts permalink.
#
# It also generates the section index pages (news/<section>.md, category-driven
# so the theme's `section` layout aggregates by `categories`, not by a fragile
# path substring), the /news/ magazine landing (news/index.md),
# _data/navigation/posts.yml, and one self-contained neon SVG preview card per
# section (used when an item has no per-item image).
#
# Idempotent-ish: safe to re-run; it reads sources, (re)writes targets, removes
# the now-empty legacy dirs. Stdlib only.  Run: ruby scripts/migrate-to-news-structure.rb
# =============================================================================
require 'date'
require 'yaml'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
ENRICH = YAML.safe_load(File.read(File.join(ROOT, 'scripts', 'news-enrichment.yml')), permitted_classes: [Date])
SECTIONS = ENRICH['sections']
VOCAB    = ENRICH['tag_vocabulary']
SYN      = ENRICH['tag_synonyms']
DEFTAG   = ENRICH['default_tag']
OVERRIDE = ENRICH['tag_overrides'] || {}

# ── front-matter helpers ─────────────────────────────────────────────────────
def split_fm(raw)
  m = raw.match(/\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)\z/m)
  return [nil, raw] unless m
  fm = (YAML.safe_load(m[1], permitted_classes: [Date, Time]) rescue nil)
  [fm.is_a?(Hash) ? fm : nil, m[2] || '']
end

def q(s) # double-quoted YAML scalar
  '"' + s.to_s.gsub('\\', '\\\\\\\\').gsub('"', '\"') + '"'
end

def flow(arr) # flow sequence with bare scalars, e.g. [a, b, c]
  '[' + arr.map { |x| x.to_s }.join(', ') + ']'
end

# Emit front matter in a fixed, readable order; pass through unknown keys.
QUOTED = %w[title description excerpt verdict sub-title preview_caption].freeze
ORDER  = %w[title description date categories tags author verdict excerpt preview permalink featured].freeze
def dump_fm(fm)
  keys = ORDER + (fm.keys - ORDER)
  lines = []
  keys.each do |k|
    next unless fm.key?(k)
    v = fm[k]
    line =
      case k
      when 'categories', 'tags' then "#{k}: #{flow(Array(v))}"
      when 'date'               then "date: #{v.is_a?(Date) ? v.strftime('%Y-%m-%d') : v}"
      when 'featured'           then "featured: #{v ? 'true' : 'false'}"
      else
        if QUOTED.include?(k) || (v.is_a?(String) && (v.include?(':') || v.include?('#')) && k != 'preview' && k != 'permalink')
          "#{k}: #{q(v)}"
        elsif v.is_a?(Array) then "#{k}: #{flow(v)}"
        elsif v == true || v == false then "#{k}: #{v}"
        else "#{k}: #{v}"
        end
      end
    lines << line
  end
  "---\n" + lines.join("\n") + "\n---\n"
end

# Drop a single leading "# Title" H1 that duplicates the front-matter title.
def strip_leading_h1(body)
  lines = body.lstrip.lines
  return body if lines.empty?
  if lines.first =~ /\A#\s+\S/
    rest = lines[1..] || []
    rest.shift while rest.first && rest.first.strip.empty?
    return "\n" + rest.join
  end
  body
end

def preview_ok?(pv)
  return false if pv.nil? || pv.to_s.strip.empty?
  s = pv.to_s.sub(%r{\A/}, '')
  cand = s.start_with?('assets/') ? File.join(ROOT, s) : File.join(ROOT, 'assets', s)
  File.exist?(cand)
end

# ── tag normalisation (two-pass: map -> cap3 -> drop singleton pills) ─────────
def map_tags(section, tags, slug = nil)
  ovr = (OVERRIDE[section] || {})[slug]
  return ovr if ovr
  syn = SYN[section] || {}
  vocab = VOCAB[section]
  out = []
  Array(tags).each do |t|
    c = syn[t.to_s.downcase]
    out << c if c && !out.include?(c)
  end
  # order by vocabulary position, cap at 3
  out.sort_by { |c| vocab.index(c) || 99 }.first(3)
end

# ── collect + transform items ────────────────────────────────────────────────
sources = {
  'hacks'       => Dir.glob(File.join(ROOT, 'pages', '_hacks', '*.md')),
  'tools'       => Dir.glob(File.join(ROOT, 'pages', '_tools', '*.md')),
  'field-notes' => Dir.glob(File.join(ROOT, 'pages', '_posts', '*.md')) # flat only
}

items = [] # {section, src, slug, date, fm, body, pills}
sources.each do |section, files|
  files.sort.each do |src|
    fm, body = split_fm(File.read(src, encoding: 'UTF-8'))
    unless fm
      warn "SKIP (no front matter): #{src}"
      next
    end
    base = File.basename(src, '.md')
    date = fm['date']
    date = (Date.parse(date.to_s) rescue nil) unless date.is_a?(Date)
    if date.nil?
      warn "SKIP (no/invalid date): #{src}"
      next
    end
    slug = base.sub(/\A\d{4}-\d{2}-\d{2}-/, '') # strip date prefix for field notes
    items << { section: section, src: src, slug: slug, date: date, fm: fm,
               body: body, pills: map_tags(section, fm['tags'], slug) }
  end
end

# Pass 2: drop pills that would be singletons across their section, default if empty.
counts = Hash.new(0)
items.each { |it| it[:pills].each { |p| counts["#{it[:section]}/#{p}"] += 1 } }
defaulted = []
items.each do |it|
  kept = it[:pills].select { |p| counts["#{it[:section]}/#{p}"] >= 2 }
  if kept.empty?
    kept = [DEFTAG[it[:section]]]
    defaulted << "#{it[:section]}/#{it[:slug]}"
  end
  it[:pills] = kept
end

# ── write migrated posts ─────────────────────────────────────────────────────
written = Hash.new(0)
items.each do |it|
  sec = SECTIONS[it[:section]]
  fm  = it[:fm].dup
  fm.delete('collection')                    # no longer a Jekyll collection
  fm['categories'] = [sec['name']]           # exactly [<Section>]
  fm['tags']       = it[:pills]
  # preview: keep working per-item image, else the section card
  unless preview_ok?(fm['preview'])
    fm['preview'] = "/images/previews/section-#{it[:section]}.svg"
  end
  # permalink: hacks/tools pin their old URL; field notes keep the dated default
  if sec['permalink_pattern']
    fm['permalink'] = sec['permalink_pattern'].sub(':slug', it[:slug])
  end
  fm['featured'] = true if sec['featured'] == it[:slug]

  body = strip_leading_h1(it[:body])
  out_dir = File.join(ROOT, 'pages', '_posts', it[:section])
  FileUtils.mkdir_p(out_dir)
  out = File.join(out_dir, "#{it[:date].strftime('%Y-%m-%d')}-#{it[:slug]}.md")
  File.write(out, dump_fm(fm) + body)
  File.delete(it[:src]) unless File.expand_path(it[:src]) == File.expand_path(out)
  written[it[:section]] += 1
end

# remove now-empty legacy collection dirs
%w[_hacks _tools].each do |d|
  dir = File.join(ROOT, 'pages', d)
  Dir.rmdir(dir) if Dir.exist?(dir) && (Dir.entries(dir) - %w[. ..]).empty?
end

# ── section SVG preview cards (self-contained neon gradient) ──────────────────
FileUtils.mkdir_p(File.join(ROOT, 'assets', 'images', 'previews'))
def svg_card(title, subtitle, c1, c2)
  gid = "g#{title.gsub(/[^a-z0-9]/i, '')}"
  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630" role="img" aria-label="#{title}">
      <defs>
        <linearGradient id="#{gid}" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="#{c1}"/>
          <stop offset="1" stop-color="#{c2}"/>
        </linearGradient>
        <pattern id="#{gid}s" width="40" height="40" patternUnits="userSpaceOnUse">
          <path d="M0 40 L40 40 M40 0 L40 40" stroke="#ffffff" stroke-opacity="0.06" stroke-width="1"/>
        </pattern>
      </defs>
      <rect width="1200" height="630" fill="#0a0a0f"/>
      <rect width="1200" height="630" fill="url(##{gid})" opacity="0.92"/>
      <rect width="1200" height="630" fill="url(##{gid}s)"/>
      <text x="80" y="500" fill="#ffffff" font-family="ui-monospace, Menlo, Consolas, monospace" font-size="110" font-weight="700">#{title}</text>
      <text x="84" y="560" fill="#ffffff" fill-opacity="0.82" font-family="Helvetica, Arial, sans-serif" font-size="34">#{subtitle}</text>
      <text x="80" y="130" fill="#ffffff" fill-opacity="0.72" font-family="ui-monospace, Menlo, monospace" font-size="30">lifehacker.dev / news</text>
    </svg>
  SVG
end
SECTIONS.each do |slug, sec|
  c1, c2 = sec['gradient']
  File.write(File.join(ROOT, 'assets', 'images', 'previews', "section-#{slug}.svg"),
             svg_card(sec['title'], 'lifehacker.dev', c1, c2))
end

# ── section index pages (regular pages, category-driven) ─────────────────────
FileUtils.mkdir_p(File.join(ROOT, 'news'))
SECTIONS.each do |slug, sec|
  front = "---\n" \
          "layout: section\n" \
          "title: #{q(sec['title'])}\n" \
          "description: #{q(sec['description'])}\n" \
          "permalink: /news/#{slug}/\n" \
          "category: #{q(sec['name'])}\n" \
          "icon: #{sec['icon']}\n" \
          "section_style: #{sec['section_style']}\n" \
          "sidebar: false\n" \
          "---\n"
  File.write(File.join(ROOT, 'news', "#{slug}.md"), front)
end

# ── /news/ magazine landing ──────────────────────────────────────────────────
landing = <<~MD
  ---
  layout: news
  title: "News"
  description: "Every hack, honest tool review, and field note — the whole newsroom in one place."
  permalink: /news/
  section_style: magazine
  sidebar: false
  ---
MD
File.write(File.join(ROOT, 'news', 'index.md'), landing)

# ── _data/navigation/posts.yml (section list the news/section layouts read) ──
nav = +"# News sections — read by the theme's `news` and `section` layouts.\n" \
       "# Each `title` MUST equal the posts' `categories:[<title>]` value; the\n" \
       "# layouts group posts by `post.categories contains item.title`.\n" \
       "# Generated by scripts/migrate-to-news-structure.rb (issue #337).\n\n"
SECTIONS.each do |slug, sec|
  nav << "- title: #{sec['name']}\n"
  nav << "  icon: #{sec['nav_icon']}\n"
  nav << "  url: /news/#{slug}/\n"
  nav << "  description: #{q(sec['description'])}\n"
end
File.write(File.join(ROOT, '_data', 'navigation', 'posts.yml'), nav)

# ── report ───────────────────────────────────────────────────────────────────
puts "migrated: #{written.map { |k, v| "#{k}=#{v}" }.join('  ')}  total=#{written.values.sum}"
puts "generated: news/index.md, news/{hacks,tools,field-notes}.md, _data/navigation/posts.yml, 3 SVG cards"
puts "\npill distribution:"
%w[hacks tools field-notes].each do |s|
  dist = counts.select { |k, _| k.start_with?("#{s}/") }.map { |k, v| "#{k.split('/').last}=#{v}" }
  puts "  #{s}: #{dist.sort.join('  ')}"
end
unless defaulted.empty?
  puts "\nITEMS THAT FELL BACK TO default_tag (#{defaulted.size}) — review these:"
  defaulted.sort.each { |d| puts "  #{d}" }
end

# collision tripwire: a post whose path substring-matches ANOTHER section name
# (would only matter if a section page used path-based discovery, which ours do
# not — but flag it so a future refactor doesn't reintroduce the bug).
names = SECTIONS.keys
coll = []
items.each do |it|
  path = "pages/_posts/#{it[:section]}/#{it[:date].strftime('%Y-%m-%d')}-#{it[:slug]}.md"
  names.each { |n| coll << "#{path} ~ #{n}" if n != it[:section] && path.include?(n) }
end
unless coll.empty?
  puts "\nPATH-SUBSTRING COLLISIONS (informational; section pages use category matching):"
  coll.each { |c| puts "  #{c}" }
end
