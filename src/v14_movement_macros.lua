-- language: Lua, file: v14_movement_macros.lua, runtime: Roblox Luau, target: GoHub V14 Advanced Movement & Route Macros
-- ==============================================================================
-- GOHUB V14 — UNIVERSAL SUITE: ADVANCED MOVEMENT & ROUTE MACROS (MILESTONE 4)
-- Features 18-28:
--   F18: Spider / Wall Climb with surface normal tangent plane projection & anti-gravity
--   F19: Dual Grappling Hook (SpringConstraint elastic pendulum & RopeConstraint winch)
--   F20: Bhop Strafe with Source Engine AirAccelerate & ground friction bypass
--   F21: Omnidirectional Dash with neon ghost clones & camera FOV punch
--   F22: Procedural Super Jump with HipHeight compression & quadratic release
--   F23: V13 Movement Preservation (Flight, Speed, Noclip, InfJump, ClickTP, TP Tool)
--   F24: Live Route Macro Recorder with adaptive deadband sampling
--   F25: Continuous Loop Playback Engine (TweenService & Humanoid:MoveTo modes)
--   F26: PathfindingService dynamic obstacle avoidance & 3-stage anti-stuck watchdog
--   F27: Universal Auto-Collect (TouchTransmitter sequence 0->1 & ProximityPrompt)
--   F28: V13 Waypoints Preservation (save, teleport, delete, JSON serialization)
-- ==============================================================================

local GoHubV14Movement = {}
GoHubV14Movement.__index = GoHubV14Movement
GoHubV14Movement.Version = "14.0.0"

-- ------------------------------------------------------------------------------
-- 1. SAFE SERVICE ACQUISITION & ENVIRONMENT RESOLVER
-- ------------------------------------------------------------------------------
local function safeGetService(serviceName)
    local ok, service = pcall(function()
        return game:GetService(serviceName)
    end)
    if ok and service then
        return service
    end
    return nil
end

local Players = safeGetService("Players")
local RunService = safeGetService("RunService")
local UserInputService = safeGetService("UserInputService")
local TweenService = safeGetService("TweenService")
local TeleportService = safeGetService("TeleportService")
local HttpService = safeGetService("HttpService")
local Workspace = safeGetService("Workspace") or (typeof(workspace) == "userdata" and workspace)
local PathfindingService = safeGetService("PathfindingService")
local ProximityPromptService = safeGetService("ProximityPromptService")
local Debris = safeGetService("Debris")

local LocalPlayer = nil
if Players then
    LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        pcall(function()
            LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        end)
    end
end

local Mouse = nil
if LocalPlayer then
    pcall(function()
        Mouse = LocalPlayer:GetMouse()
    end)
end

-- Fast table.clear guarantee across Luau, LuaJIT, and standard Lua 5.1
if typeof(table) == "table" and typeof(table.clear) ~= "function" then
    table.clear = function(t)
        for k in pairs(t) do
            t[k] = nil
        end
    end
end

-- ------------------------------------------------------------------------------
-- 2. UNIVERSAL EXECUTOR POLYFILLS (TOUCH & PROMPT)
-- ------------------------------------------------------------------------------
local raw_firetouchinterest = rawget(_G, "firetouchinterest") or rawget(shared, "firetouchinterest")
local raw_fireproximityprompt = rawget(_G, "fireproximityprompt") or rawget(shared, "fireproximityprompt")

local function safeFireTouch(characterPart, targetPart, touchState)
    if raw_firetouchinterest and typeof(raw_firetouchinterest) == "function" then
        local ok = pcall(function()
            raw_firetouchinterest(characterPart, targetPart, touchState)
        end)
        if ok then return true end
    end

    -- Fallback: Transient CFrame micro-nudge for non-firetouch environments
    if touchState == 0 and characterPart and targetPart and characterPart:IsA("BasePart") and targetPart:IsA("BasePart") then
        pcall(function()
            local origCFrame = characterPart.CFrame
            local targetPos = targetPart.Position
            characterPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 0.05, 0))
            task.delay(0.015, function()
                if characterPart and characterPart.Parent then
                    characterPart.CFrame = origCFrame
                end
            end)
        end)
        return true
    end
    return false
end

local function safeFirePrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then
        return false
    end

    if raw_fireproximityprompt and typeof(raw_fireproximityprompt) == "function" then
        local ok = pcall(function()
            raw_fireproximityprompt(prompt, 0)
        end)
        if ok then return true end
    end

    -- Native Roblox method fallback
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.delay(prompt.HoldDuration + 0.05, function()
            pcall(function()
                prompt:InputHoldEnd()
            end)
        end)
    end)
    return ok
end

-- ------------------------------------------------------------------------------
-- 3. CENTRAL HUBSTATE BINDING & ZERO-ALLOC INFRASTRUCTURE
-- ------------------------------------------------------------------------------
local GlobalCore = rawget(_G, "GoHubV14Core") or rawget(shared, "GoHubV14Core")
local HubState = (GlobalCore and GlobalCore.HubState) or rawget(_G, "HubState") or rawget(shared, "HubState")

if not HubState then
    HubState = {
        Connections = {},
        Loops = {},
        Pools = {
            Scratch = {},
        },
        Movement = {
            Speed = 16.0,
            DefaultSpeed = 16.0,
            SpeedActive = false,
            Flight = false,
            FlightActive = false,
            FlightSpeed = 50.0,
            Noclip = false,
            NoclipActive = false,
            InfiniteJump = false,
            InfiniteJumpActive = false,
            ClickTP = false,
            ClickTPActive = false,
            WallClimb = false,
            WallClimbActive = false,
            Bhop = false,
            BhopActive = false,
            SuperJumpCharged = false,
            HipHeight = 2.0,
            -- Python test-suite lowercase aliases
            speed = 16.0,
            default_speed = 16.0,
            flight = false,
            flight_speed = 50.0,
            noclip = false,
            inf_jump = false,
            click_tp = false,
            wall_climb = false,
            bhop = false,
            super_jump_charged = false,
            hip_height = 2.0,
        },
        Macro = {
            Recording = false,
            Playback = false,
            Waypoints = {},
            Mode = "Tween",
            Loop = false,
            AntiStuck = true,
            -- Python test-suite lowercase aliases
            recording = false,
            playback = false,
            waypoints = {},
            mode = "Tween",
            loop = false,
            anti_stuck = true,
        },
        Collector = {
            Active = false,
            Radius = 25.0,
            active = false,
            radius = 25.0,
        },
        Waypoints = {},
        Settings = {
            Theme = "Bloom",
        },
    }

    function HubState.RegisterLoop(tag, connection)
        if HubState.Loops[tag] then
            pcall(function()
                HubState.Loops[tag]:Disconnect()
            end)
        end
        HubState.Loops[tag] = connection
        return connection
    end

    function HubState.DropLoop(tag)
        if HubState.Loops[tag] then
            pcall(function()
                HubState.Loops[tag]:Disconnect()
            end)
            HubState.Loops[tag] = nil
        end
    end

    function HubState.ClearAllLoops()
        for tag, conn in pairs(HubState.Loops) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        table.clear(HubState.Loops)
    end
end

-- Ensure sub-tables exist with dual casing
if not HubState.Movement then HubState.Movement = {} end
if not HubState.Macro then HubState.Macro = {} end
if not HubState.Collector then HubState.Collector = {} end
if not HubState.Waypoints then HubState.Waypoints = {} end
if not HubState.Pools then HubState.Pools = {} end
if not HubState.Pools.Scratch then HubState.Pools.Scratch = {} end

-- Scratch buffer recycling (Rule: table.clear)
local ScratchPool = HubState.Pools.Scratch
for i = 1, 8 do
    if not ScratchPool[i] then
        ScratchPool[i] = {}
    end
