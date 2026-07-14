# lifehacker-read — test evidence

Verification record for the read-only MCP server. Everything below was **run**,
not described — reproduce it with:

```bash
cd mcp/lifehacker-read && npm install && npm run evidence
```

Captured on Node v25.6.0 · Darwin 25.5.0 · branch `claude/concept-layer`.

## Summary

| Check | Result |
|---|---|
| `tsc` typecheck (server **and** tests) | ✅ pass |
| `tsc` production build | ✅ pass |
| Unit + integration suite | ✅ **57/57 pass** across 13 suites |
| Stdio end-to-end smoke (real subprocess) | ✅ ALL CHECKS PASSED |
| No-write proof (git status before == after) | ✅ the server/tests modified nothing in the repo |
| Guardrails-by-absence (no mutating verb) | ✅ asserted by test **and** smoke |

## What the suite covers

The tests drive the **real** server over an in-memory MCP transport and
cross-check every answer against an **independent** read of the repo (filesystem
counts + a separate YAML/JSON parse), so green means the tools agree with the
files on disk — not merely with themselves.

- **Protocol & capabilities** — 12 tools, 9 resource templates, content discoverable via `resources/list`.
- **Guardrails by absence** — no `create/update/propose/merge/approve/close/set_*` verb exists in the surface (the security invariant).
- **Content model** — `list_collection` counts equal `*.md` on disk for all 5 collections; item roundtrip; date-structured post permalinks; unknown slug → structured error; invalid collection → schema error.
- **search_content** — scored + sorted; collection filter; tag filter; limit.
- **taxonomy** — tag pool internally consistent; `Field Notes` category present.
- **query_backlog** — counts cross-checked against a YAML parse of `_data/backlog.yml` (total + per-status).
- **query_health_queue** — count == `queue.json` length; paging; schema-max rejection; severity filter.
- **brand** — **every** banned-when-sincere word classifies as banned; neutral word ok; per-collection voice mapping; Prime Directive present.
- **concepts (the durable layer)** — `list_concepts` count == `_data/concepts.yml`; **every concept carries ≥1 source** (a concept with no carrier is a claim); `get_concept` by id + unknown-id error; `find_concepts` ranks the relevant concept first; tag filter; the `lifehacker://concepts` resource + a concept template resolve.
- **resources** — every listed resource reads non-empty; findings/scout evidence quarantined; analytics stale-flag surfaced; unknown URI rejected.
- **units** — front-matter parser edge cases; repo-root resolution (valid + bad `LH_REPO_ROOT`).

## Full run log

<details>
<summary>npm run evidence — complete output</summary>

~~~text
============================================================
 lifehacker-read — test evidence
============================================================
node:   v25.6.0
npm:    11.8.0
os:     Darwin 25.5.0
repo:   /Users/bamr87/github/lifehacker.dev/.claude/worktrees/lifehacker-mcp-integration-e6442e
commit: 99d865a on claude/concept-layer

===== no-write proof: repo status BEFORE =====
 M _data/navigation/main.yml
 M mcp/lifehacker-read/README.md
 M mcp/lifehacker-read/src/resources.ts
 M mcp/lifehacker-read/src/server.test.ts
 M mcp/lifehacker-read/src/smoke.ts
 M mcp/lifehacker-read/src/tools.ts
?? _data/concepts.yml
?? concepts.md
?? mcp/lifehacker-read/scripts/analyze-post.ts
?? mcp/lifehacker-read/src/concepts.ts

----- typecheck (tsc, tests included) -----
[typecheck (tsc, tests included)] OK

----- build (production tsc) -----
[build (production tsc)] OK

----- unit + integration suite -----

> lifehacker-read@0.1.0 test
> node --import tsx --test src/server.test.ts src/unit.test.ts

▶ protocol & capabilities
  ✔ exposes exactly the 9 expected read tools (4.869166ms)
  ✔ every tool declares a description (0.867167ms)
  ✔ registers the 9 resource templates (0.901ms)
  ✔ lists the static + enumerated resources (content is discoverable) (75.905042ms)
