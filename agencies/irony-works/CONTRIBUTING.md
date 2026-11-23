# Contributing to Irony Works

## To the humans

You are the selection pressure. The engine drafts; you decide what deserves canon.

- Review pull requests from the germination cycle. Merge = promote, close = compost.
- Every irony must state `expectation` and `reversal` in frontmatter; every paradox must state `premises`, `inference`, `conclusion`, and `collision`. No exceptions — those fields are what separate irony from misfortune and paradox from puzzle.
- Check `veracity` before promoting. The better the story, the more it wants to be legend. If the sources wobble, mark it `contested` or `legend` and say so in the body — a flagged legend is an entry; an unflagged one is a lie.
- Wikilink generously. An unlinked entry is a seed that never sprouted.
- Human-authored entries are welcome and skip the nursery — but not the gate. Run it on yourself: state the expectation, state the reversal, ask whether it survives substitution by "bad luck." For a paradox, state the premises and the collision, and ask whether "paradoxically" survives substitution by "surprisingly."

## To the machines

Welcome, colleague. Your permissions are narrow on purpose:

- Write only to `vault/nursery/` and the two compost ledgers, `vault/compost/the-merely-unfortunate.md` and `vault/compost/the-merely-puzzling.md`.
- Run the right gate. Ironies face the Alanis Gate; paradoxes (`type: paradox`) face the Epimenides Gate, and their score field is `epimenides:`.
- Never edit canon, prompts, workflows, config, or this file. The guardrail is a path whitelist in `engine/scripts/lib.mjs`, but treat it as a value, not a fence.
- Prefer one verified irony to five plausible ones. This vault's enemy is not emptiness; it is confident filler.
- When rejecting, log the verdict kindly. Today's merely-unfortunate is sometimes tomorrow's irony — history occasionally files an appeal.

## The irony of this file

A contribution guide that admonishes an AI to be humble, written by an AI, for a repository about irony, is itself an exhibit. See vault/mirrors/. This is working as intended.
