---
title: "Quantum Entanglement Teleportation Breakthrough"
layout: article
permalink: /news/science-technology/quantum-entanglement-teleportation/
date: 2013-04-02
categories:
  - Science & Technology
tags:
  - quantum computing
  - physics
  - telecommunications
excerpt: "In 2013 physicists in Germany, Switzerland, and Denmark teleported quantum states between stationary matter qubits—single atoms, superconducting circuits, and atomic ensembles—advancing the building blocks of quantum networks and quantum computing."
preview: /images/previews/science-technology.svg
---

**Key figures**: Christian Nölleke, Stephan Ritter, Gerhard Rempe (Max Planck Institute of Quantum Optics); Lars Steffen, Andreas Wallraff (ETH Zurich); Charles H. Bennett (quantum teleportation theory); Anton Zeilinger (first photonic teleportation)

## Summary

During 2013, several independent research groups reported milestone demonstrations of quantum teleportation between stationary "matter" qubits—the physical systems, such as atoms and superconducting circuits, that can store and process quantum information. Where earlier teleportation experiments had chiefly transferred quantum states between fast-moving photons, the 2013 results showed that quantum states could be reliably transferred between the kinds of qubits that would serve as the nodes of a future quantum network or the registers of a quantum computer.

The most cited of these results was published on April 2, 2013, in *Physical Review Letters* by Christian Nölleke, Stephan Ritter, Gerhard Rempe, and colleagues at the Max Planck Institute of Quantum Optics in Garching, Germany. The team teleported the quantum state of one single atom onto a second single atom held in a separate laboratory 21 metres away, each atom trapped inside an optical cavity that greatly improved the efficiency of collecting the photons used to link them. The experiment achieved a teleportation fidelity of about 88 percent and a success probability of roughly 0.1 percent—nearly five orders of magnitude higher than in previous experiments with remote material qubits, and well above the threshold at which the transfer cannot be explained by classical means.

Quantum teleportation—the transfer of a quantum state from one particle to another without transmitting the particle itself—had been proposed theoretically in 1993 by Charles H. Bennett and colleagues and first demonstrated with photons in 1997. The 2013 experiments extended the technique to atoms held in place as quantum memories, to superconducting circuits on a chip, and to macroscopic atomic ensembles, collectively marking the year as a turning point in the effort to build practical quantum information infrastructure.

## Background: Quantum Teleportation Theory

Quantum teleportation emerged from theoretical work in the early 1990s exploring how quantum information could be transmitted without sending the quantum system itself. In their 1993 paper, Bennett and colleagues showed that if two particles are entangled—a quantum state in which the particles remain correlated even at arbitrary distances—then measuring the joint state of the particle to be teleported together with one member of the entangled pair, and transmitting that measurement result classically to a distant location, allows the original quantum state to be reconstructed on the other member of the pair without ever moving the original particle.

This process violates neither the no-cloning theorem (a quantum state cannot be perfectly copied) nor relativistic causality (no information travels faster than light, because the classical measurement result is transmitted at light speed or slower). No usable information about the teleported state can be extracted from the measurement result alone; the state is recovered only when the receiving station applies a correction determined by that result. Quantum teleportation therefore transfers the state without enabling faster-than-light signalling. The first experimental demonstrations, using photons, were reported in 1997 by Anton Zeilinger's group in Innsbruck and by a group in Rome.

## The 2013 Milestones: Teleporting Between Matter Qubits

The distinctive contribution of 2013 was teleportation between *stationary* systems capable of storing quantum information, rather than between the photons that carry it.

- **Single atoms as quantum memories (Max Planck Institute of Quantum Optics).** The Garching team confined two individual rubidium atoms in optical cavities in separate laboratories connected by a 60-metre optical fibre, with the atoms 21 metres apart. Each atom emitted a photon whose polarization was entangled with the atom's internal spin state; a joint (Bell-state) measurement on the two photons projected the distant atoms into an entangled state, and a final measurement and correction teleported the state of one atom onto the other. Because the atoms remain in place and can hold a quantum state for an extended time, the demonstration realized teleportation between two nodes that could act as memories in a quantum network.

- **Superconducting circuits on a chip (ETH Zurich).** In a paper published in *Nature* on August 15, 2013, Lars Steffen, Andreas Wallraff, and colleagues reported the first fully deterministic quantum teleportation in a solid-state system, transferring quantum states between two superconducting circuits about six millimetres apart on a single chip. Unlike photonic schemes, which succeed only probabilistically, the experiment used real-time feed-forward electronics to complete the teleportation on every attempt, at a rate on the order of 10,000 times per second—an approach directly relevant to processors built from superconducting qubits.

- **Macroscopic atomic ensembles (University of Copenhagen).** A group led by Eugene Polzik reported deterministic teleportation of a quantum state between two clouds of caesium atoms, each containing about a billion atoms, published in *Nature Physics* in 2013. The result showed that teleportation could operate between large, macroscopic collections of matter rather than only between individual particles.

## Practical Implications: Quantum Repeaters and Networks

The significance of teleporting between matter qubits lay in its relevance to building quantum networks. Classical fibre-optic networks rely on repeaters—devices that receive a degraded signal and re-amplify or retransmit it. Quantum states cannot be copied (the no-cloning theorem), making conventional repeater amplification impossible for quantum communication. Instead, **quantum repeaters** are proposed to extend quantum communication by dividing a long link into segments, generating entanglement within each segment using stored qubits, and then joining the segments through **entanglement swapping**—a procedure closely related to teleportation, in which entanglement is transferred so that two particles that never interacted become entangled.

