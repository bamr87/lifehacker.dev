---
title: Hilbert's Hotel
type: paradox
kind: veridical
family: [infinity-and-motion]
standing: resolved
status: canon
veracity: attested
era: modern
posed: "1924 — David Hilbert, in a Göttingen lecture on the infinite, never published; dated to January by Kragh's reading of the lecture notes. Popularised by George Gamow in One Two Three… Infinity (1947)"
premises:
  - "A hotel has infinitely many rooms, numbered 1, 2, 3, and so on, and every room is occupied."
  - "A full hotel has no vacancy: to house a new guest, someone must leave."
  - "The manager may ask every guest to move at once."
inference: >
  Move the guest in room n to room n + 1. Every guest still has a room, no
  guest has left, and room 1 is empty.
conclusion: >
  A completely full hotel accommodates a new guest — and, by moving each
  guest from room n to room 2n, infinitely many new guests.
collision: >
  The intuition that full means no vacancy — an intuition, not a fact, which
  makes the conclusion true and the paradox veridical.
fault: >
  The second premise, which is a truth about finite hotels mistaken for a
  truth about hotels. An infinite set can be matched one-to-one with a
  proper part of itself; Dedekind made that the definition of infinite.
planted: 2026-09-09
tended: 2026-09-09
gardener: claude
epimenides: 8/10
sources:
  - Helge Kragh, "The True (?) Story of Hilbert's Infinite Hotel", arXiv:1403.0059 (2014) — traces the hotel to Hilbert's January 1924 lecture and its silence until Gamow
  - George Gamow, One Two Three… Infinity (1947)
  - Galileo Galilei, Discorsi (1638), the first day — the squares matched to the whole numbers
  - Richard Dedekind, Was sind und was sollen die Zahlen? (1888), definition 64
---
# Hilbert's Hotel

For most of a century nobody could say whether Hilbert had actually proposed the hotel that bears his name; Kragh (2014) found it in the notes of a Göttingen lecture from early 1924 — given, never published, and then popularised by Gamow in 1947 with the details everyone now repeats. The hotel has a room for every natural number and a guest in every room. A traveller arrives. The manager asks each guest to move up one — room one to room two, room two to room three — and hands the traveller the key to room one. When a coach arrives carrying infinitely many travellers, the manager sends each guest from room *n* to room *2n* and gives the newcomers the odd rooms. No guest has left. The hotel was full. The hotel is full again, with more people in it.

The argument is sound and the conclusion is true, which is what makes this the vault's cleanest [[veridical]] paradox: nothing gives way except an intuition, and the intuition was never about infinity in the first place. "Full means no vacancy" is a theorem about finite collections — a finite set cannot be matched one-to-one with a proper part of itself — and the hotel is simply the place where that theorem is caught being applied outside its jurisdiction. Galileo saw the same thing in 1638 when he matched the perfect squares to the whole numbers and found neither collection larger than the other, and concluded, reasonably for his century, that *larger* and *smaller* do not apply to infinities. Dedekind (1888) took the opposite lesson and made the anomaly the definition: a set is infinite exactly when it can be put in one-to-one correspondence with a proper part of itself. That is the cost of the paradox, and it was paid before Hilbert told the story. The hotel is an illustration of a settled result, which is why it is filed `resolved`: the guests still have to move, but nobody argues about where.

## Threads
- Way: [[veridical]]
- Rhymes with: [[achilles-and-the-tortoise]] (infinity refusing to behave like a large number), [[the-borges-condition]] (a complete collection that still has room)
