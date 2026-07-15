#!/usr/bin/env ruby
# =============================================================================
# usage_ledger.rb — fold per-run AI usage artifacts into the committed ledger
# -----------------------------------------------------------------------------
# The durable half of AI metering. Each AI job uploads an `ai-usage-*` artifact
# (one JSONL record per model call, written by usage.rb / usage_report.rb);
# artifacts expire, so the ai-usage workflow sweeps them daily through this
# script into files that don't:
#
#   ingest <dir>   merge every *.jsonl under <dir> into _data/ai_usage/ledger.jsonl
#                  — dedup by record id (safe to re-ingest the same artifact
#                  forever), sorted by timestamp. Prints how many were new.
#   summarize      recompute _data/ai_usage/summary.yml (the Liquid dashboard's
#                  data source: totals, 7d/30d windows, by workflow/role/model/
#                  month/auth, top PRs split creation-vs-downstream) and the
#                  committed AI_USAGE.md snapshot (SITE_HEALTH.md's sibling).
#
# Every dollar is API-equivalent (list prices); by_auth shows how much ran on
# subscription OAuth ($0 marginal) vs a metered key (real dollars). Stdlib only.
#   ruby scripts/ai/usage_ledger.rb ingest /tmp/artifacts
#   ruby scripts/ai/usage_ledger.rb summarize
# =============================================================================
require_relative '../ci/_lib'
require 'json'
require 'time'
require 'date'
require 'set'
require 'fileutils'

