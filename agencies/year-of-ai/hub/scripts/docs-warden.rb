#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# docs-warden.rb — the documentation coverage / drift engine (ADR-0005).
# =============================================================================
# Deterministic tier behind .github/workflows/docs-warden.yml. Two checks:
#
#   --base REF   PR COVERAGE: for the code/config paths changed vs REF, was the
#                doc each obligates (per .github/config/docs_warden.yml rules)
#                changed in the SAME diff? Unmet obligations → findings.
#   --census     DRIFT: every plumbing file (scripts/**, genome/bin/*, workflows)
#                must be NAMED somewhere in the doc corpus, else it has drifted
#                into being undocumented.
#
# Outputs --json / --summary (Markdown); --check exits 1 only when enforcement is
# soft/hard-gate AND a GATE-severity finding exists (rollout default `warn` never
# fails). HUB doc surface only; no overlap with ai-content-review / framework-pr-
# reviewer / genome-sync. Ruby 3.x stdlib only.
# =============================================================================

require 'yaml'
require 'json'
require 'optparse'

ROOT   = File.expand_path('..', __dir__)
CONFIG = File.join(ROOT, '.github', 'config', 'docs_warden.yml')

opts = { mode: nil, base: nil }
OptionParser.new do |o|
  o.on('--base REF') { |v| opts[:mode] = :base; opts[:base] = v }
  o.on('--census')   { opts[:mode] = :census }
  o.on('--json FILE') { |v| opts[:json] = v }
  o.on('--summary FILE') { |v| opts[:summary] = v }
  o.on('--check')    { opts[:check] = true }
end.parse!

cfg = YAML.load_file(CONFIG)
enforcement = cfg['enforcement'] || 'warn'

def gmatch?(path, pat)
  if pat.end_with?('/**')
    path.start_with?(pat[0..-3])
  else
    File.fnmatch?(pat, path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
  end
end

def any?(path, pats)
  pats.any? { |p| gmatch?(path, p) }
end

# A required doc is "satisfied" if the change set touched that exact path or
# anything under it (dir prefix).
def satisfied?(req, changed)
  changed.any? { |c| c == req || c.start_with?("#{req}/") || gmatch?(c, req) }
end

Dir.chdir(ROOT)
findings = []

if opts[:mode] == :base
  changed = `git diff --name-only --diff-filter=ACMR #{opts[:base]}...HEAD 2>/dev/null`.split("\n").reject(&:empty?)
  changed = `git diff --name-only --diff-filter=ACMR HEAD~1 2>/dev/null`.split("\n").reject(&:empty?) if changed.empty?
  exempt = cfg['exempt_paths'] || []
  (cfg['rules'] || []).each do |rule|
    rule['match'].each do |_|
      changed.each do |path|
        next if any?(path, exempt)
        next unless any?(path, rule['match'])

        ok = (rule['requires'] || []).any? { |req| satisfied?(req, changed) }
        next if ok

        findings << {
          'check' => 'coverage', 'path' => path, 'rule' => rule['id'],
          'requires' => rule['requires'], 'severity' => rule['severity'],
          'note' => rule['note']
        }
      end
    end
  end
  findings.uniq! { |f| [f['path'], f['rule']] }
elsif opts[:mode] == :census
  census = cfg['census'] || {}
  corpus = (census['doc_corpus'] || []).flat_map { |g| Dir.glob(g) }
                                       .select { |f| File.file?(f) }
                                       .map { |f| File.read(f, encoding: 'utf-8', invalid: :replace) }
                                       .join("\n")
  (census['code_globs'] || []).flat_map { |g| Dir.glob(g) }.select { |f| File.file?(f) }.uniq.sort.each do |f|
    base = File.basename(f)
    next if corpus.include?(base)

    findings << {
      'check' => 'census', 'path' => f, 'rule' => 'documented',
      'requires' => census['doc_corpus'], 'severity' => 'required',
      'note' => "#{base} is not named in any doc — undocumented/drifted."
    }
  end
else
  abort 'usage: docs-warden.rb (--base REF | --census) [--json F] [--summary F] [--check]'
end

# ---- output -----------------------------------------------------------------
gate = findings.select { |f| f['severity'] == 'gate' }
File.write(opts[:json], JSON.pretty_generate('enforcement' => enforcement, 'findings' => findings)) if opts[:json]

md = +"## 📝 Docs Warden — #{opts[:mode]} (enforcement: `#{enforcement}`)\n\n"
if findings.empty?
  md << "✅ Documentation coverage complete — every changed surface is documented.\n"
else
  by = findings.group_by { |f| f['severity'] }
  md << "Found **#{findings.size}** undocumented change(s): "
  md << %w[gate required advisory].map { |s| "#{(by[s] || []).size} #{s}" }.join(' · ') << "\n\n"
  md << "| Surface | Check | Rule | Needs doc | Severity |\n|---|---|---|---|---|\n"
  findings.first(40).each do |f|
    md << "| `#{f['path']}` | #{f['check']} | #{f['rule']} | #{Array(f['requires']).first(2).join(', ')} | **#{f['severity']}** |\n"
  end
  md << "\n_Add the doc update, or waive a gate finding with a `docs-exempt: <reason>` line in the PR body._\n"
end
File.write(opts[:summary], md) if opts[:summary]
puts md

if opts[:check] && enforcement != 'warn' && !gate.empty?
  warn "docs-warden: #{gate.size} GATE-severity documentation gap(s) under enforcement=#{enforcement}."
  exit 1
end
exit 0
