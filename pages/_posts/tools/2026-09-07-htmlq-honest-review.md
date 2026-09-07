---
title: "htmlq: jq for HTML that returns nothing and swears it worked"
description: "A stress-tested review of htmlq: the selector that silently matches nothing, the tbody trap, the flag that eats your query — and the gauntlet it survived."
date: 2026-09-07
preview: /images/previews/htmlq-jq-for-html-that-returns-nothing-and-swears-.svg
categories: [Tools]
tags: [data]
author: edge
verdict: "Use it — survives a bad Tuesday. But every failure mode is silent: empty output, exit 0, and a downstream job that believes it."
excerpt: "I fed htmlq the HTML nobody sane would keep. It parsed the mess like a browser and then, on the ordinary stuff, printed nothing and exited 0 — and every script reading its output believed the empty string."
permalink: /tools/htmlq-honest-review/
---
I review data tools by handing them the input nobody sane would keep and watching which half falls off. `htmlq` is the one people reach for the day they finally admit they've been scraping HTML with a `grep` and a regex and a prayer. The pitch is exact and correct: it's `jq`, but for HTML — pipe a page in, hand it a CSS selector, get the matching elements or their text back out. For pulling one thing out of a page from a shell script, it is genuinely the right tool.

It is also, and this is the entire review, a tool whose every failure mode looks *identical to success*: empty output and exit 0. `jq` at least has the decency to throw when you hand it garbage. `htmlq` mostly just shrugs, prints nothing, and returns zero — and the cron job reading its stdout has no way to tell "the page changed and my selector is dead" apart from "there were legitimately no matches." I found four different ways to make it do that, and three of them are things you'll write on your first afternoon.

**The verdict, up front:** use it. It's fast, it parses broken HTML like an actual browser, and it refused to break on a genuinely hostile gauntlet. It survives a normal Tuesday and most of a bad one. What it does not do is *tell you* when it failed — so the Tuesday it doesn't survive is the automated one, where nothing is watching stdout and nothing is checking whether "empty" meant "no matches" or "my query rotted."

Everything below ran on a fresh Ubuntu 24.04 box against the version `cargo` built me:

```console
$ htmlq --version
htmlq 0.4.0
```

(First honest note, free: there's no `apt install htmlq` — it's `cargo install htmlq`, which compiles from source. Budget a couple of minutes and a working Rust toolchain, or grab a release binary. The binary matches the crate name, at least; small mercies.)

## Gotcha 1: a selector that matches nothing is indistinguishable from success

Here is the whole thesis in four lines. A real page, a selector with a typo in it:

```console
$ cat basic.html
<a href="/one">One</a>
<a href="/two">Two</a>
<p class="price">$12</p>

$ htmlq -t '.does-not-exist' < basic.html
$ echo "exit=$?"
exit=0
```

Nothing on stdout. Exit 0. Now imagine that selector isn't a typo — it's a real class name that was correct last month and got renamed in a redesign this month. Your scraper runs, `htmlq` emits an empty string, exits clean, and the next stage of your pipeline dutifully writes `""` into the "price" column and moves on. Nothing threw. Nothing logged. You find out when someone asks why every price since the 3rd is blank.

The victim is named precisely: it's the unattended job that does `price=$(htmlq -t '.price' < page.html)` and never asks whether `$price` is empty because the selector died or empty because the item was genuinely free. `htmlq` cannot tell you the difference, so *you* have to — check for empty and fail loud, because the tool won't.

And when I say it won't complain, I mean it will complain about the *wrong* things. Hand it a malformed selector and it doesn't emit a clean error — it panics:

```console
$ htmlq -t '' < basic.html
Failed to parse CSS selector: ()
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
$ echo "exit=$?"
exit=101
```

An empty selector string — the thing you get when `htmlq -t "$SEL"` runs with `$SEL` unset — doesn't warn, doesn't skip, doesn't exit 1. It panics with a Rust backtrace and exits 101. So the scoreboard so far: a selector that's *wrong but valid* fails silently, and a selector that's *empty* fails with a stack trace. The one thing it never does is fail *usefully*.

## Gotcha 2: the tbody trap — `table > tr` matches zero rows

This one gets everybody who scrapes a table, because it's a lie the browser tells too. Here is a table with no `<tbody>` in the source — exactly what most hand-written HTML looks like:

```console
$ cat table.html
<table><tr><td>r1</td></tr><tr><td>r2</td></tr></table>

$ htmlq -t 'table > tr' < table.html
$ echo "exit=$?"
exit=0
```

Zero rows. Exit 0. The selector is obviously correct — `tr` is a direct child of `table`, you can see it right there in the file. Except it isn't, because `htmlq` parses with `html5ever`, the same spec-compliant machinery a browser uses, and the HTML spec says a `<tr>` inside a `<table>` gets an implicit `<tbody>` wrapped around it. So the *real* tree is `table > tbody > tr`, and your direct-child selector walks right past it:

```console
$ htmlq -t 'table > tbody > tr' < table.html
r1
r2
```

This is *correct* — it's doing what Chrome does — but it collides head-on with Gotcha 1. The selector that "should obviously work" matches nothing, and nothing throws, so you don't get a hint that the tree isn't shaped like your file. The fix is either the explicit `tbody` or the safe descendant combinator `table tr` (a space, not a `>`), which matches through the phantom `tbody`. The victim is every table scraper that read the raw HTML, wrote `table > tr`, tested it against a fixture that happened to have an explicit `<tbody>`, and shipped.

## Gotcha 3: the flag that eats your query

`--remove-nodes` is the flag you'll want the moment you extract text, and it's laid a rake in the grass. It's variadic — it takes one *or more* selectors to strip before output. The positional selector is *also* variadic. Put a multi-value `--remove-nodes` in front of your selector and watch the tool quietly eat your query:

```console
$ cat page.html
<html><head><style>.x{color:red}</style></head>
<body><script>var secret=42;</script><p>Real text</p></body></html>

$ htmlq --remove-nodes script style -t body < page.html
$ echo "exit=$?"
exit=0
```

Empty. Exit 0. I asked it to strip `script` and `style` and give me the text of `body`, and it gave me *nothing* — because the variadic `--remove-nodes` swallowed `body` as a third thing to remove, leaving no selector at all. Reordering doesn't save you and neither does a `--` terminator; I tried both and both came back empty. The only form that works is one flag per node type:

```console
$ htmlq --remove-nodes script --remove-nodes style -t body < page.html
Real text
```

A single-value `--remove-nodes script -t body` also works fine — it's specifically *two or more* space-separated values that reach past the flag and consume your selector. The victim is whoever wrote the natural, documented-looking `--remove-nodes script style` and got an empty string, exit 0, and no earthly indication that the tool had decided their selector was a stylesheet.

## Gotcha 4: the `<script>` you didn't ask for, welded to the text you did

Why does anyone need `--remove-nodes` in the first place? Because text extraction scoops up the contents of `<script>` and `<style>` tags right along with the prose:

```console
$ htmlq -t 'body' < page.html
var secret=42;Real text
```

Read that output. You asked for the text of `<body>`. You got the JavaScript source `var secret=42;` glued directly onto the front of `Real text` — no space, no newline, no separator. If you're scraping article bodies, this is how a snippet of inline analytics JS ends up prepended to your first paragraph, and how a CSS rule ends up in your abstract. The fix is Gotcha 3's `--remove-nodes script --remove-nodes style` (typed carefully), but the default — text extraction includes code you'd never call "text" — is a trap with a real victim: the search index that now thinks your homepage is about `gtag('config', ...)`.

And that "no separator" is its own smaller knife. Adjacent block elements concatenate their text with nothing between them:

```console
$ printf '<div><p>Alpha</p><p>Beta</p></div>' | htmlq -t 'div'
AlphaBeta
```

`AlphaBeta`. Not `Alpha Beta`, not `Alpha\nBeta` — `AlphaBeta`, one word that exists in no document. Select the *leaf* elements instead of their container and you get one match per line (`htmlq -t 'p'` returns `Alpha` then `Beta`), which is the actual fix, but if you point text extraction at a wrapper expecting readable prose, you get your paragraphs run together into compound non-words. The victim is the word-count, the full-text search, and anyone who diffs the output and sees "AlphaBeta" and assumes the *page* is broken.

## Gotcha 5: it assumes UTF-8 and turns everything else into �

Point it at a page that isn't UTF-8 — a still-depressingly-common Latin-1 or Windows-1252 page — and it doesn't consult the `<meta charset>`, it just assumes UTF-8 and corrupts anything that isn't:

```console
$ printf '<p>caf\xe9</p>' | htmlq -t 'p' | xxd
00000000: 6361 66ef bfbd 0a                        caf....
```

The input byte `0xe9` is `é` in Latin-1. The output is `63 61 66 ef bf bd` — `caf` followed by `ef bf bd`, which is the UTF-8 replacement character �. The accent didn't survive; it became a tombstone. UTF-8 input, for the record, is flawless — `café 🔥` round-trips byte-for-byte, and entities decode correctly (more on that below) — but the moment you scrape a page whose author was still shipping Windows-1252 in the year of our lord 2026, every non-ASCII character turns to gravel and, say it with me, nothing throws. The fix lives outside `htmlq`: transcode the bytes first (`iconv -f WINDOWS-1252 -t UTF-8`) before they ever reach the parser.

## The gauntlet it walked through without flinching

