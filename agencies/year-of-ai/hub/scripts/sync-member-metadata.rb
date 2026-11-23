#!/usr/bin/env ruby
# frozen_string_literal: true

# sync-member-metadata.rb — push consistent GitHub repo metadata to every
# member repo, from the hub registry (_data/hub.yml).
#
# The org survey (2026-07-06) found the member repos' GitHub metadata drifting:
# descriptions null on some members and styled differently everywhere, homepage
# unset on all, topics empty on all. The hub registry already knows every
# member's canonical title, so it is the natural source of truth.
#
# For each non-archived org repo not in exclude_repos:
#   description — "<Title> — a self-growing knowledge base in the <org>
#                  lineage." (a per-repo `description` in the registry wins)
#   homepage    — https://<org>.github.io/<name>/
#   topics      — knowledge-base, ai-generated, jekyll, github-pages, the org
#                 name, and the repo name
#
# Usage:
#   ruby scripts/sync-member-metadata.rb           # default: --check (dry run)
#   ruby scripts/sync-member-metadata.rb --apply   # PATCH the drifted fields
#
# Requires the `gh` CLI; --apply needs push/admin rights on the member repos.
# Idempotent: only drifted fields are written; topics are merged, never removed.

require 'json'
require 'open3'
require_relative 'lib/hub'

apply = ARGV.include?('--apply')

cfg = Hub.load_registry
org = cfg['org']
base_topics = ['knowledge-base', 'ai-generated', 'jekyll', 'github-pages', org.downcase]

overrides = (cfg['repos'] || []).each_with_object({}) { |r, h| h[r['name']] = r }
exclude = cfg['exclude_repos'] || []

repos = Hub.gh_api("orgs/#{org}/repos?per_page=100") || []
members = repos.reject { |r| r['archived'] || exclude.include?(r['name']) }
               .sort_by { |r| r['name'] }

drift = 0
members.each do |repo|
  name = repo['name']
  over = overrides[name] || {}
  title = over['title'] || Hub.humanize(name)
  want_desc = over['description'] ||
              "#{title} — a self-growing knowledge base in the #{org} lineage."
  want_home = "https://#{org}.github.io/#{name}/"
  want_topics = base_topics + [name.downcase]

  changes = {}
  changes['description'] = want_desc if repo['description'].to_s.strip != want_desc
  changes['homepage'] = want_home if repo['homepage'].to_s.strip != want_home
  topics = repo['topics'] || []
  topics_missing = want_topics - topics

  next if changes.empty? && topics_missing.empty?

  drift += 1
  puts "#{org}/#{name}:"
  changes.each { |k, v| puts "  #{k}: #{repo[k].inspect} -> #{v.inspect}" }
  puts "  topics: +#{topics_missing.join(' +')}" unless topics_missing.empty?

  next unless apply

  unless changes.empty?
    args = changes.flat_map { |k, v| ['-f', "#{k}=#{v}"] }
    _out, err, st = Open3.capture3('gh', 'api', '-X', 'PATCH', "repos/#{org}/#{name}", *args)
    warn "  ! PATCH failed for #{name}: #{err.lines.first}" unless st.success?
  end
  unless topics_missing.empty?
    body = JSON.generate('names' => (topics + want_topics).uniq)
    _out, err, st = Open3.capture3('gh', 'api', '-X', 'PUT', "repos/#{org}/#{name}/topics",
                                   '--input', '-', stdin_data: body)
    warn "  ! topics PUT failed for #{name}: #{err.lines.first}" unless st.success?
  end
end

if drift.zero?
  puts 'All member metadata already consistent.'
else
  puts "#{drift} member(s) drifted#{apply ? ' — applied' : ' (dry run; use --apply)'}"
end
exit(apply || drift.zero? ? 0 : 1)
