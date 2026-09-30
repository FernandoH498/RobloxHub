-- language: Lua, file: v14_game_trolling.lua, runtime: Roblox Luau, target: GoHub V14 UI/UX 2.0, MM2 Suite 2.0 & Physics Trolling
-- ==============================================================================
-- GOHUB V14 — UNIVERSAL SUITE: UI/UX 2.0, MM2 SUITE 2.0 & PHYSICS TROLLING
-- Milestone 5: Mobile Floating Dock, Zero-Alloc Telemetry HUD, Dynamic Crosshair/Hitmarkers,
--              MM2 Ballistic Intercept, 2D Radar, Stare/Spectator HUD, Knife Auto-Dodge,
--              Multi-Game Profiles, Vortex Black Hole Fling, Reversible Ragdoll,
--              Invisible Car/Kidnap Aura, and Clone Runner Decoy.
-- ==============================================================================

local GameTrollingModule = {}
GameTrollingModule.__index = GameTrollingModule
GameTrollingModule.Version = "14.0.0"

-- Service Acquisition
local function safeGetService(name)
    local ok, service = pcall(function() return game:GetService(name) end)
    if ok and service then return service end
    return nil
end

local Players = safeGetService("Players")
local RunService = safeGetService("RunService")
local UserInputService = safeGetService("UserInputService")
local TweenService = safeGetService("TweenService")
local Workspace = safeGetService("Workspace") or workspace
local Debris = safeGetService("Debris")
local HttpService = safeGetService("HttpService")
local PathfindingService = safeGetService("PathfindingService")

local LocalPlayer = Players and Players.LocalPlayer
local Camera = Workspace and Workspace.CurrentCamera

-- Global HubState reference
local HubState = rawget(_G, "GoHubV14State") or rawget(shared, "GoHubV14State") or {}
local AudioEngine = rawget(_G, "GoHubV14Audio") or rawget(shared, "GoHubV14Audio")

