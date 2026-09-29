--[[
    ========================================================================
    GOHUB — DEFINITIVE V12 (FINAL ENGINE)
    Target: Roblox Studio / Luau Engine
    
    Front-End Guarantee:
      - 100% IDENTICAL FRONT-END DESIGN (Sidebar, Avatar ID 135247969077372,
        Dark Theme 15,15,22, Purple Glow, Draggable Window, Sliders, Close Btn).
      - Zero visual regressions.
      
    V11 Final Engine Upgrades:
      1. Infinite Yield Complete Fling Engine (WalkFling, SpinFling, Target Fling, AntiFling)
      2. R15 & Jamal Viral Emotes Suite + IY Dance Suite + Real-Time Speed Slider
      3. Waypoints System (Save, List, Teleport)
      4. Advanced Character Tools (Anti-Sit, SpinBot, Instant Respawn)
      5. Universal ESP with Chams & MM2 Full Suite
      6. Full Target Parser & Retractable Command Bar (Key ';')
      7. Smooth Flight V7/V8 Engine & WalkSpeed Heartbeat Loop
    ========================================================================
]]

if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
while not Camera do
    task.wait(0.1)
    Camera = Workspace.CurrentCamera
end
local Mouse = LocalPlayer:GetMouse()

-- Safe GuiRoot Discovery (Universal Executor & Vanilla Compatibility)
local function GetSafeGuiRoot()
    local successHui, hui = pcall(function() return typeof(gethui) == "function" and gethui() end)
    if successHui and hui then return hui end
    
    local successHui2, hui2 = pcall(function() return typeof(get_hidden_gui) == "function" and get_hidden_gui() end)
    if successHui2 and hui2 then return hui2 end
    
    local successCore, core = pcall(function() return game:GetService("CoreGui") end)
    if successCore and core then
        local canParent = pcall(function()
            local test = Instance.new("Folder")
            test.Parent = core
            test:Destroy()
        end)
        if canParent then return core end
    end
    
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    return pg
end

local GuiRoot = GetSafeGuiRoot() or LocalPlayer:WaitForChild("PlayerGui")

-- ====================================================================
-- CONFIGURAÇÕES GLOBAIS & ESTADO DO HUB (V10)
-- ====================================================================
local HubState = {
    Theme = {
        Background = Color3.fromRGB(15, 15, 22),
        Sidebar = Color3.fromRGB(22, 22, 32),
        Card = Color3.fromRGB(28, 28, 40),
        Accent = Color3.fromRGB(148, 0, 211),
        AccentGlow = Color3.fromRGB(180, 50, 255),
        Text = Color3.fromRGB(245, 245, 250),
        TextDim = Color3.fromRGB(150, 150, 170),
        Close = Color3.fromRGB(220, 60, 60),
        Success = Color3.fromRGB(60, 220, 120),
        Murderer = Color3.fromRGB(255, 40, 40),
        Sheriff = Color3.fromRGB(40, 140, 255),
        Innocent = Color3.fromRGB(40, 255, 120),
        Border = Color3.fromRGB(148, 0, 211)
    },
    Assets = {
        WaifuImageId = "rbxassetid://135247969077372"
    },
    Movement = {
        Speed = 16,
        DefaultSpeed = 16,
        SpeedActive = false,
        FlightSpeed = 50,
        FlightActive = false,
        NoclipActive = false,
        InfiniteJumpActive = false,
        ClickTPActive = false
    },
    Combat = {
        AimbotActive = false,
        TargetPart = "Head",
        FOV = 120,
        Smoothness = 0.2,
        TeamCheck = false,
        VisibilityCheck = true,
        FOVCircleVisible = true
    },
    Visuals = {
        XRayActive = false,
        FullbrightActive = false,
        NoFogActive = false,
        UniversalESP = false
    },
    MM2 = {
        RoleESP = false,
        CoinESP = false,
        AutoGrabGun = false,
        Hitboxes = false
    },
    Fling = {
        Active = false,
        WalkFling = false,
        AntiFling = false,
        LoopTarget = nil
    },
    Animation = {
        CurrentTrack = nil,
        Speed = 1
    },
    CustomDances = {},
    WindowMinimized = false,
    Character = {
        AntiSit = false,
        SpinBot = false,
        SpinSpeed = 30
    },
    Waypoints = {},
    Skin = {
        OriginalDesc = nil,
        HeadlessActive = false,
        KorbloxActive = false
    },
    Radial = {
        Visible = false,
        SelectedSlot = nil
    },
    CmdBar = {
        Prefix = ";",
        Visible = false
    }
}

-- ====================================================================
-- POOL DE EVENTOS & CONEXÕES
-- ====================================================================
local ConnectionPool = {}

local function RegisterLoop(tag, connection)
    if ConnectionPool[tag] then
        ConnectionPool[tag]:Disconnect()
    end
    ConnectionPool[tag] = connection
end

local function DropLoop(tag)
    if ConnectionPool[tag] then
        ConnectionPool[tag]:Disconnect()
        ConnectionPool[tag] = nil
    end
end

-- ====================================================================
-- ANTI-AFK NATIVO (VirtualUser Hook)
-- ====================================================================
RegisterLoop("AntiAFK_Loop", LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end))

-- ====================================================================
-- TARGET PARSER DO INFINITE YIELD
-- ====================================================================
local TargetParser = {}

function TargetParser.FindPlayers(query)
    if not query or query == "" then return {} end
    local q = query:lower()
    local result = {}
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if q == "me" then
        return {LocalPlayer}
    elseif q == "all" then
        for _, p in ipairs(Players:GetPlayers()) do table.insert(result, p) end
        return result
    elseif q == "others" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(result, p) end
        end
        return result
    elseif q == "random" then
        local others = TargetParser.FindPlayers("others")
        if #others > 0 then return {others[math.random(1, #others)]} end
        return {}
    elseif q == "nearest" then
        if not myRoot then return {} end
        local nearest, dist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = p
                end
            end
        end
        return nearest and {nearest} or {}
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #q) == q or p.DisplayName:lower():sub(1, #q) == q or p.Name:lower():find(q) or p.DisplayName:lower():find(q) then
            table.insert(result, p)
        end
    end
    return result
end

-- ====================================================================
-- FÍSICA E MOVIMENTAÇÃO (FLIGHT, SPEED, NOCLIP, CLICKTP, INF JUMP)
-- ====================================================================
local MovementEngine = {}
local bgInstance, bvInstance

function MovementEngine.SetFlight(enabled)
    HubState.Movement.FlightActive = enabled
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not enabled or not hrp or not hum then
        DropLoop("Flight_Render")
        if bgInstance then bgInstance:Destroy(); bgInstance = nil end
        if bvInstance then bvInstance:Destroy(); bvInstance = nil end
        if hum then hum.PlatformStand = false end
        return
    end

    if bgInstance then bgInstance:Destroy() end
    if bvInstance then bvInstance:Destroy() end

    bgInstance = Instance.new("BodyGyro")
    bgInstance.P = 9e4
    bgInstance.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bgInstance.CFrame = hrp.CFrame
    bgInstance.Parent = hrp

    bvInstance = Instance.new("BodyVelocity")
    bvInstance.Velocity = Vector3.zero
    bvInstance.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bvInstance.Parent = hrp

    hum.PlatformStand = true

    RegisterLoop("Flight_Render", RunService.RenderStepped:Connect(function()
        if not HubState.Movement.FlightActive or not hrp or not hrp.Parent then
            MovementEngine.SetFlight(false)
            return
        end

        local cam = Workspace.CurrentCamera
        bgInstance.CFrame = cam.CFrame

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        if moveDir.Magnitude > 0 then
            bvInstance.Velocity = moveDir.Unit * HubState.Movement.FlightSpeed
        else
            bvInstance.Velocity = Vector3.zero
        end
    end))
end

function MovementEngine.ApplySpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = HubState.Movement.SpeedActive and HubState.Movement.Speed or HubState.Movement.DefaultSpeed
    end
end

RegisterLoop("Speed_Heartbeat", RunService.Heartbeat:Connect(function()
    if HubState.Movement.SpeedActive then MovementEngine.ApplySpeed() end
end))

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.4)
    if HubState.Movement.SpeedActive then MovementEngine.ApplySpeed() end
end)

function MovementEngine.SetNoclip(enabled)
    HubState.Movement.NoclipActive = enabled
    if enabled then
        RegisterLoop("Core_Noclip", RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end))
    else
        DropLoop("Core_Noclip")
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end
            end
        end
    end
end

function MovementEngine.SetInfiniteJump(enabled)
    HubState.Movement.InfiniteJumpActive = enabled
    if enabled then
        RegisterLoop("Core_InfJump", UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
    else
        DropLoop("Core_InfJump")
    end
end

function MovementEngine.SetClickTP(enabled)
    HubState.Movement.ClickTPActive = enabled
    if enabled then
        RegisterLoop("Core_ClickTP", UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and Mouse.Hit then hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
            end
        end))
    else
        DropLoop("Core_ClickTP")
    end
end

function MovementEngine.GiveTPTool()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp or bp:FindFirstChild("Waifu TP Tool") then return end
    local tool = Instance.new("Tool")
    tool.Name = "Waifu TP Tool"
    tool.RequiresHandle = false
    tool.Activated:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and Mouse.Hit then hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
    end)
    tool.Parent = bp
end

-- ====================================================================
-- SISTEMA DE WAYPOINTS DO INFINITE YIELD
-- ====================================================================
local WaypointEngine = {}

function WaypointEngine.SaveCurrent(name)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local wpName = name or ("Ponto_" .. (#HubState.Waypoints + 1))
    table.insert(HubState.Waypoints, { Name = wpName, CFrame = hrp.CFrame })
end

function WaypointEngine.TeleportTo(wp)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and wp and wp.CFrame then
        hrp.CFrame = wp.CFrame
    end
end

-- ====================================================================
-- SISTEMA DE FLING (MOTOR INFINITE YIELD: WALKFLING, SPINFLING & ANTIFLING)
-- ====================================================================
local FlingEngine = {}

-- 1. WALKFLING (O clássico mais estável do Infinite Yield)
-- Permite andar normalmente sem girar a tela; ao encostar em qualquer player, lança-o violentamente
function FlingEngine.ToggleWalkFling(enabled)
    HubState.Fling.WalkFling = enabled
    if not enabled then
        DropLoop("WalkFling_Heartbeat")
        MovementEngine.SetNoclip(false)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        return
    end

    MovementEngine.SetNoclip(true)
    local movel = 0.1
    RegisterLoop("WalkFling_Heartbeat", RunService.Heartbeat:Connect(function()
        if not HubState.Fling.WalkFling then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and char.Parent and root and root.Parent) then return end

        local vel = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)

        RunService.RenderStepped:Wait()
        if char and char.Parent and root and root.Parent then
            root.AssemblyLinearVelocity = vel
        end

        RunService.Stepped:Wait()
        if char and char.Parent and root and root.Parent then
            root.AssemblyLinearVelocity = vel + Vector3.new(0, movel, 0)
            movel = movel * -1
        end
    end))
end

-- 2. SPINFLING (Fling Clássico por Torque com propriedades físicas reforçadas do IY)
function FlingEngine.ToggleSpinFling(enabled)
    HubState.Fling.Active = enabled
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if enabled then
        for _, child in ipairs(char:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
            end
        end
        MovementEngine.SetNoclip(true)
        task.wait(0.1)

        local spin = hrp:FindFirstChild("WaifuFlingSpin") or Instance.new("BodyAngularVelocity")
        spin.Name = "WaifuFlingSpin"
        spin.Parent = hrp
        spin.MaxTorque = Vector3.new(0, math.huge, 0)
        spin.P = math.huge
        spin.AngularVelocity = Vector3.new(0, 99999, 0)

        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("BasePart") then
                v.Massless = true
                v.AssemblyLinearVelocity = Vector3.zero
            end
        end

        RegisterLoop("SpinFling_Pulse", RunService.Heartbeat:Connect(function()
            if not HubState.Fling.Active or not spin or not spin.Parent then return end
            spin.AngularVelocity = Vector3.new(0, 99999, 0)
        end))
    else
        DropLoop("SpinFling_Pulse")
        MovementEngine.SetNoclip(false)
        if hrp:FindFirstChild("WaifuFlingSpin") then
            hrp.WaifuFlingSpin:Destroy()
        end
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                v.Massless = false
                v.AssemblyLinearVelocity = Vector3.zero
            elseif v:IsA("BodyAngularVelocity") and v.Name == "WaifuFlingSpin" then
                v:Destroy()
            end
        end
    end
end

-- Compatibilidade direta
function FlingEngine.ToggleFling(enabled)
    FlingEngine.ToggleSpinFling(enabled)
end

-- 3. FLING NO ALVO (Teleporte e colisão precisa sem destruir o próprio personagem)
function FlingEngine.FlingTarget(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local tHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHrp then return end

    local origCF = hrp.CFrame
    FlingEngine.ToggleSpinFling(true)

    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < 1.5 do
            RunService.Heartbeat:Wait()
            if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
            tHrp = targetPlayer.Character.HumanoidRootPart
            hrp.CFrame = tHrp.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
            hrp.AssemblyLinearVelocity = Vector3.new(9999, 9999, 9999)
        end
        FlingEngine.ToggleSpinFling(false)
        task.wait(0.05)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = origCF
    end)
end

-- Compatibilidade InvisFling
function FlingEngine.InvisFling(targetPlayer)
    FlingEngine.FlingTarget(targetPlayer)
end

-- 4. LOOP FLING NO ALVO
function FlingEngine.LoopFling(targetPlayer)
    HubState.Fling.LoopTarget = targetPlayer
    if not targetPlayer then
        DropLoop("LoopFling_Heartbeat")
        FlingEngine.ToggleSpinFling(false)
        return
    end

    FlingEngine.ToggleSpinFling(true)
    RegisterLoop("LoopFling_Heartbeat", RunService.Heartbeat:Connect(function()
        local target = HubState.Fling.LoopTarget
        if not target or not target.Character then
            FlingEngine.LoopFling(nil)
            return
        end
        local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if tRoot and myRoot then
            myRoot.CFrame = tRoot.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
            myRoot.AssemblyLinearVelocity = Vector3.new(9999, 9999, 9999)
        end
    end))
end

-- 5. ANTI-FLING (Proteção total do Infinite Yield)
function FlingEngine.ToggleAntiFling(enabled)
    HubState.Fling.AntiFling = enabled
    if enabled then
        RegisterLoop("AntiFling_Loop", RunService.Stepped:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end))
    else
        DropLoop("AntiFling_Loop")
    end
