#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# migrate-to-news-structure.rb — convert a flat year repo into the theme's
# "news" section layout (zer0-mistakes `news` / `section` / `article` layouts).
# =============================================================================
#
# WHAT IT DOES (see ARCHITECTURE.md / ADR for the rationale)
#
# The year repos historically stored content flat at the repo root:
#     <category-slug>/<topic-slug>.md          (title/date/category front matter)
#     <category-slug>/index.md                 (generated category index)
#     INDEX.md, TIMELINE.md                    (generated master index/timeline)
#     README.md                                (homepage + knowledge table)
#
# The shared theme ships a full "news" system: `_posts/<section>/` directories
# rendered at /news/<section>/ by the `section` layout, a /news/ magazine
# landing (`news` layout), and posts whose `tags` become the section's
# collapsible sub-topic sidebar / filter pills. This script maps the year's
# taxonomy CATEGORIES onto news SECTIONS and each topic file onto a POST:
#
#     <category-slug>/<topic>.md   ->   _posts/<category-slug>/<date>-<topic>.md
#         front matter: categories: [<Category Name>], tags: [...], excerpt, preview
#     (new) _posts/<category-slug>/<year>-01-01-index.md   layout: section  -> /news/<slug>/
#     (new) news.md                                        layout: news     -> /news/
#     (new) index.html                                     layout: news     -> /   (homepage)
#     (new) _data/navigation/posts.yml                     the section list
#     (rewritten) _data/navigation/main.yml                a News dropdown
#     (new) assets/images/previews/*.svg                   self-contained card art
#     (new) favicon.ico + assets/images/favicon.svg        browser identity
#
# The old generated artifacts (category index.md files, INDEX.md) are removed
# because the section pages + /news/ landing supersede them. README.md and
# TIMELINE.md are kept, with their internal article links rewritten to the new
# post URLs.
#
# The theme's `article` layout renders page.title and an auto "Related Posts"
# block (by shared tags), so this script strips each body's duplicate `# Title`
# H1 and the old generated `## Related` crossref block.
#
# USAGE
#     ruby scripts/migrate-to-news-structure.rb \
#         --repo /path/to/year-repo \
#         --enrichment enrich-2005.yml \
#         [--year 2005] [--section-style grid] [--news-style magazine] \
#         [--homepage news|readme] [--dry-run]
#
# The enrichment YAML supplies the section metadata (name/icon/description/
# featured) and per-article tags; excerpts are derived from each article's
# `## Summary` paragraph. The script is deterministic and idempotent-safe on a
# fresh checkout; re-running after a partial run is not supported (run on a
# clean clone).
# =============================================================================

require "yaml"
require "fileutils"
require "optparse"
require "date"
require "pathname"

# Content carries UTF-8 (em dashes, accents); don't let an ASCII locale break
# regex/IO on it.
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

options = {
  section_style: "grid",
  news_style: "magazine",
  homepage: "news",
  dry_run: false,
}
OptionParser.new do |o|
  o.banner = "Usage: migrate-to-news-structure.rb --repo PATH --enrichment FILE [options]"
  o.on("--repo PATH", "Path to the year repo working tree") { |v| options[:repo] = v }
  o.on("--enrichment FILE", "Enrichment YAML (sections + per-article tags)") { |v| options[:enrichment] = v }
  o.on("--year YEAR", "Subject year (defaults to repo basename)") { |v| options[:year] = v }
  o.on("--org ORG", "GitHub org for the Source nav link (default: from the repo's _config.yml)") { |v| options[:org] = v }
  o.on("--section-style STYLE", "grid | list | magazine (default grid)") { |v| options[:section_style] = v }
  o.on("--news-style STYLE", "magazine | grid | list for /news/ (default magazine)") { |v| options[:news_style] = v }
  o.on("--homepage MODE", "news = /news/ magazine is the homepage; readme = keep README") { |v| options[:homepage] = v }
  o.on("--dry-run", "Report actions without writing") { options[:dry_run] = true }
end.parse!

abort "--repo is required" unless options[:repo]
abort "--enrichment is required" unless options[:enrichment]

