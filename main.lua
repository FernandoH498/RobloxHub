--[[
    Waifu Hub — Premium Edition (V8)
    Target: Roblox Studio / Luau Engine
    Features: Modular Architecture, TweenService UI/UX, RunService event-driven logic, Universal Movement, Aimbot FOV/Raycast, Highlight ESP
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
local AppConfig = {
    Theme = {
        Background = Color3.fromRGB(15, 15, 22),
        Sidebar = Color3.fromRGB(22, 22, 32),
        CardBackground = Color3.fromRGB(28, 28, 40),
        Accent = Color3.fromRGB(148, 0, 211),
        AccentBright = Color3.fromRGB(180, 50, 255),
        TextPrimary = Color3.fromRGB(245, 245, 250),
        TextMuted = Color3.fromRGB(150, 150, 170),
        Success = Color3.fromRGB(60, 210, 120),
        Border = Color3.fromRGB(148, 0, 211)
    },
    Assets = {
        WaifuImageId = "rbxassetid://135247969077372"
    },
    Movement = {
        WalkSpeed = 16,
        WalkSpeedCustom = 32,
        WalkSpeedEnabled = false,
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
        ESPActive = false,
        MM2CoinESP = false,
        JailbreakAura = false
    }
}

-- ====================================================================
-- GERENCIADOR DE CONEXÕES (DESACOPLAMENTO DE LOOPS)
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
-- NÚCLEO DE MOVIMENTAÇÃO UNIVERSAL
-- ====================================================================
local UniversalController = {}

function UniversalController.ToggleNoclip(state)
    AppConfig.Movement.NoclipActive = state
    if state then
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

function UniversalController.ToggleInfiniteJump(state)
    AppConfig.Movement.InfiniteJumpActive = state
    if state then
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

local FlightKeys = { W = 0, S = 0, A = 0, D = 0, Space = 0, Shift = 0 }

function UniversalController.ToggleFlight(state)
    AppConfig.Movement.FlightActive = state
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not state or not root then
        DropLoop("Core_FlightRender")
        DropLoop("Core_FlightKeyBegan")
        DropLoop("Core_FlightKeyEnded")
        if root then
            local bv = root:FindFirstChild("HubFlyBV")
            local bg = root:FindFirstChild("HubFlyBG")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        return
    end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "HubFlyBV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.Name = "HubFlyBG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.CFrame = root.CFrame
    bg.Parent = root

    RegisterLoop("Core_FlightKeyBegan", UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.W then FlightKeys.W = 1
        elseif input.KeyCode == Enum.KeyCode.S then FlightKeys.S = 1
        elseif input.KeyCode == Enum.KeyCode.A then FlightKeys.A = 1
        elseif input.KeyCode == Enum.KeyCode.D then FlightKeys.D = 1
        elseif input.KeyCode == Enum.KeyCode.Space then FlightKeys.Space = 1
        elseif input.KeyCode == Enum.KeyCode.LeftShift then FlightKeys.Shift = 1 end
    end))

    RegisterLoop("Core_FlightKeyEnded", UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then FlightKeys.W = 0
        elseif input.KeyCode == Enum.KeyCode.S then FlightKeys.S = 0
        elseif input.KeyCode == Enum.KeyCode.A then FlightKeys.A = 0
        elseif input.KeyCode == Enum.KeyCode.D then FlightKeys.D = 0
        elseif input.KeyCode == Enum.KeyCode.Space then FlightKeys.Space = 0
        elseif input.KeyCode == Enum.KeyCode.LeftShift then FlightKeys.Shift = 0 end
    end))

    RegisterLoop("Core_FlightRender", RunService.RenderStepped:Connect(function()
        if not AppConfig.Movement.FlightActive or not root or not root.Parent then return end
        local camCFrame = Camera.CFrame
        local dir = (camCFrame.LookVector * (FlightKeys.W - FlightKeys.S))
            + (camCFrame.RightVector * (FlightKeys.D - FlightKeys.A))
            + (Vector3.new(0, 1, 0) * (FlightKeys.Space - FlightKeys.Shift))

        if dir.Magnitude > 0 then
            dir = dir.Unit * AppConfig.Movement.FlightSpeed
        end
        bv.Velocity = dir
        bg.CFrame = camCFrame
    end))
end

