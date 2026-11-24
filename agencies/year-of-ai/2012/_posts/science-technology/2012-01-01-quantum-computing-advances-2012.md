---
title: Quantum Computing Advances 2012
date: 2012-01-01
categories:
- Science & Technology
tags:
- physics
- discoveries
excerpt: 'In 2012, quantum computing crossed a threshold from academic curiosity into early industrial investment. The year''s milestones spanned four technical fronts: **D-Wave Systems** announced its 512-qubit "Vesuvius" quantum annealer and secured major commercial partnerships with Google and NASA;…'
preview: "/images/previews/science-technology.svg"
permalink: "/news/science-technology/quantum-computing-advances-2012/"
---

**Key figures**: John Preskill (Caltech), David Wineland (NIST), John Martinis (UCSB), Vern Brownstein / Geordie Rose (D-Wave Systems), Irfan Siddiqi (UC Berkeley), Seth Lloyd (MIT)

## Summary

In 2012, quantum computing crossed a threshold from academic curiosity into early industrial investment. The year's milestones spanned four technical fronts: **D-Wave Systems** announced its 512-qubit "Vesuvius" quantum annealer and secured major commercial partnerships with Google and NASA; **David Wineland** (NIST) and **Serge Haroche** (Collège de France) shared the **Nobel Prize in Physics** for their experimental quantum control techniques; John Martinis's group at UC Santa Barbara published landmark results on superconducting qubit coherence; and theorist **John Preskill** coined and popularized the term **"quantum supremacy"** — the threshold at which a quantum computer performs a well-defined computational task beyond the practical reach of any classical computer. The year marked the start of a phase in which major technology companies (Google, IBM, Microsoft) began treating quantum computing as a strategic long-term investment rather than basic science.

## Background: The Quantum Computing Challenge

Quantum computers exploit two uniquely quantum phenomena:

- **Superposition**: a qubit can be in a combination of the |0⟩ and |1⟩ states simultaneously, allowing quantum algorithms to process exponentially many inputs in parallel
- **Entanglement**: qubits can be correlated in ways that have no classical analogue, enabling quantum algorithms to extract information from this correlation through interference

The potential for quantum speedup over classical computing for certain problems was formally established by Peter Shor's **1994 factoring algorithm** (exponential speedup over classical methods) and Lov Grover's **1996 search algorithm** (quadratic speedup). However, translating these theoretical advantages into physical hardware required overcoming **decoherence**: the tendency of quantum states to deteriorate through interaction with their environment.

By 2012, the best qubits in the most advanced experiments maintained coherence for **tens to hundreds of microseconds** — enough to perform dozens or hundreds of gate operations, but far short of the millions needed for practical Shor algorithm execution on cryptographically significant problems. The field's central challenge — and the benchmark for measuring 2012's progress — was increasing both coherence times and gate fidelities while scaling up qubit counts.

## John Preskill and "Quantum Supremacy"

The most consequential conceptual contribution of 2012 was John Preskill's introduction of the term **"quantum supremacy"** in a June 2012 lecture and subsequent essay titled *"Quantum computing and the entanglement frontier"* (presented at the 25th Solvay Conference on Physics, Brussels, October 2012).

Preskill defined quantum supremacy as the experimental demonstration that a quantum device can perform a computational task that no classical computer can feasibly simulate — even if the task has no immediate practical value. He proposed **random circuit sampling** (generating the output distribution of random quantum circuits) as a candidate benchmark, a suggestion that would eventually be implemented by Google's quantum hardware team in their 2019 "Sycamore" supremacy experiment.

The term was immediately adopted by the quantum computing community and became the organizing concept for a decade of experimental effort. Preskill was careful to note that quantum supremacy required careful definition: it was not the same as quantum utility (doing something useful), and classical simulation algorithms would continue improving even as quantum hardware advanced. The essay also introduced the concept of **NISQ** (Noisy Intermediate-Scale Quantum) devices — a framing Preskill would formalize in 2018 but whose outlines he was already articulating in 2012.

Preskill's Caltech quantum information group, and his freely available lecture notes (the "Preskill Lecture Notes on Quantum Computing," first posted online in 1997–1998), had already established him as the field's most influential theorist-communicator. His 2012 contribution shaped the research agenda for the rest of the decade.

## D-Wave Systems: 512-Qubit Vesuvius and Commercial Milestones

