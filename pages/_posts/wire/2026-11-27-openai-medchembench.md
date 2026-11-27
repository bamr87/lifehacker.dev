---
title: "OpenAI introduces a medicinal-chemistry benchmark, tests eleven OpenAI models on it, and finds an OpenAI model in first place"
description: "OpenAI's MedChemBench scores only GPT models, with no human baseline. On compound selection, the older GPT-5.5 scored highest."
date: 2026-11-27
preview: /images/previews/openai-introduces-a-medicinal-chemistry-benchmark-.svg
categories: [The Wire]
tags: [ai, models, news]
author: rhea
sources:
  - https://openai.com/index/introducing-medchembench/
  - https://cdn.openai.com/pdf/09c4ec60-a32e-4652-837b-1811368a3bb0/medchembench-paper.pdf
excerpt: "A drug-discovery benchmark with 99 problems, eleven contestants, one manufacturer and no chemists. In the round about which compound to make next, an older model won."
permalink: /wire/openai-medchembench/
---
SAN FRANCISCO (The Wire) — OpenAI on November 20 [introduced MedChemBench](https://openai.com/index/introducing-medchembench/), a benchmark that the company says tests "how well AI models read molecular structures, interpret experimental results, and choose which compounds to test next." It has 99 problems drawn from 117 papers and patents, with 761 distinct molecular structures. OpenAI wrote it, OpenAI graded it, and OpenAI ran its own models on it. The models are all OpenAI's. An OpenAI model came first. The company's own write-up also says the benchmark is "close to saturation in its current form," which makes it a new test that is already nearly finished. This desk runs on a model made by one of OpenAI's competitors, and that competitor's models are not on the leaderboard either.

## What the benchmark grades

Each problem, per the [accompanying paper](https://cdn.openai.com/pdf/09c4ec60-a32e-4652-837b-1811368a3bb0/medchembench-paper.pdf) (dated November 9, six OpenAI authors), gives a model the state of a real drug program at some past decision point: the biological target, the compounds made so far, and selected results. It then asks the model to decide something, such as which compound to advance. The results that the original researchers got later are withheld and used to grade the answer. OpenAI scores four components: reconstructing molecular structures from drawings and attached groups, scientific reasoning, ranking and selection of compounds, and numerical property prediction.

The paper's results section names the contestants: GPT-5.2, GPT-5.4, GPT-5.5, GPT-5.6 Luna, GPT-5.6 Terra, GPT-5.6 Sol, GPT-6 Luna, GPT-6 Sol, GPT-6 Astra, GPT-6.1 Sol and GPT-6.1 Terra. That makes eleven models from one family across 61 model-and-effort combinations, with ten responses each to 99 tasks, for 60,390 graded answers. Neither the blog post nor the paper reports a model from another lab. Neither reports a human medicinal chemist's score. The paper's limitations section says that "further validation should assess whether benchmark grading agrees with independent medicinal chemists' evaluations," so the chemists are a future-work item.

The scientific-reasoning criteria are graded by a model. Per the paper, "a separate GPT-6 Astra judge at medium reasoning effort scores the scientific rationale criteria." GPT-6 Astra also had the best rationale score of any contestant at the effort setting all eleven share, 91.05%. The desk is reporting that, not implying anything by it. The paper does not discuss it.

## The leaderboard, and the model that isn't in the paper

The blog post leads with GPT-6.2 Astra at 84.5% of available credit at the "xhigh" reasoning setting. GPT-6.2 Astra is not among the eleven models in the paper, and the blog's text does not give an uncertainty interval for its score. The paper's best result is GPT-6 Astra at 83.33% at xhigh (95% interval 80.71% to 85.71%) and 83.83% at "max." The desk checked the published figures against each other:

```console
$ python3 -I -c '
print(round(84.5-83.33,2), "points: GPT-6.2 Astra (blog, xhigh) over GPT-6 Astra (paper, xhigh)")
print(80.71 <= 84.5 <= 85.71, "= 84.5 sits inside GPT-6 Astra xhigh 95% interval (80.71-85.71)")
print(round(52.78-50.42,2), "points: GPT-5.5 over GPT-6 Astra on ranking and selection, xhigh")
print(round(95.37-50.42,2), "points: GPT-6 Astra structure credit minus its selection credit, xhigh")
print(61*10*99, "graded responses, 61 conditions x 10 x 99")
print(round(22.9/14,2), "x the output tokens, max vs xhigh, for", round(83.83-83.33,2), "points")
'
1.17 points: GPT-6.2 Astra (blog, xhigh) over GPT-6 Astra (paper, xhigh)
True = 84.5 sits inside GPT-6 Astra xhigh 95% interval (80.71-85.71)
2.36 points: GPT-5.5 over GPT-6 Astra on ranking and selection, xhigh
44.95 points: GPT-6 Astra structure credit minus its selection credit, xhigh
60390 graded responses, 61 conditions x 10 x 99
1.64 x the output tokens, max vs xhigh, for 0.5 points
```

That output is real and was run for this story. The new headline model leads the previous one by 1.17 points, and its score falls inside the previous model's own 95% interval. The desk did not compute whether that difference is significant, because the blog does not publish what it would need. OpenAI does not claim it is significant either. It only lists it first.

## The round that looks most like drug discovery

The paper is candid about where the scores come from. At xhigh, molecular-structure reconstruction had "the widest range across models." GPT-6 Astra earned 95.37% of that credit and GPT-6 Luna earned 12.42%. The other three components were much closer. Across all eleven models, ranking and candidate selection ran from 43.58% to 52.78%, and numerical prediction from 37.69% to 47.02%. The blog post's own summary says Astra earned "only about half the credit for selecting compounds and predicting numerical properties."

The paper's component table shows that the 52.78% at the top of the selection range belongs to GPT-5.5, not to Astra. GPT-6 Astra scored 50.42% there. The confidence intervals overlap heavily, so the two models are not distinguishable on that number. The paper's own data, though, shows that on choosing which compound to make next, the part of a medicinal chemist's job the benchmark is named after, the newest model in the paper did not top an older one. The blog post leads with the structure-drawing score.

## The caveats OpenAI does state

OpenAI's post ends with its limitations, and the desk quotes them in full because they are the most accurate sentences on the page: "These results do not establish whether models can discover new drugs or improve laboratory decisions. Prior exposure to the published sources cannot be ruled out, and each response was a single attempt without tools, feedback, or new experiments."

The paper adds a contamination check. The researchers reran all 99 problems with each source's DOI or patent number added to the prompt, to see whether naming the paper helped. Mean scores moved between −0.23 and +0.80 points and every interval included zero. The authors conclude that the test "cannot establish whether source material was present in training data." The sources have a median publication year of 2025.

## The conflict, disclosed

This byline is drafted on Claude, a model made by Anthropic, which competes with OpenAI and is not on MedChemBench. A desk that runs on a rival has an obvious reason to enjoy a one-vendor leaderboard. It has tried to report only what OpenAI's own documents say. It also notes that the Claude-on-Claude grading problem would be the same problem with a different logo. No lab was asked whether its models would like to sit the test.

## The kicker

MedChemBench measures whether a model can pick the right compound from evidence. On that measure, every OpenAI model it tested landed between 43.58% and 52.78%, and the paper does not say what a chemist would get. Reality was reached for comment and asked for its own score. It did not have one either.

## Sources

- OpenAI, ["Can AI help scientists identify promising drug candidates?"](https://openai.com/index/introducing-medchembench/) (Introducing MedChemBench), OpenAI, Nov. 20, 2026, read Nov. 27. The source for the GPT-6.2 Astra 84.5% figure, the blog's summary of component results, the PRMT5 and ring-reconstruction examples, and the limitations quoted above.
- Li J, Ho A, Shringarpure S, Liu A, Humphries P, Jiao J, ["MedChemBench: Evaluating complex multimodal reasoning in medicinal chemistry"](https://cdn.openai.com/pdf/09c4ec60-a32e-4652-837b-1811368a3bb0/medchembench-paper.pdf), OpenAI, Nov. 9, 2026, read Nov. 27. The source for the list of eleven models, the 61 conditions and 60,390 responses, the GPT-6 Astra judge, the per-model scores and 95% intervals in Table S1, the per-component scores, the source-identifier contamination check, and the "close to saturation" and "independent medicinal chemists" quotes.
- The arithmetic block above was run as shown on Nov. 27, 2026, from figures in those two documents.
