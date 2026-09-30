# GoHub V14 — Test Infrastructure & Quality Assurance Specification

> **Document ID:** GOHUB-V14-TEST-INFRA  
> **Target System:** GoHub V14 Universal Roblox Suite  
> **Test Harness:** Python 3.12 / `luaparser.ast` / Pytest-compatible Opaque-Box E2E Runner  
> **Status:** Authoritative  

---

## 1. Test Philosophy & 4-Tier Methodology

The GoHub V14 test infrastructure implements an authoritative, requirement-driven, opaque-box testing methodology designed to guarantee functional correctness, mathematical fidelity, zero-allocation memory compliance, and executor cross-compatibility without relying on brittle implementation details.

```
                      +---------------------------------------+
                      |               TIER 4                  |
                      |   Real-World Application Scenarios    |
                      |  Multi-Feature End-to-End Workflows   |
                      +---------------------------------------+
                     /                                         \
                    +-------------------------------------------+
                    |                  TIER 3                   |
                    |         Cross-Feature Combinations        |
                    |         Pairwise Interaction Matrix       |
                    +-------------------------------------------+
                   /                                             \
                  +-----------------------------------------------+
                  |                    TIER 2                     |
                  |          Boundary & Corner Cases              |
                  |   Limits, Nil Inputs, Extremes (>=5 / Feat)   |
                  +-----------------------------------------------+
                 /                                                 \
                +---------------------------------------------------+
                |                      TIER 1                       |
                |               Full Feature Coverage               |
                |        50 Features x >=5 Test Cases (>=250)       |
                +---------------------------------------------------+
               /                                                     \
              +-------------------------------------------------------+
              |             STATIC & SYNTAX CONTRACTS                 |
              |       Luau AST Parsing (luaparser) & Zero-Alloc       |
              +-------------------------------------------------------+
```

### The 4 Tiers of Verification:

1. **Tier 1: Feature Coverage (>=5 test cases per feature across all 50 features, >=250 total)**
   - Verifies the canonical happy path, state machine transitions, interface contracts, and expected observable behaviors for all 50 cataloged features.
2. **Tier 2: Boundary & Corner Cases (>=5 test cases per feature across all 50 features, >=250 total)**
   - Subject each feature to boundary values (min, max, zero, negative, extreme magnitudes), nil/missing arguments, invalid data types, rapid toggling, and unexpected state changes.
3. **Tier 3: Cross-Feature Combinations (Pairwise Interaction Tests)**
   - Validates that concurrent features operate without resource collisions, physics fighting, state corruption, or event loop starvation (e.g. Flight + Noclip, Aimbot + ESP, Vortex Fling + Ragdoll, Audio BassBoost + Visualizer, Grapple + Bhop).
4. **Tier 4: Real-World Application Scenarios (End-to-End Workflows)**
   - Simulates complete operational missions encountered by players:
     - Scenario A: *Full MM2 Round Lifecycle* (Role detection, radar blip tracking, knife throw detection, auto-dodge, ballistic intercept auto-shoot, coin farming).
     - Scenario B: *High-Mobility Infiltration & Route Macro* (Macro recording, obstacle pathfinding, bhop strafe, grapple winch, drop collection, safe loop playback).
     - Scenario C: *Combat Engagement & Physics Trolling* (Aimbot target lock, recoil crosshair update, hitmarker chime, black hole vortex fling, reversible fake death ragdoll recovery).
     - Scenario D: *Cinematic Streaming & Telemetry Stability* (Autofocus DoF, motion blur, shader preset cycle, day/night shortest arc, telemetry HUD circular buffer under load).

---

## 2. Feature Inventory Matrix & Verification Catalog

All 50 features defined in `PROJECT.md` are mapped below with their contract dependencies, zero-alloc specifications, and multi-tier test allocations:

