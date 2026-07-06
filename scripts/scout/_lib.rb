#!/usr/bin/env ruby
# =============================================================================
# scripts/scout/_lib.rb — shared logic for the content-scout (sister-site crawl)
# -----------------------------------------------------------------------------
# The content-scout skill BROWSES a configured SOURCE site (it-journey.dev by
# default) and writes raw topic PROPOSALS as JSONL. This file owns the
# deterministic part: validating a free-form proposal, reducing it to a *stable
# fingerprint* (so two runs that land on the same topic dedup), and shaping it
# into a `_data/backlog.yml` entry the content-factory / grow-lifehacker already
# reads.
#
# The JUDGEMENT (does this fit the lifehacker brand? what's the satirical angle?)
# is the agent's, made while reading the source page. Everything DOWNSTREAM of
# that judgement is mechanical and lives here, so it is testable with NO browser
# and NO network. build_backlog.rb does the side-effecting file append; this
# module stays pure.
#
# Reuses scripts/ci/_lib.rb for the repo root, UTF-8 reads, YAML loading, and the
# SAME Digest::SHA1 fingerprint recipe family the harness/explorer use — so a
# scout topic and an explorer gap live in one dedup namespace and never produce a
# duplicate backlog item for the same idea.
#
# The non-negotiable rule this file enforces at the DATA layer: every proposal
# must carry a real http(s) `source_url`. A proposal with no source is dropped —
# "always reference the it-journey.dev page" is not a suggestion, it is a filter.
#
# Stdlib only (Digest/JSON/YAML) — runs on Ruby 2.6 local and 3.3 CI. No
# endless-method defs. Run `ruby scripts/scout/_lib.rb --self-test` to verify.
# =============================================================================
require 'digest'
require 'json'
require 'set'
require_relative '../ci/_lib'