end

-- ====================================================================
-- SISTEMA DE PERSONAGEM (ANTI-SIT, SPINBOT)
-- ====================================================================
local CharEngine = {}

function CharEngine.ToggleAntiSit(enabled)
    HubState.Character.AntiSit = enabled
    if enabled then
        RegisterLoop("Char_AntiSit", RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Sit then hum.Sit = false end
        end))
    else
        DropLoop("Char_AntiSit")
    end
end

function CharEngine.ToggleSpinBot(enabled)
    HubState.Character.SpinBot = enabled
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if enabled then
        local spin = Instance.new("BodyAngularVelocity")
        spin.Name = "WaifuSpinBot"
        spin.MaxTorque = Vector3.new(0, math.huge, 0)
        spin.AngularVelocity = Vector3.new(0, HubState.Character.SpinSpeed, 0)
        spin.Parent = hrp
    else
        if hrp:FindFirstChild("WaifuSpinBot") then hrp.WaifuSpinBot:Destroy() end
    end
end

-- ====================================================================
-- ILUMINAÇÃO & MUNDO (FULLBRIGHT & NOFOG)
-- ====================================================================
local LightingEngine = {}
local OriginalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd
}

function LightingEngine.ToggleFullbright(enabled)
    HubState.Visuals.FullbrightActive = enabled
    if enabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    else
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
    end
end

function LightingEngine.ToggleNoFog(enabled)
    HubState.Visuals.NoFogActive = enabled
    if enabled then
        Lighting.FogEnd = 1e6
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then v.Density = 0 end
        end
    else
        Lighting.FogEnd = OriginalLighting.FogEnd
    end
end

-- ====================================================================
-- MOTOR DE ANIMAÇÕES & DANÇAS (R15 EXPANDIDO, PASSINHO DO JAMAL & IY)
-- ====================================================================
local AnimationEngine = {}

-- Banco Universal com IDs e fallbacks
local DualEmoteDatabase = {
    -- Passinho do Jamal (Tendência Viral Brasil)
    ["Passinho do Jamal (Principal)"] = { R15 = "rbxassetid://131086670591743" },
    ["Passinho do Jamal (Fogo Fogo)"] = { R15 = "rbxassetid://101508054279219" },
    ["Passinho do Jamal (Kitsi UGC)"] = { R15 = "rbxassetid://90852521137542" },
    ["Passinho do Jamal (Mandrake)"] = { R15 = "rbxassetid://95654893473488" },
    ["Passinho do Jamal (Dance Moves)"] = { R15 = "rbxassetid://121260976461862" },

    -- Danças Oficiais do Infinite Yield (R15)
    ["IY Dança 1 (Breakdance)"] = { R15 = "rbxassetid://3333432454" },
    ["IY Dança 2 (Pop & Lock)"] = { R15 = "rbxassetid://4555808220" },
    ["IY Dança 3 (Hip Hop / Hype)"] = { R15 = "rbxassetid://4049037604" },
    ["IY Dança 4 (Wave Step)"] = { R15 = "rbxassetid://4555782893" },
    ["IY Dança 5 (Freestyle)"] = { R15 = "rbxassetid://10214311282" },

    -- Danças Famosas & Virais (R15 & R6 Fallback)
    ["Floss"] = { R15 = "rbxassetid://10714340543", R6 = "rbxassetid://5917459365" },
    ["Dab"] = { R15 = "rbxassetid://10714107111", R6 = "rbxassetid://248263260" },
    ["Dizzy (SpiderTree)"] = { R15 = "rbxassetid://3361426436", R6 = "rbxassetid://182435998" },
    ["Swoosh"] = { R15 = "rbxassetid://3361487920", R6 = "rbxassetid://182436842" },
    ["Spin Dance"] = { R15 = "rbxassetid://3361481910", R6 = "rbxassetid://182436935" },
    ["Hyped"] = { R15 = "rbxassetid://3695333486", R6 = "rbxassetid://182435998" },
    ["Twirl"] = { R15 = "rbxassetid://3361499912", R6 = "rbxassetid://182436842" },
    ["Tilt Walk"] = { R15 = "rbxassetid://3361438942", R6 = "rbxassetid://182435998" },
    ["Dança Clássica 1"] = { R15 = "rbxassetid://507771019", R6 = "rbxassetid://182435998" },
    ["Dança Clássica 2"] = { R15 = "rbxassetid://507776043", R6 = "rbxassetid://182436842" },
    ["Dança Clássica 3"] = { R15 = "rbxassetid://507777268", R6 = "rbxassetid://182436935" },
    ["Cheer (Torcer)"] = { R15 = "rbxassetid://507770677", R6 = "rbxassetid://128777973" },
    ["Wave (Acenar)"] = { R15 = "rbxassetid://10714346580", R6 = "rbxassetid://128777973" },
    ["Point (Apontar)"] = { R15 = "rbxassetid://10714347258", R6 = "rbxassetid://128853357" },
    ["Laugh (Rir)"] = { R15 = "rbxassetid://10714344445", R6 = "rbxassetid://129423131" },
    ["Shrug (Ombros)"] = { R15 = "rbxassetid://10714348656", R6 = "rbxassetid://182435998" },
    ["Stadium (Estádio)"] = { R15 = "rbxassetid://3361440866", R6 = "rbxassetid://182436842" },
    ["Tilt (Curvar)"] = { R15 = "rbxassetid://3361464908", R6 = "rbxassetid://182435998" },
    ["Spasm (Spasm Dance)"] = { R15 = "rbxassetid://3361474812", R6 = "rbxassetid://248263260" },
    ["Zombie (Dança Zumbi)"] = { R15 = "rbxassetid://3361413867", R6 = "rbxassetid://182436935" }
}

-- Categorias para interface organizada
local EmoteCategories = {
    {
        Category = "Passinho do Jamal (Viral Brasil)",
        Emotes = {
            { Name = "Passinho do Jamal (Principal)", ID = "131086670591743" },
            { Name = "Passinho do Jamal (Fogo Fogo)", ID = "101508054279219" },
            { Name = "Passinho do Jamal (Kitsi UGC)", ID = "90852521137542" },
            { Name = "Passinho do Jamal (Mandrake)", ID = "95654893473488" },
            { Name = "Passinho do Jamal (Dance Moves)", ID = "121260976461862" }
        }
    },
    {
        Category = "Danças do Infinite Yield (R15)",
        Emotes = {
            { Name = "IY Dança 1 (Breakdance)", ID = "3333432454" },
            { Name = "IY Dança 2 (Pop & Lock)", ID = "4555808220" },
            { Name = "IY Dança 3 (Hip Hop / Hype)", ID = "4049037604" },
            { Name = "IY Dança 4 (Wave Step)", ID = "4555782893" },
            { Name = "IY Dança 5 (Freestyle)", ID = "10214311282" }
        }
    },
    {
        Category = "Danças Virais & Clássicas (R15)",
        Emotes = {
            { Name = "Floss", ID = "10714340543" },
            { Name = "Dizzy (SpiderTree)", ID = "3361426436" },
            { Name = "Spin Dance", ID = "3361481910" },
            { Name = "Hyped", ID = "3695333486" },
            { Name = "Swoosh", ID = "3361487920" },
            { Name = "Twirl", ID = "3361499912" },
            { Name = "Tilt Walk", ID = "3361438942" },
            { Name = "Dab", ID = "10714107111" },
            { Name = "Dança Clássica 1", ID = "507771019" },
            { Name = "Dança Clássica 2", ID = "507776043" },
            { Name = "Dança Clássica 3", ID = "507777268" },
            { Name = "Cheer (Torcer)", ID = "507770677" },
            { Name = "Wave (Acenar)", ID = "10714346580" },
            { Name = "Point (Apontar)", ID = "10714347258" },
            { Name = "Laugh (Rir)", ID = "10714344445" },
            { Name = "Shrug (Ombros)", ID = "10714348656" },
            { Name = "Stadium (Estádio)", ID = "3361440866" },
            { Name = "Tilt (Curvar)", ID = "3361464908" },
            { Name = "Spasm (Spasm Dance)", ID = "3361474812" },
            { Name = "Zombie (Dança Zumbi)", ID = "3361413867" }
        }
    }
}

function AnimationEngine.Stop()
    if HubState.Animation.CurrentTrack then
        pcall(function() HubState.Animation.CurrentTrack:Stop() end)
        HubState.Animation.CurrentTrack = nil
    end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            if track.Priority == Enum.AnimationPriority.Action4 then
                pcall(function() track:Stop() end)
            end
        end
    end
end

function AnimationEngine.SetSpeed(spd)
    HubState.Animation.Speed = tonumber(spd) or 1
    if HubState.Animation.CurrentTrack then
        pcall(function()
            HubState.Animation.CurrentTrack:AdjustSpeed(HubState.Animation.Speed)
        end)
    end
end

function AnimationEngine.PlayRaw(rawId, emoteName)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    AnimationEngine.Stop()

    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    local cleanId = tostring(rawId):gsub("%D", "")
    local track = nil

    -- Pipeline 1: Tentativa direta com Animation instance (rbxassetid://)
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. cleanId
    local s1, t1 = pcall(function()
        return animator:LoadAnimation(anim)
    end)
    if s1 and t1 then
        track = t1
    end

    -- Pipeline 2: game:GetObjects para unpack de bundle/UGC (Passinho do Jamal e similares)
    if not track or (track and track.Length == 0) then
        local sObjs, objs = pcall(function()
            return game:GetObjects("rbxassetid://" .. cleanId)
        end)
        if sObjs and objs and #objs > 0 then
            for _, obj in ipairs(objs) do
                local found = (obj:IsA("Animation") and obj) or obj:FindFirstChildOfClass("Animation", true)
                if found and found.AnimationId and found.AnimationId ~= "" then
                    local s2, t2 = pcall(function()
                        return animator:LoadAnimation(found)
                    end)
                    if s2 and t2 then
                        track = t2
                        break
                    end
                end
            end
        end
    end

    -- Pipeline 3: Fallback via HumanoidDescription
    if not track and emoteName then
        pcall(function()
            local desc = hum:FindFirstChildOfClass("HumanoidDescription") or hum:GetAppliedDescription()
            if desc then
                desc:AddEmote(emoteName, tonumber(cleanId))
                hum:PlayEmoteAsync(emoteName)
            end
        end)
    end

    -- Pipeline 4: Fallback Animate.PlayEmote
    if not track and emoteName then
        local animateScript = char:FindFirstChild("Animate")
        local playEmoteBindable = animateScript and animateScript:FindFirstChild("PlayEmote")
        if playEmoteBindable and playEmoteBindable:IsA("BindableFunction") then
            pcall(function()
                playEmoteBindable:Invoke(emoteName:lower())
            end)
        end
    end

    -- Se o track foi obtido e carregado com sucesso
    if track then
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = true
        track:Play()
        local currentSpd = HubState.Animation.Speed or 1
        pcall(function() track:AdjustSpeed(currentSpd) end)
        HubState.Animation.CurrentTrack = track
    end
end

function AnimationEngine.Play(emoteName)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
    local entry = DualEmoteDatabase[emoteName]
    if not entry then
        for name, data in pairs(DualEmoteDatabase) do
            if name:lower():find(emoteName:lower(), 1, true) then
                entry = data
                emoteName = name
                break
            end
        end
    end
    if not entry then
        for _, custom in ipairs(HubState.CustomDances) do
            if custom.Name:lower():find(emoteName:lower(), 1, true) then
                AnimationEngine.PlayRaw(custom.ID, custom.Name)
                return
            end
        end
    end
    if not entry then return end

    local targetId = isR15 and entry.R15 or entry.R6
    if not targetId and isR15 then
        targetId = entry.R15
    elseif not targetId and not isR15 then
        targetId = entry.R6 or entry.R15
    end

    if targetId then
        AnimationEngine.PlayRaw(targetId, emoteName)
    end
end

function AnimationEngine.SaveCustomDance(name, rawId)
    if not name or name:gsub("%s+", "") == "" then return false, "Nome inválido" end
    if not rawId or rawId:gsub("%s+", "") == "" then return false, "ID inválido" end

    local cleanId = tostring(rawId):gsub("%D", "")
    if cleanId == "" then return false, "ID numérico não encontrado" end

    for i = #HubState.CustomDances, 1, -1 do
        if HubState.CustomDances[i].Name:lower() == name:lower() then
            table.remove(HubState.CustomDances, i)
        end
    end

    table.insert(HubState.CustomDances, {
        Name = name,
        ID = cleanId
    })

    if writefile then
        pcall(function()
            writefile("gohub_custom_dances.json", HttpService:JSONEncode(HubState.CustomDances))
        end)
    end

    return true, cleanId
end

function AnimationEngine.DeleteCustomDance(nameOrIndex)
    if type(nameOrIndex) == "number" then
        if HubState.CustomDances[nameOrIndex] then
            table.remove(HubState.CustomDances, nameOrIndex)
            if writefile then
                pcall(function()
                    writefile("gohub_custom_dances.json", HttpService:JSONEncode(HubState.CustomDances))
                end)
            end
            return true
        end
    elseif type(nameOrIndex) == "string" then
        for i = #HubState.CustomDances, 1, -1 do
            if HubState.CustomDances[i].Name:lower() == nameOrIndex:lower() then
                table.remove(HubState.CustomDances, i)
                if writefile then
                    pcall(function()
                        writefile("gohub_custom_dances.json", HttpService:JSONEncode(HubState.CustomDances))
                    end)
                end
                return true
            end
        end
    end
    return false
end

function AnimationEngine.LoadSavedDances()
    pcall(function()
        if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile("gohub_custom_dances.json") then
            local raw = readfile("gohub_custom_dances.json")
            local data = HttpService:JSONDecode(raw)
            if type(data) == "table" then
                HubState.CustomDances = data
            end
        end
    end)
end
AnimationEngine.LoadSavedDances()

function AnimationEngine.GetRadialEmotes()
    local list = {}
    -- Prioridade 1: Danças salvas customizadas pelo usuário
    if HubState.CustomDances and #HubState.CustomDances > 0 then
        for _, d in ipairs(HubState.CustomDances) do
            if #list < 8 then
                table.insert(list, { Name = d.Name, ID = d.ID, IsCustom = true })
            end
        end
    end
    -- Prioridade 2: Preencher com os emotes mais famosos (Passinho do Jamal, IY, Floss, etc.)
    local fallbackEmotes = {
        { Name = "Jamal (Principal)", ID = "131086670591743" },
        { Name = "Passinho Fogo", ID = "101508054279219" },
        { Name = "Floss", ID = "10714340543" },
        { Name = "Breakdance (IY)", ID = "3333432454" },
        { Name = "Pop & Lock (IY)", ID = "4555808220" },
        { Name = "Hip Hop (IY)", ID = "4049037604" },
        { Name = "SpiderTree", ID = "3361426436" },
        { Name = "Spin Dance", ID = "3361481910" },
        { Name = "Hyped", ID = "3695333486" },
        { Name = "Dab", ID = "10714107111" }
    }
    for _, fb in ipairs(fallbackEmotes) do
        if #list < 8 then
            local alreadyIn = false
            for _, existing in ipairs(list) do
                if existing.ID == fb.ID then alreadyIn = true; break end
            end
            if not alreadyIn then
                table.insert(list, fb)
            end
        end
    end
    return list
end

-- ====================================================================
-- VISUAIS: X-RAY & ESP UNIVERSAL (CHAMS)
-- ====================================================================
local XRayEngine = {}
local SavedTransparencies = {}

function XRayEngine.Toggle(enabled)
    HubState.Visuals.XRayActive = enabled
    if enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character) then
                local isPlayerPart = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and obj:IsDescendantOf(p.Character) then isPlayerPart = true; break end
                end
                if not isPlayerPart and obj.Transparency < 0.5 then
                    SavedTransparencies[obj] = obj.Transparency
                    obj.Transparency = 0.55
                end
            end
        end
    else
        for obj, orig in pairs(SavedTransparencies) do
            if obj and obj.Parent then obj.Transparency = orig end
        end
        table.clear(SavedTransparencies)
    end