-- Helper for Safe GUI Root
local function getGuiRoot()
    if typeof(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore and core then return core end
    if LocalPlayer then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then return pg end
    end
    return Workspace
end

-- ==============================================================================
-- 1. ENGINE R5: MOBILE FLOATING CAPSULE DOCK
-- ==============================================================================
local DockEngine = {
    Visible = false,
    Expanded = false,
    ScreenGui = nil,
    Capsule = nil,
    ActionsFrame = nil,
}

function DockEngine.Init(guiRoot, onToggleHub)
    guiRoot = guiRoot or getGuiRoot()
    if DockEngine.ScreenGui then return DockEngine end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GoHubV14_FloatingDock"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 999
    pcall(function() sg.Parent = guiRoot end)
    DockEngine.ScreenGui = sg

    local capsule = Instance.new("Frame")
    capsule.Name = "DockCapsule"
    capsule.Size = UDim2.new(0, 44, 0, 44)
    capsule.Position = UDim2.new(0.05, 0, 0.35, 0)
    capsule.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    capsule.BackgroundTransparency = 0.15
    capsule.ClipsDescendants = true
    capsule.Active = true
    capsule.Parent = sg
    DockEngine.Capsule = capsule

    local corner = Instance.new("UICorner", capsule)
    corner.CornerRadius = UDim.new(0, 22)

    local stroke = Instance.new("UIStroke", capsule)
    stroke.Color = Color3.fromRGB(150, 70, 240)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3

    -- Main toggle icon
    local hubBtn = Instance.new("ImageButton", capsule)
    hubBtn.Name = "HubToggleBtn"
    hubBtn.Size = UDim2.new(0, 44, 0, 44)
    hubBtn.Position = UDim2.new(0, 0, 0, 0)
    hubBtn.BackgroundTransparency = 1
    hubBtn.Image = "rbxassetid://135247969077372"
    hubBtn.ScaleType = Enum.ScaleType.Fit

    -- Container for quick action buttons
    local actions = Instance.new("Frame", capsule)
    actions.Name = "Actions"
    actions.Size = UDim2.new(0, 220, 0, 44)
    actions.Position = UDim2.new(0, 48, 0, 0)
    actions.BackgroundTransparency = 1
    DockEngine.ActionsFrame = actions

    local layout = Instance.new("UIListLayout", actions)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center

    local function makeDockAction(name, icon, callback)
        local btn = Instance.new("ImageButton", actions)
        btn.Name = name .. "Btn"
        btn.Size = UDim2.new(0, 32, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
        btn.BackgroundTransparency = 0.3
        btn.Image = icon
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = Color3.fromRGB(170, 85, 255)
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.6

        btn.MouseButton1Click:Connect(function()
            if AudioEngine and AudioEngine.PlaySFX then
                AudioEngine.PlaySFX("Click")
            end
            callback()
        end)
        return btn
    end

    makeDockAction("Fly", "rbxassetid://6031075931", function()
        if rawget(_G, "GoHubV14Movement") and _G.GoHubV14Movement.ToggleFlight then
            _G.GoHubV14Movement.ToggleFlight()
        end
    end)

    makeDockAction("Noclip", "rbxassetid://6031075938", function()
        if rawget(_G, "GoHubV14Movement") and _G.GoHubV14Movement.SetNoclip then
            local cur = HubState.Movement and HubState.Movement.Noclip or false
            _G.GoHubV14Movement.SetNoclip(not cur)
        end
    end)

    makeDockAction("ESP", "rbxassetid://6031075929", function()
        local cur = HubState.MM2 and HubState.MM2.RoleESP or false
        if HubState.MM2 then HubState.MM2.RoleESP = not cur end
    end)

    makeDockAction("Speed", "rbxassetid://6031075933", function()
        if rawget(_G, "GoHubV14Movement") and _G.GoHubV14Movement.SetSpeed then
            local cur = HubState.Movement and HubState.Movement.Speed or 16
            local nxt = (cur >= 50) and 16 or 50
            _G.GoHubV14Movement.SetSpeed(nxt)
        end
    end)

    makeDockAction("Audio", "rbxassetid://6031075927", function()
        if AudioEngine and AudioEngine.SetBassBoost then
            local cur = HubState.Audio and HubState.Audio.BassBoost or false
            AudioEngine.SetBassBoost(not cur, 10.0)
        end
    end)

    -- Draggable & Edge Snapping
    local isDragging = false
    local dragStart = Vector2.zero
    local startPos = UDim2.new()
    local totalMove = 0

    hubBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = capsule.Position
            totalMove = 0
        end
    end)

    if UserInputService then
        UserInputService.InputChanged:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                totalMove = totalMove + delta.Magnitude
                capsule.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if isDragging then
                    isDragging = false
                    if totalMove < 6 then
                        DockEngine.ToggleExpand()
                        if onToggleHub then onToggleHub() end
                    else
                        DockEngine.SnapToEdge()
                    end
                end
            end
        end)
    end

    DockEngine.Visible = true
    return DockEngine
end

function DockEngine.SetVisible(visible)
    DockEngine.Visible = visible
    if DockEngine.ScreenGui then
        DockEngine.ScreenGui.Enabled = visible
    end
end

function DockEngine.Toggle(visible)
    if visible == nil then
        DockEngine.SetVisible(not DockEngine.Visible)
    else
        DockEngine.SetVisible(visible == true)
    end
end

function DockEngine.ToggleExpand()
    DockEngine.Expanded = not DockEngine.Expanded
    local targetW = DockEngine.Expanded and 270 or 44
    if DockEngine.Capsule and TweenService then
        TweenService:Create(DockEngine.Capsule, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, targetW, 0, 44)
        }):Play()
    end
end

function DockEngine.SnapToEdge()
    if not DockEngine.Capsule or not Workspace.CurrentCamera then return end
    local viewport = Workspace.CurrentCamera.ViewportSize
    local curX = DockEngine.Capsule.AbsolutePosition.X
    local snapX = (curX < viewport.X / 2) and 12 or (viewport.X - DockEngine.Capsule.AbsoluteSize.X - 12)
    local curY = math.clamp(DockEngine.Capsule.AbsolutePosition.Y, 20, viewport.Y - 60)

    if TweenService then
        TweenService:Create(DockEngine.Capsule, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, snapX, 0, curY)
        }):Play()
    end
end

