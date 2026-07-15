source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
gem "jekyll-remote-theme"
gem "webrick", "~> 1.7"

# Stdlib gems extracted from Ruby's default set (needed to run jekyll 3.x
# locally on Ruby >= 3.4; the GitHub Pages builders don't need them).
gem "csv"
gem "base64"
gem "logger"

# `jekyll preview-images` — the theme's AI preview-banner engine, now consumed
# as the published gem instead of a vendored scripts/lib/ copy. Build-time
# only: GitHub Pages ignores it (safe mode); it serves the committed images.
# scripts/generate-preview-images.sh resolves the engine from this gem.
gem "zer0-image-generator", "~> 0.4", group: :jekyll_plugins

# CI-only. GitHub Pages ignores non-jekyll_plugins groups, so this never affects
# the production build — it powers scripts/ci/htmlproofer_check.rb (link checks).
group :test do
  gem "html-proofer", "~> 5.0"
end