end

local UniversalESPHighlights = {}
local function UpdateUniversalESP(enabled)
    HubState.Visuals.UniversalESP = enabled
    if not enabled then
        DropLoop("UniversalESP_Loop")
        for _, hl in pairs(UniversalESPHighlights) do
            if hl and hl.Parent then hl:Destroy() end
        end
        table.clear(UniversalESPHighlights)
        return
    end

    RegisterLoop("UniversalESP_Loop", RunService.Heartbeat:Connect(function()
        if not HubState.Visuals.UniversalESP then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hl = UniversalESPHighlights[p]
                if not hl or not hl.Parent then
                    hl = Instance.new("Highlight")
                    hl.Name = "Waifu_Universal_ESP"
                    hl.FillColor = HubState.Theme.Accent
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.4
                    hl.Adornee = p.Character
                    hl.Parent = p.Character
                    UniversalESPHighlights[p] = hl
                end
            end
        end
    end))
end

-- ====================================================================
-- MURDER MYSTERY 2 SUITE (ROLES, COINS, AUTO-GUN, HITBOXES)
-- ====================================================================
local MM2Engine = {}
local MM2RoleFolder = Instance.new("Folder")
MM2RoleFolder.Name = "Waifu_MM2_Roles"
pcall(function() MM2RoleFolder.Parent = GuiRoot end)

local MM2CoinFolder = Instance.new("Folder")
MM2CoinFolder.Name = "Waifu_MM2_Coins"
pcall(function() MM2CoinFolder.Parent = GuiRoot end)

local MM2HitboxFolder = Instance.new("Folder")
MM2HitboxFolder.Name = "Waifu_MM2_Hitboxes"
pcall(function() MM2HitboxFolder.Parent = GuiRoot end)

local function DetectRole(p)
    if not p or not p.Character then return nil end
    local hasKnife, hasGun = false, false
    local function checkItem(item)
        if item:IsA("Tool") then
            local n = item.Name:lower()
            if n == "knife" or n:find("scythe") or n:find("pitchfork") or n:find("blade") then hasKnife = true end
            if n == "gun" or n == "revolver" or n:find("blaster") then hasGun = true end
        end
    end
    for _, item in ipairs(p.Character:GetChildren()) do checkItem(item) end
    local bp = p:FindFirstChild("Backpack")
    if bp then for _, item in ipairs(bp:GetChildren()) do checkItem(item) end end

    if hasKnife then return "MURDER", HubState.Theme.Murderer end
    if hasGun then return "SHERIFE", HubState.Theme.Sheriff end
    return nil
end

function MM2Engine.ToggleRoleESP(enabled)
    HubState.MM2.RoleESP = enabled
    if not enabled then
        DropLoop("MM2_RoleLoop")
        MM2RoleFolder:ClearAllChildren()
        return
    end

    RegisterLoop("MM2_RoleLoop", RunService.Heartbeat:Connect(function()
        if not HubState.MM2.RoleESP then return end
        MM2RoleFolder:ClearAllChildren()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local role, color = DetectRole(p)
                if role then
                    local hl = Instance.new("Highlight", MM2RoleFolder)
                    hl.Adornee = p.Character
                    hl.FillColor = color
                    hl.OutlineColor = color
                    hl.FillTransparency = 0.5

                    local bgui = Instance.new("BillboardGui", MM2RoleFolder)
                    bgui.Adornee = p.Character.Head
                    bgui.Size = UDim2.new(0, 100, 0, 40)
                    bgui.StudsOffset = Vector3.new(0, 2.5, 0)
                    bgui.AlwaysOnTop = true

                    local txt = Instance.new("TextLabel", bgui)
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.BackgroundTransparency = 1
                    txt.TextColor3 = color
                    txt.Font = Enum.Font.GothamBold
                    txt.TextSize = 14
                    txt.Text = role
                end
            end
        end
    end))
end

function MM2Engine.ToggleCoinESP(enabled)
    HubState.MM2.CoinESP = enabled
    if not enabled then
        DropLoop("MM2_CoinLoop")
        MM2CoinFolder:ClearAllChildren()
        return
    end

    RegisterLoop("MM2_CoinLoop", RunService.Heartbeat:Connect(function()
        if not HubState.MM2.CoinESP then return end
        MM2CoinFolder:ClearAllChildren()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "Coin_Server" or obj.Name == "Coin" or obj.Name == "CoinContainer") then
                local hl = Instance.new("Highlight", MM2CoinFolder)
                hl.Adornee = obj
                hl.FillColor = Color3.fromRGB(255, 215, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.3
            end
        end
    end))
end

function MM2Engine.ToggleAutoGrabGun(enabled)
    HubState.MM2.AutoGrabGun = enabled
    if not enabled then
        DropLoop("MM2_AutoGunLoop")
        return
    end

    RegisterLoop("MM2_AutoGunLoop", RunService.Heartbeat:Connect(function()
        if not HubState.MM2.AutoGrabGun then return end
        local gunDrop = Workspace:FindFirstChild("GunDrop")
        if gunDrop and gunDrop:IsA("BasePart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = gunDrop.CFrame
        end
    end))
end

function MM2Engine.ToggleHitboxes(enabled)
    HubState.MM2.Hitboxes = enabled
    if not enabled then
        DropLoop("MM2_HitboxLoop")
        MM2HitboxFolder:ClearAllChildren()
        return
    end

    RegisterLoop("MM2_HitboxLoop", RunService.Heartbeat:Connect(function()
        if not HubState.MM2.Hitboxes then return end
        MM2HitboxFolder:ClearAllChildren()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local box = Instance.new("BoxHandleAdornment", MM2HitboxFolder)
                box.Adornee = p.Character.HumanoidRootPart
                box.Size = Vector3.new(3.5, 4.5, 3.5)
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.Transparency = 0.6
                box.AlwaysOnTop = true
            end
        end
    end))
end

-- ====================================================================
-- COMBATE & MIRA (AIMBOT FOV RAYCAST)
-- ====================================================================
-- ====================================================================
-- SKIN & MORPH SUITE (REMOTE SCANNER, REANIMATION RIG & VISUAL CLONER)
-- ====================================================================
local SkinEngine = {}

-- 1. Detecção de Remotas do Servidor para Replicação Global (Everyone Sees)
function SkinEngine.ScanAndFireRemote(targetUserId, targetOutfitId)
    local found = false
    local remotesToTest = {}
    
    local function checkObj(obj)
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("cloth") or n:find("outfit") or n:find("avatar") or n:find("morph") 
               or n:find("wear") or n:find("char") or n:find("skin") or n:find("costume") 
               or n:find("dress") or n:find("bundle") or n:find("apply") then
                table.insert(remotesToTest, obj)
            end
        end
    end

    pcall(function()
        for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            checkObj(obj)
        end
    end)
    pcall(function()
        for _, obj in ipairs(game:GetService("JointsService"):GetDescendants()) do
            checkObj(obj)
        end
    end)

    for _, rem in ipairs(remotesToTest) do
        local ok = pcall(function()
            if rem:IsA("RemoteEvent") then
                if targetOutfitId then
                    rem:FireServer(targetOutfitId)
                    rem:FireServer("Outfit", targetOutfitId)
                    rem:FireServer("Wear", targetOutfitId)
                end
                if targetUserId then
                    rem:FireServer(targetUserId)
                    rem:FireServer("Character", targetUserId)
                    rem:FireServer("Morph", targetUserId)
                end
            elseif rem:IsA("RemoteFunction") then
                if targetOutfitId then
                    task.spawn(function() pcall(function() rem:InvokeServer(targetOutfitId) end) end)
                end
                if targetUserId then
                    task.spawn(function() pcall(function() rem:InvokeServer(targetUserId) end) end)
                end
            end
        end)
        if ok then found = true end
    end

    -- Testar Admin Suites (Adonis, HD Admin, Kohl's)
    pcall(function()
        local chatService = game:GetService("TextChatService")
        local legacyChat = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        local cmdStr = ";char me " .. tostring(targetUserId or targetOutfitId)
        
        if legacyChat and legacyChat:FindFirstChild("SayMessageRequest") then
            legacyChat.SayMessageRequest:FireServer(cmdStr, "All")
            legacyChat.SayMessageRequest:FireServer(":char me " .. tostring(targetUserId or targetOutfitId), "All")
        end
        if chatService and chatService.ChatInputBarConfiguration then
            local channel = chatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:SendAsync(cmdStr)
                channel:SendAsync(":char me " .. tostring(targetUserId or targetOutfitId))
            end
        end
    end)

    return found
end

-- 2. Clonador de Aparência (HumanoidDescription / Morph Local e Servidor)
function SkinEngine.ClonePlayerSkin(targetPlayer)
    if not targetPlayer then return false, "Jogador não especificado" end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false, "Humanoid não encontrado" end

    -- Salvar descrição original caso queira resetar
    if not HubState.Skin.OriginalDesc then
        pcall(function()
            HubState.Skin.OriginalDesc = hum:GetAppliedDescription()
        end)
    end

    local targetUserId = targetPlayer.UserId
    
    -- Tentar disparo de remotas do jogo primeiro (Everyone Sees se disponível)
    SkinEngine.ScanAndFireRemote(targetUserId, nil)

    -- Aplicar descrição completa no cliente
    local successDesc, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(targetUserId)
    end)

    if successDesc and desc then
        pcall(function()
            hum:ApplyDescription(desc)
        end)
        return true, "Skin clonada com sucesso de @" .. targetPlayer.Name
    end

    -- Fallback manual de roupas/acessórios caso GetHumanoidDescription falhe
    local targetChar = targetPlayer.Character
    if targetChar then
        pcall(function()
            local targetShirt = targetChar:FindFirstChildOfClass("Shirt")
            local targetPants = targetChar:FindFirstChildOfClass("Pants")
            local targetBodyColors = targetChar:FindFirstChildOfClass("BodyColors")

            local myShirt = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
            local myPants = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)

            if targetShirt then myShirt.ShirtTemplate = targetShirt.ShirtTemplate end
            if targetPants then myPants.PantsTemplate = targetPants.PantsTemplate end
            if targetBodyColors then
                local myBC = char:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", char)
                myBC.HeadColor3 = targetBodyColors.HeadColor3
                myBC.TorsoColor3 = targetBodyColors.TorsoColor3
                myBC.LeftArmColor3 = targetBodyColors.LeftArmColor3
                myBC.RightArmColor3 = targetBodyColors.RightArmColor3
                myBC.LeftLegColor3 = targetBodyColors.LeftLegColor3
                myBC.RightLegColor3 = targetBodyColors.RightLegColor3
            end
        end)
        return true, "Roupas clonadas diretamente de @" .. targetPlayer.Name
    end

    return false, "Falha ao obter dados do personagem"
