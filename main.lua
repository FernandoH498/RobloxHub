--[[
    Waifu Hub — Premium Edition (V8 Expanded)
    Target: Roblox Studio / Luau Engine
    Features:
      - Modular Architecture & Event Connection Pooling
      - TweenService UI/UX with Draggable Windows & Custom Animations
      - Universal Movement (Noclip, Flight, Infinite Jump, Speed Slider)
      - Teleport System (Select Player & Warp)
      - Fling Physics Controller
      - Custom Animations & Dances (Infinite Yield Style)
      - X-Ray Vision (Wall Transparency Engine)
      - Combat System (Aimbot FOV, Raycast Visibility)
      - MM2 Suite (Role ESP: Murderer/Sheriff/Innocent, Coin ESP, Auto Gun Grab)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ====================================================================
-- CONFIGURAÇÃO GLOBAL & ESTADO
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
        Murderer = Color3.fromRGB(255, 40, 40),
        Sheriff = Color3.fromRGB(40, 140, 255),
        Innocent = Color3.fromRGB(40, 255, 120),
        Hero = Color3.fromRGB(255, 220, 0),
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
        InfiniteJumpActive = false
    },
    Fling = {
        Active = false,
        TargetPlayer = nil
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
        PlayerESP = false,
        XRayActive = false
    },
    MM2 = {
        RoleESP = false,
        CoinESP = false,
        AutoGrabGun = false
    },
    Animation = {
        CurrentTrack = nil
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
-- MÓDULO DE FÍSICA & MOVIMENTAÇÃO UNIVERSAL
-- ====================================================================
local MovementEngine = {}

function MovementEngine.SetNoclip(enabled)
    HubState.Movement.NoclipActive = enabled
    if enabled then
        RegisterLoop("Core_Noclip", RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end))
    else
        DropLoop("Core_Noclip")
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
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
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end))
    else
        DropLoop("Core_InfJump")
    end
end

local FlyVectors = { W = 0, S = 0, A = 0, D = 0, Up = 0, Down = 0 }

function MovementEngine.SetFlight(enabled)
    HubState.Movement.FlightActive = enabled
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not enabled or not root then
        DropLoop("Fly_Render")
        DropLoop("Fly_KeyBegan")
        DropLoop("Fly_KeyEnded")
        if root then
            local bv = root:FindFirstChild("WaifuFlyBV")
            local bg = root:FindFirstChild("WaifuFlyBG")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        return
    end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "WaifuFlyBV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.Name = "WaifuFlyBG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.CFrame = root.CFrame
    bg.Parent = root

    RegisterLoop("Fly_KeyBegan", UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.W then FlyVectors.W = 1
        elseif input.KeyCode == Enum.KeyCode.S then FlyVectors.S = 1
        elseif input.KeyCode == Enum.KeyCode.A then FlyVectors.A = 1
        elseif input.KeyCode == Enum.KeyCode.D then FlyVectors.D = 1
        elseif input.KeyCode == Enum.KeyCode.Space then FlyVectors.Up = 1
        elseif input.KeyCode == Enum.KeyCode.LeftShift then FlyVectors.Down = 1 end
    end))

    RegisterLoop("Fly_KeyEnded", UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then FlyVectors.W = 0
        elseif input.KeyCode == Enum.KeyCode.S then FlyVectors.S = 0
        elseif input.KeyCode == Enum.KeyCode.A then FlyVectors.A = 0
        elseif input.KeyCode == Enum.KeyCode.D then FlyVectors.D = 0
        elseif input.KeyCode == Enum.KeyCode.Space then FlyVectors.Up = 0
        elseif input.KeyCode == Enum.KeyCode.LeftShift then FlyVectors.Down = 0 end
    end))

    RegisterLoop("Fly_Render", RunService.RenderStepped:Connect(function()
        if not HubState.Movement.FlightActive or not root or not root.Parent then return end
        local camCF = Camera.CFrame
        local dir = (camCF.LookVector * (FlyVectors.W - FlyVectors.S))
            + (camCF.RightVector * (FlyVectors.D - FlyVectors.A))
            + (Vector3.new(0, 1, 0) * (FlyVectors.Up - FlyVectors.Down))

        if dir.Magnitude > 0 then
            dir = dir.Unit * HubState.Movement.FlightSpeed
        end
        bv.Velocity = dir
        bg.CFrame = camCF
    end))
end

function MovementEngine.UpdateWalkSpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = HubState.Movement.SpeedActive and HubState.Movement.Speed or HubState.Movement.DefaultSpeed
    end
