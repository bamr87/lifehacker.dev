#!/usr/bin/env ruby
# =============================================================================
# scripts/sim/simulate.rb — end-to-end simulation of the combined autopilot
# -----------------------------------------------------------------------------
# Bootstraps synthetic scenarios and drives them through the REAL code of all
# three layers — the test harness's fingerprint scheme, the triage ranking
# (Triage.build), and the fleet decision (Fleet::Plan.compute) — asserting that
# the contracts hold *between* the layers, not just within them. Then it checks
# the cross-cutting invariants (no-close, no-merge, kill switch, no schedule, no
# admin scope, quarantine) statically. Deterministic; no gh, no network.
#
#   ruby scripts/sim/simulate.rb        # exits non-zero if any assertion fails
# =============================================================================
require 'digest'
require_relative '../triage/_lib'   # Triage + LH (reuses scripts/ci/_lib)
require_relative '../fleet/plan'    # Fleet::Plan + Fleet::Policy

CAPS = LH.yload(LH.read(File.join(LH::ROOT, '_data', 'fleet', 'budget.yml')))

# Build a finding exactly as aggregate.rb would (same fingerprint scheme), so the
# simulation exercises the real dedup identity.
def fp(check_id, file, rule)
  Digest::SHA1.hexdigest("#{check_id}|#{file.to_s.downcase}|#{rule}")[0, 12]
end

def finding(check_id:, severity:, rule:, file: '', line: nil, evidence: '', route_to: 'local', pdc: false)
  { 'check_id' => check_id, 'severity' => severity, 'file' => file, 'line' => line,
    'rule' => rule, 'evidence' => evidence, 'route_to' => route_to,
    'prime_directive_candidate' => pdc, 'fingerprint' => fp(check_id, file, rule) }
end

def todo(id, title)
  { 'id' => id, 'status' => 'todo', 'title' => title }
end