end

-- 3. Aplicar Skin por User ID ou Outfit ID
function SkinEngine.ApplyByUserId(userId)
    local numId = tonumber(userId)
    if not numId then return false, "ID inválido" end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false, "Humanoid não encontrado" end

    if not HubState.Skin.OriginalDesc then
        pcall(function()
            HubState.Skin.OriginalDesc = hum:GetAppliedDescription()
        end)
    end

    -- Tentativa de disparo em remotas do servidor
    SkinEngine.ScanAndFireRemote(numId, nil)

    local success, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(numId)
    end)
    if success and desc then
        pcall(function()
            hum:ApplyDescription(desc)
        end)
        return true, "Skin aplicada para o ID: " .. tostring(numId)
    else
        return false, "Não foi possível carregar o ID do avatar"
    end
end

-- 4. Headless Horseman (Cabeça Invisível)
function SkinEngine.ToggleHeadless(enabled)
    HubState.Skin.HeadlessActive = enabled
    local char = LocalPlayer.Character
    if not char then return end

    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = enabled and 1 or 0
        local face = head:FindFirstChildOfClass("Decal")
        if face then face.Transparency = enabled and 1 or 0 end
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("SpecialMesh") then
                if enabled then
                    child.Scale = Vector3.new(0.001, 0.001, 0.001)
                else
                    child.Scale = Vector3.new(1.25, 1.25, 1.25)
                end
            end
        end
    end
end

-- 5. Korblox Deathspeaker (Perna Direita Korblox)
function SkinEngine.ToggleKorblox(enabled)
    HubState.Skin.KorbloxActive = enabled
    local char = LocalPlayer.Character
    if not char then return end

    local rLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
    local rLower = char:FindFirstChild("RightLowerLeg")
    local rFoot = char:FindFirstChild("RightFoot")

    if enabled then
        if rLeg and rLeg:IsA("BasePart") then rLeg.Transparency = 1 end
        if rLower and rLower:IsA("BasePart") then rLower.Transparency = 1 end
        if rFoot and rFoot:IsA("BasePart") then rFoot.Transparency = 1 end

        -- Criar Mesh da Perna do Korblox Deathspeaker
        local attachPart = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg") or char:FindFirstChild("HumanoidRootPart")
        if attachPart and not char:FindFirstChild("KorbloxLegMesh") then
            local korbloxLeg = Instance.new("Part")
            korbloxLeg.Name = "KorbloxLegMesh"
            korbloxLeg.CanCollide = false
            korbloxLeg.Massless = true
            korbloxLeg.CFrame = attachPart.CFrame
            korbloxLeg.Parent = char

            local specialMesh = Instance.new("SpecialMesh", korbloxLeg)
            specialMesh.MeshId = "rbxassetid://902942093"
            specialMesh.TextureId = "rbxassetid://902843398"
            specialMesh.Scale = Vector3.new(1, 1, 1)

            local weld = Instance.new("WeldConstraint", korbloxLeg)
            weld.Part0 = korbloxLeg
            weld.Part1 = attachPart
        end
    else
        if rLeg and rLeg:IsA("BasePart") then rLeg.Transparency = 0 end
        if rLower and rLower:IsA("BasePart") then rLower.Transparency = 0 end
        if rFoot and rFoot:IsA("BasePart") then rFoot.Transparency = 0 end

        local existing = char:FindFirstChild("KorbloxLegMesh")
        if existing then existing:Destroy() end
    end
end

-- 6. Resetar para Avatar Original
function SkinEngine.ResetAvatar()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and HubState.Skin.OriginalDesc then
        pcall(function()
            hum:ApplyDescription(HubState.Skin.OriginalDesc)
        end)
    end
    SkinEngine.ToggleHeadless(false)
    SkinEngine.ToggleKorblox(false)
end

-- 7. Hat Reanimation Rig (Replicação de Física Netless FE)
local HatReanimActive = false
function SkinEngine.ToggleHatReanim(enabled)
    HatReanimActive = enabled
    local char = LocalPlayer.Character
    if not char then return end

    if not enabled then
        DropLoop("HatReanim_Physics")
        return
    end

    -- Configuração de física com network ownership para chapéus
    pcall(function()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        RegisterLoop("HatReanim_Physics", RunService.Heartbeat:Connect(function()
            if not HatReanimActive or not char or not char.Parent then
                DropLoop("HatReanim_Physics")
                return
            end
            for _, acc in ipairs(char:GetChildren()) do
                if acc:IsA("Accessory") then
                    local handle = acc:FindFirstChild("Handle")
                    if handle and handle:IsA("BasePart") then
                        handle.CanCollide = false
                        -- Manter autoridade de velocidade para replicação de rede contínua
                        pcall(function()
                            handle.Velocity = Vector3.new(0, 25, 0)
                        end)
                    end
                end
            end
        end))
    end)
end

local CombatEngine = {}

local function RaycastCheck(part, targetChar)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, dir, params)
    if result then return result.Instance:IsDescendantOf(targetChar) end
    return true
end

function CombatEngine.GetBestTarget()
    local best = nil
    local minDist = HubState.Combat.FOV
    local mouseLoc = Vector2.new(Mouse.X, Mouse.Y)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local isTeammate = HubState.Combat.TeamCheck and (p.Team == LocalPlayer.Team)
            if not isTeammate then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local part = p.Character:FindFirstChild(HubState.Combat.TargetPart)
                if hum and hum.Health > 0 and part then
                    local sPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local sPos = Vector2.new(sPoint.X, sPoint.Y)
                        local dist = (sPos - mouseLoc).Magnitude
                        if dist < minDist then
                            if not HubState.Combat.VisibilityCheck or RaycastCheck(part, p.Character) then
                                minDist = dist
                                best = part
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

RegisterLoop("Aimbot_Render", RunService.RenderStepped:Connect(function()
    if not HubState.Combat.AimbotActive then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local target = CombatEngine.GetBestTarget()
    if target then
        local camCF = Camera.CFrame
        local targetCF = CFrame.new(camCF.Position, target.Position)
        Camera.CFrame = camCF:Lerp(targetCF, math.clamp(HubState.Combat.Smoothness, 0.05, 1))
    end
end))

-- ====================================================================
-- FRONT-END PREMIUM ORIGINAL INTACTO (SIDEBAR, WAIFU, SLIDERS, DRAGGABLE)
-- ====================================================================
-- Limpeza segura de instâncias anteriores em todos os containers
local oldNames = {"GoHub_V12_Definitive", "WaifuHub_V10_Definitive", "WaifuHub_V8_Definitive", "WaifuHub_V8", "WaifuHub"}
for _, oldName in ipairs(oldNames) do
    pcall(function() if GuiRoot and GuiRoot:FindFirstChild(oldName) then GuiRoot[oldName]:Destroy() end end)
    pcall(function() if game:GetService("CoreGui"):FindFirstChild(oldName) then game:GetService("CoreGui")[oldName]:Destroy() end end)
    pcall(function() if LocalPlayer:FindFirstChildOfClass("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(oldName) then LocalPlayer.PlayerGui[oldName]:Destroy() end end)
end

local MainScreen = Instance.new("ScreenGui")
MainScreen.Name = "GoHub_V12_Definitive"
MainScreen.ResetOnSpawn = false
MainScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(MainScreen)
    end
end)

MainScreen.Parent = GuiRoot

-- FOV Circle
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Size = UDim2.new(0, HubState.Combat.FOV * 2, 0, HubState.Combat.FOV * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = HubState.Combat.FOVCircleVisible and HubState.Combat.AimbotActive
FOVCircle.Parent = MainScreen

Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)
local FOVStroke = Instance.new("UIStroke", FOVCircle)
FOVStroke.Color = HubState.Theme.Accent
FOVStroke.Thickness = 1.5

RegisterLoop("UI_FOVFollow", RunService.RenderStepped:Connect(function()
    if FOVCircle.Visible then FOVCircle.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y) end
end))

-- Janela Principal
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 720, 0, 450)
MainWindow.Position = UDim2.new(0.5, -360, 0.5, -225)
MainWindow.BackgroundColor3 = HubState.Theme.Background
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = MainScreen

Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 10)
local WindowStroke = Instance.new("UIStroke", MainWindow)
WindowStroke.Color = HubState.Theme.Border
WindowStroke.Thickness = 1.8

-- Animação de Entrada Segura
MainWindow.Size = UDim2.new(0, 720, 0, 450)
MainWindow.Position = UDim2.new(0.5, -360, 0.5, -225)
MainWindow.Visible = true

pcall(function()
    MainWindow.Size = UDim2.new(0, 0, 0, 0)
    MainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(MainWindow, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 720, 0, 450),
        Position = UDim2.new(0.5, -360, 0.5, -225)
    }):Play()
end)

task.delay(0.5, function()
    if not HubState.WindowMinimized and MainWindow and MainWindow.Parent then
        MainWindow.Size = UDim2.new(0, 720, 0, 450)
        MainWindow.Position = UDim2.new(0.5, -360, 0.5, -225)
        MainWindow.Visible = true
    end
end)

-- Draggable Fluido
local isDragging, dragInput, dragStart, startPos
MainWindow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then isDragging = false end
        end)
    end
end)

MainWindow.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and isDragging then
        local delta = input.Position - dragStart
        TweenService:Create(MainWindow, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        }):Play()
    end
end)

-- Botão de Minimizar ("—")
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeBtn"
MinimizeButton.Size = UDim2.new(0, 28, 0, 28)
MinimizeButton.Position = UDim2.new(1, -70, 0, 10)
MinimizeButton.BackgroundColor3 = HubState.Theme.Card
MinimizeButton.TextColor3 = HubState.Theme.AccentGlow
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 14
MinimizeButton.Text = "—"
MinimizeButton.ZIndex = 5
MinimizeButton.Parent = MainWindow

Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 6)
local MinStroke = Instance.new("UIStroke", MinimizeButton)
MinStroke.Color = HubState.Theme.Accent
MinStroke.Thickness = 1

MinimizeButton.MouseEnter:Connect(function()
    TweenService:Create(MinimizeButton, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Accent, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
end)

MinimizeButton.MouseLeave:Connect(function()
    TweenService:Create(MinimizeButton, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Card, TextColor3 = HubState.Theme.AccentGlow }):Play()
end)

-- Botão de Fechar ("✕")
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseBtn"
CloseButton.Size = UDim2.new(0, 28, 0, 28)
CloseButton.Position = UDim2.new(1, -38, 0, 10)
CloseButton.BackgroundColor3 = HubState.Theme.Card
CloseButton.TextColor3 = HubState.Theme.Close
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.Text = "✕"
CloseButton.ZIndex = 5
CloseButton.Parent = MainWindow

Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 6)
local CloseStroke = Instance.new("UIStroke", CloseButton)
CloseStroke.Color = HubState.Theme.Close
CloseStroke.Thickness = 1

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Close, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Card, TextColor3 = HubState.Theme.Close }):Play()
end)

-- Floating Badge Compacto para Restaurar o Hub Minimizado
local FloatingBadge = Instance.new("Frame")
FloatingBadge.Name = "GoHubFloatingBadge"
FloatingBadge.Size = UDim2.new(0, 125, 0, 36)
FloatingBadge.Position = UDim2.new(0.5, -62, 0, 18)
FloatingBadge.BackgroundColor3 = HubState.Theme.Background
FloatingBadge.BorderSizePixel = 0
FloatingBadge.Visible = false
FloatingBadge.ZIndex = 100
FloatingBadge.Parent = MainScreen

Instance.new("UICorner", FloatingBadge).CornerRadius = UDim.new(1, 0)
local BadgeStroke = Instance.new("UIStroke", FloatingBadge)
BadgeStroke.Color = HubState.Theme.AccentGlow
BadgeStroke.Thickness = 1.5

local BadgeIcon = Instance.new("ImageLabel")
BadgeIcon.Size = UDim2.new(0, 26, 0, 26)
BadgeIcon.Position = UDim2.new(0, 5, 0.5, -13)
BadgeIcon.BackgroundColor3 = HubState.Theme.Card
BadgeIcon.Image = HubState.Assets.WaifuImageId
BadgeIcon.ScaleType = Enum.ScaleType.Fit
BadgeIcon.ZIndex = 101
BadgeIcon.Parent = FloatingBadge
Instance.new("UICorner", BadgeIcon).CornerRadius = UDim.new(1, 0)

local BadgeText = Instance.new("TextLabel")
BadgeText.Size = UDim2.new(1, -38, 1, 0)
BadgeText.Position = UDim2.new(0, 36, 0, 0)
BadgeText.BackgroundTransparency = 1
BadgeText.Font = Enum.Font.GothamBold
BadgeText.Text = "GOHUB  ▲"
BadgeText.TextColor3 = HubState.Theme.Text
BadgeText.TextSize = 11
BadgeText.TextXAlignment = Enum.TextXAlignment.Left
BadgeText.ZIndex = 101
BadgeText.Parent = FloatingBadge

