--[[
    Waifu Hub — Premium Edition (V8 Definitive)
    Target: Roblox Studio / Luau Engine
    Design:
      - Premium Sidebar UI with Waifu Avatar (ID: 135247969077372)
      - TweenService Animations (Smooth Entrance, Tab Switch, Hover Glow)
      - Close Button ("X") & Smooth Dragging
      - Flight Engine (BodyGyro + BodyVelocity com controle total de câmera)
      - Slider de Velocidade Interativo (Linha + Bolinha arrastável com persistência)
      - MM2 Suite (Role ESP: Assassino/Xerife, Coin ESP, Auto TP Arma Caída)
      - Jogadores (Lista dinâmica de servidores, Teleporte & Fling)
      - Visuais (X-Ray seletivo, Aimbot com FOV e Raycast)
      - Danças & Emotes (Infinite Yield style)
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
-- CONFIGURAÇÕES GLOBAIS & TEMA
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
        InfiniteJumpActive = false
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
        XRayActive = false
    },
    MM2 = {
        RoleESP = false,
        CoinESP = false,
        AutoGrabGun = false,
        Hitboxes = false
    },
    Animation = {
        CurrentTrack = nil
    }
}

-- ====================================================================
-- POOL DE CONEXÕES & CLEANUP
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
-- MÓDULO DE FÍSICA & MOVIMENTAÇÃO (FLIGHT & SPEED ROBUSTO)
-- ====================================================================
local MovementEngine = {}
local bgInstance, bvInstance

-- 1. VOO BASEADO NO MODELO DA V7 (BodyGyro + BodyVelocity + RenderStepped)
function MovementEngine.SetFlight(enabled)
    HubState.Movement.FlightActive = enabled
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not enabled or not hrp or not hum then
        DropLoop("Core_FlightRender")
        if bgInstance then bgInstance:Destroy(); bgInstance = nil end
        if bvInstance then bvInstance:Destroy(); bvInstance = nil end
        if hum then hum.PlatformStand = false end
        return
    end

    if bgInstance then bgInstance:Destroy() end
    if bvInstance then bvInstance:Destroy() end

    bgInstance = Instance.new("BodyGyro")
    bgInstance.Name = "Waifu_BodyGyro"
    bgInstance.P = 9e4
    bgInstance.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bgInstance.CFrame = hrp.CFrame
    bgInstance.Parent = hrp

    bvInstance = Instance.new("BodyVelocity")
    bvInstance.Name = "Waifu_BodyVelocity"
    bvInstance.Velocity = Vector3.zero
    bvInstance.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bvInstance.Parent = hrp

    hum.PlatformStand = true

    RegisterLoop("Core_FlightRender", RunService.RenderStepped:Connect(function()
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

-- 2. VELOCIDADE COM APLICAÇÃO CONTÍNUA
function MovementEngine.ApplyWalkSpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = HubState.Movement.SpeedActive and HubState.Movement.Speed or HubState.Movement.DefaultSpeed
    end
end

RegisterLoop("Speed_Heartbeat", RunService.Heartbeat:Connect(function()
    if HubState.Movement.SpeedActive then
        MovementEngine.ApplyWalkSpeed()
    end
end))

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.4)
    if HubState.Movement.SpeedActive then
        MovementEngine.ApplyWalkSpeed()
    end
end)