✔ protocol & capabilities (83.228541ms)
▶ guardrails by absence (the security invariant)
  ✔ NO tool is a mutating verb (0.74325ms)
  ✔ no merge/approve/close/set-switch tool exists (0.391417ms)
✔ guardrails by absence (the security invariant) (1.276875ms)
▶ content model (cross-checked vs files on disk)
  ✔ list_collection(hacks) count == *.md on disk (19.04725ms)
  ✔ list_collection(tools) count == *.md on disk (4.593291ms)
  ✔ list_collection(posts) count == *.md on disk (17.349166ms)
  ✔ list_collection(docs) count == *.md on disk (4.261166ms)
  ✔ list_collection(about) count == *.md on disk (0.582917ms)
  ✔ get_content_item roundtrips a real item and carries a body (10.415792ms)
  ✔ posts permalink is date-structured (17.558792ms)
  ✔ unknown slug returns a structured error, not a throw (0.608958ms)
  ✔ invalid collection is rejected (schema error result, not success) (0.491166ms)
✔ content model (cross-checked vs files on disk) (75.326708ms)
▶ search_content
  ✔ returns scored hits, sorted descending (38.490709ms)
  ✔ collection filter is honored (4.031292ms)
  ✔ tag filter returns only items carrying the tag (63.093375ms)
  ✔ limit is respected (33.481042ms)
✔ search_content (139.260708ms)
▶ taxonomy
  ✔ tags pool is internally consistent (count == members) (31.157458ms)
  ✔ categories include 'Field Notes' (31.509666ms)
✔ taxonomy (62.821209ms)
▶ query_backlog (cross-checked vs _data/backlog.yml)
  ✔ unfiltered count == backlog length on disk (12.500041ms)
  ✔ status:todo count matches independent count (11.9565ms)
  ✔ status:done count matches independent count (12.806959ms)
✔ query_backlog (cross-checked vs _data/backlog.yml) (37.447542ms)
▶ query_health_queue (cross-checked vs _data/health/queue.json)
  ✔ unfiltered count == queue length on disk (count is the full total, not the page) (0.918834ms)
  ✔ limit truncates the item page (0.406291ms)
  ✔ limit above the schema max is rejected (0.26325ms)
  ✔ severity filter is honored (0.628292ms)