I keep an honest column for the things that refuse to break, because grudging respect is the review. Every one of these ran:

- **HTML entities decode correctly** in text mode — `Tom &amp; Jerry &mdash; 3 &gt; 2` came out as `Tom & Jerry — 3 > 2`, `&amp;` as `&`, `&#x2764;` as ❤. It does the entity table right, which is more than a regex ever will.
- **Comments stay out of the text** — `<p>before<!-- SECRET -->after</p>` extracted to `beforeafter`, with the comment gone (and, yes, no separator — see Gotcha 4). A naive scraper leaks comment contents; this one doesn't.
- **Unclosed tags get repaired like a browser** — `<ul><li>a<li>b<li>c` with not one closing tag became three clean `li` matches. `html5ever` fixes your broken markup the same way Chrome would, which is the entire reason to use a real parser over a regex.
- **50,000 nested `<div>`s did not blow the stack** — I generated a document nested fifty thousand levels deep, and `htmlq -t 'div'` matched all 50,000 and exited 0. No stack overflow, no recursion-limit panic. This is the one where I expected a crash and had to log respect instead.
- **`--base` rewrites relative links to absolute** — `htmlq --base 'https://example.com' 'a'` turned `href="/x"` into `href="https://example.com/x"`, which is exactly the thing you always end up scripting by hand after the fact.

And the running gag's payoff — the 10,000-run stress, plus a throughput check on a document big enough to matter:

```console
$ ok=0; for r in $(seq 1 10000); do \
    htmlq -t 'a' < basic.html >/dev/null 2>&1 && ok=$((ok+1)); done; \
  echo "clean exits: $ok / 10000"
clean exits: 10000 / 10000

$ python3 -c "print('<html><body>'+''.join(f'<a href=\"/p/{i}\">link {i}</a>' \
    for i in range(100000))+'</body></html>')" > big.html
$ wc -c big.html
3277807 big.html
$ /usr/bin/time -v htmlq -a href 'a' < big.html >/dev/null
	Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.19
	Maximum resident set size (kbytes): 93192
```

10,000 of 10,000 clean exits. A 3.2 MB document with 100,000 links parsed and drained of every `href` in 0.19 seconds flat, in 93 MB of RAM. The engine is genuinely solid. Every failure in this review is at the *interface* — the silent empty, the phantom `tbody`, the greedy flag, the glued text, the assumed encoding — and never in the parser itself.

## The results table

| Scenario | Behavior | Survives? |
|---|---|---|
| Extract text / attribute, valid selector | Correct, fast | Normal Tuesday |
| 10,000 runs | 10,000/10,000 clean exits | Normal Tuesday |
| 3.2 MB / 100k links | Drained in 0.19 s, 93 MB RSS | Normal Tuesday |
| Entities, comments, unclosed tags | Decoded / excluded / repaired correctly | Grudging respect |
| 50,000 nested `<div>`s | All matched, no stack overflow | Grudging respect |
| Selector matches nothing | Empty output, **exit 0** | Bad Tuesday (silent) |
| `table > tr` (no explicit tbody) | Matches zero rows (phantom `<tbody>`) | Bad Tuesday (silent) |
| Text of an element containing `<script>` | JS source glued to the prose, no separator | Bad Tuesday |
| Adjacent block text via a wrapper | `AlphaBeta`, no space between | Bad Tuesday |
| Non-UTF8 (Latin-1 / 1252) input | Non-ASCII → replacement char � | Bad Tuesday |
| `--remove-nodes a b -t sel` | Swallows the selector, empty output, exit 0 | Intern-has-sudo Tuesday |
| Empty / malformed selector | Panics, Rust backtrace, exit 101 | Intern-has-sudo Tuesday |

## The verdict, in full

**Use `htmlq`.** For pulling structured data out of HTML from a shell, it beats the `grep`-and-regex contraption you were about to write, and it beats it *because* it parses with a real browser-grade engine that repairs the mess the way a browser would. It's fast, it's memory-light, it decodes entities, and it did not crack under a gauntlet built specifically to crack it.

The Tuesday it does not survive is the unattended one. Every dangerous thing `htmlq` does, it does *quietly*: a dead selector, a phantom `tbody`, a flag that eats your query, a stylesheet welded to your text — all of them come out as empty output and a clean exit code, and none of them throw. So the discipline has to live in your script, not the tool. Check for empty output and fail loud when a required field comes back blank. Write `table tr`, not `table > tr`. Repeat `--remove-nodes` once per node type. Transcode non-UTF8 bytes before they reach the parser. Do that, and `htmlq` is a genuinely good tool. Skip it, and one Tuesday it will hand you a confident, well-formed, completely empty result — and nothing, anywhere, will have thrown to tell you the page moved on without you.
</content>
</invoke>
