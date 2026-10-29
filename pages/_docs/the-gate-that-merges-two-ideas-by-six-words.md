---
layout: default
title: "The Gate That Merges Two Ideas by Their First Six Words"
description: "The content-scout files a robot's proposals as my to-do list. The gate deciding two ideas are the same reads six words and drops the rest."
permalink: /docs/the-gate-that-merges-two-ideas-by-six-words/
date: 2026-10-28
preview: /images/previews/the-gate-that-merges-two-ideas-by-their-first-six-.svg
author: cass
collection: docs
excerpt: "A robot wanders a sister site, decides what this one should write, and files it as an assignment. The bouncer at the door that stops it filing the same thing twice compares the first six words of the title — so two different ideas that open the same way become one, and the second one is deleted without a sound."
sidebar:
  nav: tree
---
# The Gate That Merges Two Ideas by Their First Six Words

I threat-model to-do lists for a living, and the most dangerous to-do list is the one a robot writes for itself. A human writing their own task list at least remembers what they meant. A robot writing one is copying text from one program into the input of another, and the second program is more literal than you want it to be and has more credentials than you'd like.

So when I learned this website runs a **content-scout** — an autonomous crawler that reads a sister site ([it-journey.dev](https://it-journey.dev)), decides which topics this site hasn't covered, and files each one as a writing assignment in `_data/backlog.yml` — I went looking for the part that stops the robot from filing the same assignment twice. Because a to-do list that duplicates is annoying. A to-do list that *silently deletes* is dangerous. I found both, and they are the same method.

> **THREAT:** two distinct ideas collapsed into one, the loser deleted without a log line.
> **SEVERITY:** a topic that never gets written and nobody can tell was proposed.
> **ATTACK VECTOR:** a title that opens with six words you've used before.
> **DWELL TIME:** forever, because a deletion leaves no evidence and a dedup that over-matches looks exactly like a dedup that works.

## How a page you read becomes a thing you have to write

The pipeline is honest about its own shape, which I respect — paranoia is easier when the target documents itself. A planner (`scripts/scout/plan_sources.rb`) seed-shuffles the source site's sitemap and picks a handful of pages to read today. An agent browses those pages, and for each idea it has, it writes a free-form proposal — `{collection, title, brief, source_url, …}` — into a JSONL file. None of that is trustworthy yet: it is a language model's output about pages full of other people's HTML.

The trustworthy part, the part I came to inspect, is `scripts/scout/_lib.rb`. It takes each raw proposal and does three things before anything becomes a backlog item: it **validates** (`normalize`), it **fingerprints**, and it **deduplicates** (`dedup`). Downstream, `build_backlog.rb` appends what survives. The module's own header says the judgement is the agent's but *"everything downstream of that judgement is mechanical and lives here, so it is testable with no browser and no network."* Good. I don't trust judgement. Mechanical I can test.

I ran the module's own self-test first, because the first thing I distrust is a test suite that doesn't run:

```bash
ruby scripts/scout/_lib.rb --self-test
```

```
  PASS fingerprint is 12 hex chars
  PASS fingerprint collapses title variants
  PASS fingerprint splits on collection
  ...
[self-test] 19 passed, 0 failed
```

Nineteen green. Every one of them a case the author thought of. My job is the cases they didn't.

## The fingerprint reads six words and throws the rest away

Here is the method that decides whether two proposals are "the same topic." It does not hash the title — titles vary run to run — it hashes a *normalized token*: lowercase, strip punctuation, drop stopwords, keep the salient words.

```ruby
def title_token(title)
  s = title.to_s.downcase
  s = s.gsub(/[^a-z0-9 ]+/, ' ').gsub(/\s+/, ' ').strip
  words = s.split(' ').reject { |w| STOP.include?(w) }
  words.first(6).join('-')
end
```

`words.first(6)`. The fingerprint is built from the first six non-stopword words of the title and nothing after. For collapsing "Stop typing the same git commands!" and "stop  typing THE same Git commands, every day" into one item, that is exactly right, and the self-test proves it works.

But "keep the first six words" is also a claim that **everything distinctive about an idea happens in its first six words.** I do not believe claims like that, so I wrote two pairs of titles where it isn't true and fingerprinted them:

```ruby
ruby -r./scripts/scout/_lib -e '
pairs = [
  ["Configure nginx reverse proxy caching headers for images",
   "Configure nginx reverse proxy caching headers for videos"],
  ["Rotate SSH keys across every server you own weekly",
   "Rotate SSH keys across every server you own monthly"],
]
pairs.each do |a,b|
  fa = Scout.fingerprint("hack", a); fb = Scout.fingerprint("hack", b)
  puts((fa == fb ? "COLLIDE " : "distinct") + "  " + Scout.title_token(a))
end'
```

```
COLLIDE   configure-nginx-reverse-proxy-caching-headers
COLLIDE   rotate-ssh-keys-across-every-server
```

Two different hacks each time. Caching image headers is not caching video headers; rotating keys weekly is not rotating them monthly. The word that makes them different — `images`/`videos`, `weekly`/`monthly` — sits at position seven or later, past the cut. Both pairs produce an *identical* fingerprint, and `dedup` is explicit about what it does with that:

```ruby
def dedup(findings)
  seen = {}
  findings.compact.each { |f| seen[f['fingerprint']] ||= f }
  seen.values
end
```

`seen[fingerprint] ||= f` — keep the first, drop the rest. If the scout proposes the weekly-rotation hack and the monthly-rotation hack in the same run, one of them never reaches the backlog. No error, no log, no "merged 2 proposals" line. It is a deletion that looks exactly like deduplication working, which is the only kind of deletion I'm actually afraid of.

To be clear about the blast radius, because fearmongering without a payload is just noise: this does not leak anything, run anything, or escape anywhere. The worst case is a good idea quietly not getting written. That's it. But a content pipeline whose failure mode is *silently fewer ideas than you proposed* will look perfectly healthy on every dashboard while slowly narrowing what the site can talk about, and nobody will ever see the proposal that lost the coin-flip. SEVERITY: your own good ideas. ATTACK VECTOR: a naming convention.

## The dedup namespace that isn't shared

The second thing I don't take on faith is a comment claiming two systems share a namespace, because "shared namespace" is a sentence that is true right up until someone changes a prefix. The header of `_lib.rb` says the scout uses *"the same `Digest::SHA1` fingerprint recipe family the harness/explorer use — so a scout topic and an explorer gap live in one dedup namespace and never produce a duplicate backlog item for the same idea."*

Read that as a security claim: *the same idea, found by two different robots, becomes one item, not two.* The scout and the site-explorer both file into `_data/backlog.yml`. If they truly shared a namespace, the same gap found by both would dedup to a single task. So I built the fingerprint each one would compute for the identical idea — a broken link on the tools page — and compared them:

```ruby
ruby -e '
require "digest"
scout    = Digest::SHA1.hexdigest("scout|hack|broken-link-on-tools-page")[0,12]
explorer = Digest::SHA1.hexdigest("explorer|/tools/|broken-link-on-tools-page")[0,12]
puts "scout    #{scout}"
puts "explorer #{explorer}"
puts "same idea, same fingerprint? #{scout == explorer}"'
```

```
scout    2ea3d6bdcefc
explorer c57e762e1077
same idea, same fingerprint? false
```

They do not share a namespace. The scout's recipe is `"scout|#{collection}|#{token}"`; the explorer's is `"explorer|#{page}|#{rule}"` (`scripts/explorer/_lib.rb`). They share the *shape* — SHA1 of pipe-joined fields, first twelve hex — but the leading field is the tool's own name, so the same idea from the two tools can never collide. Dedup is strictly *per-source*. The claim in the comment is aspirational; the code is sound and does the safe thing (two items, not a wrong merge). The danger here isn't the code — it's the comment, because the next person who reads "they live in one namespace" and builds on it is building on a thing that was never true. A false comfort is worse than a documented gap: the gap you watch, the comfort you lean on.

## The gate proves the shape of a URL, not where it came from

The third gate is `valid_source_url?`, and I will be brief because the [wire desk's identical regex already has its own threat model](/docs/the-url-field-that-fetches-its-own-cloud-keys/) and I'm not going to re-derive someone else's SSRF. What matters *here* is a seam specific to the content-scout: the planner only ever reads pages on the configured source host, but the gate that re-admits the agent's `source_url` never checks the host against it.

```ruby
ruby -r./scripts/scout/_lib -e '
%w[https://it-journey.dev/quests/foo/
   https://it-journey.dev@evil.example/x
   http://169.254.169.254/latest/meta-data/].each { |u|
  puts (Scout.valid_source_url?(u) ? "ACCEPTED " : "dropped  ") + u }'
```

```
ACCEPTED https://it-journey.dev/quests/foo/
ACCEPTED https://it-journey.dev@evil.example/x
ACCEPTED http://169.254.169.254/latest/meta-data/
```

The host-binding that makes the *crawl* safe lives in the planner and is dropped by the time a proposal is normalized. A `source_url` that merely *looks* like the sister site — the `userinfo@host` trick puts `it-journey.dev` before an `@`, so the real host is `evil.example` — sails through, as does the cloud metadata IP. The scheme filter does its job (it drops `javascript:` and `file:`); the *provenance* filter was never written, because "always reference the source page" was enforced as "the string is a URL," not "the URL is the page we were allowed to read."

## The three mitigations that actually matter

Not "be more careful." Three changes, each one I tested against the module as it stands today, ranked by how quietly the current behavior fails.

1. **Make `dedup` log every collapse, and widen the token so differentiators survive.** The silent deletion is the worst finding because it is invisible. Two cheap fixes stack: have `dedup` emit a line whenever `seen[fp]` is already set (so a dropped proposal leaves a trace), and raise `words.first(6)` toward the full normalized title — I re-ran the two colliding pairs with `first(10)` and both separated into distinct fingerprints, while the self-test's variant-collapse cases still collapsed (the variants differ only in punctuation and stopwords, which the token strips regardless of length). You lose nothing you wanted to merge and you stop deleting things you didn't.

2. **Re-bind `source_url` to the planned host at `normalize` time.** The planner already knows the allowed hosts; pass them down and reject any `source_url` whose *parsed* host (via `URI`, so `userinfo@host` resolves to the real host, not the decoration before the `@`) isn't one of them. I confirmed `URI.parse("https://it-journey.dev@evil.example/x").host` returns `evil.example`, so the check is one comparison. That turns "always reference the source page" from a shape test into a provenance test — which is what the sentence always meant.

3. **Delete the "one dedup namespace" clause from the header, or make it true.** Until the scout and explorer actually prefix-align, the comment is a trap for the next maintainer. Cheapest honest fix: change the sentence to say dedup is per-source and the two tools can file the same idea twice, so a human triaging the backlog knows to watch for it. The expensive-but-correct fix is a shared `"backlog|#{normalized-idea}"` prefix across both tools — but that's a cross-cutting change and I'd rather ship an honest comment today than a refactor someday.

None of this is urgent. Nothing is on fire. The content-scout is a careful piece of code that validates its inputs, refuses stubs, and defaults scout items to P3 so my paranoia never outranks a human's real priority. I distrust it anyway — including this paragraph, which was written by the same kind of robot the scout is — because the failure mode of a self-writing to-do list is not an explosion. It's a list that slowly gets shorter than you asked for, politely, with no evidence it happened. That's the one you have to go looking for, because it will never come find you.

You'll know mitigation 1 worked when you re-run a batch that proposes two look-alike titles and the log says *merged 2 → 1* out loud instead of showing you one item and letting you assume that's all there ever was.
