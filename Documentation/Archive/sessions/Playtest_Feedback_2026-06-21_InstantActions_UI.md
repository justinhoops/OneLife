# OneLife Session-Specific: Playtest Feedback & Decisions — 2026-06-21

**Date:** 2026-06-21 (Sunday, ~12:40 AM MDT)  
**Type:** Playtest + UI Direction Session (one agent session only)  
**Status:** Decisions captured. Can be archived or deleted after Tier 1–2 of permanent plan complete.  
**Permanent Reference:** See /docs/permanent/UI_Overhaul_InstantActions_Plan.md for the full actionable plan this session triggered.

---

## Playtest Summary (What Justin Reported)

- Played a full life (or significant arc) on the latest build post all D4 immersion work + P1–P4 polish + fame/sports/athlete depth.
- Core feedback: "Basically overhaul the UI to fix the recent changes we just made, not everything but mainly instant actions. We can keep the stat bar, and the bottom tab with the domains."
- Specific pain points observed:
  - Recent D4 additions (Year Goal choice, stance selection + chips, life shape in momentum strip / forecasts, focus residue / continuity notes) have started to clutter or compete visually with the instant action "Right Now" grids and quick actions.
  - The powerful frictionless instant layer (static always-available actions, dedicated subdomain quicks for athlete/founder/creator/politics/crime, long-press previews now carrying D4 shape/legacy info) is still there and responsive, but the surface around it feels less clean/glanceable than before the D4 pass.
  - Stat bar (top stat island) and bottom domain tabs remain solid and should be preserved.
  - Long-press preview is useful (now shows shape/legacy carry) but discoverability/affordance could be stronger.
  - Overall: Game feels deep and the new immersion systems are working (quiet years have texture, legacy echoes, adult children carry player focus history), but the instant actions UI needs a targeted surface recovery pass to restore the "frictionless delight" feel without losing the new depth.

No crashes, build issues, or mechanical breakage reported. Focus is purely on information hierarchy, visual calm in action areas, and making powerful systems (previews + D4 context) obvious without adding noise.

---

## Decisions Made This Session ( binding for this agent run)

1. **Scope Lock**: Overhaul is **limited to instant actions / quick actions / frictionless surfaces** (ActionTray, momentum strip in LifeConsoleView, per-domain instant trays in ContentView, preview handling). 
   - Explicitly **keep** top stat bar unchanged (or micro-only if conflict).
   - Explicitly **keep** bottom domain tab bar (light standardization OK if it helps instant visibility, but no full redesign).
   - No new systems, no orchestrator changes, no heavy logic. Pure hierarchy, affordance, copy, layout, and visual separation.

2. **Philosophy**: D4 (stances, shapes, year goals, residue) must remain **supportive texture**, not compete with instant taps. 
   - Instant grids = clean, thumb-friendly, obvious "tap now or hold for preview".
   - D4 depth lives primarily in: long-press previews (1–2 line carry note), year summary cards, journal/forecast flavor, legacy harvest, and next-life meta.
   - Mental model reinforcement: UI should make "instant micro move vs year commitment/stance" boundary feel obvious again.

3. **Create Permanent + Session Files** (this fulfills the COO directive):
   - **Permanent**: `/home/workdir/artifacts/docs/permanent/UI_Overhaul_InstantActions_Plan.md` — full tiered plan, success metrics, files to touch, player impact. Stays in repo for all future agents/team.
   - **This session file**: Captures raw playtest notes + decisions. One-session only. After implementation of the permanent plan tiers, this can be moved to `/docs/sessions/archive/` or deleted. Do not treat as ongoing spec.

4. **Execution Approach**: Follow the exact style of prior successful arcs (D1–D4, P1–P4, S/F phases):
   - Targeted edits only.
   - Build + simulator launch verification after each meaningful slice.
   - Update permanent plan with **COMPLETE** blocks.
   - Keep one-hand play, thumb zone, 2-col grids, floating deltas, ALWAYS badges, long-press previews intact/enhanced.
   - Low overhead: Reuse existing components (previewInstantAction, ActionTray, momentum strip, AppFeedback, etc.).

5. **Priority Order**:
   - Tier 1 first (momentum strip shape pill + action grid affordance + preview D4 lines + visual separation of stance/goal area). This directly addresses the "fix the recent changes" feedback.
   - Tier 2: Domain tab consistency.
   - Tier 3: Polish + longevity test.
   - Then resume broader P5 or next short command.

6. **No Full Redesign**: This is recovery polish, not reinvention. The game was already in a strong playable state post-P4; this sands the one rough surface the latest immersion work created.

---

## Open Items / Risks Captured This Session (for permanent plan)

- Risk: Over-adding "hold" icons or D4 lines could re-introduce density if not kept minimal. Solution: One micro affordance + optional 1-line in preview only.
- Risk: Domain tab count / labels might need tiny standardization for instant visibility. Solution: Light touch only.
- Opportunity: Once instant layer feels clean again, the D4 systems (life shapes writing into quiet years + legacy) will shine more because the surface isn't fighting them.
- Next playtest trigger: After Tier 1 complete, Justin should do another short session focused on instant actions + glance timing + preview usage.

---

## Files Created This Session

- Permanent plan (see above).
- This session file (one-time capture).

All other planning stays in the main IMPLEMENTATION_PLAN.md (which already has excellent D4/P/S/F sections). This session simply triggered a focused sub-plan for the instant UI surface.

---

**Session closed.** The permanent plan is now the living spec for any future agent or coding pass on this topic. Justin can say "tier 1" or "refine the plan around X" or any other short command to proceed.

*This file is session-specific only. Archive or delete after the work ships.*