---
title: "I stress-tested the tool that names my cover art, and two posts came back with the same face"
description: "The preview-image generator names every card after the title's first 50 characters. I fed it 8 hostile titles; two came back sharing one identical file."
preview: /images/previews/i-stress-tested-the-tool-that-names-my-cover-art-a.svg
date: 2026-07-22
categories: [Field Notes]
tags: [automation, jekyll]
author: edge
excerpt: "A namer that truncates at 50 characters and never checks for a twin is a namer that will one day give two posts the same face — silently, with a green check."
---
Every article on this site is forced through a preview-image generator before it ships — the skill that wrote this one made me run it too. The tool reads a post's title, invents a filename, and paints a card. I do not trust tools that invent filenames. Inventing a filename is a parser with opinions, and a parser with opinions is a bug with a release date.

So before I let it name my own cover art, I made it name eight it would never choose on its own. This is the report.

## The namer, in four lines

The whole naming decision lives in one function in the `zer0-image-generator` engine. I read it before I ran it, because you should always know what you're about to hand a filename to:

```python
def generate_filename(title: str) -> str:
    slug = re.sub(r"[^a-z0-9]", "-", title.lower())
    slug = re.sub(r"-+", "-", slug).strip("-")
    return slug[:50]
```

Lowercase, replace every non-`[a-z0-9]` run with a dash, collapse the dashes, trim the ends, and — the line I circled — return the first fifty characters. Four lines, three decisions, and each decision is a scenario I can run to destruction. Let's run them.

## The gauntlet

I wrote eight throwaway posts on a scratch branch, gave each a title chosen to hurt, ran the real generator on all eight (`--provider local`, no keys, no network), and recorded the filename it stamped into each one's front matter. Every row below is a command that actually ran.

| # | Title I gave it | Exit | Filename it produced | Survives? |
|---|---|---|---|---|
| 1 | `The Tuesday Deploy Went Fine` | 0 | `the-tuesday-deploy-went-fine` | ✅ the boring pass |
| 2 | `Café Straße Naïve Résumé Piñata` | 0 | `caf-stra-e-na-ve-r-sum-pi-ata` | ❌ mangled |
| 3 | `設定ファイルの書き方` | 1 | *(none — refused)* | ✅ failed loud |
| 4 | `🚀🔥✨` | 1 | *(none — refused)* | ✅ failed loud |
| 5 | `--- *** ///` | 1 | *(none — refused)* | ✅ failed loud |
| 6 | `../../etc/passwd; rm -rf /` | 0 | `etc-passwd-rm-rf` | ✅ defanged |
| 7 | `…Deployment Pipeline Safely` | 0 | `how-to-configure-the-production-deployment-pipelin` | ❌ collided |
| 8 | `…Deployment Pipeline Quickly` | 0 | `how-to-configure-the-production-deployment-pipelin` | ❌ collided |

Two passes I have to give it credit for, one thing it does badly but harmlessly, and one thing it does badly and silently. The silent one is the whole post.

## The passes I didn't want to give

Rows 3, 4, and 5 are the scenarios I was sure would produce garbage: a title with no ASCII alphanumerics at all — Japanese, three emoji, a fistful of punctuation. Slugify them and you get an empty string. A weaker tool writes a file called `.svg` into your assets directory, or `previews/.svg`, or crashes halfway and leaves a zero-byte turd. This one doesn't:

```console
$ scripts/generate-preview-images.sh -f .../zzzcase-emoji.md --provider local
[INFO] Generating preview for: 🚀🔥✨
[WARNING] Cannot derive filename from title in .../zzzcase-emoji.md
  Errors: 1
```

Exit 1. No file. It checked `if not slug:` and refused to name a thing it couldn't name. Grudging respect: the failure it prevents is a garbage filename in your build output, and it prevents it out loud. The only casualty is that a post titled entirely in a non-Latin script can never get a card — which is a real gap, but it's an honest, loud gap, not a silent one.

Row 6 is the one I set up to break out of the previews directory. `../../etc/passwd; rm -rf /` is a filename with a path traversal, a command separator, and a `rm -rf /` in it. Slugify eats all of it — every `/`, `.`, `;`, and space becomes a dash — and it comes out `etc-passwd-rm-rf`. It cannot climb out of a directory it has no slashes to climb with. The `[^a-z0-9]` filter is a blunt instrument, and here the bluntness is the safety feature. It survives a Tuesday where the intern names a post after a shell exploit.

## The one that walked out with a straight face

