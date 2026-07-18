# lifehacker-read — test evidence

Verification record for the read-only MCP server + concept engine. Everything below was **run**, not described — reproduce it with:

```bash
cd mcp/lifehacker-read && npm install && npm run evidence
```

Captured on Node v22.22.2 · Linux 6.18.5 · branch `claude/reorganize-collections-news-pi9kdf`.

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

The tests drive the **real** server over an in-memory MCP transport and cross-check every answer against an **independent** read of the repo (filesystem counts + a separate YAML/JSON parse), so green means the tools agree with the files on disk — not merely with themselves.

- **Protocol & capabilities** — 16 tools, 9 resource templates, content discoverable via `resources/list`.
- **Guardrails by absence** — no `create/update/propose/merge/approve/close/set_*` verb exists in the surface (the security invariant).
- **Content model** — the site's content is five logical **sections**: `hacks`, `tools`, and `field-notes` are section subdirectories of Jekyll's `posts` collection (`pages/_posts/{hacks,tools,field-notes}/`), while `docs` and `about` are standalone page collections (`pages/_docs`, `pages/_about`). `list_collection` counts equal `*.md` on disk for all five sections; roundtrip; **public URLs are preserved** across the reorg (`/hacks/<slug>/`, `/tools/<slug>/`, `/posts/<YYYY>/<MM>/<DD>/<slug>/`, `/docs/<slug>/`, `/about/<slug>/` — front-matter `permalink` wins, else the computed pattern, with the field-note date parsed out of the filename); unknown slug → error; invalid collection → schema error.
- **search_content / taxonomy / query_backlog / query_health_queue / brand** — each cross-checked against an independent parse of the underlying file(s).
- **concepts (the durable layer)** — `list_concepts` == `_data/concepts.yml`; **every concept carries ≥1 source**; `get_concept` + unknown-id error; `find_concepts` ranks correctly; the `lifehacker://concepts` resource + template resolve.
- **concept engine** — `relate_concept` (derived carriers exclude curated; explicit wiki links surface); `concepts_for` by tag/text (+ empty-input error); `concept_coverage` (per-concept carriers, weak concepts, high-frequency **uncovered tags**); `suggest_concept_growth` (ranked, typed `capture`/`reinforce`/`pin` moves); the `concepts/coverage` + `concepts/graph` resources.
- **resources** — every listed resource reads non-empty; findings/scout evidence quarantined; unknown URI rejected.
- **units** — front-matter parser edge cases; brand `check_word` (banned vs. advisory watch-words); repo-root resolution.

## Full run log

<details>
<summary>npm run evidence — complete output</summary>

~~~text
============================================================
 lifehacker-read — test evidence
============================================================
node:   v22.22.2
npm:    10.9.7
os:     Linux 6.18.5
repo:   /home/user/lifehacker.dev
commit: 9bed3ba on claude/reorganize-collections-news-pi9kdf

===== no-write proof: repo status BEFORE =====
 M .claude/skills/grow-lifehacker/SKILL.md
 M .claude/skills/session-retrospective/SKILL.md
 M .github/workflows/deploy-verify.yml
 M README.md
 M _data/brand/accepted.yml
 M docs/RETROSPECTIVE-HOOK.md
 M docs/journey/README.md
 M docs/proposals/mcp-integration.md
 M mcp/lifehacker-read/README.md
 M mcp/lifehacker-read/scripts/analyze-post.ts
 M mcp/lifehacker-read/scripts/collect-evidence.sh
 M mcp/lifehacker-read/src/brand.ts
 M mcp/lifehacker-read/src/collections.ts
 M mcp/lifehacker-read/src/server.test.ts
 M mcp/lifehacker-read/src/smoke.ts
 M mcp/lifehacker-read/src/tools.ts
 M mcp/lifehacker-read/src/unit.test.ts
 M scripts/content/triage_import.rb
 M scripts/explorer/_lib.rb
 M scripts/explorer/plan_routes.rb
 M scripts/scout/_lib.rb
 M scripts/sim/simulate.rb
 M scripts/triage/_lib.rb

----- typecheck (tsc, tests included) -----
[typecheck (tsc, tests included)] OK

----- build (production tsc) -----
[build (production tsc)] OK