function UniversalController.SetWalkSpeed(speed, enabled)
    AppConfig.Movement.WalkSpeedCustom = speed
    AppConfig.Movement.WalkSpeedEnabled = enabled
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = enabled and speed or AppConfig.Movement.WalkSpeed
    end
end

function UniversalController.ExecuteServerHop()
    task.spawn(function()
        local placeId = game.PlaceId
        local serversApi = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(serversApi))
        end)

        if success and response and response.data then
            for _, srv in ipairs(response.data) do
                if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(placeId, srv.id, LocalPlayer)
                    return
                end
            end
        end
        TeleportService:Teleport(placeId, LocalPlayer)
    end)
end

-- ====================================================================
-- SISTEMA DE COMBATE & AIMBOT
-- ====================================================================
local CombatSystem = {}

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

function CombatSystem.GetBestTarget()
    local bestTarget = nil
    local minDistance = AppConfig.Combat.FOV
    local mouseLoc = Vector2.new(Mouse.X, Mouse.Y)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if AppConfig.Combat.TeamCheck and p.Team == LocalPlayer.Team then
                continue
            end
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local part = p.Character:FindFirstChild(AppConfig.Combat.TargetPart)
            if hum and hum.Health > 0 and part then
                local sPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local sPos = Vector2.new(sPoint.X, sPoint.Y)
                    local dist = (sPos - mouseLoc).Magnitude
                    if dist < minDistance then
                        if not AppConfig.Combat.VisibilityCheck or RaycastVisibility(part, p.Character) then
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

RegisterLoop("Combat_AimbotLoop", RunService.RenderStepped:Connect(function()
    if not AppConfig.Combat.AimbotActive then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local target = CombatSystem.GetBestTarget()
    if target then
        local camCFrame = Camera.CFrame
        local targetCFrame = CFrame.new(camCFrame.Position, target.Position)
        Camera.CFrame = camCFrame:Lerp(targetCFrame, math.clamp(AppConfig.Combat.Smoothness, 0.05, 1))
    end
end))

-- ====================================================================
-- SISTEMA DE VISUAIS (ESP HIGHLIGHT)
-- ====================================================================
local VisualsManager = {}

local function AttachHighlight(player)
    if player == LocalPlayer then return end

    local function setup(char)
        if not char then return end
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not root then return end

        local hl = char:FindFirstChild("Waifu_ESP_Highlight")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "Waifu_ESP_Highlight"
            hl.FillColor = AppConfig.Theme.Accent
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0.1
            hl.Adornee = char
            hl.Enabled = AppConfig.Visuals.ESPActive
            hl.Parent = char
        end
    end

    player.CharacterAdded:Connect(setup)
    if player.Character then setup(player.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do
    AttachHighlight(p)
end
Players.PlayerAdded:Connect(AttachHighlight)

function VisualsManager.ToggleESP(state)
    AppConfig.Visuals.ESPActive = state
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("Waifu_ESP_Highlight")
            if hl then hl.Enabled = state end
        end
    end
end

-- ====================================================================
-- INTERFACE GRÁFICA (UI/UX PREMIUM V8)
-- ====================================================================
local parentContainer = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
local MainScreen = Instance.new("ScreenGui")
MainScreen.Name = "WaifuHub_V8_Universal"
MainScreen.ResetOnSpawn = false
MainScreen.Parent = parentContainer

-- FOV Circle
local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "FOVIndicator"
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Size = UDim2.new(0, AppConfig.Combat.FOV * 2, 0, AppConfig.Combat.FOV * 2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = AppConfig.Combat.FOVCircleVisible and AppConfig.Combat.AimbotActive
FOVFrame.Parent = MainScreen

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVFrame

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = AppConfig.Theme.Accent
FOVStroke.Thickness = 1.5
FOVStroke.Parent = FOVFrame

RegisterLoop("UI_FOVFollow", RunService.RenderStepped:Connect(function()
    if FOVFrame.Visible then
        FOVFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    end
end))

-- Janela Principal
local Window = Instance.new("Frame")
Window.Name = "HubWindow"
Window.Size = UDim2.new(0, 680, 0, 420)
Window.Position = UDim2.new(0.5, -340, 0.5, -210)
Window.BackgroundColor3 = AppConfig.Theme.Background
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
Window.Parent = MainScreen

local WindowCorner = Instance.new("UICorner")
WindowCorner.CornerRadius = UDim.new(0, 10)
WindowCorner.Parent = Window

local WindowStroke = Instance.new("UIStroke")
WindowStroke.Color = AppConfig.Theme.Border
WindowStroke.Thickness = 1.8
WindowStroke.Parent = Window

-- Animação de Entrada
Window.Size = UDim2.new(0, 0, 0, 0)
Window.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(Window, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 680, 0, 420),
    Position = UDim2.new(0.5, -340, 0.5, -210)
}):Play()

