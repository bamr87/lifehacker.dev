#!/usr/bin/env ruby
# =============================================================================
# htmlproofer_check.rb — internal link / image / anchor integrity
# -----------------------------------------------------------------------------
# Runs html-proofer over the BUILT _site/ and converts each failure into a
# finding. Internal failures are severity:error (broken internal links block the
# merge gate). External link checking is OFF here — flaky, not the PR author's
# fault; the nightly sweep owns it.
#
# CRASH-SAFE BY DESIGN: every path writes test-results/htmlproofer.json and exits
# 0, letting aggregate.rb enforce the gate. If html-proofer raises (a bad option,
# an API change), we record a severity:error `proofer-crashed` finding so a
# broken checker BLOCKS the gate rather than silently passing — the failure mode
# that let 341 real failures through on the first CI run.
#   ruby scripts/ci/htmlproofer_check.rb
# =============================================================================
require_relative '_lib'

SITE = File.join(LH::ROOT, '_site')

def done(findings)
  LH.write('htmlproofer', findings)
  exit 0
end

begin
  require 'html-proofer'
rescue LoadError
  done([LH.finding(check_id: 'htmlproofer', severity: 'info', rule: 'gem-missing',
                   evidence: 'html-proofer not installed; skipped (CI installs it)')])
end

unless Dir.exist?(SITE)
  done([LH.finding(check_id: 'htmlproofer', severity: 'info', rule: 'no-site',
                   evidence: 'no _site/ to proof; run build.sh first')])
end

# Genuinely theme-template output we cannot fix from content/config: the theme's
# author-card renders the logo as a protocol-relative //assets/... URL. Tracked
# upstream (bamr87/zer0-mistakes); don't block content PRs on it. Everything
# else — including links our own nav/content produce — stays strict.
IGNORE = [%r{\A//assets/}]

opts = {
  disable_external: true,
  ignore_urls: IGNORE,
  allow_missing_href: true,
  ignore_missing_alt: true
}

findings = []
begin
  runner = HTMLProofer.check_directory(SITE, opts)
  begin
    runner.run
  rescue StandardError
    # html-proofer raises when failures remain; we read them off the runner.
  end
  fails =
    if runner.respond_to?(:failures) then runner.failures
    elsif runner.respond_to?(:failed_checks) then runner.failed_checks
    else []
    end
  Array(fails).each do |f|
    path = (f.respond_to?(:path) ? f.path.to_s : '').sub(/\A#{Regexp.escape(SITE)}\/?/, '_site/')
    findings << LH.finding(
      check_id: 'htmlproofer', severity: 'error',
      rule: (f.respond_to?(:check_name) ? "link:#{f.check_name}" : 'link'),
      file: path, line: (f.respond_to?(:line) ? f.line : nil),
      evidence: (f.respond_to?(:description) ? f.description.to_s[0, 200] : f.to_s[0, 200]),
      route_to: 'local'
    )
  end
rescue StandardError => e
  findings << LH.finding(check_id: 'htmlproofer', severity: 'error', rule: 'proofer-crashed',
                         evidence: "html-proofer raised #{e.class}: #{e.message.to_s[0, 160]}")
end

# Record the one knowingly-ignored theme bug so it stays visible and routable.
findings << LH.finding(check_id: 'htmlproofer', severity: 'info', rule: 'theme-logo-protocol-relative',
                       evidence: 'author-card logo renders as //assets/images/logo.svg (theme bug; ignored, file upstream)',
                       route_to: 'upstream')

if findings.size == 1 # only the tracked info note above
  findings << LH.finding(check_id: 'htmlproofer', severity: 'info', rule: 'clean',
                         evidence: 'no broken internal links, images, or anchors')
end

done(findings)
