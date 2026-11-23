# =============================================================================
# Gemfile — ai-world-view.github.io (remote_theme consumer)
# =============================================================================
# This site vendors no theme files; it renders via the zer0-mistakes theme
# pulled over `remote_theme` (see _config.yml). Production builds on native
# GitHub Pages, which ignores this file and uses its own github-pages gem set —
# this Gemfile is only for local builds/previews, kept in lockstep with Pages.
# =============================================================================
source "https://rubygems.org"

# GitHub Pages gem — bundles Jekyll and every GitHub Pages whitelisted plugin
# (jekyll-seo-tag, jekyll-feed, jekyll-sitemap, jekyll-include-cache, …).
gem "github-pages", "~> 233", group: :jekyll_plugins

# Pull the shared theme from GitHub at build time.
gem "jekyll-remote-theme"

# Theme layouts use {% include_cached %}; load the plugin that provides it.
gem "jekyll-include-cache"

# Required to run `jekyll serve` on Ruby 3.x (webrick left the stdlib).
gem "webrick"

# `jekyll preview-images` — the fleet's AI preview-banner engine (same pin as
# lifehacker.dev and the year-of-ai hub). Build-time only: GitHub Pages
# ignores it (safe mode) and serves the committed images. The grow tick
# (grow-lineage.yml "Illustrate" step) installs it on the runner to banner the
# member repos; scripts/generate-preview-images.sh resolves the engine from
# this gem for the hub's own pages.
gem "zer0-image-generator", "~> 0.4", group: :jekyll_plugins

platforms :windows, :jruby do
  gem "tzinfo"
  gem "tzinfo-data"
end
gem "wdm", :platforms => [:windows]
