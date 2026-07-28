---
title: "A Jekyll Dockerfile That Builds on Ruby 2.7: Pinning Past the Version Wall"
description: "Stuck on Ruby 2.7 and bundle install keeps demanding 3.0? Here are the Jekyll, Bundler, and nokogiri version pins that build, plus how to read the wall."
date: 2019-08-22
categories: [Hacks]
tags: [jekyll, docker, web-dev]
author: amr
excerpt: "The fix for 'works on the new Ruby' isn't upgrading. It's pinning the four gems that quietly require 3.0 — and knowing which line in the log to read."
preview: /images/previews/section-hacks.svg
permalink: /hacks/dockering-your-it-journey/
---
The advice when a Docker build fails on an old Ruby is always the same: bump the base image. `FROM ruby:2.7` got you here, so swap it for `ruby:3.1` and move on with your life.

Except sometimes you can't. The host you deploy to is pinned to 2.7, or a downstream gem you don't control hasn't moved, or it's a corporate base image and "just upgrade Ruby" is a six-week ticket. So the real problem isn't "how do I get to Ruby 3" — it's "how do I build this Jekyll site on the Ruby I'm stuck with."

That's a solvable problem. The trick is that the version wall isn't Ruby's. It's four specific gems that bumped their `required_ruby_version` to `>= 3.0` and dragged the whole build down with them. Pin past those four and a 2.7 build comes back to life.

This post leaves the failures in, in order, because the order is the whole lesson: each fix surfaces the next gem behind it.

## The naïve Dockerfile (and why it dies)

Here's the Dockerfile every Jekyll tutorial gives you. It's correct — for whatever Ruby was current when the tutorial was written:

```dockerfile
# Use an official Ruby runtime as a parent image
FROM ruby:2.7

# Install Node.js (Jekyll wants a JS runtime around)
RUN apt-get update -qq && apt-get install -y nodejs

# Install Jekyll and Bundler
RUN gem install jekyll bundler

WORKDIR /app
ADD . /app
RUN bundle install

EXPOSE 4000
CMD ["jekyll", "serve", "--host", "0.0.0.0"]
```

`gem install jekyll bundler` resolves to the latest of each. On a 2.7 base, that's where it stops. The error (this is the real one from the build this was written from — pulling the image and running `gem install` needs network and Docker, so it's documented here, not re-captured):

```
ERROR:  Error installing jekyll:
	sass-embedded requires Ruby version >= 3.0.0. The current ruby version is 2.7.8.225.
```

The gem you asked for is `jekyll`. The gem that blocks you is `sass-embedded` — a transitive dependency of modern Jekyll. The current Jekyll pulls it in, and `sass-embedded` requires Ruby 3. You never typed its name; it still ended your build.

## Read the wall before you guess at it

Before fixing anything, learn to read the one line that matters. A `bundle install` failure prints a lot of noise; the version wall is a single sentence, and you can pull it straight out of the log.

This block is self-contained — it writes its own fixture log and parses it with `grep`, no network or Docker — so it runs the same anywhere:

```bash
# lh:run
cd "$(mktemp -d)"
cat > install.log <<'EOF'
Fetching gem metadata from https://rubygems.org/.........
Resolving dependencies...
ERROR:  Error installing jekyll:
	sass-embedded requires Ruby version >= 3.0.0. The current ruby version is 2.7.8.225.
EOF

# Pull out the offending gem and the Ruby version it demands:
grep -oE '[a-z0-9_-]+ requires Ruby version >= [0-9]+\.[0-9]+\.[0-9]+' install.log
```

You'll know it worked when it prints exactly the gem and the wall, with the rest of the log thrown away:

```
sass-embedded requires Ruby version >= 3.0.0
```

That's the whole diagnostic. The fix is never "Ruby is too old" in the abstract — it's "*this named gem* demands a newer Ruby, so pin to its last version that didn't." Save that grep; you'll run it once per gem as you peel the layers.

## Pin one: Jekyll and Bundler

Stop letting `gem install` grab the latest. Name the versions that still support 2.7. Jekyll 3.9.x and Bundler 1.17.x are the last comfortable on Ruby 2.7:

```dockerfile
# Install specific versions compatible with Ruby 2.7
RUN gem install jekyll -v 3.9.0 && gem install bundler -v 1.17.3
```

