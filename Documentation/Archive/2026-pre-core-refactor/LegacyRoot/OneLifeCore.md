{\rtf1\ansi\ansicpg1252\cocoartf2869
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # OneLife Core Design Spec - July 2026\
\
## Vision & Key Principles\
- Raw, authentic life simulator ("BitLife killer") with realistic consequences, earned success, and no ultra-exploits.\
- Playable + Immersive + Easy context pickup.\
- Every major system \uc0\u8804 2 taps. Instant feedback. No repetitive chores or filler.\
- Player-driven with glanceable context, optional depth, and meaningful age-up resolutions.\
- Balance via friction, trade-offs, and pressure feedback loops \'97 prevents too easy or chore-like gameplay.\
- Fully offline, private, deterministic core. No runtime AI or APIs.\
\
## Core Interaction Loop\
1. **Glance Layer** (always visible / 1 tap)  \
   - Persistent top **stat island** (Happy, Health, Smart, Looks, Rep, Cash \'97 color-coded/glanceable).  \
   - Bottom or top domain tabs (Education/Work, Finances, Relationships, Health, etc.).  \
   - In active domain: **Current Pressures** overview (2\'964 horizontal bars + High/Med/Low labels + icons).  \
   - Immediately below: 3\'965 **Instant Action** cards from DomainActionRegistry (title, short desc, effect preview tied to current pressures).\
\
2. **Inspect Layer** (player-initiated, fully inside domain view \'97 no popup)  \
   - Tap any pressure bar/icon \uc0\u8594  clean expandable panel or in-place details:  \
     - Why the pressure exists (short, state-based explanation).  \
     - Affected NPCs / elements / history.  \
     - 1\'962 suggested instant actions to address it.  \
   - NPC/relationship depth lives here (tension, recent interactions, personality notes). Player controls when they dive deeper.\
\
3. **Resolve Layer**  \
   - Prominent **AGE UP** button.  \
   - Processes the year (instant actions taken + auto events + pressure resolution).  \
   - Shows clean yearly summary modal: narrative headline, key stat deltas, major story flags, updated pressures for next year.  \
   - Only regular modal. Rare major life events (breakup, firing, health scare) can use similar focused modals.\
\
## Dynamic Domain Islands (Best Addition)\
- Each domain tab functions as its own living "island" with glanceable pressures + instant actions + optional inspect.\
- Consistent UI structure across domains for learnability.\
- Drastically different flavor and mechanical weight per domain (see examples below).\
- Makes context obvious at a glance while supporting deep immersion on demand.\
\
## Balance & Instant Actions\
- **Instant actions are limited like BitLife**: Registry metadata enforces `maxPerYear`, cooldowns, energy/time/money costs, and diminishing returns. Prevents stat grinding/spam.\
- Actions are contextual and pressure-tied: Availability, success odds, and effects shift based on current pressures.\
- Trade-offs and consequences everywhere \'97 good choices yield progress; neglect or bad luck creates believable setbacks in age-up summaries.\
- Pressures create natural friction loops: High pressure unlocks risky/high-reward options but increases negative outcome chances if ignored.\
- Goal: Realistic difficulty curve with earned success. No exploits, no endless chores.\
\
## Pressures (Domain-Specific, Consistent Depth)\
- Glance: Bars + labels + icons.  \
- Inspect: Deeper why + NPCs + suggestions.  \
- Dynamic: Change based on actions, auto events, and time. Influence action availability/outcomes.  \
- Domain flavor examples (same UI, different feel):\
  - **Education/Work**: Deadline Stress (urgency), Workload (burnout), Skill Gap (competence). High Deadline unlocks "Cram" but risks Health/Relationships.\
  - **Relationships**: Emotional Tension, Neglect/Distance, Interference. Personality-influenced; inspect shows specific NPC notes.\
  - **Finances**: Cash Flow Strain, Debt Burden, Opportunity Cost. Mathematical/compounding feel.\
  - **Health**: Fatigue, Illness Risk, Lifestyle Decay. More passive decay; affects other domains.\
\
## NPCs & Relationships\
- Feel alive via **simple personality traits** (flags/vectors, e.g., Avoidant, Ambitious, Supportive, Jealous) + large **scenario banks**.\
- Traits influence pressure evolution, scenario selection, and action outcomes.\
- Scenario banks: Pre-generated or template-based (thousands of unique micro-events). Triggers based on pressures + traits + state. Runtime is pure lookup + rules \'97 deterministic.\
- AI used **only offline** during development for generating initial scenario/narrative content. No runtime AI, no APIs, fully private.\
- Context surfaces in Relationships domain inspect panel and age-up summaries. No constant popups.\
\
## Technical Foundation\
- **DomainActionRegistry**: Single source of truth. Actions include prereqs, effects, pressure impacts, limits, and metadata for suggestions/scenarios.\
- Console simulation (`LifeConsoleView`): Primary testing tool. Must support full loop with pressures, limits, scenarios, and multi-year runs for balance.\
- Delete dead UI aggressively. Wire everything from registry.\
- Onboarding: Short guided first year demonstrating glance \uc0\u8594  inspect \u8594  action \u8594  age-up.\
\
## Future Polish / Non-v1\
- Haptics, subtle animations on pressure changes.\
- Progressive disclosure for new players.\
- Lightweight on-device AI (optional, post-v1) for extra narrative variety if needed.\
- Deeper NPC arcs or expanded scenario banks via updates.\
\
This model delivers end-to-end playability with discoverability, immersion, and balance while staying true to the raw/authentic vision. Prioritize console validation of pressures + action limits + basic scenarios before heavy UI work.}