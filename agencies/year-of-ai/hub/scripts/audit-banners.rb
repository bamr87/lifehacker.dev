#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# audit-banners.rb — the banner-quality baseline (ADR-0008 Phase 0).
# =============================================================================
# Shallow-clones every member of the lineage, and for each committed preview
# banner (assets/images/previews/*.svg):
#
#   1. strict-lints it with the zer0-image-generator engine (`--inspect`, the
#      SAME lint the illustration loop gates on) and counts what it is made of
#      (<text>, <filter>, gradients, size);
#   2. renders it at 600px and 120px (resvg) and writes one contact sheet per
#      repo, so a human can see the thumbnail test fail or pass at a glance;
#   3. for a deterministic sample of N banners, runs the loop's vision CRITIC
#      (`--inspect --critic`) against the article the banner illustrates.
#
# Writes a Markdown report and a JSON twin (the JSON is what
# scripts/reillustrate.rb reads to work the backlog worst-first). Read-only
# against the members: nothing is pushed anywhere. Ruby stdlib only, and
# Ruby 2.6-compatible on purpose — it runs where python3, resvg and a Claude
# login are, which is usually a laptop, not a runner.
#
#   ruby scripts/audit-banners.rb --engine ../zer0-CMS/packages/zer0-image-generator/lib/zer0_image_generator/preview_generator.py
#   ruby scripts/audit-banners.rb --members 2008 --critic 5 --no-render
#   ruby scripts/audit-banners.rb --help
#
# KPIs (the before picture every later phase is measured against):
#   strict-clean %, mean critic `overall`, `thumbnail_holds` %, cost/banner.
# =============================================================================

require 'json'
require 'yaml'
require 'open3'
require 'optparse'
require 'fileutils'
require 'digest'
require 'time'

ROOT = File.expand_path('..', __dir__)

opts = {
  org: nil,
  members: nil,
  engine: ENV['ZER0_IMAGE_ENGINE'],
  work: File.join(ROOT, '.audit-banners'),
  critic: 20,
  critic_model: 'claude-sonnet-5-5',
  seed: 'adr-0008',
  out: File.join(ROOT, '_reports', 'banners-baseline.md'),
  json: nil,
  render: true,
  refresh: false
}
OptionParser.new do |o|
  o.banner = 'usage: ruby scripts/audit-banners.rb [options]'
  o.on('--org ORG', 'GitHub org (default: _data/hub.yml org)') { |v| opts[:org] = v }
  o.on('--members LIST', 'comma-separated member repos (default: every lineage/seeds/*.md)') { |v| opts[:members] = v.split(',').map(&:strip) }
  o.on('--engine PATH', 'preview_generator.py with --inspect (zer0-image-generator >= 0.10; default $ZER0_IMAGE_ENGINE, then the installed gem)') { |v| opts[:engine] = v }
  o.on('--work DIR', 'clone + render scratch dir (default .audit-banners/, gitignored)') { |v| opts[:work] = v }
  o.on('--critic N', Integer, 'banners to vision-critique (default 20; 0 = lint only)') { |v| opts[:critic] = v }
  o.on('--critic-model MODEL', 'critic model (default claude-sonnet-5-5)') { |v| opts[:critic_model] = v }
  o.on('--seed TEXT', 'sample seed (default adr-0008 — same seed, same sample)') { |v| opts[:seed] = v }
  o.on('--out PATH', 'Markdown report (default _reports/banners-baseline.md)') { |v| opts[:out] = v }
  o.on('--json PATH', 'JSON twin (default: the report path with .json)') { |v| opts[:json] = v }
  o.on('--no-render', 'skip the 600px/120px renders and contact sheets') { opts[:render] = false }
  o.on('--refresh', 're-clone members even when a clone exists') { opts[:refresh] = true }
  o.on('-h', '--help') { puts o; exit 0 }
end.parse!
opts[:json] ||= opts[:out].sub(/\.md\z/, '') + '.json'

def log(msg)
  warn "[audit-banners] #{msg}"
end

def capture(*cmd, chdir: nil)
  o = {}
  o[:chdir] = chdir if chdir
  Open3.capture3(*cmd, **o)
rescue SystemCallError => e
  ['', e.message, nil]
end

