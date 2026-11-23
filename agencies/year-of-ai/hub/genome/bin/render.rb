#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# genome/bin/render.rb — the token-substitution engine (the shared core).
# =============================================================================
# Builds the {{TOKEN}} → value map from a filled concept manifest (genome.yml,
# deep-merged over genome.defaults.GENERATED.yml when present) and expands tokens
# in any template text. RAISES on an unresolved {{TOKEN}} — that is the
# completeness gate: a template that references a token the manifest doesn't
# define fails loudly rather than shipping a literal `{{...}}` to a planted org.
#
# Reused by bin/extract.rb (round-trip check), bin/verify.rb (drift), and the
# staged bin/plant.rb. No network, no side effects beyond stdout / the returned
# string.
#
# Usage:
#   ruby genome/bin/render.rb <template-file> [--manifest genome.yml]   # print rendered
#   ruby genome/bin/render.rb --selftest                                # prove abstraction
#   require_relative 'render'; Genome.render(text, manifest_hash)       # as a library
# =============================================================================

require 'yaml'

module Genome
  GENOME_DIR = File.expand_path('..', __dir__)

  # Fixed map: manifest dotted-path → {{TOKEN}} name. The single source of which
  # manifest field abstracts which token; extract.rb inverts this same map.
  FIELD_TOKENS = {
    'identity.org'                => 'ORG',
    'identity.hub_repo'           => 'HUB_REPO',
    'identity.hub_domain'         => 'HUB_DOMAIN',
    'identity.git_author_email'   => 'GIT_AUTHOR_EMAIL',
    'identity.theme_repo'         => 'THEME_REPO',
    'branding.site_title'         => 'SITE_TITLE',
    'branding.site_tagline'       => 'SITE_TAGLINE',
    'branding.founder_name'       => 'FOUNDER_NAME',
    'branding.founder_email'      => 'FOUNDER_EMAIL',
    'branding.author_bio'         => 'AUTHOR_BIO',
    'branding.author_location'    => 'AUTHOR_LOCATION',
    'branding.copyright_year'     => 'COPYRIGHT_YEAR',
    'branding.preview_image_style' => 'PREVIEW_IMAGE_STYLE',
    'branding.preview_provider'   => 'PREVIEW_PROVIDER',
    'branding.preview_model'      => 'PREVIEW_MODEL',
    'branding.chat_assistant_name' => 'CHAT_ASSISTANT_NAME',
    'branding.chat_system_prompt' => 'CHAT_SYSTEM_PROMPT',
    'analytics.google_analytics'  => 'GOOGLE_ANALYTICS',
    'analytics.posthog_api_key'   => 'POSTHOG_API_KEY',
    'analytics.posthog_host'      => 'POSTHOG_HOST',
    'social.twitter'              => 'TWITTER',
    'social.instagram'            => 'INSTAGRAM',
    'social.youtube_url'          => 'YOUTUBE_URL',
    'comments.giscus_repo_id'     => 'GISCUS_REPO_ID',
    'comments.giscus_category_id' => 'GISCUS_CATEGORY_ID',
    'lexicon.unit_noun'           => 'UNIT_NOUN',
    'lexicon.unit_noun_plural'    => 'UNIT_NOUN_PLURAL',
    'lexicon.unit_icon'           => 'UNIT_ICON',
    'lexicon.subject_singular'    => 'SUBJECT_SINGULAR',
    'lexicon.knowledge_table_heading' => 'KNOWLEDGE_TABLE_HEADING',
    'taxonomy.taxonomy_strategy'  => 'TAXONOMY_STRATEGY',
    'lifecycle.first_member'      => 'FIRST_MEMBER',
    'cadence.cron'                => 'CRON',
  }.freeze

  module_function

  def dig_path(hash, dotted)
    dotted.split('.').reduce(hash) { |h, k| h.is_a?(Hash) ? h[k] : nil }
  end

  # Build {{TOKEN}} => value from a manifest hash. Empty/blank values are allowed
  # (e.g. analytics default empty); only a MISSING token raises at render time.
  def token_map(manifest)
    map = {}
    FIELD_TOKENS.each do |path, token|
      v = dig_path(manifest, path)
      map[token] = v.nil? ? nil : v.to_s
    end
    # naive plural fallback if not supplied
    map['UNIT_NOUN_PLURAL'] ||= (map['UNIT_NOUN'] ? "#{map['UNIT_NOUN']}s" : nil)
    map
  end

  def render(text, manifest)
    map = manifest.is_a?(Hash) && manifest.key?('__token_map__') ? manifest['__token_map__'] : token_map(manifest)
    out = text.gsub(/\{\{\s*([A-Z_]+)\s*\}\}/) do
      tok = Regexp.last_match(1)
      raise "render: unresolved token {{#{tok}}} (not defined by the manifest)" unless map.key?(tok) && !map[tok].nil?

      map[tok]
    end
    leftover = out.scan(/\{\{\s*[A-Z_]+\s*\}\}/).uniq
    raise "render: tokens left unresolved: #{leftover.join(', ')}" unless leftover.empty?

    out
  end

  def load_manifest(path)
    base = File.join(GENOME_DIR, 'genome.defaults.GENERATED.yml')
    defaults = File.exist?(base) ? (YAML.load_file(base) || {}) : {}
    filled = YAML.load_file(path) || {}
    deep_merge(defaults, filled)
  end

  def deep_merge(a, b)
    a.merge(b) { |_k, av, bv| av.is_a?(Hash) && bv.is_a?(Hash) ? deep_merge(av, bv) : bv }
  end
end

# ---- CLI --------------------------------------------------------------------
if __FILE__ == $PROGRAM_NAME
  if ARGV.delete('--selftest')
    sample = +"org={{ORG}} title={{SITE_TITLE}} unit={{UNIT_NOUN}} plural={{UNIT_NOUN_PLURAL}} " \
             "subject=\"{{SUBJECT_SINGULAR}} <member>\" theme={{THEME_REPO}} cron='{{CRON}}'"
    %w[genome.yml genome.example.countries.yml].each do |mf|
      path = File.join(Genome::GENOME_DIR, mf)
      next unless File.exist?(path)

      m = YAML.load_file(path)
      puts "── #{mf} ──"
      puts "  #{Genome.render(sample, m)}"
    end
    # prove the failure gate
    begin
      Genome.render('x={{NOT_A_TOKEN}}', YAML.load_file(File.join(Genome::GENOME_DIR, 'genome.yml')))
      puts '  ✗ expected unresolved-token raise did not happen'; exit 1
    rescue RuntimeError => e
      puts "  ✓ unresolved-token gate works: #{e.message}"
    end
    exit 0
  end

  tpl = ARGV.shift or abort 'usage: render.rb <template-file> [--manifest genome.yml] | --selftest'
  mi = ARGV.index('--manifest')
  mf = mi ? ARGV[mi + 1] : File.join(Genome::GENOME_DIR, 'genome.yml')
  print Genome.render(File.read(tpl, encoding: 'utf-8'), Genome.load_manifest(mf))
end
