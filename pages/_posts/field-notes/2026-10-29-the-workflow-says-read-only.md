---
title: "My workflow says contents: read. The robot it summons brings its own key."
description: "My @claude workflow is read-only on paper. On Aug 8 its bot pushed a commit anyway. The real ceiling is a second token, minted over OIDC."
date: 2026-10-29
preview: /images/previews/my-workflow-says-contents-read-the-robot-it-summon.svg
categories: [Field Notes]
tags: [ci-cd, ai]
author: cass
excerpt: "The permissions block says read-only and the run log agrees. Then claude[bot] pushed a commit from inside that run, because it brought its own key."
---
Assume breach. Today the suspect is a YAML block that has never told me a lie, because it has only ever told me half the truth.

Nobody threat-models the `permissions:` block. It is the part of a GitHub workflow you read first in review, because it is short, and because it is the one place that promises to tell you the worst a job can do. Here is the one in this site's `@claude` mention handler, `.github/workflows/claude.yml`:

```yaml
permissions:
  contents: read
  pull-requests: read
  issues: read
  id-token: write
  actions: read
```

Read-only on every axis that matters. The run log agrees. This is the header from a real run on 2026-08-08, printed by the runner itself:

```console
GITHUB_TOKEN Permissions
Actions: read
Contents: read
Issues: read
Metadata: read
PullRequests: read
```

And here is what that read-only job did two minutes later, on PR #429:

```console
$ gh api repos/bamr87/lifehacker.dev/pulls/429/commits --jq '.[] | [.sha[0:7], .commit.author.date, .commit.author.name, (.commit.message|split("\n")[0])] | @tsv'
b457632	2026-08-08T08:05:48Z	lifehacker-triage[bot]	triage: refresh queue + health dashboard
e9f3299	2026-08-08T23:04:58Z	claude[bot]	fix(triage): unwrap SITE_HEALTH.md prose, fix generator root cause
```

A commit, authored by `claude[bot]`, at 23:04:58, from inside a run that went from 23:02:16 to 23:05:17 under a token that cannot push. Every convenience feature is an attack surface with better marketing, and this one's marketing is so good it's printed in the log.

> **SEVERITY:** a second key. **ATTACK VECTOR:** the line in the permissions block that looks like it's about something else.

## The line that is about something else

It's `id-token: write`. It doesn't grant the job any repository power. It lets the job ask GitHub for an OIDC identity token, a signed note that says "I am a workflow run in bamr87/lifehacker.dev." `anthropics/claude-code-action` takes that note to Anthropic's token-exchange endpoint and trades it for a **Claude GitHub App installation token**. From then on, that token does the work. The run log narrates the swap:

```console
Requesting OIDC token...
OIDC token successfully obtained
Exchanging OIDC token for app token...
App token successfully obtained
Using GITHUB_TOKEN from OIDC
```

That last line is the whole post. Every environment variable called `GITHUB_TOKEN` in the agent's world now holds the App's token, not the job's. In the action's source (`src/github/token.ts`, read at `main` `d70510b`; this site pins `@v1`, and the log lines above come from the `@v1` runs), the only way to skip the swap is to pass `github_token:` yourself (`Using provided GITHUB_TOKEN for authentication`). This workflow doesn't. When you do ask for extra scopes, the default set it requests is `contents: write`, `pull_requests: write`, `issues: write`. With none asked for, as here, it sends no list at all and takes what the exchange hands back. On Aug 8, that was enough to push.

So the job's `permissions:` block is accurate. It describes a token nobody uses. The real ceiling for this job is whatever the Claude GitHub App was granted when it was installed on the repository, and that lives in the repo's settings, not in a file a reviewer reads. I tried to read it from here:

```console
$ gh api user/installations
gh: You must authenticate with an access token authorized to a GitHub App in order to list installations (HTTP 403)
```

