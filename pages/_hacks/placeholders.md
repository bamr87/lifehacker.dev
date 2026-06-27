---
title: "Front Matter Placeholders: Stop Frontmatter Drift Before the Validator Sees It"
description: "Pre-fill boring frontmatter fields with Front Matter CMS defaults, audit the drift you already have with grep, and the author-import failure behind it."
date: 2024-04-25
collection: hacks
author: amr
excerpt: "Templates tell authors which fields exist. Placeholders fill them in correctly — and grep finds the 600 files that drifted before anyone wired that up."
tags: [frontmatter, jekyll, templates, grep, content-strategy]
---

A Jekyll site with a few hundred markdown files has a frontmatter consistency problem whether you've noticed it or not. Some posts have `description`, some have `excerpt`, a few have both with subtly different text. Categories are a bare string in 2022 and a YAML list in 2024. `lastmod` exists on maybe 40% of files, chosen by nobody, applied at random.

None of this is anyone's fault, exactly. Someone opened a new post, copy-pasted the frontmatter from the file next to it, and renamed two fields. The template told them which keys to write. Nothing told them what those keys should *contain* — so the boring fields got copied wrong, or left blank, or quietly omitted.

There are two halves to fixing this, and they need two different tools. Placeholders make every *new* file correct. A grep audit plus a normalizer finds the *old* files that already drifted. Here's both, with the failure that kicked it off left in.

## The part where it broke

Before any of this was wired up, a batch import set the `author` field on a few posts to this:

```text
author: 2024-04-25 16:19:09.808000+00:00
```

That's a timestamp where a name should be. The importer had grabbed the wrong column, and because nothing pre-filled `author` with a known-good value, the garbage rode straight into the frontmatter and sat there until a build surfaced it. The fix isn't "be more careful pasting." The fix is to make the correct value the *default* value, so the boring fields are never blank long enough for the wrong thing to fill them.

## Placeholders: make the new files correct