end

-- ====================================================================
-- MÓDULO DE FLING (DESVIO DE FÍSICA E COLISÃO)
-- ====================================================================
local FlingEngine = {}

function FlingEngine.ToggleFling(enabled, targetPlr)
    HubState.Fling.Active = enabled
    HubState.Fling.TargetPlayer = targetPlr

    if not enabled then
        DropLoop("Fling_Heartbeat")
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local bav = root:FindFirstChild("FlingRotVelocity")
            if bav then bav:Destroy() end
        end
        return
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "FlingRotVelocity"
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.AngularVelocity = Vector3.new(999999, 999999, 999999)
    bav.Parent = root

    RegisterLoop("Fling_Heartbeat", RunService.Heartbeat:Connect(function()
        if not HubState.Fling.Active then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        -- Forçar rotação extrema e noclip local durante o contato
        for _, part in ipairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        if HubState.Fling.TargetPlayer and HubState.Fling.TargetPlayer.Character then
            local targetRoot = HubState.Fling.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
                myRoot.AssemblyLinearVelocity = Vector3.new(999999, 999999, 999999)
            end
        else
            myRoot.AssemblyLinearVelocity = Vector3.new(999999, 999999, 999999)
        end
    end))
end

-- ====================================================================
-- MÓDULO DE TELEPORTE ENTRE JOGADORES
-- ====================================================================
local TeleportEngine = {}

function TeleportEngine.ToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if targetRoot and myRoot then
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    end
end

-- ====================================================================
-- MÓDULO DE ANIMAÇÕES & DANÇAS (INFINITE YIELD ENGINE)
-- ====================================================================
local AnimationEngine = {}

local EmoteDatabase = {
    ["Floss"] = "rbxassetid://10714340543",
    ["Dab"] = "rbxassetid://10714107111",
    ["Shuffle"] = "rbxassetid://10714349479",
    ["Electro Dance"] = "rbxassetid://10714352726",
    ["Zombie"] = "rbxassetid://10714347258",
    ["Hero Pose"] = "rbxassetid://10714344445",
    ["Wave"] = "rbxassetid://10714346580"
}

function AnimationEngine.PlayEmote(animId)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    
    if HubState.Animation.CurrentTrack then
        HubState.Animation.CurrentTrack:Stop()
        HubState.Animation.CurrentTrack = nil
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animId

    local track = animator:LoadAnimation(anim)
    track.Looped = true
    track:Play()
    HubState.Animation.CurrentTrack = track
end

function AnimationEngine.StopEmotes()
    if HubState.Animation.CurrentTrack then
        HubState.Animation.CurrentTrack:Stop()
        HubState.Animation.CurrentTrack = nil
    end
end

-- ====================================================================
-- MÓDULO X-RAY (TRANSPARÊNCIA SELETIVA DE ESTRUTURAS)
-- ====================================================================
local XRayEngine = {}
local OriginalTransparencyMap = {}

function XRayEngine.ToggleXRay(enabled)
    HubState.Visuals.XRayActive = enabled
    if enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character) then
                local isPlayerPart = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and obj:IsDescendantOf(p.Character) then
                        isPlayerPart = true
                        break
                    end
                end
                if not isPlayerPart and obj.Transparency < 0.5 then
                    OriginalTransparencyMap[obj] = obj.Transparency
                    obj.Transparency = 0.55
                end
            end
        end
    else
        for obj, origTrans in pairs(OriginalTransparencyMap) do
            if obj and obj.Parent then
                obj.Transparency = origTrans
            end
        end
        table.clear(OriginalTransparencyMap)
    end
end

-- ====================================================================
-- MÓDULO MURDER MYSTERY 2 (ROLE ESP, COINS & AUTO-GUN)
-- ====================================================================
local MM2Engine = {}
local MM2RoleHighlights = {}
local CoinHighlights = {}

local function CheckPlayerRole(player)
    if not player or not player.Character then return "Innocent" end
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character

    local function hasTool(name)
        if backpack and backpack:FindFirstChild(name) then return true end
        if character and character:FindFirstChild(name) then return true end
        return false
    end

    if hasTool("Knife") then
        return "Murderer"
    elseif hasTool("Gun") or hasTool("Revolver") then
        return "Sheriff"
    end
    return "Innocent"
end

