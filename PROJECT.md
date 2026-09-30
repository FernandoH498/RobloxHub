# Project: GoHub V14 Universal Roblox Suite

## Architecture
GoHub V14 is a modular, high-performance universal Luau script suite built for Rayfield UI and compatible with all modern PC and mobile Roblox executors. The architecture decouples core services, rendering, physics, automation, game-specific suites, and telemetry while maintaining a shared zero-alloc state container (`HubState`), connection loop manager, and instance pool.

```
+---------------------------------------------------------------------------------------+
|                                      Rayfield UI                                      |
|  10 Core Tabs | 29 Sections | 91 UI Elements | Themes | Command Bar | Floating Dock   |
+---------------------------------------------------------------------------------------+
                                           |
+---------------------------------------------------------------------------------------+
|                                    HubState & Bus                                     |
|  Zero-Alloc Scratch Buffers | Loop Registrar | Theme Manager | Config Persistence     |
+---------------------------------------------------------------------------------------+
     |                 |                |                 |                 |
     v                 v                v                 v                 v
+----------+     +----------+     +----------+      +-----------+     +-----------+
|    R1    |     |    R2    |     |  R3 & R4 |      | R5, R6, R7|     |    R8     |
|  Audio & |     |Graphics &|     | Movement |      |  UI/UX,   |     |Zero-Alloc |
|Tactical  |     | Shaders  |     | & Route  |      |   MM2,    |     |  Adornee  |
|   SFX    |     |   2.0    |     |  Macros  |      |  Trolling |     |   Pool    |
+----------+     +----------+     +----------+      +-----------+     +-----------+
```

## Feature Inventory
Every feature from the authoritative survey and ORIGINAL_REQUEST is cataloged below with its assigned milestone. No feature is left unassigned.

| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | V13 UI Core & Theme Engine | 10 Tabs, 29 Sections, 91 UI Elements, 9 themes, theme persistence, safe GUI root (`gethui`/`CoreGui`) | M1 | V13 Baseline |
| 2 | Zero-Alloc Infrastructure & Memory Management | Scratch buffer recycling via `table.clear`, static pre-allocation, weak table caching (`__mode="k"`) | M1 | R8 |
| 3 | Highlight Adornee Pool | Static 24-instance pool with distance/priority queue preventing renderer crashes | M1 | R8 |
| 4 | Universal Executor Polyfill Layer | Safe wrappers for syn, fluxus, electron, wave, celestia, solara, delta, macsploit, drawing fallback | M1 | R8 |
| 5 | V13 Technical Debt Resolution | Fix button flag collisions, eliminate per-frame highlight/adornment allocations, weak X-Ray cache | M1 | Survey Audit |
| 6 | Custom Music Player & BGM Playlist | Playlist engine, track selector, volume control, playback speed modifier, looping | M2 | R1 |
| 7 | Bass Boost DSP Equalizer | Real-time `EqualizerSoundEffect` dynamic DSP (LowGain, MidGain, HighGain tuning) | M2 | R1 |
| 8 | Tactical Sound Design (SFX) | Pitch-randomized audio feedback for clicks, toggles, fly, warp, dropkick, hitmarkers | M2 | R1 |
| 9 | 3D Character Audio Visualizer | Orbital neon ring and particle ring reacting to `PlaybackLoudness` with exponential smoothing | M2 | R1 |
| 10 | Floor Beat-Drop Shockwaves | Expanding neon shockwave rings triggered on dynamic energy threshold beat drops | M2 | R1 |
| 11 | 2D Spectrum Equalizer HUD | Multi-band derivative simulated equalizer display with low/mid/treble harmonic jitter | M2 | R1 |
| 12 | Dynamic Autofocus Depth of Field | 20Hz raycast autofocus with exponential distance smoothing driving `DepthOfFieldEffect` | M3 | R2 |
| 13 | Dynamic Motion Blur | Camera angular velocity delta tracking ($\omega = \Delta\theta/\Delta t$) driving `BlurEffect` | M3 | R2 |
| 14 | 4 Cinematic Shader Presets | Cyberpunk Neon, Sunset Noir, VHS Retro, Midnight Glow (+ Golden Hour preserved) | M3 | R2 |
| 15 | Shortest-Arc Day/Night Cycle | Circular geodesic interpolation for smooth 24-hour time transitions | M3 | R2 |
| 16 | Camera-Space Particle Motes | Upward ceiling raycast occlusion detecting outdoor embers vs indoor micro-dust | M3 | R2 |
| 17 | V13 Visuals Preservation | Fullbright, NoFog, X-Ray with weak table caching, Raycast Aimbot, FOV Circle | M3 | V13 Baseline |
| 18 | Spider / Wall Climb | Surface normal tangent plane vector projection $\vec{V} - (\vec{V}\cdot\hat{N})\hat{N}$ with anti-gravity | M4 | R3 |
| 19 | Dual Grappling Hook | `SpringConstraint` elastic pendulum and `RopeConstraint` winch with slingshot momentum boost | M4 | R3 |
| 20 | Bhop Strafe Engine | Source Engine `AirAccelerate` physics with ground touchdown friction bypass | M4 | R3 |
| 21 | Omnidirectional Dash | Dash impulses with after-image ghost clones and camera FOV punch | M4 | R3 |
| 22 | Procedural Super Jump | `HipHeight` compression (2.0 to 0.4 studs) storing quadratic vertical release impulse | M4 | R3 |
| 23 | V13 Movement Preservation | Flight, FlightSpeed, WalkSpeed, Noclip, Infinite Jump, ClickTP, TP Tool | M4 | V13 Baseline |
| 24 | Live Route Macro Recorder | Adaptive deadband sampling ($\Delta P \ge 2.5\text{ studs}$ or $\Delta\theta \ge 15^\circ$ or actions) | M4 | R4 |
| 25 | Macro Playback Engine | Continuous loop playback supporting `TweenService` CFrame and `Humanoid:MoveTo` modes | M4 | R4 |
| 26 | Pathfinding & Anti-Stuck Watchdog | `PathfindingService` dynamic obstacle avoidance with jump-nudge and noclip watchdog | M4 | R4 |
| 27 | Universal Auto-Collect | `TouchTransmitter` (`firetouchinterest` sequence) and `ProximityPrompt` auto-fire | M4 | R4 |
| 28 | V13 Waypoints Preservation | Saved waypoints, coordinate serialization, teleport, and delete | M4 | V13 Baseline |
| 29 | Mobile Floating Capsule Dock | Draggable floating quick-action toolbar with touch/mouse input and viewport edge-snapping | M5 | R5 |
| 30 | Real-Time Telemetry HUD | 60-sample zero-alloc circular buffer tracking 1% low FPS, Ping, and Luau Memory MB | M5 | R5 |
| 31 | Dynamic Crosshair & Hitmarkers | Dynamic velocity/recoil spread crosshair with procedural hitmarkers and audio chime | M5 | R5 |
| 32 | MM2 Ballistic Intercept Auto-Shoot | Closed-form quadratic solver ($a t^2 + b t + c = 0$) with velocity & ping latency compensation | M5 | R6 |
| 33 | MM2 2D Minimap Radar | Camera-relative 2D radar with role-colored blips (Murderer, Sheriff, Innocent, Gun) | M5 | R6 |
| 34 | Staring & Spectator HUD | Dot-product angular gaze detection ($\cos\alpha \ge 0.965$) and spectator detection | M5 | R6 |
| 35 | Knife Throw Detection & Auto-Dodge | Trajectory closest-point-of-approach (CPA) calculation with lateral evasive impulse | M5 | R6 |
| 36 | Multi-Game Profile Loader | Dynamic PlaceId/GameId detection loading configs for MM2, Blade Ball, Rivals, Brookhaven, Arsenal | M5 | R6 |
| 37 | V13 MM2 Preservation | Hybrid Role ESP, Coin ESP (using Adornee pool), AutoGrabGun, Expand Hitboxes | M5 | V13 Baseline |
| 38 | Black Hole Vortex Fling | Accretion disc spiral physics (tangential orbit + gravitational pull + ejection impulse) | M5 | R7 |
| 39 | 100% Reversible Fake Death / Ragdoll | `Motor6D.Enabled = false` with runtime `BallSocketConstraint` instances without health loss | M5 | R7 |
| 40 | Invisible Car & Kidnap Aura | Invisible vehicle seat assembly and proximity welding kidnap aura | M5 | R7 |
| 41 | Clone Runner Decoy | Decoy character clone with PathfindingService runner dummy and stealth cloak | M5 | R7 |
| 42 | V13 Trolling & Fun Preservation | WalkFling, SpinFling, LoopFling, AntiFling, DropKick, Instant Fling, SpinBot, Anti-Sit | M5 | V13 Baseline |
| 43 | V13 Skins & Dance Engine Preservation | Headless, Korblox, Clone Skin, 30 preset dances, 8 radial slots, custom dance IDs | M5 | V13 Baseline |
| 44 | V13 Commands & Hotkeys Preservation | 30+ Command Bar commands, 8 hotkey bindings (`2x W`, `2x Space`, `K`, `C`, `X`, `;`, `R`, `M`) | M5 | V13 Baseline |
| 45 | Comprehensive E2E Testing Suite | Multi-tier opaque-box test suite (Tiers 1-4) verifying 100% of features | M6 | Acceptance Criteria |
| 46 | Luau AST Syntax Validation | Automated `validate_ast.py` verifying 0 syntax errors via `luaparser.ast` on all builds | M6 | Acceptance Criteria |
| 47 | Adversarial Hardening (Tier 5) | Memory leak audits, pcall error handling, nil safety, and connection lifecycle checks | M6 | Acceptance Criteria |
| 48 | Forensic Integrity Audit | Systematic checks ensuring zero cheating, dummy facades, or hardcoded bypasses | M6 | Acceptance Criteria |
| 49 | Monolithic Assembly & File Sync | Synchronize full build across `GoHubV14.lua` and `main.lua`, update `README.md` | M6 | Acceptance Criteria |
| 50 | GitHub Main Branch Delivery | Commit and push synchronized repository to `origin/main` | M6 | Acceptance Criteria |

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Foundation & Zero-Alloc Core | HubState, Rayfield V3 window, theme manager, 24-Highlight Adornee pool, weak table cache, universal executor polyfill matrix, V13 technical debt resolution | none | DONE |
| M2 | Audio & Music Engine 2.0 | Custom BGM music player, playlist, EqualizerSoundEffect Bass Boost DSP, tactical SFX with pitch randomization, 3D character visualizer, floor shockwaves, 2D spectrum equalizer HUD | M1 | DONE |
| M3 | Graphics & Shaders 2.0 | Dynamic 20Hz raycast autofocus DoF, angular velocity motion blur, 4 cinematic presets, shortest-arc day/night, ceiling-aware motes, V13 visuals preservation | M1 | IN_PROGRESS |
| M4 | Advanced Movement & Route Macros | Spider wall climb, dual grappling hook, bhop air accelerate, dash with ghosts, super jump, adaptive deadband route recorder, loop playback, pathfinding, universal auto-collect, V13 movement preservation | M1 | IN_PROGRESS |
| M5 | UI/UX 2.0, MM2, Trolling & Game Profiles | Mobile floating dock, telemetry HUD, dynamic crosshair/hitmarkers, MM2 ballistic auto-shoot, 2D radar, stare/spectator HUD, knife dodge, multi-game profiles, black hole vortex fling, reversible fake death, invisible car/kidnap aura, clone decoy, V13 skins/dances/trolling preservation | M1, M2, M4 | PLANNED |
| M6 | Integration, E2E Verification & Git Delivery | Complete monolithic assembly into GoHubV14.lua and main.lua, 100% E2E test pass, luaparser AST validation (0 errors), Tier 5 adversarial hardening, Forensic Audit (CLEAN), Git commit & push | M1-M5, Test Track | PLANNED |