-- ==============================================================================
-- 2. ENGINE R5: ZERO-ALLOC TELEMETRY HUD & SPARKLINES
-- ==============================================================================
local TelemetryEngine = {
    Capacity = 60,
    Samples = table.create(60, 0.0166),
    Head = 1,
    SortedScratch = table.create(60, 0.0166),
    Bars = table.create(60),
    Container = nil,
    Label = nil,
    LastRenderTime = 0,
    Active = false,
}

function TelemetryEngine.Init(guiRoot)
    guiRoot = guiRoot or getGuiRoot()
    if TelemetryEngine.Container then return TelemetryEngine end

    local container = Instance.new("Frame")
    container.Name = "GoHubV14_TelemetryHUD"
    container.Size = UDim2.new(0, 204, 0, 58)
    container.Position = UDim2.new(1, -216, 0, 12)
    container.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    container.BackgroundTransparency = 0.25
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(140, 60, 230)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.5
    pcall(function() container.Parent = guiRoot end)
    TelemetryEngine.Container = container

    local lbl = Instance.new("TextLabel", container)
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 6, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(235, 235, 255)
    lbl.Font = Enum.Font.RobotoMono
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "FPS: 60 (60) | 0ms | 0MB"
    TelemetryEngine.Label = lbl

    local sparkFrame = Instance.new("Frame", container)
    sparkFrame.Name = "SparklineContainer"
    sparkFrame.Size = UDim2.new(0, 60 * 3, 0, 26)
    sparkFrame.Position = UDim2.new(0, 8, 0, 24)
    sparkFrame.BackgroundTransparency = 1

    for i = 1, TelemetryEngine.Capacity do
        local bar = Instance.new("Frame", sparkFrame)
        bar.Size = UDim2.new(0, 2, 0, 2)
        bar.Position = UDim2.new(0, (i - 1) * 3, 1, -2)
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
        TelemetryEngine.Bars[i] = bar
    end

    TelemetryEngine.Active = true
    return TelemetryEngine
end

function TelemetryEngine.Update(dt)
    if not TelemetryEngine.Active then return end
    dt = math.max(dt or 0.0166, 0.0001)

    TelemetryEngine.Samples[TelemetryEngine.Head] = dt
    TelemetryEngine.Head = (TelemetryEngine.Head % TelemetryEngine.Capacity) + 1

    local now = os.clock()
    if now - TelemetryEngine.LastRenderTime < 0.066 then return end
    TelemetryEngine.LastRenderTime = now

    -- Copy to scratch without allocation
    for i = 1, TelemetryEngine.Capacity do
        TelemetryEngine.SortedScratch[i] = TelemetryEngine.Samples[i]
    end
    table.sort(TelemetryEngine.SortedScratch)

    local p99Dt = TelemetryEngine.SortedScratch[TelemetryEngine.Capacity - 1]
    local curFps = math.floor(1 / dt)
    local lowFps = math.floor(1 / p99Dt)

    local ping = 0
    if LocalPlayer and typeof(LocalPlayer.GetNetworkPing) == "function" then
        ping = math.floor((LocalPlayer:GetNetworkPing() or 0) * 1000)
    end
    local memMb = math.floor((typeof(gcinfo) == "function" and gcinfo() or 0) / 1024)

    if TelemetryEngine.Label then
        TelemetryEngine.Label.Text = string.format("FPS: %d (%d) | %dms | %dMB", curFps, lowFps, ping, memMb)
    end

    local readIdx = TelemetryEngine.Head
    for i = 1, TelemetryEngine.Capacity do
        local sDt = TelemetryEngine.Samples[readIdx]
        readIdx = (readIdx % TelemetryEngine.Capacity) + 1

        local norm = math.clamp((1 / sDt) / 144, 0, 1)
        local barH = math.clamp(math.floor(norm * 24), 2, 24)
        local bar = TelemetryEngine.Bars[i]
        if bar then
            bar.Size = UDim2.new(0, 2, 0, barH)
            bar.Position = UDim2.new(0, (i - 1) * 3, 1, -barH)
            if norm >= 0.416 then
                bar.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
            elseif norm >= 0.208 then
                bar.BackgroundColor3 = Color3.fromRGB(255, 180, 40)
            else
                bar.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
            end
        end
    end
end