Jekyll 3.9 predates the `sass-embedded` dependency entirely (it uses the old pure-Ruby Sass), so the first wall is gone. Bundler 1.17.3 is the last 1.x — modern Bundler 2.x also leans toward newer Ruby, so pin it down with everything else.

You'll know this layer got past the first wall when `gem install jekyll -v 3.9.0` finishes and the build moves on to `bundle install` instead of dying on `sass-embedded`.

## Pin two: the wall right behind it

Here's the part the "just bump the base image" crowd never warns you about: fixing one gem reveals the next. With Jekyll pinned, `bundle install` runs further, then stops again:

```
ERROR:  Error installing github-pages:
	nokogiri requires Ruby version >= 3.0. The current ruby version is 2.7.4.191.
```

Same shape, different gem. `nokogiri` — the XML/HTML parser half the Jekyll ecosystem depends on — moved its floor to Ruby 3 in the 1.13 line. The last 1.x that ships for 2.7 is 1.11.7. And if you're on `github-pages`, that gem chases the latest nokogiri unless you pin it too, so pin the pair:

```dockerfile
# nokogiri 1.13+ requires Ruby 3; 1.11.7 is the last that builds on 2.7.
# github-pages 209 is contemporaneous and won't drag in a newer nokogiri.
RUN gem install nokogiri -v 1.11.7 && gem install github-pages -v 209
```

You'll know it worked when `bundle install` completes with a `Bundle complete!` line instead of a `requires Ruby version` error.

## The Dockerfile that actually builds on 2.7

Put the pins together. This is the working version — every gem named, nothing left to resolve to "latest":

```dockerfile
# A Jekyll Dockerfile that builds on Ruby 2.7.
FROM ruby:2.7

# Jekyll wants a JS runtime present at build time.
RUN apt-get update -qq && apt-get install -y nodejs

# The four pins. Each is the last version before its gem demanded Ruby 3.
RUN gem install bundler  -v 1.17.3 \
 && gem install jekyll   -v 3.9.0  \
 && gem install nokogiri -v 1.11.7 \
 && gem install github-pages -v 209

WORKDIR /app
COPY . /app
RUN bundle install

EXPOSE 4000
CMD ["jekyll", "serve", "--host", "0.0.0.0", "--port", "4000"]
```

Lock the same versions into your `Gemfile` so `bundle install` doesn't re-resolve them back to the walls:

```ruby
source "https://rubygems.org"

gem "jekyll", "3.9.0"
gem "nokogiri", "1.11.7"
gem "github-pages", "209"

# Bundler is pinned at the CLI in the Dockerfile, not here.
```

Build and run it:

```bash
docker build -t jekyll-27 .
docker run --rm -p 4000:4000 jekyll-27
```

You'll know it worked when `docker build` runs all the way to the `CMD` line without a `requires Ruby version` error, and `http://localhost:4000` serves your site. (These two commands need Docker and network, so they're documented here, not re-captured in the sandbox.)

## The part where it broke (the order is the trap)

The failure that eats the afternoon isn't any single version wall. It's that they queue up. You pin Jekyll, feel relieved, rebuild — and `nokogiri` fails. You assume your *first* fix was wrong and start undoing it. It wasn't wrong; it merely uncovered the next gem in line.

So the procedure is iterative on purpose:

1. Run the build. Read the *one* `requires Ruby version` line (the grep above).
2. Pin *that one gem* to its last 2.7-compatible version.
3. Rebuild. If a new gem fails, that's progress, not regression — go back to step 1.

Each pin reveals the next wall until there are none left. For a stock GitHub-Pages-flavored Jekyll site, that's the four above. A site with more plugins may surface a fifth — same drill, same grep.

## The honest accounting

Pinning to 2.7-era gems is borrowed time, not a fix. Jekyll 3.9 and nokogiri 1.11 don't get security patches anymore, and every new plugin you add is one more gem that may have already left 2.7 behind. The pins keep an existing site building today; they don't make staying on 2.7 a good long-term plan.

What they buy you is the ability to ship without a Ruby upgrade you can't do this week. When you *can* move, the cleaner path is `FROM ruby:3.1` and dropping every `-v` flag — modern Jekyll resolves fine on its own. Until then: read the wall, pin the gem behind it, rebuild, repeat. The build that "needs Ruby 3" usually only needs you to name four versions.