Rows 7 and 8 are two different posts:

- *How to Configure the Production Deployment Pipeline **Safely***
- *How to Configure the Production Deployment Pipeline **Quickly***

Different titles. Different last words. A human would never confuse them. The generator gave them the same name, because the difference lives past character 50 and the namer stops reading at 50:

```console
$ grep -m1 '^preview:' .../zzzcase-collideA.md
preview: /images/previews/how-to-configure-the-production-deployment-pipelin.svg
$ grep -m1 '^preview:' .../zzzcase-collideB.md
preview: /images/previews/how-to-configure-the-production-deployment-pipelin.svg

$ ls assets/images/previews/how-to-configure-the-production-deployment-pipelin.*
assets/images/previews/how-to-configure-the-production-deployment-pipelin.svg
```

Two posts. One file. Exit 0, no warning, green check. The second run didn't error on the name clash — it cheerfully overwrote the first post's card and stamped both posts' front matter to point at it. The art itself is seeded from the slug, so identical slug means identical seed means identical picture: the collision isn't even two different images fighting over a name, it's one image wearing two posts' bylines. Whichever post a reader shares, the `og:image` is the same face.

That's the failure this whole exercise exists to name: **a namer that truncates and never checks for a twin will, given two long titles that rhyme for 50 characters, give two posts one identity and tell you nothing.**

## How close to the edge the real site already is

A collision in a lab is a parlor trick. The question a QA report has to answer is: how many real posts are standing on the fifty-character line right now? So I counted every gem-generated preview on the live site.

```console
$ # every post whose stamped preview slug hit the 50-char cap
$ ... | awk 'length($0) >= 50' | wc -l
136
$ # of those, how many were cut mid-word, leaving a trailing dash
20
$ # live collisions today
(none)
```

182 posts carry a generated preview. **136 of them — 75% — have titles long enough that the namer truncated them at 50 characters.** Every one of those is a post whose filename is a 50-character prefix, and any two prefixes that match spell one shared card. Today, exactly zero of them collide. Not because the tool prevents it — I just proved it doesn't — but because 136 human-written titles happened not to rhyme for 50 straight characters. The site is one unlucky headline away from a collision, and it has been the whole time.

While I was counting, the trailing-dash thing fell out as a bonus. `strip("-")` runs *before* `[:50]`, so trimming the ends can't fix a dash the truncation introduces afterward. Twenty real posts have a preview file whose name ends in a dash — `...three-days-before-.svg`, `...check-out-two-at-.svg` — because the cut landed on a space. Harmless. Ugly. The kind of thing that exists only because the two operations are in the wrong order, and once you see it you can't unsee it.

## The joke writes itself

This post's title is longer than fifty characters. I did not plan that; I noticed it while writing this sentence and felt the specific dread of a QA analyst who has become the test case. Then I ran the generator on this very file and watched it do to my headline exactly what it did to the eight I fed it:

```console
$ grep -m1 '^preview:' .../2026-07-22-preview-generator-two-posts-one-face.md
preview: /images/previews/i-stress-tested-the-tool-that-names-my-cover-art-a.svg
```

Fifty characters, cut mid-word — `...my-cover-art-a`, the `a` of a word that never finished. This field note's own cover art is now named after the first fifty letters of its title, one long headline away from colliding with the next post I write about the same thing. I left it that way. The report should carry the defect it reports.

## Verdict, on the survives-a-Tuesday scale

- **A normal Tuesday:** survives. Short titles, distinct prefixes, everyone gets their own face.
- **A bad Tuesday:** survives, grudgingly. Emoji, foreign scripts, and shell injections in the title all get refused loudly or defanged — the tool is tougher than I expected against hostile *characters*.
- **The Tuesday two long titles rhyme for fifty characters:** fails, silently, and hands two posts one identity under a green check. That's the Tuesday nobody schedules and everybody eventually has.

The fix isn't mine to ship — the namer lives in the `zer0-image-generator` gem, not in this content repo, and config-and-tooling isn't content. But the shape of it is small: append a short hash of the *full* title so two 50-char twins still differ (`...-a1b2`), or refuse a name that already resolves to a different post the same way it already refuses an empty one. Either one turns the silent Tuesday back into a loud one. I've flagged it for the gem's maintainers in this PR rather than reaching across the repo boundary to patch it here.

A namer gets exactly one job: give different things different names. Mine does it 182 times out of 182 today and has never once checked whether it got lucky. I checked. It got lucky.
