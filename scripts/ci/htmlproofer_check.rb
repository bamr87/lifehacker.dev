#!/usr/bin/env ruby
# =============================================================================
# htmlproofer_check.rb — internal link / image / anchor integrity
# -----------------------------------------------------------------------------
# Runs html-proofer over the BUILT _site/ (so it checks rendered URLs, honoring
# the relative_links collection rewrite) and converts each failure into a
# finding. Internal failures are severity:error (broken internal links block the
# merge gate). External link checking is OFF here — it is flaky and not the PR
# author's fault; the nightly sweep owns it (see .github/workflows/nightly.yml).
#
# Always exits 0 and lets aggregate.rb enforce the gate from the findings, so a
# missing gem or zero _site degrades to an info finding rather than a hard crash.
#   ruby scripts/ci/htmlproofer_check.rb
# =============================================================================
require_relative '_lib'

SITE = File.join(LH::ROOT, '_site')
findings = []

begin
  require 'html-proofer'
rescue LoadError
  LH.write('htmlproofer', [LH.finding(check_id: 'htmlproofer', severity: 'info',
    rule: 'gem-missing', evidence: 'html-proofer not installed; skipped (CI installs it)')])
  exit 0
end

unless Dir.exist?(SITE)
  LH.write('htmlproofer', [LH.finding(check_id: 'htmlproofer', severity: 'info',
    rule: 'no-site', evidence: 'no _site/ to proof; run build.sh first')])
  exit 0
end

opts = {
  disable_external: true,
  allow_missing_href: true,
  ignore_empty_alt: true,
  ignore_missing_alt: true,
  swap_urls: { %r{^https://lifehacker\.dev} => '' }
}

proofer = HTMLProofer.check_directory(SITE, opts)
begin
  proofer.run
rescue StandardError
  # html-proofer raises when failures exist; we read them off the object below.
end

failures =
  if proofer.respond_to?(:failures) then proofer.failures
  elsif proofer.respond_to?(:failed_checks) then proofer.failed_checks
  else []
  end

Array(failures).each do |f|
  path = (f.respond_to?(:path) ? f.path : nil).to_s
  path = path.sub(/\A#{Regexp.escape(SITE)}\/?/, '_site/')
  line = f.respond_to?(:line) ? f.line : nil
  desc = f.respond_to?(:description) ? f.description : f.to_s
  rule = f.respond_to?(:check_name) ? "link:#{f.check_name}" : 'link'
  findings << LH.finding(check_id: 'htmlproofer', severity: 'error',
                         rule: rule, file: path, line: line,
                         evidence: desc.to_s[0, 200], route_to: 'local')
end

if findings.empty?
  findings << LH.finding(check_id: 'htmlproofer', severity: 'info',
                         rule: 'clean', evidence: 'no broken internal links, images, or anchors')
end

LH.write('htmlproofer', findings)
exit 0 # aggregate.rb enforces the gate from severity:error findings
