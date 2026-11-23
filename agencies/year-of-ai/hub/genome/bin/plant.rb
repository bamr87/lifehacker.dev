#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# genome/bin/plant.rb — assemble (and, gated, plant) a new org from a manifest.
# =============================================================================
# Runs FROM the canonical hub (which holds the live files). For a target concept
# manifest it assembles a complete, rendered hub tree by reading the live repo per
# genome/manifest.yml — transplant files copied verbatim, template/override files
# transformed (this org's literals → the target's values, derived from the two
# manifests via render.rb's token map). No duplicate payload is committed; the
# live repo IS the source, so the genome never drifts from a stale copy.
#
#   --dry-run (default): assemble into ./_planted/<org>/, print a plan + a
#     leak report (residual source-concept literals = lexicon/edge cases to refine).
#     Creates NOTHING external.
#   --apply: STAGED — refuses. Creating a public org + its hub is irreversible and,
#     like spawning (ADR-0002), runs only on an explicit owner go (two-key confirm
#     + the human org-creation/secret steps in GENOME.md §3).
#
# Usage:
#   ruby genome/bin/plant.rb --target genome/genome.example.countries.yml
# =============================================================================

require 'yaml'
require 'fileutils'
require 'shellwords'
require 'time'
require_relative 'render'

ROOT     = File.expand_path('../..', __dir__)
GENOME   = File.join(ROOT, 'genome')
MANIFEST = File.join(GENOME, 'manifest.yml')

opts = { source: File.join(GENOME, 'genome.yml'), out: nil, apply: false }
until ARGV.empty?
  case (a = ARGV.shift)
  when '--target'  then opts[:target] = ARGV.shift
  when '--source'  then opts[:source] = ARGV.shift
  when '--out'     then opts[:out] = ARGV.shift
  when '--apply'      then opts[:apply] = true
  when '--confirm'    then opts[:confirm] = ARGV.shift
  when '--dry-run'    then opts[:apply] = false
  when '--with-fleet' then opts[:with_fleet] = true
  else abort "unknown arg #{a.inspect}"
  end
end
abort 'usage: plant.rb --target <manifest.yml> [--dry-run]' unless opts[:target]

man      = YAML.load_file(MANIFEST)
source   = Genome.load_manifest(opts[:source])
target   = Genome.load_manifest(opts[:target])
src_map  = Genome.token_map(source)
tgt_map  = Genome.token_map(target)
org      = tgt_map['ORG'] or abort 'target manifest has no identity.org'
out      = opts[:out] || File.join(ROOT, '_planted', org)

# Distinctive structural literals — SAFE for bare gsub. Deliberately EXCLUDES
# prose/instance/date tokens: a bare UNIT_NOUN ("year") would corrupt Jekyll date
# config (:year, year-month-day); FIRST_MEMBER ("1776") would mangle ids;
# COPYRIGHT_YEAR/CRON/SUBJECT_SINGULAR/KNOWLEDGE_TABLE_HEADING/TAXONOMY_STRATEGY
# are instance/prose. The unit-noun is handled ONLY via curated phrases below.
SAFE_TOKENS = %w[
  ORG HUB_REPO HUB_DOMAIN GIT_AUTHOR_EMAIL THEME_REPO SITE_TITLE SITE_TAGLINE
  FOUNDER_NAME FOUNDER_EMAIL AUTHOR_BIO AUTHOR_LOCATION PREVIEW_IMAGE_STYLE
  PREVIEW_PROVIDER PREVIEW_MODEL CHAT_ASSISTANT_NAME CHAT_SYSTEM_PROMPT
  GOOGLE_ANALYTICS POSTHOG_API_KEY POSTHOG_HOST TWITTER INSTAGRAM YOUTUBE_URL
  GISCUS_REPO_ID GISCUS_CATEGORY_ID UNIT_ICON
].freeze

def cap_first(s)
  s.empty? ? s : s[0].upcase + s[1..-1]
end