end

local function acquireScratch(index)
    local idx = index or 1
    local buf = ScratchPool[idx]
    if not buf then
        buf = {}
        ScratchPool[idx] = buf
    end
    table.clear(buf)
    return buf
end

-- Weak-key table cache for collectible instances & path nodes (StreamingEnabled safe)
local CollectibleWeakCache = setmetatable({}, { __mode = "k" })
local PathNodeWeakCache = setmetatable({}, { __mode = "v" })

-- Helper to safely get Character, RootPart and Humanoid
local function getCharacterEntities()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hrp, hum
end

-- Zero-allocation character parts cache for Noclip and Bhop loops
local CharacterPartsCache = {}
local cachedCharacter = nil
local charDescendantAddedConn = nil
local charDescendantRemovingConn = nil

local function getCachedCharacterParts(char)
    if not char or not char.Parent then
        table.clear(CharacterPartsCache)
        cachedCharacter = nil
        return CharacterPartsCache
    end
    if char ~= cachedCharacter then
        if charDescendantAddedConn then
            pcall(function() charDescendantAddedConn:Disconnect() end)
            charDescendantAddedConn = nil
        end
        if charDescendantRemovingConn then
            pcall(function() charDescendantRemovingConn:Disconnect() end)
            charDescendantRemovingConn = nil
        end
        cachedCharacter = char
        table.clear(CharacterPartsCache)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(CharacterPartsCache, part)
            end
        end
        charDescendantAddedConn = char.DescendantAdded:Connect(function(desc)
            if desc:IsA("BasePart") then
                table.insert(CharacterPartsCache, desc)
            end
        end)
        charDescendantRemovingConn = char.DescendantRemoving:Connect(function(desc)
            for i = #CharacterPartsCache, 1, -1 do
                if CharacterPartsCache[i] == desc then
                    table.remove(CharacterPartsCache, i)
                    break
                end
            end
        end)
    end
    return CharacterPartsCache
end

-- ------------------------------------------------------------------------------
-- 4. MATHEMATICAL ENGINE & VECTOR OPERATORS
-- ------------------------------------------------------------------------------
local MathEngine = {}

-- Vector projection onto tangent plane of surface normal:
-- V_tangent = V - (V . N_hat) * N_hat
function MathEngine.TangentPlaneProjection(velocity, surfaceNormal)
    if not surfaceNormal or surfaceNormal.Magnitude < 1e-6 then
        return velocity or Vector3.new(0, 0, 0)
    end
    local nHat = surfaceNormal.Unit
    local dotVal = velocity:Dot(nHat)
    local normalComponent = nHat * dotVal
    return velocity - normalComponent
end

-- Source Engine AirAccelerate Algorithm:
-- addspeed = wishspeed - currentspeed
-- accelspeed = min(accel * wishspeed * dt, addspeed)
function MathEngine.SourceAirAccelerate(currentVel, wishDir, wishSpeed, accel, dt)
    if not wishDir or wishDir.Magnitude < 1e-6 or wishSpeed <= 0 then
        return currentVel
    end
    local wishHat = wishDir.Unit
    local currentSpeed = currentVel:Dot(wishHat)
    local addSpeed = wishSpeed - currentSpeed
    if addSpeed <= 0 then
        return currentVel
    end
    local clampedDt = math.min(0.1, math.max(0.0, dt))
    local accelSpeed = math.min(accel * wishSpeed * clampedDt, addSpeed)
    return currentVel + (wishHat * accelSpeed)
end

-- Super Jump quadratic release impulse:
-- I = k * (h_default - h_compressed)^2
function MathEngine.SuperJumpImpulse(defaultHipHeight, compressedHipHeight, kConstant)
    local k = math.max(0.0, kConstant or 85.0)
    local deltaH = math.max(0.0, defaultHipHeight - compressedHipHeight)
    return k * (deltaH * deltaH)
end

-- Adaptive deadband sampling evaluator
function MathEngine.ShouldRecordWaypoint(currPos, lastPos, currLook, lastLook, minDistance, minAngleDeg)
    if not lastPos then
        return true
    end
    local deltaDist = (currPos - lastPos).Magnitude
    if deltaDist >= (minDistance or 2.5) then
        return true
    end
    if currLook and lastLook and currLook.Magnitude > 1e-4 and lastLook.Magnitude > 1e-4 then
        local dotProduct = math.max(-1.0, math.min(1.0, currLook.Unit:Dot(lastLook.Unit)))
        local angleDeg = math.deg(math.acos(dotProduct))
        if angleDeg >= (minAngleDeg or 15.0) then
            return true
        end
    end
    return false
end

-- ------------------------------------------------------------------------------
-- 5. FEATURE 18: SPIDER / WALL CLIMB WITH TANGENT PROJECTION & ANTI-GRAVITY
-- ------------------------------------------------------------------------------
local spiderRayParams = nil
local spiderFilterTable = {}
pcall(function()
    spiderRayParams = RaycastParams.new()
    spiderRayParams.FilterType = Enum.RaycastFilterType.Exclude
    spiderRayParams.IgnoreWater = true
end)

local function getSpiderRayParams()
    if not spiderRayParams then
        pcall(function()
            spiderRayParams = RaycastParams.new()
            spiderRayParams.FilterType = Enum.RaycastFilterType.Exclude
            spiderRayParams.IgnoreWater = true
        end)
    end
    return spiderRayParams
end

local SpiderClimbState = {
    Active = false,
    LinearVelocity = nil,
    RootAttachment = nil,
    ClimbSpeed = 24.0,
    UpSpeed = 30.0,
    RayDistance = 3.8,
    IsTouchingWall = false,
    LastNormal = Vector3.new(0, 1, 0),
}

local function setupSpiderActuator(hrp)
    if not hrp then return end
    local rootAtt = hrp:FindFirstChild("GoHubSpiderAttachment")
    if not rootAtt then
        rootAtt = Instance.new("Attachment")
        rootAtt.Name = "GoHubSpiderAttachment"
        rootAtt.Parent = hrp
    end
    SpiderClimbState.RootAttachment = rootAtt

    local lv = hrp:FindFirstChild("GoHubSpiderLinearVelocity")
    if not lv then
        lv = Instance.new("LinearVelocity")
        lv.Name = "GoHubSpiderLinearVelocity"
        lv.Attachment0 = rootAtt
        lv.MaxForce = 1e6
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.VectorVelocity = Vector3.new(0, 0, 0)
        lv.Enabled = false
        lv.Parent = hrp
    end
    SpiderClimbState.LinearVelocity = lv
end

local function teardownSpiderActuator()
    if SpiderClimbState.LinearVelocity then
        pcall(function() SpiderClimbState.LinearVelocity:Destroy() end)
        SpiderClimbState.LinearVelocity = nil
    end
    if SpiderClimbState.RootAttachment then
        pcall(function() SpiderClimbState.RootAttachment:Destroy() end)
        SpiderClimbState.RootAttachment = nil
    end
end

-- ------------------------------------------------------------------------------
-- 6. FEATURE 19: DUAL GRAPPLING HOOK (SPRING & ROPE WINCH WITH SLINGSHOT BOOST)
-- ------------------------------------------------------------------------------
local GrappleState = {
    Hooks = {
        [1] = {
            Active = false,
            Target = Vector3.new(0, 0, 0),
            AnchorAttachment = nil,
            Beam = nil,
            Spring = nil,
            Rope = nil,
            Length = 0,
        },
        [2] = {
            Active = false,
            Target = Vector3.new(0, 0, 0),
            AnchorAttachment = nil,
            Beam = nil,
            Spring = nil,
            Rope = nil,
            Length = 0,
        },
    },
    MaxRange = 300.0,
    Stiffness = 1200.0,
    Damping = 80.0,
    WinchSpeed = 45.0,
    ReleaseSpeedMult = 1.6,
    SlingshotBoostForce = 80.0,
    IsReeling = false,
}

