#!/usr/bin/env ruby
# =============================================================================
# lint_agencies.rb — the agencies registry and the trees it describes agree
# -----------------------------------------------------------------------------
# lifehacker.dev holds its sub-agencies as self-contained site trees under
# agencies/, described in _data/agencies.yml (agencies/README.md,
# docs/adr/0002-agencies.md). Three things can go wrong quietly, and this check
# makes each one loud:
#
#   * A tree nobody registered, or a registered tree that is not there. The
#     registry is how the platform (zer0-CMS) and a reader find a site and learn
#     where it came from; a tree outside it has no provenance.
#   * A site whose provenance is missing. `source:` is written by
#     scripts/agencies/import.rb; a row without it was typed by hand.
#   * `agencies` missing from `_config.yml` `exclude:`. Production is GitHub's
#     own Pages build of the WHOLE repository, while the CI overlay build copies
#     only pages/, _data/, _includes/ and assets/ — so without that exclude
#     every agency page would be published on the apex domain by a build no gate
#     ever saw. This is the one error here that protects readers.
#
# It does not re-check a tree against its source: a `home` tree is edited here
# and is supposed to drift from its import. `import.rb --verify` answers that
# question on demand.
#
# Stdlib only. Run: ruby scripts/ci/lint_agencies.rb
# =============================================================================
require_relative '_lib'

REGISTRY_REL = '_data/agencies.yml'
AGENCIES_DIR = File.join(LH::ROOT, 'agencies')
SOURCE_KEYS  = %w[repo path commit imported files tree_sha256].freeze

findings = []
add = lambda do |severity, rule, evidence, file = REGISTRY_REL|
  findings << LH.finding(check_id: 'agencies', severity: severity, rule: rule, file: file, evidence: evidence)
end

def child_dirs(dir)
  return [] unless Dir.exist?(dir)
  Dir.children(dir).select { |c| File.directory?(File.join(dir, c)) }.sort
end

registry_path = File.join(LH::ROOT, REGISTRY_REL)
registry = File.exist?(registry_path) ? (LH.yload(LH.read(registry_path)) rescue nil) : nil

if registry.nil?
  # No registry and no trees is a repository without agencies — nothing to check.
  add.call('error', 'registry-missing', 'agencies/ holds site trees but _data/agencies.yml is missing or unreadable') unless child_dirs(AGENCIES_DIR).empty?
  exit LH.write('agencies', findings).zero? ? 0 : 1
end

add.call('error', 'schema', "schema is #{registry['schema'].inspect}, expected \"agencies/v1\"") unless registry['schema'] == 'agencies/v1'

agencies = registry['agencies'].is_a?(Array) ? registry['agencies'] : []
seen_keys  = {}
seen_paths = {}
expected   = {}   # agency key => the site directory names it must hold (network) or nil (single)

