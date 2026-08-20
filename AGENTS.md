# AGENTS.md

Instructions for AI coding agents (Codex, Claude Code, etc.) working on QGroundControl.

## Quick References

- [CODING_STYLE.md](CODING_STYLE.md) — Naming, formatting, C++20 features, QML style, logging
- [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md) — Architecture patterns (Fact System, Multi-Vehicle, FirmwarePlugin)
- [tools/README.md](tools/README.md) — Development scripts and tooling
- [test/README.md](test/README.md) — Test framework, base classes, CTest labels, MultiSignalSpy, coverage
- [.github/ci-overview.md](.github/ci-overview.md) — CI workflow/action/script layout and conventions
- [.pre-commit-config.yaml](.pre-commit-config.yaml) — All enforced linters (clang-format, clang-tidy, ruff, pyright, shellcheck, actionlint, zizmor, qmllint, clazy, vehicle-null-check, check-no-qassert, check-no-qtest-ignore-message)

## Golden Rules (enforced — violations fail CI)

These are the non-negotiables. The first four are QGC's core architecture patterns; the rest are
enforced by pre-commit hooks, so ignoring them wastes a build cycle. Full list with code examples:
[.github/CONTRIBUTING.md#architecture-patterns](.github/CONTRIBUTING.md#architecture-patterns) and
[CODING_STYLE.md#common-pitfalls](CODING_STYLE.md#common-pitfalls).

- **Fact System** — ALL vehicle parameters flow through Facts; never create custom parameter storage.
- **Multi-Vehicle** — ALWAYS null-check `activeVehicle()` / `Vehicle*` before dereferencing (`vehicle-null-check`).
- **Firmware Plugin** — use `vehicle->firmwarePlugin()` for firmware-specific behavior, not `if (px4)` branches.
- **QML Integration** — register types with `QML_ELEMENT`/`QML_SINGLETON`/`QML_UNCREATABLE`; expose state via `Q_PROPERTY`.
- **No `Q_ASSERT` in production code** — use defensive checks with early returns (`check-no-qassert`).
- **No `QTest::ignoreMessage`** in tests — use `expectLogMessage`/`ignoreLogMessage` (`check-no-qtest-ignore-message`).
- **No fixed-delay `QTest::qWait(<n>)`** — use `QTRY_*_WITH_TIMEOUT` or `QSignalSpy::wait` (`check-no-fixed-qwait`).

## Critical Files (Read First!)

1. `src/FactSystem/Fact.h` — Parameter system foundation
2. `src/Vehicle/Vehicle.h` — Core vehicle model
3. `src/FirmwarePlugin/FirmwarePlugin.h` — Firmware abstraction

## Code Structure

Key modules (full tree under `src/` — ~33 subdirectories):

```text
src/
├── Vehicle/          # Vehicle state/comms
├── Comms/            # Link layer (serial, UDP, TCP, Bluetooth)
├── FactSystem/       # Parameter management
├── FirmwarePlugin/   # PX4/ArduPilot abstraction
├── AutoPilotPlugins/ # Vehicle setup UI
├── MissionManager/   # Mission planning
├── MAVLink/          # Protocol handling
├── VideoManager/     # Video pipeline (GStreamer)
├── FlyView/          # In-flight UI
├── PlanView/         # Mission planning UI
├── QmlControls/      # Reusable QML components
└── Settings/         # Persistent settings
```

## Build & Test Commands

The `just` recipes are the canonical workflow — see [tools/README.md](tools/README.md) for the full list.
[.github/ci-overview.md](.github/ci-overview.md) documents how CI invokes builds and tests; match CI, don't guess.

```bash
just configure          # CMake configure (pulls submodules first)
just build              # incremental build; uses all cores (override with JOBS=N)
just test               # ctest, LABELS="Unit|Integration" EXCLUDE="Flaky|Network"
just lint               # fast pre-commit gate (clang-format, ruff, qmllint, ...)
just check              # lint + test (run before declaring done)
just format-fix         # apply clang-format / ruff-format
just info               # print resolved versions (Qt, CMake, GStreamer)
```

- **Build incrementally** — rebuild every few file edits during multi-file C++/Qt work, not just at the end; fix build errors before continuing.
- **Tight test loops** — iterate one test with `ctest -R <name>` (or `--gtest_filter`); only run the full label on the final pass. CI runs `ctest --output-on-failure -L Unit`.
- **Match CI** — before running tests/lint locally, use the same command CI runs ([.github/ci-overview.md](.github/ci-overview.md)), not a local guess.

## Definition of Done

Before considering a change complete:

1. `just build` succeeds.
2. `just lint` (or `pre-commit run --all-files` for the full sweep) passes.
3. Relevant tests pass (`ctest -R <name>` for the touched area; full `-L Unit` on the final pass).
4. Commit message follows Conventional Commits (below).

## Commit & Review Conventions

Commit messages follow **Conventional Commits** — the type drives release automation
(`.releaserc.json` → semantic-release). Use: `feat`, `fix`, `perf`, `revert` (release-triggering);
`docs`, `style`, `chore`, `refactor`, `test`, `build`, `ci` (no release). Example: `fix(Vehicle): guard null activeVehicle in telemetry handler`.

Your output will be reviewed by another AI agent before being accepted. Keep changes focused and
minimal, use clear naming, and leave explanatory commit messages. Avoid unrelated changes,
commented-out code, or ambiguous TODOs.

---

**Key Principle**: Match the style of code you're editing. See [CODING_STYLE.md](CODING_STYLE.md) for conventions and [CODING_STYLE.md#examples](CODING_STYLE.md#examples) for canonical Vehicle/Fact/QML snippets.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **qgroundcontrol** (48765 symbols, 77450 relationships, 290 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `node .gitnexus/run.cjs analyze` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? `npx gitnexus analyze` (npm 11 crash → `npm i -g gitnexus`; #1939).

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "master"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `query({search_query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/qgroundcontrol/context` | Codebase overview, check index freshness |
| `gitnexus://repo/qgroundcontrol/clusters` | All functional areas |
| `gitnexus://repo/qgroundcontrol/processes` | All execution flows |
| `gitnexus://repo/qgroundcontrol/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