-- 3. NOCLIP
function MovementEngine.SetNoclip(enabled)
    HubState.Movement.NoclipActive = enabled
    if enabled then
        RegisterLoop("Core_Noclip", RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
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

-- 4. INFINITE JUMP
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

-- ====================================================================
-- MÓDULO DE FLING
-- ====================================================================
local FlingEngine = {}
local flingingActive = false

function FlingEngine.Toggle(enabled)
    flingingActive = enabled
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if enabled then
        local spin = Instance.new("BodyAngularVelocity")
        spin.Name = "FlingSpin"
        spin.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        spin.AngularVelocity = Vector3.new(0, 50000, 0)
        spin.Parent = hrp
    else
        if hrp:FindFirstChild("FlingSpin") then
            hrp.FlingSpin:Destroy()
        end
    end
end

-- ====================================================================
-- MÓDULO DE ANIMAÇÕES & DANÇAS (INFINITE YIELD)
-- ====================================================================
local AnimationEngine = {}
local EmoteList = {
    ["Floss"] = "rbxassetid://10714340543",
    ["Dab"] = "rbxassetid://10714107111",
    ["Shuffle"] = "rbxassetid://10714349479",
    ["Electro Dance"] = "rbxassetid://10714352726",
    ["Zombie"] = "rbxassetid://10714347258",
    ["Hero Pose"] = "rbxassetid://10714344445",
    ["Wave"] = "rbxassetid://10714346580"
}

function AnimationEngine.Play(animId)
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

function AnimationEngine.Stop()
    if HubState.Animation.CurrentTrack then
        HubState.Animation.CurrentTrack:Stop()
        HubState.Animation.CurrentTrack = nil
    end
end

-- ====================================================================
-- MÓDULO X-RAY
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
                    if p.Character and obj:IsDescendantOf(p.Character) then
                        isPlayerPart = true
                        break
                    end
                end
                if not isPlayerPart and obj.Transparency < 0.5 then
                    SavedTransparencies[obj] = obj.Transparency
                    obj.Transparency = 0.55
                end
            end
        end
    else
        for obj, orig in pairs(SavedTransparencies) do
            if obj and obj.Parent then
                obj.Transparency = orig
            end
        end
        table.clear(SavedTransparencies)
    end
end

-- ====================================================================
-- MÓDULO MURDER MYSTERY 2
-- ====================================================================
local MM2Engine = {}
local MM2RoleFolder = Instance.new("Folder", game:GetService("CoreGui")); MM2RoleFolder.Name = "Waifu_MM2_Roles"
local MM2CoinFolder = Instance.new("Folder", game:GetService("CoreGui")); MM2CoinFolder.Name = "Waifu_MM2_Coins"
local MM2HitboxFolder = Instance.new("Folder", game:GetService("CoreGui")); MM2HitboxFolder.Name = "Waifu_MM2_Hitboxes"

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
                    local hl = Instance.new("Highlight")
                    hl.Adornee = p.Character
                    hl.FillColor = color
                    hl.OutlineColor = color
                    hl.FillTransparency = 0.5
                    hl.Parent = MM2RoleFolder

                    local bgui = Instance.new("BillboardGui")
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
                    bgui.Parent = MM2RoleFolder
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
                local hl = Instance.new("Highlight")
                hl.Adornee = obj
                hl.FillColor = Color3.fromRGB(255, 215, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.3
                hl.Parent = MM2CoinFolder
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
                local box = Instance.new("BoxHandleAdornment")
                box.Adornee = p.Character.HumanoidRootPart
                box.Size = Vector3.new(3.5, 4.5, 3.5)
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.Transparency = 0.6
                box.AlwaysOnTop = true
                box.Parent = MM2HitboxFolder
            end
        end
    end))
end

-- ====================================================================
-- MÓDULO DE COMBATE (AIMBOT)
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
    if result then
        return result.Instance:IsDescendantOf(targetChar)
    end
    return true
end

function CombatEngine.GetBestTarget()
    local best = nil
    local minDist = HubState.Combat.FOV
    local mouseLoc = Vector2.new(Mouse.X, Mouse.Y)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if HubState.Combat.TeamCheck and p.Team == LocalPlayer.Team then continue end
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
-- FRONT-END PREMIUM ORIGINAL (SIDEBAR, TWEENS & WAIFU AVATAR)
-- ====================================================================
local GuiRoot = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Destruir versão anterior se existir
if GuiRoot:FindFirstChild("WaifuHub_V8_Definitive") then
    GuiRoot.WaifuHub_V8_Definitive:Destroy()
end

local MainScreen = Instance.new("ScreenGui")
MainScreen.Name = "WaifuHub_V8_Definitive"
MainScreen.ResetOnSpawn = false
MainScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainScreen.Parent = GuiRoot

-- Círculo Indicador do FOV
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Size = UDim2.new(0, HubState.Combat.FOV * 2, 0, HubState.Combat.FOV * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = HubState.Combat.FOVCircleVisible and HubState.Combat.AimbotActive
FOVCircle.Parent = MainScreen

local FOVCorner = Instance.new("UICorner", FOVCircle)
FOVCorner.CornerRadius = UDim.new(1, 0)
local FOVStroke = Instance.new("UIStroke", FOVCircle)
FOVStroke.Color = HubState.Theme.Accent
FOVStroke.Thickness = 1.5

RegisterLoop("UI_FOVFollow", RunService.RenderStepped:Connect(function()
    if FOVCircle.Visible then
        FOVCircle.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    end
end))

-- Janela Principal (Design Premium Dark + Bordas Roxas)
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 720, 0, 450)
MainWindow.Position = UDim2.new(0.5, -360, 0.5, -225)
MainWindow.BackgroundColor3 = HubState.Theme.Background
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = MainScreen

local WindowCorner = Instance.new("UICorner", MainWindow)
WindowCorner.CornerRadius = UDim.new(0, 10)
local WindowStroke = Instance.new("UIStroke", MainWindow)
WindowStroke.Color = HubState.Theme.Border
WindowStroke.Thickness = 1.8