module Scout
  ROOT    = LH::ROOT
  DATA    = File.join(ROOT, '_data', 'scout')
  PLAN    = File.join(DATA, 'plan.json')          # seeded crawl plan (plan_sources.rb)
  IDEAS   = File.join(DATA, 'ideas.jsonl')        # raw proposals from the run
  BACKLOG = File.join(ROOT, '_data', 'backlog.yml')

  # The lifehacker collections a proposal can target. This is the CLOSED set the
  # agent must choose from — an open-ended kind would never map to a pillar or a
  # voice. Mirrors _data/brand/identity.yml pillars (hacks/tools/field-notes/meta).
  COLLECTIONS = %w[hack tool post doc].freeze

  # Default voice per collection, from _data/brand/voice.yml (the same mapping
  # grow-lifehacker uses). The agent may override with an explicit `voice`, but
  # only to another profile that exists.
  VOICE_FOR = {
    'hack' => 'how-to-practical',
    'tool' => 'tool-review-honest',
    'post' => 'meta-confession',
    'doc'  => 'meta-confession'
  }.freeze
  VOICES = (VOICE_FOR.values + %w[satire-deadpan]).uniq.freeze

  # Where each collection's published pages live (for the "already written?" check).
  COLLECTION_GLOB = {
    'hack' => 'pages/_hacks/*.md',
    'tool' => 'pages/_tools/*.md',
    'post' => 'pages/_posts/*.md',
    'doc'  => 'pages/_docs/*.md'
  }.freeze

  SOURCE = 'content-scout'

  # Same stopword list the explorer uses, so the two fingerprint families reduce
  # prose the same way.
  STOP = %w[the a an is are of to and or on in for with this that it as be too very
            page site content but so when where why how you your i we our my a2
            your yours guide intro introduction how-to howto tutorial].freeze

  module_function

  def collections
    COLLECTIONS
  end

  # Collapse a free-text title to a short, stable token so two runs that describe
  # the same topic in different words still fingerprint identically. We DON'T hash
  # the prose (it varies run to run); we hash a normalized token: lowercase, strip
  # punctuation, drop stopwords, keep the first few salient words.
  def title_token(title)
    s = title.to_s.downcase
    s = s.gsub(/[^a-z0-9 ]+/, ' ').gsub(/\s+/, ' ').strip
    words = s.split(' ').reject { |w| STOP.include?(w) }
    words.first(6).join('-')
  end

  # The fingerprint. SAME shape as scripts/ci/aggregate.rb / explorer:
  #   SHA1("<check>|<slot>|<rule>")[0,12]
  # so scout topics share the dedup namespace with harness/explorer findings.
  # Here: check slot is "scout", and the identity is (collection, title token) —
  # NOT the source URL, because two different it-journey pages can inspire the
  # same lifehacker topic, and we want that to be ONE backlog item, not two.
  def fingerprint(collection, title)
    Digest::SHA1.hexdigest("scout|#{collection}|#{title_token(title)}")[0, 12]
  end

  # A source_url is required, and must be a real http(s) URL with a host — not a
  # bare path, not a mailto:, not an empty string. This is the filter that makes
  # "always reference the source page" true by construction.
  def valid_source_url?(url)
    u = url.to_s.strip
    !!(u =~ %r{\Ahttps?://[^/\s]+\.[^/\s]+(/.*)?\z}i)
  end

  # Validate + canonicalize one raw proposal from the run. Returns a finding hash
  # or nil (dropped). Defends against a model that invented a collection, left the
  # source out, or produced a stub — garbage in must not become a backlog item.
  def normalize(obs)
    return nil unless obs.is_a?(Hash)
    collection = obs['collection'].to_s.strip.downcase
    collection = 'post' if collection == 'field-note' || collection == 'fieldnote'
    return nil unless COLLECTIONS.include?(collection)

    title = obs['title'].to_s.strip
    brief = obs['brief'].to_s.strip
    return nil if title.length < 10          # too thin to be a real title
    return nil if brief.length < 20          # a brief that briefs nothing

    src = obs['source_url'].to_s.strip
    return nil unless valid_source_url?(src) # NO source -> NOT a scout item

    voice = obs['voice'].to_s.strip
    voice = VOICE_FOR[collection] unless VOICES.include?(voice)

    f = {
      'kind'         => collection,
      'title'        => title,
      'brief'        => brief,
      'voice'        => voice,
      'source_url'   => src,
      'source_title' => obs['source_title'].to_s.strip[0, 200],
      'rationale'    => obs['rationale'].to_s.strip[0, 300]
    }
    f['fingerprint'] = fingerprint(collection, title)
    f
  end

  # Deduplicate a batch IN-MEMORY (one run can land the same topic from two source
  # pages). Keep the first representative per fingerprint.
  def dedup(findings)
    seen = {}
    findings.compact.each { |f| seen[f['fingerprint']] ||= f }
    seen.values
  end

  # A backlog candidate, shaped like an entry in _data/backlog.yml. We never invent
  # an id here (build_backlog.rb assigns the next free SRC-### so ids stay
  # collision-free and auditable). Scout items default to P3 so a human's curated
  # P1/P2 always outranks scout backfill.
  def backlog_entry(f)
    {
      'kind'         => f['kind'],
      'title'        => f['title'],
      'brief'        => f['brief'],
      'voice'        => f['voice'],
      'priority'     => 'P3',
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
    lines << "    priority: #{e['priority']}"
    lines << "    status: #{e['status']}"
    lines << "    source: #{e['source']}"
    lines << "    source_url: #{e['source_url']}"
    lines << "    source_title: #{e['source_title'].inspect}" if e['source_title']
    lines << "    fingerprint: #{e['fingerprint']}"
    lines.join("\n")
  end

  # --- dedup nets read from the repo (so a topic already queued or already
  #     published never gets proposed again) --------------------------------

  # Every fingerprint already represented in the backlog (scout + explorer entries
  # carry one). Plain-code dedup, not an agent's memory.
  def known_fingerprints(items)
    items.map { |i| i['fingerprint'] }.compact.to_set
  end

  # Title tokens already present in the backlog — catches a near-duplicate title
  # even when it has no fingerprint (a human-written item).
  def known_title_tokens(items)
    items.map { |i| title_token(i['title']) }.reject(&:empty?).to_set
  end

  # Title tokens of already-PUBLISHED pages, from their front-matter titles. A
  # topic the site already covers is not a gap. Network-free; reads pages/ on disk.
  def published_title_tokens
    tokens = Set.new
    COLLECTION_GLOB.each_value do |glob|
      Dir.glob(File.join(ROOT, glob)).each do |path|
        fm, = LH.parse(path)
        next unless fm && fm['title']
        t = title_token(fm['title'])
        tokens << t unless t.empty?
      end
    end
    tokens
  end

  # Next free SRC-### id given the items already present (+ any staged this run).
  # Its own series — never collides with the human HACK-/TOOL-/DOC- or explorer
  # EXP- series.
  def next_src_id(items)
    used = items.map { |i| i['id'].to_s }.grep(/\ASRC-(\d+)\z/) { $1.to_i }
    format('SRC-%03d', (used.max || 0) + 1)
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

  # fingerprint stability + variant collapse
  fp1 = Scout.fingerprint('hack', 'Stop typing the same git commands every day')
  fp2 = Scout.fingerprint('hack', 'stop  typing THE same Git commands, every day!')
  t.call('fingerprint is 12 hex chars', fp1 =~ /\A[0-9a-f]{12}\z/)
  t.call('fingerprint collapses title variants', fp1 == fp2)
  t.call('fingerprint splits on collection', Scout.fingerprint('hack', 'x y z abc') != Scout.fingerprint('tool', 'x y z abc'))

  # source_url is required
  t.call('valid https url accepted', Scout.valid_source_url?('https://it-journey.dev/quests/foo/'))
  t.call('bare path rejected', !Scout.valid_source_url?('/quests/foo/'))
  t.call('empty rejected', !Scout.valid_source_url?(''))

  good = { 'collection' => 'hack', 'title' => 'Stop retyping your kubectl contexts',
           'brief' => 'A named-context alias file and the footgun when two clusters share a name.',
           'source_url' => 'https://it-journey.dev/quests/k8s/' }
  n = Scout.normalize(good)
  t.call('valid proposal normalizes', !n.nil?)
  t.call('voice defaulted from collection', n && n['voice'] == 'how-to-practical')
  t.call('normalized carries source_url', n && n['source_url'] == good['source_url'])

  t.call('missing source_url dropped', Scout.normalize(good.reject { |k, _| k == 'source_url' }).nil?)
  t.call('bad collection dropped', Scout.normalize(good.merge('collection' => 'newsletter')).nil?)
  t.call('stub title dropped', Scout.normalize(good.merge('title' => 'todo')).nil?)
  t.call('field-note aliased to post', Scout.normalize(good.merge('collection' => 'field-note'))&.fetch('kind') == 'post')

  # dedup collapses same fingerprint
  a = Scout.normalize(good)
  b = Scout.normalize(good.merge('title' => 'Stop  RETYPING your kubectl contexts',
                                 'source_url' => 'https://it-journey.dev/other/'))
  t.call('dedup collapses same topic from two sources', Scout.dedup([a, b]).size == 1)

  # id series
  items = [{ 'id' => 'SRC-001' }, { 'id' => 'HACK-009' }, { 'id' => 'EXP-004' }]
  t.call('next_src_id continues its own series', Scout.next_src_id(items) == 'SRC-002')
  t.call('next_src_id starts at 001 when none', Scout.next_src_id([{ 'id' => 'HACK-001' }]) == 'SRC-001')

  # render round-trips through YAML and carries the source
  e = Scout.backlog_entry(a).merge('id' => 'SRC-042')
  block = "backlog:\n" + Scout.render(e) + "\n"
  parsed = LH.yload(block)['backlog'].first
  t.call('render -> valid YAML', parsed.is_a?(Hash))
  t.call('rendered entry keeps source_url', parsed && parsed['source_url'] == good['source_url'])
  t.call('rendered entry is todo/P3', parsed && parsed['status'] == 'todo' && parsed['priority'] == 'P3')

  puts "\n[self-test] #{ok} passed, #{fail} failed"
  exit(fail.zero? ? 0 : 1)
end