REPO = File.expand_path(options[:repo])
abort "repo not found: #{REPO}" unless Dir.exist?(REPO)
enrich = YAML.load_file(File.expand_path(options[:enrichment]))
YEAR = (options[:year] || File.basename(REPO)).to_s

# Derive the GitHub org for the "Source" nav link from the target repo's own
# config, so this migrator carries no org/concept literal of its own.
def detect_org(repo)
  cfg = File.join(repo, "_config.yml")
  return nil unless File.exist?(cfg)

  text = File.read(cfg)
  text[/^github_user:\s*["']?([^"'\s]+)/, 1] || text[%r{^repository:\s*["']?([^"'/\s]+)}, 1]
end
ORG = options[:org] || detect_org(REPO) || "your-org"
SECTION_STYLE = options[:section_style]
NEWS_STYLE = options[:news_style]
HOMEPAGE = options[:homepage]
DRY = options[:dry_run]

sections = enrich.fetch("sections")           # ordered slug => {name, icon, description, featured}
tag_map  = enrich.fetch("tags", {})           # "slug/article" => [tags]
site_meta = enrich.fetch("site", {})

log = []
def say(log, msg) = (log << msg; puts msg)

# ---- helpers ---------------------------------------------------------------

# Split a Jekyll markdown file into [front_matter_hash, body_string].
def split_front_matter(text)
  if text =~ /\A---\s*\n(.*?)\n---\s*\n?(.*)\z/m
    [YAML.safe_load($1, permitted_classes: [Date, Time]) || {}, $2]
  else
    [{}, text]
  end
end

# Derive a card excerpt from the article body: the first paragraph after the
# `## Summary` heading (falls back to the first plain paragraph). Whitespace
# collapsed; truncated on a word boundary so it stays meta-description sized.
def derive_excerpt(body)
  para = nil
  if body =~ /^##\s+Summary\s*\n+(.+?)(?:\n\s*\n|\z)/m
    para = $1
  else
    body.each_line do |line|
      s = line.strip
      next if s.empty? || s.start_with?("#", "**", "<!--", "|", "-", ">")
      para = s
      break
    end
  end
  return "" unless para
  text = para.gsub(/\s+/, " ").strip
  text = text.gsub(/\[([^\]]+)\]\([^)]*\)/, '\1') # unwrap markdown links
  return text if text.length <= 300

  cut = text[0, 300]
  cut = cut.sub(/\s+\S*\z/, "").rstrip
  "#{cut}…"
end

# Remove the leading `# Title` H1 and the redundant `**Category**:` line, and
# strip the generated `## Related` crossref marker block.
def clean_body(body)
  b = body.dup
  b = b.sub(/\A\s*#\s+.+?\n/, "")                       # leading H1
  b = b.sub(/\A\s*\*\*Category\*\*:.*?\n/, "")          # redundant category line
  b = b.gsub(
    /\n?<!--\s*BEGIN GENERATED:\s*crossrefs.*?END GENERATED:\s*crossrefs\s*-->\s*/m, "\n"
  )
  # Drop any remaining (hand-written) `## Related` section up to the next
  # heading/EOF — the `article` layout renders related posts by shared tags.
  b = b.gsub(/^##\s+Related\b.*?(?=^##\s|\z)/m, "")
  b.strip + "\n"
end

def front_matter(hash)
  # Psych handles quoting/escaping; line_width -1 keeps long scalars (excerpts)
  # on one line. Key order follows the hash's insertion order. Dates passed as
  # Date objects emit as plain ISO (YYYY-MM-DD), per the repo's date invariant.
  Psych.dump(hash, line_width: -1) + "---\n"
end

# Rewrite inline relative `*.md` links in a body to the moved target's new post
# URL. `old_dir` is the article's original section slug (its old directory);
# links are resolved relative to it. External/absolute/already-liquid links and
# links whose target isn't in the map are left untouched.
def rewrite_body_links(body, old_dir, url_map)
  body.gsub(/\]\((?!https?:|\/|\{\{)([^)#]+?\.md)(#[^)]*)?\)/) do
    target = Regexp.last_match(1)
    anchor = Regexp.last_match(2)
    resolved = (Pathname.new(old_dir) + target).cleanpath.to_s
    if (u = url_map[resolved])
      "]({{ '#{u}' | relative_url }}#{anchor})"
    else
      "](#{target}#{anchor})"
    end
  end
end

def write(path, content, log, dry)
  say(log, "  write   #{path.sub(REPO + '/', '')}")
  return if dry

  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def remove(path, log, dry)
  return unless File.exist?(path)

  say(log, "  remove  #{path.sub(REPO + '/', '')}")
  File.delete(path) unless dry
end

# Prepend front matter to a root doc (README/TIMELINE) that otherwise has none,
# so it renders reliably (with Liquid processed) at a clean permalink instead of
# being copied as a static file.
def prepend_front_matter(path, hash, log, dry)
  return unless File.exist?(path)

  text = File.read(path)
  return if text.start_with?("---\n") # already has front matter

  say(log, "  frontm  #{path.sub(REPO + '/', '')}")
  File.write(path, front_matter(hash) + "\n" + text) unless dry
end

# ---- SVG preview placeholders ----------------------------------------------

SECTION_COLORS = {
  # 2000s taxonomy
  "history-politics"   => %w[#7c3aed #4c1d95],
  "science-technology" => %w[#0ea5e9 #075985],
  "arts-culture"       => %w[#ec4899 #9d174d],
  "society-economics"  => %w[#f59e0b #92400e],
  "people"             => %w[#10b981 #065f46],
  # 18th-century taxonomy (1776–1778)
  "politics"           => %w[#7c3aed #4c1d95],
  "military"           => %w[#dc2626 #7f1d1d],
  "science"            => %w[#0ea5e9 #075985],
  "arts"               => %w[#ec4899 #9d174d],
  "economics"          => %w[#f59e0b #92400e],
  "default"            => %w[#334155 #0f172a],
}

def xml_escape(str)
  str.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
end

def preview_svg(label, slug)
  c1, c2 = SECTION_COLORS[slug] || SECTION_COLORS["default"]
  gid = "g_#{slug.gsub(/[^a-z0-9]/, '')}"
  label = xml_escape(label) # raw & in "History & Politics" is invalid XML -> broken <img>
  # Explicit width/height give the SVG intrinsic dimensions — without them
  # Chromium renders nothing under `object-fit: cover` at card sizes. Text is
  # centered so it survives cover-cropping into tall/narrow containers.
  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="800" height="400" viewBox="0 0 800 400" preserveAspectRatio="xMidYMid slice" role="img" aria-label="#{label}">
      <defs>
        <linearGradient id="#{gid}" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="#{c1}"/>
          <stop offset="1" stop-color="#{c2}"/>
        </linearGradient>
      </defs>
      <rect width="800" height="400" fill="url(##{gid})"/>
      <text x="400" y="205" text-anchor="middle" fill="#ffffff" font-family="Georgia, 'Times New Roman', serif"
            font-size="150" font-weight="700" opacity="0.95">#{YEAR}</text>
      <text x="400" y="262" text-anchor="middle" fill="#ffffff" font-family="Helvetica, Arial, sans-serif"
            font-size="30" font-weight="500" opacity="0.92" letter-spacing="1">#{label}</text>
    </svg>
  SVG
end

# =============================================================================
# 1. Move + rewrite article files; build the old->new URL map.
# =============================================================================

say(log, "== migrating #{REPO} (year #{YEAR}) ==")

# Pass 1 — enumerate every article, compute its new post URL, and build the
# old->new map BEFORE any rewriting (so inline cross-links to articles that
# sort later still resolve).
url_map = {} # "section/article.md" (repo-relative old path) => "/section/yyyy/mm/dd/article/"
queue = []
sections.each do |slug, meta|
  dir = File.join(REPO, slug)
  unless Dir.exist?(dir)
    say(log, "!! section dir missing, skipping: #{slug}")
    next
  end
  Dir.glob(File.join(dir, "*.md")).sort.each do |file|
    base = File.basename(file)
    next if base == "index.md"

    fm, body = split_front_matter(File.read(file))
    article_slug = File.basename(base, ".md")
    date = fm["date"]
    date = Date.parse(date.to_s) unless date.is_a?(Date)

    # Clean, hierarchical permalink under the section (set explicitly on each
    # post below) — avoids Jekyll's `pretty` scheme deriving ugly, space/&
    # encoded URLs from the category name.
    url_map["#{slug}/#{base}"] = "/news/#{slug}/#{article_slug}/"
    queue << { slug: slug, meta: meta, file: file, base: base,
               article_slug: article_slug, date: date, fm: fm, body: body }
  end
end

# Pass 2 — rewrite bodies (inline cross-links + cleanup) and move each file.
queue.each do |a|
  slug = a[:slug]
  front = {
    "title"      => a[:fm]["title"].to_s,
    "date"       => a[:date],
    "categories" => [a[:meta]["name"]],
    "tags"       => tag_map["#{slug}/#{a[:article_slug]}"] || [],
    "excerpt"    => derive_excerpt(a[:body]),
    "preview"    => "/images/previews/#{slug}.svg",
    "permalink"  => "/news/#{slug}/#{a[:article_slug]}/",
  }
  front["featured"] = true if a[:meta]["featured"].to_s == a[:article_slug]

  body = rewrite_body_links(clean_body(a[:body]), slug, url_map)
  new_path = File.join(REPO, "_posts", slug, "#{a[:date].strftime('%Y-%m-%d')}-#{a[:article_slug]}.md")
  write(new_path, front_matter(front) + "\n" + body, log, DRY)
  remove(a[:file], log, DRY)
end

# Old generated category indexes + master index -> superseded by section pages.
sections.each_key do |slug|
  dir = File.join(REPO, slug)
  remove(File.join(dir, "index.md"), log, DRY)
  Dir.rmdir(dir) if !DRY && Dir.exist?(dir) && Dir.empty?(dir)
end
remove(File.join(REPO, "INDEX.md"), log, DRY)

# =============================================================================
# 2. Section index posts (layout: section) -> /news/<slug>/
# =============================================================================

sections.each do |slug, meta|
  icon = meta["icon"].to_s.sub(/\Abi-/, "") # section layout wants the bare name
  front = {
    "layout"        => "section",
    "title"         => meta["name"],
    "category"      => meta["name"],
    "categories"    => [meta["name"]],
    "tags"          => [slug],
    "icon"          => icon,
    "description"   => meta["description"].to_s,
    "section_style" => SECTION_STYLE,
    "index"         => true,
    "sitemap"       => false,
    "permalink"     => "/news/#{slug}/",
    "preview"       => "/images/previews/#{slug}.svg",
    "date"          => Date.new(YEAR.to_i, 1, 1),
  }
  body = "Every #{meta['name']} article in the #{YEAR} knowledge base. " \
         "Use the topic filters to narrow by sub-topic.\n"
  write(File.join(REPO, "_posts", slug, "#{YEAR}-01-01-index.md"), front_matter(front) + "\n" + body, log, DRY)
end

# =============================================================================
# 3. /news/ landing + homepage
# =============================================================================

news_front = {
  "layout"        => "news",
  "title"         => "#{site_meta['title'] || "The Year #{YEAR}"} — Newsroom",
  "description"   => site_meta["tagline"].to_s,
  "section_style" => NEWS_STYLE,
  "permalink"     => "/news/",
}
write(File.join(REPO, "news.md"), front_matter(news_front) + "\n" +
  "Browse the year #{YEAR} as a living newsroom — every article, grouped into sections.\n", log, DRY)

if HOMEPAGE == "news"
  home_front = {
    "layout"        => "news",
    "title"         => site_meta["title"] || "The Year #{YEAR}",
    "description"   => site_meta["tagline"].to_s,
    "section_style" => NEWS_STYLE,
    "permalink"     => "/",
  }
  write(File.join(REPO, "index.html"), front_matter(home_front), log, DRY)
end

# =============================================================================
# 4. Navigation data
# =============================================================================

posts_nav = sections.map do |slug, meta|
  { "title" => meta["name"], "icon" => meta["icon"], "url" => "/news/#{slug}/",
    "description" => meta["description"] }
end
write(File.join(REPO, "_data", "navigation", "posts.yml"),
      "# Sections shown by the theme's news + section layouts (site.data.navigation.posts).\n" \
      "# Generated by scripts/migrate-to-news-structure.rb — regenerate; do not hand-edit.\n" +
      Psych.dump(posts_nav, line_width: -1).sub(/\A---\n/, ""), log, DRY)

main_nav = [
  { "title" => "Home", "icon" => "bi-house", "url" => "/" },
  { "title" => "News", "icon" => "bi-newspaper", "url" => "/news/",
    "children" => sections.map { |slug, meta| { "title" => meta["name"], "url" => "/news/#{slug}/" } } },
  { "title" => "Timeline of #{YEAR}", "icon" => "bi-clock-history", "url" => "/TIMELINE/" },
  { "title" => "Index", "icon" => "bi-list-ul", "url" => "/knowledge-index/" },
  { "title" => "Source", "icon" => "bi-github", "url" => "https://github.com/#{ORG}/#{YEAR}" },
]
write(File.join(REPO, "_data", "navigation", "main.yml"),
      "# Main navigation — used by the zer0-mistakes navbar/sidebar (nav: main).\n" \
      "# Generated by scripts/migrate-to-news-structure.rb.\n" +
      Psych.dump(main_nav, line_width: -1).sub(/\A---\n/, ""), log, DRY)

# =============================================================================
# 5. SVG preview placeholders
# =============================================================================

sections.each do |slug, meta|
  write(File.join(REPO, "assets", "images", "previews", "#{slug}.svg"),
        preview_svg(meta["name"], slug), log, DRY)
end
write(File.join(REPO, "assets", "images", "previews", "default.svg"),
      preview_svg("The Year #{YEAR}", "default"), log, DRY)

# Browser identity. The theme's _includes/core/favicon.html always emits the
# `favicon.ico` link and assumes the consuming site carries one at its root;
# jekyll-remote-theme copies only _layouts/_includes/_sass/assets, so the
# theme's own root favicon.ico never reaches a member. Without this every
# member 404s on /<year>/favicon.ico.
favicon_script = File.join(__dir__, "generate-favicon.rb")
if File.exist?(favicon_script)
  cmd = ["ruby", favicon_script, "--repo", REPO, "--label", YEAR.to_s]
  cmd << "--dry-run" if DRY
  say(log, "  favicon favicon.ico + assets/images/favicon.svg")
  system(*cmd, out: File::NULL) || say(log, "  WARN    generate-favicon.rb failed; favicon not written")
else
  say(log, "  WARN    scripts/generate-favicon.rb missing; favicon not written")
end

# =============================================================================
# 6. Rewrite internal article links in README.md and TIMELINE.md
# =============================================================================

def rewrite_links(path, url_map, log, dry)
  return unless File.exist?(path)

  text = File.read(path)
  changed = 0
  url_map.each do |old_rel, new_url|
    # Match ](section/article.md) and ](./section/article.md)
    text = text.gsub(/\]\(\.?\/?#{Regexp.escape(old_rel)}\)/) do
      changed += 1
      "]({{ '#{new_url}' | relative_url }})"
    end
  end
  # Old category index / bare category links -> /news/<slug>/
  text = text.gsub(%r{\]\(\.?/?([a-z0-9-]+)/index\.md\)}) { "]({{ '/news/#{$1}/' | relative_url }})" }
  text = text.gsub(%r{\]\(INDEX\.md\)}, "]({{ '/news/' | relative_url }})")
  if changed.positive? || text != File.read(path)
    say(log, "  relink  #{path.sub(REPO + '/', '')} (#{changed} article links)")
    File.write(path, text) unless dry
  end
end

rewrite_links(File.join(REPO, "README.md"), url_map, log, DRY)
rewrite_links(File.join(REPO, "TIMELINE.md"), url_map, log, DRY)

# README/TIMELINE carry no front matter; give them explicit front matter so they
# render (Liquid processed) at stable permalinks. README becomes the browsable
# "knowledge index"; the /news/ magazine is the homepage.
prepend_front_matter(File.join(REPO, "README.md"),
  { "title" => "#{site_meta['title'] || "The Year #{YEAR}"} — Knowledge Index",
    "permalink" => "/knowledge-index/",
    "description" => "The full #{YEAR} knowledge table — every notable event, linked to its article." },
  log, DRY)
prepend_front_matter(File.join(REPO, "TIMELINE.md"),
  { "layout" => "default", "title" => "Timeline of #{YEAR}", "permalink" => "/TIMELINE/" },
  log, DRY)

# =============================================================================
# 7. Patch _config.yml: article layout for posts (with the hero opted in),
#    card/social fallback image, browser identity (logo + favicon), and (when
#    the /news/ magazine is the homepage) drop jekyll-readme-index so
#    index.html owns "/". Idempotent string patches.
# =============================================================================

cfg_path = File.join(REPO, "_config.yml")
if File.exist?(cfg_path)
  cfg = File.read(cfg_path)
  before = cfg.dup

  cfg = cfg.sub(/^[ \t]*-[ \t]*jekyll-readme-index[ \t]*\r?\n/, "") if HOMEPAGE == "news"

  unless cfg.match?(/^teaser:/)
    line = "teaser: /images/previews/default.svg\nog_image: /images/previews/default.svg\n"
    cfg = cfg.match?(/^permalink:.*\n/) ? cfg.sub(/^(permalink:.*\n)/) { "#{$1}#{line}" } : line + cfg
  end

  # Browser identity. Guarded on the key it writes, so this is also the repair
  # path for a member migrated before these settings existed.
  unless cfg.include?("favicon:")
    identity =
      "\n" \
      "# Masthead brand mark. Unset, the theme's header renders an <img> with an\n" \
      "# empty src, which resolves to the baseurl itself and shows as broken.\n" \
      "logo: /assets/images/favicon.svg\n" \
      "\n" \
      "# Browser identity. The theme's core/favicon.html always emits the `ico`\n" \
      "# link and assumes the site carries a favicon at its root; remote_theme\n" \
      "# ships only _layouts/_includes/_sass/assets, so the theme's own never\n" \
      "# arrives. Assets minted by the hub's scripts/generate-favicon.rb.\n" \
      "favicon:\n" \
      "  ico: /favicon.ico\n" \
      "  svg: /assets/images/favicon.svg\n" \
      "\n"
    cfg = cfg.match?(/^og_image:.*\n/) ? cfg.sub(/^(og_image:.*\n)/) { "#{$1}#{identity}" } : cfg + identity
  end

  # The article layout renders its top-of-page hero from page.preview only for
  # featured/breaking posts unless a post opts in (theme issue #303). Every
  # article this script writes carries a preview, so opt the collection in.
  hero_comment =
    "# The article layout renders the top-of-page hero from page.preview only\n" \
    "# for featured/breaking posts unless a post opts in. Every article here\n" \
    "# carries a preview, so opt the collection in; the layout still guards on\n" \
    "# page.preview, so a post without one simply renders no hero.\n"

  if cfg.include?("type: posts")
    # Already migrated — inject the opt-in into the existing posts default.
    unless cfg.include?("show_hero")
      cfg = cfg.sub(/^([ \t]*)layout: article[ \t]*\r?\n/) do
        indent = Regexp.last_match(1)
        "#{Regexp.last_match(0)}" +
          hero_comment.each_line.map { |l| "#{indent}#{l}" }.join +
          "#{indent}show_hero: true\n"
      end
    end
  else
    posts_default =
      "  - scope:\n" \
      "      path: \"\"\n" \
      "      type: posts\n" \
      "    values:\n" \
      "      layout: article\n" +
      hero_comment.each_line.map { |l| "      #{l}" }.join +
      "      show_hero: true\n" \
      "      author_profile: false\n" \
      "      read_time: true\n" \
      "      share: true\n" \
      "      comments: false\n" \
      "      related: true\n"
    if cfg.match?(/^defaults:[ \t]*\r?\n/)
      cfg = cfg.sub(/^defaults:[ \t]*\r?\n/) { "#{$&}#{posts_default}" }
    else
      cfg += "\ndefaults:\n#{posts_default}"
    end
  end

  if cfg != before
    say(log, "  config  _config.yml (posts->article+hero, teaser, favicon, homepage)")
    File.write(cfg_path, cfg) unless DRY
  end
end

say(log, "== done: #{url_map.size} articles migrated across #{sections.size} sections ==")