-- Animação de Entrada
MainWindow.Size = UDim2.new(0, 0, 0, 0)
MainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(MainWindow, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 720, 0, 450),
    Position = UDim2.new(0.5, -360, 0.5, -225)
}):Play()

-- Mecanismo Draggable Fluido
local isDragging, dragInput, dragStart, startPos
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
        local delta = input.Position - dragStart
        TweenService:Create(MainWindow, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        }):Play()
    end
end)

-- Botão de Fechar ("X")
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

local CloseCorner = Instance.new("UICorner", CloseButton)
CloseCorner.CornerRadius = UDim.new(0, 6)
local CloseStroke = Instance.new("UIStroke", CloseButton)
CloseStroke.Color = HubState.Theme.Close
CloseStroke.Thickness = 1

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Close, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Card, TextColor3 = HubState.Theme.Close }):Play()
end)

CloseButton.MouseButton1Click:Connect(function()
    MovementEngine.SetFlight(false)
    MovementEngine.SetNoclip(false)
    MovementEngine.SetInfiniteJump(false)
    FlingEngine.Toggle(false)
    AnimationEngine.Stop()
    XRayEngine.Toggle(false)
    MM2Engine.ToggleRoleESP(false)
    MM2Engine.ToggleCoinESP(false)
    MM2Engine.ToggleAutoGrabGun(false)
    MM2Engine.ToggleHitboxes(false)

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end

    for tag, conn in pairs(ConnectionPool) do
        conn:Disconnect()
    end
    table.clear(ConnectionPool)

    MM2RoleFolder:Destroy()
    MM2CoinFolder:Destroy()
    MM2HitboxFolder:Destroy()
    MainScreen:Destroy()
end)

-- Barra Lateral (Sidebar) com Avatar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 200, 1, 0)
Sidebar.BackgroundColor3 = HubState.Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow

local SidebarCorner = Instance.new("UICorner", Sidebar)
SidebarCorner.CornerRadius = UDim.new(0, 10)

local WaifuAvatar = Instance.new("ImageLabel")
WaifuAvatar.Name = "WaifuAvatar"
WaifuAvatar.Size = UDim2.new(0, 54, 0, 54)
WaifuAvatar.Position = UDim2.new(0, 14, 0, 14)
WaifuAvatar.BackgroundColor3 = HubState.Theme.Card
WaifuAvatar.Image = HubState.Assets.WaifuImageId
WaifuAvatar.ScaleType = Enum.ScaleType.Fit
WaifuAvatar.Parent = Sidebar

local AvatarCorner = Instance.new("UICorner", WaifuAvatar)
AvatarCorner.CornerRadius = UDim.new(1, 0)
local AvatarStroke = Instance.new("UIStroke", WaifuAvatar)
AvatarStroke.Color = HubState.Theme.AccentGlow
AvatarStroke.Thickness = 1.5

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Position = UDim2.new(0, 78, 0, 16)
TitleLabel.Size = UDim2.new(0, 110, 0, 20)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "WAIFU HUB"
TitleLabel.TextColor3 = HubState.Theme.Text
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Sidebar

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Position = UDim2.new(0, 78, 0, 36)
SubTitleLabel.Size = UDim2.new(0, 110, 0, 16)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Font = Enum.Font.Gotham
SubTitleLabel.Text = "PREMIUM V8"
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

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)

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

-- ====================================================================
-- COMPONENTES DA UI (SEÇÃO, TOGGLE, SLIDER PRECISO, BOTÃO)
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

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

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

    local switchCorner = Instance.new("UICorner", switch)
    switchCorner.CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = switch

    local circleCorner = Instance.new("UICorner", circle)
    circleCorner.CornerRadius = UDim.new(1, 0)

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

-- Slider Responsivo (com Linha, Preenchimento e Bolinha Arrastável)
local function AddSlider(parent, label, minVal, maxVal, defaultVal, callback)
    local val = defaultVal
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 54)
    frame.BackgroundColor3 = HubState.Theme.Card
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

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

    local trackCorner = Instance.new("UICorner", track)
    trackCorner.CornerRadius = UDim.new(1, 0)

    local initialPct = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(initialPct, 0, 1, 0)
    fill.BackgroundColor3 = HubState.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initialPct, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.Parent = track

    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)
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

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Accent }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = HubState.Theme.Card }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)
end

-- ====================================================================
-- MONTAGEM DAS ABAS DO HUB
-- ====================================================================

