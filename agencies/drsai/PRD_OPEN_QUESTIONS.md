# PRD: Open Questions Tracker

**Document:** DrSAI PRD  
**Last Updated:** 2025-12-28  
**Status:** Open

---

## Open Questions

| # | Question | Category | Owner | Due | Status | Notes |
|---|----------|----------|-------|-----|--------|-------|
| 1 | Is the fine-tuned Llama-3.2-Seuss-70B model already trained, or does it need to be created? What is the timeline? | Technical / Dependency | ML Team (TBD) | Before Alpha start | Open | Critical blocker - cannot proceed without model |
| 2 | Do we have legal access to the 44 Dr. Seuss books for training data? Do we need licensing? | Legal / Dependency | Legal (TBD) | Before Alpha start | Open | High risk - copyright concerns |
| 3 | Can we use a transformative fair-use approach for Dr. Seuss style? Should we consult IP attorney? | Legal / Risk | Legal (TBD) | Before Alpha start | Open | Risk R2 - high impact if wrong |
| 4 | Should we build the scansion engine internally or use an existing library? What is the timeline? | Technical / Dependency | Engineering (TBD) | Alpha planning | Open | Medium risk - needed for quality gate |
| 5 | What is the exact methodology for the user study (A/B test design, recruitment, "smile" measurement)? | Product / Testing | Product (TBD) | Alpha planning | Open | Needed for hypothesis validation |
| 6 | Is the cost target (< $0.10 per generation) realistic based on current model inference costs? | Business / Cost | Engineering (TBD) | Alpha planning | Open | May need adjustment based on actual costs |
| 7 | What is the pricing model for authenticated API users? Free tier limits vs paid tier? | Business / Monetization | Product (TBD) | Beta planning | Open | Not blocking MVP, but needed for Beta |
| 8 | Who are the specific owners for ML Team, Engineering, Legal, Product? | Organizational | TBD | ASAP | Open | Several dependencies and risks need owners |
| 9 | Should we support web UI in addition to CLI, or is CLI-first approach sufficient for MVP? | Product / Scope | Product (TBD) | Alpha planning | Open | Current scope is CLI-only, may need to revisit |
| 10 | What happens if meter compliance is <98% but >95%? Do we reject, warn, or accept? | Technical / Quality | Engineering (TBD) | Alpha planning | Open | Edge case in quality requirements |
| 11 | How do we handle topics that are inappropriate for all-ages content (violence, etc.)? Content filter approach? | Product / Safety | Product (TBD) | Alpha planning | Open | Edge case - "wrap in hope and silliness" needs implementation |
| 12 | Should we support batch generation (multiple topics at once) or only single requests? | Product / Scope | Product (TBD) | Beta planning | Open | Not in current scope, may be requested |
| 13 | What is the fallback if ElevenLabs API is unavailable or too expensive? Standard TTS? | Technical / Dependency | Engineering (TBD) | 1.0 planning | Open | P2 feature, but need fallback plan |
| 14 | Do we need to support authentication/API keys for MVP, or is IP-based rate limiting sufficient? | Technical / Security | Engineering (TBD) | Alpha planning | Open | Current plan is IP-based, may need auth for Beta |
| 15 | What is the exact definition of "anapestic tetrameter compliance"? How do we handle variations? | Technical / Quality | ML Team (TBD) | Alpha planning | Open | Core quality metric needs precise definition |

---

## Questions by Category

### Technical (6 questions)
- Questions: 1, 4, 10, 13, 14, 15
- Priority: High (blockers for Alpha)

### Legal (2 questions)
- Questions: 2, 3
- Priority: High (blockers for Alpha)

### Product (4 questions)
- Questions: 5, 9, 11, 12
- Priority: Medium (needed for Alpha/Beta planning)

### Business (2 questions)
- Questions: 6, 7
- Priority: Low-Medium (not blocking MVP)

### Organizational (1 question)
- Questions: 8
- Priority: High (needed ASAP)

---

## Questions by Priority

### Critical (Must Answer Before Alpha)
- Q1: Model availability
- Q2: Training data legal access
- Q3: Fair-use legal approach
- Q8: Owner assignments
- Q15: Meter compliance definition

### High (Should Answer During Alpha Planning)
- Q4: Scansion engine approach
- Q5: User study methodology
- Q6: Cost validation
- Q10: Meter compliance edge case
- Q11: Content filtering
- Q14: Authentication approach

### Medium (Can Answer During Beta Planning)
- Q7: Pricing model
- Q9: Web UI consideration
- Q12: Batch generation
- Q13: ElevenLabs fallback

---

## Resolution Tracking

**Resolved Questions:** 0  
**Open Questions:** 15  
**Blocking Alpha:** 5  
**Blocking Beta:** 3  
**Future Considerations:** 7

---

**Next Review:** Weekly during Alpha planning phase



