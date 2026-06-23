source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
gem "jekyll-remote-theme"
gem "webrick", "~> 1.7"

# rexml is no longer a default gem on modern rubies, and jekyll/kramdown require
# it at load time (a CI build dies with `cannot load such file -- rexml` without
# it). Keep this list minimal: adding other unconstrained stdlib gems (csv,
# logger, …) conflicts with github-pages' pinned deps and makes bundler drop
# github-pages, downgrading Jekyll. GitHub Pages' own build ignores this Gemfile.
gem "rexml"
