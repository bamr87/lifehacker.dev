#!/usr/bin/env ruby
# =============================================================================
# plan_routes.rb — pick WHICH pages each persona visits this run
# -----------------------------------------------------------------------------
# The explorer must be random enough to cover the site over time, but bounded
# (cost cap) and reproducible (so a flaky run can be replayed). We get both with
# a SEEDED shuffle: the seed defaults to the UTC date, so a given day's plan is
# deterministic and re-runnable, while consecutive days roam different corners.
#
# Input: the live sitemap (sitemap.xml) if reachable, else the committed
# _data/navigation + a crawl of pages/_*/*.md as a fallback so the planner works
# headless with no network. Output: a JSON plan — per persona, a capped list of
# URLs plus a couple of "wander" budget slots the agent fills by following links
# it finds live (that is the genuinely random part the seed can't predict).
#
#   ruby scripts/explorer/plan_routes.rb [--seed YYYYMMDD] [--per-persona N]
#
# Stdlib only. No endless-method defs.
# =============================================================================
require 'json'
require 'date'
require_relative '_lib'

seed_arg = (ARGV[ARGV.index('--seed') + 1] if ARGV.include?('--seed'))
PER      = (ARGV[ARGV.index('--per-persona') + 1].to_i if ARGV.include?('--per-persona'))
per_persona = (PER && PER > 0) ? PER : 6           # cost cap: pages/persona/run
seed = (seed_arg || Time.now.utc.strftime('%Y%m%d')).to_s

# Collect candidate paths from the committed content (network-free, always works).
def content_paths
  paths = ['/', '/hacks/', '/tools/', '/posts/', '/docs/', '/about/']
  Dir.glob(File.join(Explorer::ROOT, 'pages', '_*', '*.md')).each do |f|
    rel = LH.rel(f)
    m = rel.match(%r{\Apages/_(\w+)/(.+)\.md\z}) or next
    coll, name = m[1], m[2]
    case coll
    when 'posts'
      if name =~ /\A(\d{4})-(\d{2})-(\d{2})-(.+)\z/
        paths << "/posts/#{$1}/#{$2}/#{$3}/#{$4}/"
      end
    when 'hacks' then paths << "/hacks/#{name}/"
    when 'tools' then paths << "/tools/#{name}/"
    when 'docs'  then paths << "/docs/#{name}/"
    when 'about' then paths << "/about/#{name}/"
    end
  end
  paths.uniq
end

all = content_paths
# Seeded deterministic shuffle: a stable RNG from the date string.
rng = Random.new(Digest::SHA1.hexdigest(seed).to_i(16) % (2**31))
shuffled = all.shuffle(random: rng)

# Each persona gets its own window into the shuffle so they don't all visit the
# same first N pages, but the home + one hub are ALWAYS in every persona's set
# (those are the highest-traffic surfaces; never skip them).
anchors = ['/', shuffled.find { |p| p =~ %r{\A/(hacks|tools|docs)/\z} } || '/hacks/'].uniq
plan = {}
Explorer::PERSONAS.each_with_index do |persona, i|
  window = shuffled.rotate(i * per_persona)
  picks  = (anchors + window).uniq.first(per_persona)
  plan[persona] = {
    'visit'        => picks,
    'wander_slots' => 2,            # agent follows 2 live links of its choosing
    'lens'         => Explorer::PERSONAS[i]
  }
end

out = {
  'generated_at' => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
  'seed'         => seed,
  'site'         => Explorer::SITE,
  'per_persona'  => per_persona,
  'total_url_budget' => per_persona * Explorer::PERSONAS.size,
  'plan'         => plan
}
Dir.mkdir(Explorer::DATA) unless Dir.exist?(Explorer::DATA)
File.write(File.join(Explorer::DATA, 'plan.json'), JSON.pretty_generate(out))
puts "[plan] seed=#{seed} per_persona=#{per_persona} budget=#{out['total_url_budget']} candidates=#{all.size}"
Explorer::PERSONAS.each { |p| puts "  #{p}: #{plan[p]['visit'].join(' ')}  (+#{plan[p]['wander_slots']} wander)" }
