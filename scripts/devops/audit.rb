#!/usr/bin/env ruby
# =============================================================================
# scripts/devops/audit.rb — the CI/CD auditor (deterministic core)
# -----------------------------------------------------------------------------
# The mechanical half of the DevOps Manager: lints the whole pipeline for
# correctness, guardrail integrity, and throughput, and emits a report. The
# devops-manager skill runs this, then adds judgment (proposing/applying
# improvements). Errors mean the pipeline is mis-wired; warnings are throughput
# or hygiene; info is context. Exit non-zero on any error.
#   ruby scripts/devops/audit.rb
# =============================================================================
require_relative '../ci/_lib'

WF_DIR = File.join(LH::ROOT, '.github', 'workflows')
findings = []
def add(findings, sev, area, msg)
  findings << { sev: sev, area: area, msg: msg }
end

wf = Dir[File.join(WF_DIR, '*.yml')].sort
read = ->(p) { File.exist?(p) ? LH.read(p) : '' }
wf_read = wf.map { |f| [File.basename(f), LH.read(f)] }.to_h

# --- 1. Guardrail integrity (errors) ----------------------------------------
wf_read.each do |name, c|
  add(findings, 'error', 'least-privilege', "#{name} grants `administration` scope") if c =~ /administration:\s*(write|read)/
  add(findings, 'error', 'least-privilege', "#{name} grants `workflows` write scope") if c =~ /^\s*workflows:\s*write/
