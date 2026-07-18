# =============================================================================
# scripts/triage/_lib.rb — shared logic for the lifehacker.dev triage layer
# -----------------------------------------------------------------------------
# Turns PR1's findings into a classified, scored, deduplicated work queue. Pure
# functions (no gh / no network) so build_queue.rb is fully testable; the
# side-effecting gh calls live in file_issues.rb. Reuses scripts/ci/_lib.rb for
# YAML/JSON reading and the repo root.
# =============================================================================
require_relative '../ci/_lib'

module Triage
  ROOT      = LH::ROOT
  HEALTH    = File.join(ROOT, '_data', 'health')
  ANALYTICS = File.join(ROOT, '_data', 'analytics', 'summary.json')
  THIS_REPO = 'bamr87/lifehacker.dev'
  THEME_REPO = 'bamr87/zer0-mistakes'

  # severity tier -> weight. Severity DOMINATES the score: the sev1 weight (8)
  # exceeds the maximum any reach multiplier (2.0) can lift a sev3 (2*2=4) to, so
  # a critical build break always outranks a popular-but-cosmetic nit.
  SEV_WEIGHT = { 'sev1' => 8, 'sev2' => 5, 'sev3' => 2, 'sev4' => 1 }.freeze
  CONF = { 'error' => 1.0, 'warning' => 0.7, 'info' => 0.4 }.freeze

  module_function

  # Keep only findings worth a tracked issue: real errors/warnings, plus the
  # one upstream-routed info note (the theme-origin link tracker). Drop "clean",
  # "gem-missing", "search-json-unchecked" and the like.
  def actionable?(f)
    return true if %w[error warning].include?(f['severity'])
    f['severity'] == 'info' && f['route_to'].to_s == 'upstream'
  end

  # finding -> {type, area, severity (tier), route, repo}
  def classify(f)
    cid  = f['check_id'].to_s
    rule = f['rule'].to_s
    err  = f['severity'] == 'error'

    type, area, sev =
      case cid
      when 'build'
        ['type/build-break', 'area/build', 'sev1']
      when 'htmlproofer'
        ['type/link-rot', 'area/content', err ? 'sev2' : 'sev4']
      when 'frontmatter'
        if rule == 'description-too-long'
          ['type/content-polish', 'area/content', 'sev4']
        else
          ['type/content-bug', 'area/content', 'sev2']
        end
      when 'drift'
        ['type/drift', 'area/site', err ? 'sev2' : 'sev4']
      when 'brand'
        rule == 'avoid-phrase' ? ['type/brand-lint', 'area/voice', 'sev3']
                               : ['type/brand-lint', 'area/voice', 'sev4']
      when 'prime-directive'
        ['type/field-note-candidate', 'area/content', 'sev3']
      else
        ['type/other', 'area/site', 'sev4']
      end

    route = f['route_to'].to_s.empty? ? 'local' : f['route_to'].to_s
    repo  = route == 'upstream' ? THEME_REPO : THIS_REPO
    { type: type, area: area, severity: sev, route: route, repo: repo }
  end

  # Map a finding's file to the public URL it affects (for reach lookup). nil for
  # non-page findings (a data file, the whole build).
  def url_for(file)
    return nil if file.nil? || file.empty?
    if file.start_with?('_site/')
      return file.sub(%r{\A_site}, '').sub(%r{index\.html\z}, '')
    end
    # News sections (issue #337): pages/_posts/<section>/<date>-<slug>.md keep
    # their classic URLs — hacks/tools by slug, field notes by date.
    if (ns = file.match(%r{\Apages/_posts/(hacks|tools|field-notes)/(\d{4})-(\d{2})-(\d{2})-(.+)\.md\z}))
      sec, y, mo, d, slug = ns.captures
      return "/hacks/#{slug}/" if sec == 'hacks'
      return "/tools/#{slug}/" if sec == 'tools'
      return "/posts/#{y}/#{mo}/#{d}/#{slug}/"
    end
    m = file.match(%r{\Apages/_(\w+)/(.+)\.md\z})
    return nil unless m
    coll, name = m[1], m[2]
    case coll
    when 'posts' then (name =~ /\A(\d{4})-(\d{2})-(\d{2})-(.+)\z/ ? "/posts/#{$1}/#{$2}/#{$3}/#{$4}/" : nil)
    when 'docs'  then "/docs/#{name}/"
    when 'about' then "/about/#{name}/"
    end
  end

  def analytics
    @analytics ||= (File.exist?(ANALYTICS) ? (JSON.parse(LH.read(ANALYTICS)) rescue {}) : {})
  end

  def reach_views(url)
    return 0 if url.nil?
    (analytics['pages'] || {})[url].to_i
  end

  # 28-day pageviews -> a gentle multiplier. Unknown/zero -> 1.0 so a GA outage
  # never blocks ranking; severity still dominates.
  def reach_mult(views)
    return 1.0 if views <= 0
    return 1.2 if views < 100
    return 1.5 if views < 1000
    2.0
  end

  # RICE-ish: (reach x severity x confidence) / effort. Upstream items cost more
  # (we don't own the fix) so they rank slightly lower at equal severity.
  def score(tier, finding_severity, views, route)
    effort = route == 'upstream' ? 2.0 : 1.0
    w = SEV_WEIGHT[tier] || 1
    c = CONF[finding_severity] || 0.5
    ((reach_mult(views) * w * c) / effort).round(2)
  end

  # Stable issue title from a finding (fingerprint keeps identity; title is human).
  def issue_title(item)
    loc = item['url_path'] || item['file']
    "[#{item['severity']}] #{item['type'].split('/').last}: #{item['rule']}#{loc && !loc.empty? ? " (#{loc})" : ''}"
  end

  # The issue body carries the fingerprint marker file_issues.rb dedups on.
  def issue_body(item)
    <<~BODY
      <!-- triage-fp: #{item['fingerprint']} -->
      Filed by the lifehacker.dev triage bot from the test harness. A human triages and closes.

      | field | value |
      |---|---|
      | check | `#{item['check_id']}` |
      | rule | `#{item['rule']}` |
      | where | `#{item['file']}#{item['line'] ? ":#{item['line']}" : ''}` |
      | severity | #{item['severity']} |
      | route | #{item['route']} |
      | RICE score | #{item['score']} |

      **Evidence**

      > #{item['evidence']}

      _Fingerprint `#{item['fingerprint']}` is stable across line shifts — re-running triage updates this issue instead of filing a duplicate._
    BODY
  end

  # PURE: findings array -> ranked, deduplicated queue items. The whole triage
  # ranking, with no IO — build_queue.rb writes the files, the E2E simulation
  # asserts on the result, both calling THIS so they can't diverge.
  def build(findings)
    groups = Hash.new { |h, k| h[k] = [] }
    findings.each { |f| groups[f['fingerprint']] << f if actionable?(f) }

    items = groups.map do |fp, fs|
      rep   = fs.min_by { |f| { 'error' => 0, 'warning' => 1, 'info' => 2 }[f['severity']] || 3 }
      c     = classify(rep)
      url   = url_for(rep['file'])
      views = reach_views(url)
      item = {
        'fingerprint' => fp, 'check_id' => rep['check_id'], 'rule' => rep['rule'],
        'file' => rep['file'], 'line' => rep['line'], 'evidence' => rep['evidence'],
        'type' => c[:type], 'area' => c[:area], 'severity' => c[:severity],
        'route' => c[:route], 'repo' => c[:repo], 'url_path' => url,
        'reach_views' => views, 'occurrences' => fs.size,
        # Carry the Field-Note signal across the queue boundary so file_issues.rb
        # can label/route prime-directive candidates distinctly downstream.
        'prime_directive_candidate' => !!rep['prime_directive_candidate'],
        'score' => score(c[:severity], rep['severity'], views, c[:route]),
        'issue_number' => nil, 'blocked_on' => nil
      }
      item['title'] = issue_title(item)
      item
    end

    items.sort_by { |i| [-i['score'], i['severity'], i['file'].to_s] }
  end
end
