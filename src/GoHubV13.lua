--[[
    ========================================================================================
    GOHUB V13 — DEFINITIVE RAYFIELD & SHADER SUITE (MASSIVE UPGRADE)
    Target: Roblox Studio / Luau Engine / Standard Executors
    Author: Agente de Modificação da UI 6 (Sintetizador de Abas e Motores GoHub V13)
    
    Arquitetura de Síntese:
      - Framework de Interface: Sirius Rayfield Library (V3 / Modern UI)
      - Suporte Completo a 8 Abas Especializadas:
          1. 'Universal'  : Speed Slider (16-300), Flight Toggle + Speed Slider, Noclip, Inf Jump,
                            ClickTP, TP Tool, Server Hop, Rejoin.
          2. 'Jogadores'  : Dropdown & Input Alvo, TP Alvo, Espectar/Restaurar, Drop Kick Fling [K],
                            WalkFling, SpinFling, Fling Instantâneo, LoopFling, Anti-Fling.
          3. 'Skins'      : Clonar Skin do Alvo, Aplicar por User ID, Headless, Korblox, Reset Skin.
          4. 'MM2'        : Detecção Híbrida de Papéis (Remote + Inv + Inocentes Verdes), Coin ESP,
                            Auto-Grab Gun, Hitboxes Expandidas.
          5. 'Danças'     : Parar Danças [X], Slider de Velocidade, Radial Menu [C], Danças Customizadas
                            (Nome, ID, Testar, Salvar, Deletar), Danças Pré-definidas.
          6. 'Personagem' : Anti-Sit, SpinBot + Slider de Velocidade, Botão Respawn.
          7. 'Waypoints'  : Adicionar Waypoint, Dropdown de Seleção, Teleportar, Deletar.
          8. 'Comandos'   : Dicionário de Atalhos, Comandos Rápidos e Botão para Command Bar (;).
      - Background Systems & Hotkeys 100% Preservados e Ativos:
          • 2x 'W'       -> Sprint inteligente (25 SPS)
          • 2x 'Espaço'  -> Alternar Voo Suave (70 SPS)
          • 'R'          -> Alternar X-Ray (Transparência de Cenário)
          • 'M'          -> Alternar MM2 Role ESP
          • 'K'          -> Drop Kick Fling Instantâneo (Motor Avançado de Impulso 5000)
          • 'C'          -> Roda Radial Circular de Emotes (Slots 1-8 + Teclas Numéricas 1-8)
          • 'X'          -> Parar Dança Instantaneamente
          • ';' ou '\''  -> Command Bar Retrátil Nativa (Dispatcher com 30+ Comandos)
          • Anti-AFK     -> VirtualUser Heartbeat Hook no LocalPlayer.Idled
    ========================================================================================
]]

-- Carregamento e Serviços
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
local Debris = game:GetService("Debris")

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

-- Safe GuiRoot Discovery
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
    
    return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
end

local GuiRoot = GetSafeGuiRoot() or LocalPlayer:WaitForChild("PlayerGui")

-- ====================================================================
-- ESTADO GLOBAL DO GOHUB V13
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
        ShaderActive = false,
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
        LoopTarget = nil,
        DropKickActive = false,
        DropKickForce = 5000
    },
    Animation = {
        CurrentTrack = nil,
        Speed = 1
    },
    CustomDances = {},
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
        SelectedSlot = nil,
        Slots = {
            [1] = { Name = "Jamal (Principal)", ID = "131086670591743" },
            [2] = { Name = "Passinho Fogo", ID = "101508054279219" },
            [3] = { Name = "Floss", ID = "10714340543" },
            [4] = { Name = "Breakdance (IY)", ID = "3333432454" },
            [5] = { Name = "Pop & Lock (IY)", ID = "4555808220" },
            [6] = { Name = "Hip Hop (IY)", ID = "4049037604" },
            [7] = { Name = "SpiderTree", ID = "3361426436" },
            [8] = { Name = "Spin Dance", ID = "3361481910" }
        }
    },
    CmdBar = {
        Prefix = ";",
        Visible = false
    },
    SelectedPlayer = nil,
    IsSpectating = false
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
-- ANTI-AFK NATIVO
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
        local n = p.Name:lower()
        local dn = p.DisplayName:lower()
        if n:sub(1, #q) == q or dn:sub(1, #q) == q or n:find(q, 1, true) or dn:find(q, 1, true) then
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
    if HubState.IsSpectating then
        HubState.IsSpectating = false
        Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
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
    if not bp or bp:FindFirstChild("GoHub TP Tool") then return end
    local tool = Instance.new("Tool")
    tool.Name = "GoHub TP Tool"
    tool.RequiresHandle = false
    tool.Activated:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and Mouse.Hit then hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
    end)
    tool.Parent = bp
end

function MovementEngine.ServerHop()
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
end

function MovementEngine.Rejoin()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end

-- ====================================================================
-- SISTEMA DE WAYPOINTS
-- ====================================================================
local WaypointEngine = {}