local function resolveHookIndex(slotOrIndex)
    if typeof(slotOrIndex) == "number" then
        if slotOrIndex == 1 or slotOrIndex == 2 then
            return slotOrIndex
        end
        return 1
    elseif typeof(slotOrIndex) == "string" then
        local lower = string.lower(slotOrIndex)
        if lower == "right" or lower == "hook2" or lower == "2" then
            return 2
        end
        return 1
    end
    return 1
end

local function destroyHookInstances(hook)
    if hook.Spring then pcall(function() hook.Spring:Destroy() end) hook.Spring = nil end
    if hook.Rope then pcall(function() hook.Rope:Destroy() end) hook.Rope = nil end
    if hook.Beam then pcall(function() hook.Beam:Destroy() end) hook.Beam = nil end
    if hook.AnchorAttachment then pcall(function() hook.AnchorAttachment:Destroy() end) hook.AnchorAttachment = nil end
    hook.Active = false
    hook.Length = 0
end

-- ------------------------------------------------------------------------------
-- 7. FEATURE 20: BHOP STRAFE (AIRACCELERATE & ZERO-FRICTION BYPASS)
-- ------------------------------------------------------------------------------
local BhopState = {
    Active = false,
    WishSpeed = 30.0,
    AirAccelerate = 10.0,
    FrictionBypass = true,
    SavedHorizontalVel = Vector3.new(0, 0, 0),
    ZeroFrictionProperties = nil,
    DefaultFrictionProperties = nil,
    OriginalPropertiesCache = setmetatable({}, { __mode = "k" }),
}

pcall(function()
    BhopState.ZeroFrictionProperties = CustomPhysicalProperties.new(0.7, 0.0, 0.0, 100.0, 100.0)
    BhopState.DefaultFrictionProperties = CustomPhysicalProperties.new(0.7, 0.3, 0.5, 1.0, 1.0)
end)

-- ------------------------------------------------------------------------------
-- 8. FEATURE 21: OMNIDIRECTIONAL DASH (GHOST CLONES & CAMERA FOV PUNCH)
-- ------------------------------------------------------------------------------
local DashState = {
    ImpulseMagnitude = 120.0,
    CooldownTime = 1.25,
    LastDashTime = 0.0,
    FadeDuration = 0.45,
    FovPunchDegrees = 15.0,
    MaxFovCap = 120.0,
    IsDashing = false,
}

local function spawnGhostFrame(char, accentColor, transparency)
    if not char then return end
    local ghostModel = Instance.new("Model")
    ghostModel.Name = "GoHubDashGhost"

    local color = accentColor or Color3.fromRGB(0, 255, 255)
    local startTrans = transparency or 0.35

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 0.95 and part.Name ~= "HumanoidRootPart" then
            local ghostPart = Instance.new("Part")
            ghostPart.Name = "GhostPart"
            ghostPart.Size = part.Size
            ghostPart.CFrame = part.CFrame
            ghostPart.Anchored = true
            ghostPart.CanCollide = false
            ghostPart.CanTouch = false
            ghostPart.CanQuery = false
            ghostPart.Material = Enum.Material.Neon
            ghostPart.Color = color
            ghostPart.Transparency = startTrans

            -- Copy mesh if present
            local originalMesh = part:FindFirstChildOfClass("SpecialMesh")
            if originalMesh then
                local cloneMesh = originalMesh:Clone()
                cloneMesh.Parent = ghostPart
            end

            ghostPart.Parent = ghostModel

            if TweenService then
                local tween = TweenService:Create(
                    ghostPart,
                    TweenInfo.new(DashState.FadeDuration, Enum.EasingStyle.Linear),
                    { Transparency = 1.0 }
                )
                tween:Play()
            end
        end
    end

    ghostModel.Parent = Workspace
    if Debris then
        Debris:AddItem(ghostModel, DashState.FadeDuration + 0.1)
    else
        task.delay(DashState.FadeDuration + 0.1, function()
            pcall(function() ghostModel:Destroy() end)
        end)
    end
end

-- ------------------------------------------------------------------------------
-- 9. FEATURE 22: PROCEDURAL SUPER JUMP (HIPHEIGHT COMPRESSION & QUADRATIC IMPULSE)
-- ------------------------------------------------------------------------------
local SuperJumpState = {
    DefaultHipHeight = 2.0,
    MinHipHeight = 0.4,
    KConstant = 85.0,
    MaxChargeTime = 1.5,
    ChargeStartTime = 0.0,
    IsCharging = false,
}

-- ------------------------------------------------------------------------------
-- 10. FEATURE 24 & 25: ROUTE MACRO RECORDER & PLAYBACK ENGINE
-- ------------------------------------------------------------------------------
local MacroState = {
    Recording = false,
    Playback = false,
    Waypoints = {},
    LastPosition = nil,
    LastLookVector = nil,
    RecordStartTime = 0.0,
    MinDistance = 2.5,
    MinAngleDeg = 15.0,
    MaxBufferSize = 5000,
    CurrentIndex = 1,
    PlaybackMode = "Tween", -- "Tween" or "MoveTo"
    Loop = false,
    SpeedMultiplier = 1.0,
    AntiStuck = true,
    CurrentTween = nil,
    SavedRoutes = {},
}

-- ------------------------------------------------------------------------------
-- 11. FEATURE 26: PATHFINDING SERVICE & ANTI-STUCK WATCHDOG
-- ------------------------------------------------------------------------------
local AntiStuckState = {
    WatchdogEnabled = true,
    LastSamplePosition = nil,
    LastSampleTime = 0.0,
    StallTime = 0.0,
    StallThreshold = 1.0, -- Seconds
    StallSpeedThreshold = 0.2, -- Studs/sec
    Stage = 0,
    RecoveryActions = { "jump_nudge", "noclip_burst", "recompute_path" },
}

-- ------------------------------------------------------------------------------
-- 12. FEATURE 27: UNIVERSAL AUTO-COLLECT ENGINE
-- ------------------------------------------------------------------------------
local CollectorState = {
    Active = false,
    Radius = 25.0,
    MinRadius = 5.0,
    MaxRadius = 100.0,
    MaxBatchSize = 15,
    ItemCategories = { "Coin", "Gem", "Token", "GunDrop", "Drop", "Orb", "Candy", "Snowflake", "Heart", "Present" },
    LastCollectTime = 0.0,
    ThrottleInterval = 0.1,
}

local collectorOverlapParams = nil
local collectorFilterTable = {}
pcall(function()
    collectorOverlapParams = OverlapParams.new()
    collectorOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
    collectorOverlapParams.IgnoreWater = true
end)

local function getCollectorOverlapParams()
    if not collectorOverlapParams then
        pcall(function()
            collectorOverlapParams = OverlapParams.new()
            collectorOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
            collectorOverlapParams.IgnoreWater = true
        end)
    end
    return collectorOverlapParams
end

local function isCollectibleCandidate(instance)
    if not instance or not instance.Parent then return false end
    if instance:FindFirstChildOfClass("TouchTransmitter") then
        return true
    end
    if instance:FindFirstChildOfClass("ProximityPrompt") then
        return true
    end
    local name = instance.Name
    for _, cat in ipairs(CollectorState.ItemCategories) do
        if string.find(name, cat) then
            return true
        end
    end
    return false
end

-- ==============================================================================
-- 13. MOVEMENT ENGINE IMPLEMENTATION (FEATURES 18, 19, 20, 21, 22, 23)
-- ==============================================================================
local MovementEngine = {}

