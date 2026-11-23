---
title: "The Second Genus: Teaching a Vault to File Paradoxes"
description: "Design notes from adding paradoxes to an AI-grown encyclopedia of irony — a four-field grammar for a fuzzy concept, Quine's taxonomy as an enum, a second adversarial gate, and one pipeline that grows two schemas."
date: 2026-09-09
draft: true
categories: [posts, ai, knowledge-systems]
tags: [obsidian, github-actions, claude, jekyll, zer0-mistakes, agentic-workflows, paradox, schema-design, prompt-engineering]
lastmod: 2026-09-09
---

A month after the founding session, Irony Works got a second genus. The instruction was one line — *focus on paradoxes; build the linguistic framework; the goal is a repository of paradoxes new, old, debated, and hypothetical* — and the session ended with a paradox schema, a second adversarial gate, a new branch of the site, eight seed entries from Eubulides to Fermi, and the engine rewired so that one pipeline grows two kinds of thing. The reusable part is not the paradoxes. It is the method for turning a fuzzy word into fields, and what happened when the pipeline was asked to hold two schemas at once.

## Start from a definition with joints in it

The founding session's lesson was that a fuzzy concept scales only if its skeleton is mandatory frontmatter: irony became `expectation` plus `reversal`, and anything that could not fill both went to compost. Paradox needed the same treatment, and the trick was to find a definition with joints. Sainsbury's is the standard one — *an apparently unacceptable conclusion derived by apparently acceptable reasoning from apparently acceptable premises* — and it has three *apparently*s in it. Each one became a field, plus a fourth for the wall the conclusion hits:

```yaml
premises:      # each one, alone, commands assent
inference:     # the step that looks valid
conclusion:    # the destination the reader refuses
collision:     # what it runs into — an intuition, a fact, or logic itself
```

That fourth field did more work than expected. What a conclusion collides with predicts what kind of paradox it is: collide with an intuition and the conclusion is probably true (Quine's *veridical*); with a fact, false, so a premise or step is wrong (*falsidical*); with logic itself, and something accepted has to be given up (*antinomy*). The classification is not a separate judgment layered on top; it falls out of a field the writer had to fill anyway. When you design a schema for a fuzzy concept, look for the field whose value implies the others. It is the one the model will get right most often, because it is the one closest to the raw material.

## Encode the mandate as fields, not folders

The request named four kinds of paradox — old, new, debated, hypothetical — and the obvious move was four folders. It would have been wrong within an hour: the Liar is old *and* debated; Newcomb's problem is new, debated, *and* hypothetical. The four words are not one axis. So they became three fields and a flag: `era` and `posed` carry age, `standing` (`resolved | contested | open`) carries the debate, and a `hypothesis` field, present only when the paradox rides on a counterfactual, carries the rest. Any combination is now a query rather than a filing decision.

The `hypothesis` field earned its place twice. Naming the counterfactual a paradox depends on — *backward time travel is possible*; *a reliable predictor exists* — makes "reject the hypothesis" visible as one candidate resolution instead of a silent assumption. And its mere presence is the flag, which keeps the frontmatter honest: a template that offered `hypothesis: ""` would have been truthy in Liquid and every entry would have worn the badge. Absence is a value too; design for it.

## Give the second genus its own adversary

The Alanis Gate is named for the most famous use of the word *ironic* that isn't. The paradox gate needed the same shape, and the candidate was waiting in the literature: Epimenides the Cretan, who said all Cretans are liars. It is the most famous paradox in the world and it is not one — if the sentence is false, some Cretan sometimes tells the truth, and nothing contradicts anything. Its strengthened descendant, *this sentence is false*, is the deepest antinomy in logic. So the **Epimenides Gate** composts its namesake at five out of ten and passes the Liar at ten, and that arrangement is written into the rubric as the first two lines of the calibration set.

The rest of the gate follows the founding recipe: five axes scored zero to two, a threshold, and a verdict list that names the neighbours rather than just saying no. For paradox the neighbours are `MERELY-SURPRISING` (a finding with a headline), `EQUIVOCATION` (dissolves when one word is disambiguated), `TRANSPARENT-FALLACY`, `DILEMMA` (a conflict of values, not truths), `ANOMALY` (a fact against a theory with no argument in between), and `NOT-EVEN-WRONG`. The compost ledger opened with one row per verdict — the ham sandwich, the French paradox, the paradox of choice, the trolley problem, jumbo shrimp — so the negative space is a calibration set too. A rubric with a worked example of every way to fail is worth more than a rubric with adjectives.

The gate ran for real before the session ended. Asked to score the Hilbert's Hotel entry, it passed it at eight and took two points with reasons I could not argue with: the conceptual cost (Dedekind's definition of the infinite) was paid thirty-six years before Hilbert told the story, and the entry's month-level dating of an unpublished lecture "outruns even Kragh's archival evidence slightly." I softened the date. **An adversarial prompt is also a reviewer for your own writing** — point it at the entries you wrote yourself, not just the ones the machine drafts.

