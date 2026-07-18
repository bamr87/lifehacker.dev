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

# Genuinely theme-template output we cannot fix from this repo's content/config,
# tracked upstream (bamr87/zer0-mistakes); don't block content PRs on them.
# Everything else — including links our own nav/content produce — stays strict.
#   //assets/...      author-card logo rendered as a protocol-relative URL
#   /news/<cat>/      theme article layout's category permalink scheme (we use /categories/)
#   .github/...       theme repo doc refs leaking from a theme include
#   /archives/#...    the `news` layout's archive widget links to an /archives/ page
#                     the theme never ships (issue #337; magazine landing only)
#   #<subtopic>       the `section` layout's sub-topic sidebar renders JS filter
#                     anchors <a href="#<tag>" data-section=...> that have no
#                     scroll target in `grid` style. Scoped to the reused
#                     per-section pill vocabulary (scripts/news-enrichment.yml) so a
#                     genuinely broken same-page anchor in prose still fails.
SECTION_PILLS = %w[
  shell git ci-cd jekyll docker security web-dev data
  search files system editor productivity
  automation ai satire business engineering career
].freeze
IGNORE = [%r{\A//assets/}, %r{\A/news/}, %r{\.github/}, %r{\A/archives/},
          /\A#(?:#{SECTION_PILLS.map { |p| Regexp.escape(p) }.join('|')})\z/]

opts = {
  disable_external: true,
  enforce_https: false, # CI builds with _config_dev's url: http://localhost:4000,
                        # so the theme's canonical/SEO tags render http:// absolute
                        # URLs. HTTPS is a production concern (the .dev TLD forces it
                        # and prod url is https://lifehacker.dev) — not internal-link
                        # integrity, which is what this check is for.
  ignore_urls: IGNORE,
  allow_missing_href: true,
  ignore_missing_alt: true
}

findings = []
begin
  runner = HTMLProofer.check_directory(SITE, opts)
  begin
    runner.run
  rescue SystemExit, StandardError
    # html-proofer 5.x EXITS (SystemExit) — not just raises — when failures
    # remain. rescue StandardError alone misses that and the process dies before
    # we record anything, letting the gate pass on real failures. Catch both and
    # read the failures off the runner below.
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
rescue SystemExit, StandardError => e
  findings << LH.finding(check_id: 'htmlproofer', severity: 'error', rule: 'proofer-crashed',
                         evidence: "html-proofer raised #{e.class}: #{e.message.to_s[0, 160]}")
end

# Record the knowingly-ignored theme-origin link patterns so they stay visible
# and routable (PR2 will file these upstream automatically).
findings << LH.finding(check_id: 'htmlproofer', severity: 'info', rule: 'theme-origin-links-ignored',
                       evidence: 'ignored theme-layout links: //assets logo, /news/<cat>/ category scheme, .github refs, /archives/ archive widget, #<subtopic> section-sidebar filter anchors (file upstream)',
                       route_to: 'upstream')

if findings.size == 1 # only the tracked info note above
  findings << LH.finding(check_id: 'htmlproofer', severity: 'info', rule: 'clean',
                         evidence: 'no broken internal links, images, or anchors')
end

done(findings)
