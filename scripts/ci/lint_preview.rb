# =============================================================================
# lint_preview.rb — the gate that stops the cover-art failure from coming back.
# -----------------------------------------------------------------------------
# History (docs/PREVIEW-IMAGES.md): the old pipeline's capability ladder always
# fell through to a deterministic template, and because a template renders and
# exits 0, nothing noticed. 200 of 243 articles ended up wearing FOUR pictures
# between them, none of which contained a single word. Every check here exists
# because that failure was silent:
#
#   missing-preview-file   the stamp points at nothing — the card renders blank
#   shared-preview         one image doing duty for many articles (the pathology)
#   textless-banner        a generated banner with no headline — unreadable at 300px
#   unsafe-svg             script / foreignObject / external ref smuggled into art
#   preview-outside-safe-band  type that the homepage's 120px card crop cuts off
#   orphan-preview         art on disk that nothing references
#
# Stdlib only. Run: ruby scripts/ci/lint_preview.rb
# =============================================================================
require_relative '_lib'

PREVIEW_DIR = 'assets/images/previews'.freeze
# In-body figure art (scripts/media/figures.mjs + openai_image.mjs, one subdir
# per article slug). Figures are exhibits, never cover art, so they are held to
# the safety + existence rules only — not the headline/safe-band rules.
FIGURES_DIR = 'assets/images/figures'.freeze
DESIGN = begin
  JSON.parse(LH.read(File.join(LH::ROOT, '_data', 'preview', 'design.json')))
rescue StandardError
  {}
end
LAYOUT = DESIGN['layout'] || {}
CANVAS = DESIGN['canvas'] || {}
SAFE_TOP    = (LAYOUT['safeTop']    || 0.2) * (CANVAS['height'] || 1024)
SAFE_BOTTOM = (LAYOUT['safeBottom'] || 0.8) * (CANVAS['height'] || 1024)

SOURCES = [
  'pages/_posts/hacks', 'pages/_posts/tools', 'pages/_posts/field-notes',
  'pages/_posts/wire', 'pages/_posts', 'pages/_docs'
].freeze

findings = []

# ── 1. every article's stamp resolves, and nothing is over-shared ─────────────
# Theme convention (_includes/home/cover.html): a `preview:` may omit the
# `/assets` prefix, so both spellings must resolve.
def resolve(value)
  clean = value.to_s.sub(%r{\A/}, '')
  [File.join(LH::ROOT, 'assets', clean), File.join(LH::ROOT, clean)]
    .find { |p| File.file?(p) }
end

users = Hash.new { |h, k| h[k] = [] }
seen = {}
# Art embedded in an article BODY is not cover art, but it is still in use.
# `docs/the-plugin-that-isnt-a-plugin` embeds the old template banner on purpose,
# as an exhibit of what the retired pipeline produced — and the first version of
# this lint called it an orphan and had it deleted, which broke the page.
#   body_embeds  — real `![](…)` / <img src> embeds. A missing one is a broken
#                  image on the page, so it is an error.
#   body_mentions — the path appearing anywhere at all, code blocks included.
#                  Not a render, but still a reason never to delete the file.
# The split matters: these articles are *about* the preview pipeline, so their
# code blocks are full of example paths like `/images/previews/foo.png` that
# must not be mistaken for broken images.
body_embeds = Hash.new { |h, k| h[k] = [] }
body_refs = Hash.new { |h, k| h[k] = [] }
# Both art trees count as "in use": cover art under previews/, and the weekly
# epic's in-body figures under figures/<slug>/ (one extra path segment).
PREVIEW_PATH = %r{/(?:assets/)?images/(?:previews/[A-Za-z0-9._-]+|figures/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+)\.(?:svg|png|jpe?g|webp)}i

