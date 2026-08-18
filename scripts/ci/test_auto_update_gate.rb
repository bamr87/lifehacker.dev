#!/usr/bin/env ruby
# =============================================================================
# test_auto_update_gate.rb — the auto-update Gate contract, executed
# -----------------------------------------------------------------------------
# auto-update's Gate used to test `secrets.FLEET_TOKEN != ''` — PRESENCE. An
# expired PAT satisfies a presence test perfectly, so every run passed the gate
# and then died in `Checkout` with "could not read Username", a message naming
# neither the token nor its expiry. That cost 135 doomed runs / 55.7m over 14
# days before anyone traced it (bamr87/bamr87#58).
#
# A regex lint would only prove the OLD string is gone. This RUNS the gate. It
# lifts the `Gate` step's `run:` block verbatim out of the workflow — so it
# exercises the shipped script, not a copy that can drift — and drives it
# through all four states with a stubbed `gh` on PATH, asserting exit code,
# `$GITHUB_OUTPUT`, the `::error::` annotation, and the API-call budget:
#
#   AUTO_UPDATE_ENABLED != true  -> exit 0, go=false, 0 API calls
#   enabled, token UNSET         -> exit 0, go=false, 0 API calls
#   enabled, token REJECTED      -> exit 1, no go=,   1 API call, ::error::
#   enabled, token LIVE          -> exit 0, go=true,  1 API call
#
# The third row is the bug: on the old gate it produced `go=true`, which is
# exactly what this pins. It fails loudly rather than idling green so the
# fleet's failure-ranked remediation loop can still see the next expiry.
#
# No network, no secrets, stdlib only — the `gh` stub is a shell script whose
# exit code the case supplies. Run: ruby scripts/ci/test_auto_update_gate.rb
# =============================================================================
require 'yaml'
require 'tmpdir'
require 'fileutils'
require_relative '_lib'

WF_PATH = ENV['LH_AUTO_UPDATE_WF'] || File.join(LH::ROOT, '.github', 'workflows', 'auto-update.yml')

failures = []
def check(failures, desc, ok, detail = nil)
  puts(ok ? "  ok   #{desc}" : "  FAIL #{desc}#{detail ? "\n         -> #{detail}" : ''}")
  failures << desc unless ok
end

raw = File.read(WF_PATH)
doc = LH.yload(raw)
steps = doc.dig('jobs', 'sync', 'steps') or abort("no jobs.sync.steps in #{WF_PATH}")

# --- 1. Static contract -----------------------------------------------------
puts "\nstatic contract"

check(failures, 'no presence-only `FLEET_TOKEN != \'\'` gate remains',
      !raw.include?("FLEET_TOKEN != ''"),
      'a presence test cannot tell a live PAT from an expired one')

gate_i     = steps.index { |s| s['name'] == 'Gate' }
checkout_i = steps.index { |s| s['name'] == 'Checkout' }
check(failures, 'a Gate step exists', !gate_i.nil?)
check(failures, 'a Checkout step exists', !checkout_i.nil?)
abort("\nauto-update gate contract: cannot continue — Gate/Checkout step missing") if gate_i.nil? || checkout_i.nil?

check(failures, 'the Gate runs BEFORE Checkout', gate_i < checkout_i,
      'probing after Checkout would still burn the doomed checkout')

script = steps[gate_i]['run'].to_s
check(failures, 'the Gate probes token validity against the API',
      script.include?('gh api') && script.include?('GH_TOKEN='),
      'no live probe found in the Gate script')
check(failures, 'the Gate receives the token value, not a boolean',
      steps[gate_i].dig('env', 'FLEET_TOKEN').to_s.include?('secrets.FLEET_TOKEN'),
      'a boolean `secrets.FLEET_TOKEN != \'\'` cannot be probed')
check(failures, 'Checkout still pins actions/checkout@v7',
      steps[checkout_i]['uses'] == 'actions/checkout@v7')

# --- 2. Behavioural contract: run the shipped script ------------------------
# (enabled, token, stub gh exit code) -> (expected exit, expected output, calls, annotation)
CASES = [
  ['disabled',            'false', 'tok', 0, 0, 'go=false', 0, false],
  ['enabled, no token',   'true',  '',    0, 0, 'go=false', 0, false],
  ['enabled, bad token',  'true',  'tok', 1, 1, '',         1, true],
  ['enabled, good token', 'true',  'tok', 0, 0, 'go=true',  1, false]
].freeze

puts "\nbehavioural contract (Gate `run:` block lifted verbatim from the workflow)"
puts format('  %-22s %-5s %-5s %-9s %-5s', 'case', 'exit', 'calls', 'output', 'error')

Dir.mktmpdir do |tmp|
  bin = File.join(tmp, 'bin')
  FileUtils.mkdir_p(bin)
  stub = File.join(bin, 'gh')
  File.write(stub, <<~SH)
    #!/usr/bin/env bash
    echo "$*" >> "$GH_CALL_LOG"
    exit "${STUB_GH_RC:-0}"
  SH
  FileUtils.chmod(0o755, stub)

  CASES.each do |desc, enabled, token, stub_rc, want_exit, want_out, want_calls, want_err|
    out_f = File.join(tmp, 'out'); File.write(out_f, '')
    log_f = File.join(tmp, 'log'); File.write(log_f, '')

    env = {
      'PATH' => "#{bin}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH')}",
      'ENABLED' => enabled, 'FLEET_TOKEN' => token,
      'GITHUB_OUTPUT' => out_f, 'GH_CALL_LOG' => log_f,
      'GITHUB_REPOSITORY' => 'bamr87/lifehacker.dev',
      'STUB_GH_RC' => stub_rc.to_s
    }
    stdout_str = IO.popen(env, ['bash', '-c', script], err: [:child, :out], &:read)
    code  = $?.exitstatus
    got   = File.read(out_f).strip
    calls = File.read(log_f).lines.count { |l| !l.strip.empty? }
    err   = stdout_str.include?('::error::')

    puts format('  %-22s %-5s %-5s %-9s %-5s', desc, code, calls, got.empty? ? '(none)' : got, err)

    check(failures, "#{desc}: exit #{want_exit}", code == want_exit, "got exit #{code}")
    check(failures, "#{desc}: output #{want_out.empty? ? '(none)' : want_out}", got == want_out, "got #{got.inspect}")
    check(failures, "#{desc}: #{want_calls} API call(s)", calls == want_calls, "got #{calls}")
    check(failures, "#{desc}: #{want_err ? 'emits' : 'no'} ::error::", err == want_err)
    # The whole point: a rejected token must NOT gate quietly to go=false.
    check(failures, "#{desc}: never silently go=false on a rejected token", got != 'go=false') if want_err
  end
end

puts
if failures.empty?
  puts "auto-update gate contract: ALL PASS (#{CASES.length} states)"
  exit 0
else
  puts "auto-update gate contract: #{failures.length} FAILED"
  failures.each { |f| puts "  - #{f}" }
  exit 1
end
