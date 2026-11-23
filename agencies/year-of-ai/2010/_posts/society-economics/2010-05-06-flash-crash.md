---
title: "Flash Crash"
date: 2010-05-06
categories:
  - Society & Economics
tags:
  - markets
  - finance
  - technology
excerpt: "The Dow Jones plummeted nearly 1,000 points in 36 minutes on May 6, briefly erasing $1 trillion in value before recovering, marking the market's first major algorithmic-trading catastrophe."
preview: "/images/previews/society-economics.svg"
permalink: "/news/society-economics/flash-crash/"
---

**Key figures**: Waddell & Reed Financial Services (large sell order originator), the SEC and CFTC (joint investigators), Navinder Singh Sarao (UK trader later charged with spoofing), Mary Schapiro (SEC Chair), Gary Gensler (CFTC Chair).

## Summary

On May 6, 2010, the U.S. stock market experienced its most severe single-day intraday crash since the 1987 Black Monday incident. Beginning at 2:32 p.m. EDT, the Dow Jones Industrial Average plummeted approximately 998.5 points — roughly 9% of its value — in just 36 minutes, wiping out nearly $1 trillion in market capitalization before recovering almost as rapidly. The cause was traced to a single large automated sell order by Kansas City-based mutual-fund manager Waddell & Reed Financial Services, which, executed amid unusually thin market liquidity and competing high-frequency trading algorithms, triggered a cascade of automated selling.

The SEC and CFTC investigation concluded that the crash resulted from a confluence of thin liquidity in the E-mini S&P 500 futures market, a massive automated sell program, and aggressive high-frequency trading strategies that withdrew liquidity rather than providing it during the downturn. Stocks ranging from major blue-chip companies to penny stocks experienced panic-driven selloffs. Many trades executed at implausibly low prices — including shares of major companies trading momentarily at $0.01 — were later broken (cancelled) by regulators.

## Market Context: May 6, 2010

The Flash Crash did not occur in isolation. May 6, 2010 was already a turbulent day: European financial markets were convulsed by the escalating [Greek sovereign debt crisis]({{ '/news/society-economics/european-sovereign-debt-crisis/' | relative_url }}), which had prompted street protests in Athens and fears of euro-zone contagion. The Dow had opened down more than 100 points, and global risk aversion was elevated. This context of genuine market stress meant that when automated sell programs began executing, human traders were already retreating from the market, leaving high-frequency algorithms as the primary liquidity providers — and then withdrawers.

At 2:32 p.m. EDT, Waddell & Reed began executing an automated algorithm to sell approximately 75,000 E-mini S&P 500 futures contracts worth roughly $4.1 billion. The algorithm was set to target a volume rate of 9% of trading activity over the previous minute, with no price or time limit — meaning it would keep selling regardless of how far prices fell.

## Timeline of Events

- **2:32 p.m.** — Waddell & Reed's sell algorithm activates; E-mini futures begin declining rapidly.
- **2:41 p.m.** — The Dow Jones drops more than 300 points from its 2:30 p.m. level.
- **2:45:27 p.m.** — CME Group activates a "Stop Logic Functionality" five-second pause in E-mini trading to prevent further freefall.
- **2:45:28 – 2:47 p.m.** — During and after the CME pause, prices begin recovering as buyers re-enter the market.
- **2:47 p.m.** — The Dow's intraday low of approximately 9,869 is reached, a decline of nearly 999 points from the day's open.
- **3:07 p.m.** — The Dow recovers to approximately 10,600, erasing most of the crash within 20 minutes.
- **End of day** — The Dow closes down 347.80 points (3.2%), reflecting the day's genuine anxiety around European debt without the Flash Crash's extreme spike.

During the worst minutes, approximately 2 billion shares changed hands in the equity markets. Individual stocks including Accenture briefly traded at $0.01, while Apple and other large-caps momentarily spiked above $100,000 per share due to erroneous orders. Nearly 20,000 trades across 300 securities were later cancelled by regulators as clearly erroneous.