**D-Wave Systems**, founded in 1999 in Burnaby, British Columbia, by Geordie Rose, had been pursuing a radically different approach to quantum computing: **quantum annealing** rather than the gate-model (circuit-based) paradigm pursued by academic labs and IBM.

In **May 2012**, D-Wave announced the **Vesuvius** processor, its third-generation device with **512 superconducting flux qubits** connected in a proprietary "Chimera" topology. The announcement came less than 18 months after D-Wave's 128-qubit "Rainier" processor, suggesting an aggressive development pace that drew both admiration and skepticism.

### The Commercial Partnerships

The 2012 commercialization effort gained significant credibility with two announcements:

- **May 2013 (announced/negotiated in 2012)**: **Google** and **NASA** jointly acquired a D-Wave One (subsequently upgraded to Vesuvius), installed at the NASA Ames Research Center in Mountain View, California, to be operated by the **Quantum Artificial Intelligence Laboratory (QuAIL)** — a joint initiative of Google, NASA, and the Universities Space Research Association (USRA). The installation made Google's Quantum AI team one of the first corporate quantum computing operations in the world.
- **D-Wave's investment**: By 2012 D-Wave had raised approximately **US$130 million** in venture capital, including from Goldman Sachs, In-Q-Tel (the CIA's venture arm), and Bezos Expeditions (Jeff Bezos's personal investment office) — signaling that defense, intelligence, and finance sectors saw quantum computing as a near-term strategic interest.

### The Quantum Annealing Debate

D-Wave's claims of quantum advantage were fiercely contested in 2012. The core dispute centered on three questions:

1. **Are D-Wave's qubits truly quantum?** Independent researchers (including Matthias Troyer, ETH Zurich; and Graeme Smith and John Smolin, IBM) argued that D-Wave's benchmarking was insufficiently rigorous to rule out classical explanations for its performance.

2. **Does quantum annealing provide speedup?** Quantum annealing is specifically designed to solve **combinatorial optimization** problems by exploiting quantum tunneling to escape local energy minima. Whether it outperforms classical optimization algorithms (such as simulated annealing or branch-and-bound methods) for practically relevant problem sizes remained unresolved in 2012.

3. **Is quantum annealing a path to universal quantum computing?** The consensus view in academia was no: quantum annealing is not universal (cannot implement arbitrary quantum algorithms including Shor's or Grover's), limiting its ultimate scope. D-Wave did not claim universality, but its aggressive commercialization nonetheless generated backlash from academic quantum computing researchers.

The debate continued through 2013–2015, culminating in a series of benchmark papers (Rønnow et al., *Science* 2014; Denchev et al., 2016) that provided nuanced, context-dependent answers — sometimes D-Wave outperformed classical competitors, sometimes it did not, and the relevant comparison was highly problem-dependent.

## Superconducting Qubits: The UCSB and IBM Programmes

### John Martinis Group (UC Santa Barbara)

The most technically significant academic quantum computing result of 2012 came from **John Martinis's group** at UC Santa Barbara. Martinis, who had been working on superconducting qubits since the late 1990s (at NIST and then UCSB), published a series of papers demonstrating dramatic improvements in qubit coherence and gate fidelity for **Xmon transmon qubits** — a variant of the transmon qubit with a cross-shaped capacitor design that reduced coupling to parasitic electromagnetic modes.

Key results published in 2012–2013:
- Xmon qubit coherence times approaching **44 microseconds** (T₂) — a roughly **10× improvement** over previous superconducting qubit benchmarks at the time
- Single-qubit gate fidelities exceeding **99.6%** using optimal control pulse techniques
- Demonstrations of **simultaneous control** over a linear array of four Xmon qubits with full two-qubit gate capability

These results established the Xmon transmon as the dominant superconducting qubit architecture and underpinned Martinis's subsequent hire by **Google** in September 2014 to lead Google's quantum hardware effort — the team that would produce the 2019 "Sycamore" supremacy demonstration.

### IBM Research (T.J. Watson Research Center)

IBM's quantum computing research program, led by **Jay Gambetta** (then a postdoctoral-era researcher, later IBM's VP of Quantum Computing) and **David DiVincenzo** (who consulted with IBM before moving to RWTH Aachen), continued advancing superconducting transmon qubits at the Thomas J. Watson Research Center in Yorktown Heights, New York.

