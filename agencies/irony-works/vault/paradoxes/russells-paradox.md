---
title: Russell's Paradox
type: paradox
kind: antinomy
family: [logic-and-self-reference]
standing: resolved
status: canon
veracity: attested
era: modern
posed: "1901 — Bertrand Russell, working through Cantor; communicated to Frege by letter, 16 June 1902. Zermelo claimed, in 1908, to have found it independently and earlier"
premises:
  - "For any property, there is a set of exactly the things that have it (unrestricted comprehension)."
  - "Sets can be members of sets, and 'is not a member of itself' is a property like any other."
inference: >
  Let R be the set of all sets that are not members of themselves, and ask
  whether R is a member of R. If it is, it fails the defining property, so
  it is not. If it is not, it satisfies the property, so it is.
conclusion: >
  R is a member of itself if and only if it is not.
collision: >
  Logic itself: a contradiction derived from the one principle naive set
  theory rested on.
fault: >
  The first premise. Unrestricted comprehension was replaced — by Zermelo's
  separation axiom, which only carves subsets out of sets already given, and
  by Russell's theory of types, which forbids a set from ranging over
  itself. Neither restores the naive principle; both make the question
  unaskable.
planted: 2026-09-09
tended: 2026-09-09
gardener: claude
epimenides: 10/10
sources:
  - Russell to Frege, 16 June 1902, and Frege's reply of 22 June 1902, in van Heijenoort (ed.), From Frege to Gödel (1967)
  - Gottlob Frege, Grundgesetze der Arithmetik, vol. II (1903), afterword
  - Bertrand Russell, The Principles of Mathematics (1903), ch. X; "Mathematical Logic as Based on the Theory of Types", American Journal of Mathematics 30 (1908)
  - Ernst Zermelo, "Neuer Beweis für die Möglichkeit einer Wohlordnung" (the claim of prior discovery) and "Untersuchungen über die Grundlagen der Mengenlehre I" (the separation axiom), both Mathematische Annalen 65 (1908)
---
# Russell's Paradox

In June 1902 Bertrand Russell wrote to Gottlob Frege, whose life's work — a derivation of arithmetic from logic — was at the printer in its second volume, to report a difficulty. Frege's system allowed a set for every definable property. Consider, Russell wrote, the property of not being a member of oneself; most sets have it, since the set of teacups is not a teacup. Now form the set *R* of all sets with that property, and ask whether *R* belongs to itself. If it does, then by definition it does not; if it does not, then by definition it does. Frege replied within the week that the ground on which he had meant to build arithmetic had begun to give way, and added an afterword to the volume conceding that a scientific writer could hardly meet anything worse than to have a foundation shaken after the work was finished. Zermelo later claimed to have found the same contradiction on his own, and the record allows it; but Russell wrote the letter.

The paradox is a perfect [[antinomy]], and its resolution is the vault's model of what resolving one costs. The reasoning is two lines and unimpeachable. The second premise — that self-membership is a property like any other — is what Cantor's sets had always allowed. So the fault had to be the first, and the first premise was the *whole* of naive set theory: that a property determines a set. Zermelo's axioms (1908) replaced it with separation, which lets you collect the members of an existing set that satisfy a property but never conjure a set from a property alone, so that the set of all sets, and *R* with it, is never formed. Russell's own repair (1908) was the theory of types, a hierarchy in which a set can only contain things of the level below, so that "is a member of itself" is not false but ungrammatical. Both are restrictions, both are still in use, and neither tells you which is true; they tell you what you can no longer say. The paradox's standing is `resolved` in the only sense an antinomy ever is: the concept that produced it was withdrawn, and mathematics was rebuilt on a narrower one — Quine's point that an antinomy establishes that some trusted pattern of reasoning must be made explicit and henceforward avoided or revised.

## Threads
- Way: [[antinomy]]
- Rhymes with: [[the-liar]] (self-reference, in sentences), [[the-kodak-moment]] (a foundation undone by what it was built to contain), [[the-borges-condition]]
