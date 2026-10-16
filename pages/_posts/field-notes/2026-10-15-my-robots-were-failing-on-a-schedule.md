---
title: "My robots were failing on a schedule, and the schedule was the bug"
description: "An October audit of my GitHub Actions fleet found a job that failed 116 runs in a row, crons firing into a billing wall, and AI loops fighting over one 429."
date: 2026-10-15
preview: /images/previews/my-robots-were-failing-on-a-schedule-and-the-sched.svg
categories: [Field Notes]
tags: [ci-cd, automation, ai]
author: amr
excerpt: "A cron never gets tired, never gets discouraged, and never notices that it has failed 116 times in a row. That's the selling point, and it's also the problem."
---
A cron job is the most loyal employee you will ever have. It shows up at `13 */4 * * *` whether or not there is any work, whether or not the last six attempts caught fire, and whether or not anyone is still paying for the building. On October 14 I sat down to count what that loyalty was costing my fleet of repos, and the answer was a little embarrassing.

This is the field note from that audit. Every number below comes from the pull requests that came out of it, which quote their own evidence window (September 14 to October 14). Where a number is an estimate, the PR says so, and so do I.

## The job that failed 116 times and kept its shift

The headline find lives in `year-of-ai/year-of-ai.github.io`. Its orchestrator dispatches a `grow-lineage.yml` workflow about four times a day. In the 30-day window it ran 124 times. Eight of those succeeded early on. Then it failed **116 runs in a row**, every one at the same step: "Fail loudly if the growth tick produced no content."

It did fail loudly. It failed loudly 116 times, into a log nobody was reading, and each failure kicked off a telemetry ledger run of its own (124 more runs, 45 of them cancelled). The PR puts the bill at roughly 550 wall-minutes plus the Claude quota every tick burned on its way to producing nothing.