function TelemetryEngine.GetMetrics()
    local dt = TelemetryEngine.Samples[TelemetryEngine.Head] or 0.016
    local curFps = math.floor(1 / math.max(dt, 0.0001))
    local ping = LocalPlayer and typeof(LocalPlayer.GetNetworkPing) == "function" and math.floor(LocalPlayer:GetNetworkPing() * 1000) or 0
    local memMb = typeof(gcinfo) == "function" and math.floor(gcinfo() / 1024) or 0
    return {
        FPS = curFps,
        Ping = ping,
        MemoryMB = memMb
    }
end

function TelemetryEngine.Toggle(visible)
    if visible == nil then
        TelemetryEngine.Active = not TelemetryEngine.Active
    else
        TelemetryEngine.Active = (visible == true)
    end
    if not TelemetryEngine.Container and TelemetryEngine.Active then
        TelemetryEngine.Init()
    end
    if TelemetryEngine.Container then
        TelemetryEngine.Container.Visible = TelemetryEngine.Active
    end
end

-- ==============================================================================
-- 3. ENGINE R5: DYNAMIC CROSSHAIR & HITMARKERS
-- ==============================================================================
local CrosshairEngine = {
    Enabled = false,
    RecoilImpulse = 0,
    BaseGap = 4,
    Lines = {},
    Hitmarkers = {},
    Gui = nil,
}

function CrosshairEngine.Init(guiRoot)
    guiRoot = guiRoot or getGuiRoot()
    if CrosshairEngine.Gui then return CrosshairEngine end

    local sg = Instance.new("ScreenGui")
    sg.Name = "GoHubV14_CrosshairGui"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 998
    pcall(function() sg.Parent = guiRoot end)
    CrosshairEngine.Gui = sg

    local center = Instance.new("Frame", sg)
    center.Name = "CrosshairCenter"
    center.Size = UDim2.new(0, 0, 0, 0)
    center.Position = UDim2.new(0.5, 0, 0.5, 0)
    center.BackgroundTransparency = 1

    -- 4 lines: Top, Bottom, Left, Right
    local dirs = {
        Top = { Size = Vector2.new(2, 10), Offset = Vector2.new(-1, -14) },
        Bottom = { Size = Vector2.new(2, 10), Offset = Vector2.new(-1, 4) },
        Left = { Size = Vector2.new(10, 2), Offset = Vector2.new(-14, -1) },
        Right = { Size = Vector2.new(10, 2), Offset = Vector2.new(4, -1) },
    }

    for name, spec in pairs(dirs) do
        local line = Instance.new("Frame", center)
        line.Name = name
        line.Size = UDim2.new(0, spec.Size.X, 0, spec.Size.Y)
        line.Position = UDim2.new(0, spec.Offset.X, 0, spec.Offset.Y)
        line.BackgroundColor3 = Color3.fromRGB(240, 240, 255)
        line.BorderSizePixel = 0
        CrosshairEngine.Lines[name] = line
    end

    -- Hitmarker (4 diagonal ticks at 45 degrees)
    for i = 1, 4 do
        local tick = Instance.new("Frame", center)
        tick.Name = "Hitmarker_" .. i
        tick.Size = UDim2.new(0, 10, 0, 2)
        tick.Rotation = 45 + (i - 1) * 90
        tick.Position = UDim2.new(0, -5, 0, -1)
        tick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tick.BackgroundTransparency = 1
        tick.BorderSizePixel = 0
        CrosshairEngine.Hitmarkers[i] = tick
    end

    CrosshairEngine.Enabled = true
    return CrosshairEngine
end

