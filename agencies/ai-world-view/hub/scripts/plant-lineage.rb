#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# plant-lineage.rb — spawn ONE new tangential-era repo (ADR-0002).
# =============================================================================
#
# The DECIDE step (a frontier-model pass, or a human) first authors the new era's
# concept seed at `lineage/seeds/<id>.md` (§1 Concept Definition + an empty §8).
# This script does the deterministic PLANT: it creates the public repo, drops the
# canonical year-repo skeleton (`lineage/repo-template/` — the `.claude` adapters,
# CLAUDE.md, telemetry/), provisions `_config.yml` + enables GitHub Pages (reusing
# provision-org-sites.rb), and leaves the repo empty of content. The next
# `orchestrate.yml` run grows it like any other repo.
#
# Safety (ADR-0002 §E):
#   - DRY-RUN by default. A real spawn needs BOTH `--apply` AND `--confirm <id>`
#     where <id> equals --id (a two-key action).
#   - Idempotent / non-destructive: refuses any existing repo with content
#     beyond the plant surface; RESUMES an interrupted plant (an empty or
#     skeleton-only vessel). Never deletes or overwrites. One repo per run.
#   - Creates only the vessel — no content is generated here.
#
# Usage:
#   ruby scripts/plant-lineage.rb --id 2012                       # dry-run plan
#   ruby scripts/plant-lineage.rb --id 2012 --apply --confirm 2012  # plant for real
#
# Requires `gh` (repo + pages write) and `git` for the real run. The new era's
# seed must already exist at lineage/seeds/<id>.md; commit it to the hub yourself
# (or via the plant-lineage workflow) so the orchestrator can grow it.
# =============================================================================

require 'optparse'
require 'fileutils'
require 'tmpdir'
require 'yaml'
require 'shellwords'
require_relative 'lib/hub'