The fix in [year-of-ai.github.io#138](https://github.com/year-of-ai/year-of-ai.github.io/pull/138) is not a fix to the generator. It's a gate. Scheduled dispatch now only happens when the repo variable `GROW_LINEAGE_ENABLED` is `'true'`, and it's unset, so it's off. A manual run with `trigger_growth: true` still works, so whoever fixes the generator can test it by hand. While paused, the log prints which repos it *would* have grown.

The lesson I keep relearning: "fail loudly" is only loud if someone is in the room. A failing scheduled job with no human on the other end is a space heater.

## Crons firing into a billing wall

The private half of my fleet has been sitting behind an account-level Actions billing block, tracked in [bamr87/bamr87#268](https://github.com/bamr87/bamr87/issues/268). The job never starts. There's no log. The only evidence is an annotation on the check run: *"The job was not started because recent account payments have failed or your spending limit needs to be increased."*

The crons did not care. They kept firing, and every refusal showed up as one more red X in a dashboard that was already hard to read. So a batch of PRs ([drsai#33](https://github.com/bamr87/drsai/pull/33), [cv#13](https://github.com/bamr87/cv/pull/13), [git-with-the-program#18](https://github.com/bamr87/git-with-the-program/pull/18), [law-ai#163](https://github.com/bamr87/law-ai/pull/163), [gitorio#127](https://github.com/bamr87/gitorio/pull/127)) comments out the `schedule:` blocks in those private repos, keeps the original cron lines verbatim in the comments, and adds `workflow_dispatch` where a workflow had none so it can still be run by hand.

I like the shape of this one more than the savings. Nothing is disabled through the API. Nothing changes in repo settings. The pause is a diff, which means the un-pause is a diff too, and both are reviewable.

## "Every four hours" was a guess I never revisited

Here on lifehacker.dev, `auto-merge.yml` and `auto-update.yml` each ran every four hours. [lifehacker.dev#701](https://github.com/bamr87/lifehacker.dev/pull/701) counted 248 runs of each in 30 days, 185 of them from the schedule, and `auto-merge` was green on 247. That's a very reliable workflow doing very little: a `workflow_run` trigger on the pipeline already fires whenever a PR can actually turn green.

Both are now a daily backstop. The PR estimates about 155 runs a month saved per workflow. That's an estimate from the run counts, not a measurement after the fact, and I'll find out in November whether it held.

The hub repo got the same treatment in [bamr87#353](https://github.com/bamr87/bamr87/pull/353): `git-digs.yml` was gated on a `GIT_DIGS_ENABLED` variable that was unset, so 17 of 17 runs in the window were skipped. Skipped runs are cheap, but they're not free, and they're noise. The schedule is commented out now, in the workflow and in the fleet registry, because the hub's own tests insist the two agree.

## The docs-only commit that ran the whole test suite

Fifteen repos call the shared `standard-ci.yml` gate in the hub. The audit found that only one caller (this site) had any `paths-ignore`, so a README typo fix ran full CI everywhere else. A reusable workflow can't take `paths-ignore`, so [bamr87#354](https://github.com/bamr87/bamr87/pull/354) makes the gate decide for itself: a small `changes` job lists the changed files through the compare API, and if every one matches the docs patterns, the `ci` job is skipped. A skipped job still satisfies a required check.

The part I'd steal for any shared gate is that it **fails open**. Unknown base, compare error, a diff over 300 files, an event it doesn't recognize: all of those run CI as before. A skip optimization that fails closed is a way to merge broken code faster.

How much does this save? Unknown. The review guessed 20 to 40 percent of caller runs are docs-only, and the PR labels that "unmeasured." I'm leaving it that way here too.

That change, plus the stricter dependency installs that landed earlier, became `v2.0.0` of the gate, and a sweep of caller PRs (it-journey, lifehacker.dev, ai-seed, zer0-pages and others) moved from `@main` to `@v2`.

## Thirty AI loops, one subscription, same alarm clock

The other half of the waste wasn't Actions minutes. It was the Claude subscription that the fleet's AI workflows share. [bamr87#348](https://github.com/bamr87/bamr87/issues/348) documents the hub's daily issue pipeline losing whole tiers to HTTP 429 `usage_limit_reached` on busy mornings: on October 12, tier 2 had spent 35 turns ($1.15 metered) when the limit hit, and that work was thrown away.

The cause was boring. Fleet AI schedules were clustered in 05:00 to 11:00 UTC, the same window the hub's own loops use. Everyone set their alarm for the same time and then fought over the bathroom.

The fix follows a rule the hub already wrote down in `_data/fleet.yml` and nobody downstream was obeying: the hub owns 02:00 to 10:59 UTC, fleet AI crons go from 11:00 onward, off the hour. The 30 scheduled fleet AI workflows now get distinct slots 30 minutes apart, from 11:10 to 01:40 UTC. Frequencies didn't change, and the original order is preserved, so scouts still run before factories.

## The error message that told me to rotate a valid token

One more, because it's my favorite kind of bug. Before the stagger, a 429 produced a run record with `total_cost_usd == 0` and empty model usage. The classifier in the hub's workflows looked at exactly that shape and announced: **the Claude credential was REJECTED (expired or revoked), rotate it.**

The credential was fine. The account was out of session. [bamr87#334](https://github.com/bamr87/bamr87/pull/334) adds a branch that checks for `api_error_status: 429` or limit language first and reports "usage limit hit, the credential is valid, here is the reset time." The same classifier was copy-pasted in six places, and all six got the patch.

A wrong diagnosis is worse than no diagnosis. No diagnosis makes you look. A confident wrong one sends you off to rotate secrets at 6 a.m.

## A correction I'm leaving in

During the cleanup, the `standard-ci` pin PR on this repo ([#702](https://github.com/bamr87/lifehacker.dev/pull/702)) was merged while it was still a draft. The first report blamed the auto-merge workflow. That was wrong: the timeline shows `ready_for_review` and then `merged` five seconds later, both by my own account, and the PR didn't carry any of the labels the auto-merge sweep looks for. [#703](https://github.com/bamr87/lifehacker.dev/pull/703) adds an explicit draft check to auto-merge anyway, as defense in depth, and says plainly in its description that it would not have prevented #702.

I'm keeping that in because it's the most useful sentence in the whole audit. The tempting story was "the robot did it." The timeline said otherwise.

## What I'd tell you to check in your own repos

- List every scheduled workflow and its last 30 days of conclusions. Anything with a long unbroken streak of the same failure is a candidate for a gate, not a retry.
- If a cron's work is already covered by an event trigger, demote the cron to a daily backstop.
- Pause with a diff (commented `schedule:`, kept `workflow_dispatch`, a repo variable as the switch), not with a settings toggle nobody will remember.
- If several jobs share a rate-limited resource, give them slots, not the same top-of-the-hour.
- Read your error classifiers as carefully as your code. They're the part that tells a tired human what to do.

None of this made the fleet do more. It made it stop doing things that weren't working, on a schedule, forever. Some of these PRs are still waiting on me; the rest are merged, and November's run counts will tell me whether the estimates were honest.
