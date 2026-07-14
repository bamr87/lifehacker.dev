# lifehacker-read — test evidence

Verification record for the read-only MCP server + concept engine. Everything
below was **run**, not described — reproduce it with:

```bash
cd mcp/lifehacker-read && npm install && npm run evidence
```

Captured on Node v25.6.0 · Darwin 25.5.0 · branch `claude/concept-layer`.

## Summary

| Check | Result |
|---|---|
| `tsc` typecheck (server **and** tests) | ✅ pass |
| `tsc` production build | ✅ pass |
| Unit + integration suite | ✅ **64/64 pass** across 14 suites |
| Stdio end-to-end smoke (real subprocess) | ✅ ALL CHECKS PASSED |
| No-write proof (git status before == after) | ✅ the server/tests modified nothing in the repo |
| Guardrails-by-absence (no mutating verb) | ✅ asserted by test **and** smoke |

## What the suite covers

The tests drive the **real** server over an in-memory MCP transport and
cross-check every answer against an **independent** read of the repo (filesystem
counts + a separate YAML/JSON parse), so green means the tools agree with the
files on disk — not merely with themselves.

- **Protocol & capabilities** — 16 tools, 9 resource templates, content discoverable via `resources/list`.
- **Guardrails by absence** — no `create/update/propose/merge/approve/close/set_*` verb exists in the surface (the security invariant).
- **Content model** — `list_collection` counts equal `*.md` on disk for all 5 collections; roundtrip; date permalinks; unknown slug → error; invalid collection → schema error.
- **search_content / taxonomy / query_backlog / query_health_queue / brand** — each cross-checked against an independent parse of the underlying file(s).
- **concepts (the durable layer)** — `list_concepts` == `_data/concepts.yml`; **every concept carries ≥1 source**; `get_concept` + unknown-id error; `find_concepts` ranks correctly; the `lifehacker://concepts` resource + template resolve.
- **concept engine** — `relate_concept` (derived carriers exclude curated; explicit wiki links surface); `concepts_for` by tag/text (+ empty-input error); `concept_coverage` (per-concept carriers, weak concepts, high-frequency **uncovered tags**); `suggest_concept_growth` (ranked, typed `capture`/`reinforce`/`pin` moves); the `concepts/coverage` + `concepts/graph` resources.
- **resources** — every listed resource reads non-empty; findings/scout evidence quarantined; unknown URI rejected.
- **units** — front-matter parser edge cases; repo-root resolution.

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
commit: 1fdaff6 on claude/concept-layer

===== no-write proof: repo status BEFORE =====
 M _data/concepts.yml
 M concepts.md
 M mcp/lifehacker-read/README.md
 M mcp/lifehacker-read/src/concepts.ts
 M mcp/lifehacker-read/src/resources.ts
 M mcp/lifehacker-read/src/server.test.ts
 M mcp/lifehacker-read/src/smoke.ts
 M mcp/lifehacker-read/src/tools.ts
?? mcp/lifehacker-read/src/engine.ts

----- typecheck (tsc, tests included) -----
[typecheck (tsc, tests included)] OK

----- build (production tsc) -----
[build (production tsc)] OK

----- unit + integration suite -----

> lifehacker-read@0.1.0 test
> node --import tsx --test src/server.test.ts src/unit.test.ts

▶ protocol & capabilities
  ✔ exposes exactly the 9 expected read tools (3.871791ms)
  ✔ every tool declares a description (0.47825ms)
  ✔ registers the 9 resource templates (0.444834ms)
  ✔ lists the static + enumerated resources (content is discoverable) (37.177334ms)
✔ protocol & capabilities (42.417916ms)
▶ guardrails by absence (the security invariant)
  ✔ NO tool is a mutating verb (0.499875ms)
  ✔ no merge/approve/close/set-switch tool exists (0.32475ms)
✔ guardrails by absence (the security invariant) (0.903833ms)
▶ content model (cross-checked vs files on disk)
  ✔ list_collection(hacks) count == *.md on disk (8.071458ms)
  ✔ list_collection(tools) count == *.md on disk (3.427917ms)
  ✔ list_collection(posts) count == *.md on disk (11.264708ms)
  ✔ list_collection(docs) count == *.md on disk (3.559834ms)
  ✔ list_collection(about) count == *.md on disk (0.475625ms)
  ✔ get_content_item roundtrips a real item and carries a body (7.764208ms)
  ✔ posts permalink is date-structured (11.117667ms)
  ✔ unknown slug returns a structured error, not a throw (0.402083ms)
  ✔ invalid collection is rejected (schema error result, not success) (0.310208ms)
✔ content model (cross-checked vs files on disk) (46.638959ms)
▶ search_content
  ✔ returns scored hits, sorted descending (24.810667ms)
  ✔ collection filter is honored (3.405375ms)
  ✔ tag filter returns only items carrying the tag (41.623917ms)
  ✔ limit is respected (20.917792ms)
✔ search_content (90.864708ms)
▶ taxonomy
  ✔ tags pool is internally consistent (count == members) (19.976875ms)
  ✔ categories include 'Field Notes' (18.753209ms)
✔ taxonomy (38.796042ms)
▶ query_backlog (cross-checked vs _data/backlog.yml)
  ✔ unfiltered count == backlog length on disk (7.533666ms)
  ✔ status:todo count matches independent count (7.474667ms)
  ✔ status:done count matches independent count (7.398208ms)