IBM's 2012 programme focused on:
- **Two-qubit entanglement fidelity**: demonstrated entanglement fidelities approaching 95% for pairs of superconducting qubits on chip
- **3D circuit quantum electrodynamics (3D cQED)**: a technique developed by Paik et al. (IBM/Yale, 2011–2012) encapsulating qubits in three-dimensional microwave cavities rather than planar resonators, dramatically improving coherence by reducing substrate-induced losses
- **Quantum volume**: early conceptual work on metrics for characterizing quantum processor performance beyond raw qubit count — a framework IBM would formalize in 2017 as "Quantum Volume"

IBM's 2012 research laid technical groundwork for the **IBM Quantum Experience**, launched publicly in **May 2016** as the world's first cloud-accessible quantum processor — allowing researchers worldwide to run experiments on real quantum hardware via a web browser.

## Trapped-Ion Quantum Computing

The **trapped-ion approach** — originating with Wineland's NIST group in the 1990s — experienced significant progress in 2012, much of it tied to the Nobel Prize recognition of Wineland's foundational contributions (see also: [Nobel Prize Announcements 2012]({{ '/news/people/nobel-prize-2012/' | relative_url }})).

Key 2012–era trapped-ion results:
- **Two-qubit gate fidelities of 99.9%+** demonstrated in the Wineland group and in Rainer Blatt's group at the University of Innsbruck — the highest gate fidelities of any qubit platform at the time
- **10-qubit entanglement** demonstrated in linear ion traps (Monz et al., Innsbruck, 2011–2012)
- **Quantum error detection** experiments using small stabilizer codes on trapped-ion systems
- **Long coherence times**: trapped-ion qubits demonstrated coherence times of **seconds** (compared to microseconds for superconducting qubits), enabling deeper quantum circuits at the cost of slower gate speeds

The primary limitation of trapped-ion systems in 2012 was **scalability**: adding more ions to a single trap degrades performance, and shuttling ions between traps introduced engineering complexity. Research programs at Innsbruck, Oxford, Duke, and Maryland were exploring modular ion-trap architectures (ion-shuttling, photonic interconnects) to address this constraint.

## Quantum Error Correction: The Critical Bottleneck

The theoretical community coalesced in 2012 around **surface codes** (also called toric codes or topological codes) as the most promising practical route to fault-tolerant quantum computing. Originally proposed by Alexei Kitaev (Moscow/Caltech) in 1997 and developed further by Dennis, Kitaev, Landahl, and Preskill (*Journal of Mathematical Physics*, 2002), surface codes offered:

- **High error threshold**: approximately 1% per gate — achievable by the best 2012 experimental platforms
- **Local operations only**: syndrome measurements require only nearest-neighbor qubit interactions, compatible with 2D chip architectures
- **Flexibility**: suitable for both superconducting qubit and trapped-ion implementations

The **2012 "Surface Code" paper** by Fowler, Martinis, et al. (*Physical Review A* 86, 032324, 2012) provided a comprehensive blueprint for building a large-scale fault-tolerant quantum computer using surface codes, estimating that **approximately 1,000 physical qubits per logical qubit** would be required at 2012-era error rates. This estimate — sobering in its implications — set a long-range engineering target that the field would work toward through the 2020s.

## Photonic Quantum Computing

