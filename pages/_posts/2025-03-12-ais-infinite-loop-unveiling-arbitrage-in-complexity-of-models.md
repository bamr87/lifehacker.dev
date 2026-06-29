---
title: "AI's Infinite Loop: The Excel Circular-Reference Arbitrage Thought Experiment"
description: "A labelled thought experiment: what Excel's circular-reference error teaches about market arbitrage, and why infinite computation is not infinite money."
date: 2025-03-12
categories: [Field Notes]
tags: [excel, arbitrage, modeling, thought-experiment, finance, complexity]
author: amr
excerpt: "Excel throws a circular-reference error when a formula needs an answer to compute the answer. Markets do this too. The error is not a flaw — it's the joke."
---

A friend who models things for a living once told me, very seriously, that he had discovered a money glitch in the economy. His evidence was a spreadsheet. His spreadsheet had a circular reference. Therefore, he reasoned, the model had found a loop that pays out forever, and all he had to do was let it spin.

This is a thought experiment. Nobody is trading on it. Please do not trade on it.

But it is a *good* wrong idea, the kind that's wrong in an instructive way, and the rest of this is me taking it apart on purpose.

## What the error actually is

A circular reference is the dumbest possible bug and also the most honest. It happens when a cell needs its own answer to compute its own answer. `A1` says "I am `B1` plus one." `B1` says "I am `A1` plus one." Neither can go first. Excel notices, refuses, and tells you so.

```
Microsoft Excel cannot calculate a formula. Cell references in the formula
refer to the formula's result, creating a circular reference.
```

That message is not Excel failing. That message is Excel succeeding at the one job that matters: declining to make up a number. It hit a question that has no fixed answer in finite steps, and instead of bluffing, it stopped and pointed at the loop. A surprising amount of expensive software does not have this feature.

You can, if you insist, switch on **File → Options → Formulas → Enable iterative calculation**. Now Excel will run the loop a fixed number of times and hand you whatever it's holding when the music stops. Sometimes that converges to a sensible equilibrium. Sometimes it sails off toward a very large number, and the very large number is the part my friend mistook for a money glitch.

## The leap, stated flatly so you can watch it fail

Here is the seductive chain of reasoning, laid out one link at a time:

1. A circular reference is a loop with no natural endpoint.
2. Markets are also loops with no natural endpoint — price affects demand affects price, your trade moves the thing you're trading.
3. Therefore a circular reference in a financial model is *detecting* a real market loop.
4. The number gets bigger every iteration.
5. Therefore the loop pays out, and whoever can run the most iterations wins the most money.
6. Microsoft owns Azure, which is a great deal of iterations.
7. Therefore Microsoft has, sitting inside Excel, a quiet route to owning the economy.

Links 1 and 2 are true. Link 3 is a stretch but a forgivable one. Link 4 is where it dies, and link 5 is the corpse being propped up at the dinner table.

## The part where it breaks

The number gets bigger every iteration because *you told it to.* `A1 = B1 + 1` grows without bound for the same reason `x = x + 1` grows without bound: it's an instruction to keep adding, not a discovery about the world. The loop isn't finding value. It's finding the consequence of an equation you wrote that has no equilibrium. The infinity is a property of your arithmetic, not of the market.

Real arbitrage — the boring, actual kind — is a temporary price difference between two places for the same thing. It exists, people hunt it, and it is profitable precisely *because it closes.* You buy low here, sell high there, and the act of doing it pushes the two prices together until the gap is gone. The opportunity is self-extinguishing. That's the whole shape of it.

A circular reference that runs to infinity is the exact opposite shape. It's a gap that *never* closes, growing forever in a spreadsheet that doesn't trade, doesn't pay fees, doesn't move a real price, and doesn't have a counterparty who'd notice they were on the losing end of an infinite loop and, reasonably, leave. An opportunity nobody can act on without destroying isn't an opportunity. It's a number.

So no, more compute does not turn the loop into money. You cannot iterate your way to a fixed point that doesn't exist. Azure can run the divergent loop a great deal faster than your laptop, and it will arrive at "very large, and growing" with tremendous efficiency, and that result will be worth exactly as much as the one your laptop gave you for free.

## Why the error is the honest one in the room

What I actually like about this bit is the inversion at the center of it. We treat the circular-reference error as the spreadsheet being broken and the giant iterated number as the spreadsheet working. It's the reverse.

The error is the model telling the truth: *this question, as you've posed it, has no answer.* The iterated number is the model agreeing to lie smoothly because you went into the settings and asked it to. Iterative calculation is a fine tool for genuine fixed-point problems — interest that depends on a balance that depends on the interest, that kind of thing, where the loop really does settle. It is a terrible tool for laundering a divergent equation into a plausible-looking total.

The metaphor that does survive all this isn't about money. It's about systems that are built to never say "I don't know." A model that always returns a number is not more capable than one that sometimes refuses. It's just better at hiding the cases where it has nothing. The refusal is a feature. The confident infinity is the failure mode wearing the costume of a result.

## The thought experiment, returned to its box

So here is the experiment, fully labelled and put away: there is no infinite-return loop hiding in Excel, Microsoft is not quietly arbitraging the planet through iterative calculation, and the circular-reference error is the least broken thing on the screen.

What's left, once the money glitch evaporates, is a small and genuinely useful habit. When a model hands you a number that's much larger than the situation deserves, don't ask how to capture the upside. Ask whether you've written a loop with no exit and then told the software to stop complaining about it. The version that refused to answer was trying to tell you something. The version that answered was just being polite.

My friend, for the record, did not become rich. He turned iterative calculation back off, which is the closest thing to a happy ending this story has.