function WaypointEngine.SaveCurrent(name)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "Personagem não encontrado" end
    local wpName = (name and name ~= "") and name or ("Ponto_" .. (#HubState.Waypoints + 1))
    table.insert(HubState.Waypoints, { Name = wpName, CFrame = hrp.CFrame })
    return true, wpName
end

function WaypointEngine.TeleportTo(wp)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and wp and wp.CFrame then
        hrp.CFrame = wp.CFrame
        return true
    end
    return false
end

function WaypointEngine.DeleteWaypoint(wpName)
    for i = #HubState.Waypoints, 1, -1 do
        if HubState.Waypoints[i].Name == wpName then
            table.remove(HubState.Waypoints, i)
            return true
        end
    end
    return false
end

-- ====================================================================
-- SISTEMA DE FLING (INFINITE YIELD ENGINE + DROP KICK AVANÇADO)
-- ====================================================================
local FlingEngine = {}

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

function FlingEngine.ToggleSpinFling(enabled)
    HubState.Fling.Active = enabled
    if not enabled then
        DropLoop("SpinFling_Pulse")
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local spin = hrp:FindFirstChild("GoHubFlingSpin")
            if spin then spin:Destroy() end
        end
        return
    end

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

        local spin = hrp:FindFirstChild("GoHubFlingSpin") or Instance.new("BodyAngularVelocity")
        spin.Name = "GoHubFlingSpin"
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
        if hrp:FindFirstChild("GoHubFlingSpin") then
            hrp.GoHubFlingSpin:Destroy()
        end
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
                v.Massless = false
                v.AssemblyLinearVelocity = Vector3.zero
            elseif v:IsA("BodyAngularVelocity") and v.Name == "GoHubFlingSpin" then
                v:Destroy()
            end
        end
    end
end

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

-- Motor Drop Kick Fling
local dropKickAnimation = Instance.new("Animation")
dropKickAnimation.AnimationId = "rbxassetid://133566007754001"
local isDropKicking = false
local dropKickActionId = 0

function FlingEngine.PerformDropKick(customForce)
    if isDropKicking then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end

    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    local leg = char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg") or hrp

    dropKickActionId = dropKickActionId + 1
    local currentActionId = dropKickActionId
    isDropKicking = true
    HubState.Fling.DropKickActive = true

    local origWalkSpeed = hum.WalkSpeed
    local origAutoRotate = hum.AutoRotate

    local track
    local loadOk = pcall(function()
        track = animator:LoadAnimation(dropKickAnimation)
        track.Priority = Enum.AnimationPriority.Action
    end)

    if not loadOk or not track then
        isDropKicking = false
        HubState.Fling.DropKickActive = false
        return
    end

    local tempConstraints = {}
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer and otherPlayer.Character then
            for _, p1 in ipairs(char:GetDescendants()) do
                if p1:IsA("BasePart") then
                    for _, p2 in ipairs(otherPlayer.Character:GetDescendants()) do
                        if p2:IsA("BasePart") then
                            local con = Instance.new("NoCollisionConstraint")
                            con.Part0 = p1
                            con.Part1 = p2
                            con.Parent = char
                            table.insert(tempConstraints, con)
                        end
                    end
                end
            end
        end
    end

    local function cleanupDropKick()
        pcall(function()
            if track and track.IsPlaying then track:Stop(0.15) end
            if track then track:Destroy() end
        end)
        for _, con in ipairs(tempConstraints) do
            pcall(function() con:Destroy() end)
        end
        table.clear(tempConstraints)
        if hum and hum.Parent then
            hum.WalkSpeed = origWalkSpeed
            hum.AutoRotate = origAutoRotate
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            hum.BreakJointsOnDeath = true
            hum.PlatformStand = false
            hum.Sit = false
        end
        if hrp and hrp.Parent then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        if leg and leg.Parent then
            leg.AssemblyLinearVelocity = Vector3.zero
            leg.AssemblyAngularVelocity = Vector3.zero
        end
        isDropKicking = false
        HubState.Fling.DropKickActive = false
    end

    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    hum.BreakJointsOnDeath = false
    hum.AutoRotate = true

    track:Play(0)

    task.spawn(function()
        local camera = Workspace.CurrentCamera
        local force = customForce or HubState.Fling.DropKickForce or 5000
        local upForce = force * 0.12
        local animLen = track.Length
        if animLen <= 0 then animLen = 1.2 end
        local playDuration = math.max(0.2, animLen - 0.25)
        local startTime = tick()

        local camLook = camera and camera.CFrame.LookVector or hrp.CFrame.LookVector
        local forwardDir = Vector3.new(camLook.X, 0, camLook.Z).Unit
        if forwardDir.Magnitude < 0.1 then forwardDir = hrp.CFrame.LookVector end
        local flingDir = (forwardDir * 2.5 + Vector3.new(0, 0.45, 0)).Unit

        local lungeSpeed = math.max(origWalkSpeed * 1.8, 38)

        while track.IsPlaying and (tick() - startTime < playDuration) do
            if currentActionId ~= dropKickActionId or not char.Parent or not hrp.Parent or hum.Health <= 0 then
                break
            end

            local moveDir = hum.MoveDirection
            local currentForward = (moveDir.Magnitude > 0.05 and moveDir.Unit or forwardDir)
            local currentY = math.clamp(hrp.AssemblyLinearVelocity.Y, -25, 15)
            local safeLunge = currentForward * lungeSpeed + Vector3.new(0, currentY, 0)

            hrp.AssemblyLinearVelocity = safeLunge
            hrp.AssemblyAngularVelocity = Vector3.zero

            if leg and leg.Parent then
                leg.AssemblyLinearVelocity = safeLunge
                leg.AssemblyAngularVelocity = Vector3.zero
            end

            local myPos = hrp.Position
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local tChar = player.Character
                    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                    local tHum = tChar:FindFirstChildOfClass("Humanoid")
                    if tRoot and tHum and tHum.Health > 0 then
                        local dist = (tRoot.Position - myPos).Magnitude
                        if dist <= 13 then
                            pcall(function()
                                tHum.Sit = true
                                tHum.PlatformStand = true
                                tHum:ChangeState(Enum.HumanoidStateType.Physics)

                                for _ = 1, 3 do
                                    pcall(function() tRoot:RequestNetworkOwnership() end)
                                end

                                local targetLaunchVel = flingDir * force + Vector3.new(0, upForce, 0)

                                for _, part in ipairs(tChar:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        part.AssemblyLinearVelocity = targetLaunchVel
                                    end
                                end

                                local bv = tRoot:FindFirstChild("DropKickBV") or Instance.new("BodyVelocity")
                                bv.Name = "DropKickBV"
                                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                bv.Velocity = targetLaunchVel
                                bv.P = 1e6
                                bv.Parent = tRoot
                                Debris:AddItem(bv, 0.5)

                                local bav = tRoot:FindFirstChild("DropKickBAV") or Instance.new("BodyAngularVelocity")
                                bav.Name = "DropKickBAV"
                                bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                                bav.AngularVelocity = Vector3.new(
                                    math.random(-60, 60),
                                    math.random(-60, 60),
                                    math.random(-60, 60)
                                )
                                bav.P = 1e6
                                bav.Parent = tRoot
                                Debris:AddItem(bav, 0.5)

                                tRoot.AssemblyLinearVelocity = targetLaunchVel
                                tRoot.AssemblyAngularVelocity = Vector3.new(
                                    math.random(-40, 40),
                                    math.random(-40, 40),
                                    math.random(-40, 40)
                                )
                            end)
                        end
                    end
                end
            end

            RunService.Heartbeat:Wait()
            if currentActionId ~= dropKickActionId or not char.Parent or not hrp.Parent then break end

            if hrp.AssemblyLinearVelocity.Magnitude > (lungeSpeed + 25) then
                hrp.AssemblyLinearVelocity = safeLunge
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end

        cleanupDropKick()
    end)
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
        spin.Name = "GoHubSpinBot"
        spin.MaxTorque = Vector3.new(0, math.huge, 0)
        spin.AngularVelocity = Vector3.new(0, HubState.Character.SpinSpeed, 0)
        spin.Parent = hrp
    else
        if hrp:FindFirstChild("GoHubSpinBot") then hrp.GoHubSpinBot:Destroy() end
    end
end

-- ====================================================================
-- ILUMINAÇÃO & VISUAIS (FULLBRIGHT, NOFOG, X-RAY)
-- ====================================================================
-- ====================================================================
-- ILUMINAÇÃO, SHADERS REALISTAS & EFEITOS CINEMÁTICOS (GOLDEN HOUR)
-- ====================================================================
local LightingEngine = {}

local PristineBaseline = {
    Captured = false,
    Brightness = 1,
    ExposureCompensation = 0,
    ClockTime = 14,
    Ambient = Color3.fromRGB(128, 128, 128),
    OutdoorAmbient = Color3.fromRGB(128, 128, 128),
    FogEnd = 100000,
    FogStart = 0,
    FogColor = Color3.fromRGB(192, 192, 192),
    Atmospheres = {},
    OriginalSky = nil,
    OriginalEffects = {}
}

local ActiveShaderInstances = {}
local UIToggleElements = {}

local function CapturePristineBaseline()
    if PristineBaseline.Captured then return end

    PristineBaseline.Brightness = Lighting.Brightness
    PristineBaseline.ExposureCompensation = Lighting.ExposureCompensation
    PristineBaseline.ClockTime = Lighting.ClockTime
    PristineBaseline.Ambient = Lighting.Ambient
    PristineBaseline.OutdoorAmbient = Lighting.OutdoorAmbient
    PristineBaseline.FogEnd = Lighting.FogEnd
    PristineBaseline.FogStart = Lighting.FogStart
    PristineBaseline.FogColor = Lighting.FogColor

    PristineBaseline.Atmospheres = {}
    for _, obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") then
            PristineBaseline.Atmospheres[obj] = obj.Density
        end
    end

    PristineBaseline.OriginalSky = nil
    PristineBaseline.OriginalEffects = {}
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") and not obj:GetAttribute("GoHubShader") then
            PristineBaseline.OriginalSky = obj
        elseif obj:IsA("PostEffect") and not obj:GetAttribute("GoHubShader") then
            table.insert(PristineBaseline.OriginalEffects, {
                Instance = obj,
                OriginalEnabled = obj.Enabled
            })
        end
    end

    PristineBaseline.Captured = true
end

local function ReconcileLighting()
    if not PristineBaseline.Captured then
        CapturePristineBaseline()
    end

    local shaderOn = HubState.Visuals.ShaderActive
    local fbOn = HubState.Visuals.FullbrightActive
    local noFogOn = HubState.Visuals.NoFogActive

    if fbOn then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = PristineBaseline.Ambient
        Lighting.OutdoorAmbient = PristineBaseline.OutdoorAmbient
    end

    if shaderOn then
        Lighting.Brightness = 2.25
        Lighting.ExposureCompensation = 0.1
        Lighting.ClockTime = 17.55
    elseif fbOn then
        Lighting.Brightness = 2.0
        Lighting.ExposureCompensation = PristineBaseline.ExposureCompensation
        Lighting.ClockTime = 14.0
    else
        Lighting.Brightness = PristineBaseline.Brightness
        Lighting.ExposureCompensation = PristineBaseline.ExposureCompensation
        Lighting.ClockTime = PristineBaseline.ClockTime
    end

    if noFogOn then
        Lighting.FogEnd = 1e6
        Lighting.FogStart = 1e6
        for _, obj in ipairs(Lighting:GetDescendants()) do
            if obj:IsA("Atmosphere") then
                obj.Density = 0
            end
        end
    else
        Lighting.FogEnd = PristineBaseline.FogEnd
        Lighting.FogStart = PristineBaseline.FogStart
        Lighting.FogColor = PristineBaseline.FogColor
        for atm, origDensity in pairs(PristineBaseline.Atmospheres) do
            if atm and atm.Parent then
                atm.Density = origDensity
            end
        end
    end
end

local ShaderPresets = {
    GoldenHour = {
        Skybox = {
            SkyboxBk = "http://www.roblox.com/asset/?id=144933338",
            SkyboxDn = "http://www.roblox.com/asset/?id=144931530",
            SkyboxFt = "http://www.roblox.com/asset/?id=144933262",
            SkyboxLf = "http://www.roblox.com/asset/?id=144933244",
            SkyboxRt = "http://www.roblox.com/asset/?id=144933299",
            SkyboxUp = "http://www.roblox.com/asset/?id=144931564",
            StarCount = 5000,
            SunAngularSize = 5
        },
        Bloom = {
            Intensity = 0.3,
            Size = 10,
            Threshold = 0.8
        },
        Blur = {
            Size = 5
        },
        ColorCorrection = {
            Brightness = 0,
            Contrast = 0.1,
            Saturation = 0.25,
            TintColor = Color3.fromRGB(255, 255, 255)
        },
        SunRays = {
            Intensity = 0.1,
            Spread = 0.8
        },
        Lighting = {
            Brightness = 2.25,
            ExposureCompensation = 0.1,
            ClockTime = 17.55
        }
    }
}

local function CreateShaderEffects()
    CapturePristineBaseline()

    if PristineBaseline.OriginalSky and PristineBaseline.OriginalSky.Parent == Lighting then
        PristineBaseline.OriginalSky.Parent = nil
    end

    for _, item in ipairs(PristineBaseline.OriginalEffects) do
        if item.Instance and item.Instance.Parent then
            pcall(function() item.Instance.Enabled = false end)
        end
    end

    local preset = ShaderPresets.GoldenHour

    local sky = Instance.new("Sky")
    sky.Name = "GoHubShader_Sky"
    sky:SetAttribute("GoHubShader", true)
    sky.SkyboxBk = preset.Skybox.SkyboxBk
    sky.SkyboxDn = preset.Skybox.SkyboxDn
    sky.SkyboxFt = preset.Skybox.SkyboxFt
    sky.SkyboxLf = preset.Skybox.SkyboxLf
    sky.SkyboxRt = preset.Skybox.SkyboxRt
    sky.SkyboxUp = preset.Skybox.SkyboxUp
    sky.StarCount = preset.Skybox.StarCount
    sky.SunAngularSize = preset.Skybox.SunAngularSize
    sky.Parent = Lighting
    ActiveShaderInstances["Sky"] = sky

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "GoHubShader_Bloom"
    bloom:SetAttribute("GoHubShader", true)
    bloom.Intensity = preset.Bloom.Intensity
    bloom.Size = preset.Bloom.Size
    bloom.Threshold = preset.Bloom.Threshold
    bloom.Parent = Lighting
    ActiveShaderInstances["Bloom"] = bloom

    local blur = Instance.new("BlurEffect")
    blur.Name = "GoHubShader_Blur"
    blur:SetAttribute("GoHubShader", true)
    blur.Size = preset.Blur.Size
    blur.Parent = Lighting
    ActiveShaderInstances["Blur"] = blur

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "GoHubShader_ColorCorrection"
    cc:SetAttribute("GoHubShader", true)
    cc.Brightness = preset.ColorCorrection.Brightness
    cc.Contrast = preset.ColorCorrection.Contrast
    cc.Saturation = preset.ColorCorrection.Saturation
    cc.TintColor = preset.ColorCorrection.TintColor
    cc.Parent = Lighting
    ActiveShaderInstances["ColorCorrection"] = cc

    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Name = "GoHubShader_SunRays"
    sunRays:SetAttribute("GoHubShader", true)
    sunRays.Intensity = preset.SunRays.Intensity
    sunRays.Spread = preset.SunRays.Spread
    sunRays.Parent = Lighting
    ActiveShaderInstances["SunRays"] = sunRays

    ReconcileLighting()
end

local function RemoveShaderEffects()
    for name, instance in pairs(ActiveShaderInstances) do
        if instance and instance.Parent then
            pcall(function() instance:Destroy() end)
        end
    end
    ActiveShaderInstances = {}

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:GetAttribute("GoHubShader") then
            pcall(function() obj:Destroy() end)
        end
    end

    if PristineBaseline.Captured then
        if PristineBaseline.OriginalSky and PristineBaseline.OriginalSky.Parent == nil then
            PristineBaseline.OriginalSky.Parent = Lighting
        end

        for _, item in ipairs(PristineBaseline.OriginalEffects) do
            if item.Instance and item.Instance.Parent then
                pcall(function() item.Instance.Enabled = item.OriginalEnabled end)
            end
        end
    end

    ReconcileLighting()
end

function LightingEngine.ToggleShader(enabled)
    HubState.Visuals.ShaderActive = enabled
    if enabled then
        CreateShaderEffects()
    else
        RemoveShaderEffects()
    end
end

function LightingEngine.ToggleFullbright(enabled)
    HubState.Visuals.FullbrightActive = enabled
    ReconcileLighting()
end

function LightingEngine.ToggleNoFog(enabled)
    HubState.Visuals.NoFogActive = enabled
    ReconcileLighting()
end

-- ====================================================================
-- COMBAT ENGINE (AIMBOT COM RAYCAST, FOV CHECK & CAMERA LERP)
-- ====================================================================
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

-- FOV Circle Visual Renderer (Drawing API ou Frame Fallback)
local DrawingFOVCircle = nil
pcall(function()
    if typeof(Drawing) == "table" and typeof(Drawing.new) == "function" then
        DrawingFOVCircle = Drawing.new("Circle")
        DrawingFOVCircle.Thickness = 1.5
        DrawingFOVCircle.NumSides = 64
        DrawingFOVCircle.Filled = false
        DrawingFOVCircle.Transparency = 1
        DrawingFOVCircle.Visible = false
    end
end)

local GuiFOVCircle = nil
if not DrawingFOVCircle then
    pcall(function()
        local fovGui = Instance.new("ScreenGui")
        fovGui.Name = "GoHub_FOV_Gui"
        fovGui.ResetOnSpawn = false
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(fovGui) end end)
        fovGui.Parent = GuiRoot

        GuiFOVCircle = Instance.new("Frame")
        GuiFOVCircle.Name = "FOVCircleFrame"
        GuiFOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
        GuiFOVCircle.BackgroundTransparency = 1
        GuiFOVCircle.Visible = false
        GuiFOVCircle.Parent = fovGui

        local corner = Instance.new("UICorner", GuiFOVCircle)
        corner.CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke", GuiFOVCircle)
        stroke.Thickness = 1.5
        stroke.Color = HubState.Theme.Accent
    end)
end

RegisterLoop("Aimbot_Render", RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera or Camera
    local mousePos = UserInputService:GetMouseLocation()
    local fovRadius = HubState.Combat.FOV
    local showFOV = HubState.Combat.AimbotActive and HubState.Combat.FOVCircleVisible

    if DrawingFOVCircle then
        pcall(function()
            DrawingFOVCircle.Position = mousePos
            DrawingFOVCircle.Radius = fovRadius
            DrawingFOVCircle.Color = HubState.Theme.Accent
            DrawingFOVCircle.Visible = showFOV
        end)
    elseif GuiFOVCircle then
        pcall(function()
            GuiFOVCircle.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
            GuiFOVCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
            GuiFOVCircle.Visible = showFOV
        end)
    end

    if not HubState.Combat.AimbotActive then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local target = CombatEngine.GetBestTarget()
    if target and cam then
        local camCF = cam.CFrame
        local targetCF = CFrame.new(camCF.Position, target.Position)
        cam.CFrame = camCF:Lerp(targetCF, math.clamp(HubState.Combat.Smoothness, 0.05, 1))
    end
end))

local XRayEngine = {}
local SavedTransparencies = {}

function XRayEngine.Toggle(enabled)
    HubState.Visuals.XRayActive = enabled
    if enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not (LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character)) then
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

-- ====================================================================
-- UNIVERSAL ESP (CHAMS ROXO DE ALTO RENDIMENTO COM CACHE DE HIGHLIGHT)
-- ====================================================================
local UniversalESPFolder = Instance.new("Folder")
UniversalESPFolder.Name = "GoHub_Universal_ESP"
pcall(function() UniversalESPFolder.Parent = GuiRoot end)

local UniversalESPCache = {}

local function ClearPlayerESP(p)
    if UniversalESPCache[p] then
        pcall(function() UniversalESPCache[p]:Destroy() end)
        UniversalESPCache[p] = nil
    end
end

local function UpdateUniversalESP(enabled)
    HubState.Visuals.UniversalESP = enabled
    if not enabled then
        DropLoop("Universal_ESP_Loop")
        for p, hl in pairs(UniversalESPCache) do
            if hl and hl.Parent then pcall(function() hl:Destroy() end) end
        end
        table.clear(UniversalESPCache)
        pcall(function() UniversalESPFolder:ClearAllChildren() end)
        return
    end

    RegisterLoop("Universal_ESP_Loop", RunService.Heartbeat:Connect(function()
        if not HubState.Visuals.UniversalESP then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then
                    local hl = UniversalESPCache[p]
                    if not hl or not hl.Parent then
                        ClearPlayerESP(p)
                        local newHl = Instance.new("Highlight")
                        newHl.Name = "UniESP_" .. p.Name
                        newHl.Adornee = p.Character
                        newHl.FillColor = HubState.Theme.Accent or Color3.fromRGB(148, 0, 211)
                        newHl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        newHl.FillTransparency = 0.45
                        newHl.OutlineTransparency = 0.1
                        newHl.Parent = UniversalESPFolder
                        UniversalESPCache[p] = newHl
                    elseif hl.Adornee ~= p.Character then
                        hl.Adornee = p.Character
                    end
                else
                    ClearPlayerESP(p)
                end
            else
                ClearPlayerESP(p)
            end
        end

        for p, _ in pairs(UniversalESPCache) do
            if not p.Parent then ClearPlayerESP(p) end
        end
    end))
end

-- ====================================================================
-- MURDER MYSTERY 2 SUITE COMPLETO
-- ====================================================================
local MM2Engine = {}
local MM2RoleFolder = Instance.new("Folder")
MM2RoleFolder.Name = "GoHub_MM2_Roles"
pcall(function() MM2RoleFolder.Parent = (Workspace or GuiRoot) end)

local MM2CoinFolder = Instance.new("Folder")
MM2CoinFolder.Name = "GoHub_MM2_Coins"
pcall(function() MM2CoinFolder.Parent = (Workspace or GuiRoot) end)

local MM2HitboxFolder = Instance.new("Folder")
MM2HitboxFolder.Name = "GoHub_MM2_Hitboxes"
pcall(function() MM2HitboxFolder.Parent = (Workspace or GuiRoot) end)

local MM2RoleDataCache = {}
local MM2DroppedGun = nil
local lastRemotePoll = 0
local remoteListenersSetup = false
local playerCharConnections = {}

-- Dicionario exaustivo de armas MM2 (Godlies, Antigos, Cromas, Natal, Halloween)
local KNIFE_NAMES = {
    ["knife"] = true, ["defaultknife"] = true, ["blade"] = true, ["dagger"] = true,
    ["sword"] = true, ["scythe"] = true, ["pitchfork"] = true, ["katana"] = true,
    ["slasher"] = true, ["cleaver"] = true, ["cutter"] = true, ["axe"] = true,
    ["saw"] = true, ["sickle"] = true, ["bat"] = true, ["spear"] = true,
    ["corrupt"] = true, ["icebreaker"] = true, ["candy"] = true, ["lugercane"] = true,
    ["ghostblade"] = true, ["boneblade"] = true, ["hallowblade"] = true, ["plasmablade"] = true,
    ["darksword"] = true, ["heat"] = true, ["tides"] = true, ["pixel"] = true,
    ["spider"] = true, ["clockwork"] = true, ["fang"] = true, ["frostbite"] = true,
    ["icedragon"] = true, ["winter"] = true, ["chill"] = true, ["flames"] = true,
    ["pumpking"] = true, ["gingerbread"] = true, ["battleaxe"] = true, ["deathshard"] = true,
    ["hallows"] = true, ["nebula"] = true, ["waves"] = true, ["candleflame"] = true,
    ["icewing"] = true, ["vampire"] = true, ["heartblade"] = true, ["cookieblade"] = true,
    ["gingerscythe"] = true, ["hallowscythe"] = true, ["elderwood scythe"] = true,
    ["spectral"] = true, ["splitter"] = true, ["ghost"] = true, ["traveller"] = true
}