-- Mecanismo Draggable Fluido
local isDragging, dragInput, dragStart, startPos
local function UpdateDrag(input)
    local delta = input.Position - dragStart
    TweenService:Create(Window, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    }):Play()
end

Window.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStart = input.Position
        startPos = Window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

Window.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and isDragging then
        UpdateDrag(input)
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 190, 1, 0)
Sidebar.BackgroundColor3 = AppConfig.Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Window

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 10)
SidebarCorner.Parent = Sidebar

local WaifuImg = Instance.new("ImageLabel")
WaifuImg.Name = "WaifuHeader"
WaifuImg.Size = UDim2.new(0, 56, 0, 56)
WaifuImg.Position = UDim2.new(0, 14, 0, 14)
WaifuImg.BackgroundColor3 = AppConfig.Theme.CardBackground
WaifuImg.Image = AppConfig.Assets.WaifuImageId
WaifuImg.ScaleType = Enum.ScaleType.Fit
WaifuImg.Parent = Sidebar

local ImgCorner = Instance.new("UICorner")
ImgCorner.CornerRadius = UDim.new(1, 0)
ImgCorner.Parent = WaifuImg

local ImgStroke = Instance.new("UIStroke")
ImgStroke.Color = AppConfig.Theme.AccentBright
ImgStroke.Thickness = 1.5
ImgStroke.Parent = WaifuImg

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Position = UDim2.new(0, 78, 0, 18)
HeaderTitle.Size = UDim2.new(0, 100, 0, 20)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.Text = "WAIFU HUB"
HeaderTitle.TextColor3 = AppConfig.Theme.TextPrimary
HeaderTitle.TextSize = 14
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Sidebar

local HeaderSub = Instance.new("TextLabel")
HeaderSub.Position = UDim2.new(0, 78, 0, 38)
HeaderSub.Size = UDim2.new(0, 100, 0, 16)
HeaderSub.BackgroundTransparency = 1
HeaderSub.Font = Enum.Font.Gotham
HeaderSub.Text = "PREMIUM V8"
HeaderSub.TextColor3 = AppConfig.Theme.AccentBright
HeaderSub.TextSize = 11
HeaderSub.TextXAlignment = Enum.TextXAlignment.Left
HeaderSub.Parent = Sidebar

local TabList = Instance.new("Frame")
TabList.Name = "TabList"
TabList.Size = UDim2.new(1, -20, 1, -100)
TabList.Position = UDim2.new(0, 10, 0, 85)
TabList.BackgroundTransparency = 1
TabList.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabList

local ContentPanel = Instance.new("Frame")
ContentPanel.Name = "ContentPanel"
ContentPanel.Size = UDim2.new(1, -210, 1, -20)
ContentPanel.Position = UDim2.new(0, 200, 0, 10)
ContentPanel.BackgroundTransparency = 1
ContentPanel.Parent = Window

local TabPages = {}
local CurrentPageRef = nil

local function MakePage(id)
    local page = Instance.new("ScrollingFrame")
    page.Name = id .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = AppConfig.Theme.Accent
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

    TabPages[id] = page
    return page
end