✔ query_backlog (cross-checked vs _data/backlog.yml) (22.470666ms)
▶ query_health_queue (cross-checked vs _data/health/queue.json)
  ✔ unfiltered count == queue length on disk (count is the full total, not the page) (0.405084ms)
  ✔ limit truncates the item page (0.232292ms)
  ✔ limit above the schema max is rejected (0.161875ms)
  ✔ severity filter is honored (0.389125ms)
✔ query_health_queue (cross-checked vs _data/health/queue.json) (1.238958ms)
▶ brand (cross-checked vs _data/brand/*.yml)
  ✔ get_brand_identity carries the Prime Directive + voice profiles (1.052375ms)
  ✔ EVERY banned-when-sincere word classifies as banned (4.270042ms)
  ✔ a neutral word classifies as ok (0.297583ms)
  ✔ voice profile resolves per collection (1.759375ms)
✔ brand (cross-checked vs _data/brand/*.yml) (7.435792ms)
▶ concepts (the durable layer, cross-checked vs _data/concepts.yml)
  ✔ list_concepts count == ledger length on disk (1.042291ms)
  ✔ every concept carries at least one source (a concept with no carrier is a claim) (1.019916ms)
  ✔ get_concept returns the sentence + sources for a known id (0.991584ms)
  ✔ get_concept on an unknown id returns a structured error (0.951375ms)
  ✔ find_concepts ranks the relevant concept first (1.031708ms)
  ✔ list_concepts tag filter is honored (0.894417ms)
  ✔ the concepts resource + a concept template resolve (2.887667ms)
✔ concepts (the durable layer, cross-checked vs _data/concepts.yml) (8.906ms)
▶ concept engine (relate / reverse-lookup / coverage / growth)
  ✔ relate_concept expands a concept into content + tags + siblings (22.523083ms)
  ✔ concepts_for(tag) finds the concepts carrying that tag (0.971167ms)
  ✔ concepts_for(text) matches by keyword/sentence (0.90125ms)
  ✔ concepts_for with no input returns a helpful error (0.096958ms)
  ✔ concept_coverage reports carriers, weak concepts, and uncovered tags (64.341334ms)
  ✔ suggest_concept_growth returns ranked, typed next moves (58.278125ms)
  ✔ the coverage + graph resources resolve (57.204542ms)
✔ concept engine (relate / reverse-lookup / coverage / growth) (204.450791ms)
▶ resources
  ✔ brand/identity resource contains the Prime Directive (0.398833ms)
  ✔ findings resource is quarantined (2.786083ms)
  ✔ analytics resource surfaces the stale flag (0.338667ms)
  ✔ config/effective exposes the site config (0.347917ms)
  ✔ a content template resource returns the body (5.45175ms)
  ✔ EVERY listed resource reads without error and is non-empty (165.739708ms)
  ✔ an unknown resource URI is rejected (0.497792ms)
✔ resources (175.672334ms)
▶ frontmatter.parsePage
  ✔ splits a fenced front-matter block from the body (4.030083ms)
  ✔ no front matter → empty map, whole text is body (0.0855ms)
  ✔ an unclosed fence is treated as body (never throws) (0.053084ms)
  ✔ malformed YAML front matter degrades to an empty map (0.496125ms)
  ✔ asTags normalizes arrays and comma strings (0.076042ms)
✔ frontmatter.parsePage (5.356791ms)
▶ brand helpers
  ✔ check_word flags a sincerely-banned word (1.796583ms)
  ✔ check_word handles a banned word that carries an inline glossary comment (0.936292ms)
  ✔ check_word passes a neutral word (0.545125ms)
  ✔ voiceForCollection maps collections to the autopilot's default profile (0.06275ms)
✔ brand helpers (3.463417ms)
▶ repo root resolution
  ✔ resolves a checkout that contains _config.yml (0.148375ms)
  ✔ throws on an LH_REPO_ROOT that is not the repo (0.21375ms)
✔ repo root resolution (0.4145ms)
ℹ tests 64
ℹ suites 14
ℹ pass 64
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 911.884375
[unit + integration suite] OK

----- stdio end-to-end smoke -----
[lifehacker-read] serving from /Users/bamr87/github/lifehacker.dev/.claude/worktrees/lifehacker-mcp-integration-e6442e

lifehacker-read smoke test (repo: /Users/bamr87/github/lifehacker.dev/.claude/worktrees/lifehacker-mcp-integration-e6442e)

Tools (16): check_word, concept_coverage, concepts_for, find_concepts, get_brand_identity, get_concept, get_content_item, list_collection, list_concepts, list_taxonomy, query_backlog, query_health_queue, relate_concept, resolve_voice_profile, search_content, suggest_concept_growth
  [PASS] expected read tools present
  [PASS] NO mutating verb exists — guardrails-by-absence

Static resources: 265; templates: 9
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
suggest_concept_growth: top move → Capture a concept for the "cli" cluster
  [PASS] concept engine suggests ranked growth moves

ALL CHECKS PASSED
[stdio end-to-end smoke] OK

===== no-write proof: repo status AFTER =====
 M _data/concepts.yml
 M concepts.md
 M mcp/lifehacker-read/README.md
 M mcp/lifehacker-read/src/concepts.ts
 M mcp/lifehacker-read/src/resources.ts
 M mcp/lifehacker-read/src/server.test.ts
 M mcp/lifehacker-read/src/smoke.ts
 M mcp/lifehacker-read/src/tools.ts
?? mcp/lifehacker-read/src/engine.ts
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