local GUN_NAMES = {
    ["gun"] = true, ["defaultgun"] = true, ["revolver"] = true, ["pistol"] = true,
    ["blaster"] = true, ["luger"] = true, ["shotgun"] = true, ["laser"] = true,
    ["crossbow"] = true, ["bow"] = true, ["glock"] = true, ["amerilaser"] = true,
    ["old glory"] = true, ["plasmabeam"] = true, ["gingermint"] = true, ["swirly gun"] = true,
    ["ocean"] = true, ["lightbringer"] = true, ["darkbringer"] = true, ["iceblaster"] = true,
    ["red luger"] = true, ["green luger"] = true, ["ginger luger"] = true, ["sugar"] = true,
    ["shark"] = true, ["flamethrower"] = true, ["watergun"] = true, ["harvester"] = true,
    ["elderwood revolver"] = true, ["vampires edge"] = true, ["hallowgun"] = true
}

local function isKnifeItem(item)
    if not item or not item:IsA("Tool") then return false end
    local n = item.Name:lower()
    if KNIFE_NAMES[n] then return true end
    for kName in pairs(KNIFE_NAMES) do
        if n:find(kName, 1, true) then return true end
    end
    if item:FindFirstChild("KnifeServer") or item:FindFirstChild("KnifeScript") or item:FindFirstChild("KnifeClient")
       or item:FindFirstChild("Slash") or item:FindFirstChild("Stab") or item:FindFirstChild("Throw")
       or item:GetAttribute("WeaponType") == "Knife" or item:GetAttribute("Type") == "Knife" then
        return true
    end
    local handle = item:FindFirstChild("Handle")
    if handle and (handle:FindFirstChild("Slash") or handle:FindFirstChild("Stab") or handle:FindFirstChild("Throw")) then
        return true
    end
    return false
end

local function isGunItem(item)
    if not item or not item:IsA("Tool") then return false end
    local n = item.Name:lower()
    if GUN_NAMES[n] then return true end
    for gName in pairs(GUN_NAMES) do
        if n:find(gName, 1, true) then return true end
    end
    if item:FindFirstChild("GunServer") or item:FindFirstChild("GunScript") or item:FindFirstChild("GunClient")
       or item:FindFirstChild("Shoot") or item:FindFirstChild("Fire") or item:FindFirstChild("Reload")
       or item:GetAttribute("WeaponType") == "Gun" or item:GetAttribute("Type") == "Gun" then
        return true
    end
    local handle = item:FindFirstChild("Handle")
    if handle and (handle:FindFirstChild("Shoot") or handle:FindFirstChild("GunDrop") or handle:FindFirstChild("Fire")) then
        return true
    end
    return false
end

local function connectPlayerWeapons(p)
    if not p or playerCharConnections[p] then return end

    local function scanChar(char)
        if not char then return end
        for _, child in ipairs(char:GetChildren()) do
            if isKnifeItem(child) then
                MM2RoleDataCache[p.Name:lower()] = "MURDER"
                MM2RoleDataCache[tostring(p.UserId)] = "MURDER"
            elseif isGunItem(child) then
                local r = MM2DroppedGun and "HEROI" or "SHERIFE"
                MM2RoleDataCache[p.Name:lower()] = r
                MM2RoleDataCache[tostring(p.UserId)] = r
            end
        end

        char.ChildAdded:Connect(function(child)
            if isKnifeItem(child) then
                MM2RoleDataCache[p.Name:lower()] = "MURDER"
                MM2RoleDataCache[tostring(p.UserId)] = "MURDER"
            elseif isGunItem(child) then
                local r = MM2DroppedGun and "HEROI" or "SHERIFE"
                MM2RoleDataCache[p.Name:lower()] = r
                MM2RoleDataCache[tostring(p.UserId)] = r
            end
        end)
    end

    local function scanBackpack(bp)
        if not bp then return end
        for _, child in ipairs(bp:GetChildren()) do
            if isKnifeItem(child) then
                MM2RoleDataCache[p.Name:lower()] = "MURDER"
                MM2RoleDataCache[tostring(p.UserId)] = "MURDER"
            elseif isGunItem(child) then
                MM2RoleDataCache[p.Name:lower()] = "SHERIFE"
                MM2RoleDataCache[tostring(p.UserId)] = "SHERIFE"
            end
        end
        bp.ChildAdded:Connect(function(child)
            if isKnifeItem(child) then
                MM2RoleDataCache[p.Name:lower()] = "MURDER"
                MM2RoleDataCache[tostring(p.UserId)] = "MURDER"
            elseif isGunItem(child) then
                MM2RoleDataCache[p.Name:lower()] = "SHERIFE"
                MM2RoleDataCache[tostring(p.UserId)] = "SHERIFE"
            end
        end)
    end

    if p.Character then scanChar(p.Character) end
    local cConn = p.CharacterAdded:Connect(scanChar)
    local bp = p:FindFirstChild("Backpack")
    if bp then scanBackpack(bp) end
    local bpConn = p.ChildAdded:Connect(function(c)
        if c:IsA("Backpack") then scanBackpack(c) end
    end)

    playerCharConnections[p] = { cConn, bpConn }
end

local function disconnectPlayerWeapons(p)
    local conns = playerCharConnections[p]
    if conns then
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        playerCharConnections[p] = nil
    end
end

local function SetupMM2RemoteListeners()
    if remoteListenersSetup then return end
    remoteListenersSetup = true

    pcall(function()
        local repStorage = game:GetService("ReplicatedStorage")
        local remotesFolder = repStorage:FindFirstChild("Remotes")
        local gameplayFolder = remotesFolder and remotesFolder:FindFirstChild("Gameplay")

        local function attachRemoteEvent(rem)
            if rem and rem:IsA("RemoteEvent") then
                rem.OnClientEvent:Connect(function(...)
                    local args = {...}
                    for _, arg in ipairs(args) do
                        if type(arg) == "table" then
                            for k, v in pairs(arg) do
                                local targetName = type(k) == "string" and k or (type(v) == "table" and (v.Player or v.Name or v.Username))
                                local roleStr = type(v) == "table" and (v.Role or v.role) or (type(v) == "string" and v)
                                if targetName and roleStr and type(roleStr) == "string" then
                                    local lowerRole = roleStr:lower()
                                    if lowerRole:find("murd") then
                                        MM2RoleDataCache[tostring(targetName):lower()] = "MURDER"
                                    elseif lowerRole:find("sher") then
                                        MM2RoleDataCache[tostring(targetName):lower()] = "SHERIFE"
                                    elseif lowerRole:find("hero") then
                                        MM2RoleDataCache[tostring(targetName):lower()] = "HEROI"
                                    elseif lowerRole:find("innoc") then
                                        MM2RoleDataCache[tostring(targetName):lower()] = "INOCENTE"
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end

        if gameplayFolder then
            for _, child in ipairs(gameplayFolder:GetChildren()) do attachRemoteEvent(child) end
            gameplayFolder.ChildAdded:Connect(attachRemoteEvent)
        end
        if remotesFolder then
            for _, child in ipairs(remotesFolder:GetChildren()) do attachRemoteEvent(child) end
        end
    end)
end

local function PollMM2Remotes()
    local now = tick()
    if now - lastRemotePoll < 2.0 then return end
    lastRemotePoll = now

    task.spawn(function()
        pcall(function()
            local repStorage = game:GetService("ReplicatedStorage")
            local remotesFolder = repStorage:FindFirstChild("Remotes")
            local gameplayFolder = remotesFolder and remotesFolder:FindFirstChild("Gameplay")
            local getPlayerData = (gameplayFolder and gameplayFolder:FindFirstChild("GetPlayerData"))
                or (remotesFolder and remotesFolder:FindFirstChild("GetPlayerData"))
                or repStorage:FindFirstChild("GetPlayerData", true)

            if getPlayerData and getPlayerData:IsA("RemoteFunction") then
                local data = getPlayerData:InvokeServer()
                if type(data) == "table" then
                    for k, v in pairs(data) do
                        local playerName = type(k) == "string" and k or (type(v) == "table" and (v.Player or v.Name or v.Username))
                        local roleStr = type(v) == "table" and (v.Role or v.role) or (type(v) == "string" and v)
                        if playerName and roleStr and type(roleStr) == "string" then
                            local lower = roleStr:lower()
                            if lower:find("murd") then
                                MM2RoleDataCache[tostring(playerName):lower()] = "MURDER"
                            elseif lower:find("sher") then
                                MM2RoleDataCache[tostring(playerName):lower()] = "SHERIFE"
                            elseif lower:find("hero") then
                                MM2RoleDataCache[tostring(playerName):lower()] = "HEROI"
                            elseif lower:find("innoc") then
                                MM2RoleDataCache[tostring(playerName):lower()] = "INOCENTE"
                            end
                        end
                    end
                end
            end
        end)
    end)
end

local function DetectRole(p)
    if not p then return nil end

    local pNameLower = p.Name:lower()
    local pUserIdStr = tostring(p.UserId)
    local cachedRole = MM2RoleDataCache[pNameLower] or MM2RoleDataCache[pUserIdStr]

    if cachedRole == "MURDER" then
        return "MURDER", HubState.Theme.Murderer or Color3.fromRGB(255, 35, 35)
    elseif cachedRole == "SHERIFE" then
        return "SHERIFE", HubState.Theme.Sheriff or Color3.fromRGB(40, 140, 255)
    elseif cachedRole == "HEROI" then
        return "HEROI", Color3.fromRGB(255, 215, 0)
    end

    if p.Character then
        for _, item in ipairs(p.Character:GetChildren()) do
            if isKnifeItem(item) then
                MM2RoleDataCache[pNameLower] = "MURDER"
                MM2RoleDataCache[pUserIdStr] = "MURDER"
                return "MURDER", HubState.Theme.Murderer or Color3.fromRGB(255, 35, 35)
            elseif isGunItem(item) then
                local r = MM2DroppedGun and "HEROI" or "SHERIFE"
                MM2RoleDataCache[pNameLower] = r
                MM2RoleDataCache[pUserIdStr] = r
                local col = (r == "HEROI") and Color3.fromRGB(255, 215, 0) or (HubState.Theme.Sheriff or Color3.fromRGB(40, 140, 255))
                return r, col
            end
        end
    end

    local bp = p:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if isKnifeItem(item) then
                MM2RoleDataCache[pNameLower] = "MURDER"
                MM2RoleDataCache[pUserIdStr] = "MURDER"
                return "MURDER", HubState.Theme.Murderer or Color3.fromRGB(255, 35, 35)
            elseif isGunItem(item) then
                MM2RoleDataCache[pNameLower] = "SHERIFE"
                MM2RoleDataCache[pUserIdStr] = "SHERIFE"
                return "SHERIFE", HubState.Theme.Sheriff or Color3.fromRGB(40, 140, 255)
            end
        end
    end

    return "INOCENTE", HubState.Theme.Innocent or Color3.fromRGB(40, 220, 100)
end

local droppedGunESP = nil

local function UpdateGunDropESP()
    local drop = Workspace:FindFirstChild("GunDrop") or Workspace:FindFirstChild("Gun", true)
    if drop and (drop:IsA("BasePart") or (drop:IsA("Model") and drop.PrimaryPart)) then
        MM2DroppedGun = drop
        local targetPart = drop:IsA("BasePart") and drop or drop.PrimaryPart
        if not droppedGunESP or not droppedGunESP.Billboard or not droppedGunESP.Billboard.Parent then
            if droppedGunESP then
                if HubState.ReleaseHighlight then
                    HubState.ReleaseHighlight(droppedGunESP.Highlight)
                elseif _G.HighlightPool and _G.HighlightPool.ReleaseHighlight then
                    _G.HighlightPool.ReleaseHighlight(droppedGunESP.Highlight)
                else
                    pcall(function() droppedGunESP.Highlight:Destroy() end)
                end
                pcall(function() droppedGunESP.Billboard:Destroy() end)
            end

            local hl = (HubState.AcquireHighlight and HubState.AcquireHighlight(drop, 1, Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255)))
                or (_G.HighlightPool and _G.HighlightPool.AcquireHighlight and _G.HighlightPool.AcquireHighlight(drop, 1, Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255)))

            local bb = Instance.new("BillboardGui")
            bb.Name = "MM2_GunDrop_BB"
            bb.Adornee = targetPart
            bb.Size = UDim2.new(0, 160, 0, 40)
            bb.StudsOffset = Vector3.new(0, 2.0, 0)
            bb.AlwaysOnTop = true
            pcall(function() bb.Parent = MM2RoleFolder end)

            local txt = Instance.new("TextLabel", bb)
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextColor3 = Color3.fromRGB(255, 215, 0)
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 13
            txt.TextStrokeTransparency = 0.2
            txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            txt.Text = "★ ARMA CAÍDA [PEGAR!] ★"

            droppedGunESP = { Highlight = hl, Billboard = bb }
        end
    else
        MM2DroppedGun = nil
        if droppedGunESP then
            if HubState.ReleaseHighlight then
                HubState.ReleaseHighlight(droppedGunESP.Highlight)
            elseif _G.HighlightPool and _G.HighlightPool.ReleaseHighlight then
                _G.HighlightPool.ReleaseHighlight(droppedGunESP.Highlight)
            else
                pcall(function() droppedGunESP.Highlight:Destroy() end)
            end
            pcall(function() droppedGunESP.Billboard:Destroy() end)
            droppedGunESP = nil
        end
    end
end

