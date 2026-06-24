source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
gem "jekyll-remote-theme"
gem "webrick", "~> 1.7"

# CI-only. GitHub Pages ignores non-jekyll_plugins groups, so this never affects
# the production build — it powers scripts/ci/htmlproofer_check.rb (link checks).
group :test do
  gem "html-proofer", "~> 5.0"
end
