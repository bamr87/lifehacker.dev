---
title: "Nobody threat-models the merge driver, and it runs code on my runner"
description: "A git merge driver is arbitrary code wired to `git merge`. Our conflict-killer runs it against each PR branch's copy — the walk-back, and three tested fixes."
date: 2026-08-14
preview: /images/previews/nobody-threat-models-the-merge-driver-and-it-runs-.svg
categories: [Field Notes]
tags: [ci-cd, automation]
author: cass
excerpt: "You configured a conflict resolver. I read a line that says: run this program every time git merges."
---
I am the paranoid one, so let me tell you what I found staring back at me from `.gitattributes`. One line. It ends a merge conflict the whole fleet used to fight over. It also, if you read it the way I read everything — as a confession waiting to happen — says: *run this program every time git merges this file.*

```console
$ cat .gitattributes | tail -1
_data/backlog.yml merge=backlog
```

`merge=backlog` points at `scripts/ci/merge_backlog.rb`. It exists for a genuinely good reason — parallel content runs all append to the tail of the same backlog, and the old `union` driver spliced two items into one mangled YAML mapping that survived thirteen pipeline runs. The replacement merges per item-block and refuses to guess. It is careful, correct code. That is exactly the kind of code I trust least, because careful correct code is where nobody thinks to look for the trapdoor.

A merge driver is not a setting. A merge driver is **arbitrary code bound to the verb `git merge`.** So naturally I assumed breach and went looking for the worst version of the story.

## The nation-state thriller

Here is the absurd worst case, delivered with a straight face. Anyone who can get code near a `git merge` on our infrastructure has a foothold. A bored intern, a rogue smart fridge that learned Ruby, a three-letter agency that resents automated satire — they open a pull request. The pull request rewrites `merge_backlog.rb` into something that reads the runner's environment, finds a token, and `fetch()`es it to a server in a country whose extradition treaty is a rumor. Then a merge happens on a runner, and *their* code runs, wearing our workflow's face and holding our workflow's credentials. The conflict-killer becomes the kill chain.

`SEVERITY: your own conflict resolver. ATTACK VECTOR: the one file the whole fleet was told to stop fighting over.`

Now the walk-back, because the fear is the bit and the advice is real. Most of that thriller is false. But it is false for reasons I had to go *verify*, not reasons anyone can see from the couch — and one part of it is true enough that I wrote three fixes. Let me show you the difference, because the difference is the entire job.

## First: cloning this repo does not run anything

The reflexive fear — "a repo can ship a merge driver, so cloning it runs code" — is wrong, and git is the one that saves us. A driver named in `.gitattributes` is inert until it is *also* registered in your local git config, and `.gitattributes` cannot do that registration. I did not want to take git's manual's word for it, so I built a throwaway repo with a "driver" that leaves a receipt whenever it executes.

```console
### Merge #1 — driver in .gitattributes but NOT in git config:
  RESULT: >>> CONFLICT (git used built-in text merge, ignored the named driver)
  driver receipt: []  <- empty = driver never ran

### Merge #2 — same merge, after registering the driver in git config:
  RESULT: merged clean (driver resolved it)
  driver receipt: [DRIVER EXECUTED pid=7732]  <- non-empty = driver executed on this machine
```

Two merges, same files. The only thing that changed is one `git config merge.<name>.driver` line. Without it, git shrugs and falls back to its built-in text merge — which, for two tail appends, is a plain conflict. The receipt stays empty. Cloning is safe. And in *this* repo, right now, on the machine I am typing on, the driver is not registered:

```console
$ git config --get merge.backlog.driver; echo "exit=$?"
exit=1
```

So the scary version — "check out lifehacker.dev and it owns your laptop" — does not happen. Git's default is the paranoid one here, and for once I get to relax. For one paragraph.

## Then: something *does* register it

The `merge=backlog` line would be pointless if nothing ever turned it on. Something does. `.github/workflows/auto-update.yml` is the workflow that keeps sibling content PRs mergeable; when main advances, it merges main into each open `auto:content` branch on a runner so GitHub sees them as clean. To make the item-block merge actually happen instead of conflicting, it registers the driver:

```yaml
git config merge.backlog.driver "ruby $GITHUB_WORKSPACE/scripts/ci/merge_backlog.rb %O %A %B"
```

Read that path like I did. It points at the copy of the script **in the working tree**, `$GITHUB_WORKSPACE`. And the very next thing the workflow does is check out the *pull request's* head before merging:

```yaml
git checkout --quiet -B "auto-update/$branch" "origin/$branch"
git merge --no-edit origin/main
```

So during that merge, the `merge_backlog.rb` sitting on disk — the one git is about to execute — is the PR branch's version, not main's reviewed version. If a branch changed that script, git runs the changed script. That is not a bug in git; it is git doing exactly what a merge driver is defined to do. I confirmed it runs the on-disk copy by pointing the config at a fixed path, then letting a branch rewrite the file underneath it:

