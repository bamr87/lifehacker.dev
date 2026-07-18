# =============================================================================
# scripts/explorer/_lib.rb — shared logic for the site-explorer / persona agent
# -----------------------------------------------------------------------------
# The explorer skill BROWSES the live site and writes raw observations as JSONL.
# This file owns the deterministic part: turning a free-form observation into a
# *stable fingerprint* (so two runs that hit the same problem dedup), into a
# *route* (GitHub issue now vs a backlog idea for later), and into the labels
# the triage queue already understands.
#
# The judgement (is this confusing? is this a gap?) is the agent's, made while
# looking at the page. Everything DOWNSTREAM of that judgement is mechanical and
# lives here, so it is testable with no browser and no network. file_findings.rb
# does the side-effecting `gh` calls; this module stays pure.
#
# Reuses scripts/ci/_lib.rb for the repo root, UTF-8 reads, and — crucially — the
# SAME fingerprint recipe family the test harness uses, so explorer issues sit in
# the same dedup namespace as triage issues (a human never sees two issues for
# one problem from two different bots).
#
# Stdlib only (Digest/JSON/YAML) — runs on Ruby 2.6 local and 3.3 CI. No
# endless-method defs.
# =============================================================================
require 'digest'
require_relative '../ci/_lib'

module Explorer
  ROOT      = LH::ROOT
  DATA      = File.join(ROOT, '_data', 'explorer')
  FINDINGS  = File.join(DATA, 'findings.jsonl')   # raw observations from the run
  SEEN      = File.join(DATA, 'seen.json')        # fingerprint -> first/last seen, count
  THIS_REPO = 'bamr87/lifehacker.dev'
  SITE      = 'https://lifehacker.dev'

  # The three lenses. Each persona has a budget of pages and a question it asks.
  PERSONAS = %w[beginner intermediate expert].freeze

  # What an observation can BE. This is the closed vocabulary the agent must pick
  # from — an open-ended "kind" would never dedup. The route decides issue-now vs
  # backlog-later: a broken thing is a bug (issue); a missing thing is an idea
  # (backlog). persona-mismatch is the explorer's signature category — content
  # that is fine in the abstract but wrong for who is reading it.
  #
  #   kind                  -> [type-label,            area,          default-sev, route]
  KINDS = {
    'broken-ux'           => ['type/ux-bug',          'area/site',    'sev2', :issue],
    'broken-link'         => ['type/link-rot',        'area/content', 'sev2', :issue],
    'accessibility'       => ['type/a11y',            'area/site',    'sev2', :issue],
    'console-error'       => ['type/ux-bug',          'area/site',    'sev3', :issue],
    'confusing-content'   => ['type/content-polish',  'area/content', 'sev3', :issue],
    'persona-mismatch'    => ['type/persona-mismatch','area/content', 'sev3', :issue],
    'content-gap'         => ['type/content-gap',     'area/content', 'sev4', :backlog],
    'idea'                => ['type/content-gap',     'area/content', 'sev4', :backlog]
  }.freeze

  module_function

  def kinds
    KINDS.keys
  end

  # Normalize a live URL to a stable path key. The fingerprint must NOT depend on
  # the host, the scheme, a trailing query string, or a fragment — the SAME page
  # reached two different ways has to collapse to one identity. We keep the path,
  # force a trailing slash (Jekyll pretty-URLs), and lowercase it.
  def path_key(url)
    return '/' if url.nil? || url.empty?
    u = url.to_s.strip
    u = u.sub(%r{\Ahttps?://[^/]+}i, '')   # drop scheme+host
    u = u.split('#', 2).first.to_s         # drop fragment
    u = u.split('?', 2).first.to_s         # drop query
    u = '/' if u.empty?
    u = "/#{u}" unless u.start_with?('/')
    u = "#{u}/" unless u.end_with?('/') || u =~ /\.[a-z0-9]{2,5}\z/i
    u.downcase
  end

  # Collapse a free-text observation to a short, stable token so two runs that
  # describe the same problem in different words still fingerprint identically.
  # We DON'T hash the prose (it varies run to run); we hash a normalized "signal":
  # lowercase, strip punctuation, keep the first few salient words. The agent is
  # told to lead its `signal` with the stable noun ("nav contrast", "missing
  # prereqs", "404 on theme link") — that discipline is what makes dedup work.
  def signal_token(signal)
    s = signal.to_s.downcase
    s = s.gsub(/[^a-z0-9 ]+/, ' ').gsub(/\s+/, ' ').strip
    words = s.split(' ').reject { |w| STOP.include?(w) }
    words.first(6).join('-')
  end

  STOP = %w[the a an is are of to and or on in for with this that it as be too very
            page site content but so when where why how you your i we our].freeze

  # The fingerprint. SAME shape as scripts/ci/aggregate.rb
  #   SHA1("<check>|<file/loc>|<rule>")[0,12]
  # so explorer issues share the dedup namespace with harness/triage issues.
  # Here: check_id is always "explorer", the "file" slot is the path_key (the
  # page), and the "rule" slot is "<kind>:<signal_token>". Persona is deliberately
  # NOT in the fingerprint — if a beginner and an expert both trip on the same
  # broken nav, that is ONE bug, not two. (Persona-mismatch bakes the target
  # persona into the signal instead, so those stay distinct by design.)
  def fingerprint(obs)
    page = path_key(obs['url'])
    rule = "#{obs['kind']}:#{signal_token(obs['signal'])}"
    Digest::SHA1.hexdigest("explorer|#{page}|#{rule}")[0, 12]
  end

  # Validate + canonicalize one raw observation from the run. Returns a finding
  # hash or nil (dropped). Defends against a model that invented a kind or left
  # the signal empty — garbage in must not become a noisy issue.
  def normalize(obs)
    return nil unless obs.is_a?(Hash)
    kind = obs['kind'].to_s
    return nil unless KINDS.key?(kind)
    sig = obs['signal'].to_s.strip
    return nil if sig.length < 4            # too vague to dedup or act on
    persona = PERSONAS.include?(obs['persona'].to_s) ? obs['persona'] : 'beginner'
    tlabel, area, dsev, route = KINDS[kind]
    # The agent may raise severity for a clear blocker, but never below the floor.
    sev = %w[sev1 sev2 sev3 sev4].include?(obs['severity'].to_s) ? obs['severity'] : dsev
    f = {
      'check_id'   => 'explorer',
      'kind'       => kind,
      'persona'    => persona,
      'url'        => obs['url'].to_s,
      'url_path'   => path_key(obs['url']),
      'signal'     => sig,
      'evidence'   => obs['evidence'].to_s[0, 500],
      'suggestion' => obs['suggestion'].to_s[0, 300],
      'type'       => tlabel,
      'area'       => area,
      'severity'   => sev,
      'route'      => route.to_s,         # "issue" | "backlog"
      'repo'       => THIS_REPO
    }
    f['fingerprint'] = fingerprint(f)
    f['rule']        = "#{kind}:#{signal_token(sig)}"
    f
  end

  # Deduplicate a batch IN-MEMORY (one run can hit the same nav on five pages).
  # Keep the highest-severity representative per fingerprint, count occurrences,
  # and record which personas flagged it (a problem all three personas hit is a
  # stronger signal than one persona's nit — surfaced in the body, not the fp).
  def dedup(findings)
    by_fp = Hash.new { |h, k| h[k] = [] }
    findings.compact.each { |f| by_fp[f['fingerprint']] << f }
    by_fp.map do |fp, fs|
      rep = fs.min_by { |f| %w[sev1 sev2 sev3 sev4].index(f['severity']) || 9 }
      rep.merge(
        'occurrences' => fs.size,
        'personas'    => fs.map { |f| f['persona'] }.uniq.sort,
        'pages'       => fs.map { |f| f['url_path'] }.uniq.sort.first(8)
      )
    end.sort_by { |f| [%w[sev1 sev2 sev3 sev4].index(f['severity']) || 9, f['url_path']] }
  end

  # --- routing: issue now vs backlog idea later --------------------------------
  # A broken/confusing/mismatched thing is a BUG -> a deduped GitHub issue that
  # feeds the triage queue (same fp namespace, same labels). A MISSING thing
  # (content-gap / idea) is not a bug — it is a proposal, and proposals belong in
  # _data/backlog.yml where grow-lifehacker will pick them up. We never file an
  # issue for "you should write about X"; that would drown the triage queue in
  # wishlist noise. The split is purely the `route` field set above.
  def issues(findings)
    findings.select { |f| f['route'] == 'issue' }
  end

  def backlog_ideas(findings)
    findings.select { |f| f['route'] == 'backlog' }
  end

  # A backlog candidate, shaped like an entry in _data/backlog.yml so a human (or
  # the content-factory reviewer) can paste/merge it. We map a gap to a kind by
  # the page it was found on; the explorer never invents an id (build_backlog.rb
  # assigns the next free EXP-### so ids stay collision-free and auditable).
  def backlog_entry(f)
    {
      'kind'        => kind_for_path(f['url_path']),
      'title'       => f['signal'],
      'brief'       => f['evidence'].empty? ? f['suggestion'] : f['evidence'],
      'voice'       => 'how-to-practical',
      'priority'    => 'P3',
      'status'      => 'todo',
      'source'      => 'site-explorer',
      'fingerprint' => f['fingerprint'],
      'seen_on'     => f['url_path'],
      'personas'    => (f['personas'] || [f['persona']])
    }
  end

  def kind_for_path(path)
    case path
    when %r{\A/news/hacks/}, %r{\A/hacks/} then 'hack'
    when %r{\A/news/tools/}, %r{\A/tools/} then 'tool'
    when %r{\A/news/field-notes/}, %r{\A/posts/} then 'post'
    when %r{\A/docs/}  then 'doc'
    else 'hack'
    end
  end

  # --- the dedup marker + issue body (mirrors Triage.issue_body) ---------------
  # SAME marker convention as the triage bot (`triage-fp: <fp>`) so a single
  # `gh issue list --search "triage-fp: <fp>"` finds an issue no matter which bot
  # filed it. Two bots, one dedup key, zero duplicate issues for one problem.
  def issue_title(f)
    "[#{f['severity']}] #{f['type'].split('/').last}: #{f['signal']} (#{f['url_path']})"
  end

  def issue_body(f)
    personas = (f['personas'] || [f['persona']]).join(', ')
    pages    = (f['pages'] || [f['url_path']]).join('`, `')
    <<~BODY
      <!-- triage-fp: #{f['fingerprint']} -->
      <!-- explorer-finding -->
      Filed by the lifehacker.dev **site-explorer** from a live browse of #{SITE}. A human triages and closes.

      | field | value |
      |---|---|
      | kind | `#{f['kind']}` |
      | flagged by | #{personas} |
      | where | `#{pages}` |
      | severity | #{f['severity']} |
      | occurrences this run | #{f['occurrences'] || 1} |

      **What the persona hit**

      > #{f['evidence']}

      **Suggested direction** (not a mandate)

      > #{f['suggestion'].empty? ? '_none offered_' : f['suggestion']}

      ---
      _This is a live-site UX/content observation, not a build-time check. Fingerprint
      `#{f['fingerprint']}` shares the triage dedup namespace — re-running the explorer
      updates this issue instead of filing a duplicate, and the triage queue can pick
      it up like any other finding._
    BODY
  end
end