| # | Feature Name | Milestone | Interface Contract / Method | T1 Tests | T2 Tests | T3 Tests | T4 Tests |
|---|--------------|-----------|-----------------------------|----------|----------|----------|----------|
| 1 | V13 UI Core & Theme Engine | M1 | `Window.ModifyTheme`, `SaveTheme`, `GetSafeGuiRoot` | >=5 | >=5 | Yes | Yes |
| 2 | Zero-Alloc Infrastructure | M1 | `HubState.Pools.Scratch`, `table.clear` recycling | >=5 | >=5 | Yes | Yes |
| 3 | Highlight Adornee Pool | M1 | `HubState.AcquireHighlight`, `ReleaseHighlight` (max 24) | >=5 | >=5 | Yes | Yes |
| 4 | Universal Executor Polyfill Layer | M1 | `gethui`, `syn`, `fluxus`, `Drawing`, `firetouchinterest` | >=5 | >=5 | Yes | Yes |
| 5 | V13 Technical Debt Resolution | M1 | Unique flag IDs, zero per-frame `Instance.new` | >=5 | >=5 | Yes | Yes |
| 6 | Custom Music Player & BGM Playlist | M2 | `AudioEngine.PlayTrack`, `SetVolume`, `SetSpeed` | >=5 | >=5 | Yes | Yes |
| 7 | Bass Boost DSP Equalizer | M2 | `AudioEngine.SetBassBoost(enabled, levelDb)` | >=5 | >=5 | Yes | Yes |
| 8 | Tactical Sound Design (SFX) | M2 | `HubState.PlaySFX(sfxType, customPitch)` (jitter 0.94-1.06) | >=5 | >=5 | Yes | Yes |
| 9 | 3D Character Audio Visualizer | M2 | `Visualizer.Update(loudness)` (12 orbital nodes, corona) | >=5 | >=5 | Yes | Yes |
| 10 | Floor Beat-Drop Shockwaves | M2 | `AudioEngine.OnBeatDrop` (L > 1.35*avg and L > 380) | >=5 | >=5 | Yes | Yes |
| 11 | 2D Spectrum Equalizer HUD | M2 | `SpectrumHUD.Update(loudness)` (12 frequency bands) | >=5 | >=5 | Yes | Yes |
| 12 | Dynamic Autofocus Depth of Field | M3 | `LightingEngine.SetAutofocusDoF(enabled)` (20Hz raycast) | >=5 | >=5 | Yes | Yes |
| 13 | Dynamic Motion Blur | M3 | `LightingEngine.SetMotionBlur(enabled)` (angular velocity $\omega$) | >=5 | >=5 | Yes | Yes |
| 14 | 4 Cinematic Shader Presets | M3 | `LightingEngine.ApplyPreset(presetName)` | >=5 | >=5 | Yes | Yes |
| 15 | Shortest-Arc Day/Night Cycle | M3 | `LightingEngine.SetTimeCycle(enabled, speed)` | >=5 | >=5 | Yes | Yes |
| 16 | Camera-Space Particle Motes | M3 | `LightingEngine.SetMotes(enabled)` (ceiling detection) | >=5 | >=5 | Yes | Yes |
| 17 | V13 Visuals Preservation | M3 | `Fullbright`, `NoFog`, `X-Ray`, `Aimbot`, `FOVCircle` | >=5 | >=5 | Yes | Yes |
| 18 | Spider / Wall Climb | M4 | `MovementEngine.SetWallClimb(enabled)` ($\vec{V} - (\vec{V}\cdot\hat{N})\hat{N}$) | >=5 | >=5 | Yes | Yes |
| 19 | Dual Grappling Hook | M4 | `MovementEngine.FireGrapple`, `ReleaseGrapple` | >=5 | >=5 | Yes | Yes |
| 20 | Bhop Strafe Engine | M4 | `MovementEngine.SetBhop(enabled)` (Source AirAccelerate) | >=5 | >=5 | Yes | Yes |
| 21 | Omnidirectional Dash | M4 | `MovementEngine.PerformDash(direction)` (ghost clones, FOV punch) | >=5 | >=5 | Yes | Yes |
| 22 | Procedural Super Jump | M4 | `MovementEngine.SuperJump()` (HipHeight compression 2.0->0.4) | >=5 | >=5 | Yes | Yes |
| 23 | V13 Movement Preservation | M4 | `Flight`, `FlightSpeed`, `WalkSpeed`, `Noclip`, `InfJump`, `ClickTP` | >=5 | >=5 | Yes | Yes |
| 24 | Live Route Macro Recorder | M4 | `MacroEngine.StartRecording`, `StopRecording` (adaptive deadband) | >=5 | >=5 | Yes | Yes |
| 25 | Macro Playback Engine | M4 | `MacroEngine.StartPlayback(route, mode, loop)` | >=5 | >=5 | Yes | Yes |
| 26 | Pathfinding & Anti-Stuck Watchdog | M4 | `MacroEngine.ComputePath`, `Watchdog.CheckStuck` | >=5 | >=5 | Yes | Yes |
| 27 | Universal Auto-Collect | M4 | `CollectorEngine.SetAutoCollect(enabled, radius)` | >=5 | >=5 | Yes | Yes |
| 28 | V13 Waypoints Preservation | M4 | `WaypointEngine.SaveCurrent`, `Teleport`, `Delete` | >=5 | >=5 | Yes | Yes |
| 29 | Mobile Floating Capsule Dock | M5 | `DockEngine.SetVisible`, `SetExpanded`, Edge Snap | >=5 | >=5 | Yes | Yes |
| 30 | Real-Time Telemetry HUD | M5 | `TelemetryEngine.GetMetrics()` (60-sample circular buffer) | >=5 | >=5 | Yes | Yes |
| 31 | Dynamic Crosshair & Hitmarkers | M5 | `CrosshairEngine.UpdateSpread`, `TriggerHitmarker` | >=5 | >=5 | Yes | Yes |
| 32 | MM2 Ballistic Intercept Auto-Shoot | M5 | `MM2Engine.ComputeBallisticAim(targetChar)` ($at^2+bt+c=0$) | >=5 | >=5 | Yes | Yes |
| 33 | MM2 2D Minimap Radar | M5 | `MM2Engine.UpdateRadar(cameraCFrame)` (blips: M, S, I, Gun) | >=5 | >=5 | Yes | Yes |
| 34 | Staring & Spectator HUD | M5 | `MM2Engine.CheckStaring()` ($\cos\alpha \ge 0.965$), Spectators | >=5 | >=5 | Yes | Yes |
| 35 | Knife Throw Detection & Auto-Dodge | M5 | `MM2Engine.DetectKnifeThrow()`, lateral evasive impulse | >=5 | >=5 | Yes | Yes |
| 36 | Multi-Game Profile Loader | M5 | `ProfileLoader.LoadForGame(placeId)` (MM2, BladeBall, Rivals...) | >=5 | >=5 | Yes | Yes |
| 37 | V13 MM2 Preservation | M5 | `RoleESP`, `CoinESP`, `AutoGrabGun`, `ExpandHitboxes` | >=5 | >=5 | Yes | Yes |
| 38 | Black Hole Vortex Fling | M5 | `TrollingEngine.StartVortexFling(target)` (accretion spiral) | >=5 | >=5 | Yes | Yes |
| 39 | 100% Reversible Fake Death / Ragdoll | M5 | `TrollingEngine.ToggleFakeDeath(enabled)` (Motor6D + BallSocket) | >=5 | >=5 | Yes | Yes |
| 40 | Invisible Car & Kidnap Aura | M5 | `TrollingEngine.ToggleInvisibleCar`, `ToggleKidnapAura` | >=5 | >=5 | Yes | Yes |
| 41 | Clone Runner Decoy | M5 | `TrollingEngine.SpawnDecoy()` (Character clone + stealth cloak) | >=5 | >=5 | Yes | Yes |
| 42 | V13 Trolling & Fun Preservation | M5 | `WalkFling`, `SpinFling`, `LoopFling`, `AntiFling`, `DropKick` | >=5 | >=5 | Yes | Yes |
| 43 | V13 Skins & Dance Engine Preservation | M5 | `Headless`, `Korblox`, `CloneSkin`, 30 presets, 8 radial slots | >=5 | >=5 | Yes | Yes |
| 44 | V13 Commands & Hotkeys Preservation | M5 | 30+ CmdBar commands, 8 hotkey bindings (2x W, 2x Space, K, C...) | >=5 | >=5 | Yes | Yes |
| 45 | Comprehensive E2E Testing Suite | M6 | 4-Tier test execution harness (`tests/run_tests.py`) | >=5 | >=5 | Yes | Yes |
| 46 | Luau AST Syntax Validation | M6 | `validate_ast.py` (`luaparser.ast` zero-syntax error check) | >=5 | >=5 | Yes | Yes |
| 47 | Adversarial Hardening (Tier 5) | M6 | pcall coverage, memory leak audits, nil safety guards | >=5 | >=5 | Yes | Yes |
| 48 | Forensic Integrity Audit | M6 | Genuine implementations verification (no facades/dummy bypasses) | >=5 | >=5 | Yes | Yes |
| 49 | Monolithic Assembly & File Sync | M6 | Synchronization across `GoHubV14.lua`, `main.lua`, `README.md` | >=5 | >=5 | Yes | Yes |
| 50 | GitHub Main Branch Delivery | M6 | Clean commit and push to `origin/main` | >=5 | >=5 | Yes | Yes |