-- 1. ABA UNIVERSAL
local universalPage = CreatePage("Universal")
AddSection(universalPage, "Física & Movimento")
AddToggle(universalPage, "Noclip (Atravessar Paredes)", false, function(s)
    MovementEngine.SetNoclip(s)
end)
AddToggle(universalPage, "Infinite Jump (Pulo Infinito)", false, function(s)
    MovementEngine.SetInfiniteJump(s)
end)
AddToggle(universalPage, "Ativar Voo (W/A/S/D + Espaço/Shift)", false, function(s)
    MovementEngine.SetFlight(s)
end)
AddSlider(universalPage, "Velocidade de Voo", 10, 250, 50, function(v)
    HubState.Movement.FlightSpeed = v
end)
AddToggle(universalPage, "Ativar Velocidade Customizada", false, function(s)
    HubState.Movement.SpeedActive = s
    MovementEngine.ApplyWalkSpeed()
end)
AddSlider(universalPage, "Velocidade de Caminhada (SPS)", 16, 250, 32, function(v)
    HubState.Movement.Speed = v
    if HubState.Movement.SpeedActive then
        MovementEngine.ApplyWalkSpeed()
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

-- 2. ABA JOGADORES (SELEÇÃO, TP & FLING)
local tpPage = CreatePage("Jogadores")
AddSection(tpPage, "Ações Rápidas de Jogador")
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

AddButton(tpPage, "Teleportar para Jogador Selecionado", function()
    if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot then
            myRoot.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
    end
end)

AddToggle(tpPage, "Ativar Fling (Girar e Lançar)", false, function(s)
    FlingEngine.Toggle(s)
end)

AddSection(tpPage, "Lista de Jogadores no Servidor")
local playerListContainer = Instance.new("Frame")
playerListContainer.Size = UDim2.new(1, 0, 0, 150)
playerListContainer.BackgroundColor3 = HubState.Theme.Card
playerListContainer.Parent = tpPage

local plcCorner = Instance.new("UICorner", playerListContainer)
plcCorner.CornerRadius = UDim.new(0, 6)

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

            local c = Instance.new("UICorner", pBtn)
            c.CornerRadius = UDim.new(0, 4)

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

-- 3. ABA MURDER MYSTERY 2
local mm2Page = CreatePage("MM2")
AddSection(mm2Page, "Detecção & Papéis (Role ESP)")
AddToggle(mm2Page, "Ver Assassino & Xerife (Role ESP)", false, function(s)
    MM2Engine.ToggleRoleESP(s)
end)
AddSection(mm2Page, "Moedas & Itens")
AddToggle(mm2Page, "ESP de Moedas (Coin ESP)", false, function(s)
    MM2Engine.ToggleCoinESP(s)
end)
AddToggle(mm2Page, "Auto-Coletar Arma ao Cair (Gun Drop)", false, function(s)
    MM2Engine.ToggleAutoGrabGun(s)
end)
AddSection(mm2Page, "Combate")
AddToggle(mm2Page, "Hitboxes Expandidas", false, function(s)
    MM2Engine.ToggleHitboxes(s)
end)

-- 4. ABA VISUAIS & MIRA
local visualPage = CreatePage("Visuais")
AddSection(visualPage, "Visão")
AddToggle(visualPage, "Ativar X-Ray (Paredes Transparentes)", false, function(s)
    XRayEngine.Toggle(s)
end)
AddSection(visualPage, "Aimbot com Raycast")
AddToggle(visualPage, "Aimbot Ativo (Segurar Botão Direito)", false, function(s)
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

-- 5. ABA DANÇAS (INFINITE YIELD)
local animPage = CreatePage("Danças")
AddSection(animPage, "Emotes Especiais")
for emoteName, animId in pairs(EmoteList) do
    AddButton(animPage, "Dança: " .. emoteName, function()
        AnimationEngine.Play(animId)
    end)
end
AddSection(animPage, "Controle")
AddButton(animPage, "Parar Todas as Danças", function()
    AnimationEngine.Stop()
end)

-- Criar Botões das Abas na Sidebar
CreateTab("Universal", "⚡", 1)
CreateTab("Jogadores", "👤", 2)
CreateTab("MM2", "🔪", 3)
CreateTab("Visuais", "👁", 4)
CreateTab("Danças", "💃", 5)

-- Ativar Aba Padrão
Pages["Universal"].Visible = true
CurrentPage = Pages["Universal"]
local defaultTabBtn = TabListContainer:FindFirstChild("UniversalBtn")
if defaultTabBtn then
    defaultTabBtn.BackgroundColor3 = HubState.Theme.Accent
    defaultTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

print("Waifu Hub V8 Definitive Loaded Cleanly!")
