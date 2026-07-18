#!/usr/bin/env ruby
# =============================================================================
# run_hack_commands.rb — the Prime Directive runner
# -----------------------------------------------------------------------------
# Brand rule: "the useful thing must actually be useful. If a hack doesn't work,
# it isn't published — it becomes a Field Note about why it didn't." This check
# extracts shell blocks from hacks/tools and runs them in a locked-down sandbox.
# A block that exits non-zero is recorded as prime_directive_candidate:true —
# the seed of a Field Note.
#
# SAFETY MODEL (non-negotiable):
#   * Commands are NEVER executed on the host. They run only inside a Docker
#     container with --network=none, a read-only root, a tmpfs HOME, and a
#     non-root user. No Docker -> blocks are reported "unverified", never run.
#   * This check is NON-BLOCKING (warning/info only). A broken command must not
#     red-gate a PR; it becomes a triage signal (PR2) and a Field Note idea.
#
# MODES (env LH_PRIME_MODE):
#   optin  (default) — only run blocks the author opted in: a ```bash lh:run
#                      fence info string, or a `# lh:run` line inside the block.
#                      Prose is full of illustrative fragments and tool commands
#                      that need binaries a bare sandbox lacks; auto-running them
#                      all yields false failures and erodes trust in the gate.
#   optout           — run every bash/sh block except lines marked `# lh:norun`
#                      and blocks marked `lh:norun`. Used by the nightly sweep.
#
#   ruby scripts/ci/run_hack_commands.rb
# =============================================================================
require_relative '_lib'
require 'open3'
require 'tmpdir'

MODE = (ENV['LH_PRIME_MODE'] || 'optin').strip
# Hacks and tools are the "runnable" news sections (issue #337 moved them under
# pages/_posts/<section>/). Field notes are narrative and are not command-run.
DIRS = %w[pages/_posts/hacks pages/_posts/tools]
SHELL_LANGS = %w[bash sh shell zsh console shell-session].freeze
IMAGE = 'lifehacker-sandbox:ci'

def docker?
  out, = Open3.capture2e('docker', 'version', '--format', '{{.Server.Version}}')
  $?.success? && !out.strip.empty?
rescue StandardError
  false
end

# Extract fenced code blocks: [{lang, info, lines:[...], start_line}]
def code_blocks(body)
  blocks = []
  cur = nil
  body.each_line.with_index(1) do |line, no|
    if (m = line.chomp.match(/\A`{3,}\s*([^\s`]*)(.*)\z/)) && cur.nil?
      cur = { lang: m[1].to_s.downcase, info: "#{m[1]} #{m[2]}".downcase, lines: [], start: no }
    elsif line.strip.start_with?('```') && cur
      blocks << cur
      cur = nil
    elsif cur
      cur[:lines] << line.rstrip
    end
  end
  blocks
end

def eligible?(block)
  return false unless SHELL_LANGS.include?(block[:lang])
  return false if block[:info].include?('lh:norun')
  body = block[:lines].join("\n")
  if MODE == 'optout'
    true
  else # optin
    block[:info].include?('lh:run') || body =~ /#\s*lh:run\b/
  end
end

# Turn a documentation block into a runnable script: drop prompt markers ($, >),
# comments, blank lines, and any `# lh:norun` line.
def runnable_script(block)
  block[:lines].map { |l|
    s = l.sub(/\A\s*[\$>]\s+/, '')
    next nil if s.strip.empty? || s.strip.start_with?('#')
    next nil if l =~ /#\s*lh:norun\b/
    s
  }.compact.join("\n")
end

findings = []
have_docker = docker?
image_ready = false

if have_docker
  dockerfile = File.join(LH::ROOT, 'scripts', 'ci', 'sandbox.Dockerfile')
  _o, st = Open3.capture2e('docker', 'build', '-q', '-t', IMAGE, '-f', dockerfile, File.dirname(dockerfile))
  image_ready = st.success?
end

DIRS.each do |dir|
  Dir.glob(File.join(LH::ROOT, dir, '*.md')).sort.each do |path|
    _fm, body = LH.parse(path)
    rel = LH.rel(path)
    code_blocks(body).each do |block|
      next unless eligible?(block)
      script = runnable_script(block)
      next if script.empty?

      unless have_docker && image_ready
        findings << LH.finding(check_id: 'prime-directive', severity: 'info',
                               rule: 'unverified-no-sandbox', file: rel, line: block[:start],
                               evidence: 'shell block not verified (no Docker sandbox available)',
                               prime_directive_candidate: false)
        next
      end

      out, st = Dir.mktmpdir do |tmp|
        File.write(File.join(tmp, 'block.sh'), "set -e\n#{script}\n")
        Open3.capture2e(
          'docker', 'run', '--rm', '--network=none', '--read-only',
          '--tmpfs', '/home/run:exec', '--tmpfs', '/tmp:exec',
          '-u', 'run', '-w', '/home/run',
          '-v', "#{tmp}:/work:ro", IMAGE,
          'bash', '/work/block.sh'
        )
      end

      if st.success?
        findings << LH.finding(check_id: 'prime-directive', severity: 'info',
                               rule: 'verified', file: rel, line: block[:start],
                               evidence: 'shell block ran clean in the sandbox')
      else
        findings << LH.finding(check_id: 'prime-directive', severity: 'warning',
                               rule: 'command-failed', file: rel, line: block[:start],
                               evidence: "block exited non-zero — Field Note candidate: #{out.strip[0, 160]}",
                               prime_directive_candidate: true)
      end
    end
  end
end

LH.write('prime-directive', findings)
puts "[prime-directive] mode=#{MODE} docker=#{have_docker} image=#{image_ready}"
# Non-blocking by design: always exit 0. Failures are triage/Field-Note signal.
exit 0