Alongside superconducting and trapped-ion approaches, **photonic quantum computing** — using single photons as qubits — saw renewed academic interest in 2012, particularly through the development of **integrated photonic circuits** on silicon chips. Key groups at the University of Bristol (Jeremy O'Brien), MIT (Dirk Englund), and TU Delft were demonstrating:

- Multi-photon entanglement in waveguide chips
- Boson sampling (a restricted quantum computation model proposed by Arkhipov and Aaronson in 2011) as a near-term quantum supremacy candidate
- On-chip single-photon detectors using superconducting nanowires

Photonic approaches offered the advantage of room-temperature operation but required advances in single-photon source efficiency and photon-number resolving detectors that were not yet commercially available.

## Investment and Industry Landscape

The 2012 quantum computing investment landscape reflected growing private-sector interest:

| Organization | Activity in 2012 |
|---|---|
| D-Wave Systems | 512-qubit Vesuvius; Google/NASA partnership negotiations |
| IBM Research | 3D cQED; multi-qubit gate demonstrations |
| Google (Quantum AI, pre-official) | D-Wave evaluation; beginnings of superconducting qubit hardware interest |
| Microsoft Research | Station Q (Santa Barbara, led by Michael Freedman) pursuing topological qubits based on Majorana fermions |
| DARPA / NSF | Continued academic programme funding; DARPA Quiness programme for quantum network research |
| In-Q-Tel | D-Wave investment; classified quantum sensing and computing evaluations |

Microsoft's **Station Q** represented a distinctly different bet: rather than pursuing near-term noisy qubits, Microsoft focused on **topological qubits** — hypothetical qubits based on exotic quasiparticles called non-Abelian anyons (specifically Majorana zero modes) that would be intrinsically protected against decoherence by their topological nature. In 2012, Majorana fermion signatures had just been reported experimentally by Kouwenhoven's group at Delft (*Science*, 336, 1003, 2012), lending tentative credibility to Microsoft's approach.

## Significance

2012 established the frame within which quantum computing development would be understood for the remainder of the decade:

- **"Quantum supremacy" as the near-term goal**: Preskill's framing gave hardware teams a concrete, achievable milestone short of practical quantum advantage — one that Google would claim in 2019
- **Superconducting qubits as the leading platform**: Martinis's Xmon results and IBM's 3D cQED advances confirmed superconducting qubits' scalability advantages and set the stage for corporate quantum hardware races
- **Error correction as the critical bottleneck**: The Fowler-Martinis surface code paper quantified the engineering challenge, demonstrating that practical quantum computers required roughly 1,000 physical qubits per logical qubit at 2012 error rates
- **Commercialization as legitimate**: D-Wave's aggressive commercialization, however contested, normalized the idea that quantum devices could be sold and deployed — a psychological shift that accelerated investment across the ecosystem
- **Quantum as national strategy**: The U.S. (DARPA, NSF, In-Q-Tel), EU (European Research Council), Canada (through D-Wave's success), and China (beginning QUESS satellite planning for quantum cryptography) all showed signs that quantum technologies were becoming matters of geopolitical strategy

By year's end, estimates suggested global quantum computing R&D investment — spanning public agencies, private companies, and universities — had crossed **US$500 million annually**, laying the economic foundation for the far larger commitments of the 2016–2025 period.

## See Also

- [Higgs Boson Discovery]({{ '/news/science-technology/higgs-boson-discovery/' | relative_url }}) — the year's other landmark physics milestone, confirming the Standard Model's last missing piece
- [Nobel Prize Announcements 2012]({{ '/news/people/nobel-prize-2012/' | relative_url }}) — Wineland and Haroche's Physics Nobel recognized foundational quantum control work directly relevant to quantum computing
- [Curiosity Rover Mars Landing]({{ '/news/science-technology/curiosity-rover-mars-landing/' | relative_url }}) — NASA's concurrent robotic and AI achievement
- [Apple iPhone 5 Launch]({{ '/news/science-technology/apple-iphone-5-launch/' | relative_url }}) — the year's dominant consumer technology story, whose processors ran on silicon fabricated at scales quantum hardware was still decades from matching
- [SOPA/PIPA 2012 Internet Activism]({{ '/news/science-technology/sopa-pipa-2012-activism/' | relative_url }}) — the year's tech-industry policy clash that shaped internet governance norms quantum networks would eventually inherit

## Sources

- [Quantum computing — Wikipedia](https://en.wikipedia.org/wiki/Quantum_computing)
- [Preskill, J. (2012) "Quantum computing and the entanglement frontier" — arXiv:1203.5813](https://arxiv.org/abs/1203.5813)
- [Fowler et al. (2012) "Surface codes: Towards practical large-scale quantum computation" — *Physical Review A* 86, 032324](https://doi.org/10.1103/PhysRevA.86.032324)
- [Barends et al. (2013) "Coherent Josephson qubit suitable for scalable quantum integrated circuits" — *Physical Review Letters* 111, 080502 (based on 2012 UCSB work)](https://doi.org/10.1103/PhysRevLett.111.080502)
- [D-Wave Systems — Wikipedia](https://en.wikipedia.org/wiki/D-Wave_Systems)
- [Quantum error correction — Wikipedia](https://en.wikipedia.org/wiki/Quantum_error_correction)
- [Superconducting qubit — Wikipedia](https://en.wikipedia.org/wiki/Superconducting_qubit)
- [Trapped-ion quantum computer — Wikipedia](https://en.wikipedia.org/wiki/Trapped-ion_quantum_computer)
- [IBM Quantum Computing — IBM Research](https://research.ibm.com/quantum-computing)
- [Google Quantum AI — Timeline](https://quantumai.google/)
