#!/usr/bin/env ruby
# =============================================================================
# plan_sources.rb — pick WHICH source-site pages the scout reads this run
# -----------------------------------------------------------------------------
# The content-scout must be random enough to cover a whole sister site over time,
# but bounded (cost cap) and reproducible (a flaky run can be replayed). We get
# both with a SEEDED shuffle of the site's sitemap: the seed defaults to the UTC
# date, so a given day's plan is deterministic and re-runnable, while consecutive
# days roam different corners of the source.
#
# Configurable for other sites: SCOUT_SOURCES is a comma-separated list of base
# URLs (default https://it-journey.dev). For each, we fetch <base>/sitemap.xml
# (following a one-level sitemap index if that's what it is), keep same-host HTML
# pages, seed-shuffle, and take a per-source slice. If a sitemap is unreachable
# we degrade to the homepage so the planner always yields *something* — the
# agent still has a starting point and can wander from there.
#
#   SCOUT_SOURCES="https://it-journey.dev" \
#     ruby scripts/scout/plan_sources.rb [--seed YYYYMMDD] [--per-source N]
#
# Output: _data/scout/plan.json — per source, a capped list of URLs plus a couple
# of "wander" budget slots the agent fills by following links it finds live (the
# genuinely random part the seed can't predict).
#
# Stdlib only (net/http, uri, json, digest). No endless-method defs.
# =============================================================================
require 'net/http'
require 'uri'
require 'json'
require 'digest'
require_relative '_lib'

seed_arg   = (ARGV[ARGV.index('--seed') + 1] if ARGV.include?('--seed'))
per_arg    = (ARGV[ARGV.index('--per-source') + 1].to_i if ARGV.include?('--per-source'))
PER_SOURCE = (per_arg && per_arg > 0) ? per_arg : 6            # cost cap: pages/source/run
SEED       = (seed_arg || Time.now.utc.strftime('%Y%m%d')).to_s
SOURCES    = (ENV['SCOUT_SOURCES'] || 'https://it-journey.dev')
             .split(',').map(&:strip).reject(&:empty?)

# Skip assets and feeds — the scout reads prose, not stylesheets or images.
SKIP_EXT = /\.(css|js|png|jpe?g|gif|svg|webp|ico|pdf|zip|xml|json|txt|woff2?)\z/i

def http_get(url, limit = 3)
  raise 'too many redirects' if limit <= 0
  uri = URI.parse(url)
  res = Net::HTTP.start(uri.host, uri.port,
                        use_ssl: uri.scheme == 'https',
                        open_timeout: 10, read_timeout: 15) do |http|
    http.get(uri.request_uri, 'User-Agent' => 'lifehacker-content-scout/1.0')
  end
  case res
  when Net::HTTPSuccess    then res.body
  when Net::HTTPRedirection then http_get(URI.join(url, res['location']).to_s, limit - 1)
  else raise "HTTP #{res.code} for #{url}"
  end
end

# Pull every <loc> out of a sitemap (or sitemap-index) body.
def locs(xml)
  xml.to_s.scan(%r{<loc>\s*(.*?)\s*</loc>}im).flatten.map { |u| u.gsub(/\s+/, '') }
end

# Resolve a base URL to a list of same-host HTML page URLs from its sitemap.
# Follows a sitemap INDEX one level deep (bounded). Degrades to [base/] on any error.
def pages_for(base)
  host = URI.parse(base).host
  root = base.sub(%r{/+\z}, '')
  found = []
  begin
    top = locs(http_get("#{root}/sitemap.xml"))
    nested = top.select { |u| u =~ /\.xml\z/i }
    if nested.any? && found.empty?
      # sitemap index -> fetch a bounded handful of child sitemaps
      nested.first(5).each { |sm| found.concat(locs(http_get(sm))) rescue nil }
    end
    found.concat(top.reject { |u| u =~ /\.xml\z/i })
  rescue StandardError => e
    warn "[plan] #{host}: sitemap fetch failed (#{e.class}: #{e.message}) — degrading to homepage"
  end
  pages = found.uniq
             .select { |u| URI.parse(u).host == host rescue false }
             .reject { |u| u =~ SKIP_EXT }
  pages.empty? ? ["#{root}/"] : pages
end

# Seeded deterministic shuffle: a stable RNG from the seed string (same recipe
# as scripts/explorer/plan_routes.rb).
rng = Random.new(Digest::SHA1.hexdigest(SEED).to_i(16) % (2**31))

sources_plan = SOURCES.map do |base|
  all = pages_for(base)
  visit = all.shuffle(random: rng).first(PER_SOURCE)
  {
    'base'         => base,
    'host'         => (URI.parse(base).host rescue base),
    'candidates'   => all.size,
    'visit'        => visit,
    'wander_slots' => 2   # agent follows 2 live links of its choosing per source
  }
end

out = {
  'generated_at'     => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
  'seed'             => SEED,
  'per_source'       => PER_SOURCE,
  'total_url_budget' => PER_SOURCE * SOURCES.size,
  'sources'          => sources_plan
}

Dir.mkdir(Scout::DATA) unless Dir.exist?(Scout::DATA)
File.write(Scout::PLAN, JSON.pretty_generate(out))
puts "[plan] seed=#{SEED} per_source=#{PER_SOURCE} sources=#{SOURCES.size} budget=#{out['total_url_budget']}"
sources_plan.each do |s|
  puts "  #{s['host']}: #{s['candidates']} candidates -> visit #{s['visit'].size} (+#{s['wander_slots']} wander)"
  s['visit'].each { |u| puts "      #{u}" }
end