module AIUsageLedger
  SUMMARY_HEADER = <<~HDR
    # =============================================================================
    # summary.yml — generated AI-usage rollup (scripts/ai/usage_ledger.rb)
    # -----------------------------------------------------------------------------
    # Recomputed by the ai-usage workflow from _data/ai_usage/ledger.jsonl; the
    # /docs/ai-usage/ page renders it via Liquid. All dollars are API-equivalent
    # (what the tokens would bill at list prices — subscription OAuth runs have
    # zero marginal cost). Do not edit by hand.
    # =============================================================================
  HDR

  module_function

  # LH_AI_LEDGER_DIR overrides the target (the E2E simulation points it at a
  # temp dir so it can drive the real code without touching the committed data).
  def dir
    ENV['LH_AI_LEDGER_DIR'].to_s.empty? ? File.join(LH::ROOT, '_data', 'ai_usage') : ENV['LH_AI_LEDGER_DIR']
  end

  def ledger_path
    File.join(dir, 'ledger.jsonl')
  end

  def dashboard_path
    ENV['LH_AI_LEDGER_DIR'].to_s.empty? ? File.join(LH::ROOT, 'AI_USAGE.md') : File.join(dir, 'AI_USAGE.md')
  end

  def load_ledger
    return [] unless File.exist?(ledger_path)
    LH.read(ledger_path).split("\n").map { |l| JSON.parse(l) rescue nil }.compact
  end

  def ingest(src_dir)
    existing = load_ledger
    seen = existing.map { |r| r['id'] }.to_set
    added = 0
    Dir[File.join(src_dir, '**', '*.jsonl')].sort.each do |f|
      LH.read(f).split("\n").each do |line|
        rec = JSON.parse(line) rescue nil
        next unless rec.is_a?(Hash) && rec['id']
        next if seen.include?(rec['id'])
        seen << rec['id']
        existing << rec
        added += 1
      end
    end
    existing.sort_by! { |r| r['ts'].to_s }
    FileUtils.mkdir_p(dir)
    File.open(ledger_path, 'w') { |io| existing.each { |r| io.puts(JSON.generate(r)) } }
    puts "[usage_ledger] ingest: #{added} new record(s), #{existing.size} total."
    added
  end

  def bucket(records)
    {
      'calls'          => records.size,
      'cost_usd'       => records.sum { |r| r['cost_usd'].to_f }.round(4),
      'input_tokens'   => records.sum { |r| r.dig('tokens', 'input').to_i },
      'output_tokens'  => records.sum { |r| r.dig('tokens', 'output').to_i },
      'cache_read'     => records.sum { |r| r.dig('tokens', 'cache_read').to_i },
      'cache_creation' => records.sum { |r| r.dig('tokens', 'cache_creation').to_i }
    }
  end

  def group_rows(records, key_name)
    records.group_by { |r| yield(r) }
           .map { |k, rs| { key_name => k.to_s.empty? ? '(none)' : k.to_s }.merge(bucket(rs)) }
           .sort_by { |row| -row['cost_usd'] }
  end

  def summarize(now: Time.now.utc)
    records = load_ledger
    d7  = records.select { |r| (t = Time.parse(r['ts']) rescue nil) && t >= now - 7 * 86_400 }
    d30 = records.select { |r| (t = Time.parse(r['ts']) rescue nil) && t >= now - 30 * 86_400 }

    prs = records.select { |r| r['pr'] }.group_by { |r| r['pr'].to_i }.map do |pr, rs|
      creation = rs.select { |r| r['pr_source'] == 'created' }.sum { |r| r['cost_usd'].to_f }
      total    = rs.sum { |r| r['cost_usd'].to_f }
      { 'pr' => pr, 'calls' => rs.size, 'cost_usd' => total.round(4),
        'creation_usd' => creation.round(4), 'downstream_usd' => (total - creation).round(4) }
    end.sort_by { |row| -row['cost_usd'] }

    total_cost = records.sum { |r| r['cost_usd'].to_f }
    summary = {
      'generated_at'    => now.iso8601,
      'records'         => records.size,
      'all_time'        => bucket(records),
      'last_30d'        => bucket(d30),
      'last_7d'         => bucket(d7),
      'by_workflow'     => group_rows(d30, 'workflow') { |r| r['workflow'] },
      'by_role'         => group_rows(d30, 'role') { |r| r['agent'] },
      'by_model'        => group_rows(d30, 'model') { |r| r['model'] },
      'by_month'        => records.group_by { |r| r['ts'].to_s[0, 7] }
                                  .map { |m, rs| { 'month' => m }.merge(bucket(rs)) }
                                  .sort_by { |row| row['month'] },
      'by_auth'         => records.group_by { |r| r['auth'].to_s }
                                  .map { |a, rs| [a.empty? ? 'none' : a, bucket(rs)] }.to_h,
      'top_prs'         => prs.first(15),
      'estimated_share' => total_cost.zero? ? 0.0 : (records.select { |r| r['cost_source'] == 'estimated' }.sum { |r| r['cost_usd'].to_f } / total_cost).round(4),
      'error_calls'     => records.count { |r| r['status'] == 'error' }
    }
    FileUtils.mkdir_p(dir)
    LH.ywrite(File.join(dir, 'summary.yml'), summary, fallback_header: SUMMARY_HEADER)
    write_dashboard(summary)
    puts "[usage_ledger] summarize: #{records.size} record(s), all-time $#{format('%.2f', summary['all_time']['cost_usd'])} API-equivalent."
    summary
  end

  def write_dashboard(s)
    usd = ->(v) { format('$%.2f', v.to_f) }
    out = +"<!-- generated by scripts/ai/usage_ledger.rb — do not edit by hand -->\n"
    out << "# AI Usage & Cost\n\n"
    out << "_Last rollup: #{s['generated_at']}_ · **#{s['records']}** AI call(s) on record.\n\n"
    out << "Every number is **API-equivalent** — what the tokens would bill at list prices. "
    out << "Runs on Claude Code subscription auth (OAuth) cost $0 marginal; the metered-key share is real spend.\n\n"
    out << "| window | calls | output tokens | cost (API-equiv) |\n|---|---|---|---|\n"
    [['all time', 'all_time'], ['last 30d', 'last_30d'], ['last 7d', 'last_7d']].each do |label, key|
      b = s[key]
      out << "| #{label} | #{b['calls']} | #{b['output_tokens']} | #{usd.call(b['cost_usd'])} |\n"
    end
    out << "\n## By workflow (last 30d)\n\n"
    if (s['by_workflow'] || []).empty?
      out << "_No AI calls in the window._\n"
    else
      out << "| workflow | calls | output tokens | cost |\n|---|---|---|---|\n"
      s['by_workflow'].each { |r| out << "| #{r['workflow']} | #{r['calls']} | #{r['output_tokens']} | #{usd.call(r['cost_usd'])} |\n" }
    end
    out << "\n## Most expensive PRs (all time)\n\n"
    if (s['top_prs'] || []).empty?
      out << "_No PR-attributed calls yet._\n"
    else
      out << "| PR | calls | creation | reviews/fixes | total |\n|---|---|---|---|---|\n"
      s['top_prs'].first(10).each do |r|
        out << "| ##{r['pr']} | #{r['calls']} | #{usd.call(r['creation_usd'])} | #{usd.call(r['downstream_usd'])} | #{usd.call(r['cost_usd'])} |\n"
      end
    end
    out << "\n_Generated from `_data/ai_usage/`. The live version is at_ "
    out << "[/docs/ai-usage/](https://lifehacker.dev/docs/ai-usage/)_. Don't edit this file by hand._\n"
    File.write(dashboard_path, out)
  end
end

if __FILE__ == $PROGRAM_NAME
  case ARGV[0]
  when 'ingest'
    abort 'usage: usage_ledger.rb ingest <dir>' unless ARGV[1] && Dir.exist?(ARGV[1])
    AIUsageLedger.ingest(ARGV[1])
    AIUsageLedger.summarize
  when 'summarize'
    AIUsageLedger.summarize
  else
    abort "usage: usage_ledger.rb ingest <dir> | summarize"
  end
end