function MM2Engine.ToggleRoleESP(enabled)
    HubState.MM2.RoleESP = enabled
    if not enabled then
        DropLoop("MM2_RoleLoop")
        MM2RoleFolder:ClearAllChildren()
        table.clear(MM2RoleDataCache)
        if droppedGunESP then
            if HubState.ReleaseHighlight then
                HubState.ReleaseHighlight(droppedGunESP.Highlight)
            elseif _G.HighlightPool and _G.HighlightPool.ReleaseHighlight then
                _G.HighlightPool.ReleaseHighlight(droppedGunESP.Highlight)
            else
                pcall(function() droppedGunESP.Highlight:Destroy() end)
            end
            pcall(function() droppedGunESP.Billboard:Destroy() end)
            droppedGunESP = nil
        end
        for p, _ in pairs(playerCharConnections) do
            disconnectPlayerWeapons(p)
        end
        return
    end

    SetupMM2RemoteListeners()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            connectPlayerWeapons(p)
        end
    end

    local playerESP = {}

    local function cleanupESP(p)
        local data = playerESP[p]
        if data then
            if HubState.ReleaseHighlight then
                HubState.ReleaseHighlight(data.Highlight)
            elseif _G.HighlightPool and _G.HighlightPool.ReleaseHighlight then
                _G.HighlightPool.ReleaseHighlight(data.Highlight)
            else
                pcall(function() data.Highlight:Destroy() end)
            end
            pcall(function() data.Billboard:Destroy() end)
            playerESP[p] = nil
        end
    end

    RegisterLoop("MM2_RoleLoop", RunService.Heartbeat:Connect(function()
        if not HubState.MM2.RoleESP then return end
        PollMM2Remotes()
        UpdateGunDropESP()

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    connectPlayerWeapons(p)
                    local role, color = DetectRole(p)
                    local data = playerESP[p]

                    if not data or not data.Highlight or not data.Billboard or not data.Billboard.Parent then
                        cleanupESP(p)

                        local roleHl = (HubState.AcquireHighlight and HubState.AcquireHighlight(p.Character, 2, color, color))
                            or (_G.HighlightPool and _G.HighlightPool.AcquireHighlight and _G.HighlightPool.AcquireHighlight(p.Character, 2, color, color))

                        local bgui = Instance.new("BillboardGui")
                        bgui.Name = "MM2_BB_" .. p.Name
                        bgui.Adornee = p.Character.Head
                        bgui.Size = UDim2.new(0, 140, 0, 40)
                        bgui.StudsOffset = Vector3.new(0, 2.6, 0)
                        bgui.AlwaysOnTop = true
                        pcall(function() bgui.Parent = MM2RoleFolder end)

                        local txt = Instance.new("TextLabel", bgui)
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.BackgroundTransparency = 1
                        txt.TextColor3 = color
                        txt.Font = Enum.Font.GothamBold
                        txt.TextSize = 13
                        txt.TextStrokeTransparency = 0.2
                        txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        txt.Text = "[" .. role .. "] " .. p.DisplayName

                        playerESP[p] = { Highlight = roleHl, Billboard = bgui, Label = txt, CurrentRole = role }
                    else
                        if data.Highlight and data.Highlight.Adornee ~= p.Character then
                            data.Highlight.Adornee = p.Character
                            data.Billboard.Adornee = p.Character.Head
                        end

                        if data.CurrentRole ~= role then
                            data.CurrentRole = role
                            if data.Highlight then
                                data.Highlight.FillColor = color
                                data.Highlight.OutlineColor = color
                                data.Highlight.FillTransparency = (role == "INOCENTE") and 0.65 or 0.35
                            end
                            data.Label.TextColor3 = color
                            data.Label.Text = "[" .. role .. "] " .. p.DisplayName
                        end
                    end
                else
                    cleanupESP(p)
                end
            else
                cleanupESP(p)
            end
        end

        for p, _ in pairs(playerESP) do
            if not p.Parent then
                cleanupESP(p)
                disconnectPlayerWeapons(p)
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
-- SKIN & MORPH SUITE
-- ====================================================================
local SkinEngine = {}

function SkinEngine.ScanAndFireRemote(targetUserId)
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
        for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do checkObj(obj) end
        for _, obj in ipairs(game:GetService("JointsService"):GetDescendants()) do checkObj(obj) end
    end)

    for _, rem in ipairs(remotesToTest) do
        local ok = pcall(function()
            if rem:IsA("RemoteEvent") then
                if targetUserId then
                    rem:FireServer(targetUserId)
                    rem:FireServer("Character", targetUserId)
                    rem:FireServer("Morph", targetUserId)
                end
            elseif rem:IsA("RemoteFunction") then
                if targetUserId then
                    task.spawn(function() pcall(function() rem:InvokeServer(targetUserId) end) end)
                end
            end
        end)
        if ok then found = true end
    end
    return found
end

function SkinEngine.ClonePlayerSkin(targetPlayer)
    if not targetPlayer then return false, "Jogador não especificado" end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false, "Humanoid não encontrado" end

    if not HubState.Skin.OriginalDesc then
        pcall(function() HubState.Skin.OriginalDesc = hum:GetAppliedDescription() end)
    end

    local targetUserId = targetPlayer.UserId
    SkinEngine.ScanAndFireRemote(targetUserId)

    local successDesc, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(targetUserId)
    end)

    if successDesc and desc then
        pcall(function() hum:ApplyDescription(desc) end)
        return true, "Skin clonada com sucesso de @" .. targetPlayer.Name
    end

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

function SkinEngine.ApplyByUserId(userId)
    local numId = tonumber(userId)
    if not numId then return false, "ID inválido" end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false, "Humanoid não encontrado" end

    if not HubState.Skin.OriginalDesc then
        pcall(function() HubState.Skin.OriginalDesc = hum:GetAppliedDescription() end)
    end

    SkinEngine.ScanAndFireRemote(numId)

    local success, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(numId)
    end)
    if success and desc then
        pcall(function() hum:ApplyDescription(desc) end)
        return true, "Skin aplicada para o ID: " .. tostring(numId)
    else
        return false, "Não foi possível carregar o ID do avatar"
    end
end

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
                child.Scale = enabled and Vector3.new(0.001, 0.001, 0.001) or Vector3.new(1.25, 1.25, 1.25)
            end
        end
    end
end

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

function SkinEngine.ResetAvatar()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and HubState.Skin.OriginalDesc then
        pcall(function() hum:ApplyDescription(HubState.Skin.OriginalDesc) end)
    end
    SkinEngine.ToggleHeadless(false)
    SkinEngine.ToggleKorblox(false)
end

-- ====================================================================
-- MOTOR DE ANIMAÇÕES & DANÇAS (JAMAL VIRAL, IY & PRESETS)
-- ====================================================================
local AnimationEngine = {}

local DualEmoteDatabase = {
    ["Passinho do Jamal (Principal)"] = { R15 = "rbxassetid://131086670591743" },
    ["Passinho do Jamal (Fogo Fogo)"] = { R15 = "rbxassetid://101508054279219" },
    ["Passinho do Jamal (Kitsi UGC)"] = { R15 = "rbxassetid://90852521137542" },
    ["Passinho do Jamal (Mandrake)"] = { R15 = "rbxassetid://95654893473488" },
    ["Passinho do Jamal (Dance Moves)"] = { R15 = "rbxassetid://121260976461862" },

    ["IY Dança 1 (Breakdance)"] = { R15 = "rbxassetid://3333432454" },
    ["IY Dança 2 (Pop & Lock)"] = { R15 = "rbxassetid://4555808220" },
    ["IY Dança 3 (Hip Hop / Hype)"] = { R15 = "rbxassetid://4049037604" },
    ["IY Dança 4 (Wave Step)"] = { R15 = "rbxassetid://4555782893" },
    ["IY Dança 5 (Freestyle)"] = { R15 = "rbxassetid://10214311282" },

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
        pcall(function() HubState.Animation.CurrentTrack:AdjustSpeed(HubState.Animation.Speed) end)
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

    -- Pipeline 1: Animation Instance direta
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. cleanId
    local s1, t1 = pcall(function() return animator:LoadAnimation(anim) end)
    if s1 and t1 then track = t1 end

    -- Pipeline 2: GetObjects para unpack de UGC / Bundles
    if not track or (track and track.Length == 0) then
        local sObjs, objs = pcall(function() return game:GetObjects("rbxassetid://" .. cleanId) end)
        if sObjs and objs and #objs > 0 then
            for _, obj in ipairs(objs) do
                local found = (obj:IsA("Animation") and obj) or obj:FindFirstChildOfClass("Animation", true)
                if found and found.AnimationId and found.AnimationId ~= "" then
                    local s2, t2 = pcall(function() return animator:LoadAnimation(found) end)
                    if s2 and t2 then track = t2; break end
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
    if not targetId and isR15 then targetId = entry.R15
    elseif not targetId and not isR15 then targetId = entry.R6 or entry.R15 end

    if targetId then AnimationEngine.PlayRaw(targetId, emoteName) end
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

    table.insert(HubState.CustomDances, { Name = name, ID = cleanId })

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
                pcall(function() writefile("gohub_custom_dances.json", HttpService:JSONEncode(HubState.CustomDances)) end)
            end
            return true
        end
    elseif type(nameOrIndex) == "string" then
        for i = #HubState.CustomDances, 1, -1 do
            if HubState.CustomDances[i].Name:lower() == nameOrIndex:lower() then
                table.remove(HubState.CustomDances, i)
                if writefile then
                    pcall(function() writefile("gohub_custom_dances.json", HttpService:JSONEncode(HubState.CustomDances)) end)
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
            if type(data) == "table" then HubState.CustomDances = data end
        end
    end)
end
AnimationEngine.LoadSavedDances()

local DefaultRadialSlots = {
    [1] = { Name = "Jamal (Principal)", ID = "131086670591743" },
    [2] = { Name = "Passinho Fogo", ID = "101508054279219" },
    [3] = { Name = "Floss", ID = "10714340543" },
    [4] = { Name = "Breakdance (IY)", ID = "3333432454" },
    [5] = { Name = "Pop & Lock (IY)", ID = "4555808220" },
    [6] = { Name = "Hip Hop (IY)", ID = "4049037604" },
    [7] = { Name = "SpiderTree", ID = "3361426436" },
    [8] = { Name = "Spin Dance", ID = "3361481910" }
}

function AnimationEngine.SaveRadialSlots()
    pcall(function()
        if typeof(writefile) == "function" then
            local payload = HttpService:JSONEncode(HubState.Radial.Slots)
            writefile("gohub_radial_slots.json", payload)
        end
    end)
end

function AnimationEngine.LoadRadialSlots()
    pcall(function()
        if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile("gohub_radial_slots.json") then
            local raw = readfile("gohub_radial_slots.json")
            local data = HttpService:JSONDecode(raw)
            if type(data) == "table" then
                for i = 1, 8 do
                    local slotEntry = data[tostring(i)] or data[i]
                    if slotEntry and type(slotEntry) == "table" then
                        HubState.Radial.Slots[i] = {
                            Name = tostring(slotEntry.Name or "(Vazio)"),
                            ID = slotEntry.ID and tostring(slotEntry.ID) or nil
                        }
                    end
                end
            end
        end
    end)
end
AnimationEngine.LoadRadialSlots()

function AnimationEngine.SetRadialSlot(slotNum, name, id)
    slotNum = tonumber(slotNum)
    if not slotNum or slotNum < 1 or slotNum > 8 then return false, "Slot inválido (1 a 8)" end
    HubState.Radial.Slots[slotNum] = {
        Name = tostring(name or "(Vazio)"),
        ID = id and tostring(id) or nil
    }
    AnimationEngine.SaveRadialSlots()
    return true
end

function AnimationEngine.ResetRadialSlots()
    for i = 1, 8 do
        HubState.Radial.Slots[i] = {
            Name = DefaultRadialSlots[i].Name,
            ID = DefaultRadialSlots[i].ID
        }
    end
    AnimationEngine.SaveRadialSlots()
end

function AnimationEngine.GetRadialEmotes()
    local list = {}
    for i = 1, 8 do
        local slotData = HubState.Radial.Slots[i]
        if slotData and slotData.ID and slotData.ID ~= "" then
            table.insert(list, slotData)
        else
            table.insert(list, { Name = "(Vazio)", ID = nil })
        end
    end
    return list
end

-- ====================================================================
-- RODA RADIAL CIRCULAR DE EMOTES (ROBLOX NATIVE WHEEL — TECLA 'C')
-- ====================================================================
local RadialBackdrop = Instance.new("Frame")
RadialBackdrop.Name = "GoHubRadialBackdrop"
RadialBackdrop.Size = UDim2.new(1, 0, 1, 0)
RadialBackdrop.Position = UDim2.new(0, 0, 0, 0)
RadialBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
RadialBackdrop.BackgroundTransparency = 1
RadialBackdrop.Visible = false
RadialBackdrop.ZIndex = 200

local RadialWheel = Instance.new("Frame")
RadialWheel.Name = "RadialWheel"
RadialWheel.Size = UDim2.new(0, 0, 0, 0)
RadialWheel.Position = UDim2.new(0.5, 0, 0.5, 0)
RadialWheel.AnchorPoint = Vector2.new(0.5, 0.5)
RadialWheel.BackgroundColor3 = HubState.Theme.Sidebar
RadialWheel.BackgroundTransparency = 0.15
RadialWheel.BorderSizePixel = 0
RadialWheel.ZIndex = 201
RadialWheel.Parent = RadialBackdrop

Instance.new("UICorner", RadialWheel).CornerRadius = UDim.new(1, 0)
local WheelStroke = Instance.new("UIStroke", RadialWheel)
WheelStroke.Color = HubState.Theme.AccentGlow
WheelStroke.Thickness = 2.5

local WheelCenterBadge = Instance.new("Frame")
WheelCenterBadge.Size = UDim2.new(0, 75, 0, 75)
WheelCenterBadge.Position = UDim2.new(0.5, 0, 0.5, 0)
WheelCenterBadge.AnchorPoint = Vector2.new(0.5, 0.5)
WheelCenterBadge.BackgroundColor3 = HubState.Theme.Card
WheelCenterBadge.ZIndex = 203
WheelCenterBadge.Parent = RadialWheel
Instance.new("UICorner", WheelCenterBadge).CornerRadius = UDim.new(1, 0)

local WheelCenterLabel = Instance.new("TextLabel")
WheelCenterLabel.Size = UDim2.new(1, 0, 1, 0)
WheelCenterLabel.BackgroundTransparency = 1
WheelCenterLabel.Font = Enum.Font.GothamBold
WheelCenterLabel.Text = "GOHUB\nEMOTES"
WheelCenterLabel.TextColor3 = HubState.Theme.AccentGlow
WheelCenterLabel.TextSize = 11
WheelCenterLabel.ZIndex = 204
WheelCenterLabel.Parent = WheelCenterBadge

local SlotsContainer = Instance.new("Frame")
SlotsContainer.Size = UDim2.new(1, 0, 1, 0)
SlotsContainer.BackgroundTransparency = 1
SlotsContainer.ZIndex = 202
SlotsContainer.Parent = RadialWheel

local CurrentRadialEmotes = {}