function CrosshairEngine.TriggerHitmarker(isHeadshot)
    if not CrosshairEngine.Enabled then return end
    local hitColor = isHeadshot and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 255, 255)

    if AudioEngine and AudioEngine.PlaySFX then
        AudioEngine.PlaySFX("Hitmarker", isHeadshot and 1.25 or 1.0)
    end

    for _, tick in ipairs(CrosshairEngine.Hitmarkers) do
        tick.BackgroundColor3 = hitColor
        tick.BackgroundTransparency = 0
        if TweenService then
            TweenService:Create(tick, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
        end
    end
end

function CrosshairEngine.Update(dt)
    if not CrosshairEngine.Enabled then return end
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    local velMag = hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
    local velSpread = math.clamp(velMag * 0.25, 0, 16)
    CrosshairEngine.RecoilImpulse = math.max(0, CrosshairEngine.RecoilImpulse - dt * 14)

    local totalGap = CrosshairEngine.BaseGap + velSpread + CrosshairEngine.RecoilImpulse

    if CrosshairEngine.Lines.Top then
        CrosshairEngine.Lines.Top.Position = UDim2.new(0, -1, 0, -totalGap - 10)
        CrosshairEngine.Lines.Bottom.Position = UDim2.new(0, -1, 0, totalGap)
        CrosshairEngine.Lines.Left.Position = UDim2.new(0, -totalGap - 10, 0, -1)
        CrosshairEngine.Lines.Right.Position = UDim2.new(0, totalGap, 0, -1)
    end
end

function CrosshairEngine.Toggle(visible)
    if visible == nil then
        CrosshairEngine.Enabled = not CrosshairEngine.Enabled
    else
        CrosshairEngine.Enabled = (visible == true)
    end
    if not CrosshairEngine.Gui and CrosshairEngine.Enabled then
        CrosshairEngine.Init()
    end
    if CrosshairEngine.Gui then
        CrosshairEngine.Gui.Enabled = CrosshairEngine.Enabled
    end
end

-- ==============================================================================
-- 4. ENGINE R6: GAME PROFILES & MURDER MYSTERY 2 SUITE 2.0
-- ==============================================================================
local MM2Engine = {
    RoleESPActive = false,
    CoinESPActive = false,
    AutoGrabGun = false,
    HitboxExpand = false,
    BallisticAim = false,
    RadarActive = false,
    StaringHUDActive = false,
    KnifeDodgeActive = false,
    ActiveProfile = "Universal",
    Roles = {
        Murderer = nil,
        Sheriff = nil,
        Hero = nil,
        Innocents = {},
    },
    RadarBlips = {},
    RadarContainer = nil,
}

-- Closed-form quadratic solver for ballistic interception
function MM2Engine.ComputeBallisticAim(shooterPos, targetPos, targetVel, bulletSpeed, pingSec)
    bulletSpeed = bulletSpeed or 250.0
    pingSec = pingSec or 0.05

    -- Compensate target position for ping latency
    local P_t = targetPos + targetVel * pingSec
    local deltaP = P_t - shooterPos

    -- Quadratic coefficients: a*t^2 + b*t + c = 0
    local a = targetVel:Dot(targetVel) - (bulletSpeed * bulletSpeed)
    local b = 2 * deltaP:Dot(targetVel)
    local c = deltaP:Dot(deltaP)

    local disc = b * b - 4 * a * c
    if disc < 0 then
        -- No real solution, target moving too fast away: fallback to current position
        return P_t, 0
    end

    local t1 = (-b - math.sqrt(disc)) / (2 * a)
    local t2 = (-b + math.sqrt(disc)) / (2 * a)

    local tLead = nil
    if t1 > 0 and t2 > 0 then
        tLead = math.min(t1, t2)
    elseif t1 > 0 then
        tLead = t1
    elseif t2 > 0 then
        tLead = t2
    else
        return P_t, 0
    end

    local interceptPoint = P_t + targetVel * tLead
    return interceptPoint, tLead
end

-- Automatic Profile Detection
function MM2Engine.DetectProfile()
    local placeId = game.PlaceId
    local gameId = game.GameId

    local registry = {
        [142823291]   = "MM2",
        [335132309]   = "MM2",
        [13772394625] = "BladeBall",
        [17625359962] = "Rivals",
        [4924922222]  = "Brookhaven",
        [286090429]   = "Arsenal",
    }

    MM2Engine.ActiveProfile = registry[placeId] or registry[gameId] or "Universal"
    return MM2Engine.ActiveProfile
end

-- Staring Detection: Murderer gaze check
function MM2Engine.CheckMurdererStare(murdererChar)
    if not murdererChar or not LocalPlayer.Character then return false end
    local mRoot = murdererChar:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not mRoot or not myRoot then return false end

    local toMe = (myRoot.Position - mRoot.Position).Unit
    local look = mRoot.CFrame.LookVector
    local dot = look:Dot(toMe)

    -- Threshold cos(15 deg) = 0.9659
    if dot >= 0.965 then
        -- LoS check
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = { murdererChar, LocalPlayer.Character }
        local hit = Workspace:Raycast(mRoot.Position, myRoot.Position - mRoot.Position, rayParams)
        if not hit then
            return true
        end
    end
    return false
end

-- Knife Throw Detection: Closest Point of Approach (CPA)
function MM2Engine.CheckKnifeThrowCPA(knifePart)
    if not knifePart or not LocalPlayer.Character then return false end
    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end

    local Vk = knifePart.AssemblyLinearVelocity
    local vkSq = Vk:Dot(Vk)
    if vkSq < 100 then return false end -- Not a fast projectile

    local r0 = knifePart.Position - myRoot.Position
    local tCPA = -r0:Dot(Vk) / vkSq

    if tCPA > 0 and tCPA <= 1.5 then
        local pCPA = knifePart.Position + Vk * tCPA
        local missDist = (pCPA - myRoot.Position).Magnitude
        if missDist <= 6.0 then
            -- Dodge laterally
            local up = Vector3.new(0, 1, 0)
            local lateral = Vk:Cross(up).Unit
            myRoot.CFrame = myRoot.CFrame + lateral * 12
            return true
        end
    end
    return false
end

function MM2Engine.AutoShoot(enabled)
    MM2Engine.BallisticAim = (enabled == true)
end
MM2Engine.ToggleAutoShoot = MM2Engine.AutoShoot

function MM2Engine.ToggleRadar(enabled)
    MM2Engine.RadarActive = (enabled == true)
    if not MM2Engine.RadarContainer and enabled then
        MM2Engine.SetupRadar()
    end
    if MM2Engine.RadarContainer then
        MM2Engine.RadarContainer.Visible = (enabled == true)
    end
end

function MM2Engine.ToggleStareHUD(enabled)
    MM2Engine.StaringHUDActive = (enabled == true)
    if MM2Engine.StareHUDContainer then
        MM2Engine.StareHUDContainer.Visible = (enabled == true)
    end
end

function MM2Engine.ToggleKnifeDodge(enabled)
    MM2Engine.KnifeDodgeActive = (enabled == true)
end

-- 2D Radar Minimap Initialization
function MM2Engine.SetupRadar(guiRoot)
    guiRoot = guiRoot or getGuiRoot()
    if MM2Engine.RadarContainer then return MM2Engine end

    local container = Instance.new("Frame")
    container.Name = "GoHubV14_MM2Radar"
    container.Size = UDim2.new(0, 160, 0, 160)
    container.Position = UDim2.new(0, 15, 1, -180)
    container.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
    container.BackgroundTransparency = 0.3
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 80)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(160, 80, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4
    pcall(function() container.Parent = guiRoot end)
    MM2Engine.RadarContainer = container

    -- Center player blip
    local centerBlip = Instance.new("Frame", container)
    centerBlip.Size = UDim2.new(0, 6, 0, 6)
    centerBlip.Position = UDim2.new(0.5, -3, 0.5, -3)
    centerBlip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", centerBlip).CornerRadius = UDim.new(1, 0)

    MM2Engine.RadarActive = true
    return MM2Engine
end

function MM2Engine.UpdateRadar()
    if not MM2Engine.RadarActive or not MM2Engine.RadarContainer or not Camera or not LocalPlayer.Character then return end
    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local myPos = myRoot.Position
    local camLook = Camera.CFrame.LookVector
    local yaw = math.atan2(-camLook.X, -camLook.Z)
    local cosY, sinY = math.cos(yaw), math.sin(yaw)

    local R_max = 70.0
    local scale = 0.7

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local tRoot = p.Character.HumanoidRootPart
            local dx = tRoot.Position.X - myPos.X
            local dz = tRoot.Position.Z - myPos.Z

            -- 2D rotation matrix
            local xRot = dx * cosY - dz * sinY
            local yRot = dx * sinY + dz * cosY

            local dist = math.sqrt(xRot * xRot + yRot * yRot) * scale
            local angle = math.atan2(yRot, xRot)
            local clampedDist = math.min(dist, R_max)

            local blip = MM2Engine.RadarBlips[p.UserId]
            if not blip then
                blip = Instance.new("Frame", MM2Engine.RadarContainer)
                blip.Size = UDim2.new(0, 6, 0, 6)
                Instance.new("UICorner", blip).CornerRadius = UDim.new(1, 0)
                blip.BorderSizePixel = 0
                MM2Engine.RadarBlips[p.UserId] = blip
            end

            blip.Position = UDim2.new(0.5, math.floor(clampedDist * math.cos(angle) - 3), 0.5, math.floor(clampedDist * math.sin(angle) - 3))
            
            -- Role color resolution: direct assignment or global role cache
            local roleCache = rawget(_G, "GoHubV14MM2RoleCache")
            local roleFromCache = roleCache and (roleCache[p.Name:lower()] or roleCache[tostring(p.UserId)])

            if MM2Engine.Roles.Murderer == p or roleFromCache == "MURDER" then
                blip.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
            elseif MM2Engine.Roles.Sheriff == p or MM2Engine.Roles.Hero == p or roleFromCache == "SHERIFE" or roleFromCache == "HEROI" then
                blip.BackgroundColor3 = Color3.fromRGB(40, 140, 255)
            else
                blip.BackgroundColor3 = Color3.fromRGB(40, 220, 100)
            end
            blip.Visible = true
        elseif MM2Engine.RadarBlips[p.UserId] then
            MM2Engine.RadarBlips[p.UserId].Visible = false
        end
    end
end

-- ==============================================================================
-- 5. ENGINE R7: PHYSICS TROLLING & FUN MODULES
-- ==============================================================================
local TrollingEngine = {
    VortexActive = false,
    IsRagdolled = false,
    DisabledMotors = {},
    CreatedConstraints = {},
    InvisibleCarModel = nil,
    KidnapActive = false,
    DecoyClone = nil,
}

-- Black Hole / Vortex Fling with Spiral Accretion Disc
function TrollingEngine.StartVortexFling(centerCFrame, duration)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    duration = duration or 5.0
    centerCFrame = centerCFrame or hrp.CFrame
    local startT = os.clock()
    local center = centerCFrame.Position
    local up = Vector3.new(0, 1, 0)

    TrollingEngine.VortexActive = true
    hrp.AssemblyAngularVelocity = Vector3.new(0, 99999, 0)

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if os.clock() - startT > duration or not TrollingEngine.VortexActive or not char.Parent then
            conn:Disconnect()
            TrollingEngine.VortexActive = false
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            return
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local tRoot = p.Character.HumanoidRootPart
                local diff = tRoot.Position - center
                local dist = diff.Magnitude

                if dist < 35 then
                    if dist <= 3.5 then
                        -- Singularity impact: violent eject
                        hrp.CFrame = tRoot.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
                        hrp.AssemblyLinearVelocity = Vector3.new(999999, 999999, 999999)
                    else
                        -- Accretion spiral
                        local tanDir = up:Cross(diff).Unit
                        local radDir = -diff.Unit
                        local speedTan = 80 / math.sqrt(dist + 1)
                        local speedRad = 150 / (dist + 0.5)

                        hrp.CFrame = CFrame.new(center + diff + (tanDir * speedTan + radDir * speedRad) * 0.016)
                    end
                end
            end
        end
    end)
