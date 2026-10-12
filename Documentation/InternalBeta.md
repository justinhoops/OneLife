# Internal beta script

**Distribution:** Direct local-device installs for 3–5 testers. TestFlight is deferred.

## Before handing over a build

- Unit, UI, native core, Debug, and Release simulator gates must be green.
- Run seeds 101, 202, 303, 404, and 505 through the dashboard and debug console using the [seeded checklist](Working/SeededRunChecklist.md).
- Record any device-support or provisional-performance limitation with the build.

## Tester session

Record the tester, device, build commit, run seed, origin, and age of every observation.

For an instrumented session, add the `-playtest` launch argument to the Debug scheme. Recording then starts automatically and remains separate from the gameplay save. Use **Menu → Playtest Notes** to mark a boring year, weak choice, or confusing system. At Life Review, explain what most shaped the outcome and record whether the review agrees before starting a new life. Share the refreshed JSON and Markdown report from the terminal review. The uncapped report resumes by run seed after relaunch and the newest 20 completed reports are retained locally. Release builds expose no recorder UI.

The Markdown export includes a **Sandbox Health** section. Review automatic warnings for a dominant action loop, repeated-action streak, untouched domain, passive years, or unresolved recovery. Warnings identify investigation targets; they are not automatic balance verdicts and require comparison across at least two independent lives.

Before playing, use the **Cohort Run Target** shown on the Debug creation screen. It preselects the next origin and Grind, Social, or Survival style needed by the collected reports; the style is stored only in the diagnostic report and can still be changed in Playtest Notes. Mixed remains available for exploratory runs. Use **Prepare cohort summary** to share the combined gate report. It deduplicates completed lives by seed and reports the origin/style mix, median duration, outcome-explanation coverage, Life Review agreement, next recommended run, recurring evidence, and remaining requirements for Phase 2.

1. Play one life for at least 15–20 years; continue to a complete life when possible.
2. Identify the first year that felt boring.
3. Name one choice that did not feel consequential.
4. Report confusing money, school, or recovery behavior.
5. Confirm whether the next useful action was clear within two seconds.
6. At the ending, explain the outcome in your own words and compare that explanation with Life Review.

Use [InternalBetaRunLog.md](Working/InternalBetaRunLog.md) for every session.

## Triage and exit

- Fix crashes, data loss, inaccessible controls, and dead ends immediately.
- Tune other behavior only when it recurs in at least two independent runs.
- Accumulate at least ten complete lives across all three origins and the Grind, Social, and Survival strategies; Mixed runs are optional.
- Require exported reports for the ten-life gate: at least three Balanced, three Academic, three Social, and one additional run.
- Require a non-empty outcome explanation for every completed life and resolve or validate every reported Life Review mismatch.
- Pass when median complete-life time is 30–45 minutes, strategies feel materially different, no dead ends remain, and the next action is clear within two seconds. A clean cohort does not need to invent a recurring problem; recurring evidence only determines what should be tuned.

Founder E1 remains paused until this gate passes. The beta scope remains School, Cash, Love, Play, cross-cutting Health, three-tier employment, one partner model, basic events/recovery, deterministic console tooling, and life review.
