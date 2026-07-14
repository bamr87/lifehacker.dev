#!/usr/bin/env ruby
# =============================================================================
# classify_changes.rb — change-type routing for an efficient pipeline
# -----------------------------------------------------------------------------
# Classifies a set of changed files into kinds so the pipeline runs only the
# tier each change needs: CONTENT changes run the content gate, DEPENDENCY
# changes run the full build + tests, PIPELINE changes run the audit + sim, and
# pure DATA changes skip the heavy work. Deterministic and testable: pass a file
# list (args or stdin) or let CI feed `git diff --name-only <base>...HEAD`.
#
#   git diff --name-only origin/main...HEAD | ruby scripts/ci/classify_changes.rb
#   ruby scripts/ci/classify_changes.rb pages/_hacks/x.md Gemfile
#
# Prints the kinds present (space-separated) and, in CI, writes booleans
# (content/deps/pipeline/data) to $GITHUB_OUTPUT for job-level `if:` gating.
# =============================================================================

files = (ARGV.empty? ? $stdin.read.split("\n") : ARGV).map(&:strip).reject(&:empty?)

def kind_of(path)
  case path
  when %r{\A\.github/}, %r{\A\.claude/}, %r{\Ascripts/}
    'pipeline'                                   # the machinery changed — test it all
  when %r{\AGemfile}, %r{\A_config(_dev)?\.yml\z}
    'deps'                                       # build inputs changed — full build + tests
  when %r{\A_data/(health|fleet|analytics|explorer|scout|ai_usage)/}, %r{\A(SITE_HEALTH|AI_USAGE)\.md\z}
    'data'                                       # generated state / bot run-trails — lightest path
  when %r{\Apages/},
       %r{\A_data/(brand|navigation)/},
       %r{\A_data/(authors|landing|backlog)\.yml\z},
       %r{\Aassets/},
       %r{\A(index|blog|hacks|tools|categories|tags|contact|search|sitemap)\.(md|html|json)\z},
       %r{\A404\.html\z}
    'content'                                    # publications — content quality gate
  else
    'other'
  end
end

kinds = files.map { |f| kind_of(f) }.uniq
present = %w[content deps pipeline data].map { |k| [k, kinds.include?(k)] }.to_h

# Fail safe: an empty diff, or one that touches only unclassified ('other') files,
# runs the FULL pipeline rather than silently skipping checks.
present['pipeline'] = true if files.empty? || (kinds - ['other']).empty?

if (out = ENV['GITHUB_OUTPUT'])
  File.open(out, 'a') { |io| present.each { |k, v| io.puts "#{k}=#{v}" } }
end
puts(present.select { |_, v| v }.keys.join(' '))