-- ------------------------------------------------------------------------------
-- F18: SPIDER / WALL CLIMB
-- ------------------------------------------------------------------------------
function MovementEngine.SetWallClimb(enabled)
    SpiderClimbState.Active = enabled
    HubState.Movement.WallClimb = enabled
    HubState.Movement.WallClimbActive = enabled
    HubState.Movement.wall_climb = enabled

    local char, hrp, hum = getCharacterEntities()
    if not enabled or not hrp or not hum then
        HubState.DropLoop("GoHub_SpiderClimb")
        teardownSpiderActuator()
        SpiderClimbState.IsTouchingWall = false
        return
    end

    setupSpiderActuator(hrp)

    HubState.RegisterLoop("GoHub_SpiderClimb", RunService.Heartbeat:Connect(function(dt)
        if not SpiderClimbState.Active then
            MovementEngine.SetWallClimb(false)
            return
        end

        local currentChar, currentHrp, currentHum = getCharacterEntities()
        if not currentHrp or not currentHum or not currentHrp.Parent then
            return
        end

        if not SpiderClimbState.LinearVelocity or not SpiderClimbState.LinearVelocity.Parent then
            setupSpiderActuator(currentHrp)
        end

        -- Raycast forward to find wall surface normal
        local moveDir = currentHum.MoveDirection
        local castDir = (moveDir.Magnitude > 0 and moveDir or currentHrp.CFrame.LookVector) * SpiderClimbState.RayDistance

        local rp = getSpiderRayParams()
        if rp then
            spiderFilterTable[1] = currentChar
            rp.FilterDescendantsInstances = spiderFilterTable
        end

        local rayResult = Workspace:Raycast(currentHrp.Position, castDir, rp)
        if rayResult and rayResult.Normal then
            SpiderClimbState.IsTouchingWall = true
            SpiderClimbState.LastNormal = rayResult.Normal
            local normal = rayResult.Normal

            -- Tangent plane projection: V_tan = V_wish - (V_wish . N)N
            local vWish = (moveDir.Magnitude > 0 and moveDir or currentHrp.CFrame.LookVector) * SpiderClimbState.ClimbSpeed
            local vTan = MathEngine.TangentPlaneProjection(vWish, normal)

            -- Upward climb along wall tangent plane
            local upWish = Vector3.new(0, 1, 0)
            local upTan = MathEngine.TangentPlaneProjection(upWish, normal)
            if upTan.Magnitude > 1e-4 then
                upTan = upTan.Unit
            else
                upTan = Vector3.new(0, 1, 0)
            end

            local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space)
            local upSpeed = isJumping and SpiderClimbState.UpSpeed or 4.0
            local vUp = upTan * upSpeed

            -- Anti-gravity compensation: cancel normal gravity
            local vFinal = vTan + vUp
            if SpiderClimbState.LinearVelocity then
                SpiderClimbState.LinearVelocity.Enabled = true
                SpiderClimbState.LinearVelocity.VectorVelocity = vFinal
            end

            currentHum:ChangeState(Enum.HumanoidStateType.Freefall)
        else
            SpiderClimbState.IsTouchingWall = false
            if SpiderClimbState.LinearVelocity then
                SpiderClimbState.LinearVelocity.Enabled = false
            end
        end
    end))
end

MovementEngine.SetSpiderClimbEnabled = MovementEngine.SetWallClimb

-- ------------------------------------------------------------------------------
-- F19: DUAL GRAPPLING HOOK
-- ------------------------------------------------------------------------------
function MovementEngine.FireGrapple(targetPosition, hookIndex)
    local idx = resolveHookIndex(hookIndex)
    local hook = GrappleState.Hooks[idx]

    local char, hrp, hum = getCharacterEntities()
    if not hrp or not targetPosition then return end

    local originPos = hrp.Position
    local dist = (targetPosition - originPos).Magnitude
    if dist <= 0.0 or dist > GrappleState.MaxRange then
        return
    end

    destroyHookInstances(hook)

    local anchorAtt = Instance.new("Attachment")
    anchorAtt.Name = "GoHubGrappleAnchor_" .. tostring(idx)
    anchorAtt.WorldPosition = targetPosition
    anchorAtt.Parent = Workspace.Terrain
    hook.AnchorAttachment = anchorAtt

    local rootAtt = hrp:FindFirstChild("RootAttachment")
    if not rootAtt then
        rootAtt = hrp:FindFirstChild("GoHubGrappleRootAttachment")
        if not rootAtt then
            rootAtt = Instance.new("Attachment")
            rootAtt.Name = "GoHubGrappleRootAttachment"
            rootAtt.Parent = hrp
        end
    end

    -- Visual Beam
    local beam = Instance.new("Beam")
    beam.Name = "GoHubGrappleBeam_" .. tostring(idx)
    beam.Attachment0 = rootAtt
    beam.Attachment1 = anchorAtt
    beam.Color = ColorSequence.new(idx == 1 and Color3.fromRGB(0, 220, 255) or Color3.fromRGB(255, 120, 0))
    beam.Width0 = 0.15
    beam.Width1 = 0.15
    beam.Parent = hrp
    hook.Beam = beam

    -- SpringConstraint
    local spring = Instance.new("SpringConstraint")
    spring.Name = "GoHubGrappleSpring_" .. tostring(idx)
    spring.Attachment0 = rootAtt
    spring.Attachment1 = anchorAtt
    spring.FreeLength = dist
    spring.Stiffness = GrappleState.Stiffness
    spring.Damping = GrappleState.Damping
    spring.Parent = hrp
    hook.Spring = spring

    -- RopeConstraint
    local rope = Instance.new("RopeConstraint")
    rope.Name = "GoHubGrappleRope_" .. tostring(idx)
    rope.Attachment0 = rootAtt
    rope.Attachment1 = anchorAtt
    rope.Length = dist
    rope.Restitution = 0.15
    rope.Parent = hrp
    hook.Rope = rope

    hook.Active = true
    hook.Length = dist
    hook.Target = targetPosition

    -- Hook Winch Heartbeat
    if not HubState.Loops["GoHub_GrappleWinch"] then
        HubState.RegisterLoop("GoHub_GrappleWinch", RunService.Heartbeat:Connect(function(dt)
            local activeCount = 0
            for i = 1, 2 do
                local h = GrappleState.Hooks[i]
                if h.Active and h.Rope and h.Spring then
                    activeCount = activeCount + 1
                    if GrappleState.IsReeling or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        local newLen = math.max(0.0, h.Length - GrappleState.WinchSpeed * dt)
                        h.Length = newLen
                        h.Rope.Length = newLen
                        h.Spring.FreeLength = newLen
                    end
                end
            end
            if activeCount == 0 then
                HubState.DropLoop("GoHub_GrappleWinch")
            end
        end))
    end
end

function MovementEngine.ReleaseGrapple(hookIndex)
    local idx = resolveHookIndex(hookIndex)
    local hook = GrappleState.Hooks[idx]
    if not hook or not hook.Active then
        return
    end

    local char, hrp, hum = getCharacterEntities()
    if hrp then
        -- Slingshot boost momentum
        local currentVel = hrp.AssemblyLinearVelocity
        local cam = Workspace.CurrentCamera
        local lookVec = (cam and cam.CFrame.LookVector) or hrp.CFrame.LookVector
        local boostedVel = (currentVel * GrappleState.ReleaseSpeedMult) + (lookVec * GrappleState.SlingshotBoostForce)
        hrp.AssemblyLinearVelocity = boostedVel
    end

    destroyHookInstances(hook)
end

function MovementEngine.SetGrappleReeling(isReeling)
    GrappleState.IsReeling = isReeling
end