function MM2Engine.UpdateRoleESP(enabled)
    HubState.MM2.RoleESP = enabled
    if not enabled then
        DropLoop("MM2_RoleESPLoop")
        for _, hl in pairs(MM2RoleHighlights) do
            if hl and hl.Parent then hl:Destroy() end
        end
        table.clear(MM2RoleHighlights)
        return
    end

    RegisterLoop("MM2_RoleESPLoop", RunService.Heartbeat:Connect(function()
        if not HubState.MM2.RoleESP then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local role = CheckPlayerRole(p)
                local hl = MM2RoleHighlights[p]
                if not hl or not hl.Parent then
                    hl = Instance.new("Highlight")
                    hl.Name = "MM2RoleHighlight"
                    hl.FillTransparency = 0.4
                    hl.OutlineTransparency = 0.1
                    hl.Adornee = p.Character
                    hl.Parent = p.Character
                    MM2RoleHighlights[p] = hl
                end

                if role == "Murderer" then
                    hl.FillColor = HubState.Theme.Murderer
                    hl.OutlineColor = Color3.fromRGB(255, 100, 100)
                elseif role == "Sheriff" then
                    hl.FillColor = HubState.Theme.Sheriff
                    hl.OutlineColor = Color3.fromRGB(100, 200, 255)
                else
                    hl.FillColor = HubState.Theme.Innocent
                    hl.OutlineColor = Color3.fromRGB(150, 255, 150)
                end
            end
        end
    end))
end

function MM2Engine.UpdateCoinESP(enabled)
    HubState.MM2.CoinESP = enabled
    if not enabled then
        DropLoop("MM2_CoinLoop")
        for _, hl in pairs(CoinHighlights) do
            if hl and hl.Parent then hl:Destroy() end
        end
        table.clear(CoinHighlights)
        return
    end

    RegisterLoop("MM2_CoinLoop", RunService.Heartbeat:Connect(function()
        if not HubState.MM2.CoinESP then return end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "Coin_Server" or obj.Name == "Coin" or obj.Name == "CoinContainer") then
                if not CoinHighlights[obj] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "CoinHighlight"
                    hl.FillColor = Color3.fromRGB(255, 215, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.3
                    hl.Adornee = obj
                    hl.Parent = obj
                    CoinHighlights[obj] = hl
                end
            end
        end
    end))
end

function MM2Engine.UpdateAutoGrabGun(enabled)
    HubState.MM2.AutoGrabGun = enabled
    if not enabled then
        DropLoop("MM2_AutoGunLoop")
        return
    end

    RegisterLoop("MM2_AutoGunLoop", RunService.Heartbeat:Connect(function()
        if not HubState.MM2.AutoGrabGun then return end
        local gunDrop = Workspace:FindFirstChild("GunDrop")
        if gunDrop and gunDrop:IsA("BasePart") then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot then
                myRoot.CFrame = gunDrop.CFrame * CFrame.new(0, 1, 0)
            end
        end
    end))
end

-- ====================================================================
-- MÓDULO DE COMBATE & AIMBOT
-- ====================================================================
local CombatEngine = {}

local function RaycastVisibility(part, targetChar)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, dir, params)
    if result then
        return result.Instance:IsDescendantOf(targetChar)
    end
    return true
end

function CombatEngine.GetBestTarget()
    local bestTarget = nil
    local minDistance = HubState.Combat.FOV
    local mouseLoc = Vector2.new(Mouse.X, Mouse.Y)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if HubState.Combat.TeamCheck and p.Team == LocalPlayer.Team then
                continue
            end
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local part = p.Character:FindFirstChild(HubState.Combat.TargetPart)
            if hum and hum.Health > 0 and part then
                local sPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local sPos = Vector2.new(sPoint.X, sPoint.Y)
                    local dist = (sPos - mouseLoc).Magnitude
                    if dist < minDistance then
                        if not HubState.Combat.VisibilityCheck or RaycastVisibility(part, p.Character) then
                            minDistance = dist
                            bestTarget = part
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