Teleportation between quantum memories, as demonstrated at Garching, is a core ingredient of this scheme: the stationary atoms can hold entanglement until neighbouring segments are ready to be linked. The 2013 experiments thus represented concrete progress toward the hardware that a quantum internet—connecting quantum processors, sensors, and cryptographic systems across distance—would require.

## Quantum Computing and Quantum Advantage Context

The 2013 teleportation advances occurred within a period of accelerating investment in quantum computing. IBM, Google, Microsoft, and academic groups were expanding research into quantum processors, with a central challenge being how to scale such machines—adding more qubits while maintaining coherence and reducing error rates. Quantum networks, enabled by teleportation and quantum repeaters, offered one route toward distributed quantum computing, in which processors at different locations share entanglement to work on problems larger than a single device could handle. The ETH Zurich demonstration was especially notable in this context because superconducting circuits are among the leading platforms for building quantum computers, and deterministic on-chip teleportation is a primitive used in some models of quantum computation.

## Distance Records and Free-Space Precursors

Running alongside the 2013 work on matter qubits was a separate line of research pushing the *distance* over which photonic quantum states could be teleported. In 2012, a group led by Jian-Wei Pan at the University of Science and Technology of China teleported quantum states across roughly 97 kilometres of open air over Qinghai Lake, a result published in *Nature* in August 2012. Weeks later, Anton Zeilinger's group reported free-space teleportation over 143 kilometres between the Canary Islands of La Palma and Tenerife, published in *Nature* in September 2012. These free-space demonstrations, which immediately preceded the 2013 matter-qubit results, established that the classical and quantum channels required for teleportation could be maintained over distances relevant to satellite links, and they directly informed later satellite-based quantum experiments.

## The Path Toward a Quantum Internet

The 2013 results were part of a broader international effort to develop quantum networks. In subsequent years the Chinese government funded the **Micius** quantum satellite, launched in August 2016, which in 2017 demonstrated entanglement distribution and ground-to-satellite quantum teleportation over more than 1,000 kilometres—extending the free-space technique to space. China also deployed a fibre-based quantum-secured communication backbone connecting Beijing and Shanghai over roughly 2,000 kilometres, while the European Union launched the Quantum Internet Alliance to pursue similar goals. The matter-qubit teleportation of 2013 supplied a complementary piece of this program: the stationary memory nodes that a repeater-based quantum internet would connect.

## Significance

The 2013 teleportation results marked a shift in quantum information science from demonstrations that moved quantum states between flying photons toward demonstrations that moved them between the stationary qubits used to store and process information. Teleportation between single atoms, between superconducting circuits, and between atomic ensembles—reported by three independent groups within a single year—showed that the technique was becoming a practical tool rather than a laboratory curiosity.

More broadly, the year illustrated the pace at which quantum information science was maturing. In 2013 quantum computers remained small and error-prone and quantum networks remained experimental, but the matter-qubit teleportation demonstrations, together with the earlier free-space distance records, indicated that the hardware and theoretical frameworks needed to build quantum networks existed and could be improved through engineering effort. The experiments also reflected the field's international breadth, with landmark contributions from Germany, Switzerland, Denmark, Austria, and China.

## 2013 Scientific Context: A Year of Physics Milestones

The teleportation advances arrived in the same year as CERN's confirmation of the Higgs boson by the ATLAS and CMS collaborations (see [Higgs Boson Confirmation](/news/science-technology/higgs-boson-confirmation/)). Where the Higgs confirmation completed the Standard Model of particle physics—a decades-long theoretical project—the teleportation results advanced quantum information science along a more applied trajectory. Together, these achievements illustrated 2013 as a year of major physics breakthroughs at both fundamental and applied levels.

Google Glass's public launch in 2013 (see [Google Glass Launch](/news/science-technology/google-glass-launch/)) illustrated a different strand of the same technological ambition: the convergence of computing, sensing, and networking in wearable devices. The quantum internet and consumer wearable computing represented divergent technological visions—one operating at the level of individual atoms and photons, the other at the level of consumer hardware and augmented reality—yet both were animated by the same conviction that computing's physical and informational boundaries were rapidly expanding.

## See Also

- [Higgs Boson Confirmation](/news/science-technology/higgs-boson-confirmation/) — the other landmark physics result of 2013
- [Google Glass Launch](/news/science-technology/google-glass-launch/) — 2013's parallel vision of networked computing in physical space
- [Bitcoin Price Surge](/news/society-economics/bitcoin-price-surge/) — quantum cryptography's future relevance to financial security systems

## Sources

- [Efficient Teleportation Between Remote Single-Atom Quantum Memories — *Physical Review Letters* 110, 140403 (2013)](https://link.aps.org/doi/10.1103/PhysRevLett.110.140403)
- [Deterministic quantum teleportation with feed-forward in a solid state system — *Nature* 500, 319 (2013)](https://www.nature.com/articles/nature12422)
- [Deterministic quantum teleportation between distant atomic objects — *Nature Physics* 9, 400 (2013)](https://www.nature.com/articles/nphys2631)
- [Quantum teleportation — Wikipedia](https://en.wikipedia.org/wiki/Quantum_teleportation)
- [Quantum teleportation and entanglement distribution over 100-kilometre free-space channels — *Nature* 488, 185 (2012)](https://www.nature.com/articles/nature11332)
- [Quantum teleportation over 143 kilometres using active feed-forward — *Nature* 489, 269 (2012)](https://www.nature.com/articles/nature11472)
- [Micius (satellite) — Wikipedia](https://en.wikipedia.org/wiki/Micius_(satellite))
- [Quantum repeater — Wikipedia](https://en.wikipedia.org/wiki/Quantum_repeater)