SOURCES.each do |dir|
  Dir.glob(File.join(LH::ROOT, dir, '*.md')).sort.each do |path|
    next if seen[path]

    seen[path] = true
    fm, body = LH.parse(path)
    body.to_s.scan(PREVIEW_PATH).each { |ref| body_refs[ref] << LH.rel(path) }
    prose = LH.strip_code(body.to_s)
    prose.scan(/!\[[^\]]*\]\((#{PREVIEW_PATH})[^)]*\)|<img[^>]+src=["'](#{PREVIEW_PATH})["']/i).each do |md, html|
      body_embeds[md || html] << LH.rel(path)
    end
    next unless fm

    rel = LH.rel(path)
    value = fm['preview'].to_s
    next if value.empty?          # lint_frontmatter already warns on a missing stamp
    next if value.start_with?('http://', 'https://')

    users[value] << rel
    next if resolve(value)

    findings << LH.finding(check_id: 'preview', severity: 'error',
                           rule: 'missing-preview-file', file: rel,
                           evidence: "`preview: #{value}` resolves to no file — the card, the og:image, " \
                                     'and the article banner all render blank. Run ' \
                                     'scripts/preview/generate.mjs -f <file>')
  end
end

# Body-embedded art that does not resolve is exactly the break this lint caused
# once: htmlproofer catches it only after a full build, which is minutes later.
body_embeds.each do |ref, articles|
  next if resolve(ref)

  findings << LH.finding(check_id: 'preview', severity: 'error',
                         rule: 'missing-body-image', file: articles.first,
                         evidence: "body embeds `#{ref}`, which resolves to no file — the page renders a " \
                                   "broken image (also seen #{articles.size}x)")
end

users.each do |value, articles|
  next if articles.size < 2

  # >2 articles behind one image is the regression this whole framework exists to
  # prevent. Exactly 2 is usually a grandfathered pair sharing a legacy photo.
  sev = articles.size > 2 ? 'error' : 'warning'
  findings << LH.finding(check_id: 'preview', severity: sev,
                         rule: 'shared-preview', file: articles.first,
                         evidence: "#{articles.size} articles share `#{value}` " \
                                   "(#{articles.take(3).join(', ')}#{articles.size > 3 ? ', …' : ''}) — " \
                                   'cover art is per-article; generate each one')
end

# ── 2. the generated art itself ──────────────────────────────────────────────
Dir.glob(File.join(LH::ROOT, PREVIEW_DIR, '*.svg')).sort.each do |path|
  rel = LH.rel(path)
  svg = LH.read(path)
  # Cover art = something an article stamps as `preview:`. That is what has to be
  # legible in a card and inside the safe band. A body-embedded exhibit is held to
  # the safety rule only.
  is_cover = users.keys.any? { |v| resolve(v) == path }
  in_body = body_refs.keys.any? { |v| resolve(v) == path }

  if is_cover && !svg.include?('<text')
    findings << LH.finding(check_id: 'preview', severity: 'error',
                           rule: 'textless-banner', file: rel,
                           evidence: 'banner renders no text at all — unreadable as a 300px card and ' \
                                     'as a share preview. This is the shape of the old template output.')
  end

  if svg =~ /<script|<foreignObject|<image\b/i || svg =~ /(?:href|src)\s*=\s*["']https?:/i
    findings << LH.finding(check_id: 'preview', severity: 'error',
                           rule: 'unsafe-svg', file: rel,
                           evidence: 'banner contains a script, foreignObject, or external reference — ' \
                                     'cover art must be self-contained and inert')
  end

  # Type that falls outside the safe band is cut off by the homepage card crop
  # (background-size: cover at 120px => only the middle 60% survives).
  svg.scan(/<text[^>]*\sy="([\d.]+)"/).flatten.map(&:to_f).each do |y|
    next unless is_cover
    next if y >= SAFE_TOP && y <= SAFE_BOTTOM

    findings << LH.finding(check_id: 'preview', severity: 'warning',
                           rule: 'preview-outside-safe-band', file: rel,
                           evidence: "text baseline y=#{y.round} is outside the safe band " \
                                     "#{SAFE_TOP.round}..#{SAFE_BOTTOM.round} — the 120px card crop cuts it off")
    break
  end

  next if is_cover || in_body

  findings << LH.finding(check_id: 'preview', severity: 'warning',
                         rule: 'orphan-preview', file: rel,
                         evidence: 'preview art referenced by no article — not as a `preview:` stamp and ' \
                                   'not embedded in any body. Delete it or stamp it.')
end

# ── 3. figure art (the weekly epic's in-body exhibits) ───────────────────────
# Same inertness bar as the banners — these SVGs render on the page, and an
# animated figure is exactly where a <script> would love to hide. Existence is
# already covered above (missing-body-image now matches figure paths); headline
# and safe-band rules deliberately do NOT apply, because a figure is not a card.
Dir.glob(File.join(LH::ROOT, FIGURES_DIR, '**', '*.{svg,png,jpg,jpeg,webp}')).sort.each do |path|
  rel = LH.rel(path)
  if path.end_with?('.svg')
    svg = LH.read(path)
    if svg =~ /<script|<foreignObject|<image\b/i || svg =~ /(?:href|src)\s*=\s*["']https?:/i
      findings << LH.finding(check_id: 'preview', severity: 'error',
                             rule: 'unsafe-svg', file: rel,
                             evidence: 'figure contains a script, foreignObject, or external reference — ' \
                                       'in-body art must be self-contained and inert')
    end
  end
  next if body_refs.keys.any? { |v| resolve(v) == path }

  findings << LH.finding(check_id: 'preview', severity: 'warning',
                         rule: 'orphan-figure', file: rel,
                         evidence: 'figure art referenced by no article body — regenerate the epic that ' \
                                   'owns it or delete the file (its digest.json/.prompt.json sidecars go with it)')
end

errs = LH.write('preview', findings)
exit(errs.zero? ? 0 : 1)