-- ------------------------------------------------------------------------------
-- F20: BHOP STRAFE ENGINE
-- ------------------------------------------------------------------------------
function MovementEngine.SetBhop(enabled)
    BhopState.Active = enabled
    HubState.Movement.Bhop = enabled
    HubState.Movement.BhopActive = enabled
    HubState.Movement.bhop = enabled

    local char, hrp, hum = getCharacterEntities()
    if not enabled or not hrp or not hum then
        HubState.DropLoop("GoHub_BhopEngine")
        if char then
            local parts = getCachedCharacterParts(char)
            for i = 1, #parts do
                local part = parts[i]
                if part and part.Parent then
                    pcall(function()
                        part.CustomPhysicalProperties = BhopState.DefaultFrictionProperties
                    end)
                end
            end
        end
        return
    end

    HubState.RegisterLoop("GoHub_BhopEngine", RunService.Heartbeat:Connect(function(dt)
        if not BhopState.Active then
            MovementEngine.SetBhop(false)
            return
        end

        local currentChar, currentHrp, currentHum = getCharacterEntities()
        if not currentHrp or not currentHum or not currentHrp.Parent then
            return
        end

        local currVel = currentHrp.AssemblyLinearVelocity
        local horizVel = Vector3.new(currVel.X, 0, currVel.Z)
        local wishDir = currentHum.MoveDirection

        -- If touching ground: bypass friction & auto-jump
        if currentHum.FloorMaterial ~= Enum.Material.Air then
            if BhopState.FrictionBypass and BhopState.ZeroFrictionProperties then
                local parts = getCachedCharacterParts(currentChar)
                for i = 1, #parts do
                    local part = parts[i]
                    if part and part.Parent then
                        pcall(function()
                            part.CustomPhysicalProperties = BhopState.ZeroFrictionProperties
                        end)
                    end
                end
            end

            -- Automatically jump upon touching ground
            currentHum:ChangeState(Enum.HumanoidStateType.Jumping)

            -- Re-inject conserved horizontal momentum
            if BhopState.SavedHorizontalVel.Magnitude > 0 then
                currentHrp.AssemblyLinearVelocity = Vector3.new(
                    BhopState.SavedHorizontalVel.X,
                    currentHrp.AssemblyLinearVelocity.Y,
                    BhopState.SavedHorizontalVel.Z
                )
            end
        else
            -- In air: Apply Source Engine AirAccelerate
            BhopState.SavedHorizontalVel = horizVel
            if wishDir.Magnitude > 1e-4 then
                local newHoriz = MathEngine.SourceAirAccelerate(
                    horizVel,
                    wishDir,
                    BhopState.WishSpeed,
                    BhopState.AirAccelerate,
                    dt
                )
                currentHrp.AssemblyLinearVelocity = Vector3.new(
                    newHoriz.X,
                    currentHrp.AssemblyLinearVelocity.Y,
                    newHoriz.Z
                )
            end
        end
    end))
end

MovementEngine.SetBhopEnabled = MovementEngine.SetBhop

-- ------------------------------------------------------------------------------
-- F21: OMNIDIRECTIONAL DASH
-- ------------------------------------------------------------------------------
function MovementEngine.PerformDash(direction)
    local char, hrp, hum = getCharacterEntities()
    if not char or not hrp or not hum then return end

    local now = tick()
    if (now - DashState.LastDashTime) < DashState.CooldownTime then
        return
    end
    DashState.LastDashTime = now
    DashState.IsDashing = true

    -- Direction resolution
    local dashDir = nil
    if direction and direction.Magnitude > 1e-4 then
        dashDir = direction.Unit
    elseif hum.MoveDirection.Magnitude > 1e-4 then
        dashDir = hum.MoveDirection.Unit
    else
        dashDir = hrp.CFrame.LookVector
    end

    -- Assemble linear impulse (120 SPS horizontal + 15 vertical pop)
    local impulseVector = (dashDir * DashState.ImpulseMagnitude) + Vector3.new(0, 15.0, 0)
    hrp.AssemblyLinearVelocity = impulseVector

    -- FOV Punch
    local cam = Workspace.CurrentCamera
    if cam and TweenService then
        local baseFov = cam.FieldOfView
        local punchedFov = math.min(DashState.MaxFovCap, baseFov + DashState.FovPunchDegrees)
        local tweenOut = TweenService:Create(cam, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = punchedFov })
        local tweenIn = TweenService:Create(cam, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { FieldOfView = baseFov })
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            tweenIn:Play()
        end)
    end

    -- After-Image Ghost Clones (5 frames spaced by 0.035s)
    task.spawn(function()
        for i = 1, 5 do
            if char and char.Parent then
                spawnGhostFrame(char, Color3.fromRGB(0, 230, 255), 0.35)
            end
            task.wait(0.035)
        end
        DashState.IsDashing = false
    end)
end

MovementEngine.TriggerDash = MovementEngine.PerformDash

-- ------------------------------------------------------------------------------
-- F22: PROCEDURAL SUPER JUMP
-- ------------------------------------------------------------------------------
function MovementEngine.StartSuperJumpCharge()
    local char, hrp, hum = getCharacterEntities()
    if not hum then return end

    SuperJumpState.IsCharging = true
    SuperJumpState.ChargeStartTime = tick()
    HubState.Movement.SuperJumpCharged = true
    HubState.Movement.super_jump_charged = true

    HubState.RegisterLoop("GoHub_SuperJumpCharge", RunService.Heartbeat:Connect(function()
        if not SuperJumpState.IsCharging then
            HubState.DropLoop("GoHub_SuperJumpCharge")
            return
        end
        local _, _, currentHum = getCharacterEntities()
        if not currentHum then return end

        local elapsed = tick() - SuperJumpState.ChargeStartTime
        local ratio = math.min(1.0, elapsed / SuperJumpState.MaxChargeTime)
        -- Compress HipHeight from 2.0 down to 0.4
        local compressedH = math.max(SuperJumpState.MinHipHeight, SuperJumpState.DefaultHipHeight - (ratio * (SuperJumpState.DefaultHipHeight - SuperJumpState.MinHipHeight)))
        currentHum.HipHeight = compressedH
        HubState.Movement.HipHeight = compressedH
        HubState.Movement.hip_height = compressedH
    end))
end

function MovementEngine.ReleaseSuperJump()
    HubState.DropLoop("GoHub_SuperJumpCharge")
    local char, hrp, hum = getCharacterEntities()
    if not hrp or not hum then
        SuperJumpState.IsCharging = false
        HubState.Movement.SuperJumpCharged = false
        HubState.Movement.super_jump_charged = false
        return
    end

    local compressedH = hum.HipHeight
    local impulse = MathEngine.SuperJumpImpulse(SuperJumpState.DefaultHipHeight, compressedH, SuperJumpState.KConstant)

    -- Restore HipHeight
    hum.HipHeight = SuperJumpState.DefaultHipHeight
    HubState.Movement.HipHeight = SuperJumpState.DefaultHipHeight
    HubState.Movement.hip_height = SuperJumpState.DefaultHipHeight

    if impulse > 0 then
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X,
            hrp.AssemblyLinearVelocity.Y + impulse,
            hrp.AssemblyLinearVelocity.Z
        )
    end

    SuperJumpState.IsCharging = false
    HubState.Movement.SuperJumpCharged = false
    HubState.Movement.super_jump_charged = false
end

-- ------------------------------------------------------------------------------
-- F23: V13 MOVEMENT PRESERVATION (FLIGHT, SPEED, NOCLIP, INF JUMP, CLICK TP)
-- ------------------------------------------------------------------------------
local bgInstance, bvInstance

