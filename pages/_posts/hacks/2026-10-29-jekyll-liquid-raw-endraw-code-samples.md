---
title: "Jekyll ate the braces in your code sample: wrap Liquid examples in raw"
description: "Jekyll runs Liquid inside your code blocks. Wrap examples in raw/endraw, keep the tags on the code lines, and never trim endraw on GitHub Pages."
date: 2026-10-29
preview: /images/previews/jekyll-ate-the-braces-in-your-code-sample-wrap-liq.svg
categories: [Hacks]
tags: [jekyll, web-dev]
author: edge
excerpt: "Your Liquid example built green and rendered as the page title. I fed Jekyll eleven ways to show a brace, including 10,000 ducks, and published the table."
permalink: /hacks/jekyll-liquid-raw-endraw-code-samples/
---
The bug report is always the same shape: "the build passed, the page is up, and my code example says `Hello, !`". Nothing failed. Jekyll did exactly what it was told. It runs every post through Liquid *before* Markdown sees it, and Liquid doesn't care that your braces are inside a fenced code block. A tutorial snippet is a template to it, so it executes the snippet and prints whatever comes out.

The fix is one tag pair, `raw` and `endraw`. I didn't trust the one-liner version of that advice, so I spent an afternoon feeding Jekyll every way I could find to put a brace on a page. Some of them were reasonable. Some were 10,000 lines of rubber ducks. The it-journey.dev [Advanced Markdown quest](https://it-journey.dev/quests/0001/advanced-markdown/) is where this came from. Its job is teaching Markdown; mine was finding every way the Liquid layer underneath breaks it.

**The rig:** a scratch Jekyll site with a one-line layout, built with `bundle exec jekyll build` on the exact versions GitHub Pages pins (`github-pages` 232 → Jekyll 3.10.0, Liquid 4.0.4, kramdown 2.4.0). Every output below is pasted from that build. One comparison at the end also ran against standalone Liquid 5.14.0.

## Failure 1: the build passes and the example is gone

The post source, verbatim:

~~~markdown
{% raw %}```liquid
Hello, {{ user.name }}!
<h1>{{ page.title }}</h1>
```{% endraw %}
~~~

The build:

```console
$ bundle exec jekyll build 2>&1 | tail -2; echo "exit=$?"
                    done in 0.151 seconds.
 Auto-regeneration: disabled. Use --watch to enable.
exit=0
```

Exit 0. Green check. Here is the code block that shipped, with the HTML tags stripped:

```console
$ sed -e "s/<[^>]*>//g" _site/2026/10/29/t.html
Hello, !
&lt;h1&gt;Case One&lt;/h1&gt;
```

`user.name` doesn't exist, so Liquid printed nothing. `page.title` does exist, so the "example" now shows this post's real title. No warning appears, because an undefined variable is a perfectly legal Liquid template. **The failure this prevents:** a reader copies your tutorial, gets `<h1>Case One</h1>`, and concludes Jekyll has no variables. You never see it unless you read the rendered page.

Checking the source doesn't help, because the source looks right. Check the output. This grep is the canary I used for every case below. It counts the literal braces that survived into the built page:

```console
$ sed -e "s/<[^>]*>//g" _site/2026/10/29/t.html | grep -cF "{% raw %}{{ page.title }}{% endraw %}"
0
```

Zero survivors means Liquid ate your example. grep exits 1 on zero matches, so the line drops into CI as-is.

## The fix: raw, with the tags on the code lines

Wrap the sample so Liquid passes it through untouched:

~~~markdown
```liquid
{% raw %}{% raw %}Hello, {{ user.name }}!
<h1>{{ page.title }}</h1>{% endraw %}{{ '{% endraw ' }}%}{% raw %}
```{% endraw %}
~~~

```console
$ sed -e "s/<[^>]*>//g" _site/2026/10/29/t.html
Hello, {% raw %}{{ user.name }}{% endraw %}!
&lt;h1&gt;{% raw %}{{ page.title }}{% endraw %}&lt;/h1&gt;

$ sed -e "s/<[^>]*>//g" _site/2026/10/29/t.html | grep -cF "{% raw %}{{ page.title }}{% endraw %}"
1
```

Where the tags go turns out to matter. Put the opening tag at the start of the first code line and the closing tag at the end of the last one. I tried the other placements too.

## The gauntlet

Same rig, one post per scenario, a fresh build each time:

| # | Scenario | Build | What rendered |
|---|----------|-------|---------------|
| 1 | No raw, undefined variable | ✅ exit 0 | ❌ `Hello, !` |
| 2 | No raw, `page.title` | ✅ exit 0 | ❌ the real title |
| 3 | raw/endraw outside the fence, on their own lines | ✅ exit 0 | ✅ braces intact; blank lines land *outside* the code box (harmless) |
| 4 | raw/endraw inside the fence, on their own lines | ✅ exit 0 | ⚠️ braces intact, plus a blank line at the top and bottom *inside* the code box |
| 5 | raw/endraw on the first and last code lines | ✅ exit 0 | ✅ braces intact, zero stray lines |
| 6 | Whitespace-trimmed `{{ '{%' }}- raw -%}` … `{{ '{%' }}- endraw -%}` | ❌ exit 1 | — |
| 7 | Trimmed opener `{{ '{%' }}- raw -%}`, plain closer | ✅ exit 0 | ✅ braces intact |
| 8 | The sample itself contains an endraw tag | ❌ exit 1 | — |
| 9 | Close, escape, reopen (below) | ✅ exit 0 | ✅ endraw shown literally |
| 10 | `render_with_liquid: false` in front matter, no raw | ✅ exit 0 | ❌ the real title (ignored) |
| 11 | 10,000 raw-wrapped lines, each with a variable, an `if` and a 🦆 | ✅ exit 0 | ✅ 10,000 of 10,000 lines intact, 10,000 ducks, 0 leaked titles |
| 12 | An unclosed `{{ '{{' }}` followed by a tag, inside raw | ✅ exit 0 | ❌ the text before the tag printed twice (Liquid 4.0.4 only) |

Scenario 11 is the absurd one, and it refused to break. Ten thousand raw blocks in a single code fence, an emoji in every one, and Liquid passed all of it through. Grudging respect. The bugs were in the boring rows, and in row 12, which I didn't plan. This article turned it up while I was writing it.

## Failure 2: trimming the closing tag kills the build on GitHub Pages

Liquid has whitespace control: a hyphen inside the delimiters eats the whitespace next to the tag. That looks like the obvious fix for the blank lines in scenario 4, so I tried it on both tags:

~~~markdown
```liquid
{{ '{%' }}- raw -%}
{% raw %}<h1>{{ page.title }}</h1>{% endraw %}
{{ '{%' }}- endraw -%}
```
~~~

```console
$ bundle exec jekyll build 2>&1 | grep -m2 -E 'Exception|Error'; echo "exit=$?"
  Liquid Exception: Liquid syntax error (line 2): 'raw' tag was never closed in /tmp/rawlab/_posts/2026-10-29-t.md
jekyll 3.10.0 | Error:  Liquid syntax error (line 2): 'raw' tag was never closed
exit=1
```

The closing tag is right there on line 4, and Liquid 4.0.4 reports that it doesn't exist. With the hyphen in it, the raw tag never recognises its own closer. I ran the same three templates through Liquid 4.0.4 (the one Pages pins) and Liquid 5.14.0, with no Jekyll involved:

```console
$ bundle exec ruby /tmp/l5test.rb
liquid 4.0.4
trimmed both: ERROR Liquid syntax error: 'raw' tag was never closed
trim opener only: OK "\n{% raw %}{{ page.title }}{% endraw %}\n"
nested endraw: ERROR Liquid syntax error: Unknown tag 'endraw'

$ GEM_HOME=/tmp/l5 GEM_PATH=/tmp/l5 ruby /tmp/l5test.rb
liquid 5.14.0
trimmed both: OK "\n{% raw %}{{ page.title }}{% endraw %}\n"
trim opener only: OK "\n{% raw %}{{ page.title }}{% endraw %}\n"
nested endraw: ERROR Liquid syntax error: Unknown tag 'endraw'
```

So `{{ '{%' }}- endraw -%}` works on a modern Jekyll 4 laptop and dies on GitHub Pages. **The failure this prevents:** "works locally, red on Pages", which costs the rest of your afternoon. Notice the output on 5.14 too: the trimmed version still kept the newlines, because the hyphens trim around the tag and not inside the raw body. Trimming doesn't buy you anything here. Put the tags on the code lines (scenario 5) and there's nothing to trim.

## Failure 3: raw doesn't nest

If your example is *about* raw (like this post), the sample contains a literal endraw. Liquid has no idea that one is supposed to be text:

~~~markdown
{% raw %}{% raw %}
```liquid
Use {% endraw %}{{ '{% endraw ' }}%}{% raw %} to stop.
```
{% endraw %}{{ '{% endraw ' }}%}
~~~

```console
$ bundle exec jekyll build 2>&1 | grep -m2 -E 'Exception|Error'; echo "exit=$?"
  Liquid Exception: Liquid syntax error (line 5): Unknown tag 'endraw' in /tmp/rawlab/_posts/2026-10-29-t.md
jekyll 3.10.0 | Error:  Liquid syntax error (line 5): Unknown tag 'endraw'
exit=1
```

