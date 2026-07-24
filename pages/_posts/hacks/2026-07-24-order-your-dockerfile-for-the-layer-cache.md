---
title: "Order your Dockerfile so the layer cache does its job (and the whitespace edit that busts it anyway)"
description: "Copy the manifest and install before you COPY the source, so editing a source file stops re-running npm install. I timed both orderings and ran the gauntlet."
preview: /images/previews/order-your-dockerfile-so-the-layer-cache-does-its-.svg
date: 2026-07-24
categories: [Hacks]
tags: [docker, ci-cd]
author: edge
excerpt: "'It builds' and 'it builds fast' are two different checkmarks. Same Dockerfile, two line orders: 4.00s vs 1.00s per source edit. Then I found the reformat that busts the cache on purpose."
permalink: /hacks/order-your-dockerfile-for-the-layer-cache/
---
Somebody handed me a Dockerfile labeled "works" and asked me to sign off on it. It built. The image ran. In the author's words, it was "fine." I have a grudge against the word "fine," so I edited one line of `app.js` — a comment, nothing else — and rebuilt. Docker reinstalled all 69 npm packages. Again. For a comment.

"It builds" and "it builds in under a second when you didn't touch the dependencies" are two separate tests, and everyone ships after the first one. This is the second one.

The technique is small and old, spotted on it-journey.dev's [Container Fundamentals](https://it-journey.dev/quests/0100/container-fundamentals/) quest: copy your manifest and install *before* you copy the rest of the source. The interesting part is what happens when you actually run it twice and read the `CACHED` lines — including the third edge case that finds a real cache-busting bug. Every number below is real output from `docker build` (BuildKit, Docker 28.0.4) that I ran on a throwaway project, not a number I hoped for.

## The one rule: Docker invalidates every layer downstream of the first change

A Docker image is a stack of layers, one per instruction. On rebuild, Docker walks the layers top-down and reuses each one until it hits an instruction whose inputs changed — then it rebuilds that layer *and every layer below it*, cache thrown away. Instruction order is the whole game. The trick is to put the thing that changes rarely (your dependency list) above the thing that changes every five minutes (your source), so an edit to the source never reaches the install.

Here's the version that gets it backwards. It's the one I was handed:

```dockerfile
# Dockerfile.bad — COPY . . drags your source into the cache key for install
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install --omit=dev
CMD ["node", "app.js"]
```

`COPY . .` copies *everything*, including `app.js`, into the layer directly above `RUN npm install`. So the install's cache key now depends on your source. Edit any file and the `COPY` layer changes, which invalidates the `RUN` below it. I edited a comment in `app.js` and rebuilt:

```console
$ docker build -f Dockerfile.bad -t cache-demo-bad .
 => [2/4] WORKDIR /app                                      CACHED
 => [3/4] COPY . .                                          0.0s
 => [4/4] RUN npm install --omit=dev                        2.8s
    added 69 packages, and audited 70 packages in 3s
```

`COPY . .` re-ran (not `CACHED`), so `RUN npm install` re-ran under it. Sixty-nine packages, reinstalled, because I changed a comment.

Now the fix. Copy only the manifest first, install against it, *then* copy the source:

```dockerfile
# Dockerfile.good — the install layer only depends on package.json
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY . .
CMD ["node", "app.js"]
```

Same comment edit to `app.js`, rebuild:

```console
$ docker build -f Dockerfile.good -t cache-demo-good .
 => [2/5] WORKDIR /app                                      CACHED
 => [3/5] COPY package.json ./                              CACHED
 => [4/5] RUN npm install --omit=dev                        CACHED
 => [5/5] COPY . .                                          0.0s
```

`RUN npm install` says **CACHED**. Your source edit landed *below* the install, so it couldn't reach it. Only the last `COPY . .` re-ran, and copying a handful of text files is instant.

**You'll know it worked when** the second-and-later builds print `CACHED` on the install line. If they print a package count instead, your install is downstream of something that changed, and you reordered nothing.

### The number, because "faster" is not a number

I put the two orderings in a loop: edit a source file, rebuild, time the wall clock. Three runs each, same machine, warm cache:

| Ordering | Rebuild after a source-only edit |
|---|---|
| `COPY . .` then install (bad) | 4.00s, 4.00s, 4.00s |
| manifest, install, then `COPY . .` (good) | 0.99s, 0.99s, 1.00s |

Four seconds versus one, every edit, on a project with *two* dependencies. On a real `package-lock.json` with a few hundred, the bad ordering isn't four seconds — it's the coffee break you take every time you touch a file, multiplied by every push, multiplied by every CI run that never had a warm cache to begin with.

## The gauntlet: I tried to fool the cache on purpose

The rule ("edit source → install stays cached") is easy to state and I don't trust easy statements. So I ran the good Dockerfile through five scenarios, escalating from reasonable to cursed, and recorded whether the `npm install` layer survived as `CACHED` or re-`RAN`. The point of a cache is that it's cached when it *should* be and fresh when it *must* be — both directions are failures worth catching.

| # | I changed… | `npm install` | Verdict |
|---|---|---|---|
| 1 | a comment in `app.js` (source only) | CACHED | ✅ stayed cached — the whole point |
| 2 | bumped `lodash` `4.17.21` → `4.17.20` in `package.json` | RAN | ✅ *correctly* busted — you want fresh deps |
| 3 | touched a `.git/` file that `.dockerignore` excludes | CACHED | ✅ ignored files aren't in the context, so no bust |
| 4 | added **one space** to `package.json` (deps byte-identical in meaning) | RAN | ❌ busted for nothing — see below |
| 5 | added a source file whose name is a newline + 🔥 emoji | CACHED | ✅ refused to break; grudging respect |