RegisterLoop("Aimbot_Loop", RunService.RenderStepped:Connect(function()
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
-- INTERFACE GRÁFICA V8 (UI/UX COMPLETA)
-- ====================================================================
local GuiRoot = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
local MainScreen = Instance.new("ScreenGui")
MainScreen.Name = "WaifuHub_V8_Premium"
MainScreen.ResetOnSpawn = false
MainScreen.Parent = GuiRoot

-- FOV Circle
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "AimbotFOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Size = UDim2.new(0, HubState.Combat.FOV * 2, 0, HubState.Combat.FOV * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = HubState.Combat.FOVCircleVisible and HubState.Combat.AimbotActive
FOVCircle.Parent = MainScreen

local FOVCircleCorner = Instance.new("UICorner")
FOVCircleCorner.CornerRadius = UDim.new(1, 0)
FOVCircleCorner.Parent = FOVCircle

local FOVCircleStroke = Instance.new("UIStroke")
FOVCircleStroke.Color = HubState.Theme.Accent
FOVCircleStroke.Thickness = 1.5
FOVCircleStroke.Parent = FOVCircle

RegisterLoop("UI_FOVCircleUpdate", RunService.RenderStepped:Connect(function()
    if FOVCircle.Visible then
        FOVCircle.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    end
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

local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0, 10)
WindowCorner.Parent = MainWindow

local WindowStroke = Instance.new("UIStroke")
WindowStroke.Color = HubState.Theme.Border
WindowStroke.Thickness = 1.8
WindowStroke.Parent = MainWindow

-- Animação Suave de Entrada
MainWindow.Size = UDim2.new(0, 0, 0, 0)
MainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(MainWindow, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 720, 0, 450),
    Position = UDim2.new(0.5, -360, 0.5, -225)
}):Play()

-- Draggable Suave
local isDragging, dragInput, dragStart, startPos
local function UpdateDrag(input)
    local delta = input.Position - dragStart
    TweenService:Create(MainWindow, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    }):Play()
end

MainWindow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

MainWindow.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and isDragging then
        UpdateDrag(input)
    end
end)

-- Barra Lateral (Sidebar)
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 200, 1, 0)
Sidebar.BackgroundColor3 = HubState.Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local WaifuImg = Instance.new("ImageLabel")
WaifuImg.Name = "WaifuAvatar"
WaifuImg.Size = UDim2.new(0, 56, 0, 56)
WaifuImg.Position = UDim2.new(0, 14, 0, 14)
WaifuImg.BackgroundColor3 = HubState.Theme.Card
WaifuImg.Image = HubState.Assets.WaifuImageId
WaifuImg.ScaleType = Enum.ScaleType.Fit
WaifuImg.Parent = Sidebar

local ImgCorner = Instance.new("UICorner")
ImgCorner.CornerRadius = UDim.new(1, 0)
ImgCorner.Parent = WaifuImg

local ImgStroke = Instance.new("UIStroke")
ImgStroke.Color = HubState.Theme.AccentGlow
ImgStroke.Thickness = 1.5
ImgStroke.Parent = WaifuImg

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Position = UDim2.new(0, 80, 0, 18)
HeaderTitle.Size = UDim2.new(0, 110, 0, 20)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.Text = "WAIFU HUB"
HeaderTitle.TextColor3 = HubState.Theme.Text
HeaderTitle.TextSize = 14
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Sidebar

local HeaderSub = Instance.new("TextLabel")
HeaderSub.Position = UDim2.new(0, 80, 0, 38)
HeaderSub.Size = UDim2.new(0, 110, 0, 16)
HeaderSub.BackgroundTransparency = 1
HeaderSub.Font = Enum.Font.Gotham
HeaderSub.Text = "PREMIUM V8"
HeaderSub.TextColor3 = HubState.Theme.AccentGlow
HeaderSub.TextSize = 11
HeaderSub.TextXAlignment = Enum.TextXAlignment.Left
HeaderSub.Parent = Sidebar

-- Lista de Abas
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

-- Painel de Conteúdo
local ContentPanel = Instance.new("Frame")
ContentPanel.Name = "ContentPanel"
ContentPanel.Size = UDim2.new(1, -220, 1, -20)
ContentPanel.Position = UDim2.new(0, 210, 0, 10)
ContentPanel.BackgroundTransparency = 1
ContentPanel.Parent = MainWindow