# structural pairs (skip blank source literals so we never gsub "")
struct_pairs = SAFE_TOKENS.map do |tok|
  s = src_map[tok]
  next nil if s.nil? || s.empty?

  t = (tgt_map[tok] || '').to_s
  # CHAT_ASSISTANT_NAME can collide with the theme's OWN "<Name>-Mistakes" brand
  # (e.g. source "Zer0" is a substring of "Zer0-Mistakes", the Jekyll theme name,
  # which must NEVER be renamed just because a target's assistant is called
  # something else) — guard that one case with a negative lookahead.
  pat = tok == 'CHAT_ASSISTANT_NAME' ? /#{Regexp.escape(s)}(?!-[Mm]istakes)/ : s
  [pat, t]
end.compact

# curated unit-prose phrases: instantiate {unit}/{units} for source + target,
# add a Title-first variant, EXACT strings only (never bare "year").
su  = src_map['UNIT_NOUN']; sus = src_map['UNIT_NOUN_PLURAL'] || (su && "#{su}s")
tu  = tgt_map['UNIT_NOUN']; tus = tgt_map['UNIT_NOUN_PLURAL'] || (tu && "#{tu}s")
phrase_pairs = (man['phrase_tokens'] || []).flat_map do |tmpl|
  next [] unless su && tu

  s = tmpl.gsub('{units}', sus.to_s).gsub('{unit}', su)
  t = tmpl.gsub('{units}', tus.to_s).gsub('{unit}', tu)
  [[s, t], [cap_first(s), cap_first(t)]]
end

# Copyright year: NOT in SAFE_TOKENS (a bare 4-digit gsub would corrupt any other
# unrelated number in _config.yml), so it's scoped to the exact `cr_year: NNNN`
# line instead — the one place the value actually appears.
copyright_pair = if src_map['COPYRIGHT_YEAR'] && tgt_map['COPYRIGHT_YEAR']
                   ["cr_year: #{src_map['COPYRIGHT_YEAR']}", "cr_year: #{tgt_map['COPYRIGHT_YEAR']}"]
                 end

# LICENSE copyright line: same reasoning as cr_year above — the source's year
# RANGE (accumulated since year-of-ai's founding) doesn't transplant; a fresh
# org's LICENSE should read just its own genesis year.
license_pair = if tgt_map['COPYRIGHT_YEAR']
                 [/Copyright \(c\) [\d-]+ Amr Abdel\b/, "Copyright (c) #{tgt_map['COPYRIGHT_YEAR']} Amr Abdel"]
               end

# longest source first so specific literals win over their substrings. (`s` may
# be a Regexp for the guarded CHAT_ASSISTANT_NAME/license pairs — sort by its
# source text in that case.)
pairs = (struct_pairs + phrase_pairs + [copyright_pair, license_pair].compact)
        .sort_by { |s, _| -(s.is_a?(Regexp) ? s.source : s).length }

def transform(text, pairs)
  pairs.reduce(text) { |acc, (s, t)| acc.gsub(s, t) }
end

# Drop a manual `repos:` override block (instance member data) — a planted org
# self-registers its members via auto_discover. Backs up over the block's comment.
def prune_repos(body)
  lines = body.lines
  i = lines.index { |l| l.start_with?('repos:') }
  return body unless i

  j = i
  j -= 1 while j.positive? && lines[j - 1].lstrip.start_with?('#')
  lines[0...j].join.rstrip + "\n\n# Members self-register via auto_discover; no manual repos list is transplanted.\n"
end

def expand(root, entry)
  if entry.end_with?('/**')
    # Recurse, INCLUDING dotfiles/dotdirs (e.g. .claude/**). A bare trailing `**`
    # in Ruby's Dir.glob does NOT recurse and skips dotfiles — the bug that shipped
    # incomplete framework + .claude trees into planted hubs.
    Dir.glob(File.join(root, entry[0..-4], '**', '*'), File::FNM_DOTMATCH).select { |f| File.file?(f) }
  elsif entry.include?('*')
    Dir.glob(File.join(root, entry), File::FNM_PATHNAME | File::FNM_DOTMATCH).select { |f| File.file?(f) }
  else
    p = File.join(root, entry)
    File.file?(p) ? [p] : []
  end
end

# A fresh plant excludes the mature fleet/hub-tooling workflows (they fail without
# the org's context); `--with-fleet` includes them once the org has matured.
fleet_excl = (man['default_plant_exclude'] || [])
skip_fleet = ->(rel) { !opts[:with_fleet] && fleet_excl.include?(rel) }
excluded = 0

