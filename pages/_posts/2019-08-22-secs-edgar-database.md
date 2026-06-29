---
title: "Reading a Company's Soul in the SEC EDGAR Filings"
description: "A field guide to the SEC's EDGAR filings — 10-K, 10-Q, 8-K, proxies — and what a public company tells on itself when it is legally required to talk."
date: 2019-08-22
categories: [Field Notes]
tags: [sec, edgar, finance, filings, investing, due-diligence]
author: amr
excerpt: "Every public company keeps a diary. It is audited, footnoted, and filed with the federal government, and you can read it for free."
---

There is a free database where every public company in America is legally compelled to write down what it did, what it owns, what it owes, and what could go horribly wrong. It is searchable. It costs nothing. Almost nobody reads it.

It is called EDGAR, it is run by the SEC, and it is the closest thing finance has to a confessional booth — except the company is the one confessing, and a federal regulator is making sure it doesn't lie too creatively.

The title of this post promises you'll read a company's *soul*. I want to be honest up front: this is not a scraping tutorial. There is no script here, no API key, no clever one-liner that turns EDGAR into a spreadsheet. This is a reading guide. The hard part of EDGAR was never getting the data. The hard part is that the data is a 200-page document written by people whose job is to disclose the truth without making it sound interesting.

## What EDGAR actually is

EDGAR — Electronic Data Gathering, Analysis, and Retrieval — is where the SEC parks the mandatory filings of every U.S. public company. When a company sells stock to the public, it trades a great deal of privacy for that money. The trade is enforced through forms. Lots of forms.

You do not need a Bloomberg terminal. You need the company's name and a willingness to read prose that was specifically engineered not to be read.

## The forms, in order of how much they tell on the company

**10-K — the annual report.** This is the big one. Once a year, the company files an audited, comprehensive account of itself: the business, the risks, five years of financial data, management's own narrative, and the three financial statements with an independent auditor's signature attached. It is the document where a company is most exposed, because everything in it is audited and someone can be sued over it.

**10-Q — the quarterly report.** Same idea, three times a year, shorter, and — this is the part people forget — *unaudited*. The 10-Q is the company talking off the cuff between its annual confessions. Useful for catching trends early. Less load-bearing, because no auditor put their name on it.

**8-K — the "something just happened" report.** Filed when a material event occurs and shareholders need to know before the next quarterly cycle: an acquisition, a CEO walking out, a factory burning down, a restatement. If you want to know the moment a company's story changed, the 8-K is the timestamp.

**DEF 14A — the proxy statement.** Filed ahead of the shareholder vote. This is where executive compensation lives, in detail, next to the governance machinery — board structure, who sits on which committee, what shareholders are being asked to approve. If you want to know what a company values, read what it pays its executives and compare it to what it pays everyone else.

**Form 4 — the insider trade.** Filed by insiders when they buy or sell their own company's stock. Not a crystal ball. But when the people with the most information start selling, it is at least worth noticing that they have more information than you.

That is the whole vocabulary. Annual confession, quarterly aside, breaking news, compensation tell-all, and the insiders' own betting slips.

## What's inside the 10-K, and where the truth hides

The 10-K is structured, which is convenient, because it means the interesting parts are always in the same place. A few sections do most of the work.

**Risk Factors.** Companies are required to list what could go wrong, and they over-comply on purpose — disclosing a risk is legal cover, so the section is long and defensive. The skill is not reading it; it's noticing what changed from last year's. A risk factor that is new, or that moved up the list, or that suddenly got two paragraphs where it had one sentence — that is the company telling you where it is nervous. Diff this year's against last year's and the deltas are the story.

**Management's Discussion and Analysis (MD&A).** This is management explaining its own numbers in its own words. It is the most narrative part of the document and therefore the most spun. Read it, then read the actual financial statements, then notice the gap between the two. The MD&A is where revenue "grew across key segments." The statements are where you find out which segment was carrying the others.

**The financial statements themselves.** Three of them, and they answer three different questions.

- The **income statement** asks: did the company make money this period? Revenue at the top, costs and expenses subtracted on the way down, net income at the bottom. The line everyone quotes is the bottom line, but the margins between the lines — how much revenue survives each subtraction — are where the health actually shows.
- The **balance sheet** asks: what does the company own and owe right now? Assets on one side, liabilities and shareholders' equity on the other, and by construction they balance. It is a snapshot, not a movie. A single balance sheet tells you little; the change between two of them tells you almost everything.
- The **cash flow statement** asks the rudest question: forget the accounting, did actual cash come in? Split into operating, investing, and financing activities. This is the statement that is hardest to flatter, because a company can report a profit on the income statement and still be quietly running out of money, and the cash flow statement is where that shows up first.

A company can make the income statement sing. The cash flow statement is where it has to admit whether the singing was paid for.

## How people actually use this

The professionals are not doing anything you can't do. They are doing three boring things consistently.

**Trend analysis** — lining up the same number across several years and watching the slope. Revenue going up is nice; revenue going up while margins go down is a different and more interesting fact.

**Comparative analysis** — pulling the same figures from a competitor's 10-K and putting them side by side. A 12% margin means nothing in isolation. A 12% margin in an industry that runs at 25% means something.

**Event studies** — catching an 8-K, then watching how the market reacted, to learn what the market thinks matters. The filing is the cause; the price move is the audience reaction.

None of this requires a model. It requires reading two documents instead of one, and subtracting.

## The honest caveat

EDGAR gives you what the company was *required* to say, written by people who are very good at saying it without saying too much. It is the floor of disclosure, not the ceiling of truth. Everything in a 10-K is, technically, accurate — that's what the audit is for — and a genuinely accurate document can still be assembled to leave a particular impression. The numbers don't lie. The framing around them is a different employee's job.

So no, you will not find a company's soul in EDGAR, exactly. You will find the version of itself a company is legally obligated to put in writing, footnoted, and signed. Which, when you compare this year's confession to last year's, and the careful words to the unflattering cash, turns out to be a remarkably good place to start looking.

It's free. The companies already wrote it. The only thing standing between you and it is that the document is boring on purpose — and now you know that the boring parts are where they hid the interesting ones.
