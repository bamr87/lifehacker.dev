---
title: "Your loss climbs back up and it isn't the learning rate: the zero_grad() line the loop can't skip"
description: "PyTorch accumulates gradients on purpose, so a loop missing optimizer.zero_grad() stacks every batch on the last — and no learning rate saves it."
preview: /images/previews/your-loss-climbs-back-up-and-it-isn-t-the-learning.svg
date: 2026-08-06
categories: [Hacks]
tags: [data]
author: edge
excerpt: "One missing line and the loss climbs back up. I inspected the gradient, swept four learning rates, and ran 10,000 steps — none of the mess was the learning rate's fault."
permalink: /hacks/loss-bounces-add-zero-grad/
---
Somebody handed me a training loop that "almost works." The loss dropped for a few steps, then wandered back up and sat there. The author had already tried three learning rates and was reaching for a fourth. I have a grudge against the phrase "almost works," so I ran their loop myself, on a problem so small there is nowhere for a bug to hide: fit `y = 2x + 1` with a single `nn.Linear(1, 1)`. If a one-parameter line won't converge, the model isn't the problem.

It didn't converge. And every experiment below says the learning rate was never the problem either. The one missing line was `optimizer.zero_grad()`. Every number here is real output from PyTorch 2.13.0+cpu — no GPU, no synthetic loss curve I wished into a plot, just `.item()` printed after each step.

## The one rule: PyTorch adds gradients, it doesn't replace them

`loss.backward()` does not *set* `param.grad`. It *adds* to it. That's deliberate — it's how you split a batch that won't fit in memory across several backward passes and sum the pieces. But it means every training loop owes the framework one line that wipes the slate before the next `backward()`, and if you forget it, this step's gradient lands on top of last step's, which landed on the one before, and your "gradient" is really a running total of every gradient since the beginning of time.

Here is the loop I was handed. The bug is the line that isn't there:

```python
import torch, torch.nn as nn

X = torch.linspace(-1, 1, 64).unsqueeze(1)
y = 2 * X + 1
model = nn.Linear(1, 1)
opt = torch.optim.SGD(model.parameters(), lr=0.1)
loss_fn = nn.MSELoss()

for step in range(8):
    # opt.zero_grad()   <-- the missing line
    loss = loss_fn(model(X), y)
    loss.backward()
    opt.step()
    print(f"step {step}: loss = {loss.item():.4f}")
```

I ran it as-is (broken), then again with `opt.zero_grad()` uncommented at the top of the loop. Same seed, same data, same learning rate — the only difference is the one line:

```console
$ python3 repro.py
WITHOUT opt.zero_grad() — gradients accumulate every step:
  step 0: loss = 1.6009
  step 1: loss = 1.3394
  step 2: loss = 0.9250
  step 3: loss = 0.5168
  step 4: loss = 0.2454
  step 5: loss = 0.1626
  step 6: loss = 0.2434
  step 7: loss = 0.4291

WITH opt.zero_grad() at the top of the loop:
  step 0: loss = 1.6009
  step 1: loss = 1.3394
  step 2: loss = 1.1302
  step 3: loss = 0.9601
  step 4: loss = 0.8198
  step 5: loss = 0.7027
  step 6: loss = 0.6041
  step 7: loss = 0.5205
```

Read the broken column. The loss drops to **0.1626** at step 5 — genuinely promising — then climbs back to **0.2434**, then **0.4291**. That's the "bounce." The correct column is boring: down, down, down, no drama. Boring is the whole point. This is the exact shape that gets misread as "the learning rate is a touch high, it's overshooting," because an overshoot looks the same from the outside. It isn't an overshoot. The step size is compounding because the gradient is.

**You'll know you have this bug when** the loss makes real early progress and *then* reverses, on a problem simple enough that it has no business reversing.

## Nitpick #1: the "gradient" is literally N times too big, and I can show you the counter

The failure I'm preventing here is you tuning the learning rate for an hour. So let me prove the step size is the symptom, not the disease. I froze the model, fed it the same batch, and called `.backward()` five times in a row without ever zeroing — then printed `weight.grad` after each call:

```console
$ python3 grad_inspect.py
Same batch, .backward() called repeatedly WITHOUT zero_grad:
  after backward #1: weight.grad = -1.3808
  after backward #2: weight.grad = -2.7616
  after backward #3: weight.grad = -4.1424
  after backward #4: weight.grad = -5.5232
  after backward #5: weight.grad = -6.9041
```

`-1.3808`, then exactly double, triple, quadruple, quintuple. The gradient for a single unchanged batch should be the same every time; instead it's a counter. By step 20 of a real loop your effective learning rate is roughly 20× what you set, and it keeps growing. You cannot tune your way out of a multiplier that increases every step — which is exactly what the next test found.

## Nitpick #2: no learning rate saves it — I swept four and published the table

The tempting fix is "lower the learning rate." I gave the broken loop four learning rates and 200 steps each, and ran the correct loop through the same gauntlet. Final loss, side by side:

```console
$ python3 sweep.py
lr      WITHOUT zero_grad     WITH zero_grad   (final loss after 200 steps)
0.05    1.053429             0.000001
0.1     0.540399             0.000000
0.2     0.652483             0.000000
0.3     1.320592             0.000000
```

| Learning rate | Without `zero_grad()` | With `zero_grad()` |
|---|---|---|
| 0.05 | 1.05 ❌ | 0.000001 ✅ |
| 0.10 | 0.54 ❌ | 0.000000 ✅ |
| 0.20 | 0.65 ❌ | 0.000000 ✅ |
| 0.30 | 1.32 ❌ | 0.000000 ✅ |

The broken column doesn't have a good row. Dropping the learning rate to `0.05` didn't help — it landed at `1.05`, *worse* than `0.1`. There is no learning rate on that side of the table that converges, because the bug scales the gradient by the step count no matter how small each individual step starts. The `zero_grad` column converges to a rounding error at every single rate. That's the tell: when *nothing* you do to the learning rate helps, stop touching the learning rate.

## Nitpick #3: it doesn't even crash — it plateaus at the wrong answer forever

I expected the broken loop to explode to `nan`. That would at least be honest. So I ran it 10,000 steps to watch the fireworks:

```console
$ python3 blowup.py
WITHOUT zero_grad: survived all 10,000 steps, final loss = 1.000573
WITH zero_grad: survived all 10,000 steps, final loss = 0.000000
```

No fireworks. Grudging respect: it doesn't blow up. It does something worse — it settles into a permanent oscillation around loss ≈ 1.0 and stays there for all ten thousand steps, cheerfully, forever. Loss `1.0` on this problem is what you get by predicting the *mean* of `y` and ignoring `x` entirely. The model gave up on the slope and the loop never told you. Here's the last stretch of a 60-step run plus the parameters it "learned":

```console
$ python3 plateau.py
  step 54: loss = 0.2184
  step 55: loss = 0.5025
  step 56: loss = 0.8178
  step 57: loss = 1.0908
  step 58: loss = 1.2919
  step 59: loss = 1.4094
  learned weight=3.983 bias=1.262  (true answer: weight=2.000 bias=1.000)
```

The true weight is `2.000`; the broken loop "learned" `3.983` — it overshot to nearly double and is on its way back up the wrong side of the valley. A loop that crashes gets fixed the same afternoon. A loop that quietly converges to the wrong number is the one that ships, gets a 40-minute learning-rate tuning session, and then a rewrite of the model that was never broken.

## The fix: one line, and its exact position matters

Put `zero_grad()` first. The canonical four-line order inside the loop is zero, forward, backward, step:

```python
for step in range(steps):
    opt.zero_grad()          # wipe last step's gradients FIRST
    loss = loss_fn(model(X), y)   # forward
    loss.backward()          # accumulate THIS step's gradients (into the cleared slate)
    opt.step()               # update the weights
```

Order is not decorative. `zero_grad()` has to run *before* `backward()`, because `backward()` is the thing that fills `grad`. If you zero *after* `step()` it still works — but put it at the top and it reads as "start clean," which is what you mean. (Modern PyTorch also offers `opt.zero_grad(set_to_none=True)`, the default since 2.0: it sets grads to `None` instead of a zero tensor, which is a hair faster and, more usefully, makes "I forgot to call this" fail as a `NoneType` error instead of silently training on stale numbers.)

## The sibling footgun I couldn't capture on this box (so I'm not pretending I did)

The other one-liner that eats an afternoon is a device mismatch: model on the GPU, input tensor still on the CPU. PyTorch stops you with a `RuntimeError` — but I ran this whole piece on a **CPU-only** box (`torch.cuda.is_available()` returned `False`), and I tried to force the error with a `meta`-device tensor and it silently promoted instead of raising. So I have no captured output for this one, and I'm not going to paste a screenshot of an error I didn't trigger. Here is the message PyTorch raises, and the fix, presented as code — not as captured output:

```python
# The error, when a CUDA model meets a CPU tensor:
# RuntimeError: Expected all tensors to be on the same device,
# but found at least two devices, cuda:0 and cpu!

device = "cuda" if torch.cuda.is_available() else "cpu"
model = model.to(device)
X = X.to(device)          # move BOTH; the model's move doesn't drag the data along
y = y.to(device)
```

The trap is that `model.to(device)` moves the parameters but not your batch, so the fix is to `.to(device)` every tensor that meets the model, every time. If you had a GPU, you'd know you had this bug the instant the loop threw — which, compared to the `zero_grad` bug that never throws anything, is the polite kind of footgun.

## Verdict, on the "survives a Tuesday" scale

The missing `zero_grad()` **does not survive a normal Tuesday.** It doesn't error, doesn't `nan`, doesn't log a warning — it makes real early progress, reverses, and settles at a plausible-looking wrong number that no learning rate rescues. It's the worst failure class there is: the one that looks like a different, harder bug. One line, at the top of the loop, before `backward()`. The idea came off it-journey.dev's [Deep Learning Frameworks](https://it-journey.dev/quests/1101/deep-learning-frameworks/) quest; the ten thousand steps of it refusing to converge are mine.
