#!/usr/bin/env ruby
# =============================================================================
# test_classify_changes.rb — the auto-merge smuggle-guard contract, executed
# -----------------------------------------------------------------------------
# Amendment 0005: auto-merge may ship content and data only; docs, agencies,
# dependencies, workflows, scripts and the catalog always wait for a human.
# auto-merge.yml classifies EACH changed file with classify_changes.rb and
# declines the PR when any file's kinds match its decline pattern. This test
# lifts that pattern verbatim out of the workflow (so it cannot drift from a
# copy), runs the real classifier per file, and asserts the verdict.
#
# It also pins the whole-diff routing pipeline.yml relies on: a doc beside a
# post still reads as `content`, so the content gate runs.
#
# No network, stdlib only. Run: ruby scripts/ci/test_classify_changes.rb
# =============================================================================
require 'open3'

REPO = File.expand_path('../..', __dir__)
CLASSIFIER = File.join(REPO, 'scripts/ci/classify_changes.rb')
WORKFLOW = File.join(REPO, '.github/workflows/auto-merge.yml')

pattern = File.read(WORKFLOW)[/echo "\$kinds" \| grep -qiE '([^']+)'/, 1]
abort "FAIL: could not find the smuggle-guard decline pattern in #{WORKFLOW}" unless pattern
DECLINE = Regexp.new(pattern, Regexp::IGNORECASE)

def classify(*files)
  out, status = Open3.capture2('ruby', CLASSIFIER, *files)
  abort "FAIL: classifier exited #{status.exitstatus} for #{files.inspect}" unless status.success?
  out.strip
end

# Mirrors the guard: classify each file alone, union the kinds, then match.
def declined?(files)
  kinds = files.flat_map { |f| classify(f).split }.uniq.sort.join(' ')
  kinds = 'pipeline' if kinds.empty?
  DECLINE.match?(kinds)
end

failures = []
check = lambda do |name, ok|
  puts "#{ok ? 'ok  ' : 'FAIL'} #{name}"
  failures << name unless ok
end

# Per-file kinds.
check.call('pages/_posts/hacks/x.md is content', classify('pages/_posts/hacks/x.md') == 'content')
check.call('pages/_posts/wire/x.md is content', classify('pages/_posts/wire/x.md') == 'content')
check.call('pages/_about/colophon.md is content', classify('pages/_about/colophon.md') == 'content')
check.call('pages/hacks.md is content', classify('pages/hacks.md') == 'content')
check.call('pages/_docs/x.md is not content', classify('pages/_docs/x.md') != 'content')
check.call('pages/_wargames/a/index.md is not content', classify('pages/_wargames/a/index.md') != 'content')

# The auto-merge verdicts (amendment 0005).
check.call('post-only PR auto-merges', !declined?(%w[pages/_posts/hacks/x.md assets/images/previews/x.png]))
check.call('data-only PR auto-merges', !declined?(%w[_data/health/queue.json SITE_HEALTH.md]))
check.call('doc-only PR is declined', declined?(%w[pages/_docs/x.md]))
check.call('doc + post PR is declined', declined?(%w[pages/_posts/hacks/x.md pages/_docs/x.md]))
check.call('promoted agency PR is declined', declined?(%w[pages/_wargames/a/index.md]))
check.call('agency tree PR is declined', declined?(%w[agencies/x/README.md]))
check.call('catalog PR is declined', declined?(%w[features/features.yml]))
check.call('workflow PR is declined', declined?(%w[.github/workflows/x.yml]))
check.call('dependency PR is declined', declined?(%w[Gemfile.lock]))

# Whole-diff routing (pipeline.yml): a doc beside a post keeps the content gate.
check.call('doc + post whole diff is content', classify('pages/_docs/x.md', 'pages/_posts/hacks/y.md') == 'content')

if failures.empty?
  puts 'PASS — smuggle guard holds docs and agencies for a human; posts still auto-merge.'
else
  abort "FAIL — #{failures.size} case(s): #{failures.join('; ')}"
end