So I can't print the App's grant for you. What I can print is what it did: a push and a comment edit (the "Claude finished @bamr87's task in 2m 21s" note on #429), neither of which `contents: read` and `issues: read` allow.

## Who gets to summon it

The workflow's front door is one `if:` clause. Simplified, it's `contains(github.event.comment.body, '@claude')`, repeated for review comments and issues. GitHub's `contains()` is a case-insensitive substring test. The action then runs its own, stricter check, a regex from `src/github/validation/trigger.ts` that wants `@claude` as a whole word. Two gates, two definitions of "mentioned." I put them side by side in a little Node script, using the real texts from this repo (the three comments that started real work, the two issue bodies that started runs) plus some made-up strings:

```console
$ node two-gates.mjs file:data/pr-429-comment.txt file:data/pr-444-comment.txt file:data/pr-478-comment.txt file:data/issue-685.txt file:data/issue-423.txt "Original report by @claude[bot]" "cc @Claudette for the design review" "send logs to ops@claude.example" "@CLAUDE fix it" "(@claude) fix it"
workflow-if  action  text
PASS         PASS    pr-429-comment.txt
PASS         PASS    pr-444-comment.txt
PASS         PASS    pr-478-comment.txt
PASS         -       issue-685.txt
PASS         -       issue-423.txt
PASS         -       "Original report by @claude[bot]"
PASS         -       "cc @Claudette for the design review"
PASS         -       "send logs to ops@claude.example"
PASS         PASS    "@CLAUDE fix it"
PASS         -       "(@claude) fix it"
```

The two issues are the funny part. Both are work orders the bot filed itself, and both were later edited so the bot's original report sits in a `<details>` block whose summary reads `Original report by @claude[bot]`. When the owner assigned them, the `issues: assigned` event fired, the workflow's substring gate saw the bot's own name tag, and it started a runner. The action looked at the same text, found no whole-word mention, and stood down. Here's the order it did things in on #685, 2026-10-08:

```console
No trigger was met for @claude
Auto-detected mode: agent for event: issues
Requesting OIDC token...
App token successfully obtained
Checking permissions for actor: bamr87
Actor has write access: admin
Trigger result: false
No trigger found, skipping remaining steps
```

It minted the write-capable key first, then checked who was asking, then decided there was nothing to do, then revoked the key. That order is in the source too: `prepare.ts` calls `setupGitHubToken()` on line 37 and `checkWritePermissions()` on line 44. The run is green. Exit 0 is not success. It's a robot that answered a doorbell its own name tag rang.

Across the 797 runs of `claude.yml` the API still lists (2026-07-17 to today), 791 were skipped by the `if:`. Six got through. Four were real: the owner typed `@claude` on a PR, three runs did work and one failed on a missing file. The other two were the bot's own name tag.

## Now let me escalate this properly

A three-letter agency wants write access to a satirical Jekyll site. It can't break the OIDC exchange, so it does the patient thing. It recruits a sleeper agent, who spends eleven years becoming a trusted collaborator by fixing typos in hack posts. On the day of the operation the agent types the activation phrase, which it turns out is `@claude`, and the robot shows up holding a key the YAML swore it didn't have. The agency now controls the cover art for a post about `cd -`.

## Walking it back

Here is the honest version. Nobody here has an exploit, and I'm not describing a flaw in the action. It does what its docs say: it uses the App's token unless you give it one, and before it does anything a stranger asked for, it checks that the person asking has write access. Anyone who can pass that check can already push to this repo by hand. The App token is masked in logs and revoked at the end of the job. A stranger typing `@claude` should get a red X, per the source: `Actor does not have write permissions to the repository`. I didn't stage a stranger to watch it happen, so that's the code's word, not mine.

What should actually bother you is the review. If you approve a workflow change by reading its `permissions:` block, you're approving the wrong token. The block on this job says read-only, the log says read-only, and the bot pushed. For a prompt-driven agent working on issue text and comments, that's the number you most want to be true.

## The three mitigations that matter, ranked

**1. Find every job with a second key, and write its real ceiling down.** This is the audit I ran. It lists every job that uses `claude-code-action` without a `github_token:` input, meaning jobs where the declared permissions aren't the ones in use:

```ruby
#!/usr/bin/env ruby
# List every job that runs claude-code-action WITHOUT a github_token: input.
require 'yaml'

dir = ARGV[0] || '.github/workflows'
Dir.glob(File.join(dir, '*.y{a,}ml')).sort.each do |path|
  wf = YAML.safe_load(File.read(path), aliases: true) || {}
  (wf['jobs'] || {}).each do |name, job|
    perms = job['permissions'] || wf['permissions'] || '(repo default)'
    (job['steps'] || []).each do |step|
      next unless step['uses'].to_s.start_with?('anthropics/claude-code-action')
      with = step['with'] || {}
      next if with.key?('github_token')
      oidc = perms.is_a?(Hash) && perms['id-token'] == 'write'
      shown = perms.is_a?(Hash) ? perms.reject { |k, _| k == 'id-token' }.map { |k, v| "#{k}:#{v}" }.join(' ') : perms
      puts format('%-34s %-6s oidc=%-3s declared: %s', File.basename(path), name, oidc ? 'yes' : 'no', shown)
    end
  end
end
```

```console
$ ruby second-token-audit.rb .github/workflows
claude.yml                         claude oidc=yes declared: contents:read pull-requests:read issues:read actions:read
factory--issue-factory-1.yml       line   oidc=yes declared: contents:read actions:read issues:write
factory--issue-factory-2.yml       line   oidc=yes declared: contents:write issues:write pull-requests:write actions:read
```

Three jobs. I checked the latest successful run of each issue-factory job, and both print `Using GITHUB_TOKEN from OIDC` too. For each one, pick a side. Either accept that the App's installation grant is the ceiling, and go read it under Settings, GitHub Apps, Claude, Configure (I couldn't from here). Or pass `github_token: ${{ github.token }}`, which per the source takes the `OVERRIDE_GITHUB_TOKEN` branch and skips the exchange, so the `permissions:` block becomes true. Then grant the writes the agent really needs, explicitly, where a reviewer can see them. That second path I verified in the source, not in a live run.

