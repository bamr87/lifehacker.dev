#!/usr/bin/env ruby
# =============================================================================
# triage_import.rb — deterministic scanner for a content-import source tree
# -----------------------------------------------------------------------------
# Step 1 of the repeatable import→rewrite flow (see
# .claude/skills/content-import/SKILL.md). Given a SOURCE checkout of imported
# markdown (e.g. a `git worktree` of an import PR's branch) it emits the FACTS
# the editorial triage needs, one record per file:
#
#   src, slug, base_collection (_posts|_drafts), title, date, author,
#   categories, tags, preview (from front matter), assets (from the manifest),
#   quest_links[], itjourney_links[], code_blocks, shell_blocks, word_count,
#   suggested_collection (heuristic), suggested_voice (heuristic)
#
# It deliberately makes NO editorial judgment (rewrite vs skip, final voice).
# That verdict is added by the triage agents and recorded in the plan. Keeping
# the facts deterministic means the same source always yields the same skeleton,
# so a re-import is a diff, not a re-think.
#
# Stdlib only — runs on a bare runner. Usage:
#   ruby scripts/content/triage_import.rb <SOURCE_DIR> [MANIFEST_JSON] > skeleton.json
#   SOURCE_DIR   a checkout containing pages/_posts and/or pages/_drafts
#   MANIFEST_JSON optional POST_IMPORT_MANIFEST.json for src→assets mapping
# =============================================================================
require 'yaml'
require 'json'

source = ARGV[0] or abort "usage: triage_import.rb <SOURCE_DIR> [MANIFEST_JSON]"
manifest_path = ARGV[1]

def yload(str)
  YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(str) : YAML.load(str)
end

# [frontmatter_or_nil, body]
def parse(path)
  raw = File.read(path, encoding: 'UTF-8')
  if raw =~ /\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)\z/m
    fm = (yload($1) rescue nil)
    [fm.is_a?(Hash) ? fm : nil, $2 || '']
  else
    [nil, raw]
  end
end

# Map dest path -> [assets] from the import manifest, so the scanner knows which
# preview/asset files travel with each post even when the front-matter `preview:`
# was dropped as cruft.
assets_for = Hash.new { |h, k| h[k] = [] }
if manifest_path && File.exist?(manifest_path)
  man = JSON.parse(File.read(manifest_path)) rescue {}
  (man['moved'] || []).each do |m|
    # index by basename so it matches regardless of _posts/_drafts location
    assets_for[File.basename(m['dest'].to_s)] = m['assets'] || []
  end
end

# Heuristic collection routing from title/tags/categories. The agents override
# this; it just seeds the plan so obvious cases need no thought.
def suggest_collection(title, tags, cats, body)
  t = "#{title} #{Array(tags).join(' ')} #{Array(cats).join(' ')}".downcase
  return 'tools'  if t =~ /\breview\b|honest review|\bvs\b|extensions?\b/ && t =~ /vscode|tool|extension|cli|app/
  return 'hacks'  if t =~ /\bhow to\b|setup|install|configure|fix(ing)?\b|tutorial|guide|stop typing|cheat/
  'posts' # Field Notes — the default for war stories / build-log narratives
end

def suggest_voice(collection)
  { 'hacks' => 'how-to-practical', 'tools' => 'tool-review-honest',
    'posts' => 'meta-confession', 'docs' => 'meta-confession' }[collection] || 'satire-deadpan'
end

records = []
%w[_posts _drafts].each do |dir|
  Dir.glob(File.join(source, 'pages', dir, '*.md')).sort.each do |path|
    fm, body = parse(path)
    fm ||= {}
    base = File.basename(path)
    slug = base.sub(/\A\d{4}-\d{2}-\d{2}-/, '').sub(/\.md\z/, '')

    quest_links = body.scan(%r{/quests?/[^\s)"'\]]+}i).uniq
    itj_links   = body.scan(%r{https?://[^\s)"'\]]*it-journey[^\s)"'\]]*}i).uniq
    fences      = body.scan(/^```/).size / 2
    shell       = body.scan(/^```(?:bash|sh|shell|console|zsh)/i).size
    words       = body.split(/\s+/).reject(&:empty?).size

    cats = Array(fm['categories'])
    tags = Array(fm['tags'])
    coll = suggest_collection(fm['title'], tags, cats, body)

    records << {
      'src'                  => path.sub("#{source}/", ''),
      'base'                 => base,
      'slug'                 => slug,
      'base_collection'      => (dir == '_drafts' ? 'draft' : 'posts'),
      'title'                => fm['title'],
      'date'                 => fm['date'].to_s,
      'author'              => fm['author'],
      'categories'           => cats,
      'tags'                 => tags,
      'preview_frontmatter'  => fm['preview'],
      'assets'               => assets_for[base],
      'quest_links'          => quest_links,
      'itjourney_links'      => itj_links,
      'code_blocks'          => fences,
      'shell_blocks'         => shell,
      'word_count'           => words,
      'suggested_collection' => coll,
      'suggested_voice'      => suggest_voice(coll)
    }
  end
end

puts JSON.pretty_generate(records)
STDERR.puts "[triage] scanned #{records.size} files from #{source}"
