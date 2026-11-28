#!/usr/bin/env ruby
# =============================================================================
# test_content_factory_illustrate.rb — the factory's post-agent illustrator, executed
# -----------------------------------------------------------------------------
# content-factory used to tell its claude-run agent to run
# `node scripts/preview/illustrate.mjs` from the agent's own Bash tool. That
# nested Claude CLI had no login ("Not logged in"), the prompt said a failure
# "is fine", and so every factory article from 2026-10-30 on shipped without a
# motif while the job stayed green (bamr87/lifehacker.dev#842, #846).
#
# The fix moves the illustrator into a job step that runs AFTER the agent. This
# pins both halves:
#
#   static     — the prompt no longer asks the agent to illustrate; the
#                illustrator step follows "Confirm a PR was opened"; a
#                usage_report step meters it; GH_TOKEN comes from the probed
#                ./.github/actions/resolve-gh-token, not a job-level `||`.
#   behaviour  — the step's `run:` block, lifted verbatim from the workflow, is
#                driven with stubbed gh / git / node on PATH, under the shell
#                GitHub uses (bash -eo pipefail), through every path: drawn and
#                pushed, illustrator failed, no article in the PR, push
#                rejected, nothing drawn. Every path exits 0; every failure
#                path names the article in a ::warning::.
#
# No network, no secrets, stdlib only.
# Run: ruby scripts/ci/test_content_factory_illustrate.rb
# =============================================================================
require 'tmpdir'
require 'fileutils'
require_relative '_lib'

WF_PATH = ENV['LH_CONTENT_FACTORY_WF'] || File.join(LH::ROOT, '.github', 'workflows', 'content-factory.yml')
STEP    = 'Illustrate the article (post-agent)'.freeze
ARTICLE = 'pages/_posts/hacks/2026-11-28-test-hack.md'.freeze
BRANCH  = 'content/hack-test'.freeze
PR_URL  = 'https://github.com/bamr87/lifehacker.dev/pull/999'.freeze