## Interface Contracts

### M1 ↔ All Sub-Engines (`HubState` & Lifecycle)
```lua
-- HubState central registry
HubState = {
    Connections = {}, -- Array of RBXScriptConnection
    Loops = {},       -- Hashmap of named loops { [tag] = connection }
    Pools = {
        Highlights = {}, -- 24 pre-allocated Highlight instances
        Adornments = {}, -- Pre-allocated BoxHandleAdornments
        Scratch = {},    -- Reusable scratch tables
    },
    Settings = { ... },
    Audio = { ... },
    Movement = { ... },
    Lighting = { ... },
    MM2 = { ... },
    Trolling = { ... },
    Telemetry = { ... },
}

HubState.RegisterLoop(tag: string, connection: RBXScriptConnection): void
HubState.DropLoop(tag: string): void
HubState.ClearAllLoops(): void
HubState.AcquireHighlight(target: Instance, priority: number): Highlight?
HubState.ReleaseHighlight(highlight: Highlight): void
HubState.PlaySFX(sfxType: string, customPitch: number?): void
```

### M2 ↔ Audio Visualizer & Hub Actions
```lua
AudioEngine.PlayTrack(trackId: number, volume: number?, speed: number?): void
AudioEngine.SetBassBoost(enabled: boolean, levelDb: number): void
AudioEngine.GetLoudness(): (number, number) -- instantaneous, smoothed
AudioEngine.OnBeatDrop: RBXScriptSignal -- Fired when L > 1.35 * avg and L > 380
```

