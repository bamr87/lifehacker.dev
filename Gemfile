source "https://rubygems.org"

# This Gemfile is for LOCAL and CI builds only. GitHub Pages ("Deploy from a
# branch") ignores it and resolves its own copy of the github-pages bundle.
#
# GitHub Pages compatibility: build against the SAME `github-pages` gem that
# GitHub Pages runs — it pins the exact Jekyll + whitelisted-plugin versions
# Pages uses, so a green build here means a green build there. (Building with
# this gem is itself the compatibility check: a non-whitelisted plugin in
# _config.yml would fail to load.)
#
# Pinned `>= 228` on purpose: left unpinned, `bundle install` on a modern Ruby
# CI runner backtracks to an ancient release (github-pages 170 → Jekyll 3.6.2,
# which predates jekyll-include-cache on the whitelist) and the build breaks. A
# floor of 228 keeps us on a current, include-cache-bearing bundle.
gem "github-pages", ">= 228", group: :jekyll_plugins
gem "jekyll-remote-theme"
gem "webrick", "~> 1.7"