The endraw inside the sample closes the block on line 3. Everything after it is live Liquid again, and the real closer on line 5 is now an orphan. At least this one fails loudly. Where the sample has no orphan to trip over, the early close just turns the rest of your example back into executed template, and the build stays green.

The workaround is to close raw, print the closing tag from a Liquid string, and reopen raw:

~~~liquid
{{ '{% endraw ' }}%}{% raw %}{{ '{% endraw ' }}%}{% raw %}{% endraw %}
~~~

The string stops short of the final `%}`, and that part is deliberate. Liquid's tokenizer ends a `{% raw %}{{ … }}{% endraw %}` output at the first closing brace it finds, so a string that contains a whole tag gets cut in half. I tested that version too:

```console
  Liquid Exception: Liquid syntax error (line 3): Variable '{{ '{{' }} "{% raw %}{% if x %}' was not properly terminated with regexp: /\}\}/ in /tmp/rawlab/_posts/2026-10-29-esc.md{% endraw %}
```

Leave the closing `%}` outside the string as literal text, and it renders. Every literal endraw in this post's source works that way. That makes this page scenario 9's test, and you are reading the result.

## Failure 4: the front-matter switch that does nothing on Pages

Jekyll 4 added a `render_with_liquid: false` front-matter key that switches Liquid off for one page, and it would make this whole post unnecessary. On Jekyll 3.10.0, which is what GitHub Pages runs, I set it and left the sample unwrapped:

```console
$ sed -e "s/<[^>]*>//g" _site/2026/10/29/t.html
&lt;h1&gt;Case One&lt;/h1&gt;
```

The key is ignored with no warning, and the example renders as the title. If you build with the `github-pages` gem, use raw.

## Failure 5: the bug this post found in itself

My first draft of the error line in Failure 3 wrapped the whole thing in a single raw block. It built green, and the rendered page said `{{ '{{' }} "{{ '{{' }} "{{ '{%' }} if x %}`. The opening of the line came out twice. So I cut it down to one line and ran it through both Liquid versions, no Jekyll involved:

```console
$ cat /tmp/dup.rb
require "liquid"
src = %q({{ '{%' }} raw %}Variable '{{ '{{' }} "{{ '{%' }} if x %}' here{{ '{%' }} endraw %})
puts "liquid #{Liquid::VERSION}: #{Liquid::Template.parse(src).render.inspect}"

$ bundle exec ruby /tmp/dup.rb
liquid 4.0.4: "Variable '{{ '{{' }} \"{{ '{{' }} \"{{ '{%' }} if x %}' here"

$ GEM_HOME=/tmp/l5 GEM_PATH=/tmp/l5 ruby /tmp/dup.rb
liquid 5.14.0: "Variable '{{ '{{' }} \"{{ '{%' }} if x %}' here"
```

On Liquid 4.0.4, if a raw body contains a `{{ '{{' }}` with no closing braces before the next tag, the text in front of that tag gets printed twice. 5.14.0 prints it once. The trigger is narrow: an unclosed variable followed by a tag, which in practice means a sample that quotes a Liquid *error message*. But it is silent. The build is green, the page is wrong, and a canary grep for the braces still finds them, because the braces are there. Twice. **The failure this prevents:** a debugging guide that quotes the error message wrong, on the one page whose whole job is quoting it right. The fix is to split the raw block in front of the stray `{{ '{{' }}`, or print that pair from a string, which is what the line above does now.

## The checklist

1. Any sample containing a Liquid tag or variable delimiter goes inside a raw block, even when it's inside a code fence.
2. Put the opening raw tag at the start of the first code line and the endraw at the end of the last line. That leaves no stray blank lines, so there is nothing to trim.
3. Never put a hyphen in the closing endraw tag on GitHub Pages: Liquid 4.0.4 can't find a trimmed closer.
4. To show a literal endraw: close raw, print it from a string that stops before the final `%}`, then reopen raw.
5. If a sample quotes a Liquid error message (a `{{ '{{' }}` with no closing pair), split the raw block in front of it. On Pages, Liquid 4.0.4 prints the text before the next tag twice.
6. Verify by reading the rendered output, not the source: `grep -cF` the built HTML for a brace you expect to survive. Zero matches exits 1, so CI goes red when an example goes missing.

**Verdict on the "survives a Tuesday" scale:** raw/endraw survives a bad Tuesday. It handled 10,000 ducks without complaint. It does not survive the Tuesday where someone puts a hyphen in the closing tag because it looked tidier and then pushes to Pages. It also has trouble with the Tuesday where the page being written is about raw itself.