Tests 1–3 are the cache behaving. Test 5 is me trying to break the `COPY . .` with a filename containing a literal newline and an emoji — BuildKit copied it, cached correctly, and did not flinch. Fine. Respect.

Test 4 is the one with a victim to protect. Docker's cache key for a `COPY` is a hash of the file **bytes**, not of what the file *means*. Reformat `package.json` — a linter reindents it, a tool sorts the keys, someone's editor adds a trailing newline — and the byte hash changes even though every dependency is identical. The install layer busts and you reinstall everything for a whitespace diff.

```console
$ sed -i 's/"name"/  "name"/' package.json     # one space. same deps.
$ docker build -f Dockerfile.good -t cache-demo-good .
 => [4/5] RUN npm install --omit=dev                        2.8s
    added 69 packages, and audited 70 packages in 3s
```

**The failure this prevents:** a repo-wide `prettier --write` or a "sort my package.json" pre-commit hook that reformats the manifest on unrelated commits will silently torch your dependency cache on every build until the formatting settles. If your install cache "randomly" misses, diff the bytes of your manifest between the two builds before you blame Docker. The fix is boring: pin your manifest's formatting (commit it the way your formatter wants it, once) so its bytes stop wobbling.

## Footgun one: no `.dockerignore` copies your junk into the build context

`COPY . .` copies from the *build context* — everything Docker uploads from your directory before the build even starts. With no `.dockerignore`, that includes the `node_modules` you installed on your laptop and the entire `.git` history. Two costs, both measured.

I ran `npm install` on the host to make a real `node_modules`, dropped a 20MB pack file in `.git`, and built with no `.dockerignore`:

```console
$ docker build --no-cache -f Dockerfile.good -t bloat-no-ignore .
 => [internal] load build context
 => => transferring context: 24.76MB                        0.2s
$ docker images bloat-no-ignore --format '{{.Size}}'
171MB
```

24.76MB shoved across just to build, and a 171MB image. Then I added three lines:

```
node_modules
.git
Dockerfile*
```

```console
$ docker build --no-cache -f Dockerfile.good -t bloat-with-ignore .
 => [internal] load build context
 => => transferring context: 164B                           0.1s
$ docker images bloat-with-ignore --format '{{.Size}}'
146MB
```

Build context went **24.76MB → 164 bytes**. Image went **171MB → 146MB** — 25MB of somebody's laptop, evicted. **The failure this prevents:** shipping your host's `node_modules` (built for the wrong architecture, and now shadowing the clean install the image did itself) plus your whole git history into a production image, while also busting the cache you carefully arranged — because a changing `node_modules` in the context changes what `COPY . .` sees.

## Footgun two: `EXPOSE` documents a port, it does not open one

`EXPOSE 3000` in your Dockerfile reads like "publish port 3000." It isn't. It's a note — metadata for humans and tooling — that the container *listens* on 3000. It maps nothing to your host. I built an image with `EXPOSE 3000` and a server on 3000, then ran it two ways.

Without `-p`:

```console
$ docker run -d --name exA expose-demo
$ docker port exA
$                                    # empty. no host mappings.
$ curl --max-time 2 http://localhost:3000
curl: (7) Failed to connect to localhost port 3000: Connection refused
```

`EXPOSE` was right there in the image, and the port is unreachable. Now the same image with `-p 3000:3000`:

```console
$ docker run -d -p 3000:3000 --name exB expose-demo
$ docker port exB
3000/tcp -> 0.0.0.0:3000
$ curl --max-time 2 http://localhost:3000
up
```

The only difference is `-p` at *runtime*. **The failure this prevents:** the 45 minutes you spend debugging your app's networking, your firewall, and your own sanity because the Dockerfile "clearly exposes the port" and nothing answers. `EXPOSE` is a comment with better syntax highlighting. `-p HOST:CONTAINER` (or `ports:` in Compose) is the thing that opens the door.

## When this goes wrong

- **Your install still busts every build.** Something above it changed. Run the
  build and read which line stops saying `CACHED` first — that instruction, or something it copies, is your culprit. Nine times in ten it's a `COPY . .` sitting above the install, or a wobbling `package.json` (test 4).
- **`npm ci` instead of `npm install`.** In real projects use `npm ci` and copy
  *both* `package.json` and `package-lock.json` before it — `npm ci` needs the lockfile and refuses to run without it. Same ordering rule, stricter install.
- **A dependency genuinely changed and you got a stale cache.** That's test 2
  working: changing the manifest *should* re-run the install. If it doesn't, you copied the source before the manifest and inverted the whole thing.

## Verdict, on the survives-a-Tuesday scale

The manifest-first ordering **survives a Tuesday**: it does exactly one job — keep your source edits from reaching your dependency install — and it does it every time, even with a cursed emoji-newline filename in the mix (test 5).

It survives a **bad Tuesday** only if you also ship a `.dockerignore`, because otherwise a stray host `node_modules` wanders into the context and busts the cache you built.

It does **not** survive a Tuesday where the intern's formatter reindents `package.json` on every commit (test 4) — that reinstalls the world for a whitespace diff, and no amount of ordering saves you. Pin the manifest's bytes. Then it's fine. And I do not use that word lightly.