local Pages = {}
local CurrentPageRef = nil

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
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = HubState.Theme.Background
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = HubState.Theme.TextDim
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.Parent = TabListContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        if CurrentPageRef ~= Pages[name] then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(32, 28, 44),
                TextColor3 = HubState.Theme.Text
            }):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        if CurrentPageRef ~= Pages[name] then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = HubState.Theme.Background,
                TextColor3 = HubState.Theme.TextDim
            }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for tabId, p in pairs(Pages) do
            local otherBtn = TabListContainer:FindFirstChild(tabId .. "Btn")
            if p == Pages[name] then
                p.Visible = true
                CurrentPageRef = p
                TweenService:Create(btn, TweenInfo.new(0.25), {
                    BackgroundColor3 = HubState.Theme.Accent,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            else
                p.Visible = false
                if otherBtn then
                    TweenService:Create(otherBtn, TweenInfo.new(0.25), {
                        BackgroundColor3 = HubState.Theme.Background,
                        TextColor3 = HubState.Theme.TextDim
                    }):Play()
                end
            end
        end
    end)

    return btn
end

-- ====================================================================
-- COMPONENTES DE UI (TOGGLE, SLIDER, ACTION BUTTON, DROPDOWN)
-- ====================================================================
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

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

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

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = switch

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    switch.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(switch, TweenInfo.new(0.2), {
            BackgroundColor3 = state and HubState.Theme.Accent or Color3.fromRGB(45, 45, 60)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        callback(state)
    end)
end

-- Componente Slider com Linha e Bolinha Arrastável
local function AddSlider(parent, label, minVal, maxVal, defaultVal, callback)
    local val = defaultVal
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 56)
    frame.BackgroundColor3 = HubState.Theme.Card
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -60, 0, 24)
    txt.Position = UDim2.new(0, 12, 0, 4)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.Gotham
    txt.Text = label
    txt.TextColor3 = HubState.Theme.Text
    txt.TextSize = 12
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = frame

    local valDisplay = Instance.new("TextLabel")
    valDisplay.Size = UDim2.new(0, 50, 0, 24)
    valDisplay.Position = UDim2.new(1, -60, 0, 4)
    valDisplay.BackgroundTransparency = 1
    valDisplay.Font = Enum.Font.GothamBold
    valDisplay.Text = tostring(math.floor(val))
    valDisplay.TextColor3 = HubState.Theme.AccentGlow
    valDisplay.TextSize = 12
    valDisplay.TextXAlignment = Enum.TextXAlignment.Right
    valDisplay.Parent = frame

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Name = "Track"
    sliderTrack.Size = UDim2.new(1, -24, 0, 6)
    sliderTrack.Position = UDim2.new(0, 12, 0, 36)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = frame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = sliderTrack

    local fillBar = Instance.new("Frame")
    fillBar.Name = "Fill"
    local initialPercent = (val - minVal) / (maxVal - minVal)
    fillBar.Size = UDim2.new(initialPercent, 0, 1, 0)
    fillBar.BackgroundColor3 = HubState.Theme.Accent
    fillBar.BorderSizePixel = 0
    fillBar.Parent = sliderTrack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fillBar

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initialPercent, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = sliderTrack

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = HubState.Theme.AccentGlow
    knobStroke.Thickness = 1.5
    knobStroke.Parent = knob

    local isDraggingSlider = false
    local function UpdateSlider(inputX)
        local relX = math.clamp((inputX - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
        val = minVal + (maxVal - minVal) * relX
        fillBar.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, 0, 0.5, 0)
        valDisplay.Text = tostring(math.floor(val))
        callback(val)
    end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = true
            UpdateSlider(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input.Position.X)
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

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Accent }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Card }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)
end

-- ====================================================================
-- MONTAGEM DAS PÁGINAS DO HUB
-- ====================================================================

-- 1. UNIVERSAL PAGE
local universalPage = CreatePage("Universal")
AddSection(universalPage, "Física & Movimento")
AddToggle(universalPage, "Noclip (Desativar Colisão)", false, function(s)
    MovementEngine.SetNoclip(s)
end)
AddToggle(universalPage, "Infinite Jump (Pulo Contínuo)", false, function(s)
    MovementEngine.SetInfiniteJump(s)
end)
AddToggle(universalPage, "Fly Mode (W/A/S/D + Shift/Space)", false, function(s)
    MovementEngine.SetFlight(s)
end)
AddToggle(universalPage, "Ativar Velocidade Customizada", false, function(s)
    HubState.Movement.SpeedActive = s
    MovementEngine.UpdateWalkSpeed()
end)
AddSlider(universalPage, "Velocidade de Caminhada (SPS)", 16, 250, 32, function(v)
    HubState.Movement.Speed = v
    if HubState.Movement.SpeedActive then
        MovementEngine.UpdateWalkSpeed()
    end
end)
AddSection(universalPage, "Servidores")
AddButton(universalPage, "Server Hop (Pular para Menor Servidor)", function()
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
end)

-- 2. TELEPORTE & FLING PAGE
local tpPage = CreatePage("Jogadores")
AddSection(tpPage, "Ações Rápidas de Jogador")
local selectedPlayer = nil
local playerStatusLabel = Instance.new("TextLabel")
playerStatusLabel.Size = UDim2.new(1, 0, 0, 24)
playerStatusLabel.BackgroundTransparency = 1
playerStatusLabel.Font = Enum.Font.Gotham
playerStatusLabel.Text = "Jogador Selecionado: Nenhum"
playerStatusLabel.TextColor3 = HubState.Theme.AccentGlow
playerStatusLabel.TextSize = 12
playerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
playerStatusLabel.Parent = tpPage