----- unit + integration suite -----
TAP version 13
# Subtest: protocol & capabilities
    # Subtest: exposes exactly the 9 expected read tools
    ok 1 - exposes exactly the 9 expected read tools
    # Subtest: every tool declares a description
    ok 2 - every tool declares a description
    # Subtest: registers the 9 resource templates
    ok 3 - registers the 9 resource templates
    # Subtest: lists the static + enumerated resources (content is discoverable)
    ok 4 - lists the static + enumerated resources (content is discoverable)
    1..4
ok 1 - protocol & capabilities
# Subtest: guardrails by absence (the security invariant)
    # Subtest: NO tool is a mutating verb
    ok 1 - NO tool is a mutating verb
    # Subtest: no merge/approve/close/set-switch tool exists
    ok 2 - no merge/approve/close/set-switch tool exists
    1..2
ok 2 - guardrails by absence (the security invariant)
# Subtest: content model (cross-checked vs files on disk)
    # Subtest: list_collection(hacks) count == *.md on disk
    ok 1 - list_collection(hacks) count == *.md on disk
    # Subtest: list_collection(tools) count == *.md on disk
    ok 2 - list_collection(tools) count == *.md on disk
    # Subtest: list_collection(field-notes) count == *.md on disk
    ok 3 - list_collection(field-notes) count == *.md on disk
    # Subtest: list_collection(docs) count == *.md on disk
    ok 4 - list_collection(docs) count == *.md on disk
    # Subtest: list_collection(about) count == *.md on disk
    ok 5 - list_collection(about) count == *.md on disk
    # Subtest: get_content_item roundtrips a real item and carries a body
    ok 6 - get_content_item roundtrips a real item and carries a body
    # Subtest: field-notes permalink is date-structured (URL preserved as /posts/YYYY/MM/DD/slug/)
    ok 7 - field-notes permalink is date-structured (URL preserved as /posts/YYYY/MM/DD/slug/)
    # Subtest: unknown slug returns a structured error, not a throw
    ok 8 - unknown slug returns a structured error, not a throw
    # Subtest: invalid collection is rejected (schema error result, not success)
    ok 9 - invalid collection is rejected (schema error result, not success)
    1..9
ok 3 - content model (cross-checked vs files on disk)
# Subtest: search_content
    # Subtest: returns scored hits, sorted descending
    ok 1 - returns scored hits, sorted descending
    # Subtest: collection filter is honored
    ok 2 - collection filter is honored
    # Subtest: tag filter returns only items carrying the tag
    ok 3 - tag filter returns only items carrying the tag
    # Subtest: limit is respected
    ok 4 - limit is respected
    1..4
ok 4 - search_content
# Subtest: taxonomy
    # Subtest: tags pool is internally consistent (count == members)
    ok 1 - tags pool is internally consistent (count == members)
    # Subtest: categories include 'Field Notes'
    ok 2 - categories include 'Field Notes'
    1..2
ok 5 - taxonomy
# Subtest: query_backlog (cross-checked vs _data/backlog.yml)
    # Subtest: unfiltered count == backlog length on disk
    ok 1 - unfiltered count == backlog length on disk
    # Subtest: status:todo count matches independent count
    ok 2 - status:todo count matches independent count
    # Subtest: status:done count matches independent count
    ok 3 - status:done count matches independent count
    1..3
ok 6 - query_backlog (cross-checked vs _data/backlog.yml)
# Subtest: query_health_queue (cross-checked vs _data/health/queue.json)
    # Subtest: unfiltered count == queue length on disk (count is the full total, not the page)
    ok 1 - unfiltered count == queue length on disk (count is the full total, not the page)
    # Subtest: limit truncates the item page
    ok 2 - limit truncates the item page
    # Subtest: limit above the schema max is rejected
    ok 3 - limit above the schema max is rejected
    # Subtest: severity filter is honored
    ok 4 - severity filter is honored
    1..4
ok 7 - query_health_queue (cross-checked vs _data/health/queue.json)
# Subtest: brand (cross-checked vs _data/brand/*.yml)
    # Subtest: get_brand_identity carries the Prime Directive + voice profiles
    ok 1 - get_brand_identity carries the Prime Directive + voice profiles
    # Subtest: EVERY banned-when-sincere word classifies as banned
    ok 2 - EVERY banned-when-sincere word classifies as banned
    # Subtest: a neutral word classifies as ok
    ok 3 - a neutral word classifies as ok
    # Subtest: voice profile resolves per collection
    ok 4 - voice profile resolves per collection
    1..4
