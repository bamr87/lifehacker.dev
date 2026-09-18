source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
gem "jekyll-remote-theme"
gem "webrick", "~> 1.7"

# Stdlib gems extracted from Ruby's default set (needed to run jekyll 3.x
# locally on Ruby >= 3.4; the GitHub Pages builders don't need them).
gem "csv"
gem "base64"
gem "logger"

# `jekyll preview-images` — the zer0 stack's image engine, consumed as the
# published gem, never a vendored _plugins/ or scripts/lib/ copy. It reads the
# `preview_images:` block in _config.yml. Build-time only: GitHub Pages ignores
# it (safe mode) and serves the committed images. This site's banners are drawn
# by Trace Bloom (scripts/preview/generate.mjs, docs/PREVIEW-IMAGES.md), which
# needs no gem; scripts/generate-preview-images.sh is a shim to that generator.
# `~> 0.4` resolves 0.6.0 in Gemfile.lock.
gem "zer0-image-generator", "~> 0.4", group: :jekyll_plugins

# CI-only. GitHub Pages ignores non-jekyll_plugins groups, so this never affects
# the production build — it powers scripts/ci/htmlproofer_check.rb (link checks).
group :test do
  gem "html-proofer", "~> 5.0"
end
