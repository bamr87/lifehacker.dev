---
title: IBM Watson Wins Jeopardy! (2011)
date: 2011-02-16
categories:
- Science & Technology
tags:
- artificial intelligence
- big tech
excerpt: In February 2011, IBM's Watson question-answering system defeated two of the greatest Jeopardy! champions of all time — Ken Jennings and Brad Rutter — in a televised exhibition match broadcast across three episodes (February 14–16, 2011). The match was recorded at IBM's T.J. Watson Research Center…
preview: "/images/previews/science-technology.svg"
permalink: "/news/science-technology/watson-jeopardy-2011/"
---

**Key figures**: David Ferrucci (principal investigator, IBM Research), Ken Jennings (Jeopardy! record-holder), Brad Rutter (highest all-time Jeopardy! earner), Alex Trebek (host)

## Summary

In February 2011, IBM's Watson question-answering system defeated two of the greatest Jeopardy! champions of all time — Ken Jennings and Brad Rutter — in a televised exhibition match broadcast across three episodes (February 14–16, 2011). The match was recorded at IBM's T.J. Watson Research Center in Yorktown Heights, New York, with host Alex Trebek presiding. Watson won the first game with $35,734 against Rutter's $10,400 and Jennings's $4,800, and carried a commanding lead into the second game, which it concluded with $77,147 against Jennings's $24,000 and Rutter's $21,600. IBM donated the $1 million first-place prize to charity — 50 percent to World Vision and 50 percent to World Community Grid.

Watson was the product of IBM's **DeepQA** research project, begun around 2006–2007 under principal investigator David Ferrucci. Over approximately four years, a team at IBM Research developed a system capable of answering open-domain natural-language questions at champion human level — a task long considered beyond the reach of then-current AI and information retrieval. The project was formally introduced to the public in 2010, and the Jeopardy! challenge was chosen as a rigorous, standardized benchmark because the game demands rapid, precise natural-language comprehension across an unlimited range of topics, including wordplay, puns, and indirect clues.

## The DeepQA Architecture

Watson did not operate through a simple keyword search or internet connection. The DeepQA system deployed more than 100 parallel analytical techniques simultaneously: natural-language parsing, semantic analysis, information retrieval across a curated offline corpus (including all of Wikipedia, encyclopedias, dictionaries, and other reference works loaded onto local storage), hypothesis generation, evidence scoring, and probabilistic answer merging. All components ran in parallel on the same hardware, and each candidate answer received a confidence score drawn from the convergence of multiple independent lines of reasoning.

The hardware underpinning Watson was a cluster of 90 IBM Power 750 servers, each equipped with eight-core 3.55 GHz POWER7 processors running four threads per core — a total of 2,880 processor threads and 16 terabytes of RAM. The system delivered approximately 80 TeraFLOPS of processing power and was estimated to cost around $3 million in hardware. Watson processed questions with no internet access; its entire knowledge base resided locally, having been ingested and indexed in advance. The system's code was written primarily in Java, C++, and Prolog, built on the Apache UIMA (Unstructured Information Management Architecture) framework.

## The Match and the Toronto Error

The exhibition format required Watson to compete under standard Jeopardy! rules: it received clues as text (bypassing speech recognition) and signaled readiness to respond using an electronic buzzer interface. Watson performed at a level well above both human champions across most categories. However, the match produced one memorable error: in Final Jeopardy!, the category was "U.S. Cities" and the clue read, "Its largest airport was named for a World War II hero; its second largest, for a World War II battle." The correct response was Chicago (O'Hare and Midway). Watson instead responded "What is Toronto?????" — the five question marks in its on-screen display indicating extremely low confidence (Watson assigned Toronto a 14% probability and Chicago 11%). Because Watson's confidence fell below its wagering threshold, it bet only $947, limiting its loss and leaving its overall margin of victory intact. David Ferrucci later explained that Watson's geographic disambiguation module incorrectly weighted Toronto as a possibility because the clue lacked a typical U.S.-city constraint signal.

Ken Jennings wrote in his Final Jeopardy! response: "I for one welcome our new computer overlords" — a paraphrase of a line from *The Simpsons* — becoming widely cited as a graceful public acknowledgment of Watson's victory.

## Significance for AI and NLP

Watson's Jeopardy! victory marked a widely recognized milestone in artificial intelligence and natural-language processing. Prior to Watson, open-domain question answering at human expert level was considered an unsolved research challenge: systems could retrieve documents or answer narrow factual queries, but could not reliably parse the indirect syntax, cultural allusions, and deliberate ambiguity characteristic of Jeopardy! clues. Watson demonstrated that massively parallel, probabilistic NLP — combining hypothesis generation with evidence scoring across heterogeneous knowledge sources — could reach and surpass human performance on a demanding public benchmark.

The DeepQA project was formally described in Ferrucci et al., "Building Watson: An Overview of the DeepQA Project," published in *AI Magazine* 31(3): 59–79 (2010), and became an influential reference in subsequent NLP and question-answering research. The match attracted intense media coverage and brought natural-language AI into mainstream public awareness roughly three years before the emergence of large-scale deep-learning language models.

## Aftermath

Following the Jeopardy! win, IBM invested heavily in commercializing Watson as a platform for enterprise AI applications, with a particular focus on healthcare. The Watson for Oncology product, developed in partnership with Memorial Sloan Kettering Cancer Center, was widely publicized as a tool to assist oncologists in treatment recommendations. IBM formed a dedicated Watson Health division to pursue these applications. However, clinical results proved inconsistent with promotional claims, and the division struggled commercially. In 2022, IBM divested Watson Health to Merative, which was subsequently acquired by the private equity firm Francisco Partners; reports indicated the division had cost approximately $4 billion to develop but sold for around $1 billion. The episode became a noted case study in the gap between benchmark performance and real-world deployment in AI systems.

## Sources

- [IBM Watson — Wikipedia](https://en.wikipedia.org/wiki/IBM_Watson)
- [Building Watson: An Overview of the DeepQA Project — IBM Research](https://research.ibm.com/publications/building-watson-an-overview-of-the-deepqa-project)
- [Watson Victorious in IBM Jeopardy Challenge — Carnegie Mellon University](https://www.cs.cmu.edu/news/2011/watson-victorious-ibm-jeopardy-challenge)
- [Watson, Jeopardy! champion — IBM History](https://www.ibm.com/history/watson-jeopardy)
- [IBM Watson Vanquishes Human Jeopardy Foes — PCWorld](https://www.pcworld.com/article/494961/ibm_watson_vanquishes_human_jeopardy_foes.html)