local function ToggleRadialMenu(forceState)
    local state = (forceState ~= nil) and forceState or not HubState.Radial.Visible
    HubState.Radial.Visible = state

    if state then
        SlotsContainer:ClearAllChildren()
        CurrentRadialEmotes = AnimationEngine.GetRadialEmotes()

        local radius = 110
        for i = 1, 8 do
            local emoteData = CurrentRadialEmotes[i]
            local angleDeg = (i - 1) * 45 - 90
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

            slotBtn.MouseButton1Click:Connect(function()
                if emoteData and emoteData.ID and emoteData.ID ~= "" then
                    AnimationEngine.PlayRaw(emoteData.ID, emoteData.Name)
                end
                ToggleRadialMenu(false)
            end)
        end

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
            if not HubState.Radial.Visible then RadialBackdrop.Visible = false end
        end)
    end
end

RadialBackdrop.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = Vector2.new(input.Position.X, input.Position.Y)
        local centerPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local dist = (mousePos - centerPos).Magnitude
        if dist > 175 then ToggleRadialMenu(false) end
    end
end)

-- ====================================================================
-- COMMAND BAR RETRÁTIL DO INFINITE YIELD
-- ====================================================================
local CmdBarScreen = Instance.new("ScreenGui")
CmdBarScreen.Name = "GoHub_CmdBar_Screen"
CmdBarScreen.ResetOnSpawn = false
CmdBarScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() CmdBarScreen.Parent = GuiRoot end)
RadialBackdrop.Parent = CmdBarScreen

local CmdBarFrame = Instance.new("Frame")
CmdBarFrame.Name = "GoHubCmdBar"
CmdBarFrame.Size = UDim2.new(0, 480, 0, 42)
CmdBarFrame.Position = UDim2.new(0.5, -240, 0, -60)
CmdBarFrame.BackgroundColor3 = HubState.Theme.Background
CmdBarFrame.BorderSizePixel = 0
CmdBarFrame.ZIndex = 220
CmdBarFrame.Parent = CmdBarScreen

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
CmdPrefixLabel.ZIndex = 221
CmdPrefixLabel.Parent = CmdBarFrame

local CmdInput = Instance.new("TextBox")
CmdInput.Size = UDim2.new(1, -40, 1, 0)
CmdInput.Position = UDim2.new(0, 30, 0, 0)
CmdInput.BackgroundTransparency = 1
CmdInput.Font = Enum.Font.GothamSemibold
CmdInput.PlaceholderText = "Digite um comando... (ex: fly, tp fer, speed 50, fling random, kick)"
CmdInput.PlaceholderColor3 = HubState.Theme.TextDim
CmdInput.Text = ""
CmdInput.TextColor3 = HubState.Theme.Text
CmdInput.TextSize = 13
CmdInput.TextXAlignment = Enum.TextXAlignment.Left
CmdInput.ClearTextOnFocus = false
CmdInput.ZIndex = 221
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

local function DispatchCommand(rawText)
    if not rawText or rawText == "" then return end
    local args = rawText:split(" ")
    local cmd = args[1]:lower()
    table.remove(args, 1)

    if cmd == "fly" then MovementEngine.SetFlight(true)
    elseif cmd == "unfly" then MovementEngine.SetFlight(false)
    elseif cmd == "speed" or cmd == "ws" then
        local spd = tonumber(args[1]) or 32
        HubState.Movement.Speed = spd
        HubState.Movement.SpeedActive = true
        MovementEngine.ApplySpeed()
    elseif cmd == "unspeed" then
        HubState.Movement.SpeedActive = false
        MovementEngine.ApplySpeed()
    elseif cmd == "noclip" then MovementEngine.SetNoclip(true)
    elseif cmd == "clip" then MovementEngine.SetNoclip(false)
    elseif cmd == "infjump" then MovementEngine.SetInfiniteJump(true)
    elseif cmd == "uninfjump" then MovementEngine.SetInfiniteJump(false)
    elseif cmd == "clicktp" then MovementEngine.SetClickTP(true)
    elseif cmd == "unclicktp" then MovementEngine.SetClickTP(false)
    elseif cmd == "tptool" then MovementEngine.GiveTPTool()
    elseif cmd == "tp" or cmd == "goto" then
        local targetName = args[1]
        local found = TargetParser.FindPlayers(targetName)
        if #found > 0 and found[1].Character and found[1].Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp then myHrp.CFrame = found[1].Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0) end
        end
    elseif cmd == "shader" or cmd == "rtx" or cmd == "graphics" then
        local sub = args[1] and args[1]:lower()
        if sub == "on" or sub == "true" or sub == "1" then
            LightingEngine.ToggleShader(true)
        elseif sub == "off" or sub == "false" or sub == "0" then
            LightingEngine.ToggleShader(false)
        else
            LightingEngine.ToggleShader(not HubState.Visuals.ShaderActive)
        end
    elseif cmd == "unshader" or cmd == "noshader" or cmd == "unrtx" then
        LightingEngine.ToggleShader(false)
    elseif cmd == "dropkick" or cmd == "kick" or cmd == "k" or cmd == "flingkick" then
        local force = tonumber(args[1])
        FlingEngine.PerformDropKick(force)
    elseif cmd == "fling" then
        local targetName = args[1]
        if targetName then
            local found = TargetParser.FindPlayers(targetName)
            if #found > 0 then FlingEngine.FlingTarget(found[1]) end
        else
            FlingEngine.ToggleSpinFling(true)
        end
    elseif cmd == "unfling" then
        FlingEngine.ToggleSpinFling(false)
        FlingEngine.ToggleWalkFling(false)
        FlingEngine.LoopFling(nil)
    elseif cmd == "walkfling" then FlingEngine.ToggleWalkFling(true)
    elseif cmd == "unwalkfling" then FlingEngine.ToggleWalkFling(false)
    elseif cmd == "antifling" then FlingEngine.ToggleAntiFling(true)
    elseif cmd == "unantifling" then FlingEngine.ToggleAntiFling(false)
    elseif cmd == "loopfling" then
        local targetName = args[1]
        local found = TargetParser.FindPlayers(targetName)
        if #found > 0 then FlingEngine.LoopFling(found[1]) end
    elseif cmd == "unloopfling" then FlingEngine.LoopFling(nil)
    elseif cmd == "fullbright" or cmd == "fb" then LightingEngine.ToggleFullbright(true)
    elseif cmd == "unfullbright" or cmd == "unfb" then LightingEngine.ToggleFullbright(false)
    elseif cmd == "nofog" then LightingEngine.ToggleNoFog(true)
    elseif cmd == "dance" then
        local emoteName = args[1]
        if emoteName then
            if tonumber(emoteName) then AnimationEngine.PlayRaw(emoteName, "Custom_" .. emoteName)
            else AnimationEngine.Play(emoteName) end
        end
    elseif cmd == "stopdance" or cmd == "undance" or cmd == "x" then AnimationEngine.Stop()
    elseif cmd == "animspeed" or cmd == "dancespeed" then
        local spd = tonumber(args[1]) or 1
        AnimationEngine.SetSpeed(spd)
    elseif cmd == "antisit" then CharEngine.ToggleAntiSit(true)
    elseif cmd == "unantisit" then CharEngine.ToggleAntiSit(false)
    elseif cmd == "spin" then CharEngine.ToggleSpinBot(true)
    elseif cmd == "unspin" then CharEngine.ToggleSpinBot(false)
    elseif cmd == "xray" or cmd == "r" then XRayEngine.Toggle(true)
    elseif cmd == "unxray" or cmd == "unr" then XRayEngine.Toggle(false)
    elseif cmd == "roles" or cmd == "mm2" or cmd == "m" then MM2Engine.ToggleRoleESP(not HubState.MM2.RoleESP)
    elseif cmd == "unroles" or cmd == "unmm2" then MM2Engine.ToggleRoleESP(false)
    elseif cmd == "respawn" or cmd == "refresh" then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    elseif cmd == "serverhop" or cmd == "shop" then MovementEngine.ServerHop()
    elseif cmd == "rejoin" or cmd == "rj" then MovementEngine.Rejoin()
    elseif cmd == "setslot" or cmd == "slot" then
    local slotNum = tonumber(args[1])
    local targetVal = args[2]
    if slotNum and slotNum >= 1 and slotNum <= 8 and targetVal then
        local id = targetVal:match("%d+")
        local name = "Slot " .. slotNum
        if not id and DualEmoteDatabase[targetVal] then
            local entry = DualEmoteDatabase[targetVal]
            id = (entry.R15 or entry.R6 or ""):gsub("rbxassetid://", "")
            name = targetVal
        end
        if id then
            AnimationEngine.SetRadialSlot(slotNum, name, id)
            SafeNotify({ Title = "Slot " .. slotNum, Content = "Configurado para " .. name, Duration = 2.5 })
        end
    end
elseif cmd == "resetslots" or cmd == "defaultslots" then
    AnimationEngine.ResetRadialSlots()
    SafeNotify({ Title = "Roda Radial", Content = "Slots restaurados para o padrão!", Duration = 2.5 })
elseif cmd == "c" or cmd == "radial" or cmd == "wheel" then ToggleRadialMenu()
    elseif cmd == "copy" or cmd == "copyskin" then
        local targetName = args[1]
        if targetName then
            local targets = TargetParser.FindPlayers(targetName)
            if #targets > 0 then SkinEngine.ClonePlayerSkin(targets[1]) end
        end
    elseif cmd == "skin" or cmd == "morph" then
        local targetId = args[1]
        if targetId then SkinEngine.ApplyByUserId(targetId) end
    elseif cmd == "headless" then SkinEngine.ToggleHeadless(true)
    elseif cmd == "unheadless" then SkinEngine.ToggleHeadless(false)
    elseif cmd == "korblox" then SkinEngine.ToggleKorblox(true)
    elseif cmd == "unkorblox" then SkinEngine.ToggleKorblox(false)
    elseif cmd == "unskin" or cmd == "resetskin" then SkinEngine.ResetAvatar()
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
-- SISTEMA DE HOTKEYS GLOBAIS (2x W, 2x Space, R, M, K, C, X, ;)
-- ====================================================================
local lastWTime = 0
local isDoubleTapSprinting = false
local wasSpeedActiveBeforeSprint = false
local lastSpaceTime = 0

RegisterLoop("Quick_Actions_InputBegan", UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local now = tick()

    -- 1. Double Tap W -> Sprint 25
    if input.KeyCode == Enum.KeyCode.W then
        if (now - lastWTime) <= 0.32 then
            if not isDoubleTapSprinting then
                wasSpeedActiveBeforeSprint = HubState.Movement.SpeedActive
            end
            isDoubleTapSprinting = true
            HubState.Movement.Speed = 25
            HubState.Movement.SpeedActive = true
            MovementEngine.ApplySpeed()
        end
        lastWTime = now

    -- 2. Double Tap Espaço -> Voo Suave 70
    elseif input.KeyCode == Enum.KeyCode.Space then
        if (now - lastSpaceTime) <= 0.35 then
            local willFly = not HubState.Movement.FlightActive
            if willFly then HubState.Movement.FlightSpeed = 70 end
            MovementEngine.SetFlight(willFly)
            lastSpaceTime = 0
        else
            lastSpaceTime = now
        end

    -- 3. Tecla R -> Alternar X-Ray
    elseif input.KeyCode == Enum.KeyCode.R then
        XRayEngine.Toggle(not HubState.Visuals.XRayActive)

    -- 4. Tecla M -> Alternar MM2 Role ESP
    elseif input.KeyCode == Enum.KeyCode.M then
        MM2Engine.ToggleRoleESP(not HubState.MM2.RoleESP)

    -- 5. Tecla K -> Drop Kick Fling Instantâneo
    elseif input.KeyCode == Enum.KeyCode.K then
        FlingEngine.PerformDropKick()

    -- 6. Tecla C -> Roda Radial de Danças
    elseif input.KeyCode == Enum.KeyCode.C then
        ToggleRadialMenu()

    -- 7. Tecla X -> Parar Danças
    elseif input.KeyCode == Enum.KeyCode.X then
        AnimationEngine.Stop()

    -- 8. Tecla ';' ou '\'' -> Command Bar Retrátil
    elseif input.KeyCode == Enum.KeyCode.Semicolon or input.KeyCode == Enum.KeyCode.Quote then
        ToggleCmdBar()
    end
end))

RegisterLoop("Quick_Actions_InputEnded", UserInputService.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.W and isDoubleTapSprinting then
        isDoubleTapSprinting = false
        if not wasSpeedActiveBeforeSprint then
            HubState.Movement.SpeedActive = false
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = HubState.Movement.DefaultSpeed end
        end
    end
end))

-- Atalhos numéricos da Roda Radial (1 a 8)
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
        if em and em.ID then AnimationEngine.PlayRaw(em.ID, em.Name) end
        ToggleRadialMenu(false)
    end
end))

-- ====================================================================
-- CARREGAMENTO DA INTERFACE RAYFIELD (SÍNTESE COMPLETA DAS 8 ABAS)
-- ====================================================================
-- ====================================================================
-- CARREGAMENTO RESILIENTE DA RAYFIELD UI (V13 DEFINITIVE)
-- ====================================================================
local Rayfield

local function SafeNotify(config)
    if Rayfield and typeof(Rayfield.Notify) == "function" then
        pcall(function() Rayfield:Notify(config) end)
    end
end

local function LoadRayfieldLibrary()
    local sources = {
        'https://sirius.menu/rayfield',
        'https://raw.githubusercontent.com/shlexware/Rayfield/main/source'
    }
    for _, url in ipairs(sources) do
        local ok, lib = pcall(function()
            if typeof(loadstring) == "function" then
                local str = game:HttpGet(url)
                if str and #str > 0 then
                    return loadstring(str)()
                end
            end
            return nil
        end)
        if ok and lib and type(lib) == "table" and lib.CreateWindow then
            return lib
        end
    end
    return nil
end

Rayfield = LoadRayfieldLibrary()
if not Rayfield then
    warn("[GoHub V13] Falha crítica: não foi possível carregar a biblioteca Rayfield.")
    return
end

local themeSavePath = "GoHubV13/SelectedTheme.txt"

local function SaveTheme(themeName)
    pcall(function()
        if typeof(writefile) == "function" then
            if typeof(isfolder) == "function" and not isfolder("GoHubV13") then
                if typeof(makefolder) == "function" then makefolder("GoHubV13") end
            end
            writefile(themeSavePath, tostring(themeName))
        end
    end)
end