local BadgeClick = Instance.new("TextButton")
BadgeClick.Size = UDim2.new(1, 0, 1, 0)
BadgeClick.BackgroundTransparency = 1
BadgeClick.Text = ""
BadgeClick.ZIndex = 102
BadgeClick.Parent = FloatingBadge

-- Arrastar o Floating Badge
local isBadgeDragging, badgeDragInput, badgeDragStart, badgeStartPos
FloatingBadge.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isBadgeDragging = true
        badgeDragStart = input.Position
        badgeStartPos = FloatingBadge.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then isBadgeDragging = false end
        end)
    end
end)

FloatingBadge.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then badgeDragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == badgeDragInput and isBadgeDragging then
        local delta = input.Position - badgeDragStart
        TweenService:Create(FloatingBadge, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(badgeStartPos.X.Scale, badgeStartPos.X.Offset + delta.X, badgeStartPos.Y.Scale, badgeStartPos.Y.Offset + delta.Y)
        }):Play()
    end
end)

local function SetWindowMinimized(minimized)
    HubState.WindowMinimized = minimized
    if minimized then
        TweenService:Create(MainWindow, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.delay(0.25, function()
            if HubState.WindowMinimized then
                MainWindow.Visible = false
                FloatingBadge.Visible = true
                FloatingBadge.Size = UDim2.new(0, 0, 0, 0)
                TweenService:Create(FloatingBadge, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 125, 0, 36)
                }):Play()
            end
        end)
    else
        FloatingBadge.Visible = false
        MainWindow.Visible = true
        TweenService:Create(MainWindow, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 720, 0, 450),
            Position = UDim2.new(0.5, -360, 0.5, -225)
        }):Play()
    end
end

MinimizeButton.MouseButton1Click:Connect(function()
    SetWindowMinimized(true)
end)

BadgeClick.MouseButton1Click:Connect(function()
    SetWindowMinimized(false)
end)

-- ====================================================================
-- RADIAL EMOTE WHEEL MENU (ROBLOX NATIVE CIRCULAR WHEEL — TECLA 'C')
-- ====================================================================
local RadialBackdrop = Instance.new("Frame")
RadialBackdrop.Name = "GoHubRadialBackdrop"
RadialBackdrop.Size = UDim2.new(1, 0, 1, 0)
RadialBackdrop.Position = UDim2.new(0, 0, 0, 0)
RadialBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
RadialBackdrop.BackgroundTransparency = 1
RadialBackdrop.Visible = false
RadialBackdrop.ZIndex = 200
RadialBackdrop.Parent = MainScreen

local RadialWheel = Instance.new("Frame")
RadialWheel.Name = "RadialWheel"
RadialWheel.Size = UDim2.new(0, 0, 0, 0)
RadialWheel.Position = UDim2.new(0.5, 0, 0.5, 0)
RadialWheel.AnchorPoint = Vector2.new(0.5, 0.5)
RadialWheel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
RadialWheel.BackgroundTransparency = 0.15
RadialWheel.BorderSizePixel = 0
RadialWheel.ZIndex = 201
RadialWheel.Parent = RadialBackdrop

Instance.new("UICorner", RadialWheel).CornerRadius = UDim.new(1, 0)
local WheelStroke = Instance.new("UIStroke", RadialWheel)
WheelStroke.Color = HubState.Theme.AccentGlow
WheelStroke.Thickness = 2.5
WheelStroke.Transparency = 0.2

-- Linhas Divisórias dos 8 Setores
for i = 1, 8 do
    local angleDeg = (i - 1) * 45
    local divider = Instance.new("Frame")
    divider.Name = "Div_" .. i
    divider.Size = UDim2.new(0, 1, 0.5, -35)
    divider.AnchorPoint = Vector2.new(0.5, 1)
    divider.Position = UDim2.new(0.5, 0, 0.5, 0)
    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    divider.BackgroundTransparency = 0.65
    divider.BorderSizePixel = 0
    divider.Rotation = angleDeg
    divider.ZIndex = 202
    divider.Parent = RadialWheel
end

-- Centro Escuro do Menu Circular (Hub central)
local CenterCircle = Instance.new("Frame")
CenterCircle.Name = "CenterCircle"
CenterCircle.Size = UDim2.new(0, 120, 0, 120)
CenterCircle.AnchorPoint = Vector2.new(0.5, 0.5)
CenterCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
CenterCircle.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
CenterCircle.BackgroundTransparency = 0.05
CenterCircle.BorderSizePixel = 0
CenterCircle.ZIndex = 203
CenterCircle.Parent = RadialWheel

Instance.new("UICorner", CenterCircle).CornerRadius = UDim.new(1, 0)
local CenterStroke = Instance.new("UIStroke", CenterCircle)
CenterStroke.Color = HubState.Theme.Accent
CenterStroke.Thickness = 1.8

local CenterLogo = Instance.new("ImageLabel")
CenterLogo.Size = UDim2.new(0, 36, 0, 36)
CenterLogo.AnchorPoint = Vector2.new(0.5, 0.5)
CenterLogo.Position = UDim2.new(0.5, 0, 0.32, 0)
CenterLogo.BackgroundColor3 = HubState.Theme.Card
CenterLogo.Image = HubState.Assets.WaifuImageId
CenterLogo.ScaleType = Enum.ScaleType.Fit
CenterLogo.ZIndex = 204
CenterLogo.Parent = CenterCircle
Instance.new("UICorner", CenterLogo).CornerRadius = UDim.new(1, 0)

local CenterTitle = Instance.new("TextLabel")
CenterTitle.Size = UDim2.new(1, -10, 0, 16)
CenterTitle.AnchorPoint = Vector2.new(0.5, 0.5)
CenterTitle.Position = UDim2.new(0.5, 0, 0.58, 0)
CenterTitle.BackgroundTransparency = 1
CenterTitle.Font = Enum.Font.GothamBold
CenterTitle.Text = "GOHUB EMOTES"
CenterTitle.TextColor3 = HubState.Theme.AccentGlow
CenterTitle.TextSize = 10
CenterTitle.ZIndex = 204
CenterTitle.Parent = CenterCircle

local CenterInfo = Instance.new("TextLabel")
CenterInfo.Size = UDim2.new(1, -12, 0, 24)
CenterInfo.AnchorPoint = Vector2.new(0.5, 0.5)
CenterInfo.Position = UDim2.new(0.5, 0, 0.78, 0)
CenterInfo.BackgroundTransparency = 1
CenterInfo.Font = Enum.Font.Gotham
CenterInfo.Text = "[C] Fechar  •  [X] Parar"
CenterInfo.TextColor3 = HubState.Theme.TextDim
CenterInfo.TextSize = 9
CenterInfo.ZIndex = 204
CenterInfo.Parent = CenterCircle

-- Container das 8 fatias de dança
local SlotsContainer = Instance.new("Folder", RadialWheel)
SlotsContainer.Name = "SlotsContainer"

local SlotButtons = {}
local CurrentRadialEmotes = {}

local function BuildRadialSlots()
    SlotsContainer:ClearAllChildren()
    table.clear(SlotButtons)
    CurrentRadialEmotes = AnimationEngine.GetRadialEmotes()

    local radius = 110 -- Raio para centralizar os itens de texto/número
    for i = 1, 8 do
        local emoteData = CurrentRadialEmotes[i]
        local angleDeg = (i - 1) * 45 - 90 -- Slot 1 no topo (-90°), horário
        local angleRad = math.rad(angleDeg)
        local cosA, sinA = math.cos(angleRad), math.sin(angleRad)

        local slotBtn = Instance.new("TextButton")
        slotBtn.Name = "Slot_" .. i
        slotBtn.Size = UDim2.new(0, 84, 0, 48)
        slotBtn.AnchorPoint = Vector2.new(0.5, 0.5)
        slotBtn.Position = UDim2.new(0.5, cosA * radius, 0.5, sinA * radius)
        slotBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        slotBtn.BackgroundTransparency = 0.4
        slotBtn.Text = ""
        slotBtn.AutoButtonColor = false
        slotBtn.ZIndex = 205
        slotBtn.Parent = SlotsContainer

        Instance.new("UICorner", slotBtn).CornerRadius = UDim.new(0, 8)
        local slotStroke = Instance.new("UIStroke", slotBtn)
        slotStroke.Color = Color3.fromRGB(60, 60, 80)
        slotStroke.Thickness = 1

        local numBadge = Instance.new("TextLabel")
        numBadge.Size = UDim2.new(0, 18, 0, 18)
        numBadge.Position = UDim2.new(0, 4, 0, 4)
        numBadge.BackgroundColor3 = HubState.Theme.Accent
        numBadge.Font = Enum.Font.GothamBold
        numBadge.Text = tostring(i)
        numBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        numBadge.TextSize = 10
        numBadge.ZIndex = 206
        numBadge.Parent = slotBtn
        Instance.new("UICorner", numBadge).CornerRadius = UDim.new(1, 0)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -24, 1, -8)
        label.Position = UDim2.new(0, 22, 0, 4)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamSemibold
        label.Text = emoteData and emoteData.Name or "(Vazio)"
        label.TextColor3 = emoteData and HubState.Theme.Text or HubState.Theme.TextDim
        label.TextSize = 10
        label.TextWrapped = true
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.ZIndex = 206
        label.Parent = slotBtn

        slotBtn.MouseEnter:Connect(function()
            TweenService:Create(slotBtn, TweenInfo.new(0.18), { BackgroundColor3 = HubState.Theme.Accent, BackgroundTransparency = 0.1 }):Play()
            TweenService:Create(slotStroke, TweenInfo.new(0.18), { Color = Color3.fromRGB(255, 255, 255) }):Play()
            TweenService:Create(label, TweenInfo.new(0.18), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
        end)

        slotBtn.MouseLeave:Connect(function()
            TweenService:Create(slotBtn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(22, 22, 32), BackgroundTransparency = 0.4 }):Play()
            TweenService:Create(slotStroke, TweenInfo.new(0.18), { Color = Color3.fromRGB(60, 60, 80) }):Play()
            TweenService:Create(label, TweenInfo.new(0.18), { TextColor3 = emoteData and HubState.Theme.Text or HubState.Theme.TextDim }):Play()
        end)

        slotBtn.MouseButton1Click:Connect(function()
            if emoteData and emoteData.ID then
                AnimationEngine.PlayRaw(emoteData.ID, emoteData.Name)
            end
            ToggleRadialMenu(false)
        end)

        SlotButtons[i] = { Button = slotBtn, Emote = emoteData }
    end
end

local function ToggleRadialMenu(forceState)
    local state = (forceState ~= nil) and forceState or not HubState.Radial.Visible
    HubState.Radial.Visible = state

    if state then
        BuildRadialSlots()
        RadialBackdrop.Visible = true
        RadialWheel.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(RadialBackdrop, TweenInfo.new(0.22), { BackgroundTransparency = 0.4 }):Play()
        TweenService:Create(RadialWheel, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 350, 0, 350)
        }):Play()
    else
        TweenService:Create(RadialBackdrop, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        local closeTween = TweenService:Create(RadialWheel, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        task.delay(0.22, function()
            if not HubState.Radial.Visible then
                RadialBackdrop.Visible = false
            end
        end)
    end
end

-- Fechar ao clicar fora da roda circular
RadialBackdrop.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = Vector2.new(input.Position.X, input.Position.Y)
        local centerPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local dist = (mousePos - centerPos).Magnitude
        if dist > 175 then
            ToggleRadialMenu(false)
        end
    end
end)

-- Hotkey Global: Tecla 'C' para Menu Circular, Tecla 'X' para Parar Dança
RegisterLoop("UI_Radial_Dance_Hotkeys", UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.C then
        ToggleRadialMenu()
    elseif input.KeyCode == Enum.KeyCode.X then
        AnimationEngine.Stop()
    end
end))

-- Atalhos de teclado numérico (1 a 8) quando o menu circular estiver aberto
RegisterLoop("UI_Radial_Number_Hotkeys", UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not HubState.Radial.Visible then return end
    local numKeys = {
        [Enum.KeyCode.One] = 1, [Enum.KeyCode.KeypadOne] = 1,
        [Enum.KeyCode.Two] = 2, [Enum.KeyCode.KeypadTwo] = 2,
        [Enum.KeyCode.Three] = 3, [Enum.KeyCode.KeypadThree] = 3,
        [Enum.KeyCode.Four] = 4, [Enum.KeyCode.KeypadFour] = 4,
        [Enum.KeyCode.Five] = 5, [Enum.KeyCode.KeypadFive] = 5,
        [Enum.KeyCode.Six] = 6, [Enum.KeyCode.KeypadSix] = 6,
        [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.KeypadSeven] = 7,
        [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.KeypadEight] = 8
    }
    local slotNum = numKeys[input.KeyCode]
    if slotNum and CurrentRadialEmotes[slotNum] then
        local em = CurrentRadialEmotes[slotNum]
        if em and em.ID then
            AnimationEngine.PlayRaw(em.ID, em.Name)
        end
        ToggleRadialMenu(false)
    end
end))

-- Atalho de teclado para Minimizar/Restaurar (RightControl ou LeftAlt)
RegisterLoop("UI_Minimize_Hotkey", UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.LeftAlt) then
        SetWindowMinimized(not HubState.WindowMinimized)
    end
end))