failures = []
def check(failures, desc, ok, detail = nil)
  puts(ok ? "  ok   #{desc}" : "  FAIL #{desc}#{detail ? "\n         -> #{detail}" : ''}")
  failures << desc unless ok
end

doc   = LH.yload(File.read(WF_PATH))
job   = doc.dig('jobs', 'generate') or abort("no jobs.generate in #{WF_PATH}")
steps = job['steps'] || []

# --- 1. Static contract -----------------------------------------------------
puts "\nstatic contract"

agent_i   = steps.index { |s| s['uses'].to_s.include?('claude-run') }
confirm_i = steps.index { |s| s['name'].to_s.start_with?('Confirm a PR was opened') }
illus_i   = steps.index { |s| s['name'] == STEP }
usage_i   = steps.index { |s| s['run'].to_s.include?('usage_report') }
token_i   = steps.index { |s| s['uses'] == './.github/actions/resolve-gh-token' }

check(failures, 'the claude-run agent step exists', !agent_i.nil?)
prompt = agent_i ? steps[agent_i].dig('with', 'prompt').to_s : ''
check(failures, 'the agent prompt no longer runs illustrate.mjs', !prompt.include?('illustrate.mjs'),
      'a nested Claude CLI inside the agent has no login — the motif is never drawn')
check(failures, "a '#{STEP}' step exists", !illus_i.nil?)
check(failures, 'it runs after the agent and after the PR is confirmed',
      illus_i && agent_i && confirm_i && illus_i > agent_i && illus_i > confirm_i)
check(failures, 'a usage_report step meters it, after it', usage_i && illus_i && usage_i > illus_i,
      'the illustrator reaches a model outside claude-run; unmetered spend goes dark')
check(failures, 'no job-level GH_TOKEN (the `secrets.X || github.token` trap)',
      !(job['env'] || {}).key?('GH_TOKEN'))
check(failures, 'GH_TOKEN comes from ./.github/actions/resolve-gh-token, before the agent',
      token_i && agent_i && token_i < agent_i)
check(failures, 'the step is not continue-on-error (failures are warnings, not hidden)',
      illus_i && !steps[illus_i].key?('continue-on-error'))

if illus_i.nil?
  puts "\ncontent-factory illustrator contract: #{failures.length} FAILED (no step to execute)"
  failures.each { |f| puts "  - #{f}" }
  exit 1
end
script = steps[illus_i]['run'].to_s

# --- 2. Behavioural contract: run the shipped script ------------------------
# name => stub behaviour + expectations
CASES = {
  'drawn and pushed'     => { diff: "_data/backlog.yml\n#{ARTICLE}\n", node_rc: 0, drawn: true,  push_rc: 0,
                              warn: false, node: true,  push: true },
  'illustrator failed'   => { diff: "#{ARTICLE}\n", node_rc: 3, drawn: false, push_rc: 0,
                              warn: true,  node: true,  push: false },
  'no article in the PR' => { diff: "_data/backlog.yml\n", node_rc: 0, drawn: true, push_rc: 0,
                              warn: true,  node: false, push: false },
  'push rejected'        => { diff: "#{ARTICLE}\n", node_rc: 0, drawn: true, push_rc: 1,
                              warn: true,  node: true,  push: true },
  'nothing drawn'        => { diff: "#{ARTICLE}\n", node_rc: 0, drawn: false, push_rc: 0,
                              warn: false, node: true,  push: false }
}.freeze

puts "\nbehavioural contract (`#{STEP}` run: block lifted verbatim, bash -eo pipefail)"

Dir.mktmpdir do |tmp|
  bin = File.join(tmp, 'bin')
  FileUtils.mkdir_p(bin)
  stubs = {
    'gh' => <<~SH,
      #!/usr/bin/env bash
      echo "gh $*" >> "$CALL_LOG"
      case "$1 $2" in
        "pr view") echo "#{BRANCH}" ;;
        "pr diff") printf '%s' "$STUB_DIFF" ;;
      esac
    SH
    'git' => <<~SH,
      #!/usr/bin/env bash
      echo "git $*" >> "$CALL_LOG"
      for a in "$@"; do
        case "$a" in
          status) [ "$STUB_DRAWN" = 1 ] && echo "?? _data/preview/motifs/test-hack.svg"; exit 0 ;;
          push)   exit "$STUB_PUSH_RC" ;;
        esac
      done
      exit 0
    SH
    'node' => <<~SH
      #!/usr/bin/env bash
      echo "node $*" >> "$CALL_LOG"
      exit "$STUB_NODE_RC"
    SH
  }
  stubs.each do |name, body|
    path = File.join(bin, name)
    File.write(path, body)
    FileUtils.chmod(0o755, path)
  end

  CASES.each do |desc, c|
    work = File.join(tmp, desc.tr(' ', '-'))
    FileUtils.mkdir_p(work)
    File.write(File.join(work, 'pr-result.txt'), "#{PR_URL}\n")
    log_f = File.join(work, 'calls')
    File.write(log_f, '')

    env = {
      'PATH' => "#{bin}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH')}",
      'CALL_LOG' => log_f, 'COLLECTION' => 'hack',
      'GITHUB_OUTPUT' => File.join(work, 'out'),
      'GITHUB_REPOSITORY' => 'bamr87/lifehacker.dev', 'GH_TOKEN' => 'tok-123',
      'STUB_DIFF' => c[:diff], 'STUB_NODE_RC' => c[:node_rc].to_s,
      'STUB_DRAWN' => c[:drawn] ? '1' : '0', 'STUB_PUSH_RC' => c[:push_rc].to_s
    }
    out   = IO.popen(env, ['bash', '--noprofile', '--norc', '-eo', 'pipefail', '-c', script],
                     chdir: work, err: %i[child out], &:read)
    code  = $?.exitstatus
    calls = File.read(log_f)
    node_called = calls.lines.any? { |l| l.start_with?('node ') }
    push_line   = calls.lines.find { |l| l.start_with?('git ') && l.include?(' push ') }

    check(failures, "#{desc}: exits 0 (the job still passes)", code.zero?, "got exit #{code}\n#{out}")
    check(failures, "#{desc}: #{c[:warn] ? 'emits' : 'no'} ::warning::", out.include?('::warning::') == c[:warn], out)
    check(failures, "#{desc}: illustrator #{c[:node] ? 'runs' : 'does not run'}", node_called == c[:node], calls)
    check(failures, "#{desc}: #{c[:push] ? 'pushes' : 'does not push'}", !push_line.nil? == c[:push], calls)
    if c[:warn] && c[:node]
      check(failures, "#{desc}: the warning names the article", out.include?("no motif for #{ARTICLE}"), out)
    end
    next unless desc == 'drawn and pushed'

    check(failures, "#{desc}: illustrates the PR's article",
          calls.include?("node scripts/preview/illustrate.mjs -f #{ARTICLE}"), calls)
    check(failures, "#{desc}: checks out the PR's head branch",
          calls.include?("fetch --no-tags --depth=1 origin #{BRANCH}") && calls.include?("-C #{BRANCH} FETCH_HEAD"), calls)
    check(failures, "#{desc}: commits the motif dir", calls.include?('add -- _data/preview/motifs'), calls)
    check(failures, "#{desc}: pushes to the PR branch with the resolved token (so checks re-run)",
          push_line.to_s.include?('x-access-token:tok-123@github.com/bamr87/lifehacker.dev.git') &&
            push_line.to_s.include?("HEAD:refs/heads/#{BRANCH}"), push_line)
  end
end

puts
if failures.empty?
  puts "content-factory illustrator contract: ALL PASS (#{CASES.length} paths)"
  exit 0
else
  puts "content-factory illustrator contract: #{failures.length} FAILED"
  failures.each { |f| puts "  - #{f}" }
  exit 1
end