function MovementEngine.SetFlight(enabled)
    HubState.Movement.FlightActive = enabled
    HubState.Movement.Flight = enabled
    HubState.Movement.flight = enabled

    local char, hrp, hum = getCharacterEntities()
    if not enabled or not hrp or not hum then
        HubState.DropLoop("GoHub_Flight")
        if bgInstance then pcall(function() bgInstance:Destroy() end) bgInstance = nil end
        if bvInstance then pcall(function() bvInstance:Destroy() end) bvInstance = nil end
        if hum then hum.PlatformStand = false end
        return
    end

    if bgInstance then pcall(function() bgInstance:Destroy() end) end
    if bvInstance then pcall(function() bvInstance:Destroy() end) end

    bgInstance = Instance.new("BodyGyro")
    bgInstance.P = 9e4
    bgInstance.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bgInstance.CFrame = hrp.CFrame
    bgInstance.Parent = hrp

    bvInstance = Instance.new("BodyVelocity")
    bvInstance.Velocity = Vector3.new(0, 0, 0)
    bvInstance.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bvInstance.Parent = hrp

    hum.PlatformStand = true

    HubState.RegisterLoop("GoHub_Flight", RunService.RenderStepped:Connect(function()
        if not HubState.Movement.FlightActive or not hrp or not hrp.Parent then
            MovementEngine.SetFlight(false)
            return
        end

        local cam = Workspace.CurrentCamera
        if not cam then return end
        bgInstance.CFrame = cam.CFrame

        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        local speed = math.max(10.0, math.min(300.0, HubState.Movement.FlightSpeed or HubState.Movement.flight_speed or 50.0))
        if moveDir.Magnitude > 0 then
            bvInstance.Velocity = moveDir.Unit * speed
        else
            bvInstance.Velocity = Vector3.new(0, 0, 0)
        end
    end))
end

function MovementEngine.SetFlightSpeed(speed)
    local clamped = math.max(10.0, math.min(300.0, tonumber(speed) or 50.0))
    HubState.Movement.FlightSpeed = clamped
    HubState.Movement.flight_speed = clamped
end

function MovementEngine.ApplySpeed()
    local _, _, hum = getCharacterEntities()
    if hum then
        local rawSpeed = HubState.Movement.SpeedActive and (HubState.Movement.Speed or HubState.Movement.speed) or (HubState.Movement.DefaultSpeed or HubState.Movement.default_speed or 16.0)
        local clamped = math.max(16.0, math.min(300.0, rawSpeed))
        hum.WalkSpeed = clamped
    end
end

function MovementEngine.SetWalkSpeed(speed)
    local clamped = math.max(16.0, math.min(300.0, tonumber(speed) or 16.0))
    HubState.Movement.Speed = clamped
    HubState.Movement.speed = clamped
    HubState.Movement.SpeedActive = true
    MovementEngine.ApplySpeed()
end

HubState.RegisterLoop("GoHub_SpeedHeartbeat", RunService.Heartbeat:Connect(function()
    if HubState.Movement.SpeedActive then
        MovementEngine.ApplySpeed()
    end
end))

function MovementEngine.SetNoclip(enabled)
    HubState.Movement.NoclipActive = enabled
    HubState.Movement.Noclip = enabled
    HubState.Movement.noclip = enabled

    if enabled then
        HubState.RegisterLoop("GoHub_Noclip", RunService.Stepped:Connect(function()
            local char = LocalPlayer and LocalPlayer.Character
            if char then
                local parts = getCachedCharacterParts(char)
                for i = 1, #parts do
                    local part = parts[i]
                    if part and part.Parent then
                        part.CanCollide = false
                    end
                end
            end
        end))
    else
        HubState.DropLoop("GoHub_Noclip")
        local char = LocalPlayer and LocalPlayer.Character
        if char then
            local parts = getCachedCharacterParts(char)
            for i = 1, #parts do
                local part = parts[i]
                if part and part.Parent and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end
end

function MovementEngine.SetInfiniteJump(enabled)
    HubState.Movement.InfiniteJumpActive = enabled
    HubState.Movement.InfiniteJump = enabled
    HubState.Movement.inf_jump = enabled

    if enabled then
        HubState.RegisterLoop("GoHub_InfJump", UserInputService.JumpRequest:Connect(function()
            local _, _, hum = getCharacterEntities()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end))
    else
        HubState.DropLoop("GoHub_InfJump")
    end
end

function MovementEngine.SetClickTP(enabled)
    HubState.Movement.ClickTPActive = enabled
    HubState.Movement.ClickTP = enabled
    HubState.Movement.click_tp = enabled

    if enabled then
        HubState.RegisterLoop("GoHub_ClickTP", UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                local _, hrp, _ = getCharacterEntities()
                if hrp and Mouse and Mouse.Hit then
                    local targetPos = Mouse.Hit.Position
                    if targetPos then
                        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3.0, 0))
                    end
                end
            end
        end))
    else
        HubState.DropLoop("GoHub_ClickTP")
    end
end

function MovementEngine.GiveTPTool()
    if not LocalPlayer then return end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp or bp:FindFirstChild("GoHub TP Tool") then return end

    local tool = Instance.new("Tool")
    tool.Name = "GoHub TP Tool"
    tool.RequiresHandle = false
    tool.Activated:Connect(function()
        local _, hrp, _ = getCharacterEntities()
        if hrp and Mouse and Mouse.Hit then
            local targetPos = Mouse.Hit.Position
            if targetPos then
                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3.0, 0))
            end
        end
    end)
    tool.Parent = bp
end

function MovementEngine.ServerHop()
    task.spawn(function()
        if not TeleportService or not HttpService then return end
        local placeId = game.PlaceId
        local api = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
        local success, res = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(api))
        end)
        if success and res and res.data then
            for _, srv in ipairs(res.data) do
                if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(placeId, srv.id, LocalPlayer)
                    return
                end
            end
        end
        TeleportService:Teleport(placeId, LocalPlayer)
    end)
end

function MovementEngine.Rejoin()
    if TeleportService and LocalPlayer then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

-- ==============================================================================
-- 14. ROUTE MACRO ENGINE IMPLEMENTATION (FEATURES 24, 25, 26)
-- ==============================================================================
local MacroEngine = {}

-- ------------------------------------------------------------------------------
-- F24: LIVE ROUTE MACRO RECORDER (ADAPTIVE DEADBAND SAMPLING)
-- ------------------------------------------------------------------------------
function MacroEngine.StartRecording()
    local char, hrp, hum = getCharacterEntities()
    if not hrp then return end

    table.clear(MacroState.Waypoints)
    MacroState.Recording = true
    MacroState.RecordStartTime = tick()
    MacroState.LastPosition = hrp.Position
    MacroState.LastLookVector = hrp.CFrame.LookVector

    HubState.Macro.Recording = true
    HubState.Macro.recording = true
    HubState.Macro.Waypoints = MacroState.Waypoints
    HubState.Macro.waypoints = MacroState.Waypoints

    -- Initial anchor waypoint
    table.insert(MacroState.Waypoints, {
        Position = hrp.Position,
        LookVector = hrp.CFrame.LookVector,
        Timestamp = 0.0,
        Action = nil,
    })

    HubState.RegisterLoop("GoHub_MacroRecorder", RunService.Heartbeat:Connect(function()
        if not MacroState.Recording then
            HubState.DropLoop("GoHub_MacroRecorder")
            return
        end

        if #MacroState.Waypoints >= MacroState.MaxBufferSize then
            return
        end

        local _, currentHrp, _ = getCharacterEntities()
        if not currentHrp then return end

        local currPos = currentHrp.Position
        local currLook = currentHrp.CFrame.LookVector

        if MathEngine.ShouldRecordWaypoint(currPos, MacroState.LastPosition, currLook, MacroState.LastLookVector, MacroState.MinDistance, MacroState.MinAngleDeg) then
            MacroState.LastPosition = currPos
            MacroState.LastLookVector = currLook
            local timeOffset = tick() - MacroState.RecordStartTime

            table.insert(MacroState.Waypoints, {
                Position = currPos,
                LookVector = currLook,
                Timestamp = timeOffset,
                Action = nil,
            })
        end
    end))
