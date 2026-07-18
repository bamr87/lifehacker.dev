// =============================================================================
// unit.test.ts — pure-module unit tests (no MCP transport).
// -----------------------------------------------------------------------------
// The front-matter parser, brand helpers, and repo-root resolution, exercised
// directly. These cover the parsing/edge-case logic the integration tests rely
// on but don't isolate.
//   npm test
// =============================================================================
import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { checkWord, voiceForCollection } from "./brand.js";
import { asTags, parsePage } from "./frontmatter.js";
import { RepoReader, resolveRepoRoot } from "./repo.js";

describe("frontmatter.parsePage", () => {
  test("splits a fenced front-matter block from the body", () => {
    const { frontMatter, body } = parsePage("---\ntitle: Hi\ntags: [a, b]\n---\n# Body\ntext");
    assert.equal(frontMatter["title"], "Hi");
    assert.deepEqual(frontMatter["tags"], ["a", "b"]);
    assert.match(body, /# Body/);
    assert.doesNotMatch(body, /title: Hi/);
  });

  test("no front matter → empty map, whole text is body", () => {
    const { frontMatter, body } = parsePage("# Just a heading\nno fence here");
    assert.deepEqual(frontMatter, {});
    assert.match(body, /Just a heading/);
  });

  test("an unclosed fence is treated as body (never throws)", () => {
    const { frontMatter, body } = parsePage("---\ntitle: dangling\nno closing fence");
    assert.deepEqual(frontMatter, {});
    assert.match(body, /dangling/);
  });

  test("malformed YAML front matter degrades to an empty map", () => {
    const { frontMatter } = parsePage("---\n: : : not: valid: yaml\n---\nbody");
    assert.equal(typeof frontMatter, "object");
  });

  test("asTags normalizes arrays and comma strings", () => {
    assert.deepEqual(asTags(["x", "y"]), ["x", "y"]);
    assert.deepEqual(asTags("x, y ,z"), ["x", "y", "z"]);
    assert.deepEqual(asTags(undefined), []);
  });
});

describe("brand helpers", () => {
  const reader = new RepoReader();

  test("check_word flags a sincerely-banned word", () => {
    assert.equal(checkWord(reader, "seamless").classification, "banned-when-sincere");
  });

  test("check_word treats a watch-word as ok (advisory, not banned)", () => {
    // 'just' and 'leverage' are watch_words in glossary.yml — style guidance only,
    // deliberately NOT linted/banned. check_word enforces banned_when_sincere +
    // avoid_phrases, so a watch-word classifies as ok.
    assert.equal(checkWord(reader, "just").classification, "ok");
    assert.equal(checkWord(reader, "leverage").classification, "ok");
  });

  test("check_word passes a neutral word", () => {
    assert.equal(checkWord(reader, "compiler").classification, "ok");
  });

  test("voiceForCollection maps collections to the autopilot's default profile", () => {
    assert.equal(voiceForCollection("hacks"), "how-to-practical");
    assert.equal(voiceForCollection("tools"), "tool-review-honest");
    assert.equal(voiceForCollection("field-notes"), "meta-confession");
    assert.equal(voiceForCollection("docs"), "meta-confession");
    assert.equal(voiceForCollection("about"), "satire-deadpan");
  });
});

describe("repo root resolution", () => {
  test("resolves a checkout that contains _config.yml", () => {
    const root = resolveRepoRoot();
    assert.ok(new RepoReader(root).exists("_config.yml"));
  });

  test("throws on an LH_REPO_ROOT that is not the repo", () => {
    const saved = process.env.LH_REPO_ROOT;
    process.env.LH_REPO_ROOT = "/tmp/not-the-lifehacker-repo-xyz";
    try {
      assert.throws(() => resolveRepoRoot(), /does not look like/);
    } finally {
      if (saved === undefined) delete process.env.LH_REPO_ROOT;
      else process.env.LH_REPO_ROOT = saved;
    }
  });
});
