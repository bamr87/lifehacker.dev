#!/usr/bin/env ruby
# =============================================================================
# scripts/devops/loop_metrics.rb — measure how the autonomous loop is actually doing
# -----------------------------------------------------------------------------
# The devops audit (audit.rb) checks the pipeline's STRUCTURE statically. This
# script measures its OBSERVED BEHAVIOUR: it mines recent GitHub Actions runs,
# `auto:content` PRs, and their bot comments, then reports content-AGNOSTIC
# aggregates — how long runs take, how often they fail, how long a content PR
# takes to merge, how many auto-fix attempts it burns, how often it gets
# escalated to a human, and which lint rules recur across PRs.
#
# It is the evidence layer the `loop-tuner` agent reasons over: every number
# here is a lever for "make the loop faster and more accurate" WITHOUT ever
# looking at what any individual PR is about. It reads only metadata (timings,
# counts, labels, rule names) — never the substance of a post or a hack.
#
#   ruby scripts/devops/loop_metrics.rb                  # human report (markdown)
#   ruby scripts/devops/loop_metrics.rb --json           # machine report
#   ruby scripts/devops/loop_metrics.rb --out test-results/loop-metrics.json
#   ruby scripts/devops/loop_metrics.rb --pr-limit 60 --run-limit 150
#   ruby scripts/devops/loop_metrics.rb --self-test      # no gh; verify the math
#
# THE LOOP'S MEMORY (what makes runs compound instead of repeat):
#   --history PATH        # compare against the last committed snapshot in the
#                         # JSONL history (default _data/metrics/history.jsonl
#                         # when present) and emit trend signals — "this metric
#                         # regressed / improved since <ts>" — so a run can see
#                         # whether the previous run's change actually worked.
#   --append-history      # append this run's compact snapshot to the history
#                         # file (the loop-tuner commits it in its PR — history
#                         # reaches main through the same human gate as code).
#   --backlog PATH        # measure backlog health (growable `todo` items per
#                         # kind; default _data/backlog.yml) so starvation shows
#                         # up as a signal BEFORE the content factory improvises.
#
# Read-only against GitHub: it shells out to `gh` and prints. It files nothing
# and merges nothing (--append-history writes only the local history file).
# Stdlib only, so it runs on a bare runner before `bundle install`.
# =============================================================================
require 'json'
require 'time'
require 'yaml'

