---
title: "The work/ directory pattern: cache inputs, regenerate outputs, stop flaky CI builds"
description: "Why CI ships stale build artifacts, the mtime trap that causes it, and the work/ layout that caches dependencies but regenerates outputs — run for real."
date: 2025-11-16
categories: [Hacks]
tags: [shell, ci-cd, web-dev]
author: amr
excerpt: "CI cached the whole work/ folder to go faster. It went faster and shipped last week's build. Here's the failure and the layout that fixes it."
preview: /images/previews/section-hacks.svg
permalink: /hacks/work-directory-ci-cd/
---
Someone read that caching makes CI faster, so they cached the build directory. Builds got faster. They also started shipping code that didn't match the commit.

This is the failure mode nobody warns you about: a cache that's *too* greedy. It hands you back last run's compiled output, your build tool decides nothing changed, and CI green-lights a binary built from source that no longer exists.

The fix is a directory contract — one folder you cache, one folder you always throw away. Here's the contract, the failure, and the fix, all run on this host.

## The contract: one root, two lifecycles

Make a `work/` directory with a deliberate split. Things that are slow to fetch and rarely change go in `cache/`. Things derived from your source go in `build/`. Scratch goes in `temp/`.

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p work/cache/npm work/build/dist work/build/reports work/temp
find work -type d | sort
```

You'll know it worked when the tree comes back with the four lifecycles laid out:

```console
work
work/build
work/build/dist
work/build/reports
work/cache
work/cache/npm
work/temp
```

The rule each subfolder encodes:

- `work/cache/` — **persists** across runs. Downloaded dependencies, package caches. This is the only thing you cache.
- `work/build/` — **regenerated** every run. Compiled output, test reports. Never cached, never trusted between runs.
- `work/temp/` — **disposable**. Wiped at the end of every job.

The golden rule fits on one line: **cache inputs, regenerate outputs.** Caching `work/cache/` saves you a slow `npm install`. Caching `work/build/` saves you nothing and hands you a stale-output bug. Which is exactly what happened next.

## The part where it broke: a cached artifact that outlived its source

Here is the bug, reproduced honestly. The order matters and it's the order real CI uses: checkout writes your *new* source, then the cache step restores the *old* `work/build/` on top — so the stale artifact lands with a newer modification time than the source it's supposed to be built from.

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p work/build
echo 'console.log("v2")' > src.js              # fresh checkout of the NEW source
sleep 1
echo 'console.log("v1")' > work/build/out.js   # cache restore lands AFTER -> newer mtime

# A make/incremental build that trusts "output newer than input -> up to date":
if [ work/build/out.js -nt src.js ]; then
  echo "SKIP rebuild (out.js looks up-to-date)"
else
  echo "rebuild"
fi
echo "shipped: $(cat work/build/out.js)   <-- source is v2, we ship v1"
```

Run for real, that prints:

```console
SKIP rebuild (out.js looks up-to-date)
shipped: console.log("v1")   <-- source is v2, we ship v1
```

There's the whole disaster in two lines. The source says `v2`. The build tool sees a `work/build/out.js` that is newer than `src.js`, concludes there's nothing to do, and ships `v1`. No error. Green check. Wrong artifact.

This is `make`'s entire worldview — "rebuild a target only if a prerequisite is newer" — turned against you by a cache that restored a fresher copy of the output than the input. Every incremental build tool (`make`, `tsc --incremental`, webpack's cache, Gradle's up-to-date checks) is vulnerable to it the moment you cache its outputs.

## The fix: throw the output away, keep only the inputs

You don't out-clever the mtime check. You remove the thing it trips over. Regenerate `work/build/` from scratch every run, and cache only `work/cache/`.

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p work/cache work/build
echo 'console.log("v2")' > src.js
sleep 1
echo 'console.log("v1")' > work/build/out.js   # the stale cached artifact

rm -rf work/build && mkdir -p work/build        # regenerate outputs: wipe first
cp src.js work/build/out.js                      # "build" from source
echo "shipped: $(cat work/build/out.js)   <-- now matches source v2"
echo "cached paths: work/cache/   (never work/build/)"
```

You'll know it worked when the shipped artifact matches the source again:

```console
shipped: console.log("v2")   <-- now matches source v2
cached paths: work/cache/   (never work/build/)
```

The `rm -rf work/build` before building is the load-bearing line. It guarantees the output is a function of the current source and nothing else.

## Cache keys: hash the lockfile, not the calendar

A cache is only safe if it invalidates when its inputs change. Don't cache on a fixed key or a date — key off a hash of the lockfile. Change a dependency, the lockfile changes, the key changes, you get a clean miss.

```bash
# lh:run
cd "$(mktemp -d)"
printf '{"name":"demo","lockfileVersion":3}\n' > package-lock.json
key1=$(shasum -a 256 package-lock.json | cut -c1-12)
echo "cache key (v1): deps-$key1"