local function GetSavedTheme()
    local theme = "Bloom"
    pcall(function()
        if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(themeSavePath) then
            theme = readfile(themeSavePath)
        end
    end)
    return theme
end

local initialTheme = GetSavedTheme()

local Window = Rayfield:CreateWindow({
    Name = "GoHub V13 — Definitive Rayfield & Shader Suite",
    Icon = 135247969077372,
    LoadingTitle = "GoHub V13",
    LoadingSubtitle = "by dj (GoHub Suite)",
    Theme = initialTheme,
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GoHubV13",
        FileName = "gohub_config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = false
    },
    KeySystem = false
})

local function SafeDropdownUpdate(dropdown, newOptions)
    if not dropdown then return end
    pcall(function()
        if dropdown.Set then
            dropdown:Set(newOptions)
        elseif dropdown.Refresh then
            dropdown:Refresh(newOptions)
        end
    end)
end

-- ====================================================================
-- ABA 1: UNIVERSAL
-- ====================================================================
local TabUniversal = Window:CreateTab("Universal", nil)
TabUniversal:CreateSection("Física & Movimentação")

TabUniversal:CreateSlider({
    Name = "Velocidade de Caminhada (SPS)",
    Range = {16, 300},
    Increment = 1,
    Suffix = " SPS",
    CurrentValue = 16,
    Flag = "universal_walkspeed_slider",
    Callback = function(Value)
        HubState.Movement.Speed = Value
        HubState.Movement.SpeedActive = (Value ~= HubState.Movement.DefaultSpeed)
        MovementEngine.ApplySpeed()
    end,
})

TabUniversal:CreateToggle({
    Name = "Ativar Voo (W/A/S/D + Espaço/Ctrl)",
    CurrentValue = false,
    Flag = "universal_flight_toggle",
    Callback = function(Value)
        MovementEngine.SetFlight(Value)
    end,
})

TabUniversal:CreateSlider({
    Name = "Velocidade de Voo",
    Range = {10, 300},
    Increment = 5,
    Suffix = " SPS",
    CurrentValue = 50,
    Flag = "universal_flight_speed_slider",
    Callback = function(Value)
        HubState.Movement.FlightSpeed = Value
    end,
})

TabUniversal:CreateToggle({
    Name = "Noclip (Atravessar Paredes)",
    CurrentValue = false,
    Flag = "universal_noclip_toggle",
    Callback = function(Value)
        MovementEngine.SetNoclip(Value)
    end,
})

TabUniversal:CreateToggle({
    Name = "Infinite Jump (Pulo Infinito)",
    CurrentValue = false,
    Flag = "universal_infjump_toggle",
    Callback = function(Value)
        MovementEngine.SetInfiniteJump(Value)
    end,
})

TabUniversal:CreateSection("Teleporte & Utilidades")

TabUniversal:CreateToggle({
    Name = "ClickTP (Segurar Ctrl + Clique)",
    CurrentValue = false,
    Flag = "universal_clicktp_toggle",
    Callback = function(Value)
        MovementEngine.SetClickTP(Value)
    end,
})

TabUniversal:CreateButton({
    Name = "Obter TP Tool no Inventário",
    Callback = function()
        MovementEngine.GiveTPTool()
        SafeNotify({
            Title = "Universal",
            Content = "GoHub TP Tool adicionada ao seu inventário!",
            Duration = 3.5
        })
    end,
})

TabUniversal:CreateSection("Servidores")

TabUniversal:CreateButton({
    Name = "Server Hop (Menor Lotação)",
    Callback = function()
        SafeNotify({ Title = "Servidor", Content = "Procurando melhor servidor público...", Duration = 3 })
        MovementEngine.ServerHop()
    end,
})

TabUniversal:CreateButton({
    Name = "Rejoin (Reconectar ao Mesmo Servidor)",
    Callback = function()
        SafeNotify({ Title = "Servidor", Content = "Reconectando ao servidor atual...", Duration = 3 })
        MovementEngine.Rejoin()
    end,
})

-- ====================================================================
-- ABA 2: JOGADORES (SELEÇÃO, TP, SPECTATE, ADVANCED FLING)
-- ====================================================================
local TabPlayers = Window:CreateTab("Jogadores", nil)
TabPlayers:CreateSection("Seleção & Teleporte ao Alvo")