CloseButton.MouseButton1Click:Connect(function()
    MovementEngine.SetFlight(false)
    MovementEngine.SetNoclip(false)
    MovementEngine.SetInfiniteJump(false)
    MovementEngine.SetClickTP(false)
    FlingEngine.ToggleFling(false)
    FlingEngine.LoopFling(nil)
    AnimationEngine.Stop()
    CharEngine.ToggleAntiSit(false)
    CharEngine.ToggleSpinBot(false)
    XRayEngine.Toggle(false)
    UpdateUniversalESP(false)
    LightingEngine.ToggleFullbright(false)
    LightingEngine.ToggleNoFog(false)
    MM2Engine.ToggleRoleESP(false)
    MM2Engine.ToggleCoinESP(false)
    MM2Engine.ToggleAutoGrabGun(false)
    MM2Engine.ToggleHitboxes(false)

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end

    for _, conn in pairs(ConnectionPool) do conn:Disconnect() end
    table.clear(ConnectionPool)

    MM2RoleFolder:Destroy()
    MM2CoinFolder:Destroy()
    MM2HitboxFolder:Destroy()
    FloatingBadge:Destroy()
    RadialBackdrop:Destroy()
    MainScreen:Destroy()
end)

-- Barra Lateral (Sidebar)
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 200, 1, 0)
Sidebar.BackgroundColor3 = HubState.Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow

Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local WaifuAvatar = Instance.new("ImageLabel")
WaifuAvatar.Name = "WaifuAvatar"
WaifuAvatar.Size = UDim2.new(0, 54, 0, 54)
WaifuAvatar.Position = UDim2.new(0, 14, 0, 14)
WaifuAvatar.BackgroundColor3 = HubState.Theme.Card
WaifuAvatar.Image = HubState.Assets.WaifuImageId
WaifuAvatar.ScaleType = Enum.ScaleType.Fit
WaifuAvatar.Parent = Sidebar

Instance.new("UICorner", WaifuAvatar).CornerRadius = UDim.new(1, 0)
local AvatarStroke = Instance.new("UIStroke", WaifuAvatar)
AvatarStroke.Color = HubState.Theme.AccentGlow
AvatarStroke.Thickness = 1.5

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Position = UDim2.new(0, 78, 0, 16)
TitleLabel.Size = UDim2.new(0, 110, 0, 20)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "GOHUB"
TitleLabel.TextColor3 = HubState.Theme.Text
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Sidebar

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Position = UDim2.new(0, 78, 0, 36)
SubTitleLabel.Size = UDim2.new(0, 110, 0, 16)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Font = Enum.Font.Gotham
SubTitleLabel.Text = "DEFINITIVE V12"
SubTitleLabel.TextColor3 = HubState.Theme.AccentGlow
SubTitleLabel.TextSize = 11
SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubTitleLabel.Parent = Sidebar

local TabListContainer = Instance.new("Frame")
TabListContainer.Name = "TabList"
TabListContainer.Size = UDim2.new(1, -20, 1, -95)
TabListContainer.Position = UDim2.new(0, 10, 0, 85)
TabListContainer.BackgroundTransparency = 1
TabListContainer.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 5)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabListContainer

-- Painel Central de Conteúdo
local ContentPanel = Instance.new("Frame")
ContentPanel.Name = "ContentPanel"
ContentPanel.Size = UDim2.new(1, -260, 1, -20)
ContentPanel.Position = UDim2.new(0, 210, 0, 10)
ContentPanel.BackgroundTransparency = 1
ContentPanel.Parent = MainWindow

local Pages = {}
local CurrentPage = nil

local function CreatePage(id)
    local page = Instance.new("ScrollingFrame")
    page.Name = id .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = HubState.Theme.Accent
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Parent = ContentPanel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 6)
    pad.Parent = page

    Pages[id] = page
    return page
end

local function CreateTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Btn"
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = HubState.Theme.Background
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = HubState.Theme.TextDim
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.Parent = TabListContainer

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        if CurrentPage ~= Pages[name] then
            TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(32, 28, 44), TextColor3 = HubState.Theme.Text }):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        if CurrentPage ~= Pages[name] then
            TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Background, TextColor3 = HubState.Theme.TextDim }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for tabId, p in pairs(Pages) do
            local otherBtn = TabListContainer:FindFirstChild(tabId .. "Btn")
            if p == Pages[name] then
                p.Visible = true
                CurrentPage = p
                TweenService:Create(btn, TweenInfo.new(0.25), { BackgroundColor3 = HubState.Theme.Accent, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
            else
                p.Visible = false
                if otherBtn then
                    TweenService:Create(otherBtn, TweenInfo.new(0.25), { BackgroundColor3 = HubState.Theme.Background, TextColor3 = HubState.Theme.TextDim }):Play()
                end
            end
        end
    end)

    return btn
end

-- Componentes da UI
local function AddSection(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = string.upper(text)
    lbl.TextColor3 = HubState.Theme.AccentGlow
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
end

local function AddToggle(parent, label, defState, callback)
    local state = defState
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = HubState.Theme.Card
    frame.BorderSizePixel = 0
    frame.Parent = parent

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -60, 1, 0)
    txt.Position = UDim2.new(0, 12, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.Gotham
    txt.Text = label
    txt.TextColor3 = HubState.Theme.Text
    txt.TextSize = 12
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = frame

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 42, 0, 22)
    switch.Position = UDim2.new(1, -52, 0.5, -11)
    switch.BackgroundColor3 = state and HubState.Theme.Accent or Color3.fromRGB(45, 45, 60)
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.Parent = frame

    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = switch

    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    switch.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(switch, TweenInfo.new(0.2), { BackgroundColor3 = state and HubState.Theme.Accent or Color3.fromRGB(45, 45, 60) }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }):Play()
        callback(state)
    end)
end

local function AddSlider(parent, label, minVal, maxVal, defaultVal, callback)
    local val = defaultVal
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 54)
    frame.BackgroundColor3 = HubState.Theme.Card
    frame.BorderSizePixel = 0
    frame.Parent = parent

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -60, 0, 22)
    txt.Position = UDim2.new(0, 12, 0, 4)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.Gotham
    txt.Text = label
    txt.TextColor3 = HubState.Theme.Text
    txt.TextSize = 12
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = frame

    local valDisplay = Instance.new("TextLabel")
    valDisplay.Size = UDim2.new(0, 50, 0, 22)
    valDisplay.Position = UDim2.new(1, -60, 0, 4)
    valDisplay.BackgroundTransparency = 1
    valDisplay.Font = Enum.Font.GothamBold
    valDisplay.Text = tostring(math.floor(val))
    valDisplay.TextColor3 = HubState.Theme.AccentGlow
    valDisplay.TextSize = 12
    valDisplay.TextXAlignment = Enum.TextXAlignment.Right
    valDisplay.Parent = frame

    local track = Instance.new("Frame")
    track.Name = "SliderTrack"
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    track.BorderSizePixel = 0
    track.Parent = frame

    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local initialPct = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialPct, 0, 1, 0)
    fill.BackgroundColor3 = HubState.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initialPct, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.Parent = track

    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local knobStroke = Instance.new("UIStroke", knob)
    knobStroke.Color = HubState.Theme.AccentGlow
    knobStroke.Thickness = 1.5

    local isDraggingSlider = false
    local function UpdateKnob(inputX)
        local relX = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        val = math.floor(minVal + (maxVal - minVal) * relX)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, 0, 0.5, 0)
        valDisplay.Text = tostring(val)
        callback(val)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = true
            UpdateKnob(input.Position.X)
        end
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = true
            UpdateKnob(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateKnob(input.Position.X)
        end
    end)
end

local function AddButton(parent, label, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = HubState.Theme.Card
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = "  " .. label
    btn.TextColor3 = HubState.Theme.Text
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = parent

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Accent }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Card }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)
end

local function AddInput(parent, placeholder, defaultText, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = HubState.Theme.Card
    frame.BorderSizePixel = 0
    frame.Parent = parent

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(45, 45, 60)
    stroke.Thickness = 1

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, 0)
    box.Position = UDim2.new(0, 10, 0, 0)
    box.BackgroundTransparency = 1
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = placeholder or "Digite aqui..."
    box.PlaceholderColor3 = HubState.Theme.TextDim
    box.Text = defaultText or ""
    box.TextColor3 = HubState.Theme.Text
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = frame

    box.Focused:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.2), { Color = HubState.Theme.Accent }):Play()
    end)

    box.FocusLost:Connect(function(enterPressed)
        TweenService:Create(stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(45, 45, 60) }):Play()
        if callback then callback(box.Text, enterPressed) end
    end)

    return box
end

-- ====================================================================
-- COMMAND BAR RETRÁTIL DO INFINITE YIELD
-- ====================================================================
local CmdBarFrame = Instance.new("Frame")
CmdBarFrame.Name = "GoHubCmdBar"
CmdBarFrame.Size = UDim2.new(0, 480, 0, 42)
CmdBarFrame.Position = UDim2.new(0.5, -240, 0, -60)
CmdBarFrame.BackgroundColor3 = HubState.Theme.Background
CmdBarFrame.BorderSizePixel = 0
CmdBarFrame.ZIndex = 20
CmdBarFrame.Parent = MainScreen

Instance.new("UICorner", CmdBarFrame).CornerRadius = UDim.new(0, 8)
local CmdStroke = Instance.new("UIStroke", CmdBarFrame)
CmdStroke.Color = HubState.Theme.Accent
CmdStroke.Thickness = 1.5

local CmdPrefixLabel = Instance.new("TextLabel")
CmdPrefixLabel.Size = UDim2.new(0, 30, 1, 0)
CmdPrefixLabel.BackgroundTransparency = 1
CmdPrefixLabel.Font = Enum.Font.GothamBold
CmdPrefixLabel.Text = HubState.CmdBar.Prefix
CmdPrefixLabel.TextColor3 = HubState.Theme.AccentGlow
CmdPrefixLabel.TextSize = 16
CmdPrefixLabel.ZIndex = 21
CmdPrefixLabel.Parent = CmdBarFrame

local CmdInput = Instance.new("TextBox")
CmdInput.Size = UDim2.new(1, -40, 1, 0)
CmdInput.Position = UDim2.new(0, 30, 0, 0)
CmdInput.BackgroundTransparency = 1
CmdInput.Font = Enum.Font.GothamSemibold
CmdInput.PlaceholderText = "Digite um comando... (ex: fly, tp fer, speed 50, fling random)"
CmdInput.PlaceholderColor3 = HubState.Theme.TextDim
CmdInput.Text = ""
CmdInput.TextColor3 = HubState.Theme.Text
CmdInput.TextSize = 13
CmdInput.TextXAlignment = Enum.TextXAlignment.Left
CmdInput.ClearTextOnFocus = false
CmdInput.ZIndex = 21
CmdInput.Parent = CmdBarFrame

local function ToggleCmdBar(forceState)
    local state = (forceState ~= nil) and forceState or not HubState.CmdBar.Visible
    HubState.CmdBar.Visible = state
    if state then
        CmdBarFrame.Visible = true
        TweenService:Create(CmdBarFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -240, 0, 20)
        }):Play()
        task.wait(0.1)
        CmdInput:CaptureFocus()
    else
        TweenService:Create(CmdBarFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -240, 0, -60)
        }):Play()
        CmdInput:ReleaseFocus()
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Semicolon or input.KeyCode == Enum.KeyCode.Quote then
        ToggleCmdBar()
    end
end)