### M3 ↔ Lighting Engine & Presets
```lua
LightingEngine.ApplyPreset(presetName: string): void
LightingEngine.SetAutofocusDoF(enabled: boolean): void
LightingEngine.SetMotionBlur(enabled: boolean): void
LightingEngine.SetTimeCycle(enabled: boolean, speedMultiplier: number): void
LightingEngine.RestoreBaseline(): void
```

### M4 ↔ Movement & Automation
```lua
MovementEngine.SetWallClimb(enabled: boolean): void
MovementEngine.FireGrapple(targetPosition: Vector3, hookIndex: number): void
MovementEngine.ReleaseGrapple(hookIndex: number): void
MovementEngine.SetBhop(enabled: boolean): void
MovementEngine.PerformDash(direction: Vector3): void
MacroEngine.StartRecording(): void
MacroEngine.StopRecording(): WaypointRoute
MacroEngine.StartPlayback(route: WaypointRoute, mode: "Tween" | "MoveTo", loop: boolean): void
CollectorEngine.SetAutoCollect(enabled: boolean, radius: number): void
```

### M5 ↔ UI/UX, MM2 & Trolling
```lua
DockEngine.SetVisible(visible: boolean): void
TelemetryEngine.GetMetrics(): { fps: number, fpsLow: number, ping: number, memoryMb: number }
MM2Engine.ComputeBallisticAim(targetChar: Model): (Vector3?, number?) -- aimPosition, timeToHit
TrollingEngine.StartVortexFling(target: Model?): void
TrollingEngine.ToggleFakeDeath(enabled: boolean): void
TrollingEngine.SpawnDecoy(): Model?
```

## Code Layout
- `GoHubV14.lua`: Production monolithic universal Luau script with all 8 engines integrated.
- `main.lua`: Primary production entry point (synchronized with GoHubV14.lua for URL loadstring compatibility).
- `README.md`: Official documentation, feature changelog, loadstring snippets, and usage guide.
- `validate_ast.py`: Python 3.12 AST validation test harness using `luaparser.ast`.
- `tests/`: Opaque-box E2E test suite (Tiers 1-4).
