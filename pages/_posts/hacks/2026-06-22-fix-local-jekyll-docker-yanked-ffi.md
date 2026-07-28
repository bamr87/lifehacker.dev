---
title: "When a Yanked FFI Gem Breaks Your Jekyll Docker Build: One Bundler Command"
description: "A local Jekyll Docker build died on a yanked x86_64-linux ffi pin. Here is the one Bundler command that re-resolves it, and why you must not commit the result."
date: 2026-06-22
categories: [Hacks]
tags: [shell, jekyll, docker]
author: amr
excerpt: "The container died mid-`bundle install` on an ffi build that no longer exists. One bundle lock command fixed it — and the real trap is what you do next."
preview: /images/previews/section-hacks.svg
permalink: /hacks/fix-local-jekyll-docker-yanked-ffi/
---
The build worked yesterday. You changed nothing. This morning `docker compose up jekyll` gets partway through `bundle install` and stops cold:

```text
Could not find ffi-1.16.3-x86_64-linux in locally installed gems
```

No code moved. No Gemfile changed. The thing that changed was on the other end of the internet, in a repository you do not own, and your `Gemfile.lock` is now politely insisting on a gem that no longer exists.

The fix is one command. The trap is the second thing you'll be tempted to do right after.

## Why a lockfile suddenly asks for a ghost

`Gemfile.lock` pins exact builds, including platform-specific ones. Somewhere in yours sits a *generic* `x86_64-linux` build of `ffi`:

```text
ffi (1.16.3-x86_64-linux)
```

That pin was valid when it was written. Then that specific platform build got yanked from RubyGems. Yanking is a real, supported thing maintainers do — and when it happens, the exact pin stops resolving inside the Linux container. Your lockfile keeps faithfully asking for it anyway. That is the lockfile doing its job, not failing at it: its entire purpose is to demand the exact thing you recorded. The recorded thing just evaporated.

You see it only in the container, because that's the platform the yanked build targeted. On your host (`arm64-darwin`, probably) the matching pin is a different line that's still fine, so the host build stays green and the container build dies — which is exactly the kind of "works on my machine" that eats an afternoon.

## The fix: drop the stale platform and let Bundler re-resolve

Don't hand-edit the lockfile. Tell Bundler to forget that platform, and it will resolve a build that still exists:

```bash
bundle lock --remove-platform x86_64-linux
```

We ran that against a lockfile pinned to the yanked platform. Real output (trimmed):

```text
Fetching gem metadata from https://rubygems.org/..
Resolving dependencies...
Writing lockfile to /private/var/folders/.../Gemfile.lock
```

And the `PLATFORMS` block went from this:

```text
PLATFORMS
  arm64-darwin-23
  x86_64-linux
```

to this:

```text
PLATFORMS
  arm64-darwin-23
  universal-darwin-25
```

The dead `x86_64-linux` pin is gone; Bundler re-resolved the platforms it could actually satisfy. Re-run `docker compose up jekyll` and `bundle install` gets past the line it choked on.

You'll know it worked when `bundle install` no longer prints `Could not find ffi-...-x86_64-linux` and the container reaches the Jekyll boot.

Note: `bundle lock` talks to RubyGems — it fetches metadata to re-resolve. So this is not an offline command, and you need network when you run it. (For what the flag does under the hood, the [Bundler `lock` docs](https://bundler.io/man/bundle-lock.1.html) are the source of truth.)

## The part where it broke: we committed the fix

Here's the mistake that turns a two-minute fix into a teammate's two-hour confusion, and we left it in because that's the lesson.

`bundle lock --remove-platform` rewrote `Gemfile.lock`. The build came back. Relieved, you `git add Gemfile.lock`, push, and move on. Now you've shipped a *local* repair as a *shared* change — you stripped `x86_64-linux` from the lockfile everyone's CI resolves against, and the next pipeline that needs that platform gets to rediscover the problem from scratch.

This is a local-only workaround. The committed lockfile is shared; CI resolves its own platform set on its own runner. The repair belongs on your disk, not in the history.

So guard it. Before you stage anything, ask git whether the lockfile moved — and if it did, treat that as a flag, not a change to commit:

```bash
# lh:run
cd "$(mktemp -d)"
printf 'PLATFORMS\n  arm64-darwin-23\n  x86_64-linux\n' > Gemfile.lock
git init -q && git add Gemfile.lock && git commit -qm init >/dev/null 2>&1

# simulate the local-only repair rewriting the lockfile
printf 'PLATFORMS\n  arm64-darwin-23\n' > Gemfile.lock

# the guard, run before every stage:
if git diff --quiet -- Gemfile.lock; then
  echo "Gemfile.lock unchanged - safe to commit"
else
  echo "Gemfile.lock is dirty - this is your LOCAL workaround, do not stage it"
  git checkout -- Gemfile.lock && echo "reverted; tree is clean again"
fi
echo "final state: [$(git status --porcelain)]"
```

We ran that. Real output:

```text
Gemfile.lock is dirty - this is your LOCAL workaround, do not stage it
reverted; tree is clean again
final state: []
```

The guard saw the lockfile drift, named it as a local workaround, and put the tree back. `git status --porcelain` printing nothing is the tell: there is nothing staged, so there is nothing to commit by accident.

If you'd rather keep the re-resolved lockfile around between sessions, fine — but keep it out of the commit. A `git diff --quiet -- Gemfile.lock` in your pre-commit hook does the same check automatically and exits non-zero when the lockfile is dirty, so the commit stops itself.

## Verify the page actually renders, not just that install succeeded

A clean `bundle install` is necessary, not sufficient. The gem resolved; that doesn't prove Jekyll built a page. Boot the container and ask for a real route:

```bash
docker compose up jekyll
# wait for: "Server running... http://0.0.0.0:4002"
curl -sSf http://localhost:4002/ >/dev/null && echo "build OK"
```

The `-sSf` matters. `-f` makes `curl` exit non-zero on an HTTP error instead of cheerfully printing the error page and returning success, so a 500 from a broken build short-circuits the `&&` and `build OK` never prints. We confirmed that short-circuit honestly against an unreachable port:

```text
curl failed (rc=7), so 'build OK' never printed
```

(That's `docker compose up` and a live server, so it's documentation, not a sandbox block — but the `-sSf` behavior above is real output we captured.)

You'll know it fully worked when `curl` prints `build OK` — a served page, not just a green install log.

## When this goes wrong

- **You removed the platform but CI still breaks.** CI resolves its own platforms; your local `--remove-platform` never reached it (and shouldn't have, via the lockfile). If CI itself hits a yanked build, run the same command *on a fresh resolve there* or update the gem version — don't paste your darwin lockfile into a Linux runner.
- **The error names a different gem, not `ffi`.** Same shape, same fix: `bundle lock --remove-platform <the-platform-in-the-error>`. The yank-then-stale-pin pattern isn't specific to `ffi`.
- **`bundle install` is still offline-failing.** `bundle lock` needs the network to re-resolve. If you're air-gapped, you can't re-resolve against a registry that's gone; you need either connectivity or a vendored cache.

## The honest accounting

This command makes nothing faster and fixes nothing in your code, because nothing in your code was broken. It earns its keep on exactly one kind of day: when an upstream you don't control deletes a build out from under a pin you do control, and your container starts demanding a gem that has ceased to exist.

The whole trade is two lines of judgment. Let the lockfile re-resolve instead of fighting it — and then resist the very natural urge to commit the thing that just saved you, because the next person's CI is counting on that lockfile being the shared truth, not your laptop's.
