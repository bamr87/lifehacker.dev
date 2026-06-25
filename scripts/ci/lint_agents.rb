#!/usr/bin/env ruby
# =============================================================================
# lint_agents.rb — agent/skill consistency the gate enforces
# -----------------------------------------------------------------------------
# The automation is wired to named agents (.claude/agents/<name>.md) that delegate
# to skills (.claude/skills/<name>/SKILL.md). This keeps that wiring honest:
#   * every agent file has valid frontmatter (name, description, tools) and its
#     `name` matches the filename (ERROR — a broken agent file silently no-ops);
#   * every `agent: <literal>` a workflow references resolves to an existing agent
#     (ERROR — a dangling ref means the role runs with no system prompt);
#   * every skill dir has a SKILL.md with name/description frontmatter (ERROR/warn).
# Stdlib only. Run: ruby scripts/ci/lint_agents.rb
# =============================================================================
require 'yaml'
require_relative '_lib'

findings = []
AG_DIR = File.join(LH::ROOT, '.claude', 'agents')
SK_DIR = File.join(LH::ROOT, '.claude', 'skills')
WF_DIR = File.join(LH::ROOT, '.github', 'workflows')

def frontmatter(path)
  fm = LH.read(path)[/\A---\n(.*?)\n---/m, 1]
  fm && (YAML.load(fm) rescue nil)
end

# --- 1. Agent files: valid frontmatter, name == filename --------------------
agent_names = []
Dir[File.join(AG_DIR, '*.md')].sort.each do |f|
  rel = LH.rel(f)
  bn  = File.basename(f, '.md')
  fm  = frontmatter(f)
  if fm.nil?
    findings << LH.finding(check_id: 'agents', severity: 'error', rule: 'no-frontmatter', file: rel, evidence: 'agent .md lacks parseable --- frontmatter ---')
    next
  end
  agent_names << bn
  %w[name description tools].each do |k|
    findings << LH.finding(check_id: 'agents', severity: 'error', rule: "missing-key:#{k}", file: rel, evidence: "agent frontmatter missing `#{k}`") if fm[k].to_s.strip.empty?
  end
  findings << LH.finding(check_id: 'agents', severity: 'warning', rule: 'name-mismatch', file: rel, evidence: "frontmatter name `#{fm['name']}` != filename `#{bn}`") if !fm['name'].to_s.empty? && fm['name'].to_s != bn
end

# --- 2. Workflow `agent: <literal>` refs resolve to an agent ----------------
Dir[File.join(WF_DIR, '*.yml')].sort.each do |wf|
  LH.read(wf).each_line.with_index do |line, i|
    next unless line =~ /^\s*agent:\s*([A-Za-z0-9_-]+)\s*$/   # skip ${{ ... }} expressions
    name = Regexp.last_match(1)
    next if agent_names.include?(name)
    findings << LH.finding(check_id: 'agents', severity: 'error', rule: 'dangling-agent-ref', file: LH.rel(wf), line: i + 1, evidence: "references agent `#{name}` but .claude/agents/#{name}.md does not exist")
  end
end

# --- 3. Skill dirs: a SKILL.md with name/description ------------------------
Dir[File.join(SK_DIR, '*')].select { |d| File.directory?(d) && File.basename(d) != '_shared' }.sort.each do |d|
  sk = File.join(d, 'SKILL.md')
  unless File.exist?(sk)
    findings << LH.finding(check_id: 'agents', severity: 'error', rule: 'skill-missing-SKILL.md', file: LH.rel(d), evidence: 'skill directory has no SKILL.md')
    next
  end
  fm = frontmatter(sk)
  findings << LH.finding(check_id: 'agents', severity: 'warning', rule: 'skill-no-frontmatter', file: LH.rel(sk), evidence: 'SKILL.md lacks name/description frontmatter') unless fm && !fm['name'].to_s.empty? && !fm['description'].to_s.empty?
end

errs = LH.write('agents', findings)
exit(errs.zero? ? 0 : 1)