end
fleet = wf_read['fleet-dispatch.yml'].to_s
add(findings, 'error', 'autonomy-gate', 'fleet-dispatch.yml has an ACTIVE schedule (autonomy must stay opt-in)') if fleet =~ /^[^#\n]*\bschedule:/
add(findings, 'error', 'autonomy-gate', 'fleet-dispatch.yml does not read FLEET_ENABLED') unless fleet.include?('FLEET_ENABLED')

# Every autonomy workflow (one that takes an outward action automatically) must be
# gated by its ENABLED kill-switch variable, so nothing runs unattended by default.
{ 'content-factory.yml' => 'CONTENT_FACTORY_ENABLED', 'explore.yml' => 'EXPLORER_ENABLED',
  'auto-merge.yml' => 'AUTO_MERGE_ENABLED', 'auto-fix.yml' => 'AUTO_FIX_ENABLED',
  'theme-scout.yml' => 'THEME_SCOUT_ENABLED', 'agent-review.yml' => 'AGENT_REVIEW_ENABLED' }.each do |wf, gate|
  c = wf_read[wf].to_s
  add(findings, 'error', 'autonomy-gate', "#{wf} is not gated by #{gate}") unless c.empty? || c.include?(gate)
end
# Auto-merge must re-classify the PR diff (the smuggle guard): a content PR can
# never carry a deps/pipeline change past review.
am = wf_read['auto-merge.yml'].to_s
add(findings, 'error', 'auto-merge-safety', 'auto-merge.yml lacks the classify_changes smuggle guard') if !am.empty? && !am.include?('classify_changes')
# A job that pushes editorial commits with FLEET_TOKEN (to re-trigger the pipeline)
# fires a `synchronize` event — so without a loop-breaker it re-runs itself forever
# (content-review reviewing its own commit, ad infinitum). Require the synchronize
# guard on content-review. (auto-fix solves the same hazard with a MAX_ATTEMPTS cap.)
pipe_wf = wf_read['pipeline.yml'].to_s
if pipe_wf.include?('content-review:') && pipe_wf.include?('FLEET_TOKEN')
  add(findings, 'error', 'self-retrigger', "pipeline.yml content-review can loop (FLEET_TOKEN editorial push -> synchronize -> re-review); add the `github.event.action != 'synchronize'` loop-breaker to its `if`") unless pipe_wf.include?("github.event.action != 'synchronize'")
end

# Universal AI wiring: every model call must go through scripts/ai/run.sh (or the
# claude-run action that wraps it), so model/auth/fallback live in ONE place
# (_data/ai.yml). A raw `claude -p` in a workflow bypasses the fallback.
wf_read.each do |name, c|
  add(findings, 'warn', 'ai-wiring', "#{name} calls `claude -p` directly — route it through the claude-run action / scripts/ai/run.sh") if c =~ /\bclaude\s+-p\b/
end
add(findings, 'error', 'ai-wiring', 'scripts/ai/run.sh (the universal AI runner) is missing') unless File.exist?(File.join(LH::ROOT, 'scripts/ai/run.sh'))
add(findings, 'error', 'ai-wiring', 'scripts/ai/api_call.rb (the Claude API fallback) is missing') unless File.exist?(File.join(LH::ROOT, 'scripts/ai/api_call.rb'))

# OAuth-everywhere invariant: any workflow that forwards ANTHROPIC_API_KEY to an
# AI step must ALSO forward CLAUDE_CODE_OAUTH_TOKEN, so adding a key never
# silently downgrades a job to API-key-only and drops the (preferred) Claude Code
# OAuth path. Matches the env-assignment form (and the commented fleet-dispatch
# template), not prose mentions.
api_env = /ANTHROPIC_API_KEY:\s*\$\{\{\s*secrets\.ANTHROPIC_API_KEY\s*\}\}/
oauth_env = /CLAUDE_CODE_OAUTH_TOKEN:\s*\$\{\{\s*secrets\.CLAUDE_CODE_OAUTH_TOKEN\s*\}\}/
wf_read.each do |name, c|
  next unless c =~ api_env
  add(findings, 'error', 'ai-wiring', "#{name} forwards ANTHROPIC_API_KEY without CLAUDE_CODE_OAUTH_TOKEN — the OAuth path is dropped") unless c =~ oauth_env
end

# --- 2. Contract wiring (errors) --------------------------------------------
runall = read.call(File.join(LH::ROOT, 'scripts/ci/run-all.sh'))
add(findings, 'error', 'sev1-contract', 'run-all.sh does not call record_build.rb (the sev1 build finding would be lost)') unless runall.include?('record_build')
add(findings, 'error', 'sev1-contract', 'run-all.sh early-exits before aggregate on build failure') if runall =~ /build\.sh build \|\| \{[^}]*exit 1/
# A workflow that builds to feed the harness must fail safe: the build step
# `continue-on-error` + LH_BUILD_RC so a broken build becomes a sev1 finding, not
# a dead job. (run-all.sh turns LH_BUILD_RC into the record_build.rb call.) This
# pattern is shared via the build-and-harness composite; a workflow that uses it
# inherits the fail-safe (and so is exempt from the inline check below).
wf_read.each do |name, c|
  next if c.include?('build-and-harness')      # fail-safe lives in the composite
  builds = c.include?('build-overlay') || c.include?('build.sh build')
  feeds_harness = c.include?('run-all.sh') || c.include?('run_all')
  next unless builds && feeds_harness
  ok = c.include?('LH_BUILD_RC') && c.include?('continue-on-error')
  add(findings, 'warn', 'sev1-contract', "#{name} builds for the harness without the LH_BUILD_RC fail-safe (a build break would not become a sev1)") unless ok
end
# The shared composite must itself carry the fail-safe (it's the single source of
# truth for build+harness now, so the contract is verified in one place).
bh_path = File.join(LH::ROOT, '.github', 'actions', 'build-and-harness', 'action.yml')
if File.exist?(bh_path)
  bh = LH.read(bh_path)
  add(findings, 'error', 'sev1-contract', 'build-and-harness composite lacks the LH_BUILD_RC + continue-on-error fail-safe') unless bh.include?('LH_BUILD_RC') && bh.include?('continue-on-error')
end

# --- 3. Required checks present (errors/warn) -------------------------------
add(findings, 'error', 'gate', 'no workflow defines a `verify` job (the required status check)') unless wf_read.values.any? { |c| c =~ /^\s*verify:/ }
pipe = wf_read['pipeline.yml'].to_s
add(findings, 'warn', 'contract-test', 'pipeline.yml does not run the E2E simulation (contract conformance)') unless pipe.include?('simulate.rb')

# --- 4. Throughput / hygiene (warn/info) ------------------------------------
wf_read.each do |name, c|
  add(findings, 'warn', 'concurrency', "#{name} has no concurrency group (overlapping runs waste minutes)") unless c.include?('concurrency:')
  bundles = c.include?('bundle ') || c.include?('run-all.sh') || c.include?('build-overlay')
  add(findings, 'warn', 'cache', "#{name} bundles gems without bundler-cache") if c.include?('setup-ruby') && bundles && !c.include?('bundler-cache')
end
build_runs = wf_read.count { |_, c| c.include?('build-overlay') || c.include?('build.sh build') || c.include?('build-and-harness') }
add(findings, 'info', 'throughput', "#{build_runs} workflow(s) run the safe-mode build (distinct triggers — PR gate / triage / nightly); the build+harness LOGIC is shared via the build-and-harness composite")

# --- 5. Script health (errors) ----------------------------------------------
Dir[File.join(LH::ROOT, 'scripts/**/*.rb')].sort.each do |f|
  `ruby -c #{f} 2>&1`
  add(findings, 'error', 'syntax', "#{LH.rel(f)} has a Ruby syntax error") unless $?.success?
end
Dir[File.join(LH::ROOT, 'scripts/**/*.sh')].sort.each do |f|
  `bash -n #{f} 2>&1`
  add(findings, 'error', 'syntax', "#{LH.rel(f)} has a shell syntax error") unless $?.success?
end

# --- 6. Contract-schema conformance (errors) --------------------------------
# Every finding the harness writes must carry the frozen fields; every queue item
# must carry the fields PR3 leases on. Sample whatever is committed.
FIND_FIELDS  = %w[check_id severity file line rule evidence route_to prime_directive_candidate].freeze
QUEUE_FIELDS = %w[fingerprint type severity area route repo score occurrences].freeze
qf = File.join(LH::ROOT, '_data/health/queue.json')
if File.exist?(qf)
  q = JSON.parse(LH.read(qf)) rescue []
  bad = q.reject { |i| QUEUE_FIELDS.all? { |k| i.key?(k) } }
  add(findings, 'error', 'schema', "#{bad.size} queue item(s) missing required fields #{QUEUE_FIELDS.inspect}") unless bad.empty?
end

# --- report -----------------------------------------------------------------
errs = findings.count { |f| f[:sev] == 'error' }
warns = findings.count { |f| f[:sev] == 'warn' }
puts "## DevOps audit — #{errs} error, #{warns} warn, #{findings.count { |f| f[:sev] == 'info' }} info\n\n"
%w[error warn info].each do |sev|
  rows = findings.select { |f| f[:sev] == sev }
  next if rows.empty?
  puts "### #{sev}"
  rows.each { |f| puts "- [#{f[:area]}] #{f[:msg]}" }
  puts
end
Dir.mkdir(LH::RESULTS) unless Dir.exist?(LH::RESULTS)
File.write(File.join(LH::RESULTS, 'devops-audit.json'), JSON.pretty_generate(findings))
puts errs.zero? ? "PASS — pipeline is correctly wired." : "FAIL — #{errs} wiring error(s) to fix."
exit(errs.zero? ? 0 : 1)
