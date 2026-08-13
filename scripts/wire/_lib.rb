#!/usr/bin/env ruby
# =============================================================================
# scripts/wire/_lib.rb — shared logic for the wire-scout (the model-beat crawl)
# -----------------------------------------------------------------------------
# The wire-scout skill READS the news sources configured in
# _data/wire/sources.yml and writes raw dispatch PROPOSALS as JSONL. This file
# owns the deterministic part: which sources are DUE today (frequency gating,
# a pure function of the UTC date — stateless and replayable), validating a
# free-form proposal, reducing it to a stable fingerprint, and shaping it into
# the _data/backlog.yml entry the content factory already reads (kind: wire,
# author: rhea).
#
# The JUDGEMENT (is this story the model beat? what's the honest satirical
# angle?) is the agent's, made while reading the source. Everything DOWNSTREAM
# of that judgement is mechanical and lives here, testable with NO browser and
# NO network — the same split as scripts/scout/ (the sister-site crawl) and
# scripts/explorer/.
#
# The charter rule this file enforces at the DATA layer: every proposal must
# carry a real http(s) `source_url` — the story it was reported from. The press
# charter (_data/brand/identity.yml `press_charter`) calls it "show the work";
# here it is a filter, not a suggestion.
#
# Stdlib only (Digest/JSON/YAML/Date) — runs on Ruby 2.6 local and 3.3 CI. No
# endless-method defs. Run `ruby scripts/wire/_lib.rb --self-test` to verify.
# =============================================================================
require 'digest'
require 'json'
require 'set'
require 'date'
require_relative '../ci/_lib'