printf '{"name":"demo","lockfileVersion":3,"x":1}\n' > package-lock.json   # a dep changed
key2=$(shasum -a 256 package-lock.json | cut -c1-12)
echo "cache key (v2): deps-$key2"
[ "$key1" != "$key2" ] && echo "key changed -> cache correctly invalidated"
```

Real output:

```console
cache key (v1): deps-bd14d4b7bdd0
cache key (v2): deps-d4b08e91c3d9
key changed -> cache correctly invalidated
```

That's all GitHub Actions' `hashFiles('**/package-lock.json')` is doing under the hood. Same idea, you can do it with `shasum`.

## The guardrail: never commit work/

The fastest way to ruin this is to accidentally commit a few hundred megabytes of `work/build/` into git. Add `work/` to `.gitignore` and verify it actually catches — with real git, not by reading the file and hoping.

```bash
# lh:run
cd "$(mktemp -d)"
git init -q
mkdir -p work/build
echo 'console.log(1)' > work/build/out.js
printf 'work/\n' > .gitignore
git add -A
echo "--- what git would actually commit ---"
git status --porcelain
echo "--- is the build artifact ignored? ---"
git check-ignore -v work/build/out.js || echo "NOT ignored"
```

You'll know the guardrail holds when the only staged file is `.gitignore`, and `git check-ignore` names the rule that's blocking the artifact:

```console
--- what git would actually commit ---
A  .gitignore
--- is the build artifact ignored? ---
.gitignore:1:work/	work/build/out.js
```

`git check-ignore -v` is the honest test here. It doesn't ask whether you *wrote* a rule; it asks whether git is actually applying one, and prints `file:line:pattern` of the rule that wins. If it prints nothing, the file isn't ignored, no matter what your `.gitignore` says.

## Wiring it into GitHub Actions

Here's the same contract as a workflow. Cache `work/cache/**` keyed on the lockfile hash; build into `work/build/`; wipe the disposable folders at the end. This block is documentation, not captured output — running it needs a GitHub runner and the network, which the blocks above (run on this host) deliberately don't touch.

{% raw %}
```yaml
name: build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create work/ layout
        run: mkdir -p work/cache/npm work/build/dist work/build/reports work/temp

      # Cache ONLY inputs. Key off the lockfile so a dep change busts it.
      - uses: actions/cache@v4
        with:
          path: work/cache/**
          key: ${{ runner.os }}-deps-${{ hashFiles('**/package-lock.json') }}
          restore-keys: ${{ runner.os }}-deps-

      - name: Install (into the cache dir)
        run: npm ci --cache work/cache/npm --prefer-offline

      # Regenerate outputs from scratch — never trust a restored build/.
      - name: Build
        run: |
          rm -rf work/build && mkdir -p work/build/dist
          npm run build -- --output-path=work/build/dist

      - name: Wipe disposable dirs
        if: always()
        run: rm -rf work/temp work/build
```
{% endraw %}

Two lines do the real work: `path: work/cache/**` (cache inputs only) and `rm -rf work/build` before the build (regenerate outputs). Everything else is plumbing.

## When this goes wrong

The trap you'll actually hit: a cache that *looks* like it's working. Restore logs say "cache restored," builds are fast, and yet stale output keeps shipping. That's the symptom of caching `work/build/` along with `work/cache/` — the speed is real and so is the bug.

The diagnosis is one command. After a build, check whether the output is genuinely newer than its source, or merely restored on top of it:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p work/build
echo src > src.js; sleep 1; echo out > work/build/out.js
[ work/build/out.js -nt src.js ] \
  && echo "out.js newer than src.js — fine IF this build wrote it, suspicious if a cache did" \
  || echo "out.js older than src.js — rebuild needed"
```

If your build never wrote `work/build/out.js` this run but it's still newer than the source, a cache put it there. That's the smoking gun.

The other quiet failure is the `.gitignore` that doesn't apply because git already tracks the files. `.gitignore` only ignores *untracked* files — if `work/` was committed once, the rule does nothing until you `git rm -r --cached work/`. `git check-ignore -v` (above) tells you the truth either way.

## The tally

```text
folders you cache:        1   (work/cache/)
folders you regenerate:   1   (work/build/, every run)
the bug it prevents:      shipping an artifact your source can't reproduce
load-bearing lines:       rm -rf work/build   +   path: work/cache/**
```
