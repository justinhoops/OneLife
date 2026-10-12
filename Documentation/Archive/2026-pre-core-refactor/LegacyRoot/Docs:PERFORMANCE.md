{\rtf1\ansi\ansicpg1252\cocoartf2869
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # OneLife Performance.md\
\
**Goal:** Maintain 60fps console + full-life sims under 16ms/tick on device.\
\
## Current Benchmarks (Update after each sprint)\
- Baseline (post-P4): [Add your Instruments data here]\
- Target: 80-year life with family \uc0\u8804  200ms total simulation time\
\
## Hotspots & Fixes\
### P5.0 \'96 Documentation & Quick Wins\
- [ ] Instruments audit complete\
- [ ] Domain hibernation strengthened\
- [ ] Lazy UI + reduced @Observable scope\
\
### Techniques Used\
- Caching (DomainCacheArtifacts)\
- Memoization\
- Async narrative\
- LazyVStack + stable IDs\
\
## Verification Checklist\
- [ ] Full normal life plays smoothly\
- [ ] Athlete edge case no hitches\
- [ ] Console navigation = instant\
\
Update this file after every performance change.}