module Wire
  ROOT    = LH::ROOT
  DATA    = File.join(ROOT, '_data', 'wire')
  SOURCES = File.join(DATA, 'sources.yml')   # the human-edited assignment editor
  PLAN    = File.join(DATA, 'plan.json')     # today's due sources (plan_sources.rb)
  IDEAS   = File.join(DATA, 'ideas.jsonl')   # raw proposals from the run
  BACKLOG = File.join(ROOT, '_data', 'backlog.yml')

  KIND   = 'wire'
  VOICE  = 'dateline-deadpan'
  AUTHOR = 'rhea'        # the wire desk's dedicated persona (fleet/authors.rb pins it too)
  SOURCE = 'wire-scout'

  TRUST_TIERS = %w[primary reputable community rumor].freeze
  TYPES       = %w[html rss atom].freeze
  WEEKDAYS    = %w[mon tue wed thu fri sat sun].freeze

  # Same stopword list the scout/explorer use, so the fingerprint families
  # reduce prose the same way.
  STOP = %w[the a an is are of to and or on in for with this that it as be too very
            page site content but so when where why how you your i we our my a2
            your yours guide intro introduction how-to howto tutorial].freeze

  module_function

  # --- the assignment editor (_data/wire/sources.yml) -------------------------

  def config
    LH.yload(LH.read(SOURCES)) || {}
  rescue StandardError
    {}
  end

  def defaults(cfg = config)
    d = cfg['defaults'].is_a?(Hash) ? cfg['defaults'] : {}
    { 'frequency' => d['frequency'] || 'daily',
      'trust'     => TRUST_TIERS.include?(d['trust'].to_s) ? d['trust'] : 'reputable',
      'type'      => TYPES.include?(d['type'].to_s) ? d['type'] : 'html',
      'max_items' => (d['max_items'].to_i.positive? ? d['max_items'].to_i : 2) }
  end

  # A source is DUE when the date's UTC weekday matches its frequency. Stateless
  # on purpose: the answer is a pure function of (frequency, date), so a replayed
  # run plans identically and no last-crawled ledger has to be committed.
  #   daily                 -> every day        weekdays  -> Mon..Fri
  #   weekly (+ `weekday:`) -> that weekday     [mon,thu] -> those weekdays
  # (The field is `weekday`, not `on`: YAML 1.1 parses a bare `on:` key as the
  # boolean true, and lint_wire.rb flags that trap explicitly.)
  def due_today?(source, date = Date.today)
    freq = source['frequency'] || 'daily'
    wday = WEEKDAYS[(date.wday - 1) % 7] # Date#wday: 0=Sun..6=Sat; WEEKDAYS: 0=mon
    case freq
    when 'daily'    then true
    when 'weekdays' then !%w[sat sun].include?(wday)
    when 'weekly'   then wday == (WEEKDAYS.include?(source['weekday'].to_s) ? source['weekday'].to_s : 'mon')
    when Array      then freq.map(&:to_s).include?(wday)
    else false
    end
  end

  # Enabled + due sources for a date, with the defaults folded in. Junk entries
  # (no id, no url) are skipped — lint_wire.rb reports them; the planner just
  # refuses to crawl them.
  def due_sources(date = Date.today, cfg = config)
    d = defaults(cfg)
    list = cfg['sources'].is_a?(Array) ? cfg['sources'] : []
    list.filter_map do |s|
      next unless s.is_a?(Hash)
      next if s['enabled'] == false
      src = {
        'id'        => s['id'].to_s,
        'name'      => s['name'].to_s,
        'url'       => s['url'].to_s,
        'type'      => TYPES.include?(s['type'].to_s) ? s['type'] : d['type'],
        'trust'     => TRUST_TIERS.include?(s['trust'].to_s) ? s['trust'] : d['trust'],
        'frequency' => s['frequency'] || d['frequency'],
        'weekday'   => s['weekday'],
        'topics'    => Array(s['topics']).map(&:to_s),
        'include'   => Array(s['include']).map(&:to_s),
        'exclude'   => Array(s['exclude']).map(&:to_s),
        'max_items' => (s['max_items'].to_i.positive? ? s['max_items'].to_i : d['max_items'])
      }
      next if src['id'].empty? || src['url'].empty?
      due_today?(src, date) ? src.compact : nil
    end
  end

  # --- fingerprints + validation (same recipe family as scout/explorer) -------

  def title_token(title)
    s = title.to_s.downcase
    s = s.gsub(/[^a-z0-9 ]+/, ' ').gsub(/\s+/, ' ').strip
    words = s.split(' ').reject { |w| STOP.include?(w) }
    words.first(6).join('-')
  end

  # SAME shape as scout/explorer/aggregate: SHA1("<check>|<slot>|<rule>")[0,12].
  # The identity is the title token alone (the kind is always `wire`): two
  # sources breaking the same story must become ONE backlog item, not two.
  def fingerprint(title)
    Digest::SHA1.hexdigest("wire|#{KIND}|#{title_token(title)}")[0, 12]
  end

  def valid_source_url?(url)
    u = url.to_s.strip
    !!(u =~ %r{\Ahttps?://[^/\s]+\.[^/\s]+(/.*)?\z}i)
  end

  # Validate + canonicalize one raw proposal from the run. Returns a hash or nil
  # (dropped). Defends against a model that dropped the source, invented a trust
  # tier, or proposed a stub — garbage in must not become a backlog item.
  def normalize(obs)
    return nil unless obs.is_a?(Hash)
    title = obs['title'].to_s.strip
    brief = obs['brief'].to_s.strip
    return nil if title.length < 10          # too thin to be a real headline
    return nil if brief.length < 20          # a brief that briefs nothing

    src = obs['source_url'].to_s.strip
    return nil unless valid_source_url?(src) # NO source -> NOT a dispatch

    trust = obs['trust'].to_s.strip
    trust = 'reputable' unless TRUST_TIERS.include?(trust)

    f = {
      'kind'         => KIND,
      'title'        => title,
      'brief'        => brief,
      'voice'        => VOICE,
      'source_url'   => src,
      'source_title' => obs['source_title'].to_s.strip[0, 200],
      'source_id'    => obs['source_id'].to_s.strip[0, 60],
      'trust'        => trust,
      'rationale'    => obs['rationale'].to_s.strip[0, 300]
    }
    f['fingerprint'] = fingerprint(title)
    f
  end

  # Deduplicate a batch IN-MEMORY (two sources can break the same story in one
  # run). Keep the first representative per fingerprint.
  def dedup(findings)
    seen = {}
    findings.compact.each { |f| seen[f['fingerprint']] ||= f }
    seen.values
  end

  # A backlog candidate shaped like _data/backlog.yml. The wire desk pins its
  # correspondent: every wire item carries `author: rhea` (the persona is
  # rotate:false, so nothing else ever assigns it). Priority follows provenance:
  # primary-source stories P2, everything else P3 — a human's P1 outranks both.
  def backlog_entry(f)
    {
      'kind'         => KIND,
      'title'        => f['title'],
      'brief'        => f['brief'],
      'voice'        => VOICE,
      'author'       => AUTHOR,
      'priority'     => f['trust'] == 'primary' ? 'P2' : 'P3',
      'status'       => 'todo',
      'source'       => SOURCE,
      'source_url'   => f['source_url'],
      'source_title' => f['source_title'].to_s.empty? ? nil : f['source_title'],
      'fingerprint'  => f['fingerprint']
    }.compact
  end

  # Render a new entry as YAML we APPEND (never rewrite the curated block above).
  def render(e)
    lines = []
    lines << "  - id: #{e['id']}"
    lines << "    kind: #{e['kind']}"
    lines << "    title: #{e['title'].inspect}"
    lines << "    brief: #{e['brief'].inspect}"
    lines << "    voice: #{e['voice']}"
    lines << "    author: #{e['author']}"
    lines << "    priority: #{e['priority']}"
    lines << "    status: #{e['status']}"
    lines << "    source: #{e['source']}"
    lines << "    source_url: #{e['source_url']}"
    lines << "    source_title: #{e['source_title'].inspect}" if e['source_title']
    lines << "    fingerprint: #{e['fingerprint']}"
    lines.join("\n")
  end

  # --- dedup nets read from the repo (a story already queued or already run
  #     never gets proposed again) ---------------------------------------------

  def known_fingerprints(items)
    items.map { |i| i['fingerprint'] }.compact.to_set
  end

  def known_title_tokens(items)
    items.map { |i| title_token(i['title']) }.reject(&:empty?).to_set
  end

  # Titles already published on the wire — a story the desk already ran is a
  # follow-up or a correction, not a new dispatch.
  def published_title_tokens
    tokens = Set.new
    Dir.glob(File.join(ROOT, 'pages/_posts/wire/*.md')).each do |path|
      fm, = LH.parse(path)
      next unless fm && fm['title']
      t = title_token(fm['title'])
      tokens << t unless t.empty?
    end
    tokens
  end

  # Next free WIRE-### id given the items already present (+ any staged this
  # run). Its own series — never collides with HACK-/TOOL-/POST-/DOC-/SRC-/EXP-.
  def next_wire_id(items)
    used = items.map { |i| i['id'].to_s }.grep(/\AWIRE-(\d+)\z/) { $1.to_i }
    format('WIRE-%03d', (used.max || 0) + 1)
  end
end

# --- self-test (no network, no browser) --------------------------------------
if $PROGRAM_NAME == __FILE__ && ARGV.include?('--self-test')
  ok = 0
  fail = 0
  t = lambda do |desc, cond|
    if cond
      ok += 1
      puts "  PASS #{desc}"
    else
      fail += 1
      puts "  FAIL #{desc}"
    end
  end

  # frequency gating is a pure function of (frequency, date)
  mon = Date.new(2026, 8, 10)
  thu = Date.new(2026, 8, 13)
  sat = Date.new(2026, 8, 15)
  t.call('daily is due every day', Wire.due_today?({ 'frequency' => 'daily' }, sat))
  t.call('weekdays skips saturday', !Wire.due_today?({ 'frequency' => 'weekdays' }, sat))
  t.call('weekdays is due monday', Wire.due_today?({ 'frequency' => 'weekdays' }, mon))
  t.call('weekly defaults to monday', Wire.due_today?({ 'frequency' => 'weekly' }, mon))
  t.call('weekly honors weekday:', Wire.due_today?({ 'frequency' => 'weekly', 'weekday' => 'thu' }, thu))
  t.call('weekly is off other days', !Wire.due_today?({ 'frequency' => 'weekly', 'weekday' => 'thu' }, mon))
  t.call('weekday list matches', Wire.due_today?({ 'frequency' => %w[mon thu] }, thu))
  t.call('weekday list skips others', !Wire.due_today?({ 'frequency' => %w[mon thu] }, sat))
  t.call('unknown frequency is never due', !Wire.due_today?({ 'frequency' => 'hourly' }, mon))

  # fingerprint stability + variant collapse
  fp1 = Wire.fingerprint('Model X ships with a 9-page safety card')
  fp2 = Wire.fingerprint('model x SHIPS, with a 9 page safety card!')
  t.call('fingerprint is 12 hex chars', fp1 =~ /\A[0-9a-f]{12}\z/)
  t.call('fingerprint collapses title variants', fp1 == fp2)

  # proposals
  good = { 'title' => 'Vendor ships smaller model, chart implies otherwise',
           'brief' => 'The launch chart starts its y-axis at 87. The dispatch covers what shipped and the one number the post omitted.',
           'source_url' => 'https://example-lab.com/news/model-mini' }
  n = Wire.normalize(good)
  t.call('valid proposal normalizes', !n.nil?)
  t.call('kind is wire', n && n['kind'] == 'wire')
  t.call('voice is dateline-deadpan', n && n['voice'] == 'dateline-deadpan')
  t.call('trust defaults to reputable', n && n['trust'] == 'reputable')
  t.call('missing source_url dropped', Wire.normalize(good.reject { |k, _| k == 'source_url' }).nil?)
  t.call('bare-path source dropped', Wire.normalize(good.merge('source_url' => '/news/x')).nil?)
  t.call('stub title dropped', Wire.normalize(good.merge('title' => 'news')).nil?)
  t.call('invented trust tier normalized', Wire.normalize(good.merge('trust' => 'gospel'))&.fetch('trust') == 'reputable')

  # backlog entry pins the desk
  e = Wire.backlog_entry(Wire.normalize(good.merge('trust' => 'primary'))).merge('id' => 'WIRE-042')
  t.call('primary trust -> P2', e['priority'] == 'P2')
  t.call('entry pins author rhea', e['author'] == 'rhea')
  block = "backlog:\n" + Wire.render(e) + "\n"
  parsed = LH.yload(block)['backlog'].first
  t.call('render -> valid YAML', parsed.is_a?(Hash))
  t.call('rendered entry keeps author', parsed && parsed['author'] == 'rhea')
  t.call('rendered entry keeps source_url', parsed && parsed['source_url'] == good['source_url'])

  # dedup collapses the same story from two sources
  a = Wire.normalize(good)
  b = Wire.normalize(good.merge('title' => 'vendor SHIPS smaller model — chart implies otherwise!',
                                'source_url' => 'https://other-outlet.com/story'))
  t.call('dedup collapses same story from two sources', Wire.dedup([a, b]).size == 1)

  # id series
  items = [{ 'id' => 'WIRE-001' }, { 'id' => 'SRC-009' }, { 'id' => 'HACK-004' }]
  t.call('next_wire_id continues its own series', Wire.next_wire_id(items) == 'WIRE-002')
  t.call('next_wire_id starts at 001 when none', Wire.next_wire_id([{ 'id' => 'SRC-001' }]) == 'WIRE-001')

  puts "\n[self-test] #{ok} passed, #{fail} failed"
  exit(fail.zero? ? 0 : 1)
end
