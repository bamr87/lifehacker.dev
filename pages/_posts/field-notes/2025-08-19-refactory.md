---
title: "Refactory: What 'Refactoring' Code Says About Fixing the Factory Floor"
description: "An essay on stretching the software refactor metaphor onto AI-modernized ERP and US manufacturing — and where the analogy quietly stops paying rent."
date: 2025-08-19
categories: [Field Notes]
tags: [ai, satire, business]
author: amr
excerpt: "Refactor means changing the inside without changing the outside. Manufacturing is almost entirely the outside. So why does everyone keep selling the metaphor?"
preview: /images/previews/refactory-what-refactoring-code-says-about-fixing-.png
---
This is an essay, not a hack. There are no commands to run, no `before` and `after` you can paste into a terminal. If you came for a copy-pasteable fix, the back button is right there and I respect your time.

Someone, somewhere, coined the word "refactory." It is a portmanteau of *refactor* and *factory*, and it is the kind of word that sounds like a strategy after you've read it three times. The pitch underneath it is tidy: just as a developer refactors tangled code to make it cleaner without changing what it does, an American manufacturer can "refactor" its legacy ERP system with AI and emerge agile, resilient, and ready for the future.

I want to take that metaphor seriously, because it is mostly being used to sell consulting hours, and a metaphor used to sell things deserves to be poked.

## What "refactor" actually means, said precisely

Here is the part the word "refactory" is counting on you to forget.

Refactoring has a definition, and it is narrow on purpose. Refactoring is changing the *internal* structure of code **without changing its external behavior**. That is the whole deal. You rename the variable, you split the 400-line function into four, you delete the dead branch — and the program does exactly what it did before, byte for byte. If the output changes, congratulations, you didn't refactor. You wrote a bug, or a feature, and either way you should have said so.

So the entire value of "refactor" as a word is that it promises *no change in behavior*. That is what makes it safe. That is what makes it sound disciplined instead of reckless.

Now hold that definition up against a factory floor.

## A factory is almost entirely external behavior

The flat statement, said flatly: manufacturing is the external behavior. It is the part the refactor metaphor specifically promises not to touch.

A factory's "behavior" is what comes off the line — the parts, the throughput, the defect rate, the lead time, the cost per unit. When a manufacturer says it wants to modernize, it does not mean "produce the identical parts at the identical rate with cleaner internal documentation." It means: make different things, faster, cheaper, with fewer people, in response to a market that moved. That is a *behavior change*. That is the opposite of a refactor.

So the metaphor inverts itself the moment you press on it. The thing software people call refactoring — restructure the inside, freeze the outside — is the one thing nobody modernizing a factory actually wants. They want the outside to change. They are not refactoring the factory. They are rewriting it and hoping the lights stay on.

This is not pedantry for its own sake. The word matters because it sets expectations about *risk*. "We're just refactoring" is meant to reassure the board that behavior is preserved and the change is safe. Pointing that reassurance at a physical line that you fully intend to change is how you get a project that is sold as a tune-up and delivered as a transplant.

## Where the metaphor does pay rent: the ERP underneath

There is one layer where "refactor" is not a lie, and it is worth being fair about it.

A legacy ERP system *is* code — millions of lines of it, some of it written in languages whose practitioners are retiring faster than the schools produce replacements. And a lot of ERP modernization genuinely is refactoring in the strict sense: take the COBOL batch job that computes reorder points, restructure it into something maintainable, and make sure it still computes *the exact same reorder points*. Same behavior, cleaner insides, less terror when you have to change it next time. That is a real refactor, and AI tooling that helps read and restructure that code is doing real work.

The original framing of "refactory" cites the usual numbers here, and I'll pass them along the way you'd pass along a flyer someone handed you — these are the source author's claims, attributed, not re-verified by me: Deloitte's 2025 outlook on manufacturers facing higher costs and supply-chain strain; McKinsey's figure of up to 45% savings on net-new code with AI assistance; a vendor's claim of 70% less manual effort on legacy transformation; assorted defect-reduction and downtime numbers in the 20–61% range. I have not checked any of them. I am telling you that because the sincere version of this essay would quietly fold those numbers into the argument as if they were load-bearing, and they are someone's marketing until proven otherwise. Treat them as the genre they belong to: the bullet point on a slide that ends in a contact form.

What I'll commit to is the structural claim, which needs no statistics: refactoring the *ERP code* is a real, bounded engineering task, and AI is a real, if oversold, assistant for it.

## The sleight of hand is the word "just"

The trick in "refactor the factory floor" is the same trick in every "just" you've ever been handed. (House rule: the dismissive "just" is on our banned list, and this is exactly why.)

Refactoring the ERP code is the safe, bounded, behavior-preserving part — the part where the metaphor is honest. Changing what the factory *does* is the unbounded, behavior-changing, capital-and-people part — the part the metaphor was specifically chosen to make invisible. "Refactory" welds the safe word onto the dangerous work and ships the whole thing under the reassuring label.

It's a category error wearing a strategy's clothes. The code can be refactored. The factory cannot — it can only be re-tooled, retrained, re-capitalized, and re-argued past everyone whose job the new behavior changes. Those are different verbs with different price tags, and collapsing them into one cute portmanteau is how the price tag goes missing.

## The honest version of the pitch

I am not against any of the underlying work. Legacy ERP rots, and the people who can read it are leaving. Restructuring that code so the next decade's engineers can change it without praying is good and overdue, and AI tools that help are worth having even at half the breathless claims.

But say it straight:

- **The ERP code can be refactored.** Same behavior, cleaner insides, lower fear. This is the part where the word is true and AI is a legitimate, oversold-but-real assistant.
- **The factory cannot be refactored.** Changing what comes off the line is a behavior change by definition — a rebuild, a retraining, a re-capitalization. Call it that, and budget for it like that.
- **The metaphor's whole appeal is its safety, and that safety doesn't transfer.** "We're just refactoring" reassures the board precisely because refactors don't change behavior. Pointing it at a line you fully intend to change is selling a transplant as a tune-up.

"Refactory" is a good word and a bad plan, in the specific way that good words make bad plans easy to fund. The code is the part you refactor. The factory is the part you have to actually change — out loud, on purpose, with the bill in view. The day the slide deck says *that*, I'll believe the modernization is real and not a migration in a metaphor's coat.