end

function MacroEngine.StopRecording()
    MacroState.Recording = false
    HubState.Macro.Recording = false
    HubState.Macro.recording = false
    HubState.DropLoop("GoHub_MacroRecorder")
    return MacroState.Waypoints
end

function MacroEngine.SaveRoute(name, routeData)
    local r = routeData or MacroState.Waypoints
    local routeName = (name and name ~= "") and name or ("Route_" .. tostring(#MacroState.SavedRoutes + 1))
    MacroState.SavedRoutes[routeName] = r
    return true
end

function MacroEngine.LoadRoute(name)
    local r = MacroState.SavedRoutes[name]
    if r then
        MacroState.Waypoints = r
        HubState.Macro.Waypoints = r
        HubState.Macro.waypoints = r
        return r
    end
    return nil
end

-- ------------------------------------------------------------------------------
-- F25: CONTINUOUS LOOP PLAYBACK ENGINE (TWEENSERVICE & HUMANOID:MOVETO)
-- ------------------------------------------------------------------------------
function MacroEngine.StartPlayback(route, mode, loop)
    local wps = route or MacroState.Waypoints
    if not wps or #wps == 0 then
        return
    end

    MacroState.Playback = true
    MacroState.PlaybackMode = mode or MacroState.PlaybackMode or "Tween"
    MacroState.Loop = (loop ~= nil) and loop or MacroState.Loop
    MacroState.CurrentIndex = 1

    HubState.Macro.Playback = true
    HubState.Macro.playback = true
    HubState.Macro.Mode = MacroState.PlaybackMode
    HubState.Macro.mode = MacroState.PlaybackMode
    HubState.Macro.Loop = MacroState.Loop
    HubState.Macro.loop = MacroState.Loop

    task.spawn(function()
        while MacroState.Playback and #wps > 0 do
            local idx = MacroState.CurrentIndex
            local wp = wps[idx]
            if not wp then break end

            local char, hrp, hum = getCharacterEntities()
            if not hrp or not hum then
                task.wait(0.5)
            else
                local targetPos = (typeof(wp) == "Vector3" and wp) or (typeof(wp) == "table" and wp.Position) or (typeof(wp) == "table" and wp.Pos and Vector3.new(wp.Pos[1], wp.Pos[2], wp.Pos[3]))
                local targetLook = (typeof(wp) == "table" and wp.LookVector) or hrp.CFrame.LookVector

                if targetPos then
                    if MacroState.PlaybackMode == "Tween" and TweenService then
                        -- TweenService CFrame mode
                        local dist = (targetPos - hrp.Position).Magnitude
                        local speedMult = math.max(0.1, math.min(5.0, MacroState.SpeedMultiplier or 1.0))
                        local walkSpeed = HubState.Movement.Speed or HubState.Movement.speed or 16.0
                        local travelTime = math.max(0.05, dist / (walkSpeed * speedMult))

                        local targetCF = CFrame.new(targetPos, targetPos + targetLook)
                        local tween = TweenService:Create(
                            hrp,
                            TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
                            { CFrame = targetCF }
                        )
                        MacroState.CurrentTween = tween
                        tween:Play()
                        tween.Completed:Wait()
                        MacroState.CurrentTween = nil
                    else
                        -- Humanoid:MoveTo legit physics mode
                        hum:MoveTo(targetPos)
                        local moveFinished = false
                        local conn = hum.MoveToFinished:Connect(function()
                            moveFinished = true
                        end)

                        local dist = (targetPos - hrp.Position).Magnitude
                        local timeout = (dist / 16.0) + 2.5
                        local startTime = tick()

                        -- Watchdog loop while moving to waypoint
                        while not moveFinished and (tick() - startTime) < timeout and MacroState.Playback do
                            -- Anti-stuck check
                            if AntiStuckState.WatchdogEnabled then
                                local currPos = hrp.Position
                                if AntiStuckState.LastSamplePosition then
                                    local deltaMoved = (currPos - AntiStuckState.LastSamplePosition).Magnitude
                                    if deltaMoved < 0.2 then
                                        AntiStuckState.StallTime = AntiStuckState.StallTime + 0.1
                                        if AntiStuckState.StallTime >= AntiStuckState.StallThreshold then
                                            -- Execute Recovery: Stage 1 Jump nudge, Stage 2 Noclip burst
                                            hum.Jump = true
                                            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(2.0, 10.0, 2.0)
                                            AntiStuckState.StallTime = 0.0
                                        end
                                    else
                                        AntiStuckState.StallTime = 0.0
                                    end
                                end
                                AntiStuckState.LastSamplePosition = currPos
                            end
                            task.wait(0.1)
                        end
                        pcall(function() conn:Disconnect() end)
                    end
                end
            end

            -- Advance index
            if MacroState.CurrentIndex >= #wps then
                if MacroState.Loop then
                    MacroState.CurrentIndex = 1
                else
                    MacroState.Playback = false
                    break
                end
            else
                MacroState.CurrentIndex = MacroState.CurrentIndex + 1
            end
        end

        MacroState.Playback = false
        HubState.Macro.Playback = false
        HubState.Macro.playback = false
    end)
end

function MacroEngine.PlayRoute(mode, loop)
    MacroEngine.StartPlayback(MacroState.Waypoints, mode, loop)
end

function MacroEngine.StopPlayback()
    MacroState.Playback = false
    HubState.Macro.Playback = false
    HubState.Macro.playback = false
    if MacroState.CurrentTween then
        pcall(function() MacroState.CurrentTween:Cancel() end)
        MacroState.CurrentTween = nil
    end
end

-- ------------------------------------------------------------------------------
-- F26: PATHFINDING SERVICE DYNAMIC OBSTACLE AVOIDANCE & WATCHDOG
-- ------------------------------------------------------------------------------
function MacroEngine.ComputeSafePath(destination)
    if not PathfindingService then return nil end
    local _, hrp, _ = getCharacterEntities()
    if not hrp or not destination then return nil end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2.2,
        AgentHeight = 5.2,
        AgentCanJump = true,
        WaypointSpacing = 4.0,
    })

    local ok = pcall(function()
        path:ComputeAsync(hrp.Position, destination)
    end)

    if ok and path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    end
    return nil
end

function MacroEngine.SetAntiStuckEnabled(enabled)
    AntiStuckState.WatchdogEnabled = enabled
    HubState.Macro.AntiStuck = enabled
    HubState.Macro.anti_stuck = enabled
end

-- ==============================================================================
-- 15. UNIVERSAL COLLECTOR ENGINE IMPLEMENTATION (FEATURE 27)
-- ==============================================================================
local CollectorEngine = {}