agencies.each do |agency|
  key = agency['key'].to_s
  if key.empty?
    add.call('error', 'agency-key', 'an agency has no key')
    next
  end
  add.call('error', 'agency-key', "agency #{key} is listed twice") if seen_keys[key]
  seen_keys[key] = true
  %w[name beat].each { |f| add.call('error', 'agency-field', "agency #{key} has no #{f}") if agency[f].to_s.strip.empty? }
  kind = agency['kind']
  add.call('error', 'agency-kind', "agency #{key} has kind #{kind.inspect}; it is single or network") unless %w[single network].include?(kind)
  sites = agency['sites'].is_a?(Array) ? agency['sites'] : []
  add.call('error', 'agency-sites', "agency #{key} lists no sites") if sites.empty?
  add.call('error', 'agency-kind', "agency #{key} is single but lists #{sites.size} sites") if kind == 'single' && sites.size > 1
  expected[key] = kind == 'network' ? [] : nil

  site_keys = {}
  sites.each do |site|
    skey = site['key'].to_s
    path = site['path'].to_s
    where = "#{key}/#{skey.empty? ? '?' : skey}"
    add.call('error', 'site-key', "#{where}: a site has no key") if skey.empty?
    add.call('error', 'site-key', "#{where}: listed twice in the agency") if site_keys[skey]
    site_keys[skey] = true
    want = kind == 'network' ? "agencies/#{key}/#{skey}" : "agencies/#{key}"
    add.call('error', 'site-path', "#{where}: path is #{path.inspect}, expected #{want} (single: agencies/<agency>; network: agencies/<agency>/<site>)") unless path == want
    add.call('error', 'site-path', "#{where}: #{path} is also the path of #{seen_paths[path]}") if seen_paths[path]
    seen_paths[path] = where
    expected[key] << skey if kind == 'network'
    add.call('error', 'site-custody', "#{where}: custody is #{site['custody'].inspect}; it is home or mirror") unless %w[home mirror].include?(site['custody'])

    source = site['source']
    if source.is_a?(Hash)
      missing = SOURCE_KEYS.reject { |k| source.key?(k) && !source[k].to_s.strip.empty? }
      add.call('error', 'site-source', "#{where}: source lacks #{missing.join(', ')} — import it with scripts/agencies/import.rb, which writes them") unless missing.empty?
      add.call('error', 'site-source', "#{where}: source.commit #{source['commit'].inspect} is not a full commit id") if source['commit'] && source['commit'].to_s !~ /\A[0-9a-f]{40}\z/
    else
      add.call('error', 'site-source', "#{where}: no source block — every tree records where it came from")
    end

    abs = File.join(LH::ROOT, path)
    if !Dir.exist?(abs)
      add.call('error', 'site-missing', "#{where}: #{path} is registered but is not a directory", path)
    elsif Dir.glob('**/*', File::FNM_DOTMATCH, base: abs).none? { |p| File.file?(File.join(abs, p)) }
      add.call('error', 'site-empty', "#{where}: #{path} holds no files", path)
    end
  end
end

# Every directory under agencies/ belongs to a registered agency, and inside a
# network every directory is a registered site. agencies/README.md is the one
# file allowed beside the trees.
child_dirs(AGENCIES_DIR).each do |dir|
  unless expected.key?(dir)
    add.call('error', 'unregistered-tree', "agencies/#{dir} is not an agency in _data/agencies.yml — register it, then import it with scripts/agencies/import.rb", "agencies/#{dir}")
    next
  end
  next if expected[dir].nil?
  child_dirs(File.join(AGENCIES_DIR, dir)).each do |sub|
    next if expected[dir].include?(sub)
    add.call('error', 'unregistered-tree', "agencies/#{dir}/#{sub} is not a site of the #{dir} agency in _data/agencies.yml", "agencies/#{dir}/#{sub}")
  end
end
if Dir.exist?(AGENCIES_DIR)
  (Dir.children(AGENCIES_DIR).select { |c| File.file?(File.join(AGENCIES_DIR, c)) } - ['README.md']).sort.each do |stray|
    add.call('error', 'stray-file', "agencies/#{stray} sits beside the trees; only README.md lives there", "agencies/#{stray}")
  end
end

# The reader-facing guard: nothing under agencies/ reaches the apex site.
config = (LH.yload(LH.read(File.join(LH::ROOT, '_config.yml'))) rescue {}) || {}
excluded = Array(config['exclude']).map { |e| e.to_s.sub(%r{/+\z}, '') }
unless excluded.include?('agencies') || child_dirs(AGENCIES_DIR).empty?
  add.call('error', 'agencies-built-into-apex',
           '`agencies` is not in _config.yml `exclude:`. GitHub Pages builds the whole repository, so every agency page would be published on lifehacker.dev by a build the CI overlay never reproduces. Restore the exclude; publishing an agency from here is its own reviewed change (docs/adr/0002-agencies.md).',
           '_config.yml')
end

exit LH.write('agencies', findings).zero? ? 0 : 1