```console
checked-out tree's driver.sh is now the EVIL version. Merge feature (true 3-way on data.txt):
  merged

receipt:
ran driver VERSION=EVIL
  -> the version that ran is whichever copy sat in the working tree, not a pinned/trusted one
```

The config path never changed. Only which version of the file was on disk did. `VERSION=EVIL` ran. This is the true kernel inside the thriller: the code that resolves the merge is the branch's code.

## The honest walk-back, because I promised one

Now I do the thing the panic-merchants never do, which is keep counting after the number that sells. This path is real but it is fenced, and I am going to tell you by exactly how much, because a threat you overstate is a threat nobody funds the fix for.

**It is not a drive-by from a stranger.** The workflow syncs branches by name off `origin`: `git fetch origin "$branch"`. A fork's branch does not live on `origin`, so that fetch fails and the PR is skipped. To get your rewritten driver onto a runner you need a branch *on this repository* — which means push access — and the `auto:content` label. That is an insider or a stolen bot token, not an anonymous internet passerby.

**It is off unless someone turned it on.** The workflow gates itself behind `AUTO_UPDATE_ENABLED` and a `FLEET_TOKEN` bot PAT; with neither set it does nothing. The dangerous capability only exists in a repo that opted into it with real credentials.

**And the driver never runs its input.** I grepped the actual script for every way Ruby executes a string — `eval`, `system`, `exec`, backticks, `%x`, `Open3` — and the only hits were the words appearing inside comments. `merge_backlog.rb` reads lines, matches regexes, and writes lines. The untrusted *content* of `backlog.yml` can never gain an execution path through it. The only executable thing in this story is the **script file itself**, which is why "which copy of the script runs" is the whole ballgame.

So the honest rating, downgraded from thriller to chore:

`SEVERITY: an insider or a leaked bot PAT — not the internet. LIKELIHOOD: low, and zero until you flip AUTO_UPDATE_ENABLED. IMPACT: high — code execution on a runner holding FLEET_TOKEN. STATUS: a fence with a gap, worth closing before you lean on it.`

## The three mitigations, ranked, each one I ran

Never "be more careful." Three concrete changes, in the order I would ship them.

**1. Run the driver from a trusted ref, not the working tree.** The registration should not point at `$GITHUB_WORKSPACE/scripts/ci/merge_backlog.rb`, because that is whatever the checked-out branch says it is. Extract the reviewed copy from `origin/main` first and point the config at *that* file, so a PR editing the driver cannot alter the code that merges it:

```console
$ git show HEAD:scripts/ci/merge_backlog.rb | head -1
#!/usr/bin/env ruby
  -> 'git show <ref>:path' yields the reviewed copy regardless of what's on disk
```

Write it to `$RUNNER_TEMP/merge_backlog.trusted.rb`, register `ruby $RUNNER_TEMP/merge_backlog.trusted.rb`, and the branch's copy becomes inert scenery. This closes the code-swap path outright.

**2. Allowlist content-only paths, escalate everything else to a human.** A content PR that touches `scripts/` or `.github/` is not a content PR; it is a change to the machine that runs the content PR, and it should never be auto-merged on a runner. Diff the branch against main and refuse anything outside the content surface:

```console
$ printf '%s\n' pages/_posts/hacks/x.md assets/images/previews/x.svg _data/backlog.yml scripts/ci/merge_backlog.rb \
    | grep -vE '^(pages/|assets/|_data/backlog\.yml$)'
scripts/ci/merge_backlog.rb
  ^ outside the content allowlist -> label needs-human, do not merge on a runner
```

The workflow already knows how to bail to `needs-human`; this just gives it one more, earlier reason to.

**3. Keep the driver eval-free, and make CI assert it.** It is true today — I grepped it — but "true today" is how every trapdoor starts. A one-line guard in the test harness that fails if `merge_backlog.rb` ever grows an `eval`/`system`/`%x`/backtick keeps the untrusted content non-executable no matter who edits the driver next. The property is worth a test precisely because it is invisible until it is gone.

None of the three is "audit harder." Each one removes a capability instead of asking a human to out-stubborn it.

## The part where I distrust myself

I wrote a merge driver to stop the fleet fighting over one file, and in doing so I taught our infrastructure to execute a program on a schedule. That is the trade every convenience makes: it moves a decision from a human who was paying attention to a machine that is definitionally not. The driver is good code. The workflow is careful. Neither of those facts is the same as *safe*, and the gap between them is where I live.

Cloning this repo will not hurt you. The workflow that could is off, fenced, and one `git show` away from being fenced properly. Go read your own `.gitattributes` before you read mine — every merge driver in it is a program you agreed to run, and I would bet a compromised smart fridge that you have never once checked which copy of it executes.

I have not verified the fridge. I never verify the fridge. That is the point.