✔ query_health_queue (cross-checked vs _data/health/queue.json) (2.321875ms)
▶ brand (cross-checked vs _data/brand/*.yml)
  ✔ get_brand_identity carries the Prime Directive + voice profiles (2.793375ms)
  ✔ EVERY banned-when-sincere word classifies as banned (6.897167ms)
  ✔ a neutral word classifies as ok (0.54ms)
  ✔ voice profile resolves per collection (3.305208ms)
✔ brand (cross-checked vs _data/brand/*.yml) (13.662834ms)
▶ concepts (the durable layer, cross-checked vs _data/concepts.yml)
  ✔ list_concepts count == ledger length on disk (1.208458ms)
  ✔ every concept carries at least one source (a concept with no carrier is a claim) (1.053958ms)
  ✔ get_concept returns the sentence + sources for a known id (1.070958ms)
  ✔ get_concept on an unknown id returns a structured error (1.034167ms)
  ✔ find_concepts ranks the relevant concept first (1.279167ms)
  ✔ list_concepts tag filter is honored (1.022291ms)
  ✔ the concepts resource + a concept template resolve (4.302584ms)
✔ concepts (the durable layer, cross-checked vs _data/concepts.yml) (11.121416ms)
▶ resources
  ✔ brand/identity resource contains the Prime Directive (0.614709ms)
  ✔ findings resource is quarantined (2.988667ms)
  ✔ analytics resource surfaces the stale flag (0.402917ms)
  ✔ config/effective exposes the site config (0.538833ms)
  ✔ a content template resource returns the body (9.195875ms)
  ✔ EVERY listed resource reads without error and is non-empty (170.83675ms)
  ✔ an unknown resource URI is rejected (0.875875ms)
✔ resources (185.666083ms)
▶ frontmatter.parsePage
  ✔ splits a fenced front-matter block from the body (6.337916ms)
  ✔ no front matter → empty map, whole text is body (0.12725ms)
  ✔ an unclosed fence is treated as body (never throws) (0.0775ms)
  ✔ malformed YAML front matter degrades to an empty map (0.805375ms)
  ✔ asTags normalizes arrays and comma strings (0.105792ms)
✔ frontmatter.parsePage (8.326666ms)
▶ brand helpers
  ✔ check_word flags a sincerely-banned word (3.811084ms)
  ✔ check_word handles a banned word that carries an inline glossary comment (1.014041ms)
  ✔ check_word passes a neutral word (0.748ms)
  ✔ voiceForCollection maps collections to the autopilot's default profile (0.091958ms)
✔ brand helpers (5.840709ms)
▶ repo root resolution
  ✔ resolves a checkout that contains _config.yml (0.205334ms)
  ✔ throws on an LH_REPO_ROOT that is not the repo (0.312666ms)
✔ repo root resolution (0.59075ms)
ℹ tests 57
ℹ suites 13
ℹ pass 57
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 1064.591
[unit + integration suite] OK

----- stdio end-to-end smoke -----
[lifehacker-read] serving from /Users/bamr87/github/lifehacker.dev/.claude/worktrees/lifehacker-mcp-integration-e6442e

lifehacker-read smoke test (repo: /Users/bamr87/github/lifehacker.dev/.claude/worktrees/lifehacker-mcp-integration-e6442e)

Tools (12): check_word, find_concepts, get_brand_identity, get_concept, get_content_item, list_collection, list_concepts, list_taxonomy, query_backlog, query_health_queue, resolve_voice_profile, search_content
  [PASS] expected read tools present
  [PASS] NO mutating verb exists — guardrails-by-absence

Static resources: 263; templates: 9
  [PASS] brand/identity resource listed or templated
  [PASS] brand/identity has a Prime Directive
  [PASS] health/queue reads as JSON array

search_content("git"): 20 hits; top: posts/prd-machine-self-writing-documentation
  [PASS] search returns hits
  [PASS] get_content_item roundtrips the top hit
query_backlog(todo): 19 items
  [PASS] query_backlog(todo) returns a count
  [PASS] query_health_queue returns items
check_word("just"): banned-when-sincere
  [PASS] check_word('just') is banned-when-sincere
  [PASS] resolve_voice_profile(tools) = tool-review-honest
list_taxonomy(tags): 364 distinct tags
  [PASS] taxonomy has tags
list_concepts: 7 durable concepts
  [PASS] concept layer is present and every concept has a source
  [PASS] find_concepts('review bottleneck throughput') → the rate-limiter concept

ALL CHECKS PASSED
[stdio end-to-end smoke] OK

===== no-write proof: repo status AFTER =====
 M _data/navigation/main.yml
 M mcp/lifehacker-read/README.md
 M mcp/lifehacker-read/src/resources.ts
 M mcp/lifehacker-read/src/server.test.ts
 M mcp/lifehacker-read/src/smoke.ts
 M mcp/lifehacker-read/src/tools.ts
?? _data/concepts.yml
?? concepts.md
?? mcp/lifehacker-read/scripts/analyze-post.ts
?? mcp/lifehacker-read/src/concepts.ts
[no-write] OK — exercising the server + tests modified nothing tracked in the repo

===== cross-check: on-disk numbers the suite asserts against =====
  pages/_hacks: 57 markdown files
  pages/_tools: 23 markdown files
  pages/_posts: 98 markdown files
  pages/_docs:  25 markdown files
  pages/_about: 2 markdown files
  backlog total: 104 (yaml parse)
  backlog todo:  19 (yaml parse)
  backlog done:  84 (yaml parse)
  health queue:  57 findings
  glossary:      15 banned-when-sincere words

============================================================
 RESULT: ALL EVIDENCE CHECKS PASSED
============================================================
~~~

</details>