def which(tool)
  ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).map { |d| File.join(d, tool) }
     .find { |p| File.file?(p) && File.executable?(p) }
end

# ---- engine ------------------------------------------------------------------
def find_engine(explicit)
  return explicit if explicit && File.file?(explicit)

  out, _err, status = capture('gem', 'contents', 'zer0-image-generator')
  hit = status && status.success? ? out.lines.map(&:strip).find { |l| l.end_with?('preview_generator.py') } : nil
  hit
end

engine = find_engine(opts[:engine])
abort '[audit-banners] engine not found — pass --engine PATH (zer0-image-generator >= 0.10)' unless engine
help, = capture('python3', engine, '--help')
unless help.include?('--inspect')
  abort "[audit-banners] #{engine} has no --inspect — the audit needs zer0-image-generator >= 0.10 " \
        '(the illustration-loop release). Pass --engine to a newer checkout.'
end
log "engine: #{engine}"

# ---- members -----------------------------------------------------------------
hub = YAML.load_file(File.join(ROOT, '_data', 'hub.yml')) rescue {}
org = opts[:org] || hub['org']
abort '[audit-banners] no org — set _data/hub.yml org or pass --org' if org.to_s.empty?
members = opts[:members] || Dir[File.join(ROOT, 'lineage', 'seeds', '*.md')].map { |p| File.basename(p, '.md') }.sort
abort '[audit-banners] no members' if members.empty?
FileUtils.mkdir_p(File.join(opts[:work], 'members'))

def clone_member(org, repo, dir, refresh)
  if Dir.exist?(File.join(dir, '.git')) && !refresh
    return true
  end

  FileUtils.rm_rf(dir)
  _out, err, status = capture('git', 'clone', '-q', '--depth', '1', "https://github.com/#{org}/#{repo}.git", dir)
  log "clone #{repo} failed: #{err.strip}" unless status && status.success?
  status && status.success?
end

# preview: front-matter value → the articles that carry it (basename match;
# front matter omits /assets and the theme restores it). Only files inside a
# Jekyll collection directory (`_posts/`, `_<name>/`) are articles — README,
# TIMELINE and index pages reuse section banners but are not what a banner is
# drawn for. A banner more than one article carries is a SHARED section
# placeholder: reported, but never critiqued per article or backfilled.
def article_index(dir)
  index = Hash.new { |h, k| h[k] = [] }
  Dir.glob(File.join(dir, '**', '*.{md,markdown}')).sort.each do |path|
    rel = path.sub("#{dir}/", '')
    next if rel.start_with?('.git/')
    next unless rel.split('/')[0..-2].any? { |seg| seg.start_with?('_') }

    raw = File.read(path, encoding: 'utf-8') rescue next
    fm = raw[/\A---\s*\n(.*?)\n---\s*$/m, 1]
    next unless fm

    line = fm.lines.find { |l| l.start_with?('preview:') }
    next unless line

    value = line.sub('preview:', '').strip.delete('"\'')
    next if value.empty?

    index[File.basename(value.strip)] << path
  end
  index
end

# ---- renderer ----------------------------------------------------------------
RENDERER = if which('resvg') then [:resvg]
           elsif which('resvg-js') then [:resvg_js]
           elsif which('npx') then [:npx]
           end

def render(svg, png, width)
  cmd = case RENDERER && RENDERER.first
        when :resvg then ['resvg', '-w', width.to_s, svg, png]
        when :resvg_js then ['resvg-js', '--fit-width', width.to_s, svg, png]
        when :npx then ['npx', '-y', '@resvg/resvg-js-cli', '--fit-width', width.to_s, svg, png]
        end
  return false unless cmd

  _o, _e, status = capture(*cmd)
  status && status.success? && File.file?(png)
end