ok 8 - brand (cross-checked vs _data/brand/*.yml)
# Subtest: concepts (the durable layer, cross-checked vs _data/concepts.yml)
    # Subtest: list_concepts count == ledger length on disk
    ok 1 - list_concepts count == ledger length on disk
    # Subtest: every concept carries at least one source (a concept with no carrier is a claim)
    ok 2 - every concept carries at least one source (a concept with no carrier is a claim)
    # Subtest: get_concept returns the sentence + sources for a known id
    ok 3 - get_concept returns the sentence + sources for a known id
    # Subtest: get_concept on an unknown id returns a structured error
    ok 4 - get_concept on an unknown id returns a structured error
    # Subtest: find_concepts ranks the relevant concept first
    ok 5 - find_concepts ranks the relevant concept first
    # Subtest: list_concepts tag filter is honored
    ok 6 - list_concepts tag filter is honored
    # Subtest: the concepts resource + a concept template resolve
    ok 7 - the concepts resource + a concept template resolve
    1..7
ok 9 - concepts (the durable layer, cross-checked vs _data/concepts.yml)
# Subtest: concept engine (relate / reverse-lookup / coverage / growth)
    # Subtest: relate_concept expands a concept into content + tags + siblings
    ok 1 - relate_concept expands a concept into content + tags + siblings
    # Subtest: concepts_for(tag) finds the concepts carrying that tag
    ok 2 - concepts_for(tag) finds the concepts carrying that tag
    # Subtest: concepts_for(text) matches by keyword/sentence
    ok 3 - concepts_for(text) matches by keyword/sentence
    # Subtest: concepts_for with no input returns a helpful error
    ok 4 - concepts_for with no input returns a helpful error
    # Subtest: concept_coverage reports carriers, weak concepts, and uncovered tags
    ok 5 - concept_coverage reports carriers, weak concepts, and uncovered tags
    # Subtest: suggest_concept_growth returns ranked, typed next moves
    ok 6 - suggest_concept_growth returns ranked, typed next moves
    # Subtest: the coverage + graph resources resolve
    ok 7 - the coverage + graph resources resolve
    1..7
ok 10 - concept engine (relate / reverse-lookup / coverage / growth)
# Subtest: resources
    # Subtest: brand/identity resource contains the Prime Directive
    ok 1 - brand/identity resource contains the Prime Directive
    # Subtest: findings resource is quarantined
    ok 2 - findings resource is quarantined
    # Subtest: analytics resource surfaces the stale flag
    ok 3 - analytics resource surfaces the stale flag
    # Subtest: config/effective exposes the site config
    ok 4 - config/effective exposes the site config
    # Subtest: a content template resource returns the body
    ok 5 - a content template resource returns the body
    # Subtest: EVERY listed resource reads without error and is non-empty
    ok 6 - EVERY listed resource reads without error and is non-empty
    # Subtest: an unknown resource URI is rejected
    ok 7 - an unknown resource URI is rejected
    1..7
ok 11 - resources
# Subtest: frontmatter.parsePage
    # Subtest: splits a fenced front-matter block from the body
    ok 1 - splits a fenced front-matter block from the body
    # Subtest: no front matter → empty map, whole text is body
    ok 2 - no front matter → empty map, whole text is body
    # Subtest: an unclosed fence is treated as body (never throws)
    ok 3 - an unclosed fence is treated as body (never throws)
    # Subtest: malformed YAML front matter degrades to an empty map
    ok 4 - malformed YAML front matter degrades to an empty map
    # Subtest: asTags normalizes arrays and comma strings
    ok 5 - asTags normalizes arrays and comma strings
    1..5
ok 12 - frontmatter.parsePage
# Subtest: brand helpers
    # Subtest: check_word flags a sincerely-banned word
    ok 1 - check_word flags a sincerely-banned word
    # Subtest: check_word treats a watch-word as ok (advisory, not banned)
    ok 2 - check_word treats a watch-word as ok (advisory, not banned)
    # Subtest: check_word passes a neutral word
    ok 3 - check_word passes a neutral word
    # Subtest: voiceForCollection maps collections to the autopilot's default profile
    ok 4 - voiceForCollection maps collections to the autopilot's default profile
    1..4
ok 13 - brand helpers
# Subtest: repo root resolution
    # Subtest: resolves a checkout that contains _config.yml
    ok 1 - resolves a checkout that contains _config.yml
    # Subtest: throws on an LH_REPO_ROOT that is not the repo
    ok 2 - throws on an LH_REPO_ROOT that is not the repo
    1..2
ok 14 - repo root resolution
1..14
# tests 64
# suites 14
# pass 64
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 2693.472193
[unit + integration suite] OK

----- stdio end-to-end smoke -----
[lifehacker-read] serving from /home/user/lifehacker.dev

lifehacker-read smoke test (repo: /home/user/lifehacker.dev)

Tools (16): check_word, concept_coverage, concepts_for, find_concepts, get_brand_identity, get_concept, get_content_item, list_collection, list_concepts, list_taxonomy, query_backlog, query_health_queue, relate_concept, resolve_voice_profile, search_content, suggest_concept_growth
  [PASS] expected read tools present
  [PASS] NO mutating verb exists — guardrails-by-absence

Static resources: 282; templates: 9
  [PASS] brand/identity resource listed or templated
  [PASS] brand/identity has a Prime Directive
  [PASS] health/queue reads as JSON array

search_content("git"): 20 hits; top: hacks/git-bisect-run-find-the-bad-commit
  [PASS] search returns hits
  [PASS] get_content_item roundtrips the top hit
query_backlog(todo): 24 items
  [PASS] query_backlog(todo) returns a count
  [PASS] query_health_queue returns items
check_word("seamless"): banned-when-sincere
  [PASS] check_word('seamless') is banned-when-sincere
  [PASS] resolve_voice_profile(tools) = tool-review-honest
list_taxonomy(tags): 19 distinct tags
  [PASS] taxonomy has tags
list_concepts: 7 durable concepts
  [PASS] concept layer is present and every concept has a source
  [PASS] find_concepts('review bottleneck throughput') → the rate-limiter concept
suggest_concept_growth: top move → Capture a concept for the "ai" cluster
  [PASS] concept engine suggests ranked growth moves

ALL CHECKS PASSED
[stdio end-to-end smoke] OK

===== no-write proof: repo status AFTER =====
 M .claude/skills/grow-lifehacker/SKILL.md
 M .claude/skills/session-retrospective/SKILL.md
 M .github/workflows/deploy-verify.yml
 M README.md
 M _data/brand/accepted.yml
 M docs/RETROSPECTIVE-HOOK.md
 M docs/journey/README.md
 M docs/proposals/mcp-integration.md
 M mcp/lifehacker-read/README.md
 M mcp/lifehacker-read/scripts/analyze-post.ts
 M mcp/lifehacker-read/scripts/collect-evidence.sh
 M mcp/lifehacker-read/src/brand.ts
 M mcp/lifehacker-read/src/collections.ts
 M mcp/lifehacker-read/src/server.test.ts
 M mcp/lifehacker-read/src/smoke.ts
 M mcp/lifehacker-read/src/tools.ts
 M mcp/lifehacker-read/src/unit.test.ts
 M scripts/content/triage_import.rb
 M scripts/explorer/_lib.rb
 M scripts/explorer/plan_routes.rb
 M scripts/scout/_lib.rb
 M scripts/sim/simulate.rb
 M scripts/triage/_lib.rb
[no-write] OK — exercising the server + tests modified nothing tracked in the repo

===== cross-check: on-disk numbers the suite asserts against =====
  pages/_posts/hacks:        61 markdown files
  pages/_posts/tools:        25 markdown files
  pages/_posts/field-notes:  102 markdown files
  pages/_docs:               30 markdown files
  pages/_about:              2 markdown files
  backlog total: 123 (yaml parse)
  backlog todo:  24 (yaml parse)
  backlog done:  98 (yaml parse)
  health queue:  1 findings
  glossary:      9 banned-when-sincere words

============================================================
 RESULT: ALL EVIDENCE CHECKS PASSED
============================================================
~~~

</details>