---

## 3. Test Runner Invocation

The test suite is executable via standard Python 3.12:

```bash
# Execute entire test suite across all tiers and AST validation
python tests/run_tests.py

# Execute specific tier only
python tests/run_tests.py --tier 1
python tests/run_tests.py --tier 2
python tests/run_tests.py --tier 3
python tests/run_tests.py --tier 4

# Execute specific feature tests by ID (e.g. Feature 32: MM2 Ballistic Intercept)
python tests/run_tests.py --feature 32

# Execute AST validation only
python validate_ast.py

# Run with verbose output and failure stack traces
python tests/run_tests.py --verbose
```

---

## 4. Coverage Thresholds & Quality Gates

To achieve certification and sign-off, the suite enforces the following non-negotiable gates:

1. **AST Syntax Gate:**
   - 100% of tested Lua/Luau files must parse cleanly with `luaparser.ast`.
   - Zero syntax errors allowed.
2. **Feature Coverage Gate:**
   - 100% of cataloged features (50/50) must have >=5 active Tier 1 test cases ($N \ge 250$).
3. **Boundary & Corner Case Gate:**
   - 100% of cataloged features (50/50) must have >=5 active Tier 2 boundary test cases ($N \ge 250$).
4. **Integration & Scenario Gates:**
   - All Tier 3 pairwise combination tests must pass with zero state corruption.
   - All Tier 4 end-to-end real-world workflow scenarios must pass.
5. **Zero-Alloc Static Audit:**
   - Zero `Instance.new("Highlight")` calls outside initialization pool.
   - Zero `Instance.new` allocations inside per-frame RenderStepped/Heartbeat/Stepped loops.
   - Presence of `table.clear` recycling on scratch tables.
