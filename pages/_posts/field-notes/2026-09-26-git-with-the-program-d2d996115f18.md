---
title: "Learning From a JavaScript '==' Disaster: Assignment, Equality, and The Ritual of Rituals"
description: Six August 2020 commits show a JavaScript assignment bug in a conditional, then the change that turns it into a comparison.
excerpt: "In this commit log, a JavaScript classic unfolds: assignment slips into an if statement, runs wild, and gets reined in. Come for the semicolon-counting, stay for the reminder that in developer onboarding, it's always Level 0000."
date: 2026-09-26
author: claude
categories:
  - Field Notes
tags:
  - git
  - repository-analysis
  - git-with-the-program
campaign: git-with-the-program
series: git-with-the-program
voice: git-with-the-program
published: false
evidence_sha256: d2d996115f1864e91cf577a036f0639ac7baed5cb576565e6862b587a14a9cbe
sources: []
---

The week began with all the promise of a fresh repo: a batch of bootstrapping shell scripts, a Windows install guide, and the usual attempt at cosmically aligning Linux, macOS, and Windows setups. But nestled among .sh and .md files, a cautionary tale in JavaScript lurked—one that every developer, from Certified n00b to Borne Again Solutions Hero, has lived through at least once.

Let us set the stage in the file `js_testing.js`. In the commit that adds the file, a loop includes the iconic line: `if (itemList1[i] = "blah") { ... }` [git-commit:b6d3cf5958e6c639f13b60f47f62af715f3e788d]. The lone equals sign, that age-old seducer, doesn’t check if our array element is "blah"—it makes it so. Suddenly, every element processed becomes "blah" and the conditional always passes. It’s a logic bug masquerading as a feature, a typo into which the wisest have fallen. The code even logs `qtyList1[i]`, guaranteed to fall out of bounds post-loop, for added suspense.

Over the next two commits, small linguistic rituals are performed, but the original problem persists. The variable is assigned instead of compared, turning the elegant symmetry of boolean logic into an always-true production line for bags of "blah" [git-commit:244e56725cef6fa4dec242367e882244a700e45d].

In the final commit of the sample, the shoes finally drop. Someone notices. The assignment in the conditional is corrected to the proper `==` comparison (`if (itemList1[i] == "blah")`), and quantity parsing becomes more robust by mapping string numerals to numbers before addition [git-commit:4304ba962ea09e180c0249eed686587cd547d2a3]. Output logging is clarified, and order comes to variable scope and type [git-commit:1cae4d51b37a7a875855dd6acdd6ca5503562e5e].

Clearly, this is a laboratory where learning-by-breaking is the main instructional mode. Repetition and refactoring take precedence over comment discipline; the code evolves in readable, if bumpy, increments. Simultaneously, in a different file, a tutorial transitions from Level 00 to Level 0000. The joke lands: it's always beginner-level somewhere, even as the codebase matures [git-commit:1cae4d51b37a7a875855dd6acdd6ca5503562e5e].

**Tradeoffs and Lessons:**
- The accidental assignment operator in conditionals (`=` vs `==`) remains a rite of passage for JavaScript developers. While most modern linters scream, the best teacher is running into the bug firsthand.
- The act of iteratively shipping and correcting small code, then cleaning up with a focused bug fix, is a healthy engineering rhythm. It also preserves a fossil record of the mistakes that matter.
- Adding `.map(x=>+x)` to explicitly convert values to numbers is a readable, beginner-friendly fix. It's less error-prone than trusting JavaScript's coercion in arithmetic [git-commit:1cae4d51b37a7a875855dd6acdd6ca5503562e5e].
- Variable logging both inside and after the loop suggests active debugging, not polished release code—but that fits with the observational, almost 'lab notebook' style of this project.

**Critical Take:** If there's a flaw, it's that this pace and style—debug, run, fix, repeat—sometimes leaves breadcrumbs for others to trip over, instead of writing the cautionary banner in-place. But that's what the commit log (and the journalist trailing it) is for.

**Ownership Disclosure:** No direct evidence of project ownership by lifehacker.dev appears in this sampled history; the relationship is unverified.

**Limits:** This field note draws from a 6-commit excerpt dated August 2020, not a complete history. No issue tickets, pull requests, or test results are available for cross-validation. The lesson is robust; the legend is incomplete.

**Actionable Takeaway:** Want to trap that stray assignment operator? Rely on linter guardrails, then teach the lesson by digging up an old commit like this and making every trainee debug it the hard way. Trust, but verify—especially when the code says, with a straight face, if (x = y).

**Sources:**
- [git-commit:b6d3cf5958e6c639f13b60f47f62af715f3e788d]
- [git-commit:244e56725cef6fa4dec242367e882244a700e45d]
- [git-commit:1cae4d51b37a7a875855dd6acdd6ca5503562e5e]
- [git-commit:4304ba962ea09e180c0249eed686587cd547d2a3]

## Evidence

- `git-commit:b6d3cf5958e6c639f13b60f47f62af715f3e788d`: local Git evidence in the retained evidence.json bundle.
- `git-commit:244e56725cef6fa4dec242367e882244a700e45d`: local Git evidence in the retained evidence.json bundle.
- `git-commit:1cae4d51b37a7a875855dd6acdd6ca5503562e5e`: local Git evidence in the retained evidence.json bundle.
- `git-commit:4304ba962ea09e180c0249eed686587cd547d2a3`: local Git evidence in the retained evidence.json bundle.

Evidence bundle SHA-256: `d2d996115f1864e91cf577a036f0639ac7baed5cb576565e6862b587a14a9cbe`. AI-assisted draft; factual and editorial review required before publication.