module LoopMetrics
  module_function

  # --- pure analysis (no I/O) ------------------------------------------------
  # runs: [{ 'wf' => String, 'dur' => Integer(seconds), 'ok' => bool }]
  # prs:  [{ 'number','state','created','merged','closed','labels'=>[],
  #          'attempts'=>Int, 'review_comments'=>Int, 'mergeable'=>String|nil,
  #          'rules'=>[String] }]
  def analyze(runs:, prs:, backlog: nil, prev: nil)
    r = { 'runs' => analyze_runs(runs),
          'content_prs' => analyze_prs(prs),
          'auto_fix' => analyze_auto_fix(prs),
          'recurring_findings' => recurring_findings(prs),
          'conflicts' => conflicts(prs) }
    r['backlog'] = analyze_backlog(backlog) if backlog
    r['trends'] = trends(prev, r) if prev
    r['signals'] = signals(r)
    r
  end

  def pct(part, whole) = whole.zero? ? 0.0 : (100.0 * part / whole).round(1)

  def percentile(sorted, p)
    return nil if sorted.empty?
    idx = ((p / 100.0) * (sorted.size - 1)).round
    sorted[idx]
  end

  def stats(values)
    s = values.compact.sort
    { 'count' => s.size,
      'median' => percentile(s, 50),
      'p90' => percentile(s, 90),
      'max' => s.last }
  end

  def analyze_runs(runs)
    by_wf = runs.group_by { |r| r['wf'] }
    workflows = by_wf.map do |wf, rs|
      durs = rs.map { |r| r['dur'] }.compact
      fails = rs.count { |r| !r['ok'] }
      st = stats(durs)
      [wf, { 'runs' => rs.size, 'failures' => fails, 'fail_rate' => pct(fails, rs.size),
             'median_sec' => st['median'], 'p90_sec' => st['p90'], 'max_sec' => st['max'] }]
    end.to_h
    # The bottleneck is the slowest workflow by median wall-clock.
    slowest = workflows.reject { |_, v| v['median_sec'].nil? }
                       .max_by { |_, v| v['median_sec'] }
    { 'total' => runs.size,
      'failures' => runs.count { |r| !r['ok'] },
      'fail_rate' => pct(runs.count { |r| !r['ok'] }, runs.size),
      'by_workflow' => workflows,
      'slowest_workflow' => slowest&.first,
      'slowest_median_sec' => slowest&.last&.fetch('median_sec', nil) }
  end

  def hours_between(a, b)
    return nil if a.to_s.empty? || b.to_s.empty?
    ((Time.parse(b) - Time.parse(a)) / 3600.0).round(2)
  rescue ArgumentError
    nil
  end

  def analyze_prs(prs)
    merged = prs.select { |p| p['state'] == 'MERGED' || !p['merged'].to_s.empty? }
    ttm = merged.map { |p| hours_between(p['created'], p['merged']) }.compact
    escalated = prs.count { |p| (p['labels'] || []).include?('needs-human') }
    st = stats(ttm)
    { 'count' => prs.size,
      'merged' => merged.size,
      'escalated_needs_human' => escalated,
      'escalation_rate' => pct(escalated, prs.size),
      'median_hours_to_merge' => st['median'],
      'p90_hours_to_merge' => st['p90'],
      'review_comments_total' => prs.sum { |p| p['review_comments'].to_i } }
  end

  def analyze_auto_fix(prs)
    with = prs.select { |p| p['attempts'].to_i > 0 }
    attempts = prs.map { |p| p['attempts'].to_i }
    dist = Hash.new(0)
    attempts.each { |a| dist[a] += 1 }
    { 'prs_with_attempts' => with.size,
      'prs_with_attempts_rate' => pct(with.size, prs.size),
      'total_attempts' => attempts.sum,
      'max_attempts' => attempts.max || 0,
      'distribution' => dist.sort.to_h }
  end

  def recurring_findings(prs)
    tally = Hash.new(0)
    prs.each { |p| (p['rules'] || []).each { |r| tally[r] += 1 } }
    tally.sort_by { |rule, n| [-n, rule] }.first(15).map { |rule, n| { 'rule' => rule, 'prs' => n } }
  end

  def conflicts(prs)
    open = prs.select { |p| p['state'] == 'OPEN' }
    not_mergeable = open.count { |p| p['mergeable'] && p['mergeable'] != 'MERGEABLE' }
    { 'open_content_prs' => open.size, 'open_not_mergeable' => not_mergeable }
  end

  # --- backlog health (reads a file, not gh) ---------------------------------
  # The content factory draws one item per kind per day; a kind with zero `todo`
  # items forces it to improvise inline, which is unmeasured and duplicate-prone.
  # Starvation is therefore a loop signal, not a content judgment.
  GROW_KINDS = %w[hack tool post doc].freeze

  def analyze_backlog(items)
    grow = items.select { |i| i.is_a?(Hash) && GROW_KINDS.include?(i['kind'].to_s) }
    todo = grow.select { |i| i['status'].to_s == 'todo' }
    by_kind = GROW_KINDS.to_h { |k| [k, todo.count { |i| i['kind'] == k }] }
    { 'growable_todo' => todo.size,
      'todo_by_kind' => by_kind,
      'starved_kinds' => by_kind.select { |_, n| n.zero? }.keys }
  end

  # --- trends (this run vs the last committed snapshot) ----------------------
  # All tracked metrics are lower-is-better, so delta > 0 is a regression. This
  # is how the loop VERIFIES itself: an improvement a past run claimed either
  # shows up here as a falling number, or it didn't happen.
  TREND_METRICS = %w[
    runs.fail_rate runs.slowest_median_sec
    content_prs.escalation_rate content_prs.p90_hours_to_merge
    auto_fix.prs_with_attempts_rate auto_fix.total_attempts
    conflicts.open_not_mergeable
  ].freeze

  def dig_path(h, path)
    path.split('.').reduce(h) { |acc, k| acc.is_a?(Hash) ? acc[k] : nil }
  end

  def trends(prev, r)
    metrics = {}
    TREND_METRICS.each do |m|
      was = dig_path(prev, m)
      now = dig_path(r, m)
      next unless was.is_a?(Numeric) && now.is_a?(Numeric)
      metrics[m] = { 'prev' => was, 'now' => now, 'delta' => (now - was).round(2) }
    end
    { 'since' => prev['ts'], 'metrics' => metrics }
  end

  # A move counts only when it's big enough to act on: at least 10% of the larger
  # magnitude — except a clean zero-to-nonzero, which is always significant.
  def significant?(was, now)
    return false if was == now
    return true if was.zero? || now.zero?
    (now - was).abs >= 0.1 * [was.abs, now.abs].max
  end

  # --- history snapshots (the JSONL the loop-tuner commits in its PR) --------
  def snapshot(r, ts: Time.now.utc.iso8601)
    { 'ts' => ts,
      'runs' => (r['runs'] || {}).slice('total', 'fail_rate', 'slowest_workflow', 'slowest_median_sec'),
      'content_prs' => (r['content_prs'] || {}).slice('count', 'merged', 'escalation_rate',
                                                      'median_hours_to_merge', 'p90_hours_to_merge'),
      'auto_fix' => (r['auto_fix'] || {}).slice('prs_with_attempts_rate', 'total_attempts', 'max_attempts'),
      'conflicts' => r['conflicts'] || {},
      'backlog' => (r['backlog'] || {}).slice('growable_todo', 'starved_kinds'),
      'top_rules' => (r['recurring_findings'] || []).first(3) }
  end

  def load_prev_snapshot(path)
    return nil unless File.exist?(path)
    last = File.readlines(path).map(&:strip).reject(&:empty?).last
    last && (JSON.parse(last) rescue nil)
  end

  # Objective triggers the agent turns into proposals. Each is a fact + a lever.
  def signals(r)
    out = []
    sw = r.dig('runs', 'slowest_workflow')
    sm = r.dig('runs', 'slowest_median_sec')
    out << "Bottleneck: `#{sw}` has the slowest median wall-clock (#{sm}s). Look at tiering/caching/dedup there." if sw && sm && sm >= 240
    fr = r.dig('runs', 'fail_rate')
    out << "Run failure rate is #{fr}% across recent runs — high churn wastes minutes; find the most-failing workflow and its top cause." if fr && fr >= 25
    af = r['auto_fix'] || {}
    out << "#{af['prs_with_attempts']} content PR(s) needed auto-fix (max #{af['max_attempts']} attempts). Each attempt is a full pipeline re-run; fix the upstream generator so the draft is born green." if af['prs_with_attempts'].to_i > 0
    out << "Auto-fix is hitting the attempt cap — those PRs escalate to a human. Address the recurring cause, not the symptom." if af['max_attempts'].to_i >= 3
    (r['recurring_findings'] || []).select { |f| f['prs'] >= 3 }.each do |f|
      out << "Lint rule `#{f['rule']}` recurs on #{f['prs']} PRs — bake the fix into the content generator/skill so it stops being emitted."
    end
    esc = r.dig('content_prs', 'escalation_rate')
    out << "#{esc}% of content PRs were escalated to `needs-human` — diagnose whether it's conflicts, repeated lint, or build flakiness." if esc && esc >= 20
    cf = r['conflicts'] || {}
    out << "#{cf['open_not_mergeable']} open content PR(s) are currently un-mergeable (conflicts). Confirm auto-update is enabled and resolving them." if cf['open_not_mergeable'].to_i > 0
    ttm = r.dig('content_prs', 'p90_hours_to_merge')
    out << "p90 time-to-merge is #{ttm}h — long-lived PRs collide more; shorten the review/merge path." if ttm && ttm >= 48
    bl = r['backlog']
    if bl && !bl['starved_kinds'].empty?
      out << "Backlog starvation: kind(s) #{bl['starved_kinds'].join(', ')} have 0 `todo` items (#{bl['growable_todo']} growable total) — the content factory will improvise unmeasured ideas. Harvest `## Backlog ideas` from merged PRs (scripts/triage/harvest_ideas.rb) and promote the good ones."
    end
    tr = r['trends']
    (tr ? tr['metrics'] : {}).each do |m, v|
      next unless significant?(v['prev'], v['now'])
      if v['delta'] > 0
        out << "Trend regression: `#{m}` worsened #{v['prev']} -> #{v['now']} since #{tr['since']} — find what changed in the loop (check _data/fleet/improvements.yml for a recent entry to mark `regressed`) and fix or revert it."
      else
        out << "Trend improvement: `#{m}` improved #{v['prev']} -> #{v['now']} since #{tr['since']} — if an improvements-ledger entry predicted this, mark it `verified`."
      end
    end
    out << 'No strong signals in this window — the loop looks healthy. Open NO PR unless you find a real, evidenced improvement.' if out.empty?
    out
  end

  # --- gather (shells to gh; each call degrades to empty on failure) ---------
  def sh_json(cmd, default)
    raw = `#{cmd} 2>/dev/null`
    raw.strip.empty? ? default : (JSON.parse(raw) rescue default)
  end

  def gather_runs(limit)
    rows = sh_json("gh run list --limit #{limit.to_i} --json workflowName,conclusion,status,createdAt,updatedAt", [])
    rows.select { |r| r['status'] == 'completed' && !r['conclusion'].to_s.empty? }.map do |r|
      { 'wf' => r['workflowName'],
        'dur' => duration_sec(r['createdAt'], r['updatedAt']),
        'ok' => %w[success skipped neutral].include?(r['conclusion']) }
    end
  end

  def duration_sec(a, b)
    return nil if a.to_s.empty? || b.to_s.empty?
    (Time.parse(b) - Time.parse(a)).round
  rescue ArgumentError
    nil
  end

  AUTOFIX_MARKER = '<!-- auto-fix-attempt -->'
  REPORT_MARKER  = '<!-- lh-test-report -->'

  def gather_prs(pr_limit, comment_cap)
    rows = sh_json("gh pr list --state all --label auto:content --limit #{pr_limit.to_i} " \
                   '--json number,state,createdAt,mergedAt,closedAt,labels,mergeable', [])
    rows.first(comment_cap.to_i).map do |p|
      comments = sh_json("gh pr view #{p['number']} --json comments --jq .comments", [])
      bodies = comments.map { |c| c['body'].to_s }
      { 'number' => p['number'],
        'state' => p['state'],
        'created' => p['createdAt'],
        'merged' => p['mergedAt'],
        'closed' => p['closedAt'],
        'labels' => (p['labels'] || []).map { |l| l['name'] },
        'mergeable' => p['mergeable'],
        'attempts' => bodies.count { |b| b.include?(AUTOFIX_MARKER) },
        'review_comments' => comments.size,
        'rules' => report_rules(bodies) }
    end
  end

  # Pull the `rule` column out of the most recent lh-test-report comment table.
  # Each row looks like: | warning | brand | `file:line` | rule-name | evidence |
  def report_rules(bodies)
    report = bodies.reverse.find { |b| b.include?(REPORT_MARKER) }
    return [] unless report
    report.each_line.filter_map do |line|
      cells = line.split('|').map(&:strip)
      next unless cells.size >= 6           # leading + 5 columns + trailing
      rule = cells[4]
      next if rule.nil? || rule.empty? || rule == 'rule'   # skip header
      next unless rule =~ /\A[a-z0-9]/i      # skip separators like ---
      rule
    end.uniq                                 # one PR counts a rule once
  end

  def gather(pr_limit:, run_limit:, comment_cap:, backlog: nil, prev: nil)
    analyze(runs: gather_runs(run_limit), prs: gather_prs(pr_limit, comment_cap),
            backlog: backlog, prev: prev)
  end

  def gather_backlog(path)
    return nil unless path && File.exist?(path)
    doc = YAML.safe_load(File.read(path))
    items = doc.is_a?(Hash) ? doc['backlog'] : nil
    items.is_a?(Array) ? items : nil   # malformed file -> no backlog section, not a crash
  rescue Psych::Exception
    nil
  end

  # --- rendering -------------------------------------------------------------
  def render_markdown(r)
    o = +"## Autonomous-loop metrics\n\n"
    runs = r['runs']
    o << "**Runs (recent):** #{runs['total']} runs · #{runs['fail_rate']}% failed · " \
         "slowest median: `#{runs['slowest_workflow']}` at #{runs['slowest_median_sec']}s\n\n"
    unless runs['by_workflow'].empty?
      o << "| workflow | runs | fail% | median s | p90 s |\n|---|---|---|---|---|\n"
      runs['by_workflow'].sort_by { |_, v| -(v['median_sec'] || 0) }.each do |wf, v|
        o << "| #{wf} | #{v['runs']} | #{v['fail_rate']} | #{v['median_sec']} | #{v['p90_sec']} |\n"
      end
      o << "\n"
    end
    cp = r['content_prs']; af = r['auto_fix']; cf = r['conflicts']
    o << "**Content PRs:** #{cp['count']} (#{cp['merged']} merged) · " \
         "#{cp['escalation_rate']}% escalated · median TTM #{cp['median_hours_to_merge']}h · p90 #{cp['p90_hours_to_merge']}h\n"
    o << "**Auto-fix:** #{af['prs_with_attempts']} PR(s) needed it (#{af['prs_with_attempts_rate']}%), " \
         "#{af['total_attempts']} attempts total, max #{af['max_attempts']}\n"
    o << "**Conflicts:** #{cf['open_not_mergeable']}/#{cf['open_content_prs']} open content PRs un-mergeable\n"
    if (bl = r['backlog'])
      starved = bl['starved_kinds'].empty? ? 'none starved' : "STARVED: #{bl['starved_kinds'].join(', ')}"
      o << "**Backlog:** #{bl['growable_todo']} growable `todo` item(s) (#{starved})\n"
    end
    o << "\n"
    if (tr = r['trends']) && !tr['metrics'].empty?
      o << "**Trends since #{tr['since']}:**\n"
      tr['metrics'].each do |m, v|
        mark = v['delta'].positive? ? '▲' : (v['delta'].negative? ? '▼' : '·')
        o << "- #{mark} `#{m}`: #{v['prev']} -> #{v['now']}\n"
      end
      o << "\n"
    end
    unless r['recurring_findings'].empty?
      o << "**Recurring lint rules:**\n"
      r['recurring_findings'].each { |f| o << "- `#{f['rule']}` — #{f['prs']} PR(s)\n" }
      o << "\n"
    end
    o << "**Signals (levers for the loop-tuner):**\n"
    r['signals'].each { |s| o << "- #{s}\n" }
    o
  end

  # --- self-test (no gh; proves the aggregation math) ------------------------
  def self_test
    runs = [
      { 'wf' => 'pipeline', 'dur' => 100, 'ok' => true },
      { 'wf' => 'pipeline', 'dur' => 300, 'ok' => false },
      { 'wf' => 'pipeline', 'dur' => 500, 'ok' => true },
      { 'wf' => 'fast', 'dur' => 20, 'ok' => true }
    ]
    prs = [
      { 'number' => 1, 'state' => 'MERGED', 'created' => '2026-06-01T00:00:00Z',
        'merged' => '2026-06-01T10:00:00Z', 'labels' => [], 'attempts' => 0,
        'review_comments' => 2, 'mergeable' => 'MERGEABLE', 'rules' => ['description-too-long'] },
      { 'number' => 2, 'state' => 'MERGED', 'created' => '2026-06-02T00:00:00Z',
        'merged' => '2026-06-02T02:00:00Z', 'labels' => ['needs-human'], 'attempts' => 3,
        'review_comments' => 5, 'mergeable' => 'MERGEABLE', 'rules' => %w[description-too-long banned-when-sincere:just] },
      { 'number' => 3, 'state' => 'OPEN', 'created' => '2026-06-03T00:00:00Z', 'merged' => '',
        'labels' => [], 'attempts' => 1, 'review_comments' => 0, 'mergeable' => 'CONFLICTING',
        'rules' => ['description-too-long'] }
    ]
    backlog = [
      { 'id' => 'HACK-1', 'kind' => 'hack', 'status' => 'todo' },
      { 'id' => 'HACK-2', 'kind' => 'hack', 'status' => 'done' },
      { 'id' => 'TOOL-1', 'kind' => 'tool', 'status' => 'todo' },
      { 'id' => 'POST-1', 'kind' => 'post', 'status' => 'done' },
      { 'id' => 'OPS-1',  'kind' => 'ops',  'status' => 'todo' },  # ops never growable
      'junk-non-map-entry', 42                                      # malformed items must be ignored
    ]
    prev = {
      'ts' => '2026-06-01T00:00:00Z',
      'runs' => { 'fail_rate' => 10.0, 'slowest_median_sec' => 400 },
      'content_prs' => { 'escalation_rate' => 33.3 },
      'conflicts' => { 'open_not_mergeable' => 0 }
    }
    r = analyze(runs: runs, prs: prs, backlog: backlog, prev: prev)
    trend = r['trends']['metrics']
    checks = {
      'backlog.growable_todo' => [r['backlog']['growable_todo'], 2],
      'backlog.starved' => [r['backlog']['starved_kinds'], %w[post doc]],
      'trend fail_rate delta' => [trend['runs.fail_rate']['delta'], 15.0],
      'trend regression significant' => [significant?(10.0, 25.0), true],
      'trend improvement delta' => [trend['runs.slowest_median_sec']['delta'], -100],
      'trend unchanged insignificant' => [significant?(33.3, 33.3), false],
      'trend small move insignificant' => [significant?(100, 105), false],
      'trend zero-to-nonzero significant' => [significant?(0, 1), true],
      'trends carry since' => [r['trends']['since'], '2026-06-01T00:00:00Z'],
      'signal starvation' => [r['signals'].any? { |s| s.include?('Backlog starvation') && s.include?('post, doc') }, true],
      'signal regression' => [r['signals'].any? { |s| s.include?('Trend regression: `runs.fail_rate`') }, true],
      'signal improvement' => [r['signals'].any? { |s| s.include?('Trend improvement: `runs.slowest_median_sec`') }, true],
      'snapshot keeps ts' => [snapshot(r, ts: '2026-06-02T00:00:00Z')['ts'], '2026-06-02T00:00:00Z'],
      'snapshot backlog' => [snapshot(r, ts: 'x')['backlog']['growable_todo'], 2],
      'snapshot top rule' => [snapshot(r, ts: 'x')['top_rules'].first['rule'], 'description-too-long'],
      'runs.total' => [r['runs']['total'], 4],
      'runs.fail_rate' => [r['runs']['fail_rate'], 25.0],
      'runs.slowest' => [r['runs']['slowest_workflow'], 'pipeline'],
      'pipeline median' => [r['runs']['by_workflow']['pipeline']['median_sec'], 300],
      'prs.merged' => [r['content_prs']['merged'], 2],
      'prs.escalation_rate' => [r['content_prs']['escalation_rate'], 33.3],
      'prs.median_ttm' => [r['content_prs']['median_hours_to_merge'], 10.0],  # nearest-rank of [2.0, 10.0]
      'autofix.prs_with' => [r['auto_fix']['prs_with_attempts'], 2],
      'autofix.max' => [r['auto_fix']['max_attempts'], 3],
      'recurring top rule' => [r['recurring_findings'].first['rule'], 'description-too-long'],
      'recurring top count' => [r['recurring_findings'].first['prs'], 3],
      'conflicts.open_not_mergeable' => [r['conflicts']['open_not_mergeable'], 1]
    }
    failed = checks.reject { |_, (got, want)| got == want }
    if failed.empty?
      puts "loop_metrics self-test: #{checks.size}/#{checks.size} PASS"
      true
    else
      failed.each { |name, (got, want)| puts "FAIL #{name}: got #{got.inspect}, want #{want.inspect}" }
      false
    end
  end