$pass = 0
$fail = 0
def check(name, cond, detail = '')
  ok = !!cond
  ok ? ($pass += 1) : ($fail += 1)
  puts "  #{ok ? 'PASS' : 'FAIL'}  #{name}#{detail.empty? ? '' : "  (#{detail})"}"
  ok
end
def scenario(name)
  puts("\n• #{name}")
end

# ---------------------------------------------------------------------------
scenario 'healthy site — grow, do not fix'
q = Triage.build([
  finding(check_id: 'brand',       severity: 'warning', file: 'pages/_hacks/x.md', rule: 'banned-when-sincere:just'),
  finding(check_id: 'frontmatter', severity: 'warning', file: 'pages/_tools/y.md', rule: 'description-too-long')
])
check('queue built from findings', q.size == 2, "size=#{q.size}")
check('no sev1/sev2 when only warnings', q.none? { |i| %w[sev1 sev2].include?(i['severity']) })
d = Fleet::Plan.compute(queue: q, backlog: [todo('A', 'a'), todo('B', 'b'), todo('C', 'c')], open_prs: 0, caps: CAPS)
check('clean mode', d[:decision][:mode] == 'clean')
check('grows 2, fixes 0', d[:decision][:slots][:grow] == 2 && d[:decision][:slots][:fix] == 0)
check('dispatches two growers', d[:dispatched].count { |x| x[:role] == 'grow-lifehacker' } == 2)

# ---------------------------------------------------------------------------
scenario 'sev1 build break — freeze growth, all hands fixing'
q = Triage.build([finding(check_id: 'build', severity: 'error', rule: 'jekyll-build-failed', evidence: 'build failed')])
check('build error becomes a sev1', q.any? { |i| i['severity'] == 'sev1' && i['type'] == 'type/build-break' })
d = Fleet::Plan.compute(queue: q, backlog: [todo('A', 'a'), todo('B', 'b')], open_prs: 0, caps: CAPS)
check('sev1 mode', d[:decision][:mode] == 'sev1')
check('growth FROZEN (grow=0)', d[:decision][:slots][:grow] == 0)
check('dispatches only fixers', !d[:dispatched].empty? && d[:dispatched].all? { |x| x[:role] == 'fleet-bugfix' })

# ---------------------------------------------------------------------------
scenario 'link rot — dedup by fingerprint across many occurrences'
many = Array.new(10) { |i| finding(check_id: 'htmlproofer', severity: 'error', file: '_site/page/index.html', rule: 'link:Links', line: 100 + i) }
q = Triage.build(many)
check('10 findings collapse to 1 queue item', q.size == 1, "size=#{q.size}")
check('occurrences counted (10)', q.first && q.first['occurrences'] == 10)
check('classified link-rot sev2', q.first && q.first['type'] == 'type/link-rot' && q.first['severity'] == 'sev2')

# ---------------------------------------------------------------------------
scenario 'backpressure — at MAX_OPEN_PRS, launch nothing'
q = Triage.build([finding(check_id: 'htmlproofer', severity: 'error', file: '_site/a/index.html', rule: 'link:Links')])
d = Fleet::Plan.compute(queue: q, backlog: [todo('A', 'a')], open_prs: CAPS.dig('caps', 'max_open_prs'), caps: CAPS)
check('backpressure mode', d[:decision][:mode] == 'backpressure')
check('nothing dispatched at the cap', d[:dispatched].empty?)

# ---------------------------------------------------------------------------
scenario 'theme bug — routes upstream, not local'
q = Triage.build([finding(check_id: 'htmlproofer', severity: 'info', rule: 'theme-origin-links-ignored', route_to: 'upstream')])
check('upstream item present', q.size == 1)
check('routed to the theme repo', q.first && q.first['route'] == 'upstream' && q.first['repo'] == 'bamr87/zer0-mistakes')

# ---------------------------------------------------------------------------
scenario 'fingerprint integrity — findings -> queue -> issue dedup marker'
f = finding(check_id: 'frontmatter', severity: 'error', file: 'pages/_hacks/z.md', rule: 'missing-key:tags')
item = Triage.build([f]).first
check('queue preserves the finding fingerprint', item && item['fingerprint'] == f['fingerprint'])
check('issue body carries the triage-fp marker', Triage.issue_body(item).include?("triage-fp: #{f['fingerprint']}"))

# ---------------------------------------------------------------------------
scenario 'severity dominates reach — a sev1 outranks a popular sev4'
q = Triage.build([
  finding(check_id: 'build', severity: 'error', rule: 'jekyll-build-failed'),
  finding(check_id: 'brand', severity: 'warning', file: 'pages/_hacks/x.md', rule: 'banned-when-sincere:just')
])
check('sev1 sorts above sev4 regardless of reach', q.first['severity'] == 'sev1')

# ---------------------------------------------------------------------------
scenario 'severity-tier translation — ONLY build is sev1'
samples = {
  'build'        => finding(check_id: 'build',         severity: 'error',   rule: 'jekyll-build-failed'),
  'htmlproofer'  => finding(check_id: 'htmlproofer',   severity: 'error',   file: '_site/a/index.html', rule: 'link:Links'),
  'frontmatter'  => finding(check_id: 'frontmatter',   severity: 'error',   file: 'pages/_hacks/a.md',  rule: 'missing-key:tags'),
  'fm-warn'      => finding(check_id: 'frontmatter',   severity: 'warning', file: 'pages/_hacks/b.md',  rule: 'description-too-long'),
  'drift'        => finding(check_id: 'drift',         severity: 'error',   file: '_data/backlog.yml',  rule: 'backlog-published-deadlink'),
  'brand-avoid'  => finding(check_id: 'brand',         severity: 'error',   file: 'pages/_hacks/c.md',  rule: 'avoid-phrase'),
  'brand-cand'   => finding(check_id: 'brand',         severity: 'warning', file: 'pages/_hacks/d.md',  rule: 'banned-when-sincere:just')
}
tiers = samples.map { |k, f| [k, Triage.build([f]).first && Triage.build([f]).first['severity']] }.to_h
check('only the build check yields sev1', tiers.select { |_, v| v == 'sev1' }.keys == ['build'], tiers.inspect)
check('htmlproofer error -> sev2', tiers['htmlproofer'] == 'sev2')
check('frontmatter missing-key -> sev2', tiers['frontmatter'] == 'sev2')
check('frontmatter description -> sev4', tiers['fm-warn'] == 'sev4')
check('drift deadlink -> sev2', tiers['drift'] == 'sev2')
check('brand avoid-phrase -> sev3, candidate -> sev4', tiers['brand-avoid'] == 'sev3' && tiers['brand-cand'] == 'sev4')
check('record_build.rb is the canonical sev1 producer',
      LH.read(File.join(LH::ROOT, 'scripts/ci/record_build.rb')) =~ /check_id:\s*'build'.*severity:\s*'error'.*rule:\s*'jekyll-build-failed'/m)

# ---------------------------------------------------------------------------
scenario 'actionable? filtering — info dropped EXCEPT upstream tracker'
q = Triage.build([
  finding(check_id: 'htmlproofer', severity: 'info', rule: 'clean'),
  finding(check_id: 'htmlproofer', severity: 'info', rule: 'gem-missing'),
  finding(check_id: 'htmlproofer', severity: 'info', rule: 'theme-origin-links-ignored', route_to: 'upstream'),
  finding(check_id: 'frontmatter', severity: 'warning', file: 'pages/_hacks/x.md', rule: 'description-too-long')
])
check('clean/gem-missing info dropped; upstream info + warning kept', q.size == 2, "size=#{q.size}")
check('the surviving info is the upstream tracker', q.any? { |i| i['route'] == 'upstream' })

# ---------------------------------------------------------------------------
scenario 'missing/empty queue fail-safe — absence is NOT "safe to grow"'
stale = Fleet::Plan.compute(queue: [], backlog: [todo('A', 'a')], open_prs: 0, caps: CAPS, fresh: false)
check('stale/missing queue -> mode "stale", not "clean"', stale[:decision][:mode] == 'stale')
check('stale queue dispatches nothing', stale[:dispatched].empty?)
healthy = Fleet::Plan.compute(queue: [], backlog: [todo('A', 'a')], open_prs: 0, caps: CAPS, fresh: true)
check('a FRESH empty queue (genuinely healthy) does grow', healthy[:decision][:mode] == 'clean' && healthy[:decision][:slots][:grow] >= 1)

# ---------------------------------------------------------------------------
scenario 'prime-directive candidate survives the boundary + is not a bugfix'
pd = finding(check_id: 'prime-directive', severity: 'warning', file: 'pages/_hacks/z.md', rule: 'command-failed', pdc: true)
item = Triage.build([pd]).first
check('queue item keeps prime_directive_candidate=true', item['prime_directive_candidate'] == true)
check('classified type/field-note-candidate', item['type'] == 'type/field-note-candidate')
plan = Fleet::Plan.compute(queue: [item], backlog: [todo('A', 'a')], open_prs: 0, caps: CAPS)
check('field-note candidate NEVER leased to fleet-bugfix', plan[:dispatched].none? { |d| d[:role] == 'fleet-bugfix' })

# ---------------------------------------------------------------------------
scenario 'sev2 reserved grower is not starved by saturating fixers'
manyfix = Array.new(8) { |i| finding(check_id: 'htmlproofer', severity: 'error', file: "_site/p#{i}/index.html", rule: 'link:Links') }
plan = Fleet::Plan.compute(queue: Triage.build(manyfix), backlog: [todo('A', 'a'), todo('B', 'b')], open_prs: 0, caps: CAPS)
check('sev2 mode keeps grow >= 1 even with many fixers', plan[:decision][:mode] == 'sev2' && plan[:decision][:slots][:grow] >= 1, plan[:decision].inspect)

# ---------------------------------------------------------------------------
scenario 'idempotency + analytics outage'
src = [finding(check_id: 'brand', severity: 'warning', file: 'pages/_hacks/x.md', rule: 'banned-when-sincere:just'),
       finding(check_id: 'htmlproofer', severity: 'error', file: '_site/a/index.html', rule: 'link:Links')]
check('Triage.build is deterministic (byte-identical twice)', Triage.build(src).to_json == Triage.build(src).to_json)
check('analytics cache is stale -> reach defaults to 1.0, severity dominates', !!Triage.analytics['stale'])

# ---------------------------------------------------------------------------
scenario 'AI metering — capture -> ledger -> summary (the cost contract)'
require_relative '../ai/usage'
require_relative '../ai/usage_ledger'
require 'tmpdir'
Dir.mktmpdir do |tmp|
  ENV['LH_AI_LEDGER_DIR'] = tmp

  # A Claude Code result payload (the probed schema run.sh captures).
  fixture = {
    'type' => 'result', 'is_error' => false, 'duration_ms' => 3161, 'num_turns' => 7,
    'result' => 'ok', 'session_id' => 'sess-1', 'total_cost_usd' => 1.25,
    'usage' => { 'input_tokens' => 10, 'output_tokens' => 3800,
                 'cache_read_input_tokens' => 17_506, 'cache_creation_input_tokens' => 8550 },
    'modelUsage' => { 'claude-opus-4-8' => { 'inputTokens' => 10, 'outputTokens' => 3800,
                                             'cacheReadInputTokens' => 17_506, 'cacheCreationInputTokens' => 8550,
                                             'costUSD' => 1.25 } },
    'uuid' => 'fixture-uuid-1'
  }
  rec = AIUsage.from_claude_result(fixture, agent: 'grow-lifehacker')
  check('claude result -> record keeps the REPORTED cost', rec['cost_usd'] == 1.25 && rec['cost_source'] == 'reported')
  check('record identifies the primary model', rec['model'] == 'claude-opus-4-8')
  rec.merge!('ts' => '2026-07-10T00:00:00Z', 'workflow' => 'content-factory', 'pr' => 42, 'pr_source' => 'created')

  # The API fallback reports tokens but no dollars -> estimated from the table
  # (opus 4.8: 1000 in x $5/MTok + 1000 out x $25/MTok = $0.03).
  api = AIUsage.from_api_response({ 'id' => 'msg_1', 'model' => 'claude-opus-4-8', 'stop_reason' => 'end_turn',
                                    'usage' => { 'input_tokens' => 1000, 'output_tokens' => 1000 } },
                                  agent: 'brand-reviewer')
  check('api fallback -> ESTIMATED cost from _data/ai_pricing.yml', api['cost_source'] == 'estimated' && (api['cost_usd'] - 0.03).abs < 1e-9, "cost=#{api['cost_usd']}")
  api.merge!('ts' => '2026-07-11T00:00:00Z', 'workflow' => 'pipeline', 'pr' => 42, 'pr_source' => 'event')

  # Batch them like an uploaded run artifact and ingest TWICE — the ledger's
  # dedup-by-id is what makes re-sweeping artifacts always safe.
  drop = File.join(tmp, 'artifacts')
  FileUtils.mkdir_p(drop)
  File.write(File.join(drop, 'reported-1.jsonl'), [rec, api].map { |r| JSON.generate(r) }.join("\n") + "\n")
  first  = AIUsageLedger.ingest(drop)
  second = AIUsageLedger.ingest(drop)
  check('ledger ingest is idempotent (2 new, then 0)', first == 2 && second.zero?, "#{first}/#{second}")

  s = AIUsageLedger.summarize(now: Time.utc(2026, 7, 14))
  check('summary totals combine both paths', s['all_time']['calls'] == 2 && (s['all_time']['cost_usd'] - 1.28).abs < 0.001, s['all_time'].inspect)
  p42 = (s['top_prs'] || []).find { |x| x['pr'] == 42 }
  check('a PR splits creation vs downstream cost', p42 && p42['creation_usd'] == 1.25 && (p42['downstream_usd'] - 0.03).abs < 0.001, p42.inspect)
  check('summary.yml written for the Liquid dashboard', File.exist?(File.join(tmp, 'summary.yml')))
end
ENV.delete('LH_AI_LEDGER_DIR')

# ---------------------------------------------------------------------------
scenario 'kill-switch matrix — only the exact string "true" runs the fleet'
disp = File.join(LH::ROOT, 'scripts/fleet/dispatch.rb')
[%w[empty ''], %w[false false], %w[upper TRUE], %w[zero 0], %w[yes yes]].each do |label, val|
  out = `FLEET_ENABLED=#{val} ruby #{disp} 2>&1`
  check("FLEET_ENABLED=#{label} -> dispatcher idle", out.include?('idle'))
end
check('FLEET_ENABLED unset -> idle', `env -u FLEET_ENABLED ruby #{disp} 2>&1`.include?('idle'))
check('dispatcher gates on EXACTLY "true"', LH.read(disp).include?("ENV['FLEET_ENABLED'].to_s == 'true'"))

# ---------------------------------------------------------------------------
scenario 'guardrail invariants survive end-to-end (static)'
filer = LH.read(File.join(LH::ROOT, 'scripts/triage/file_issues.rb'))
check('filer never runs `gh issue close`', !filer.match?(/gh\s+issue\s+close/))
check('filer never runs `gh pr merge`',   !filer.match?(/gh\s+pr\s+merge/))
disp = LH.read(File.join(LH::ROOT, 'scripts/fleet/dispatch.rb'))
check('dispatcher honors FLEET_ENABLED kill switch', disp.include?('FLEET_ENABLED'))
fw = LH.read(File.join(LH::ROOT, '.github/workflows/fleet-dispatch.yml'))
check('fleet workflow has NO active schedule', !fw.match?(/^[^#\n]*\bschedule:/))
check('fleet workflow grants NO administration scope', !fw.match?(/administration:\s*(write|read)/))
check('untrusted-input quarantine doc present', File.exist?(File.join(LH::ROOT, '.claude/skills/_shared/quarantine.md')))

# ---------------------------------------------------------------------------
puts "\n[simulate] #{$pass} passed, #{$fail} failed across the end-to-end contract flow"
exit($fail.zero? ? 0 : 1)
