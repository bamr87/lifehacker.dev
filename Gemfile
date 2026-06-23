source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
gem "jekyll-remote-theme"
gem "webrick", "~> 1.7"

# Standard-library gems that were unbundled in Ruby 3.4+ and are no longer
# default gems on modern rubies (Ruby 3.3.x runners hit this). Jekyll/its deps
# require them at load time, so a local/CI build dies with
# `cannot load such file -- rexml` without these. (GitHub Pages' own build uses
# its pinned bundle and ignores this Gemfile, so this only affects local + CI.)
gem "rexml"
gem "base64"
gem "bigdecimal"
gem "csv"
gem "logger"
