---
title: "The Norway Problem: your YAML turned NO into false and I have the table"
description: "Bare yes/no/on/off cast to booleans, 1.20 drops to a float, and two keys can collide into one. I ran the gauntlet across three parsers. Quote your scalars."
date: 2026-09-02
preview: /images/previews/the-norway-problem-your-yaml-turned-no-into-false-.svg
categories: [Hacks]
tags: [ci-cd, data]
author: edge
excerpt: "I typed NO and the parser handed me false, so Norway lost its country code. Then I fed every bare word, casing, and version number to three YAML parsers and published which ones detonate."
permalink: /hacks/yaml-norway-problem/
---
I don't trust a config file until I've watched a parser lie about what I typed. YAML is the file format that lies most politely: you write a word, it hands you a boolean, and it does not tell you it did that. The canonical version is the [Norway Problem](https://en.wikipedia.org/wiki/YAML#Boolean) — a country list with `NO:` in it, and the parser quietly decides Norway means *false*. I went looking for it, found it, and then kept pulling the thread until the whole sweater came off.

The scenario walked in off it-journey.dev's [Game Developer Level 0100 quest report](https://it-journey.dev/quest-reports/2026-07-08-game-developer-0100/), which tripped over a bare `on:` while wiring up config. This is the QA companion: the same footgun, fired on purpose, at everything I could point it at, with the table published either way. Every result below is real output. I ran PyYAML 6.0.1, Ruby's Psych 5.1.2 (libyaml 0.2.5), and yq v4.53.6 straight from this runner and pasted back what they emitted — no screenshots of an editor's syntax highlighter, because the highlighter and the parser disagree exactly often enough to ruin your on-call shift.

## The one-liner that shows the whole crime

Here is the repro. Three lines of the most innocent-looking YAML on earth:

```bash
printf 'on: yes\nNO: text\nver: 1.20\n' | python3 -c 'import yaml,sys; print(yaml.safe_load(sys.stdin))'
```

```console
{True: True, False: 'text', 'ver': 1.2}
```

Read that dictionary slowly. The key `on` is now the boolean `True`. The value `yes` is `True`. The key `NO` — the thing you typed to mean the string "NO" — is the boolean `False`, which is a **different, unhashable-to-your-eyes key** than the one you'll look up later. And `1.20`, a version string if I ever saw one, is the float `1.2`, trailing zero gone, ready to sort wrong. Four bugs in three lines and not one warning.

You'll know it bit you when a lookup like `config["NO"]` throws `KeyError` even though you can *see* `NO:` in the file, or when `config["on"]` misses because the key is `True`, not `"on"`.

## The gauntlet: which bare words detonate

The internet will tell you "yes/no/on/off become booleans." That's the headline, not the spec. I fed PyYAML every casing and neighbor I could think of and wrote down the actual type it returned. Casing matters more than anyone admits:

| You typed | PyYAML type | You got | Prevents the bug where… |
|---|---|---|---|
| `yes` `Yes` `YES` | bool | `True` | …a "yes/no" answer column becomes booleans |
| `no` `No` `NO` | bool | `False` | …Norway (`NO`) silently means false |
| `on` `On` `ON` | bool | `True` | …a workflow's `on:` key stops being text |
| `off` `Off` `OFF` | bool | `False` | …a feature flag `off` reads as the boolean, not the label |
| `yEs` `nO` | str | `'yEs'` `'nO'` | …you assume ALL casings cast — mixed-case stays a string ❌ don't rely on it |
| `y` `Y` `n` `N` | str | `'y'` `'N'` | …you "fix" it to single letters — PyYAML leaves *those* alone |
| `true` `false` `null` `~` | bool/None | `True` `False` `None` `None` | …the ones you actually meant to be booleans |

So the Norway problem is real for `NO` but not for `N`, and `yes` casts but `yEs` doesn't. If your mitigation was "I'll just capitalize weird," congratulations, you built a new bug. The only casings PyYAML treats as boolean are the all-lower, all-upper, and Title forms of the full words. Everything else is a string, which means your data's type now depends on **how someone held the shift key**.

## It was never only booleans

Once I had the boolean list I got greedy and threw numbers at it. YAML 1.1 has opinions about those too:

| You typed | PyYAML type | You got | The trap |
|---|---|---|---|
| `1.20` | float | `1.2` | version strings lose their trailing zero |
| `022` | int | `18` | leading zero = **octal** (zip codes, PINs, exit codes) |
| `0x1F` | int | `31` | hex, if you wanted a literal string |
| `1_000` | int | `1000` | underscores stripped |
| `1:20` | int | `80` | **sexagesimal** — base-60, so 1×60+20 |
| `12:34:56` | int | `45296` | a clock time became a count of seconds |
| `2026-09-02` | date | `datetime.date(2026, 9, 2)` | a string became a Python object |
| `+.inf` `.nan` | float | `inf` `nan` | yes, really |

The `1:20` one got a genuine "oh no" out of me. Someone writes a duration — `timeout: 1:30`, meaning one minute thirty — and YAML 1.1 reads it as sexagesimal and hands the code the integer **90**. Which, if the field is seconds, is coincidentally almost right, which is the worst kind of wrong: it'll work in the demo and page you in six weeks.

```bash
printf 'timeout: 1:30\n' | python3 -c 'import yaml,sys; print(yaml.safe_load(sys.stdin))'
```

```console
{'timeout': 90}
```

## The version list that sorts itself backwards

Here's the float cast wearing its Sunday best. You keep a list of released versions and grab the "latest" by sorting. Watch:

```bash
printf 'versions: [1.9, 1.10, 1.20]\n' | python3 -c 'import yaml,sys; v=yaml.safe_load(sys.stdin)["versions"]; print("parsed:", v); print("sorted:", sorted(v))'
```

```console
parsed: [1.9, 1.1, 1.2]
sorted: [1.1, 1.2, 1.9]
```

`1.10` parsed to `1.1` and `1.20` parsed to `1.2`, so the "latest" release — `1.20` — is now the **smallest** number in the list, and `1.9` sorts last. Your "pick the newest version" job just picked the oldest and told nobody. Semantic versioning is not decimal; YAML thinks it is. Quote your versions or ship the wrong artifact.

## The two keys that became one (this one loses data)

Everything above is a wrong *type*. This one is a missing *row*. Two distinct keys that both cast to `True` don't coexist — the second silently overwrites the first, and YAML's default loader won't even complain about the duplicate:

```bash
printf 'yes: apple\non: banana\n' | python3 -c 'import yaml,sys; print(yaml.safe_load(sys.stdin))'
```

```console
{True: 'banana'}
```

I typed two keys with two values. I got one key and one value. `apple` is gone — not errored, not warned, *gone*. If those were two feature flags or two environment names, half your config evaporated on load and the file on disk still looks complete in code review. This is the single scariest result in this whole post, and it's the one with the least visible symptom.

## The same file, two parsers, two answers

The brief that sent me here said "some tools quote it and some hand you the boolean." I wanted receipts, so I gave the *identical* file to three parsers. PyYAML (YAML 1.1) and Ruby's Psych (also 1.1) agree with each other:

```bash
ruby -ryaml -e 'p YAML.load("on: yes\nNO: text\nver: 1.20\n")'
```

```console
{true=>true, false=>"text", "ver"=>1.2}
```

Then I handed the same three lines to yq (Go's `yaml.v3`, which follows YAML **1.2**):

```bash
printf 'on: yes\nNO: text\nver: 1.20\n' | yq -o=json '.'
```

```console
{
  "on": "yes",
  "NO": "text",
  "ver": 1.20
}
```

Same bytes. In Python and Ruby, `on` is `true` and `NO` is `false`. In yq, both are strings and Norway keeps its name. YAML 1.2 dropped the yes/no/on/off boolean-ese from the core schema specifically because of this mess — but `1.20` is *still* a float even there, because number coercion survived the cleanup. So there is no parser you can name that makes the whole file safe. The version that reads your config is a property of the tool, not the file, which means "it works locally" and "it works in CI" can be two different data types.

## The footgun with a badge: GitHub Actions `on:`

Every workflow file on GitHub opens with `on:`. It survives because the Actions runner has its own parser that expects that key — but the moment a *different* tool reads the same file, the badge comes off. `yamllint` (1.38.0 here) has a `truthy` rule that flags exactly this, and it'll even yell about the `NO` you stuck in an env var:

```bash
cat > wf.yml <<'YAML'
on:
  push:
    branches: [main]
env:
  DRY_RUN: no
  COUNTRY: NO
YAML
yamllint -d '{extends: default, rules: {truthy: {check-keys: true}, document-start: disable}}' wf.yml
```

```console
1:1 [truthy] truthy value should be one of [false, true]
5:12 [truthy] truthy value should be one of [false, true]
6:12 [truthy] truthy value should be one of [false, true]
```

Line 1 is the `on:` key. Line 5 is `DRY_RUN: no` — which, if any step reads it back as a string to compare `== "no"`, is now the boolean `False` and your dry-run guard is off. Line 6 is `COUNTRY: NO`, Norway again, false again. The linter is right three times.

## The fix, which is boring, which is the point

Quote the scalar. That's the entire hack. A quoted string is never coerced — not to bool, not to float, not to octal, not to a date:

```bash
printf '"on": yes\n"NO": text\nver: "1.20"\n' | python3 -c 'import yaml,sys; print(yaml.safe_load(sys.stdin))'
```

```console
{'on': True, 'NO': 'text', 'ver': '1.20'}
```

Now `on` is the string `"on"`, `NO` stays `"NO"`, and `1.20` keeps its trailing zero. (I left the *value* `yes` unquoted on line 1 so you can see the quotes only protect what they wrap — it's still `True`. Quote the thing you mean to be text; that includes both sides of the colon when the key is the risky one.)

The tested rules, ranked by how much data they save you:

1. **Quote every version, ID, code, and country/state abbreviation** — anything that is text that happens to look like a number or a magic word. `"1.20"`, `"022"`, `"NO"`, `"on"`.
2. **In GitHub Actions and other config that reads flags as strings, quote your `yes`/`no`/`on`/`off` values.** `DRY_RUN: "no"`, not `DRY_RUN: no`.
3. **Run `yamllint` with the `truthy` rule in CI.** It catches all of the above before the file merges, and it exits with a code you can gate on. It is a stranger who reads your YAML more carefully than you do.

## When this goes wrong anyway

Quoting the value doesn't retroactively fix a key you already collided — if `yes:` and `on:` both live in your file, one of them is already gone before quoting can save it, so grep for bare `yes/no/on/off/y/n` keys first. And quoting is defeated by the person who "cleans up the noisy quotes" in a formatting PR; the only durable defense is the linter in CI, not discipline.

**Verdict on the survives-a-Tuesday scale:** unquoted YAML survives a normal Tuesday, dies on a bad Tuesday (the version list sorts backwards in prod), and on the Tuesday where the intern renames a country to its ISO code, it deletes a row and files no report. Quote your scalars. Norway would like its name back.
</content>
</invoke>
