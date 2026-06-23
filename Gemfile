source "https://rubygems.org"

# This Gemfile is for LOCAL and CI builds only. GitHub Pages ("Deploy from a
# branch") ignores it and uses its own pinned bundle.
#
# We pin the same stack GitHub Pages runs — Jekyll 3.10 plus the whitelisted
# plugins this site's _config.yml actually uses — instead of the `github-pages`
# meta-gem. On modern rubies the meta-gem's resolver backtracks to ancient
# releases (e.g. github-pages 170 → Jekyll 3.6.2, which predates
# jekyll-include-cache on the whitelist), which silently breaks the build.
# Pinning the real dependencies keeps CI faithful and deterministic.

gem "jekyll", "~> 3.10"
gem "jekyll-remote-theme"

# Plugins required by the theme / listed in _config.yml plugins:
gem "jekyll-include-cache"
gem "jekyll-feed"
gem "jekyll-sitemap"
gem "jekyll-seo-tag"
gem "jekyll-relative-links"
gem "jekyll-redirect-from"
gem "jekyll-paginate"

# Platform / modern-ruby shims:
gem "webrick", "~> 1.7"
gem "rexml"   # no longer a default gem on Ruby 3.4+; jekyll/kramdown require it