local function DispatchCommand(rawText)
    if not rawText or rawText == "" then return end
    local args = rawText:split(" ")
    local cmd = args[1]:lower()
    table.remove(args, 1)

    if cmd == "fly" then
        MovementEngine.SetFlight(true)
    elseif cmd == "unfly" then
        MovementEngine.SetFlight(false)
    elseif cmd == "speed" or cmd == "ws" then
        local spd = tonumber(args[1]) or 32
        HubState.Movement.Speed = spd
        HubState.Movement.SpeedActive = true
        MovementEngine.ApplySpeed()
    elseif cmd == "unspeed" then
        HubState.Movement.SpeedActive = false
        MovementEngine.ApplySpeed()
    elseif cmd == "noclip" then
        MovementEngine.SetNoclip(true)
    elseif cmd == "clip" then
        MovementEngine.SetNoclip(false)
    elseif cmd == "infjump" then
        MovementEngine.SetInfiniteJump(true)
    elseif cmd == "uninfjump" then
        MovementEngine.SetInfiniteJump(false)
    elseif cmd == "clicktp" then
        MovementEngine.SetClickTP(true)
    elseif cmd == "unclicktp" then
        MovementEngine.SetClickTP(false)
    elseif cmd == "tptool" then
        MovementEngine.GiveTPTool()
    elseif cmd == "tp" or cmd == "goto" then
        local targetName = args[1]
        local found = TargetParser.FindPlayers(targetName)
        if #found > 0 and found[1].Character and found[1].Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp then myHrp.CFrame = found[1].Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0) end
        end
    elseif cmd == "fling" then
        local targetName = args[1]
        if targetName then
            local found = TargetParser.FindPlayers(targetName)
            if #found > 0 then
                FlingEngine.FlingTarget(found[1])
            end
        else
            FlingEngine.ToggleSpinFling(true)
        end
    elseif cmd == "unfling" then
        FlingEngine.ToggleSpinFling(false)
        FlingEngine.ToggleWalkFling(false)
        FlingEngine.LoopFling(nil)
    elseif cmd == "walkfling" then
        FlingEngine.ToggleWalkFling(true)
    elseif cmd == "unwalkfling" or cmd == "nowalkfling" then
        FlingEngine.ToggleWalkFling(false)
    elseif cmd == "antifling" then
        FlingEngine.ToggleAntiFling(true)
    elseif cmd == "unantifling" or cmd == "noantifling" then
        FlingEngine.ToggleAntiFling(false)
    elseif cmd == "loopfling" then
        local targetName = args[1]
        local found = TargetParser.FindPlayers(targetName)
        if #found > 0 then FlingEngine.LoopFling(found[1]) end
    elseif cmd == "unloopfling" then
        FlingEngine.LoopFling(nil)
    elseif cmd == "fullbright" or cmd == "fb" then
        LightingEngine.ToggleFullbright(true)
    elseif cmd == "unfullbright" or cmd == "unfb" then
        LightingEngine.ToggleFullbright(false)
    elseif cmd == "nofog" then
        LightingEngine.ToggleNoFog(true)
    elseif cmd == "dance" then
        local emoteName = args[1]
        if emoteName then
            if tonumber(emoteName) then
                AnimationEngine.PlayRaw(emoteName, "Custom_" .. emoteName)
            else
                AnimationEngine.Play(emoteName)
            end
        end
    elseif cmd == "stopdance" or cmd == "undance" then
        AnimationEngine.Stop()
    elseif cmd == "animspeed" or cmd == "dancespeed" then
        local spd = tonumber(args[1]) or 1
        AnimationEngine.SetSpeed(spd)
    elseif cmd == "antisit" then
        CharEngine.ToggleAntiSit(true)
    elseif cmd == "unantisit" then
        CharEngine.ToggleAntiSit(false)
    elseif cmd == "spin" then
        CharEngine.ToggleSpinBot(true)
    elseif cmd == "unspin" then
        CharEngine.ToggleSpinBot(false)
    elseif cmd == "xray" then
        XRayEngine.Toggle(true)
    elseif cmd == "unxray" then
        XRayEngine.Toggle(false)
    elseif cmd == "respawn" or cmd == "refresh" then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    elseif cmd == "serverhop" or cmd == "shop" then
        task.spawn(function()
            local placeId = game.PlaceId
            local api = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            local success, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(api)) end)
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
    elseif cmd == "rejoin" or cmd == "rj" then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    elseif cmd == "savedance" then
        local danceName = args[1]
        local danceId = args[2]
        if danceName and danceId then
            AnimationEngine.SaveCustomDance(danceName, danceId)
        end
    elseif cmd == "c" or cmd == "radial" or cmd == "emotes" or cmd == "wheel" then
        ToggleRadialMenu()
    elseif cmd == "x" or cmd == "stopdance" or cmd == "stop" then
        AnimationEngine.Stop()
    elseif cmd == "copy" or cmd == "copyskin" then
        local targetName = args[1]
        if targetName then
            local targets = TargetParser.FindPlayers(targetName)
            if #targets > 0 then
                SkinEngine.ClonePlayerSkin(targets[1])
            end
        end
    elseif cmd == "skin" or cmd == "morph" then
        local targetId = args[1]
        if targetId then
            SkinEngine.ApplyByUserId(targetId)
        end
    elseif cmd == "headless" then
        SkinEngine.ToggleHeadless(true)
    elseif cmd == "unheadless" then
        SkinEngine.ToggleHeadless(false)
    elseif cmd == "korblox" then
        SkinEngine.ToggleKorblox(true)
    elseif cmd == "unkorblox" then
        SkinEngine.ToggleKorblox(false)
    elseif cmd == "unskin" or cmd == "resetskin" then
        SkinEngine.ResetAvatar()
    elseif cmd == "min" or cmd == "minimize" then
        SetWindowMinimized(true)
    elseif cmd == "max" or cmd == "maximize" or cmd == "restore" then
        SetWindowMinimized(false)
    end
end

CmdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        DispatchCommand(CmdInput.Text)
        CmdInput.Text = ""
        ToggleCmdBar(false)
    end
end)

-- ====================================================================
-- MONTAGEM DAS ABAS DA V10 DEFINITIVE
-- ====================================================================

-- 1. UNIVERSAL
local universalPage = CreatePage("Universal")
AddSection(universalPage, "Física & Movimentação")
AddToggle(universalPage, "Noclip (Atravessar Paredes)", false, function(s) MovementEngine.SetNoclip(s) end)
AddToggle(universalPage, "Infinite Jump (Pulo Infinito)", false, function(s) MovementEngine.SetInfiniteJump(s) end)
AddToggle(universalPage, "Ativar Voo (W/A/S/D + Espaço/Shift)", false, function(s) MovementEngine.SetFlight(s) end)
AddSlider(universalPage, "Velocidade de Voo", 10, 250, 50, function(v) HubState.Movement.FlightSpeed = v end)
AddToggle(universalPage, "Ativar Velocidade Customizada", false, function(s)
    HubState.Movement.SpeedActive = s
    MovementEngine.ApplySpeed()
end)
AddSlider(universalPage, "Velocidade de Caminhada (SPS)", 16, 250, 32, function(v)
    HubState.Movement.Speed = v
    if HubState.Movement.SpeedActive then MovementEngine.ApplySpeed() end
end)
AddSection(universalPage, "Teleporte Rápido")
AddToggle(universalPage, "ClickTP (Segurar Ctrl + Clique)", false, function(s) MovementEngine.SetClickTP(s) end)
AddButton(universalPage, "Obter TP Tool no Inventário", function() MovementEngine.GiveTPTool() end)
AddSection(universalPage, "Servidores")
AddButton(universalPage, "Server Hop (Menor Lotação)", function() DispatchCommand("serverhop") end)
AddButton(universalPage, "Rejoin (Reconectar ao Mesmo Servidor)", function() DispatchCommand("rejoin") end)

-- 2. JOGADORES (SELEÇÃO, TP, ADVANCED FLING)
local tpPage = CreatePage("Jogadores")
AddSection(tpPage, "Seleção Rápida de Alvo")
local selectedPlayer = nil
local targetStatusLabel = Instance.new("TextLabel")
targetStatusLabel.Size = UDim2.new(1, 0, 0, 22)
targetStatusLabel.BackgroundTransparency = 1
targetStatusLabel.Font = Enum.Font.Gotham
targetStatusLabel.Text = "Jogador Selecionado: Nenhum"
targetStatusLabel.TextColor3 = HubState.Theme.AccentGlow
targetStatusLabel.TextSize = 12
targetStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
targetStatusLabel.Parent = tpPage

AddButton(tpPage, "Teleportar para Alvo", function()
    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then myHrp.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0) end
    end
end)

AddSection(tpPage, "Sistemas de Fling (Motor Infinite Yield)")
AddToggle(tpPage, "WalkFling (Tocar e Lançar - Suave)", false, function(s) FlingEngine.ToggleWalkFling(s) end)
AddToggle(tpPage, "SpinFling (Giro Clássico do IY)", false, function(s) FlingEngine.ToggleSpinFling(s) end)
AddButton(tpPage, "Fling Instantâneo no Alvo", function()
    if selectedPlayer then FlingEngine.FlingTarget(selectedPlayer) end
end)
AddToggle(tpPage, "LoopFling no Alvo Selecionado", false, function(s)
    if s then FlingEngine.LoopFling(selectedPlayer) else FlingEngine.LoopFling(nil) end
end)
AddToggle(tpPage, "Anti-Fling (Imunidade a Flings)", false, function(s)
    FlingEngine.ToggleAntiFling(s)
end)

AddSection(tpPage, "Lista de Jogadores no Servidor")
local playerListContainer = Instance.new("Frame")
playerListContainer.Size = UDim2.new(1, 0, 0, 140)
playerListContainer.BackgroundColor3 = HubState.Theme.Card
playerListContainer.Parent = tpPage

Instance.new("UICorner", playerListContainer).CornerRadius = UDim.new(0, 6)

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, -10, 1, -10)
playerScroll.Position = UDim2.new(0, 5, 0, 5)
playerScroll.BackgroundTransparency = 1
playerScroll.ScrollBarThickness = 3
playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerScroll.Parent = playerListContainer

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 4)
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Parent = playerScroll

local function RefreshPlayerList()
    for _, child in ipairs(playerScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(1, -6, 0, 26)
            pBtn.BackgroundColor3 = HubState.Theme.Background
            pBtn.Font = Enum.Font.Gotham
            pBtn.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ")"
            pBtn.TextColor3 = HubState.Theme.Text
            pBtn.TextSize = 11
            pBtn.TextXAlignment = Enum.TextXAlignment.Left
            pBtn.Parent = playerScroll

            Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)

            pBtn.MouseButton1Click:Connect(function()
                selectedPlayer = p
                targetStatusLabel.Text = "Jogador Selecionado: " .. p.DisplayName
            end)
        end
    end
end
RefreshPlayerList()
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(RefreshPlayerList)
AddButton(tpPage, "Atualizar Lista de Jogadores", RefreshPlayerList)

-- 3. WAYPOINTS
local wpPage = CreatePage("Waypoints")
AddSection(wpPage, "Gerenciador de Pontos do Mapa")
AddButton(wpPage, "Salvar Posição Atual como Waypoint", function()
    WaypointEngine.SaveCurrent()
end)

local wpContainer = Instance.new("Frame")
wpContainer.Size = UDim2.new(1, 0, 0, 160)
wpContainer.BackgroundColor3 = HubState.Theme.Card
wpContainer.Parent = wpPage

Instance.new("UICorner", wpContainer).CornerRadius = UDim.new(0, 6)

local wpScroll = Instance.new("ScrollingFrame")
wpScroll.Size = UDim2.new(1, -10, 1, -10)
wpScroll.Position = UDim2.new(0, 5, 0, 5)
wpScroll.BackgroundTransparency = 1
wpScroll.ScrollBarThickness = 3
wpScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
wpScroll.Parent = wpContainer

local wpLayout = Instance.new("UIListLayout")
wpLayout.Padding = UDim.new(0, 4)
wpLayout.SortOrder = Enum.SortOrder.LayoutOrder
wpLayout.Parent = wpScroll

local function RefreshWaypointsUI()
    for _, child in ipairs(wpScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, wp in ipairs(HubState.Waypoints) do
        local wpBtn = Instance.new("TextButton")
        wpBtn.Size = UDim2.new(1, -6, 0, 26)
        wpBtn.BackgroundColor3 = HubState.Theme.Background
        wpBtn.Font = Enum.Font.Gotham
        wpBtn.Text = "  " .. wp.Name .. " (Clique para TP)"
        wpBtn.TextColor3 = HubState.Theme.Text
        wpBtn.TextSize = 11
        wpBtn.TextXAlignment = Enum.TextXAlignment.Left
        wpBtn.Parent = wpScroll

        Instance.new("UICorner", wpBtn).CornerRadius = UDim.new(0, 4)

        wpBtn.MouseButton1Click:Connect(function()
            WaypointEngine.TeleportTo(wp)
        end)
    end
end
AddButton(wpPage, "Atualizar Lista de Waypoints", RefreshWaypointsUI)

-- 4. MURDER MYSTERY 2
local mm2Page = CreatePage("MM2")
AddSection(mm2Page, "Detecção & Papéis (Role ESP)")
AddToggle(mm2Page, "Ver Assassino & Xerife (Role ESP)", false, function(s) MM2Engine.ToggleRoleESP(s) end)
AddSection(mm2Page, "Moedas & Itens")
AddToggle(mm2Page, "ESP de Moedas (Coin ESP)", false, function(s) MM2Engine.ToggleCoinESP(s) end)
AddToggle(mm2Page, "Auto-Coletar Arma ao Cair (Gun Drop)", false, function(s) MM2Engine.ToggleAutoGrabGun(s) end)
AddSection(mm2Page, "Combate")
AddToggle(mm2Page, "Hitboxes Expandidas", false, function(s) MM2Engine.ToggleHitboxes(s) end)

-- 5. VISUAIS & MIRA
local visualPage = CreatePage("Visuais")
AddSection(visualPage, "Iluminação do Mundo")
AddToggle(visualPage, "Fullbright (Tudo Claro)", false, function(s) LightingEngine.ToggleFullbright(s) end)
AddToggle(visualPage, "NoFog (Remover Neblina)", false, function(s) LightingEngine.ToggleNoFog(s) end)
AddSection(visualPage, "Rastreamento")
AddToggle(visualPage, "Player ESP Universal (Chams Roxo)", false, function(s) UpdateUniversalESP(s) end)
AddToggle(visualPage, "Ativar X-Ray (Paredes Transparentes)", false, function(s) XRayEngine.Toggle(s) end)
AddSection(visualPage, "Aimbot com Raycast")
AddToggle(visualPage, "Aimbot Ativo (Segurar Botão Direito)", false, function(s)
    HubState.Combat.AimbotActive = s
    FOVCircle.Visible = s and HubState.Combat.FOVCircleVisible
end)
AddToggle(visualPage, "Verificação de Visibilidade (Raycast)", true, function(s) HubState.Combat.VisibilityCheck = s end)
AddSlider(visualPage, "Raio do FOV", 50, 350, 120, function(v)
    HubState.Combat.FOV = v
    FOVCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end)

-- 6. DANÇAS & EMOTES (R15 EXPANDIDO, PASSINHO DO JAMAL, IY SUITE & DANÇAS CUSTOMIZADAS)
local animPage = CreatePage("Danças")

AddSection(animPage, "Controle de Dança")
AddButton(animPage, "Parar Todas as Danças", function()
    AnimationEngine.Stop()
end)
AddSlider(animPage, "Velocidade da Animação (%)", 25, 300, 100, function(pct)
    AnimationEngine.SetSpeed(pct / 100)
end)

AddSection(animPage, "Adicionar & Salvar Dança Customizada")
local customNameBox = AddInput(animPage, "Nome da Dança (ex: Passinho Pro, Phonk...)", "")
local customIdBox = AddInput(animPage, "ID da Animação / Asset ID (ex: 131086670591743)", "")

local customBtnRow = Instance.new("Frame")
customBtnRow.Size = UDim2.new(1, 0, 0, 36)
customBtnRow.BackgroundTransparency = 1
customBtnRow.Parent = animPage

local testBtn = Instance.new("TextButton")
testBtn.Size = UDim2.new(0.48, -4, 1, 0)
testBtn.Position = UDim2.new(0, 0, 0, 0)
testBtn.BackgroundColor3 = HubState.Theme.Card
testBtn.Font = Enum.Font.GothamSemibold
testBtn.Text = "▶ Testar ID"
testBtn.TextColor3 = HubState.Theme.AccentGlow
testBtn.TextSize = 12
testBtn.Parent = customBtnRow
Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 6)

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.52, -4, 1, 0)
saveBtn.Position = UDim2.new(0.48, 8, 0, 0)
saveBtn.BackgroundColor3 = HubState.Theme.Accent
saveBtn.Font = Enum.Font.GothamBold
saveBtn.Text = "💾 Salvar no Hub"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.TextSize = 12
saveBtn.Parent = customBtnRow
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