## One pipeline, two schemas

The engine had one schema hard-wired into it: `cfg.gate.threshold`, `cfg.gate.compost`, a fixed list of vault folders, prompts named by convention. Adding a genus the honest way meant one abstraction, not a second copy of the script. The config gained a `genera` map — each genus is a template, a prompt set (scout, scribe, gate), a threshold, and a ledger — and a resolver in the library turns a rotation entry into all of them. The rotation itself stayed a flat list; a `paradox:` prefix on an entry selects the genus, so the maintainer weights the mix by editing a list rather than a schedule.

Two small decisions kept it cheap. The nursery stays shared and flat, discriminated by `type: paradox` in frontmatter, because the publisher does not recurse into folders and the human merging a draft can read one line. And the PR check routes by the same field: a paradox goes to the Epimenides rubric, an irony to the Alanis one, and a note with neither `expectation` nor `premises` — a taxonomy note, a ledger, the framework document — is reported `UNGATED` instead of being scored as a failed irony. Before this change, form notes were quietly getting the wrong gate. Routing by type fixed a bug nobody had filed.

## Verify the attributions before you write the entries

Eight seed entries meant roughly forty citations, and the vault's rule is that nothing cited was left unread. So the session front-loaded the research: parallel searches for the things most likely to be folklore — who first posed the grandfather paradox (readers of *Amazing Stories* in 1927, not Barjavel in 1943), whether Prior's 1958 paper on Epimenides exists (it does, *JSL* 23), whether Hilbert actually gave the hotel lecture (Kragh found the notes), what the 2020 PhilPapers split on Newcomb actually was. Several drafts changed shape because of what came back. The order matters: **search first, then write, then let the gate read what you wrote**. Writing first and verifying after produces prose that resists correction.

## Working-with-AI tips from this session

- **Find the definition with joints.** Before asking a model to classify a fuzzy concept, find the definition whose clauses can each become a required field. Sainsbury's three *apparently*s are a paradox schema in disguise; most good definitions are.
- **Look for the field that implies the others.** `collision` predicts `kind`. A schema with one such field is more robust than a schema with a separate judgment call for everything.
- **Orthogonal axes, not folders.** When a request lists categories, check whether an item can be in two at once. If it can, they are fields.
- **Name the gate for a near miss.** A rubric's most useful calibration example is the famous thing that almost qualifies. Put it in the first line and score it.
- **Let absence carry meaning, carefully.** A flag that is "present or not" is cleaner than an enum with an empty value, as long as every consumer treats the empty string as false. Liquid does not.
- **Abstract the second instance, not the first.** One schema hard-wired is fine. The moment a second arrives, build the map and the resolver, then re-route the existing callers through it. Do not fork the script.
- **Run the adversary on yourself.** The gate found an over-precise date in an entry I had written from a verified source. The fix took a minute and the entry is more honest.

## What's next

The rotation now alternates: fourteen slots, eight of them paradox families, so the weekly cycle will start proposing candidates from logic, infinity, vagueness, decision, knowledge, physics, and value — and, on the recursive slot, paradoxes about the vault's own arrangements. The first mirror of that kind is already filed: the Threshold Heap, a sorites about the gate's own passing score, resolved by stipulation because the vault knows exactly where its boundary is. It wrote it down.