FileUtils.rm_rf(out)
copied = 0
rendered = 0
(man['transplant'] || []).each do |e|
  expand(ROOT, e).each do |src|
    rel = src.sub("#{ROOT}/", '')
    if skip_fleet.call(rel) then excluded += 1; next end
    dst = File.join(out, rel)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
    copied += 1
  end
end
((man['template'] || []) + (man['override'] || [])).each do |e|
  expand(ROOT, e).each do |src|
    rel = src.sub("#{ROOT}/", '')
    if skip_fleet.call(rel) then excluded += 1; next end
    dst = File.join(out, rel)
    FileUtils.mkdir_p(File.dirname(dst))
    body = File.read(src, encoding: 'utf-8', invalid: :replace, undef: :replace)
    body = transform(body, pairs)
    body = prune_repos(body) if rel == '_data/hub.yml'
    File.write(dst, body)
    rendered += 1
  end
end

# growth.web_sources: false — make the planted org generate from the model's OWN
# knowledge (no web). Strip the web tools from grow-lineage (the hard guarantee)
# and flag the generate prompt. Reproducible from the manifest, not a manual edit.
web = target.dig('growth', 'web_sources')
if web == false
  gl = File.join(out, '.github', 'workflows', 'grow-lineage.yml')
  if File.file?(gl)
    b = File.read(gl, encoding: 'utf-8')
    b = b.gsub(',WebFetch,WebSearch', '')
    b = b.sub('content growth tick for this knowledge base.',
              'content growth tick for this knowledge base. NO WEB - generate every fact from your OWN knowledge; the web is unavailable (no fetch/search tools).')
    File.write(gl, b)
    puts '  no-web    : stripped WebFetch/WebSearch from grow-lineage + flagged the prompt (growth.web_sources: false)'
  end
end

# Starter homepage (the genesis gap): the narrative pages are `regenerate`, so a
# fresh plant has no `/` and the Pages build is empty. Author a concept-agnostic
# landing page from the manifest so every plant lands a LIVE site immediately; a
# genesis agent can enrich it later.
home = +<<~HOME
  ---
  title: #{tgt_map['SITE_TITLE']}
  description: >-
    #{tgt_map['SITE_TAGLINE']}
  layout: home
  permalink: /
  sidebar: false
  hide_intro: true
  ---

  <section class="text-center py-5">
    <h1 class="display-4 fw-bold mb-3">#{tgt_map['SITE_TITLE']}</h1>
    <p class="lead text-body-secondary mx-auto" style="max-width: 46rem;">#{tgt_map['SITE_TAGLINE']} Each #{tgt_map['UNIT_NOUN']} is its own self-growing repository, published with the shared <a href="https://github.com/#{tgt_map['THEME_REPO']}">zer0-mistakes</a> theme.</p>
    <div class="d-flex justify-content-center gap-2 mt-4">
      <a class="btn btn-primary btn-lg" href="https://github.com/#{org}"><i class="bi bi-github me-1"></i>Organization</a>
    </div>
  </section>

  {% assign hub = site.data.hub_index %}
  {% if hub and hub.repos and hub.repos.size > 0 %}
  <div class="row row-cols-2 row-cols-md-4 g-3 mb-5">{% for repo in hub.repos %}<div class="col"><a class="card h-100 text-decoration-none text-reset shadow-sm" href="{{ repo.site_url | default: repo.url }}"><div class="card-body text-center"><div class="h5 fw-bold mb-1 text-capitalize">{{ repo.name | replace: '-', ' ' }}</div><div class="small text-body-secondary">{% if repo.page_count == 0 %}seeded{% else %}{{ repo.page_count }} pages{% endif %}</div></div></a></div>{% endfor %}</div>
  {% else %}
  <p class="text-center text-body-secondary">The knowledge base is being seeded — #{tgt_map['UNIT_NOUN_PLURAL']} are generated automatically, one growth tick at a time. The first is <strong>#{tgt_map['FIRST_MEMBER']}</strong>.</p>
  {% endif %}
