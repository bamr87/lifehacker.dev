# =============================================================================
# scripts/ci/_lib.rb — shared helpers for the lifehacker.dev test harness
# -----------------------------------------------------------------------------
# Every check (lint_frontmatter, check_drift, lint_brand, run_hack_commands)
# requires_relative this file. It owns: front-matter parsing, the canonical
# *finding* shape, YAML loading that works on both Ruby 2.6 (local) and 3.x
# (the CI runner), and the per-check JSON writer that aggregate.rb consumes.
#
# Stdlib only — no gems — so it runs on a bare runner before `bundle install`.
# =============================================================================
require 'yaml'
require 'json'
require 'date'
require 'digest'

module LH
  # scripts/ci/_lib.rb -> repo root is two dirs up from __dir__ (scripts/ci).
  ROOT    = File.expand_path('../..', __dir__)
  RESULTS = File.join(ROOT, 'test-results')

  module_function

  # YAML.unsafe_load exists on Psych 4 (Ruby 3.1+); on 2.6 plain load is unsafe
  # already. Front matter / _data are our own trusted files, so unsafe is fine
  # and (unlike safe_load) it parses Date values without extra config.
  def yload(str)
    YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(str) : YAML.load(str)
  end

  # Write a data structure back to a YAML file WITHOUT clobbering its comment
  # header. `to_yaml` serializes only the data, so a naive File.write(path,
  # data.to_yaml) silently drops the file's leading comment block (our committed
  # _data/*.yml files document themselves in that header). This preserves whatever
  # comment header the file already has, falling back to fallback_header when it has
  # none (e.g. a first write, or a file a previous bug already stripped).
  def ywrite(path, data, fallback_header: nil)
    header = ''
    if File.exist?(path)
      lead = read(path)[/\A(?:[ \t]*#[^\n]*\n|[ \t]*\n)*/].to_s   # leading comment/blank run
      header = lead unless lead.strip.empty?
    end
    header = fallback_header.to_s if header.empty? && fallback_header
    File.write(path, header + data.to_yaml.sub(/\A---\n/, ''))
  end

  # Absolute path -> repo-relative (stable identity across machines/CI).
  def rel(path)
    path.sub(/\A#{Regexp.escape(ROOT)}\/?/, '')
  end

  # Read a file as UTF-8 (content has em-dashes, ™, etc.; Ruby 2.6 defaults to
  # US-ASCII external encoding and would choke on a regex match otherwise).
  def read(path)
    File.read(path, encoding: 'UTF-8')
  end

  # Returns [frontmatter_hash_or_nil, body_string].
  def parse(path)
    raw = read(path)
    if raw =~ /\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)\z/m
      fm = (yload($1) rescue nil)
      [fm.is_a?(Hash) ? fm : nil, $2 || '']
    else
      [nil, raw]
    end
  end

  # Strip fenced code blocks and inline code spans from a markdown body so a
  # banned word inside a shell snippet (`leverage`, `just`) is not flagged.
  def strip_code(body)
    body.gsub(/```.*?```/m, ' ').gsub(/`[^`]*`/, ' ')
  end

  # The canonical finding. aggregate.rb adds the fingerprint; producers do not.
  # severity: 'error' (blocks the gate) | 'warning' (reported) | 'info'.
  # route_to: 'local' | 'upstream' | 'backlog' (a hint PR2/triage consumes).
  def finding(check_id:, severity:, rule:, evidence:, file: '', line: nil,
              route_to: 'local', prime_directive_candidate: false)
    {
      'check_id'                  => check_id,
      'severity'                  => severity,
      'file'                      => file.to_s,
      'line'                      => line,
      'rule'                      => rule,
      'evidence'                  => evidence.to_s,
      'route_to'                  => route_to,
      'prime_directive_candidate' => prime_directive_candidate
    }
  end

  # Write a check's findings to test-results/<name>.json and echo a summary.
  # Returns the number of error-severity findings (the caller's exit hint).
  def write(name, findings)
    Dir.mkdir(RESULTS) unless Dir.exist?(RESULTS)
    File.write(File.join(RESULTS, "#{name}.json"), JSON.pretty_generate(findings))
    errs  = findings.count { |f| f['severity'] == 'error' }
    warns = findings.count { |f| f['severity'] == 'warning' }
    puts "[#{name}] #{findings.size} findings — #{errs} error, #{warns} warning"
    findings.each do |f|
      mark = case f['severity']
             when 'error'   then 'ERROR'
             when 'warning' then 'warn '
             else                'info '
             end
      loc = f['file'].to_s.empty? ? '' : " #{f['file']}#{f['line'] ? ":#{f['line']}" : ''}"
      puts "  #{mark} #{f['rule']}#{loc} — #{f['evidence']}"
    end
    errs
  end
end
