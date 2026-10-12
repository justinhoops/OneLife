#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="${ONELIFE_PROBE_BINARY:-${TMPDIR:-/tmp}/onelife-core-probe}"

SOURCES=(
  "$ROOT/Scripts/CoreRuntimeProbe.swift"
  "$ROOT/OneLife/EconomyPolicy.swift"
  "$ROOT/OneLife/AssetState.swift"
  "$ROOT/OneLife/CriminalPathState.swift"
  "$ROOT/OneLife/CriminalLegalPipeline.swift"
  "$ROOT/OneLife/DomainAction.swift"
  "$ROOT/OneLife/DomainActionRegistry.swift"
  "$ROOT/OneLife/EssentialLifeDomains.swift"
  "$ROOT/OneLife/LifeEvent.swift"
  "$ROOT/OneLife/LifeEventRegistry.swift"
  "$ROOT/OneLife/LifeContentPack.swift"
  "$ROOT/OneLife/LegalState.swift"
  "$ROOT/OneLife/LifePersistence.swift"
  "$ROOT/OneLife/LifeSimulator.swift"
  "$ROOT/OneLife/LifeState.swift"
  "$ROOT/OneLife/LifeSystems.swift"
  "$ROOT/OneLife/PartnerReactivitySystem.swift"
  "$ROOT/OneLife/PersonalitySystem.swift"
  "$ROOT/OneLife/ReactionSystem.swift"
  "$ROOT/OneLife/PersistentSituations.swift"
  "$ROOT/OneLife/PlaytestRecorder.swift"
  "$ROOT/OneLife/PrisonState.swift"
  "$ROOT/OneLife/SeededRandom.swift"
  "$ROOT/OneLife/WorldState.swift"
)

NEEDS_BUILD=0
if [[ ! -x "$OUTPUT" ]]; then
  NEEDS_BUILD=1
else
  for source in "${SOURCES[@]}"; do
    if [[ "$source" -nt "$OUTPUT" ]]; then
      NEEDS_BUILD=1
      break
    fi
  done
fi

if [[ "$NEEDS_BUILD" -eq 1 ]]; then
  xcrun swiftc -O -default-isolation MainActor -o "$OUTPUT" "${SOURCES[@]}"
fi

ONELIFE_CONTENT_PATH="$ROOT/OneLife" "$OUTPUT" "$@"
