# lifehacker-read — test evidence

Verification record for the P0 read-only MCP server (PR #281). Everything below
was **run**, not described — reproduce it with:

```bash
cd mcp/lifehacker-read && npm install && npm run evidence
```

Captured on Node v25.6.0 · Darwin 25.5.0 · commit `7264071` (`claude/mcp-p0-read-server`).

## Summary

| Check | Result |
|---|---|
| `tsc` typecheck (server **and** tests) | ✅ pass |
| `tsc` production build | ✅ pass |
| Unit + integration suite | ✅ **50/50 pass** across 12 suites |
| Stdio end-to-end smoke (real subprocess) | ✅ ALL CHECKS PASSED |
| No-write proof (git status before == after) | ✅ the server/tests modified nothing in the repo |
| Guardrails-by-absence (no mutating verb) | ✅ asserted by test **and** smoke |

## What the suite covers

The tests drive the **real** server over an in-memory MCP transport and
cross-check every answer against an **independent** read of the repo (filesystem
counts + a separate YAML/JSON parse), so green means the tools agree with the
files on disk — not merely with themselves.

- **Protocol & capabilities** — exactly 9 tools, 8 resource templates, content discoverable via `resources/list`.
- **Guardrails by absence** — no `create/update/propose/merge/approve/close/set_*` verb exists in the surface (the security invariant).
- **Content model** — `list_collection` counts equal `*.md` on disk for all 5 collections; item roundtrip; date-structured post permalinks; unknown slug → structured error; invalid collection → schema error.
- **search_content** — scored + sorted; collection filter; tag filter; limit.
- **taxonomy** — tag pool internally consistent; `Field Notes` category present.
- **query_backlog** — counts cross-checked against a YAML parse of `_data/backlog.yml` (total + per-status).
- **query_health_queue** — count == `queue.json` length; paging; schema-max rejection; severity filter.
- **brand** — **every** banned-when-sincere word classifies as banned; neutral word ok; per-collection voice mapping; Prime Directive present.
- **resources** — every one of the ~248 listed resources reads non-empty; findings/scout evidence quarantined; analytics stale-flag surfaced; unknown URI rejected.
- **units** — front-matter parser edge cases (no fence / unclosed fence / malformed YAML / tag coercion); repo-root resolution (valid + bad `LH_REPO_ROOT`).

## On-disk cross-check (the numbers the suite asserts against)

| Source | Count |
|---|---|
| `pages/_hacks` | 56 |
| `pages/_tools` | 22 |
| `pages/_posts` | 96 |
| `pages/_docs` | 22 |
| `pages/_about` | 2 |
| backlog total / todo / done | 95 / 14 / 80 |
| health queue findings | 75 |
| banned-when-sincere words | 15 |

> Note: the backlog counts use a real YAML parse. A naïve `grep 'status: todo'`
> reports 18 because it also matches the schema comment line
> `status: todo | drafting | done` — the tools (and these tests) parse YAML, so
> the true todo count is 14. The evidence script was corrected to match.

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
commit: 7264071 on claude/mcp-p0-read-server

===== no-write proof: repo status BEFORE =====
 M mcp/lifehacker-read/package.json
 M mcp/lifehacker-read/tsconfig.json
?? mcp/lifehacker-read/scripts/
?? mcp/lifehacker-read/src/harness.ts
?? mcp/lifehacker-read/src/server.test.ts
?? mcp/lifehacker-read/src/unit.test.ts
?? mcp/lifehacker-read/tsconfig.test.json

----- typecheck (tsc, tests included) -----
[typecheck (tsc, tests included)] OK

----- build (production tsc) -----
[build (production tsc)] OK

----- unit + integration suite -----

> lifehacker-read@0.1.0 test
> node --import tsx --test src/server.test.ts src/unit.test.ts

▶ protocol & capabilities
  ✔ exposes exactly the 9 expected read tools (4.664875ms)
  ✔ every tool declares a description (0.619458ms)
  ✔ registers the 8 resource templates (0.573792ms)
  ✔ lists the static + enumerated resources (content is discoverable) (70.239292ms)
✔ protocol & capabilities (76.7135ms)
▶ guardrails by absence (the security invariant)
  ✔ NO tool is a mutating verb (0.659041ms)
  ✔ no merge/approve/close/set-switch tool exists (0.345542ms)
✔ guardrails by absence (the security invariant) (1.123167ms)
▶ content model (cross-checked vs files on disk)
  ✔ list_collection(hacks) count == *.md on disk (11.045458ms)
  ✔ list_collection(tools) count == *.md on disk (3.926792ms)
  ✔ list_collection(posts) count == *.md on disk (17.198041ms)
  ✔ list_collection(docs) count == *.md on disk (4.078083ms)
  ✔ list_collection(about) count == *.md on disk (0.621958ms)
  ✔ get_content_item roundtrips a real item and carries a body (10.54575ms)
  ✔ posts permalink is date-structured (16.033458ms)
  ✔ unknown slug returns a structured error, not a throw (0.537667ms)
  ✔ invalid collection is rejected (schema error result, not success) (0.479ms)
✔ content model (cross-checked vs files on disk) (64.773459ms)
▶ search_content
  ✔ returns scored hits, sorted descending (36.078916ms)
  ✔ collection filter is honored (4.522208ms)
  ✔ tag filter returns only items carrying the tag (58.308584ms)
  ✔ limit is respected (30.546ms)
✔ search_content (129.607334ms)
▶ taxonomy
  ✔ tags pool is internally consistent (count == members) (28.505041ms)
  ✔ categories include 'Field Notes' (27.799ms)
✔ taxonomy (56.409459ms)
▶ query_backlog (cross-checked vs _data/backlog.yml)
  ✔ unfiltered count == backlog length on disk (11.055084ms)
  ✔ status:todo count matches independent count (10.543916ms)
  ✔ status:done count matches independent count (10.509791ms)
✔ query_backlog (cross-checked vs _data/backlog.yml) (32.223125ms)
▶ query_health_queue (cross-checked vs _data/health/queue.json)
  ✔ unfiltered count == queue length on disk (count is the full total, not the page) (0.698833ms)
  ✔ limit truncates the item page (0.4125ms)
  ✔ limit above the schema max is rejected (0.243542ms)
  ✔ severity filter is honored (0.707917ms)
✔ query_health_queue (cross-checked vs _data/health/queue.json) (2.144625ms)
▶ brand (cross-checked vs _data/brand/*.yml)
  ✔ get_brand_identity carries the Prime Directive + voice profiles (3.332834ms)
  ✔ EVERY banned-when-sincere word classifies as banned (7.809375ms)
  ✔ a neutral word classifies as ok (0.467209ms)
  ✔ voice profile resolves per collection (2.621958ms)
✔ brand (cross-checked vs _data/brand/*.yml) (14.311167ms)
▶ resources
  ✔ brand/identity resource contains the Prime Directive (0.982083ms)
  ✔ findings resource is quarantined (2.277292ms)
  ✔ analytics resource surfaces the stale flag (0.327666ms)
  ✔ config/effective exposes the site config (0.407ms)
  ✔ a content template resource returns the body (9.010875ms)
  ✔ EVERY listed resource reads without error and is non-empty (141.771834ms)
  ✔ an unknown resource URI is rejected (0.6815ms)
✔ resources (155.632083ms)
▶ frontmatter.parsePage
  ✔ splits a fenced front-matter block from the body (5.888125ms)
  ✔ no front matter → empty map, whole text is body (0.118792ms)
  ✔ an unclosed fence is treated as body (never throws) (0.076833ms)
  ✔ malformed YAML front matter degrades to an empty map (0.706917ms)
  ✔ asTags normalizes arrays and comma strings (0.104708ms)
✔ frontmatter.parsePage (7.759875ms)
▶ brand helpers
  ✔ check_word flags a sincerely-banned word (3.274875ms)
  ✔ check_word handles a banned word that carries an inline glossary comment (0.937209ms)
  ✔ check_word passes a neutral word (0.76725ms)
  ✔ voiceForCollection maps collections to the autopilot's default profile (0.091666ms)
✔ brand helpers (5.2505ms)
▶ repo root resolution
  ✔ resolves a checkout that contains _config.yml (0.201208ms)
  ✔ throws on an LH_REPO_ROOT that is not the repo (0.310666ms)
✔ repo root resolution (0.58825ms)
ℹ tests 50
ℹ suites 12
ℹ pass 50
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 931.4195
[unit + integration suite] OK

----- stdio end-to-end smoke -----
[lifehacker-read] serving from /Users/bamr87/github/lifehacker.dev/.claude/worktrees/lifehacker-mcp-integration-e6442e

lifehacker-read smoke test (repo: /Users/bamr87/github/lifehacker.dev/.claude/worktrees/lifehacker-mcp-integration-e6442e)

Tools (9): check_word, get_brand_identity, get_content_item, list_collection, list_taxonomy, query_backlog, query_health_queue, resolve_voice_profile, search_content
  [PASS] expected read tools present
  [PASS] NO mutating verb exists — guardrails-by-absence

Static resources: 248; templates: 8
  [PASS] brand/identity resource listed or templated
  [PASS] brand/identity has a Prime Directive
  [PASS] health/queue reads as JSON array

search_content("git"): 20 hits; top: posts/prd-machine-self-writing-documentation
  [PASS] search returns hits
  [PASS] get_content_item roundtrips the top hit
query_backlog(todo): 14 items
  [PASS] query_backlog(todo) returns a count
  [PASS] query_health_queue returns items
check_word("just"): banned-when-sincere
  [PASS] check_word('just') is banned-when-sincere
  [PASS] resolve_voice_profile(tools) = tool-review-honest
list_taxonomy(tags): 359 distinct tags
  [PASS] taxonomy has tags

ALL CHECKS PASSED
[stdio end-to-end smoke] OK

===== no-write proof: repo status AFTER =====
 M mcp/lifehacker-read/package.json
 M mcp/lifehacker-read/tsconfig.json
?? mcp/lifehacker-read/scripts/
?? mcp/lifehacker-read/src/harness.ts
?? mcp/lifehacker-read/src/server.test.ts
?? mcp/lifehacker-read/src/unit.test.ts
?? mcp/lifehacker-read/tsconfig.test.json
[no-write] OK — exercising the server + tests modified nothing tracked in the repo

===== cross-check: on-disk numbers the suite asserts against =====
  pages/_hacks: 56 markdown files
  pages/_tools: 22 markdown files
  pages/_posts: 96 markdown files
  pages/_docs:  22 markdown files
  pages/_about: 2 markdown files
  backlog total: 95 (yaml parse)
  backlog todo:  14 (yaml parse)
  backlog done:  80 (yaml parse)
  health queue:  75 findings
  glossary:      15 banned-when-sincere words

============================================================
 RESULT: ALL EVIDENCE CHECKS PASSED
============================================================
~~~

</details>