HOME
FileUtils.mkdir_p(File.join(out, 'pages'))
File.write(File.join(out, 'pages', 'home.md'), home)
puts '  homepage  : authored pages/home.md from the manifest (a live landing page)'

# Leak report: residual SOURCE-concept literals in the assembled tree (excludes
# the regenerate tier, which a genesis agent re-authors for the new concept). Only
# flag a source literal the target CHANGED — a literal the target intentionally
# REUSES (e.g. the same founder owns both orgs) is correctly kept, not a leak.
STRONG = ['year-of-ai', 'Year of AI', 'Amr Abdel-Motaleb', 'amr.abdel@gmail.com'].freeze
tgt_values = tgt_map.values.map(&:to_s)
should_be_gone = STRONG.reject { |lit| tgt_values.include?(lit) }
lexicon_src = [src_map['UNIT_NOUN'], src_map['UNIT_NOUN_PLURAL']].compact.reject(&:empty?)
strong_hits = Hash.new(0)
lexicon_hits = 0
Dir.glob(File.join(out, '**', '*'), File::FNM_DOTMATCH).select { |f| File.file?(f) }.each do |f|
  body = File.read(f, encoding: 'utf-8', invalid: :replace, undef: :replace) rescue next
  should_be_gone.each { |lit| strong_hits[lit] += body.scan(lit).size }
  # Exclude legitimately-preserved Jekyll date placeholders (:year, year-month-day)
  # so the count reflects real concept-prose residue, not correct date config.
  prose = body.gsub('year-month-day', '').gsub(/:year\b/, '')
  lexicon_src.each { |w| lexicon_hits += prose.scan(/\b#{Regexp.escape(w)}\b/i).size }
end

puts '── plant (dry-run) ──────────────────────────────────────────'
puts "  source concept : #{src_map['SITE_TITLE']}  (org #{src_map['ORG']})"
puts "  target concept : #{tgt_map['SITE_TITLE']}  (org #{org})"
puts "  assembled tree : #{out.sub("#{ROOT}/", '')}/   (#{copied} transplanted, #{rendered} rendered, #{excluded} fleet excluded#{opts[:with_fleet] ? ' [--with-fleet]' : ''})"
regen = (man['regenerate'] || [])
puts "  regenerate     : #{regen.size} narrative path(s) a genesis agent authors for the new concept:"
regen.each { |r| puts "      - #{r}" }
puts '  ── leak report ──'
strong = strong_hits.select { |_, n| n.positive? }
if strong.empty?
  puts '    ✓ no residual structural source literals (org/title/founder/email).'
else
  puts '    ✗ residual STRONG source literals (the transform missed these):'
  strong.each { |lit, n| puts "        #{lit.inspect}: #{n}" }
end
puts "    · lexicon residue ('#{lexicon_src.join("'/'")}', case-insensitive, mostly in workflow comments/descriptions): #{lexicon_hits}"
puts "      (narrative pages are in the regenerate tier; remaining hits are config/workflow prose — refine via curated phrase tokens.)"

unless opts[:apply]
  puts "\n  DRY RUN — nothing external created. Review #{out.sub("#{ROOT}/", '')}/ then proceed per GENOME.md §3."
  exit 0
end

# ---- --apply: live germination (two-key + guards) ---------------------------
abort "\n  ✗ refusing --apply: residual source literals remain in the assembled tree." unless strong.empty?
abort "\n  ✗ --apply requires --confirm #{org} (two-key guard); got #{opts[:confirm].inspect}." unless opts[:confirm] == org
abort "\n  ✗ gh is not authenticated." unless system('gh auth status >/dev/null 2>&1')
hub  = tgt_map['HUB_REPO']
repo = "#{org}/#{hub}"
me = `gh api user --jq .login 2>/dev/null`.strip
my_orgs = `gh api user/orgs --jq '.[].login' 2>/dev/null`.split("\n").map(&:strip)
unless org == me || my_orgs.include?(org)
  abort "\n  ✗ you cannot create repos under '#{org}' — it is not your account and not an org you belong to\n" \
        "    (you can use: #{me}, #{my_orgs.join(', ')}). GitHub has NO org-creation API: create the org in the\n" \
        "    web UI (github.com/account/organizations/new), add the 3 secrets, then re-run. (GENOME.md §3)"
end
abort "\n  ✗ #{repo} already exists — refusing to overwrite (idempotent)." if system("gh repo view #{repo} >/dev/null 2>&1")

# Author member #1's seed into the hub (the genome's DECIDE for the first member,
# derived from the manifest) so the planted org grows on its first tick.
fm = tgt_map['FIRST_MEMBER']
if fm && !fm.empty?
  lx = target['lexicon'] || {}
  subject = (lx['member_subject_template'] || fm).gsub('{member}', fm)
  tax = ((target['taxonomy'] || {})['default_taxonomy'] || [])
        .map { |c| "    - name: \"#{c['name']}\"\n      slug: \"#{c['slug']}\"" }.join("\n")
  heading = (lx['knowledge_table_heading'] || 'Notable Items of {{SUBJECT}}').gsub('{{SUBJECT}}', subject)
  seed = <<~SEED
    <!-- seed.md — DNA of this repository. §1-7 generated by sync-seed; §8 append-only. -->

    # Repository DNA

    ## 1. Concept Definition

    ```yaml
    concept:
      subject: "#{subject}"
      scope: "Events, people, works, and developments primarily associated with #{subject}."
      taxonomy:
    #{tax}
      source_strategy: "Verify every fact against at least two authoritative sources (one encyclopedic, one specialist)."
      conventions:
        knowledge_table_heading: "#{heading}"
        file_path: "<category-slug>/<topic-slug>.md"
        frontmatter: "[title, date, category]"
        tone: "factual, neutral, encyclopedic, third person"
    ```

    > Sections 2-7 are generated by the sync-seed skill on the first growth tick.

    ## 8. Evolution Log

    ### Genesis — #{Time.now.utc.strftime('%Y-%m-%d')}

    - **Subject**: #{subject}
    - **Planted by**: the organizational genome (`genome/bin/plant.rb --apply`) for the #{(target['branding'] || {})['site_title']} network.
  SEED
  FileUtils.mkdir_p(File.join(out, 'lineage', 'seeds'))
  File.write(File.join(out, 'lineage', 'seeds', "#{fm}.md"), seed)
  puts "  seeded member #1: lineage/seeds/#{fm}.md (#{subject})"
end

run = lambda do |cmd|
  puts "    $ #{cmd}"
  system(cmd) || abort("    ✗ command failed: #{cmd}")
end

puts "\n  Planting #{repo} …"
run.call("gh repo create #{repo} --public --description #{Shellwords.escape("#{tgt_map['SITE_TITLE']} — a self-growing knowledge-base network")}")
email = tgt_map['GIT_AUTHOR_EMAIL'].to_s.empty? ? 'noreply@example.com' : tgt_map['GIT_AUTHOR_EMAIL']
Dir.chdir(out) do
  run.call('git init -q -b main')
  run.call('git add -A')
  run.call("git -c user.name=genome-plant -c user.email=#{Shellwords.escape(email)} commit -q -m #{Shellwords.escape("feat: plant #{tgt_map['SITE_TITLE']} from the org genome")}")
  run.call("git remote add origin https://github.com/#{repo}.git")
  run.call('git push -q -u origin main')
end
# Enable GitHub Pages (deploy from branch main /). Tolerate "already enabled".
system("gh api -X POST repos/#{repo}/pages -f 'source[branch]=main' -f 'source[path]=/' >/dev/null 2>&1") ||
  system("gh api -X PUT repos/#{repo}/pages -f 'source[branch]=main' -f 'source[path]=/' >/dev/null 2>&1") ||
  warn('    ::note:: enable Pages manually if it did not auto-enable (Settings → Pages → main /).')

puts "\n  ✓ Planted #{repo}  →  https://#{tgt_map['HUB_DOMAIN']}/"
puts '  Remaining (the two human steps):'
puts "    1. Set the 3 org secrets on #{org}: CLAUDE_CODE_OAUTH_TOKEN, ANTHROPIC_API_KEY, LIFECYCLE_PAT."
puts "    2. The hub's orchestrate.yml grows member #1 (#{fm}) on its daily cron — or dispatch it now."