def contact_sheet(sheet_dir, repo, rows)
  FileUtils.mkdir_p(sheet_dir)
  cells = rows.map do |r|
    flags = []
    flags << 'TEXT' if r['features']['text'].to_i.positive?
    flags << 'FILTER' if r['features']['filter'].to_i.positive?
    flags << (r['lint']['clean'] ? 'strict-clean' : 'lint-fail')
    <<~HTML
      <figure><img src="#{r['render_600']}" width="300"><img src="#{r['render_120']}" width="120">
      <figcaption>#{r['name']} · #{r['kb']}KB · #{flags.join(' · ')}</figcaption></figure>
    HTML
  end
  html = <<~HTML
    <!doctype html><meta charset="utf-8"><title>#{repo} banners</title>
    <style>body{font:13px system-ui;background:#111;color:#ddd;display:flex;flex-wrap:wrap;gap:12px;padding:12px}
    figure{margin:0;background:#1c1c1c;padding:6px;border-radius:6px}img{display:block;margin-bottom:4px}
    img[width="120"]{image-rendering:auto}</style>
    #{cells.join}
  HTML
  path = File.join(sheet_dir, "#{repo}.html")
  File.write(path, html)
  thumbs = rows.map { |r| r['render_120'] }.compact.select { |p| File.file?(p) }
  if which('montage') && !thumbs.empty?
    capture('montage', *thumbs, '-tile', '8x', '-geometry', '+4+4', '-background', '#111', File.join(sheet_dir, "#{repo}-thumbs.png"))
  end
  path
end

# ---- pass 1: lint + features (+ renders) --------------------------------------
results = []
members.each do |repo|
  dir = File.join(opts[:work], 'members', repo)
  next unless clone_member(org, repo, dir, opts[:refresh])

  banners = Dir[File.join(dir, 'assets', 'images', 'previews', '*.svg')].sort
  index = article_index(dir)
  log "#{repo}: #{banners.length} banner(s)"
  rows = banners.map do |svg|
    out, err, status = capture('python3', engine, '--inspect', svg, chdir: dir)
    report = begin
      JSON.parse(out)
    rescue JSON::ParserError
      { 'lint' => { 'clean' => false, 'fatal' => "inspect failed: #{err.strip[-200..] || err.strip}", 'errors' => [], 'warnings' => [] },
        'features' => {}, 'kb' => (File.size(svg) / 1024.0).round(1) }
    end
    log "  inspect exit #{status && status.exitstatus} on #{File.basename(svg)}" unless status && status.success?
    row = {
      'repo' => repo, 'name' => File.basename(svg), 'path' => svg,
      'article' => (index[File.basename(svg)].length == 1 ? index[File.basename(svg)].first : nil),
      'shared' => index[File.basename(svg)].length > 1,
      'carried_by' => index[File.basename(svg)].length,
      'kb' => report['kb'], 'lint' => report['lint'], 'features' => report['features'] || {}
    }
    if opts[:render]
      base = File.join(opts[:work], 'renders', repo, File.basename(svg, '.svg'))
      FileUtils.mkdir_p(File.dirname(base))
      row['render_600'] = render(svg, "#{base}-600.png", 600) ? "#{base}-600.png" : nil
      row['render_120'] = render(svg, "#{base}-120.png", 120) ? "#{base}-120.png" : nil
    end
    row
  end
  contact_sheet(File.join(opts[:work], 'sheets'), repo, rows) if opts[:render] && !rows.empty?
  results.concat(rows)
end
abort '[audit-banners] no banners found' if results.empty?

# ---- pass 2: the critic sample -----------------------------------------------
sample = results.select { |r| r['article'] }
               .sort_by { |r| Digest::SHA256.hexdigest("#{opts[:seed]}:#{r['repo']}/#{r['name']}") }
               .first(opts[:critic])
sample.each_with_index do |row, i|
  dir = File.join(opts[:work], 'members', row['repo'])
  log "critic #{i + 1}/#{sample.length}: #{row['repo']}/#{row['name']}"
  out, err, = capture('python3', engine, '--inspect', row['path'], '--critic', '-f', row['article'],
                      '--look-rasterizer', 'resvg', '--model', opts[:critic_model], chdir: dir)
  report = JSON.parse(out) rescue { 'critic_error' => err.strip[-300..] || err.strip }
  row['critic'] = report['critic']
  row['critic_error'] = report['critic_error'] if report['critic_error']
  row['critic_cost_usd'] = report['cost_usd']
end

# ---- aggregate ---------------------------------------------------------------
def pct(n, d)
  d.zero? ? 0.0 : (100.0 * n / d).round(1)
end

def median(values)
  v = values.compact.sort
  return nil if v.empty?

  v.length.odd? ? v[v.length / 2] : ((v[v.length / 2 - 1] + v[v.length / 2]) / 2.0).round(1)
end

TEXT_WARNING_RE = /<text> present/.freeze

def summarize(rows)
  n = rows.length
  text_only = rows.count do |r|
    l = r['lint']
    !l['clean'] && !l['fatal'] && l['errors'].empty? && l['warnings'].all? { |w| w =~ TEXT_WARNING_RE }
  end
  {
    'banners' => n,
    'with_text_pct' => pct(rows.count { |r| r['features']['text'].to_i.positive? }, n),
    'strict_clean_pct' => pct(rows.count { |r| r['lint']['clean'] }, n),
    'clean_but_text_pct' => pct(text_only, n),
    'with_errors_pct' => pct(rows.count { |r| r['lint']['fatal'] || !r['lint']['errors'].empty? }, n),
    'median_kb' => median(rows.map { |r| r['kb'] }),
    'filter_pct' => pct(rows.count { |r| r['features']['filter'].to_i.positive? }, n),
    'gradient_pct' => pct(rows.count { |r| r['features']['gradient'].to_i.positive? }, n),
    'text_elements' => rows.sum { |r| r['features']['text'].to_i },
    'shared' => rows.count { |r| r['shared'] },
    'orphaned' => rows.count { |r| r['carried_by'].to_i.zero? }
  }
end

by_repo = results.group_by { |r| r['repo'] }
repo_stats = by_repo.map { |repo, rows| [repo, summarize(rows)] }.to_h
totals = summarize(results)

findings = Hash.new(0)
results.each do |r|
  l = r['lint']
  ([l['fatal']].compact + l['errors'] + l['warnings']).each do |f|
    findings[f.gsub(/\d+(\.\d+)?/, 'N').gsub(/\(N,N\)/, '(x,y)').sub(/: [^—]+(—|$)/, ': … \1').strip] += 1
  end
end

critiqued = sample.select { |r| r['critic'] }
critic_summary = {
  'sampled' => sample.length,
  'critiqued' => critiqued.length,
  'mean_overall' => critiqued.empty? ? nil : (critiqued.sum { |r| r['critic']['overall'].to_f } / critiqued.length).round(2),
  'thumbnail_holds_pct' => pct(critiqued.count { |r| r['critic']['thumbnail_holds'] }, critiqued.length),
  'cost_usd' => sample.map { |r| r['critic_cost_usd'] }.compact.sum.round(4),
  'errors' => sample.count { |r| r['critic_error'] }
}

generated = Time.now.utc.iso8601
data = {
  'schema' => 'banner-audit/v1', 'generated' => generated, 'org' => org,
  'engine' => engine.sub(%r{\A.*/(packages|gems)/}, '\1/'), 'critic_model' => opts[:critic_model], 'seed' => opts[:seed],
  'totals' => totals, 'repos' => repo_stats, 'critic' => critic_summary,
  'banners' => results.map do |r|
    r.reject { |k, _| %w[path render_600 render_120].include?(k) }
     .merge('article' => r['article'] && r['article'].sub("#{File.join(opts[:work], 'members', r['repo'])}/", ''))
  end
}
FileUtils.mkdir_p(File.dirname(opts[:json]))
File.write(opts[:json], JSON.pretty_generate(data) + "\n")

# ---- report ------------------------------------------------------------------
fmt = ->(v) { v.nil? ? '—' : v.to_s }
# A Markdown table cell: backslashes first, then pipes, so an escaped pipe in
# model text can never close the cell early; newlines collapse to spaces.
cell = ->(v) { v.to_s.gsub(/\s+/, ' ').gsub('\\') { '\\\\' }.gsub('|') { '\\|' } }
md = []
md << '# Banner quality baseline'
md << ''
md << "Generated #{generated} by `scripts/audit-banners.rb` (ADR-0008 Phase 0) over #{members.length} member(s) of `#{org}`. The JSON twin [`#{File.basename(opts[:json])}`](#{File.basename(opts[:json])}) carries every banner's row; `scripts/reillustrate.rb` works the backlog from it."
md << ''
md << '## KPIs'
md << ''
md << '| KPI | Baseline |'
md << '| --- | --- |'
md << "| Banners | #{totals['banners']} |"
md << "| Strict-clean | #{totals['strict_clean_pct']}% |"
md << "| …failing only on `<text>` | #{totals['clean_but_text_pct']}% |"
md << "| Mean critic `overall` (n=#{critic_summary['critiqued']}) | #{fmt.call(critic_summary['mean_overall'])} |"
md << "| `thumbnail_holds` | #{critic_summary['critiqued'].zero? ? '—' : "#{critic_summary['thumbnail_holds_pct']}%"} |"
cost_cell = if critic_summary['critiqued'].zero? then '—'
            elsif critic_summary['cost_usd'].zero? then '— (CLI login: no usage reported)'
            else "$#{critic_summary['cost_usd']}"
            end
md << "| Critic cost (list price, sample) | #{cost_cell} |"
md << ''
md << '## Per repo'
md << ''
md << '| Repo | Banners | With `<text>` | Strict-clean | Clean but `<text>` | Lint errors | Median KB | `<filter>` | Gradients |'
md << '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |'
repo_stats.each do |repo, s|
  md << "| #{repo} | #{s['banners']} | #{s['with_text_pct']}% | #{s['strict_clean_pct']}% | #{s['clean_but_text_pct']}% | #{s['with_errors_pct']}% | #{fmt.call(s['median_kb'])} | #{s['filter_pct']}% | #{s['gradient_pct']}% |"
end
md << "| **all** | **#{totals['banners']}** | **#{totals['with_text_pct']}%** | **#{totals['strict_clean_pct']}%** | **#{totals['clean_but_text_pct']}%** | **#{totals['with_errors_pct']}%** | **#{fmt.call(totals['median_kb'])}** | **#{totals['filter_pct']}%** | **#{totals['gradient_pct']}%** |"
md << ''
md << "#{totals['shared']} banner(s) are shared section placeholders (carried by more than one article) and #{totals['orphaned']} are carried by no article at all — neither is critiqued per article or backfilled. #{totals['text_elements']} `<text>` elements in all. Strict lint treats any `<text>` as a failure (fonts are not guaranteed at render time); the \"clean but `<text>`\" column is what the illustration loop's text→paths step fixes mechanically, without a model call."
md << ''
md << '## Lint findings'
md << ''
md << '| Count | Finding (numbers normalized) |'
md << '| ---: | --- |'
findings.sort_by { |f, c| [-c, f] }.first(15).each { |f, c| md << "| #{c} | #{cell.call(f)} |" }
md << ''
md << "## Critic sample (#{critic_summary['critiqued']}/#{critic_summary['sampled']}, model `#{opts[:critic_model]}`, seed `#{opts[:seed]}`)"
md << ''
if sample.empty?
  md << '_No critic pass (`--critic 0`, or no banner could be matched to its article)._'
else
  md << '| Banner | Overall | Thumbnail | Next change |'
  md << '| --- | ---: | :---: | --- |'
  sample.sort_by { |r| r['critic'] ? r['critic']['overall'].to_f : 99 }.each do |r|
    c = r['critic']
    if c
      md << "| #{r['repo']}/#{r['name']} | #{c['overall']} | #{c['thumbnail_holds'] ? 'holds' : 'fails'} | #{cell.call(c['next_change'].to_s[0, 180])} |"
    else
      md << "| #{r['repo']}/#{r['name']} | — | — | critic unavailable: #{cell.call(r['critic_error'].to_s[0, 120])} |"
    end
  end
end
md << ''
md << '## Method'
md << ''
md << "- Lint: `#{File.basename(engine)} --inspect` — the engine's strict lint, identical to the illustration loop's commit gate (viewBox, role/title, raster or network payloads, dangling `url(#…)`, precision, the size budget, and `<text>`)."
md << "- Renders: #{RENDERER ? RENDERER.first : 'none available'} at 600px and 120px; contact sheets are written to the scratch dir (`#{File.basename(opts[:work])}/sheets/`), not committed."
md << "- Critic: `--inspect --critic` renders each sampled banner at 1536px and 120px and asks `#{opts[:critic_model]}` for the loop's structured critique against the article it illustrates. The sample is the first N banners by SHA-256 of `seed:repo/name`, so a re-run with the same seed scores the same banners."
md << ''
FileUtils.mkdir_p(File.dirname(opts[:out]))
File.write(opts[:out], md.join("\n"))
log "wrote #{opts[:out]} and #{opts[:json]}"