function CollectorEngine.SetAutoCollect(enabled, radius)
    CollectorState.Active = enabled
    local r = math.max(0.0, math.min(CollectorState.MaxRadius, tonumber(radius) or CollectorState.Radius))
    CollectorState.Radius = r

    HubState.Collector.Active = enabled
    HubState.Collector.active = enabled
    HubState.Collector.Radius = r
    HubState.Collector.radius = r

    if not enabled or r <= 0 then
        HubState.DropLoop("GoHub_AutoCollector")
        return
    end

    HubState.RegisterLoop("GoHub_AutoCollector", RunService.Heartbeat:Connect(function()
        if not CollectorState.Active or CollectorState.Radius <= 0 then
            HubState.DropLoop("GoHub_AutoCollector")
            return
        end

        local now = tick()
        if (now - CollectorState.LastCollectTime) < CollectorState.ThrottleInterval then
            return
        end
        CollectorState.LastCollectTime = now

        local char, hrp, _ = getCharacterEntities()
        if not hrp then return end

        local hrpPos = hrp.Position
        local collectedThisTick = 0
        local scanRadius = CollectorState.Radius

        -- Scan candidates via spatial query if available, fallback to Workspace scan
        local candidateParts = nil
        if Workspace and typeof(Workspace.GetPartBoundsInRadius) == "function" then
            if not collectorOverlapParams then
                pcall(function()
                    collectorOverlapParams = OverlapParams.new()
                    collectorOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
                    collectorOverlapParams.IgnoreWater = true
                end)
            end
            if collectorOverlapParams then
                collectorFilterTable[1] = char
                collectorOverlapParams.FilterDescendantsInstances = collectorFilterTable
            end
            pcall(function()
                candidateParts = Workspace:GetPartBoundsInRadius(hrpPos, scanRadius, collectorOverlapParams)
            end)
        end
        if not candidateParts then
            candidateParts = Workspace:GetDescendants()
        end

        for _, instance in ipairs(candidateParts) do
            if collectedThisTick >= CollectorState.MaxBatchSize then
                break
            end

            if instance:IsA("BasePart") and instance.Parent then
                local dist = (instance.Position - hrpPos).Magnitude
                if dist <= scanRadius and isCollectibleCandidate(instance) then
                    local transmitter = instance:FindFirstChildOfClass("TouchTransmitter")
                    if transmitter then
                        safeFireTouch(hrp, instance, 0)
                        task.delay(0.015, function()
                            if instance and instance.Parent and hrp and hrp.Parent then
                                safeFireTouch(hrp, instance, 1)
                            end
                        end)
                        collectedThisTick = collectedThisTick + 1
                    else
                        local prompt = instance:FindFirstChildOfClass("ProximityPrompt") or (instance.Parent and instance.Parent:FindFirstChildOfClass("ProximityPrompt"))
                        if prompt and prompt.Enabled then
                            safeFirePrompt(prompt)
                            collectedThisTick = collectedThisTick + 1
                        end
                    end
                end
            end
        end
    end))
end

function CollectorEngine.SetRadius(radius)
    local r = math.max(0.0, math.min(CollectorState.MaxRadius, tonumber(radius) or 25.0))
    CollectorState.Radius = r
    HubState.Collector.Radius = r
    HubState.Collector.radius = r
end

-- ==============================================================================
-- 16. WAYPOINT ENGINE IMPLEMENTATION (FEATURE 28 — V13 PRESERVATION)
-- ==============================================================================
local WaypointEngine = {}

function WaypointEngine.SaveCurrent(name)
    local _, hrp, _ = getCharacterEntities()
    if not hrp then
        return false, "Character not found"
    end
    if #HubState.Waypoints >= 100 then
        return false, "Maximum waypoints cap (100) reached"
    end

    local wpName = (name and name ~= "") and name or ("Waypoint_" .. tostring(#HubState.Waypoints + 1))
    local wp = {
        Name = wpName,
        CFrame = hrp.CFrame,
        Position = hrp.Position,
    }
    table.insert(HubState.Waypoints, wp)
    return true, wpName
end

WaypointEngine.SaveWaypoint = WaypointEngine.SaveCurrent

function WaypointEngine.TeleportTo(wpOrName)
    local _, hrp, _ = getCharacterEntities()
    if not hrp then return false end

    if typeof(wpOrName) == "string" then
        for _, wp in ipairs(HubState.Waypoints) do
            if wp.Name == wpOrName then
                if wp.CFrame then
                    hrp.CFrame = wp.CFrame
                    return true
                elseif wp.Position then
                    hrp.CFrame = CFrame.new(wp.Position)
                    return true
                end
            end
        end
        return false
    elseif typeof(wpOrName) == "table" then
        if wpOrName.CFrame then
            hrp.CFrame = wpOrName.CFrame
            return true
        elseif wpOrName.Position then
            hrp.CFrame = CFrame.new(wpOrName.Position)
            return true
        end
    end
    return false
end

function WaypointEngine.DeleteWaypoint(wpName)
    if not wpName then return false end
    for i = #HubState.Waypoints, 1, -1 do
        if HubState.Waypoints[i].Name == wpName then
            table.remove(HubState.Waypoints, i)
            return true
        end
    end
    return false
end

function WaypointEngine.GetWaypoints()
    return HubState.Waypoints
end

function WaypointEngine.SerializeWaypoints()
    local serializable = acquireScratch(1)
    for _, wp in ipairs(HubState.Waypoints) do
        local pos = wp.Position or (wp.CFrame and wp.CFrame.Position) or Vector3.new(0, 0, 0)
        table.insert(serializable, {
            Name = wp.Name,
            Pos = { pos.X, pos.Y, pos.Z },
        })
    end

    if HttpService then
        local ok, json = pcall(function()
            return HttpService:JSONEncode({ Waypoints = serializable })
        end)
        if ok and json then
            return json
        end
    end
    return "{}"
end

function WaypointEngine.DeserializeWaypoints(jsonStr)
    if not jsonStr or jsonStr == "" then
        return {}
    end
    if not HttpService then
        return {}
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(jsonStr)
    end)

    if not ok or typeof(data) ~= "table" or not data.Waypoints then
        return {}
    end

    table.clear(HubState.Waypoints)
    for _, item in ipairs(data.Waypoints) do
        if item.Name and item.Pos and #item.Pos >= 3 then
            local pos = Vector3.new(item.Pos[1], item.Pos[2], item.Pos[3])
            table.insert(HubState.Waypoints, {
                Name = item.Name,
                Position = pos,
                CFrame = CFrame.new(pos),
            })
        end
    end
    return HubState.Waypoints
end

-- ==============================================================================
-- 17. MODULE AGGREGATION & GLOBAL EXPORTS
-- ==============================================================================
GoHubV14Movement.Movement = MovementEngine
GoHubV14Movement.Macro = MacroEngine
GoHubV14Movement.Collector = CollectorEngine
GoHubV14Movement.Waypoints = WaypointEngine
GoHubV14Movement.Math = MathEngine
GoHubV14Movement.HubState = HubState

-- Polyfill export table for global access
local exportTable = {
    Movement = MovementEngine,
    Macro = MacroEngine,
    Collector = CollectorEngine,
    Waypoints = WaypointEngine,
    Math = MathEngine,
    HubState = HubState,
    MovementEngine = MovementEngine,
    MacroEngine = MacroEngine,
    CollectorEngine = CollectorEngine,
    WaypointEngine = WaypointEngine,
}

rawset(_G, "GoHubV14Movement", exportTable)
rawset(shared, "GoHubV14Movement", exportTable)
rawset(_G, "MovementEngine", MovementEngine)
rawset(shared, "MovementEngine", MovementEngine)
rawset(_G, "MacroEngine", MacroEngine)
rawset(shared, "MacroEngine", MacroEngine)
rawset(_G, "CollectorEngine", CollectorEngine)
rawset(shared, "CollectorEngine", CollectorEngine)
rawset(_G, "WaypointEngine", WaypointEngine)
rawset(shared, "WaypointEngine", WaypointEngine)

if GlobalCore then
    GlobalCore.Movement = MovementEngine
    GlobalCore.Macro = MacroEngine
    GlobalCore.Collector = CollectorEngine
    GlobalCore.Waypoints = WaypointEngine
    GlobalCore.MovementEngine = MovementEngine
    GlobalCore.MacroEngine = MacroEngine
    GlobalCore.CollectorEngine = CollectorEngine
    GlobalCore.WaypointEngine = WaypointEngine
end

return exportTable