end

# --- CLI ---------------------------------------------------------------------
if $PROGRAM_NAME == __FILE__
  opts = { pr_limit: 60, run_limit: 150, comment_cap: 40, fmt: :markdown, out: nil,
           backlog: '_data/backlog.yml', history: '_data/metrics/history.jsonl', append: false }
  i = 0
  while i < ARGV.size
    case ARGV[i]
    when '--self-test' then exit(LoopMetrics.self_test ? 0 : 1)
    when '--json'      then opts[:fmt] = :json
    when '--markdown'  then opts[:fmt] = :markdown
    when '--pr-limit'  then opts[:pr_limit] = ARGV[i += 1].to_i
    when '--run-limit' then opts[:run_limit] = ARGV[i += 1].to_i
    when '--comment-cap' then opts[:comment_cap] = ARGV[i += 1].to_i
    when '--out'       then opts[:out] = ARGV[i += 1]
    when '--backlog'   then opts[:backlog] = ARGV[i += 1]
    when '--history'   then opts[:history] = ARGV[i += 1]
    when '--append-history' then opts[:append] = true
    end
    i += 1
  end

  prev = opts[:history] ? LoopMetrics.load_prev_snapshot(opts[:history]) : nil
  report = LoopMetrics.gather(pr_limit: opts[:pr_limit], run_limit: opts[:run_limit],
                              comment_cap: opts[:comment_cap],
                              backlog: LoopMetrics.gather_backlog(opts[:backlog]), prev: prev)
  if opts[:append] && opts[:history]
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(opts[:history]))
    File.open(opts[:history], 'a') { |f| f.puts(JSON.generate(LoopMetrics.snapshot(report))) }
    warn "loop_metrics: appended snapshot to #{opts[:history]}"
  end
  if opts[:out]
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(opts[:out]))
    File.write(opts[:out], JSON.pretty_generate(report))
    warn "loop_metrics: wrote #{opts[:out]}"
  end
  puts(opts[:fmt] == :json ? JSON.pretty_generate(report) : LoopMetrics.render_markdown(report))
end