local function MakeTab(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Btn"
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = AppConfig.Theme.Background
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = AppConfig.Theme.TextMuted
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.Parent = TabList

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        if CurrentPageRef ~= TabPages[name] then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(32, 28, 44),
                TextColor3 = AppConfig.Theme.TextPrimary
            }):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        if CurrentPageRef ~= TabPages[name] then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = AppConfig.Theme.Background,
                TextColor3 = AppConfig.Theme.TextMuted
            }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for tabId, p in pairs(TabPages) do
            local otherBtn = TabList:FindFirstChild(tabId .. "Btn")
            if p == TabPages[name] then
                p.Visible = true
                CurrentPageRef = p
                TweenService:Create(btn, TweenInfo.new(0.25), {
                    BackgroundColor3 = AppConfig.Theme.Accent,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            else
                p.Visible = false
                if otherBtn then
                    TweenService:Create(otherBtn, TweenInfo.new(0.25), {
                        BackgroundColor3 = AppConfig.Theme.Background,
                        TextColor3 = AppConfig.Theme.TextMuted
                    }):Play()
                end
            end
        end
    end)

    return btn
end

-- Construtores de Componentes
local function BuildSection(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = string.upper(text)
    lbl.TextColor3 = AppConfig.Theme.AccentBright
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
end

local function BuildToggle(parent, label, defState, callback)
    local state = defState
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = AppConfig.Theme.CardBackground
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
    txt.TextColor3 = AppConfig.Theme.TextPrimary
    txt.TextSize = 13
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = frame

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 42, 0, 22)
    switch.Position = UDim2.new(1, -52, 0.5, -11)
    switch.BackgroundColor3 = state and AppConfig.Theme.Accent or Color3.fromRGB(45, 45, 60)
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
            BackgroundColor3 = state and AppConfig.Theme.Accent or Color3.fromRGB(45, 45, 60)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        callback(state)
    end)
end

local function BuildActionBtn(parent, label, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = AppConfig.Theme.CardBackground
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = "  " .. label
    btn.TextColor3 = AppConfig.Theme.TextPrimary
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = AppConfig.Theme.Accent
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = AppConfig.Theme.CardBackground
        }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)
end

-- ====================================================================
-- MONTAGEM DAS ABAS
-- ====================================================================

-- 1. Universal Page
local universalPage = MakePage("Universal")
BuildSection(universalPage, "Física & Movimento")
BuildToggle(universalPage, "Noclip (Desativar Colisão)", false, function(s)
    UniversalController.ToggleNoclip(s)
end)
BuildToggle(universalPage, "Infinite Jump (Pulo Infinito)", false, function(s)
    UniversalController.ToggleInfiniteJump(s)
end)
BuildToggle(universalPage, "Fly Mode (W/A/S/D + Shift/Space)", false, function(s)
    UniversalController.ToggleFlight(s)
end)
BuildToggle(universalPage, "Velocidade Aumentada (32 SPS)", false, function(s)
    UniversalController.SetWalkSpeed(32, s)
end)
BuildSection(universalPage, "Servidores")
BuildActionBtn(universalPage, "Executar Server Hop (Menor Lotação)", function()
    UniversalController.ExecuteServerHop()
end)

-- 2. Combat Page
local combatPage = MakePage("Combate")
BuildSection(combatPage, "Mecanismo de Mira")
BuildToggle(combatPage, "Aimbot Ativo (Segurar Botão Direito)", false, function(s)
    AppConfig.Combat.AimbotActive = s
    FOVFrame.Visible = s and AppConfig.Combat.FOVCircleVisible
end)
BuildToggle(combatPage, "Verificação de Visibilidade (Raycast)", true, function(s)
    AppConfig.Combat.VisibilityCheck = s
end)
BuildToggle(combatPage, "Verificação de Time", false, function(s)
    AppConfig.Combat.TeamCheck = s
end)

-- 3. Visuals Page
local visualsPage = MakePage("Visuais")
BuildSection(visualsPage, "Rastreamento")
BuildToggle(visualsPage, "Player ESP (Highlight Roxo)", false, function(s)
    VisualsManager.ToggleESP(s)
end)

-- 4. Games Page
local gamesPage = MakePage("Específicos")
BuildSection(gamesPage, "Murder Mystery 2")
BuildToggle(gamesPage, "Rastreamento de Moedas", false, function(s)
    AppConfig.Visuals.MM2CoinESP = s
end)
BuildSection(gamesPage, "Jailbreak")
BuildToggle(gamesPage, "Aura de Interação Rápida", false, function(s)
    AppConfig.Visuals.JailbreakAura = s
end)

-- Inicializar Abas
MakeTab("Universal", "⚡", 1)
MakeTab("Combate", "🎯", 2)
MakeTab("Visuais", "👁", 3)
MakeTab("Específicos", "🎮", 4)

-- Ativar aba padrão
TabPages["Universal"].Visible = true
CurrentPageRef = TabPages["Universal"]
local defaultBtn = TabList:FindFirstChild("UniversalBtn")
if defaultBtn then
    defaultBtn.BackgroundColor3 = AppConfig.Theme.Accent
    defaultBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end