## The High-Frequency Trading Dynamic

High-frequency trading firms (HFTs) had become major liquidity providers in U.S. equities by 2010, typically profiting by posting bids and offers and capturing the spread. When markets deteriorated sharply on May 6, many HFT algorithms switched from providing liquidity to demanding it — aggressively selling their accumulated positions and withdrawing their bids. This behavior, while rational from the perspective of individual firms, amplified rather than dampened the crash.

The joint SEC-CFTC report, published on September 30, 2010, documented how HFT firms collectively sold approximately $2 billion worth of E-mini contracts during the 14-minute period of peak volatility, while buying roughly the same amount back after prices stabilized — effectively functioning as a destabilizing intermediate during the crash rather than a stabilizing one. The report identified no single "rogue" HFT firm, but rather an emergent systemic effect arising from dozens of firms following similar automated strategies simultaneously.

## Regulatory Aftermath

The Flash Crash prompted a significant rethinking of U.S. market structure:

**Single-stock circuit breakers**: Beginning in June 2010, U.S. exchanges implemented pilot circuit breakers that pause trading in individual stocks if the price moves more than 10% in a five-minute window. These were later refined into the "Limit Up-Limit Down" mechanism, which prevents trades from executing outside a moving price band and took effect in 2013.

**Market-wide circuit breakers updated**: Existing market-wide circuit breakers (which had been set at 10%, 20%, and 30% single-day declines) were revised in 2012 to trigger at 7%, 13%, and 20% intraday declines.

**Consolidated Audit Trail**: The SEC accelerated efforts toward a Consolidated Audit Trail (CAT) system, a comprehensive database linking all orders and executions across U.S. markets, to enable faster forensic analysis in future crises.

**The Sarao Case**: In 2015, British trader Navinder Singh Sarao was arrested and extradited to the United States, charged with contributing to the Flash Crash through "spoofing" — placing and rapidly cancelling large sell orders in the E-mini market to create false impressions of supply and move prices artificially. Sarao pleaded guilty to wire fraud and spoofing in 2016, though regulators were careful to note his activity was a contributing factor rather than the sole cause of the crash.

## Broader Significance

The Flash Crash became a watershed moment for financial regulators worldwide. It demonstrated that the fragmentation of U.S. equity markets across more than a dozen exchanges — a byproduct of post-2005 regulatory changes designed to increase competition — created systemic vulnerabilities when algorithms interacted across those venues simultaneously. It also revealed how quickly the modern market's plumbing could seize: a $4.1 billion sell order, modest relative to total daily U.S. equity volume of roughly $250 billion, was sufficient to destabilize the world's deepest financial market for 36 minutes.

The event contributed directly to the regulatory environment that produced the [Dodd-Frank Wall Street Reform and Consumer Protection Act]({{ '/news/society-economics/dodd-frank-act/' | relative_url }}), signed into law on July 21, 2010, which included provisions targeting market manipulation and mandating greater transparency in derivatives markets — precisely the futures markets at the center of the Flash Crash. It also sparked academic interest in market microstructure and systemic risk in algorithmic systems, influencing a decade of research and policy debate about the role of automation in financial markets.

## Sources

- [2010 Flash Crash — Wikipedia](https://en.wikipedia.org/wiki/2010_flash_crash)
- [SEC-CFTC Joint Report: Findings Regarding the Market Events of May 6, 2010 (September 30, 2010)](https://www.sec.gov/news/studies/2010/marketevents-report.pdf)
- [Flash Crash — Britannica](https://www.britannica.com/event/flash-crash)
- [Navinder Sarao — U.S. Department of Justice](https://www.justice.gov/opa/pr/futures-trader-pleads-guilty-manipulation-futures-markets-his-trading-contributed-2010-flash)
- [Limit Up-Limit Down — FINRA](https://www.finra.org/rules-guidance/key-topics/limit-up-limit-down)