**2. Check who's knocking before you start the runner.** The action checks write access, but only after a runner has booted and a key has been minted. The workflow can refuse earlier. Add an `author_association` clause next to the `contains()`, for example `contains(fromJSON('["OWNER","MEMBER","COLLABORATOR"]'), github.event.comment.author_association)`, plus the matching `github.event.review` and `github.event.issue` fields for the other events. I fed the real associations of all six runs that got past `if:` through that clause:

```console
$ node assoc-gate.mjs
with-gate  assoc        run                     what it did
RUN        OWNER        #429 comment            pushed e9f3299
RUN        OWNER        #444 comment            worked 4m57s
RUN        OWNER        #478 comment            worked 7m04s
RUN        OWNER        PR comment 2026-08-17   failed (missing file)
skip       CONTRIBUTOR  #423 issue (assigned)   minted token, did nothing
skip       CONTRIBUTOR  #685 issue (assigned)   minted token, did nothing
```

All four real requests survive and both phantom runs are refused before a key exists. That's an emulation of the clause against the API's real values, not a deployed workflow. One trade-off to know: on `issues` events, `issue.author_association` belongs to whoever wrote the issue, not whoever assigned it, so a bot-filed issue can't summon the bot even when the owner assigns it. Here that's the behavior you want. `claude.yml` is seeded from the hub's agent-context kit, so this change goes to the template, not to a hand edit here.

**3. Write the bot's name without the doorbell.** The cheapest fix ships in prose: write `claude[bot]`, not `@claude[bot]`. This repo's own `AGENTS.md` already says to write a bare `@name` only for a login you mean to notify. Same matcher, same text, one character removed:

```console
$ node two-gates.mjs "Original report by @claude[bot]" "Original report by claude[bot]"
workflow-if  action  text
PASS         -       "Original report by @claude[bot]"
-            -       "Original report by claude[bot]"
```

The edit that added that provenance line doesn't come from any file in this repo, so the fix belongs to whatever wraps the reports. Until then, it's one character, and it saves you a runner and a write key.

None of the three is "be more careful." Careful is exactly how I read a permissions block, agreed with it, and was wrong.

The YAML never lied, by the way. It answered the question I asked, "what can this job's token do?" I should have been asking "which token is doing the work?"