end

-- 100% Reversible Fake Death / Ragdoll (Motor6D decoupler + BallSocketConstraints)
function TrollingEngine.ToggleFakeDeath(enable)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then return end

    if enable and not TrollingEngine.IsRagdolled then
        TrollingEngine.IsRagdolled = true
        table.clear(TrollingEngine.DisabledMotors)
        table.clear(TrollingEngine.CreatedConstraints)

        hum.PlatformStand = true
        hum.AutoRotate = false
        hum:ChangeState(Enum.HumanoidStateType.Physics)

        for _, motor in ipairs(char:GetDescendants()) do
            if motor:IsA("Motor6D") and motor.Name ~= "Root" then
                motor.Enabled = false
                table.insert(TrollingEngine.DisabledMotors, motor)

                local part0 = motor.Part0
                local part1 = motor.Part1
                if part0 and part1 then
                    local a0 = Instance.new("Attachment", part0)
                    a0.CFrame = motor.C0
                    local a1 = Instance.new("Attachment", part1)
                    a1.CFrame = motor.C1

                    local bsc = Instance.new("BallSocketConstraint", part0)
                    bsc.Attachment0 = a0
                    bsc.Attachment1 = a1
                    bsc.LimitsEnabled = true
                    bsc.TwistLimitsEnabled = true
                    bsc.UpperAngle = 45
                    bsc.TwistLowerAngle = -45
                    bsc.TwistUpperAngle = 45

                    table.insert(TrollingEngine.CreatedConstraints, bsc)
                    table.insert(TrollingEngine.CreatedConstraints, a0)
                    table.insert(TrollingEngine.CreatedConstraints, a1)
                end
            end
        end
    elseif not enable and TrollingEngine.IsRagdolled then
        TrollingEngine.IsRagdolled = false

        for _, inst in ipairs(TrollingEngine.CreatedConstraints) do
            pcall(function() inst:Destroy() end)
        end
        table.clear(TrollingEngine.CreatedConstraints)

        for _, motor in ipairs(TrollingEngine.DisabledMotors) do
            if motor and motor.Parent then
                motor.Enabled = true
            end
        end
        table.clear(TrollingEngine.DisabledMotors)

        hum.PlatformStand = false
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