AddButton(tpPage, "Teleportar para Jogador Selecionado", function()
    if selectedPlayer then
        TeleportEngine.ToPlayer(selectedPlayer)
    end
end)

AddToggle(tpPage, "Fling Mode (Girar e Desovar Alvo)", false, function(s)
    FlingEngine.ToggleFling(s, selectedPlayer)
end)

AddSection(tpPage, "Lista de Jogadores no Servidor")
local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, 0, 0, 160)
playerListFrame.BackgroundColor3 = HubState.Theme.Card
playerListFrame.Parent = tpPage

local plCorner = Instance.new("UICorner")
plCorner.CornerRadius = UDim.new(0, 6)
plCorner.Parent = playerListFrame

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, -10, 1, -10)
playerScroll.Position = UDim2.new(0, 5, 0, 5)
playerScroll.BackgroundTransparency = 1
playerScroll.ScrollBarThickness = 3
playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerScroll.Parent = playerListFrame

local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 4)
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Parent = playerScroll

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

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 4)
            c.Parent = pBtn

            pBtn.MouseButton1Click:Connect(function()
                selectedPlayer = p
                playerStatusLabel.Text = "Jogador Selecionado: " .. p.DisplayName
            end)
        end
    end
end
RefreshPlayerList()
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(RefreshPlayerList)

AddButton(tpPage, "Atualizar Lista de Jogadores", RefreshPlayerList)

-- 3. MURDER MYSTERY 2 PAGE
local mm2Page = CreatePage("MM2")
AddSection(mm2Page, "Detecção & Papéis (Role ESP)")
AddToggle(mm2Page, "Enxergar Assassino & Xerife (Role ESP)", false, function(s)
    MM2Engine.UpdateRoleESP(s)
end)
AddSection(mm2Page, "Moedas & Itens")
AddToggle(mm2Page, "Localização de Moedas (Coin ESP)", false, function(s)
    MM2Engine.UpdateCoinESP(s)
end)
AddToggle(mm2Page, "Auto-Coletar Arma ao Cair (Gun Drop)", false, function(s)
    MM2Engine.UpdateAutoGrabGun(s)
end)

-- 4. VISUAIS & X-RAY PAGE
local visualPage = CreatePage("Visuais")
AddSection(visualPage, "Visão Estrutural")
AddToggle(visualPage, "Ativar X-Ray (Paredes Transparentes)", false, function(s)
    XRayEngine.ToggleXRay(s)
end)
AddSection(visualPage, "Mira Automática (Aimbot)")
AddToggle(visualPage, "Aimbot Ativo (Botão Direito)", false, function(s)
    HubState.Combat.AimbotActive = s
    FOVCircle.Visible = s and HubState.Combat.FOVCircleVisible
end)
AddToggle(visualPage, "Verificação de Visibilidade (Raycast)", true, function(s)
    HubState.Combat.VisibilityCheck = s
end)
AddSlider(visualPage, "Raio do FOV", 50, 350, 120, function(v)
    HubState.Combat.FOV = v
    FOVCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end)

-- 5. ANIMAÇÕES & DANÇAS PAGE (INFINITE YIELD)
local animPage = CreatePage("Danças")
AddSection(animPage, "Emotes do Infinite Yield")
for emoteName, animId in pairs(EmoteDatabase) do
    AddButton(animPage, "Dança: " .. emoteName, function()
        AnimationEngine.PlayEmote(animId)
    end)
end
AddSection(animPage, "Controle")
AddButton(animPage, "Parar Todas as Danças", function()
    AnimationEngine.StopEmotes()
end)

-- Criar Botões das Abas
CreateTab("Universal", "⚡", 1)
CreateTab("Jogadores", "👤", 2)
CreateTab("MM2", "🔪", 3)
CreateTab("Visuais", "👁", 4)
CreateTab("Danças", "💃", 5)

-- Ativar Página Padrão
Pages["Universal"].Visible = true
CurrentPageRef = Pages["Universal"]
local defaultTabBtn = TabListContainer:FindFirstChild("UniversalBtn")
if defaultTabBtn then
    defaultTabBtn.BackgroundColor3 = HubState.Theme.Accent
    defaultTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end