TEMPLATE_DIR = File.join(Hub::ROOT, 'lineage', 'repo-template')
SEEDS_DIR    = File.join(Hub::ROOT, 'lineage', 'seeds')
PROVISIONER  = File.join(Hub::ROOT, 'scripts', 'provision-org-sites.rb')
ORG          = (YAML.load_file(Hub::CONFIG_FILE)['org'] rescue nil) || 'ai-world-view'
SUBJECT_RE   = /^\s*subject:\s*["']?(.+?)["']?\s*$/

def die(msg)
  Hub.log_error(msg)
  exit 1
end

def run!(cmd)
  puts "  $ #{cmd}"
  system(cmd) || die("command failed (exit #{$?.exitstatus}): #{cmd}")
end

options = { apply: false, confirm: nil }
OptionParser.new do |o|
  o.banner = 'Usage: ruby scripts/plant-lineage.rb --id ID [--apply --confirm ID]'
  o.on('--id ID',      'repo/seed id to plant (e.g. 2012)') { |v| options[:id] = v.strip }
  o.on('--apply',      'actually create the repo (default: dry-run)') { options[:apply] = true }
  o.on('--confirm ID', 'must equal --id to apply (two-key guard)') { |v| options[:confirm] = v.strip }
end.parse!

id = options[:id] or die('--id is required')
die("invalid id #{id.inspect} — use lowercase letters, digits, and hyphens") unless id =~ /\A[a-z0-9][a-z0-9-]*\z/
seed_path = File.join(SEEDS_DIR, "#{id}.md")
die("seed not found: lineage/seeds/#{id}.md — the DECIDE step must author it first") unless File.exist?(seed_path)
die("repo template missing: lineage/repo-template/") unless Dir.exist?(TEMPLATE_DIR)

subject = File.read(seed_path, encoding: 'utf-8')[SUBJECT_RE, 1] || id
repo    = "#{ORG}/#{id}"
template_files = Dir.glob(File.join(TEMPLATE_DIR, '**', '*'), File::FNM_DOTMATCH).select { |f| File.file?(f) }

# Resume semantics: an existing repo is a previously interrupted plant — and
# safe to fill — when it is EMPTY, or when every file in it belongs to the
# PLANT SURFACE (the repo-template skeleton + the provisioner's rendered
# scaffold; e.g. the skeleton pushed but provisioning died). Any file beyond
# that surface means a grown member: absolute stop (idempotent,
# non-destructive).
PROVISION_SURFACE = ['_config.yml', '_data/navigation/main.yml'].freeze
resume = false
if system("gh repo view #{repo} >/dev/null 2>&1")
  empty = `gh repo view #{repo} --json isEmpty -q .isEmpty 2>/dev/null`.strip
  if empty == 'true'
    resume = true
  else
    tree = `gh api repos/#{repo}/git/trees/HEAD?recursive=1 --jq '.tree[] | select(.type=="blob") | .path' 2>/dev/null`
           .split("\n").map(&:strip).reject(&:empty?)
    allowed = template_files.map { |f| f.sub("#{TEMPLATE_DIR}/", '') } + PROVISION_SURFACE
    extra = tree - allowed
    unless tree.any? && extra.empty?
      die("#{repo} already exists with content beyond the plant surface " \
          "(#{extra.first(5).join(', ')}#{extra.size > 5 ? ', …' : ''}) — refusing to overwrite (idempotent, non-destructive)")
    end
    resume = true
  end
end

puts '── plant-lineage plan ───────────────────────────────────────'
puts "  id        : #{id}"
puts "  repo      : https://github.com/#{repo}   #{resume ? '(EXISTS as a plant vessel — resuming an interrupted plant)' : '(will be created, PUBLIC)'}"
puts "  subject   : #{subject}"
puts "  seed      : lineage/seeds/#{id}.md   (#{File.size(seed_path)} bytes, already authored)"
puts "  skeleton  : #{template_files.size} files from lineage/repo-template/"
puts "  provision : _config.yml + enable GitHub Pages (provision-org-sites.rb)"
puts "  then      : orchestrate.yml grows it on the next tick (no content planted here)"
puts '─────────────────────────────────────────────────────────────'

unless options[:apply]
  Hub.log_info("DRY RUN — nothing created. Re-run with: --apply --confirm #{id}")
  exit 0
end

die("--apply requires --confirm #{id} (got #{options[:confirm].inspect}) — two-key guard") unless options[:confirm] == id
die('gh is not authenticated (need repo + pages write) — run `gh auth login`') unless system('gh auth status >/dev/null 2>&1')

Hub.log_info(resume ? "Resuming interrupted plant of #{repo} …" : "Planting #{repo} …")
unless resume
  run!("gh repo create #{repo} --public --description #{Shellwords.escape("self-growing knowledge base — #{subject}")}")
end

Dir.mktmpdir do |dir|
  clone = File.join(dir, id)
  run!("git clone -q https://github.com/#{repo} #{clone}")
  template_files.each do |src|
    rel = src.sub("#{TEMPLATE_DIR}/", '')
    dst = File.join(clone, rel)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  end
  readme = File.join(clone, 'README.md')
  File.write(readme, File.read(readme, encoding: 'utf-8').gsub('__SUBJECT__', subject)) if File.exist?(readme)
  Dir.chdir(clone) do
    run!('git add -A')
    # Resuming past the skeleton (or re-copying identical files) stages
    # nothing — committing then would fail the whole plant on 'nothing to
    # commit'.
    if system('git diff --cached --quiet')
      Hub.log_info('  skeleton already present — nothing to commit')
    else
      run!("git -c user.name=claude-grow -c user.email=noreply@anthropic.com commit -q -m #{Shellwords.escape('chore: plant repo skeleton (.claude adapters + telemetry)')}")
      run!('git push -q origin HEAD:main')
    end
  end
end

# Render _config.yml + nav and enable Pages via the existing, idempotent provisioner.
run!("ruby #{Shellwords.escape(PROVISIONER)} --repos #{Shellwords.escape(id)} --direct --enable-pages")

Hub.log_info("Planted #{repo}  →  https://#{ORG}.github.io/#{id}/")
Hub.log_info("Remember to commit lineage/seeds/#{id}.md to the hub so the orchestrator grows it.")