-- Invisible Car & Kidnap Aura
function TrollingEngine.SpawnInvisibleCar()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if TrollingEngine.InvisibleCarModel then
        TrollingEngine.InvisibleCarModel:Destroy()
        TrollingEngine.InvisibleCarModel = nil
    end

    local car = Instance.new("Model", Workspace)
    car.Name = "GoHub_InvisibleCar"

    local seat = Instance.new("VehicleSeat", car)
    seat.Size = Vector3.new(4, 1, 4)
    seat.Position = hrp.Position + Vector3.new(0, 1, 0)
    seat.Transparency = 1
    seat.CanCollide = true
    seat.MaxSpeed = 150
    seat.Torque = 50000

    seat:Sit(char.Humanoid)
    TrollingEngine.InvisibleCarModel = car
    return car
end

function TrollingEngine.ToggleKidnapAura(enable)
    TrollingEngine.KidnapActive = enable
    if not enable then return end

    task.spawn(function()
        while TrollingEngine.KidnapActive and LocalPlayer.Character do
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local tRoot = p.Character.HumanoidRootPart
                        local dist = (tRoot.Position - hrp.Position).Magnitude
                        if dist <= 8.0 then
                            -- Plunge target into void
                            tRoot.CFrame = hrp.CFrame
                            hrp.AssemblyLinearVelocity = Vector3.new(0, -250, 0)
                            task.wait(0.5)
                            break
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- Clone Runner Decoy & Stealth Cloak
function TrollingEngine.DeployCloneDecoy()
    local char = LocalPlayer.Character
    if not char then return end

    char.Archivable = true
    local clone = char:Clone()
    clone.Name = LocalPlayer.Name .. "_Decoy"
    clone.Parent = Workspace

    -- Cloak real player
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.Transparency = 1
        end
    end

    -- Run clone away
    local hum = clone:FindFirstChildOfClass("Humanoid")
    local root = clone:FindFirstChild("HumanoidRootPart")
    if hum and root then
        local targetPos = root.Position + Vector3.new(math.random(-80, 80), 0, math.random(-80, 80))
        hum:MoveTo(targetPos)
    end

    Debris:AddItem(clone, 8)
    TrollingEngine.DecoyClone = clone
    return clone
end

function TrollingEngine.StopVortexFling()
    TrollingEngine.VortexActive = false
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

TrollingEngine.SpawnDecoy = TrollingEngine.DeployCloneDecoy

-- Export APIs
GameTrollingModule.DockEngine = DockEngine
GameTrollingModule.TelemetryEngine = TelemetryEngine
GameTrollingModule.CrosshairEngine = CrosshairEngine
GameTrollingModule.MM2Engine = MM2Engine
GameTrollingModule.TrollingEngine = TrollingEngine

rawset(_G, "GoHubV14GameTrolling", GameTrollingModule)
rawset(shared, "GoHubV14GameTrolling", GameTrollingModule)
rawset(_G, "MM2Engine", MM2Engine)
rawset(shared, "MM2Engine", MM2Engine)
rawset(_G, "TrollingEngine", TrollingEngine)
rawset(shared, "TrollingEngine", TrollingEngine)

return GameTrollingModule
