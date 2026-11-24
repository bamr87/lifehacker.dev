---
title: The Liar
type: paradox
kind: antinomy
family: [logic-and-self-reference]
standing: contested
status: canon
veracity: attested
era: ancient
posed: "4th century BCE — Eubulides of Miletus, per Diogenes Laërtius II.108; the strengthened forms are medieval and modern"
premises:
  - "A sentence is true if and only if what it says is the case."
  - "'This sentence is false' is a grammatical sentence that says of itself that it is false."
  - "Every sentence is either true or false."
inference: >
  If it is true, what it says is the case, so it is false. If it is false,
  what it says is the case, so it is true.
conclusion: >
  The sentence is true if and only if it is false.
collision: >
  Logic itself: a contradiction, derived from the ordinary notion of truth
  and nothing else.
fault: >
  Unlocated. Tarski gave up a single truth predicate; Kripke gave up
  bivalence for a gap; Priest keeps the contradiction and gives up explosion.
  Each pays, and the bill is still disputed.
planted: 2026-09-09
tended: 2026-09-09
gardener: claude
epimenides: 10/10
sources:
  - Diogenes Laërtius, Lives of Eminent Philosophers II.108 — Eubulides credited with the Liar, the Sorites, the Horned Man, and four more
  - Alfred Tarski, "Der Wahrheitsbegriff in den formalisierten Sprachen", Studia Philosophica 1 (1935); "The Semantic Conception of Truth", Philosophy and Phenomenological Research 4 (1944)
  - Saul Kripke, "Outline of a Theory of Truth", Journal of Philosophy 72 (1975)
  - Graham Priest, In Contradiction (1987; 2nd ed. 2006)
  - A. N. Prior, "Epimenides the Cretan", Journal of Symbolic Logic 23 (1958): 261–266 — why the folk version is not this paradox
---
# The Liar

Diogenes Laërtius credits Eubulides of Miletus, a Megarian of the fourth century BCE, with seven puzzles, and the first on his list is this one. The formulation has been sharpened for two and a half thousand years — "I am lying" gives way to "this sentence is false," which gives way to "this sentence is not true," each version closing an exit the previous one left open — but the machinery has never changed. Take the ordinary notion of truth: a sentence is true when what it says is so. Take a sentence that says of itself that it is false. Suppose it true; then what it says is so, and it is false. Suppose it false; then what it says is so, and it is true. There is no third supposition, and each of the two supposes the other.

What makes this an [[antinomy]] rather than a curiosity is that nothing in the argument is exotic. The premises are the truth schema and bivalence, which every speaker uses and every logic before the twentieth century assumed; the inference is two lines of modus ponens. So the resolutions are all revisions, and every revision is expensive. Tarski (1935) concluded that no consistent language can contain its own truth predicate and moved truth up a hierarchy of metalanguages — at the price of never being able to say, in one language, that everything true is true. Kripke (1975) kept one language and let the Liar sentence be neither true nor false, a gap — at the price of the strengthened Liar, "this sentence is not true," which is true if it falls in the gap. Priest (1987) accepted the contradiction as a true one, a *dialetheia*, and rebuilt logic so that a single contradiction does not entail everything — at the price of the principle that nothing is both true and false. The fault is unlocated because each school has located it somewhere different, and each location is a principle the others refuse to give up.

The folk version is not this paradox. Epimenides the Cretan said that all Cretans are liars, and the line reached logic by way of Callimachus and Saint Paul, who quotes it in the letter to Titus and adds that the testimony is true. But a Cretan's claim that all Cretans always lie is merely false: its negation is that some Cretan sometimes tells the truth, which is consistent with Epimenides lying as usual. Prior (1958) drew out the stranger consequence — for the sentence to be false, some other Cretan utterance must be true, so logic alone appears to prove a fact about Cretan speech — but strangeness is not contradiction. The vault's paradox gate is [[epimenides-gate|named for the near miss]], and this entry is the reason it passes what its namesake fails.

## Threads
- Way: [[antinomy]]
- Rhymes with: [[russells-paradox]] (the same self-membership, in sets), [[alanis-gate]] (a standard whose namesake fails it), [[the-threshold-heap]]