[Front Matter CMS](https://frontmatter.codes) is a VS Code extension that sits one layer underneath your content templates. Its content types let you declare a `default` for each field — a small rule that says "when the author opens a new file, pre-fill this key with this value." By the time the file opens, the dull fields are already right and the author only writes the body.

This is editor configuration, not a command, so the block below is documentation — paste it into `frontmatter.json` at your repo root and reload VS Code:

{% raw %}
```json
{
  "frontMatter.taxonomy.contentTypes": [
    {
      "name": "post",
      "pageBundle": false,
      "fields": [
        { "title": "Title",       "name": "title",       "type": "string" },
        { "title": "Description",  "name": "description", "type": "string" },
        { "title": "Date",         "name": "date",        "type": "datetime", "default": "{{now}}" },
        { "title": "Slug",         "name": "slug",        "type": "slug",     "default": "{{slugify ${title}}}" },
        { "title": "Author",       "name": "author",      "type": "string",   "default": "{{user}}" },
        { "title": "Draft",        "name": "draft",       "type": "boolean",  "default": false }
      ]
    }
  ]
}
```
{% endraw %}

The four `default` keys are the whole trick:

{% raw %}
- `{{now}}` stamps `date` so it can never be copied from a 2022 post.
- `{{slugify ${title}}}` derives the slug from the title, so the URL matches the headline even if the author renames the file later.
- `{{user}}` writes the current user into `author` — the exact field the timestamp import corrupted.
{% endraw %}
- `false` on `draft` means "publishable by default"; an author must explicitly flip it to `true`, which matches how most teams actually ship.

You'll know it worked when you create a post through the Front Matter sidebar and `date`, `slug`, `author`, and `draft` are already filled in correctly — you never typed them, and they're never blank.

## Placeholders fix nothing you already have

That's the catch the docs underplay. Defaults only fire on *new* files. The hundreds of files that already drifted don't change when you add a content type — they were created before the rule existed. For those you need to (1) measure the drift and (2) normalize it. Both are plain shell.

## Audit the drift with grep

Before fixing anything, find out what you're dealing with. This is offline, no build, no plugin: count which frontmatter keys appear and in how many files. We ran the whole sequence below against a throwaway site so the output is real:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p _posts

# Three posts that drifted the way real ones do.
cat > _posts/a.md <<'MD'
---
title: First Post
categories: tutorials
date: "2022-03-01"
---
body
MD

cat > _posts/b.md <<'MD'
---
title: Second Post
categories: [tutorials, jekyll]
date: 2024-04-25
lastmod: 2024-05-01
---
body
MD

cat > _posts/c.md <<'MD'
---
title: Third Post
excerpt: a teaser
date: 2023-11-12
---
body
MD

echo "=== which keys appear, and in how many files ==="
grep -rhoE '^[a-zA-Z_]+:' _posts | sort | uniq -c | sort -rn
```

Real output:

```text
=== which keys appear, and in how many files ===
   3 title:
   3 date:
   2 categories:
   1 lastmod:
   1 excerpt:
```

That table is the drift, quantified. `title` and `date` are on every file — good. `categories` is on two of three, `excerpt` on one, `lastmod` on one. You now know exactly which keys are inconsistent instead of guessing.

`grep -rhoE` is doing the work: `-r` recurses, `-o` prints only the matched key (not the whole line), `-h` suppresses filenames, and `^[a-zA-Z_]+:` matches a frontmatter key at the start of a line. Pipe through `sort | uniq -c | sort -rn` and you get a frequency table.

## Find the two specific drifts that bite

A frequency table tells you a key is inconsistent; it doesn't tell you which files to fix. Two queries do. First, list files **missing** a required key — here, `description`:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p _posts
cat > _posts/a.md <<'MD'
---
title: First Post
categories: tutorials
---
body
MD
cat > _posts/b.md <<'MD'
---
title: Second Post
description: a real description
---
body
MD

for f in _posts/*.md; do
  grep -qE '^description:' "$f" || echo "MISSING description  $f"
done
```

Real output:

```text
MISSING description  _posts/a.md
```

Only `a.md` is flagged; `b.md` has a `description`, so it's silent. That's your worklist — the exact files to backfill, by name.

Second, find `categories` written as a bare string instead of a YAML list — the 2022-vs-2024 drift that makes Jekyll treat one category as a single blob:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p _posts
cat > _posts/a.md <<'MD'
---
categories: tutorials
---
MD
cat > _posts/b.md <<'MD'
---
categories: [tutorials, jekyll]
---
MD

# Match a categories value whose first non-space character is NOT '['.
grep -rnE '^categories:[[:space:]]+[^[:space:][]' _posts
```

Real output:

```text
_posts/a.md:3:categories: tutorials
```

The regex `^categories:[[:space:]]+[^[:space:][]` reads as: the key `categories:`, then whitespace, then a character that is neither whitespace nor `[`. A list value (`[tutorials, ...]`) starts with `[` and is skipped; a bare string (`tutorials`) is caught, with its line number, ready to fix.

## Normalize the old files

Once you know which files drifted, the repeatable fix belongs in a script that runs on every CI build — coercing string categories into lists, normalizing dates to one ISO format, and bumping `lastmod` only on files that actually changed. The audit above is what you run *before* writing that normalizer (to scope the job) and *after* (to prove the count went to zero). Two tools, two jobs: placeholders keep new files clean; the audit-and-normalize pass cleans the backlog.

## When this goes wrong

A few honest edges:

- **The audit greps frontmatter naively.** `grep -rhoE '^[a-zA-Z_]+:'` matches any `key:` at the start of a line — including a `note: something` line inside your post *body*. On posts with prose that begins lines with `word:`, the counts run slightly high. For a quick drift read that's fine; if you're gating CI on exact counts, parse the frontmatter block (everything between the first two `---` lines) instead of the whole file.

- **Placeholder defaults don't validate.** {% raw %}`{{user}}`{% endraw %} writes whatever VS Code thinks your username is. If that's misconfigured, you've replaced a blank `author` with a *consistently wrong* `author`, which is harder to spot than an empty one. Check the value it produces on the first real post before you trust it on a hundred.

- **`default` only fires through the Front Matter sidebar.** Create a file with `touch` or your importer and the defaults never run — which is exactly how the timestamp got into `author` in the first place. Placeholders protect the sidebar path, not every path. Keep the grep audit in CI to catch the files that came in some other way.

## The honest accounting

Placeholders save you typing four boring fields per new post, which rounds to nothing per post. The grep audit saves you reading hundreds of files by hand, which does not.

The real win is that "what should this field contain" stops being a thing each author re-decides every time. The default decides it once; the audit proves the old files agree; and `author: 2024-04-25 16:19:09.808000+00:00` never ships again, because the correct value was already in the field before anyone had a chance to paste the wrong one.

Set the defaults. Grep the drift. Then go write the body, which was the only part that needed a human anyway.