testBtn.MouseEnter:Connect(function()
    TweenService:Create(testBtn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Accent, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
end)
testBtn.MouseLeave:Connect(function()
    TweenService:Create(testBtn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Card, TextColor3 = HubState.Theme.AccentGlow }):Play()
end)

saveBtn.MouseEnter:Connect(function()
    TweenService:Create(saveBtn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.AccentGlow }):Play()
end)
saveBtn.MouseLeave:Connect(function()
    TweenService:Create(saveBtn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Accent }):Play()
end)

AddSection(animPage, "Minhas Danças Salvas")
local customDancesContainer = Instance.new("Frame")
customDancesContainer.Size = UDim2.new(1, 0, 0, 140)
customDancesContainer.BackgroundColor3 = HubState.Theme.Card
customDancesContainer.Parent = animPage
Instance.new("UICorner", customDancesContainer).CornerRadius = UDim.new(0, 6)

local customScroll = Instance.new("ScrollingFrame")
customScroll.Size = UDim2.new(1, -10, 1, -10)
customScroll.Position = UDim2.new(0, 5, 0, 5)
customScroll.BackgroundTransparency = 1
customScroll.ScrollBarThickness = 3
customScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
customScroll.Parent = customDancesContainer

local customLayout = Instance.new("UIListLayout")
customLayout.Padding = UDim.new(0, 4)
customLayout.SortOrder = Enum.SortOrder.LayoutOrder
customLayout.Parent = customScroll

local function RefreshCustomDancesUI()
    for _, child in ipairs(customScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if #HubState.CustomDances == 0 then
        local emptyLbl = Instance.new("Frame")
        emptyLbl.Size = UDim2.new(1, 0, 0, 30)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Parent = customScroll

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.Gotham
        txt.Text = "Nenhuma dança salva. Adicione um ID acima!"
        txt.TextColor3 = HubState.Theme.TextDim
        txt.TextSize = 11
        txt.Parent = emptyLbl
        return
    end

    for idx, d in ipairs(HubState.CustomDances) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 30)
        row.BackgroundColor3 = HubState.Theme.Background
        row.Parent = customScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -140, 1, 0)
        nameLbl.Position = UDim2.new(0, 8, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamSemibold
        nameLbl.Text = d.Name .. "  (" .. d.ID .. ")"
        nameLbl.TextColor3 = HubState.Theme.Text
        nameLbl.TextSize = 11
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = row

        local playBtn = Instance.new("TextButton")
        playBtn.Size = UDim2.new(0, 60, 0, 22)
        playBtn.Position = UDim2.new(1, -125, 0.5, -11)
        playBtn.BackgroundColor3 = HubState.Theme.Accent
        playBtn.Font = Enum.Font.GothamBold
        playBtn.Text = "▶ Tocar"
        playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        playBtn.TextSize = 10
        playBtn.Parent = row
        Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 4)

        playBtn.MouseButton1Click:Connect(function()
            AnimationEngine.PlayRaw(d.ID, d.Name)
        end)

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 55, 0, 22)
        delBtn.Position = UDim2.new(1, -60, 0.5, -11)
        delBtn.BackgroundColor3 = HubState.Theme.Card
        delBtn.Font = Enum.Font.GothamBold
        delBtn.Text = "🗑 Excluir"
        delBtn.TextColor3 = HubState.Theme.Close
        delBtn.TextSize = 10
        delBtn.Parent = row
        Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)

        delBtn.MouseButton1Click:Connect(function()
            AnimationEngine.DeleteCustomDance(idx)
            RefreshCustomDancesUI()
        end)
    end
end

testBtn.MouseButton1Click:Connect(function()
    local id = customIdBox.Text
    local name = customNameBox.Text ~= "" and customNameBox.Text or "CustomTest"
    if id and id ~= "" then
        AnimationEngine.PlayRaw(id, name)
    end
end)

saveBtn.MouseButton1Click:Connect(function()
    local name = customNameBox.Text
    local id = customIdBox.Text
    local ok, res = AnimationEngine.SaveCustomDance(name, id)
    if ok then
        customNameBox.Text = ""
        customIdBox.Text = ""
        RefreshCustomDancesUI()
    end
end)

RefreshCustomDancesUI()

for _, cat in ipairs(EmoteCategories) do
    AddSection(animPage, cat.Category)
    for _, em in ipairs(cat.Emotes) do
        AddButton(animPage, "Dança: " .. em.Name, function()
            AnimationEngine.PlayRaw(em.ID, em.Name)
        end)
    end
end

-- 7. SKINS & MORPHS (V12 REPLICAÇÃO FE, CLONADOR, REMOTAS & ITENS LENDÁRIOS)
local skinPage = CreatePage("Skins")

AddSection(skinPage, "Replicação Global (Everyone Sees)")
local scanStatusLabel = Instance.new("TextLabel")
scanStatusLabel.Size = UDim2.new(1, 0, 0, 20)
scanStatusLabel.BackgroundTransparency = 1
scanStatusLabel.Font = Enum.Font.Gotham
scanStatusLabel.Text = "Status de Replicação: Pronto para verificar remotas"
scanStatusLabel.TextColor3 = HubState.Theme.AccentGlow
scanStatusLabel.TextSize = 11
scanStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
scanStatusLabel.Parent = skinPage

AddButton(skinPage, "🔍 Escanear & Forçar Remotes de Avatar do Servidor", function()
    local ok = SkinEngine.ScanAndFireRemote(LocalPlayer.UserId, nil)
    if ok then
        scanStatusLabel.Text = "Status: Remotas encontradas e disparadas com sucesso!"
        scanStatusLabel.TextColor3 = HubState.Theme.Success
    else
        scanStatusLabel.Text = "Status: Nenhuma remota vulnerável aberta neste jogo"
        scanStatusLabel.TextColor3 = HubState.Theme.Close
    end
end)

AddToggle(skinPage, "FE Hat Reanimation Rig (Replicação Física Netless)", false, function(s)
    SkinEngine.ToggleHatReanim(s)
end)

AddSection(skinPage, "Clonador Rápido de Jogadores")
local copyStatusLabel = Instance.new("TextLabel")
copyStatusLabel.Size = UDim2.new(1, 0, 0, 20)
copyStatusLabel.BackgroundTransparency = 1
copyStatusLabel.Font = Enum.Font.Gotham
copyStatusLabel.Text = "Alvo: Selecione um jogador na aba 'Jogadores'"
copyStatusLabel.TextColor3 = HubState.Theme.TextDim
copyStatusLabel.TextSize = 11
copyStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
copyStatusLabel.Parent = skinPage

AddButton(skinPage, "🎭 Clonar Skin do Jogador Selecionado", function()
    if selectedPlayer then
        local ok, msg = SkinEngine.ClonePlayerSkin(selectedPlayer)
        copyStatusLabel.Text = "Resultado: " .. tostring(msg)
        copyStatusLabel.TextColor3 = ok and HubState.Theme.Success or HubState.Theme.Close
    else
        copyStatusLabel.Text = "Aviso: Selecione um player na aba Jogadores primeiro!"
        copyStatusLabel.TextColor3 = HubState.Theme.Close
    end
end)

AddSection(skinPage, "Aplicar Avatar por User ID")
local skinIdInput = AddInput(skinPage, "User ID da Conta (ex: 261, 1, 48316149)", "")
AddButton(skinPage, "⚡ Aplicar Skin por User ID", function()
    local id = skinIdInput.Text
    if id and id ~= "" then
        local ok, msg = SkinEngine.ApplyByUserId(id)
        scanStatusLabel.Text = tostring(msg)
        scanStatusLabel.TextColor3 = ok and HubState.Theme.Success or HubState.Theme.Close
    end
end)

AddSection(skinPage, "Pacotes & Itens Lendários Gratuitos")
AddToggle(skinPage, "Headless Horseman (Cabeça Invisível)", false, function(s)
    SkinEngine.ToggleHeadless(s)
end)
AddToggle(skinPage, "Korblox Deathspeaker (Perna de Esqueleto)", false, function(s)
    SkinEngine.ToggleKorblox(s)
end)

AddSection(skinPage, "Restauração de Aparência")
AddButton(skinPage, "🔄 Restaurar Avatar Original", function()
    SkinEngine.ResetAvatar()
    scanStatusLabel.Text = "Status: Avatar original restaurado!"
    scanStatusLabel.TextColor3 = HubState.Theme.Text
end)

-- 8. UTILIDADES DO PERSONAGEM
local charPage = CreatePage("Personagem")
AddSection(charPage, "Física do Personagem")
AddToggle(charPage, "Anti-Sit (Impedir de Sentar)", false, function(s) CharEngine.ToggleAntiSit(s) end)
AddToggle(charPage, "SpinBot (Girar Personagem)", false, function(s) CharEngine.ToggleSpinBot(s) end)
AddSlider(charPage, "Velocidade do SpinBot", 10, 150, 30, function(v)
    HubState.Character.SpinSpeed = v
    if HubState.Character.SpinBot then CharEngine.ToggleSpinBot(true) end
end)
AddSection(charPage, "Ciclo de Vida")
AddButton(charPage, "Respawn Instantâneo (Reset)", function() DispatchCommand("respawn") end)

-- 9. COMANDOS & AJUDA
local cmdHelpPage = CreatePage("Comandos")
AddSection(cmdHelpPage, "Barra de Comandos Rápida")
AddButton(cmdHelpPage, "Abrir / Fechar Command Bar (Atalho: ';')", function() ToggleCmdBar() end)
AddSection(cmdHelpPage, "Lista de Comandos")
local helpText = Instance.new("TextLabel")
helpText.Size = UDim2.new(1, 0, 0, 310)
helpText.BackgroundTransparency = 1
helpText.Font = Enum.Font.Gotham
helpText.Text = [[
• fly / unfly — Ativa/Desativa o voo suave
• speed [num] / unspeed — Configura a velocidade
• noclip / clip — Ativa/Desativa atravessar paredes
• infjump / uninfjump — Pulo infinito
• clicktp / unclicktp — Segure Ctrl e clique para teleportar
• tptool — Spawna a ferramenta de teleporte no inventário
• tp [alvo] — Teleporta até o jogador (ex: tp fer, tp nearest)
• walkfling / unwalkfling — WalkFling suave do Infinite Yield
• fling [alvo] / loopfling [alvo] — Fling instantâneo ou contínuo
• antifling / unantifling — Imunidade contra flings de terceiros
• fullbright / nofog — Modifica a iluminação do mapa
• c / radial — Abre/Fecha o menu circular de danças (Atalho: 'C')
• x / stopdance — Para qualquer dança instantaneamente (Atalho: 'X')
• dance [nome/id] — Executa danças do catálogo ou custom
• savedance [nome] [id] — Salva uma nova dança customizada
• animspeed [num] — Ajusta a velocidade da dança em tempo real
• copy [alvo] — Clona a skin completa do jogador
• skin [userId] / unskin — Aplica skin por ID de conta ou restaura
• headless / unheadless — Ativa/Desativa cabeça invisível
• korblox / unkorblox — Ativa/Desativa perna do Korblox
• min / max — Minimiza ou restaura o GoHub (Atalho: RightControl)
• antisit / spin / unspin — Controles de física do personagem
• rejoin / serverhop — Controles de reconexão de servidor
]]
helpText.TextColor3 = HubState.Theme.TextDim
helpText.TextSize = 12
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextYAlignment = Enum.TextYAlignment.Top
helpText.Parent = cmdHelpPage

-- Criar Botões das Abas na Sidebar
CreateTab("Universal", "⚡", 1)
CreateTab("Jogadores", "👤", 2)
CreateTab("Skins", "🎭", 3)
CreateTab("Waypoints", "📍", 4)
CreateTab("MM2", "🔪", 5)
CreateTab("Visuais", "👁", 6)
CreateTab("Danças", "💃", 7)
CreateTab("Personagem", "🛡", 8)
CreateTab("Comandos", "⌨", 9)

-- Ativar Página Padrão
Pages["Universal"].Visible = true
CurrentPage = Pages["Universal"]
local defaultTabBtn = TabListContainer:FindFirstChild("UniversalBtn")
if defaultTabBtn then
    defaultTabBtn.BackgroundColor3 = HubState.Theme.Accent
    defaultTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

print("GoHub V12 Definitive Loaded Cleanly!")
