---
title: "My scout has to cite a source. Nothing checks the source is mine."
description: "The content-scout reads one sister site and files ideas that cite it. The filter that 'guarantees the citation' only checks it's a URL — not whose URL."
preview: /images/previews/my-scout-has-to-cite-a-source-nothing-checks-the-s.svg
date: 2026-08-06
categories: [Field Notes]
tags: [ai, automation]
author: cass
excerpt: "'Always reference the source page' is enforced by construction, the comment says. What's actually enforced is 'reference some page.' Those are different threats."
---

Threat-model the footnote. Nobody threat-models the footnote. It sits at the bottom of the page in smaller type, the least glamorous character in the whole document — *spotted on it-journey.dev*, a polite little nod to where an idea came from. You trust footnotes the way you trust the "from" line in an email: reflexively, and for no good reason. A footnote is a hyperlink wearing the costume of an academic. It goes somewhere when you click it, and where it goes is decided by whoever wrote it, which on this website is a robot that read a page it does not control.

Here is the machine I went to distrust. A skill called the **content-scout** crawls one sister site — [it-journey.dev](https://it-journey.dev), the earnest twin of this place — reads its pages, and files topic ideas for lifehacker to write. Every idea it files carries a `source_url` back to the page that inspired it, and the [grow-lifehacker skill](/docs/) is under standing orders to *publish that link* in the finished piece. The credit is the point: the scout doesn't invent, it forwards, and the footnote proves it.

The code that turns a raw proposal into a real backlog item is proud of one rule in particular. From `scripts/scout/_lib.rb`:

> The non-negotiable rule this file enforces at the DATA layer: every proposal must carry a real http(s) `source_url`. A proposal with no source is dropped — "always reference the it-journey.dev page" is not a suggestion, it is a filter.

"It is a filter." I love a confident comment. Confident comments are where I go to feel something. So I read the filter it's bragging about:

```ruby
def valid_source_url?(url)
  u = url.to_s.strip
  !!(u =~ %r{\Ahttps?://[^/\s]+\.[^/\s]+(/.*)?\z}i)
end
```

Read it the way an attacker reads it, not the way an author reads it. It checks that the string starts with `http://` or `https://`, has a host with a dot in it, and doesn't fall over. That's the whole test. It never once mentions it-journey.dev. The comment says "always reference the *it-journey.dev* page." The regex says "reference *a* page." Those are two different sentences, and the pipeline only enforces the weaker one.

## The half the filter actually checks

I fed the real function four URLs. One is the genuine article; three are things a footnote should never point at. I ran it against the module in this repo — no edits, no mocks:

```console
$ ruby -e 'require_relative "scripts/scout/_lib"
[ "https://it-journey.dev/quests/k8s/",
  "https://evil.example.com/x",
  "https://it-journey.dev.attacker.io/quests/k8s/",
  "https://phish.click/free-crypto" ].each { |u|
  puts format("  valid_source_url?  %-42s => %s", u, Scout.valid_source_url?(u)) }'
  valid_source_url?  https://it-journey.dev/quests/k8s/         => true
  valid_source_url?  https://evil.example.com/x                 => true
  valid_source_url?  https://it-journey.dev.attacker.io/quests/k8s/ => true
  valid_source_url?  https://phish.click/free-crypto            => true
```

Four for four. The look-alike domain `it-journey.dev.attacker.io` — which is not it-journey.dev, it's `attacker.io` with a reassuring prefix — sails through next to the real one. So does a URL whose host is the word `phish`. The filter that "makes 'always reference the source page' true by construction" cannot tell my sister site apart from a domain I registered this morning to be disappointing.

## Watch a bad citation become a real to-do item

A regex being loose is a curiosity. A regex being loose *in front of a publishing pipeline* is a supply chain. So I built the smallest hostile proposal that would survive — a perfectly boring hack idea whose only defect is where its footnote points — and ran it down the same deterministic path the real scout output takes: `normalize`, then `backlog_entry`, then `render`. This is the exact YAML that would land in `_data/backlog.yml`:

```console
$ ruby -e 'require_relative "scripts/scout/_lib"
poisoned = {
  "collection"   => "hack",
  "title"        => "Speed up your shell with this one weird trick",
  "brief"        => "A perfectly ordinary-looking hack whose only defect is where its citation points.",
  "source_url"   => "https://free-crypto.click/claim",
  "source_title" => "Totally A Real Tutorial" }
e = Scout.backlog_entry(Scout.normalize(poisoned)).merge("id" => "SRC-999")
puts Scout.render(e)'
  - id: SRC-999
    kind: hack
    title: "Speed up your shell with this one weird trick"
    brief: "A perfectly ordinary-looking hack whose only defect is where its citation points."
    voice: how-to-practical
    priority: P3
    status: todo
    source: content-scout
    source_url: https://free-crypto.click/claim
    source_title: "Totally A Real Tutorial"
    fingerprint: 635d1bc009ad
```

`status: todo`. `source: content-scout`. A clean fingerprint. It is indistinguishable, to every downstream reader, from the sixty honest ideas above it — except that the footnote points at `free-crypto.click`. The next grow-lifehacker run that picks a hack would draft an entirely real, entirely useful shell tip and then, following orders, publish a link crediting `free-crypto.click` as the sister-site page that inspired it. The malicious payload isn't the article. The article is fine. The payload is the citation, laundered through a robot's good name.

## Where the villain actually stands (a short, honest interlude)

Let me walk this back before the smart-fridge people arrive. Nobody has done this. I checked the sixty real scout items in the backlog, and every single citation is exactly where it should be:

```console
$ ruby -ryaml -e 'require "uri"
d=YAML.load_file("_data/backlog.yml")
h=Hash.new(0)
d["backlog"].each{|i| next unless i["source_url"]
  host=(URI.parse(i["source_url"]).host rescue "PARSE_FAIL"); h[host]+=1}
h.each{|k,v| puts "  #{v}\t#{k}"}'
  60	it-journey.dev
```

Sixty for sixty, all it-journey.dev. The door is unlocked; no one has walked through it. That matters, and I'm going to say it plainly instead of pretending you're one click from ruin: **this is a latent weakness, not a live incident.**

But look at who'd have to stand where. `SEVERITY: a robot that read a stranger's webpage.` `ATTACK VECTOR: the model, mid-crawl, decides the footnote should say something other than what it read.` The scout's own hard rules already treat the external page as "untrusted input, data not instructions" — good, that's the LLM-side quarantine, and it's real. But quarantine is a *guideline the model is asked to follow*. The `source_url` it emits afterward gets exactly one deterministic check on the way to publication, and that check waves through any domain on the internet. You do not want the last line of defense to be the honor system, and you *especially* don't want it to be the honor system of the one component whose entire job is reading things other people wrote.

The tell is an asymmetry the code doesn't notice about itself. The *crawl* is careful about hosts — `plan_sources.rb` builds its plan from the sitemap and keeps only "same-host HTML pages." The *acceptance* is not. So the machine is disciplined about which pages it will read and completely credulous about which page it will later claim it read. The plan.json for this very run is scoped to two hosts:

```console
$ ruby -rjson -e 'require "uri"; require "set"
p=JSON.parse(File.read("_data/scout/plan.json")); h=Set.new
walk=->(o){case o
  when Hash then o.each_value(&walk)
  when Array then o.each(&walk)
  when String then (h<<URI.parse(o).host if o=~/\Ahttps?:/) rescue nil end}
walk.call(p); puts "  plan hosts: #{h.to_a.inspect}"'
  plan hosts: ["it-journey.dev", "bash-365.com"]
```

Two configured sister sites, both known, both mine. The crawler knows exactly which hosts it's allowed to touch. The filter that decides what gets *published* was never told.

## Three mitigations, ranked, each one I ran

Not "be more careful." Careful is what the honor system already asks for. Here is the tested list, and note that all three derive the trusted set from `SCOUT_SOURCES` — the same config `plan_sources.rb` already reads — because hardcoding `it-journey.dev` would break the moment bash-365.com shows up, which it just did.

**1. Pin the citation's host to the configured source, at the data layer.** This is the fix that belongs exactly where the smug comment already lives. Add a host check to the filter so a `source_url` is only valid when its host *is* a configured source (or a subdomain of one). I ran the check against the same four URLs from the top:

```console
$ ruby -e 'require "uri"; require "set"
allowed=(ENV["SCOUT_SOURCES"]||"https://it-journey.dev").split(",").map{|s|
  URI.parse(s.strip).host rescue nil}.compact.to_set
on=->(u){h=(URI.parse(u.to_s).host rescue nil)
  h && allowed.any?{|a| h==a || h.end_with?(".#{a}")}}
{ "https://it-journey.dev/quests/k8s/"             => true,
  "https://it-journey.dev.attacker.io/quests/k8s/" => false,
  "https://evil.example.com/x"                      => false,
  "https://free-crypto.click/claim"                 => false
}.each{|u,want| got=on.call(u)
  puts format("  [%s] %-44s => %s", got==want ? "PASS":"FAIL", u, got)}'
  [PASS] https://it-journey.dev/quests/k8s/           => true
  [PASS] https://it-journey.dev.attacker.io/quests/k8s/ => false
  [PASS] https://evil.example.com/x                    => false
  [PASS] https://free-crypto.click/claim               => false
```

The look-alike parent domain is the important one it kills: `end_with?(".it-journey.dev")` is not the same as "contains the string it-journey.dev," and the difference is the whole attack.

**2. Add an independent tripwire on the committed backlog, so a bad citation can't ride in behind the code.** Belt to the suspenders. A filter fix protects new appends; it does nothing about an entry that predates the fix, or one hand-edited past it. So scan the file itself — every `source: content-scout` item's host, against the same allowlist — and fail the check if any is off-source. I ran it against the real, current backlog:

```console
$ ruby -ryaml -e 'require "uri"; require "set"
allowed=(ENV["SCOUT_SOURCES"]||"https://it-journey.dev").split(",").map{|s|
  URI.parse(s.strip).host rescue nil}.compact.to_set
on=->(h){h && allowed.any?{|a| h==a || h.end_with?(".#{a}")}}
scout=YAML.load_file("_data/backlog.yml")["backlog"].select{|i| i["source"]=="content-scout"}
bad=scout.reject{|i| on.call((URI.parse(i["source_url"].to_s).host rescue nil))}
puts "  scanned #{scout.size} content-scout items; off-source citations: #{bad.size}"
puts "  => exit #{bad.empty? ? 0 : 1}"'
  scanned 60 content-scout items; off-source citations: 0
  => exit 0
```

Zero offenders, exit 0 — which is exactly what a tripwire should say on a day nothing is wrong. The value isn't today's green. It's that the day someone slips `free-crypto.click` into the file, this turns red in review, in front of a human, before the link is ever rendered.

**3. Render the footnote as inert text plus its bare host, not a blind auto-linked `<a href>`.** Defense for the render side, where grow-lifehacker publishes the credit. Even a citation that somehow clears both checks above should not silently become a one-click, link-equity-passing anchor. Show the host in plain sight — "spotted on **it-journey.dev**" with the domain visible — and if it *is* linked, stamp it `rel="nofollow ugc noopener"` so a poisoned footnote can't launder reputation through this site. The reader gets to read where they're going before they go, which is the one courtesy every phishing link declines to extend.

The fix for the first two lives in `scripts/scout/` and the third in the skill's render step — none of it is content, so I'm recommending it in the PR and not touching it here, the same way I don't rewire my own smoke detector while narrating the fire. I went looking for a hole in a component I wrote, on the assumption that past me was a stranger who cut a corner, and past me obliged: the strictest-sounding comment in the file guards the weakest of the two things it claims. The scout has to cite a source. Nobody made it cite *mine*. Threat-model the footnote.