local function GetServerPlayerOptions()
    local opts = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(opts, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    if #opts == 0 then table.insert(opts, "Nenhum outro jogador") end
    return opts
end

local PlayersDropdown = TabPlayers:CreateDropdown({
    Name = "Selecionar Jogador no Servidor",
    Options = GetServerPlayerOptions(),
    CurrentOption = {GetServerPlayerOptions()[1]},
    MultipleOptions = false,
    Flag = "players_target_dropdown",
    Callback = function(Options)
        local sel = type(Options) == "table" and Options[1] or Options
        if sel and sel ~= "Nenhum outro jogador" then
            local username = sel:match("@([%w_]+)")
            if username then
                HubState.SelectedPlayer = Players:FindFirstChild(username)
            else
                local found = TargetParser.FindPlayers(sel)
                HubState.SelectedPlayer = found and found[1] or nil
            end
        end
    end,
})

TabPlayers:CreateInput({
    Name = "Ou Digite Nome/Filtro (me, others, nearest, random...)",
    PlaceholderText = "ex: fer, nearest, random",
    RemoveTextAfterFocusLost = false,
    Flag = "players_target_input",
    Callback = function(Text)
        if Text and Text ~= "" then
            local found = TargetParser.FindPlayers(Text)
            if #found > 0 then
                HubState.SelectedPlayer = found[1]
                SafeNotify({
                    Title = "Jogador Selecionado",
                    Content = "Alvo: " .. found[1].DisplayName .. " (@" .. found[1].Name .. ")",
                    Duration = 3
                })
            end
        end
    end,
})

Players.PlayerAdded:Connect(function()
    SafeDropdownUpdate(PlayersDropdown, GetServerPlayerOptions())
end)

Players.PlayerRemoving:Connect(function(p)
    if HubState.SelectedPlayer == p then HubState.SelectedPlayer = nil end
    SafeDropdownUpdate(PlayersDropdown, GetServerPlayerOptions())
end)

TabPlayers:CreateButton({
    Name = "Teleportar para Alvo Selecionado",
    Callback = function()
        if HubState.SelectedPlayer and HubState.SelectedPlayer.Character and HubState.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp then
                myHrp.CFrame = HubState.SelectedPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                SafeNotify({ Title = "Teleporte", Content = "Teleportado para @" .. HubState.SelectedPlayer.Name, Duration = 2.5 })
            end
        else
            SafeNotify({ Title = "Erro", Content = "Selecione um jogador válido primeiro!", Duration = 3 })
        end
    end,
})

TabPlayers:CreateButton({
    Name = "Espectar / Restaurar Câmera",
    Callback = function()
        if HubState.IsSpectating then
            HubState.IsSpectating = false
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if myHum then Camera.CameraSubject = myHum end
            SafeNotify({ Title = "Espectador", Content = "Câmera restaurada para seu personagem.", Duration = 3 })
        else
            if HubState.SelectedPlayer and HubState.SelectedPlayer.Character and HubState.SelectedPlayer.Character:FindFirstChildOfClass("Humanoid") then
                HubState.IsSpectating = true
                Camera.CameraSubject = HubState.SelectedPlayer.Character:FindFirstChildOfClass("Humanoid")
                SafeNotify({ Title = "Espectador", Content = "Espectando: " .. HubState.SelectedPlayer.DisplayName, Duration = 3 })
            else
                SafeNotify({ Title = "Erro", Content = "Selecione um jogador válido para espectar!", Duration = 3 })
            end
        end
    end,
})

TabPlayers:CreateSection("Arsenal de Fling (Motor Infinite Yield & Drop Kick)")

TabPlayers:CreateButton({
    Name = "💥 Drop Kick Fling [Tecla 'K']",
    Callback = function()
        FlingEngine.PerformDropKick()
    end,
})

TabPlayers:CreateToggle({
    Name = "WalkFling (Tocar e Lançar — Suave)",
    CurrentValue = false,
    Flag = "players_walkfling_toggle",
    Callback = function(Value)
        FlingEngine.ToggleWalkFling(Value)
    end,
})

TabPlayers:CreateToggle({
    Name = "SpinFling (Giro Clássico do IY)",
    CurrentValue = false,
    Flag = "players_spinfling_toggle",
    Callback = function(Value)
        FlingEngine.ToggleSpinFling(Value)
    end,
})

TabPlayers:CreateButton({
    Name = "Fling Instantâneo no Alvo",
    Callback = function()
        if HubState.SelectedPlayer then
            FlingEngine.FlingTarget(HubState.SelectedPlayer)
            SafeNotify({ Title = "Fling", Content = "Lançando @" .. HubState.SelectedPlayer.Name, Duration = 3 })
        else
            SafeNotify({ Title = "Erro", Content = "Selecione um alvo na lista primeiro!", Duration = 3 })
        end
    end,
})

TabPlayers:CreateToggle({
    Name = "LoopFling no Alvo Selecionado",
    CurrentValue = false,
    Flag = "players_loopfling_toggle",
    Callback = function(Value)
        if Value then
            if HubState.SelectedPlayer then
                FlingEngine.LoopFling(HubState.SelectedPlayer)
                SafeNotify({ Title = "LoopFling", Content = "Looping @" .. HubState.SelectedPlayer.Name, Duration = 3 })
            else
                SafeNotify({ Title = "Erro", Content = "Nenhum alvo selecionado!", Duration = 3 })
            end
        else
            FlingEngine.LoopFling(nil)
        end
    end,
})

TabPlayers:CreateToggle({
    Name = "Anti-Fling (Imunidade a Flings)",
    CurrentValue = false,
    Flag = "players_antifling_toggle",
    Callback = function(Value)
        FlingEngine.ToggleAntiFling(Value)
    end,
})

-- ====================================================================
-- ABA 3: SKINS & MORPHS (REPLICAÇÃO, CLONADOR, USER ID, ITENS LENDÁRIOS)
-- ====================================================================
local TabSkins = Window:CreateTab("Skins", nil)
TabSkins:CreateSection("Clonagem de Jogadores")

TabSkins:CreateButton({
    Name = "🎭 Clonar Skin do Alvo Selecionado",
    Callback = function()
        if HubState.SelectedPlayer then
            local ok, msg = SkinEngine.ClonePlayerSkin(HubState.SelectedPlayer)
            SafeNotify({
                Title = "Clonador de Skin",
                Content = tostring(msg),
                Duration = 4
            })
        else
            SafeNotify({
                Title = "Aviso",
                Content = "Selecione um jogador na aba 'Jogadores' primeiro!",
                Duration = 3.5
            })
        end
    end,
})

TabSkins:CreateSection("Aplicar por User ID")

local customSkinUserId = ""
TabSkins:CreateInput({
    Name = "User ID da Conta",
    PlaceholderText = "ex: 261, 1, 48316149",
    RemoveTextAfterFocusLost = false,
    Flag = "skins_userid_input",
    Callback = function(Text)
        customSkinUserId = Text
    end,
})

TabSkins:CreateButton({
    Name = "⚡ Aplicar Skin por User ID",
    Callback = function()
        if customSkinUserId and customSkinUserId ~= "" then
            local ok, msg = SkinEngine.ApplyByUserId(customSkinUserId)
            SafeNotify({
                Title = "Aplicador de Avatar",
                Content = tostring(msg),
                Duration = 4
            })
        else
            SafeNotify({ Title = "Erro", Content = "Digite um User ID numérico válido!", Duration = 3 })
        end
    end,
})

TabSkins:CreateSection("Pacotes & Modificadores Gratuitos")

TabSkins:CreateToggle({
    Name = "Headless Horseman (Cabeça Invisível)",
    CurrentValue = false,
    Flag = "skins_headless_toggle",
    Callback = function(Value)
        SkinEngine.ToggleHeadless(Value)
    end,
})

TabSkins:CreateToggle({
    Name = "Korblox Deathspeaker (Perna de Esqueleto)",
    CurrentValue = false,
    Flag = "skins_korblox_toggle",
    Callback = function(Value)
        SkinEngine.ToggleKorblox(Value)
    end,
})

TabSkins:CreateSection("Restauração")

TabSkins:CreateButton({
    Name = "🔄 Restaurar Skin Original",
    Callback = function()
        SkinEngine.ResetAvatar()
        SafeNotify({ Title = "Avatar", Content = "Avatar original restaurado com sucesso!", Duration = 3 })
    end,
})

-- ====================================================================
-- ABA 4: MURDER MYSTERY 2
-- ====================================================================
local TabMM2 = Window:CreateTab("MM2", nil)
TabMM2:CreateSection("Detecção Híbrida de Papéis")

TabMM2:CreateToggle({
    Name = "Detecção Híbrida de Papéis (Remote + Inv + Inocentes Verdes)",
    CurrentValue = false,
    Flag = "mm2_hybrid_roles_toggle",
    Callback = function(Value)
        MM2Engine.ToggleRoleESP(Value)
    end,
})

TabMM2:CreateSection("Moedas & Itens")

TabMM2:CreateToggle({
    Name = "ESP de Moedas (Coin ESP)",
    CurrentValue = false,
    Flag = "mm2_coin_esp_toggle",
    Callback = function(Value)
        MM2Engine.ToggleCoinESP(Value)
    end,
})

TabMM2:CreateToggle({
    Name = "Auto-Grab Gun (Coletar Arma ao Cair)",
    CurrentValue = false,
    Flag = "mm2_autograb_gun_toggle",
    Callback = function(Value)
        MM2Engine.ToggleAutoGrabGun(Value)
    end,
})

TabMM2:CreateSection("Combate & Hitboxes")

TabMM2:CreateToggle({
    Name = "Hitboxes Expandidas (Vermelho)",
    CurrentValue = false,
    Flag = "mm2_hitbox_toggle",
    Callback = function(Value)
        MM2Engine.ToggleHitboxes(Value)
    end,
})

-- ====================================================================
-- ABA 5: DANÇAS (CONTROLES, RADIAL, CUSTOMIZADAS, PRESETS)
-- ====================================================================
-- ====================================================================
-- ABA: VISUAIS & SHADERS REALISTAS
-- ====================================================================
local TabVisuals = Window:CreateTab("Visuais & Shaders", nil)

TabVisuals:CreateSection("Iluminação Cinemática & Shaders")

TabVisuals:CreateToggle({
    Name = "✨ Shader Realista (Golden Hour & God Rays)",
    CurrentValue = false,
    Flag = "visuals_shader_goldenhour",
    Callback = function(Value)
        LightingEngine.ToggleShader(Value)
    end,
})

TabVisuals:CreateToggle({
    Name = "Fullbright (Tudo Claro)",
    CurrentValue = false,
    Flag = "visuals_fullbright",
    Callback = function(Value)
        LightingEngine.ToggleFullbright(Value)
    end,
})

TabVisuals:CreateToggle({
    Name = "NoFog (Remover Neblina)",
    CurrentValue = false,
    Flag = "visuals_nofog",
    Callback = function(Value)
        LightingEngine.ToggleNoFog(Value)
    end,
})

TabVisuals:CreateSection("Rastreamento & Visuais")

TabVisuals:CreateToggle({
    Name = "X-Ray (Paredes Transparentes)",
    CurrentValue = false,
    Flag = "visuals_xray",
    Callback = function(Value)
        XRayEngine.Toggle(Value)
    end,
})

TabVisuals:CreateToggle({
    Name = "Player ESP Universal (Chams Roxo)",
    CurrentValue = false,
    Flag = "visuals_universal_esp",
    Callback = function(Value)
        UpdateUniversalESP(Value)
    end,
})

TabVisuals:CreateSection("Combate & Aimbot com Raycast")

TabVisuals:CreateToggle({
    Name = "Aimbot Ativo (Segurar Botão Direito)",
    CurrentValue = false,
    Flag = "visuals_aimbot_active",
    Callback = function(Value)
        HubState.Combat.AimbotActive = Value
    end,
})

TabVisuals:CreateToggle({
    Name = "Verificação de Visibilidade (Raycast)",
    CurrentValue = true,
    Flag = "visuals_aimbot_vischeck",
    Callback = function(Value)
        HubState.Combat.VisibilityCheck = Value
    end,
})

TabVisuals:CreateSlider({
    Name = "Raio do FOV (Pixels)",
    Range = {20, 500},
    Increment = 5,
    Suffix = " px",
    CurrentValue = 120,
    Flag = "visuals_aimbot_fov",
    Callback = function(Value)
        HubState.Combat.FOV = Value
    end,
})

TabVisuals:CreateToggle({
    Name = "Exibir Círculo FOV na Mira",
    CurrentValue = true,
    Flag = "visuals_aimbot_fov_visible",
    Callback = function(Value)
        HubState.Combat.FOVCircleVisible = Value
    end,
})

local TabDances = Window:CreateTab("Danças", nil)

local allPresetDances = {}
for name, _ in pairs(DualEmoteDatabase) do
    table.insert(allPresetDances, name)
end
table.sort(allPresetDances)

TabDances:CreateSection("Controle Geral de Animação")

TabDances:CreateButton({
    Name = "🛑 Parar Danças [Tecla 'X']",
    Callback = function()
        AnimationEngine.Stop()
        SafeNotify({ Title = "Danças", Content = "Animações finalizadas.", Duration = 2 })
    end,
})

TabDances:CreateSlider({
    Name = "Velocidade da Animação (%)",
    Range = {25, 300},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "dances_speed_slider",
    Callback = function(Value)
        AnimationEngine.SetSpeed(Value / 100)
    end,
})

TabDances:CreateParagraph({
    Title = "Roda Radial de Emotes [Tecla 'C']",
    Content = "Pressione a tecla 'C' a qualquer momento para abrir a Roda Circular de Emotes com seus 8 slots favoritos! Use as teclas numéricas 1 a 8 para ativar na hora."
})

-- ====================================================================
-- SEÇÃO: EDITOR DA RODA RADIAL (SLOTS 1 A 8 EDITÁVEIS E SALVOS NO DISCO)
-- ====================================================================
TabDances:CreateSection("⭐ Personalizar Roda Radial (Slots 1 a 8)")

local function GetRadialSlotListLabels()
    local labels = {}
    for i = 1, 8 do
        local slotData = HubState.Radial.Slots[i]
        local danceName = (slotData and slotData.Name and slotData.Name ~= "") and slotData.Name or "(Vazio)"
        local danceId = (slotData and slotData.ID and slotData.ID ~= "") and (" [" .. slotData.ID .. "]") or ""
        table.insert(labels, "Slot " .. i .. ": " .. danceName .. danceId)
    end
    return labels
end

local currentEditingSlot = 1
local SlotSelectorDropdown
local selectedPresetForSlot = allPresetDances[1] or "Floss"
local inputSlotManualName = ""
local inputSlotManualId = ""

SlotSelectorDropdown = TabDances:CreateDropdown({
    Name = "1. Escolher Slot para Editar",
    Options = GetRadialSlotListLabels(),
    CurrentOption = {GetRadialSlotListLabels()[1]},
    MultipleOptions = false,
    Flag = "dances_radial_slot_selector",
    Callback = function(Option)
        local sel = type(Option) == "table" and Option[1] or Option
        local num = sel and tonumber(sel:match("Slot%s+(%d+)"))
        if num then currentEditingSlot = num end
    end,
})

TabDances:CreateDropdown({
    Name = "2. Escolher Dança Pré-definida para o Slot",
    Options = allPresetDances,
    CurrentOption = {allPresetDances[1]},
    MultipleOptions = false,
    Flag = "dances_radial_preset_select",
    Callback = function(Option)
        selectedPresetForSlot = type(Option) == "table" and Option[1] or Option
    end,
})

TabDances:CreateButton({
    Name = "✅ Aplicar Dança Pré-definida no Slot Escolhido",
    Callback = function()
        if selectedPresetForSlot and DualEmoteDatabase[selectedPresetForSlot] then
            local entry = DualEmoteDatabase[selectedPresetForSlot]
            local rawId = entry.R15 or entry.R6 or ""
            local cleanId = rawId:gsub("rbxassetid://", "")
            AnimationEngine.SetRadialSlot(currentEditingSlot, selectedPresetForSlot, cleanId)
            SafeDropdownUpdate(SlotSelectorDropdown, GetRadialSlotListLabels())
            SafeNotify({
                Title = "Roda Atualizada!",
                Content = "Slot " .. currentEditingSlot .. " configurado: " .. selectedPresetForSlot,
                Duration = 3,
                Image = 135247969077372
            })
        end
    end,
})

TabDances:CreateButton({
    Name = "💾 Aplicar Dança Salva Selecionada no Slot",
    Callback = function()
        if selectedSavedDance and selectedSavedDance ~= "Nenhuma Dança Salva" then
            local id = selectedSavedDance:match("%((%d+)%)")
            local name = selectedSavedDance:match("^(.-)%s*%(") or "CustomDance"
            if id then
                AnimationEngine.SetRadialSlot(currentEditingSlot, name, id)
                SafeDropdownUpdate(SlotSelectorDropdown, GetRadialSlotListLabels())
                SafeNotify({
                    Title = "Roda Atualizada!",
                    Content = "Slot " .. currentEditingSlot .. " configurado: " .. name,
                    Duration = 3,
                    Image = 135247969077372
                })
            end
        else
            SafeNotify({ Title = "Aviso", Content = "Selecione uma dança salva na lista primeiro!", Duration = 3 })
        end
    end,
})

TabDances:CreateInput({
    Name = "Nome Manual para o Slot (Opcional)",
    PlaceholderText = "ex: Minha Dança Favorita",
    RemoveTextAfterFocusLost = false,
    Flag = "dances_radial_manual_name",
    Callback = function(Text)
        inputSlotManualName = Text
    end,
})

TabDances:CreateInput({
    Name = "ID Numérico Manual para o Slot",
    PlaceholderText = "ex: 131086670591743",
    RemoveTextAfterFocusLost = false,
    Flag = "dances_radial_manual_id",
    Callback = function(Text)
        inputSlotManualId = Text
    end,
})

TabDances:CreateButton({
    Name = "🎯 Definir ID Manual no Slot Escolhido",
    Callback = function()
        local idNum = inputSlotManualId and inputSlotManualId:match("%d+")
        if idNum then
            local displayName = (inputSlotManualName and inputSlotManualName:gsub("%s+", "") ~= "") and inputSlotManualName or ("Dança " .. idNum)
            AnimationEngine.SetRadialSlot(currentEditingSlot, displayName, idNum)
            SafeDropdownUpdate(SlotSelectorDropdown, GetRadialSlotListLabels())
            SafeNotify({
                Title = "Slot Atualizado!",
                Content = "Slot " .. currentEditingSlot .. " configurado com ID: " .. idNum,
                Duration = 3,
                Image = 135247969077372
            })
        else
            SafeNotify({ Title = "Erro", Content = "Informe um ID numérico válido para o slot!", Duration = 3 })
        end
    end,
})

TabDances:CreateButton({
    Name = "🗑 Limpar / Esvaziar Slot Escolhido",
    Callback = function()
        AnimationEngine.SetRadialSlot(currentEditingSlot, "(Vazio)", nil)
        SafeDropdownUpdate(SlotSelectorDropdown, GetRadialSlotListLabels())
        SafeNotify({ Title = "Slot Limpo", Content = "Slot " .. currentEditingSlot .. " agora está vazio.", Duration = 2.5 })
    end,
})

TabDances:CreateButton({
    Name = "🔄 Restaurar 8 Slots Padrão do GoHub",
    Callback = function()
        AnimationEngine.ResetRadialSlots()
        SafeDropdownUpdate(SlotSelectorDropdown, GetRadialSlotListLabels())
        SafeNotify({
            Title = "Roda Restaurada!",
            Content = "Os 8 slots foram restaurados para a configuração padrão.",
            Duration = 3,
            Image = 135247969077372
        })
    end,
})

TabDances:CreateButton({
    Name = "👁 Testar / Abrir Roda Radial [Tecla 'C']",
    Callback = function()
        ToggleRadialMenu()
    end,
})

TabDances:CreateSection("Adicionar Dança Customizada")

local inputCustomDanceName = ""
local inputCustomDanceId = ""

TabDances:CreateInput({
    Name = "Nome da Dança Customizada",
    PlaceholderText = "ex: Passinho Pro, Funk, Phonk...",
    RemoveTextAfterFocusLost = false,
    Flag = "dances_custom_name_input",
    Callback = function(Text)
        inputCustomDanceName = Text
    end,
})

TabDances:CreateInput({
    Name = "ID da Animação / Asset ID",
    PlaceholderText = "ex: 131086670591743",
    RemoveTextAfterFocusLost = false,
    Flag = "dances_custom_id_input",
    Callback = function(Text)
        inputCustomDanceId = Text
    end,
})

TabDances:CreateButton({
    Name = "▶ Testar ID da Dança",
    Callback = function()
        if inputCustomDanceId and inputCustomDanceId ~= "" then
            AnimationEngine.PlayRaw(inputCustomDanceId, inputCustomDanceName ~= "" and inputCustomDanceName or "TestEmote")
        else
            SafeNotify({ Title = "Erro", Content = "Informe o ID numérico da animação!", Duration = 3 })
        end
    end,
})

local function GetSavedCustomDanceNames()
    local names = {}
    for _, d in ipairs(HubState.CustomDances) do
        table.insert(names, d.Name .. " (" .. d.ID .. ")")
    end
    if #names == 0 then table.insert(names, "Nenhuma Dança Salva") end
    return names
end

local CustomDancesDropdown

TabDances:CreateButton({
    Name = "💾 Salvar Dança no Hub",
    Callback = function()
        local ok, res = AnimationEngine.SaveCustomDance(inputCustomDanceName, inputCustomDanceId)
        if ok then
            SafeNotify({ Title = "Sucesso", Content = "Dança salva no hub!", Duration = 3 })
            SafeDropdownUpdate(CustomDancesDropdown, GetSavedCustomDanceNames())
        else
            SafeNotify({ Title = "Erro", Content = tostring(res), Duration = 3 })
        end
    end,
})

TabDances:CreateSection("Minhas Danças Salvas")

local selectedSavedDance = nil
CustomDancesDropdown = TabDances:CreateDropdown({
    Name = "Danças Salvas",
    Options = GetSavedCustomDanceNames(),
    CurrentOption = {GetSavedCustomDanceNames()[1]},
    MultipleOptions = false,
    Flag = "dances_saved_dropdown",
    Callback = function(Options)
        local sel = type(Options) == "table" and Options[1] or Options
        selectedSavedDance = sel
    end,
})

TabDances:CreateButton({
    Name = "▶ Tocar Dança Salva Selecionada",
    Callback = function()
        if selectedSavedDance and selectedSavedDance ~= "Nenhuma Dança Salva" then
            local id = selectedSavedDance:match("%((%d+)%)")
            local name = selectedSavedDance:match("^(.-)%s*%(") or "CustomDance"
            if id then AnimationEngine.PlayRaw(id, name) end
        end
    end,
})

TabDances:CreateButton({
    Name = "🗑 Deletar Dança Salva Selecionada",
    Callback = function()
        if selectedSavedDance and selectedSavedDance ~= "Nenhuma Dança Salva" then
            local name = selectedSavedDance:match("^(.-)%s*%(")
            if name and AnimationEngine.DeleteCustomDance(name) then
                SafeNotify({ Title = "Danças", Content = "Dança excluída!", Duration = 3 })
                SafeDropdownUpdate(CustomDancesDropdown, GetSavedCustomDanceNames())
            end
        end
    end,
})

TabDances:CreateSection("Danças Pré-definidas do GoHub")

-- allPresetDances hoisted to top of TabDances

local selectedPresetDance = allPresetDances[1]
TabDances:CreateDropdown({
    Name = "Catálogo de Danças Pré-definidas",
    Options = allPresetDances,
    CurrentOption = {allPresetDances[1]},
    MultipleOptions = false,
    Flag = "dances_preset_dropdown",
    Callback = function(Options)
        selectedPresetDance = type(Options) == "table" and Options[1] or Options
    end,
})

TabDances:CreateButton({
    Name = "▶ Tocar Dança Pré-definida",
    Callback = function()
        if selectedPresetDance then
            AnimationEngine.Play(selectedPresetDance)
        end
    end,
})

TabDances:CreateButton({
    Name = "🔥 Tocar: Passinho do Jamal (Principal)",
    Callback = function()
        AnimationEngine.Play("Passinho do Jamal (Principal)")
    end,
})

TabDances:CreateButton({
    Name = "🔥 Tocar: Passinho do Jamal (Fogo Fogo)",
    Callback = function()
        AnimationEngine.Play("Passinho do Jamal (Fogo Fogo)")
    end,
})

TabDances:CreateButton({
    Name = "⚡ Tocar: IY Breakdance",
    Callback = function()
        AnimationEngine.Play("IY Dança 1 (Breakdance)")
    end,
})

TabDances:CreateButton({
    Name = "🕺 Tocar: Floss",
    Callback = function()
        AnimationEngine.Play("Floss")
    end,
})

-- ====================================================================
-- ABA 6: PERSONAGEM (ANTI-SIT, SPINBOT, RESPAWN)
-- ====================================================================
local TabCharacter = Window:CreateTab("Personagem", nil)
TabCharacter:CreateSection("Física & Estabilidade do Personagem")

TabCharacter:CreateToggle({
    Name = "Anti-Sit (Impedir de Sentar)",
    CurrentValue = false,
    Flag = "char_antisit_toggle",
    Callback = function(Value)
        CharEngine.ToggleAntiSit(Value)
    end,
})

TabCharacter:CreateToggle({
    Name = "SpinBot (Girar Personagem)",
    CurrentValue = false,
    Flag = "char_spinbot_toggle",
    Callback = function(Value)
        CharEngine.ToggleSpinBot(Value)
    end,
})

TabCharacter:CreateSlider({
    Name = "Velocidade do SpinBot",
    Range = {10, 150},
    Increment = 5,
    Suffix = " rad/s",
    CurrentValue = 30,
    Flag = "char_spin_speed_slider",
    Callback = function(Value)
        HubState.Character.SpinSpeed = Value
        if HubState.Character.SpinBot then CharEngine.ToggleSpinBot(true) end
    end,
})

TabCharacter:CreateSection("Ciclo de Vida")

TabCharacter:CreateButton({
    Name = "Respawn Instantâneo (Reset)",
    Callback = function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end,
})

-- ====================================================================
-- ABA 7: WAYPOINTS (ADICIONAR, TELEPORTAR, DELETAR)
-- ====================================================================
local TabWaypoints = Window:CreateTab("Waypoints", nil)
TabWaypoints:CreateSection("Gerenciador de Pontos do Mapa")

local inputWaypointName = ""
TabWaypoints:CreateInput({
    Name = "Nome do Waypoint (Opcional)",
    PlaceholderText = "ex: Base Secreta, Spawn, Cofre...",
    RemoveTextAfterFocusLost = false,
    Flag = "waypoints_name_input",
    Callback = function(Text)
        inputWaypointName = Text
    end,
})

local function GetWaypointList()
    local list = {}
    for _, wp in ipairs(HubState.Waypoints) do
        table.insert(list, wp.Name)
    end
    if #list == 0 then table.insert(list, "Nenhum Waypoint Salvo") end
    return list
end

local WaypointsDropdown
local selectedWaypointName = nil

TabWaypoints:CreateButton({
    Name = "📍 Adicionar Posição Atual como Waypoint",
    Callback = function()
        local ok, wpName = WaypointEngine.SaveCurrent(inputWaypointName)
        if ok then
            SafeNotify({ Title = "Waypoints", Content = "Waypoint '" .. wpName .. "' salvo!", Duration = 3 })
            SafeDropdownUpdate(WaypointsDropdown, GetWaypointList())
        else
            SafeNotify({ Title = "Erro", Content = tostring(wpName), Duration = 3 })
        end
    end,
})

WaypointsDropdown = TabWaypoints:CreateDropdown({
    Name = "Waypoints Salvos",
    Options = GetWaypointList(),
    CurrentOption = {GetWaypointList()[1]},
    MultipleOptions = false,
    Flag = "waypoints_list_dropdown",
    Callback = function(Options)
        selectedWaypointName = type(Options) == "table" and Options[1] or Options
    end,
})

TabWaypoints:CreateButton({
    Name = "⚡ Teleportar para Waypoint Selecionado",
    Callback = function()
        if selectedWaypointName and selectedWaypointName ~= "Nenhum Waypoint Salvo" then
            for _, wp in ipairs(HubState.Waypoints) do
                if wp.Name == selectedWaypointName then
                    WaypointEngine.TeleportTo(wp)
                    SafeNotify({ Title = "Teleporte", Content = "Teleportado para " .. wp.Name, Duration = 2.5 })
                    return
                end
            end
        else
            SafeNotify({ Title = "Erro", Content = "Selecione um waypoint válido!", Duration = 3 })
        end
    end,
})

TabWaypoints:CreateButton({
    Name = "🗑 Deletar Waypoint Selecionado",
    Callback = function()
        if selectedWaypointName and selectedWaypointName ~= "Nenhum Waypoint Salvo" then
            if WaypointEngine.DeleteWaypoint(selectedWaypointName) then
                SafeNotify({ Title = "Waypoints", Content = "Waypoint excluído!", Duration = 2.5 })
                SafeDropdownUpdate(WaypointsDropdown, GetWaypointList())
            end
        end
    end,
})

-- ====================================================================
-- ABA 8: COMANDOS & ATALHOS RÁPIDOS
-- ====================================================================
local TabCommands = Window:CreateTab("Comandos", nil)
TabCommands:CreateSection("Barra de Comandos Retrátil")

TabCommands:CreateButton({
    Name = "Abrir / Fechar Command Bar Retrátil (Atalho: ';')",
    Callback = function()
        ToggleCmdBar()
    end,
})

TabCommands:CreateSection("Lista de Atalhos Globais")

TabCommands:CreateParagraph({
    Title = "Teclas Rápidas & Hotkeys Nativas",
    Content = table.concat({
        "• 2x 'W' — Sprint Inteligente (Velocidade = 25 SPS)",
        "• 2x 'Espaço' — Alterna Voo Suave (Velocidade = 70 SPS)",
        "• 'R' — Alternar X-Ray (Transparência de paredes)",
        "• 'M' — Alternar MM2 Role ESP (Assassino, Xerife, Inocentes)",
        "• 'K' — Drop Kick Fling Instantâneo (Impulso Direcional 5000)",
        "• 'C' — Abre a Roda Radial Circular de Danças (Slots 1 a 8)",
        "• 'X' — Parar qualquer dança imediatamente",
        "• ';' ou '\'' — Abre a Command Bar retrátil no topo da tela"
    }, "\n")
})

TabCommands:CreateSection("Dicionário de Comandos Disponíveis")

TabCommands:CreateParagraph({
    Title = "Comandos da Command Bar (;)",
    Content = table.concat({
        "• fly / unfly — Ativa/Desativa o voo suave",
        "• speed [num] / unspeed — Configura velocidade de caminhada",
        "• noclip / clip — Ativa/Desativa atravessar paredes",
        "• infjump / uninfjump — Pulo infinito",
        "• clicktp / unclicktp — Segure Ctrl e clique para teleportar",
        "• tptool — Spawna a ferramenta de teleporte no inventário",
        "• tp [alvo] — Teleporta até o jogador (ex: tp fer, tp nearest)",
        "• dropkick [força] / kick — Aciona o Drop Kick Fling",
        "• fling [alvo] / walkfling / loopfling — Motores de arremesso IY",
        "• antifling / unantifling — Proteção total contra flings",
        "• fullbright / nofog / xray — Ajustes visuais de iluminação",
        "• dance [nome/id] / stopdance — Execução e parada de danças",
        "• animspeed [num] — Ajusta a velocidade de reprodução",
        "• copy [alvo] — Clona o avatar completo do jogador",
        "• skin [userId] / unskin — Aplica skin por ID ou restaura original",
        "• headless / korblox — Modificadores de corpo instantâneos",
        "• antisit / spin [velocidade] — Física e estabilidade",
        "• serverhop / rejoin / respawn — Ciclo de servidor e vida"
    }, "\n")
})

-- ====================================================================
-- ABA: CONFIGURAÇÕES & TEMAS RAYFIELD
-- ====================================================================
-- ====================================================================
-- ROTINA DE DESCARREGAMENTO TOTAL & LIMPEZA DE MEMÓRIA (UNLOAD)
-- ====================================================================
local function ResetAllStates()
    -- 1. Desconectar e esvaziar todo o ConnectionPool
    for tag, _ in pairs(ConnectionPool) do
        DropLoop(tag)
    end
    table.clear(ConnectionPool)

    -- 2. Desligar motores de movimento
    if MovementEngine.SetFlight then MovementEngine.SetFlight(false) end
    if MovementEngine.SetNoclip then MovementEngine.SetNoclip(false) end
    if MovementEngine.SetInfiniteJump then MovementEngine.SetInfiniteJump(false) end
    if MovementEngine.SetClickTP then MovementEngine.SetClickTP(false) end
    HubState.Movement.SpeedActive = false

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = HubState.Movement.DefaultSpeed or 16 end

    -- 3. Desligar motores de combate, fling e física
    HubState.Combat.AimbotActive = false
    if DrawingFOVCircle then pcall(function() DrawingFOVCircle:Remove() end) end
    if FlingEngine.ToggleWalkFling then FlingEngine.ToggleWalkFling(false) end
    if FlingEngine.ToggleSpinFling then FlingEngine.ToggleSpinFling(false) end
    if FlingEngine.LoopFling then FlingEngine.LoopFling(nil) end
    if FlingEngine.ToggleAntiFling then FlingEngine.ToggleAntiFling(false) end
    if CharEngine.ToggleAntiSit then CharEngine.ToggleAntiSit(false) end
    if CharEngine.ToggleSpinBot then CharEngine.ToggleSpinBot(false) end

    -- 4. Desligar visuais, shaders e ESP
    if XRayEngine.Toggle then XRayEngine.Toggle(false) end
    if LightingEngine.ToggleShader then LightingEngine.ToggleShader(false) end
    if LightingEngine.ToggleFullbright then LightingEngine.ToggleFullbright(false) end
    if LightingEngine.ToggleNoFog then LightingEngine.ToggleNoFog(false) end
    if UpdateUniversalESP then UpdateUniversalESP(false) end

    -- 5. Desligar MM2 Suite
    if MM2Engine.ToggleRoleESP then MM2Engine.ToggleRoleESP(false) end
    if MM2Engine.ToggleCoinESP then MM2Engine.ToggleCoinESP(false) end
    if MM2Engine.ToggleAutoGrabGun then MM2Engine.ToggleAutoGrabGun(false) end
    if MM2Engine.ToggleHitboxes then MM2Engine.ToggleHitboxes(false) end

    -- 6. Restaurar câmera, animações e avatar
    if HubState.IsSpectating then
        HubState.IsSpectating = false
        if hum then (Workspace.CurrentCamera or Camera).CameraSubject = hum end
    end
    if AnimationEngine.Stop then AnimationEngine.Stop() end
    if SkinEngine.ResetAvatar then SkinEngine.ResetAvatar() end

    -- 7. Destruir containers de interface secundária
    pcall(function() if CmdBarScreen then CmdBarScreen:Destroy() end end)
    pcall(function() if UniversalESPFolder then UniversalESPFolder:Destroy() end end)
    pcall(function() if MM2RoleFolder then MM2RoleFolder:Destroy() end end)
    pcall(function() if MM2CoinFolder then MM2CoinFolder:Destroy() end end)
    pcall(function() if MM2HitboxFolder then MM2HitboxFolder:Destroy() end end)
end

local TabSettings = Window:CreateTab("Config & Temas", nil)

TabSettings:CreateSection("Seleção de Tema Rayfield")

local ThemeDropdown = TabSettings:CreateDropdown({
    Name = "Tema da Interface",
    Options = {"Bloom", "Default", "AmberGlow", "Amethyst", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    CurrentOption = {initialTheme},
    MultipleOptions = false,
    Flag = "settings_theme_dropdown",
    Callback = function(Option)
        local selected = type(Option) == "table" and Option[1] or Option
        if selected and Window.ModifyTheme then
            Window.ModifyTheme(selected)
            SaveTheme(selected)
            SafeNotify({
                Title = "Tema Atualizado",
                Content = "Tema alterado para " .. tostring(selected),
                Duration = 3,
                Image = 135247969077372
            })
        end
    end,
})

TabSettings:CreateButton({
    Name = "Restaurar Tema Padrão (Bloom)",
    Callback = function()
        if Window.ModifyTheme then
            Window.ModifyTheme("Bloom")
            SaveTheme("Bloom")
            SafeDropdownUpdate(ThemeDropdown, {"Bloom"})
            SafeNotify({
                Title = "Tema Padrão",
                Content = "Tema restaurado para Bloom.",
                Duration = 3,
                Image = 135247969077372
            })
        end
    end,
})

TabSettings:CreateSection("Cores do Hub (Acentos & Identidade)")

TabSettings:CreateColorPicker({
    Name = "Cor de Destaque (Accent)",
    Color = HubState.Theme.Accent,
    Flag = "settings_accent_color",
    Callback = function(Value)
        HubState.Theme.Accent = Value
    end,
})

TabSettings:CreateColorPicker({
    Name = "Cor do Murderer (MM2)",
    Color = HubState.Theme.Murderer,
    Flag = "settings_murder_color",
    Callback = function(Value)
        HubState.Theme.Murderer = Value
    end,
})

TabSettings:CreateColorPicker({
    Name = "Cor do Sheriff (MM2)",
    Color = HubState.Theme.Sheriff,
    Flag = "settings_sheriff_color",
    Callback = function(Value)
        HubState.Theme.Sheriff = Value
    end,
})

TabSettings:CreateColorPicker({
    Name = "Cor dos Inocentes (MM2)",
    Color = HubState.Theme.Innocent,
    Flag = "settings_innocent_color",
    Callback = function(Value)
        HubState.Theme.Innocent = Value
    end,
})

TabSettings:CreateSection("Controle & Gerenciamento do Hub")

TabSettings:CreateButton({
    Name = "Salvar Configurações no Disco",
    Callback = function()
        pcall(function()
            if Rayfield.SaveConfiguration then Rayfield:SaveConfiguration() end
            SaveTheme(GetSavedTheme())
            SafeNotify({
                Title = "Configurações Salvas",
                Content = "Todas as flags e temas foram persistidos com sucesso.",
                Duration = 4,
                Image = 135247969077372
            })
        end)
    end,
})

TabSettings:CreateButton({
    Name = "❌ Descarregar GoHub V13 (Fechar)",
    Callback = function()
        ResetAllStates()
        LightingEngine.ToggleShader(false)
        pcall(function() Rayfield:Destroy() end)
    end,
})

SafeNotify({
    Title = "GoHub V13 Pronto!",
    Content = "Todas as 8 abas e motores sintetizados com sucesso para Rayfield.",
    Duration = 5
})

print("[GoHub V13] Rayfield Synthesis & Background Engine Initialized 100% Successfully.")
