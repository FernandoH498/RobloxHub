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


-- ==============================================================================
-- GOHUB V14 ENGINES ARCHITECTURE (EMBEDDED SUITE)
-- ==============================================================================

-- 1. ZERO-ALLOC CORE & POLYFILL MATRIX (Milestone 1)
do
-- language: Lua, file: v14_core_zeroalloc.lua, runtime: Roblox Luau, target: GoHub V14 Foundation & Zero-Alloc Core
-- ==============================================================================
-- GOHUB V14 — UNIVERSAL SUITE: FOUNDATION & ZERO-ALLOC CORE
-- Milestone 1: HubState Central Registry, 24-Highlight Pool, Universal Polyfills,
--              Flag Collision Sanitizer, 9-Theme Engine, and Rayfield V3 Integration
-- ==============================================================================

local GoHubV14Core = {}
GoHubV14Core.__index = GoHubV14Core
GoHubV14Core.Version = "14.0.0"

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
local Lighting = safeGetService("Lighting")
local VirtualUser = safeGetService("VirtualUser")
local Debris = safeGetService("Debris")
local ProximityPromptService = safeGetService("ProximityPromptService")
local VirtualInputManager = safeGetService("VirtualInputManager")

local LocalPlayer = nil
if Players then
    LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        pcall(function()
            LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        end)
    end
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
-- 2. UNIVERSAL EXECUTOR POLYFILL LAYER (FEATURE 4)
-- ------------------------------------------------------------------------------
local Polyfills = {}

-- Safe getgenv polyfill
local _raw_getgenv = getgenv
if typeof(_raw_getgenv) ~= "function" then
    local _genv_storage = _G
    _raw_getgenv = function()
        return _genv_storage
    end
    getgenv = _raw_getgenv
end
Polyfills.getgenv = _raw_getgenv

-- Safe executor namespace polyfills
syn = syn or {}
fluxus = fluxus or {}
electron = electron or {}
wave = wave or {}
celestia = celestia or {}
solara = solara or {}
delta = delta or {}
macsploit = macsploit or {}

Polyfills.syn = syn
Polyfills.fluxus = fluxus
Polyfills.electron = electron
Polyfills.wave = wave
Polyfills.celestia = celestia
Polyfills.solara = solara
Polyfills.delta = delta
Polyfills.macsploit = macsploit

-- Safe GUI Root Resolution (gethui -> get_hidden_gui -> CoreGui -> PlayerGui -> Workspace)
function Polyfills.GetSafeGuiRoot()
    -- Tier 1: Modern gethui()
    if typeof(gethui) == "function" then
        local ok, root = pcall(gethui)
        if ok and root then
            return root
        end
    end

    -- Tier 2: get_hidden_gui()
    if typeof(get_hidden_gui) == "function" then
        local ok, root = pcall(get_hidden_gui)
        if ok and root then
            return root
        end
    end

    -- Tier 3: CoreGui with write permissions check
    local okCore, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and coreGui then
        local testOk = pcall(function()
            local probe = Instance.new("Folder")
            probe.Name = "GoHub_RootProbe"
            probe.Parent = coreGui
            probe:Destroy()
        end)
        if testOk then
            return coreGui
        end
    end

    -- Tier 4: PlayerGui fallback
    if Players and Players.LocalPlayer then
        local lp = Players.LocalPlayer
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if pg then
            return pg
        end
        local okWait, waitPg = pcall(function()
            return lp:WaitForChild("PlayerGui", 3)
        end)
        if okWait and waitPg then
            return waitPg
        end
    end

    -- Tier 5: Contingency container
    return Workspace or game
end

-- GUI Protection wrapper
function Polyfills.ProtectGui(guiInstance)
    if not guiInstance then return end
    if syn and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, guiInstance)
    elseif typeof(protectgui) == "function" then
        pcall(protectgui, guiInstance)
    end
end

-- Safe Clipboard writer
function Polyfills.SetClipboard(text)
    local fn = setclipboard or toclipboard or (syn and syn.set_clipboard)
    if typeof(fn) == "function" then
        return pcall(fn, tostring(text))
    end
    return false, "Clipboard API unsupported"
end

-- Universal HTTP Request abstraction
function Polyfills.Request(options)
    local req = (syn and syn.request)
        or (http and http.request)
        or (fluxus and fluxus.request)
        or request
        or http_request

    if typeof(req) == "function" then
        return req(options)
    elseif options and (options.Method == "GET" or not options.Method) and typeof(options.Url) == "string" then
        local content = game:HttpGet(options.Url, true)
        return {
            StatusCode = 200,
            Body = content,
            Success = true
        }
    end
    error("[GoHub V14 Polyfill] Executor does not support HTTP request APIs.")
end

-- Safe Touch Interest sequence with character micro-nudge fallback
function Polyfills.FireTouchInterest(part, touchWithPart, toggle)
    if not part or not touchWithPart then return false end

    -- Check native executor firetouchinterest
    if typeof(firetouchinterest) == "function" then
        local ok = pcall(firetouchinterest, part, touchWithPart, toggle)
        if ok then
            return true
        end
    end

    -- Fallback: Character micro-nudge simulation
    local okNudge, err = pcall(function()
        if not part:IsA("BasePart") or not touchWithPart:IsA("BasePart") then return end
        if toggle == 0 or toggle == true then
            local prevCF = touchWithPart.CFrame
            local targetCF = part.CFrame
            touchWithPart.CFrame = targetCF
            if RunService then
                RunService.Heartbeat:Wait()
            end
            touchWithPart.CFrame = prevCF
        end
    end)
    return okNudge, err
end

-- Safe Proximity Prompt execution with InputHoldBegin fallback
function Polyfills.FireProximityPrompt(prompt, distance)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end

    -- Native fireproximityprompt
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt, distance or 0)
        if ok then
            return true
        end
    end

    -- Fallback: InputHold sequence
    local okFallback = pcall(function()
        if not prompt.Enabled then return end
        local holdDuration = prompt.HoldDuration or 0

        if typeof(prompt.InputHoldBegin) == "function" then
            prompt:InputHoldBegin()
            if holdDuration > 0 then
                task.wait(holdDuration + 0.05)
            end
            if typeof(prompt.InputHoldEnd) == "function" then
                prompt:InputHoldEnd()
            end
        elseif VirtualInputManager and prompt.KeyboardKeyCode then
            VirtualInputManager:SendKeyEvent(true, prompt.KeyboardKeyCode, false, game)
            if holdDuration > 0 then
                task.wait(holdDuration + 0.05)
            end
            VirtualInputManager:SendKeyEvent(false, prompt.KeyboardKeyCode, false, game)
        end
    end)
    return okFallback
end

-- ------------------------------------------------------------------------------
-- 3. DRAWING API & SCREENGUI FALLBACK ENGINE
-- ------------------------------------------------------------------------------
local DrawingPolyfill = {}
DrawingPolyfill.__index = DrawingPolyfill

local function hasNativeDrawing()
    return typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
end

Polyfills.HasNativeDrawing = hasNativeDrawing

-- Internal ScreenGui container for polyfilled drawings
local drawingGuiContainer = nil
local function getDrawingContainer()
    if drawingGuiContainer and drawingGuiContainer.Parent then
        return drawingGuiContainer
    end

    local guiRoot = Polyfills.GetSafeGuiRoot()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GoHub_DrawingPolyfill_Container"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9999
    Polyfills.ProtectGui(sg)
    pcall(function() sg.Parent = guiRoot end)
    drawingGuiContainer = sg
    return sg
end

-- Fallback Drawing Circle
local function createFallbackCircle()
    local container = getDrawingContainer()
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = container

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0

    local obj = {
        _frame = frame,
        _stroke = stroke,
        _corner = corner,
        _visible = false,
        _radius = 50,
        _position = Vector2.new(0, 0),
        _color = Color3.fromRGB(255, 255, 255),
        _thickness = 1,
        _transparency = 1,
        _filled = false,
        _numSides = 64,
        _zIndex = 10
    }

    local meta = {}
    function meta:__index(key)
        if key == "Visible" then return obj._visible end
        if key == "Radius" then return obj._radius end
        if key == "Position" then return obj._position end
        if key == "Color" then return obj._color end
        if key == "Thickness" then return obj._thickness end
        if key == "Transparency" then return obj._transparency end
        if key == "Filled" then return obj._filled end
        if key == "NumSides" then return obj._numSides end
        if key == "ZIndex" then return obj._zIndex end
        if key == "Remove" or key == "Destroy" then
            return function()
                pcall(function() frame:Destroy() end)
            end
        end
        return nil
    end

    function meta:__newindex(key, val)
        if key == "Visible" then
            obj._visible = val
            frame.Visible = val
        elseif key == "Radius" then
            obj._radius = val
            frame.Size = UDim2.new(0, val * 2, 0, val * 2)
            frame.Position = UDim2.new(0, obj._position.X - val, 0, obj._position.Y - val)
        elseif key == "Position" then
            obj._position = val
            frame.Position = UDim2.new(0, val.X - obj._radius, 0, val.Y - obj._radius)
        elseif key == "Color" then
            obj._color = val
            stroke.Color = val
            if obj._filled then frame.BackgroundColor3 = val end
        elseif key == "Thickness" then
            obj._thickness = val
            stroke.Thickness = val
        elseif key == "Transparency" then
            obj._transparency = val
            local alpha = 1 - math.clamp(val, 0, 1)
            stroke.Transparency = alpha
            if obj._filled then frame.BackgroundTransparency = alpha end
        elseif key == "Filled" then
            obj._filled = val
            frame.BackgroundTransparency = val and (1 - math.clamp(obj._transparency, 0, 1)) or 1
            if val then frame.BackgroundColor3 = obj._color end
        elseif key == "ZIndex" then
            obj._zIndex = val
            frame.ZIndex = val
        end
    end

    return setmetatable({}, meta)
end

-- Fallback Drawing Square
local function createFallbackSquare()
    local container = getDrawingContainer()
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = container

    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0

    local obj = {
        _frame = frame,
        _stroke = stroke,
        _visible = false,
        _size = Vector2.new(100, 100),
        _position = Vector2.new(0, 0),
        _color = Color3.fromRGB(255, 255, 255),
        _thickness = 1,
        _transparency = 1,
        _filled = false,
        _zIndex = 10
    }

    local meta = {}
    function meta:__index(key)
        if key == "Visible" then return obj._visible end
        if key == "Size" then return obj._size end
        if key == "Position" then return obj._position end
        if key == "Color" then return obj._color end
        if key == "Thickness" then return obj._thickness end
        if key == "Transparency" then return obj._transparency end
        if key == "Filled" then return obj._filled end
        if key == "ZIndex" then return obj._zIndex end
        if key == "Remove" or key == "Destroy" then
            return function()
                pcall(function() frame:Destroy() end)
            end
        end
        return nil
    end

    function meta:__newindex(key, val)
        if key == "Visible" then
            obj._visible = val
            frame.Visible = val
        elseif key == "Size" then
            obj._size = val
            frame.Size = UDim2.new(0, val.X, 0, val.Y)
        elseif key == "Position" then
            obj._position = val
            frame.Position = UDim2.new(0, val.X, 0, val.Y)
        elseif key == "Color" then
            obj._color = val
            stroke.Color = val
            if obj._filled then frame.BackgroundColor3 = val end
        elseif key == "Thickness" then
            obj._thickness = val
            stroke.Thickness = val
        elseif key == "Transparency" then
            obj._transparency = val
            local alpha = 1 - math.clamp(val, 0, 1)
            stroke.Transparency = alpha
            if obj._filled then frame.BackgroundTransparency = alpha end
        elseif key == "Filled" then
            obj._filled = val
            frame.BackgroundTransparency = val and (1 - math.clamp(obj._transparency, 0, 1)) or 1
            if val then frame.BackgroundColor3 = obj._color end
        elseif key == "ZIndex" then
            obj._zIndex = val
            frame.ZIndex = val
        end
    end

    return setmetatable({}, meta)
end

-- Fallback Drawing Line
local function createFallbackLine()
    local container = getDrawingContainer()
    local frame = Instance.new("Frame")
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0, 0.5)
    frame.Visible = false
    frame.Parent = container

    local obj = {
        _frame = frame,
        _visible = false,
        _from = Vector2.new(0, 0),
        _to = Vector2.new(0, 0),
        _color = Color3.fromRGB(255, 255, 255),
        _thickness = 1,
        _transparency = 1,
        _zIndex = 10
    }

    local function updateLine()
        local diff = obj._to - obj._from
        local length = diff.Magnitude
        local angle = math.deg(math.atan2(diff.Y, diff.X))
        frame.Size = UDim2.new(0, length, 0, obj._thickness)
        frame.Position = UDim2.new(0, obj._from.X, 0, obj._from.Y)
        frame.Rotation = angle
    end

    local meta = {}
    function meta:__index(key)
        if key == "Visible" then return obj._visible end
        if key == "From" then return obj._from end
        if key == "To" then return obj._to end
        if key == "Color" then return obj._color end
        if key == "Thickness" then return obj._thickness end
        if key == "Transparency" then return obj._transparency end
        if key == "ZIndex" then return obj._zIndex end
        if key == "Remove" or key == "Destroy" then
            return function()
                pcall(function() frame:Destroy() end)
            end
        end
        return nil
    end

    function meta:__newindex(key, val)
        if key == "Visible" then
            obj._visible = val
            frame.Visible = val
        elseif key == "From" then
            obj._from = val
            updateLine()
        elseif key == "To" then
            obj._to = val
            updateLine()
        elseif key == "Color" then
            obj._color = val
            frame.BackgroundColor3 = val
        elseif key == "Thickness" then
            obj._thickness = val
            updateLine()
        elseif key == "Transparency" then
            obj._transparency = val
            frame.BackgroundTransparency = 1 - math.clamp(val, 0, 1)
        elseif key == "ZIndex" then
            obj._zIndex = val
            frame.ZIndex = val
        end
    end

    return setmetatable({}, meta)
end

-- Fallback Drawing Text
local function createFallbackText()
    local container = getDrawingContainer()
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Visible = false
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Parent = container

    local stroke = Instance.new("UIStroke", label)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Enabled = false

    local obj = {
        _label = label,
        _stroke = stroke,
        _visible = false,
        _text = "",
        _size = 14,
        _position = Vector2.new(0, 0),
        _color = Color3.fromRGB(255, 255, 255),
        _center = false,
        _outline = false,
        _outlineColor = Color3.fromRGB(0, 0, 0),
        _transparency = 1,
        _zIndex = 10
    }

    local meta = {}
    function meta:__index(key)
        if key == "Visible" then return obj._visible end
        if key == "Text" then return obj._text end
        if key == "Size" then return obj._size end
        if key == "Position" then return obj._position end
        if key == "Color" then return obj._color end
        if key == "Center" then return obj._center end
        if key == "Outline" then return obj._outline end
        if key == "OutlineColor" then return obj._outlineColor end
        if key == "Transparency" then return obj._transparency end
        if key == "ZIndex" then return obj._zIndex end
        if key == "TextBounds" then return label.TextBounds end
        if key == "Remove" or key == "Destroy" then
            return function()
                pcall(function() label:Destroy() end)
            end
        end
        return nil
    end

    function meta:__newindex(key, val)
        if key == "Visible" then
            obj._visible = val
            label.Visible = val
        elseif key == "Text" then
            obj._text = tostring(val)
            label.Text = obj._text
        elseif key == "Size" then
            obj._size = val
            label.TextSize = val
        elseif key == "Position" then
            obj._position = val
            label.Position = UDim2.new(0, val.X, 0, val.Y)
        elseif key == "Color" then
            obj._color = val
            label.TextColor3 = val
        elseif key == "Center" then
            obj._center = val
            label.AnchorPoint = val and Vector2.new(0.5, 0.5) or Vector2.new(0, 0)
        elseif key == "Outline" then
            obj._outline = val
            stroke.Enabled = val
        elseif key == "OutlineColor" then
            obj._outlineColor = val
            stroke.Color = val
        elseif key == "Transparency" then
            obj._transparency = val
            label.TextTransparency = 1 - math.clamp(val, 0, 1)
        elseif key == "ZIndex" then
            obj._zIndex = val
            label.ZIndex = val
        end
    end

    return setmetatable({}, meta)
end

function DrawingPolyfill.new(drawingType)
    if hasNativeDrawing() then
        return Drawing.new(drawingType)
    end

    local dType = tostring(drawingType):lower()
    if dType == "circle" then
        return createFallbackCircle()
    elseif dType == "square" then
        return createFallbackSquare()
    elseif dType == "line" then
        return createFallbackLine()
    elseif dType == "text" then
        return createFallbackText()
    end
    error("[GoHub V14 Drawing] Unsupported drawing primitive: " .. tostring(drawingType))
end

Polyfills.Drawing = hasNativeDrawing() and Drawing or DrawingPolyfill

-- ------------------------------------------------------------------------------
-- 4. FILE SYSTEM SAFE WRAPPERS & PERSISTENCE (FEATURE 1 & 4)
-- ------------------------------------------------------------------------------
local FS = {}

function FS.IsFile(path)
    local ok, res = pcall(function()
        return isfile and isfile(path)
    end)
    return ok and res == true
end

function FS.IsFolder(path)
    local ok, res = pcall(function()
        return isfolder and isfolder(path)
    end)
    return ok and res == true
end

function FS.ReadFile(path)
    local ok, res = pcall(function()
        return readfile and readfile(path)
    end)
    if ok and type(res) == "string" then
        return res
    end
    return nil
end

function FS.WriteFile(path, content)
    local ok, err = pcall(function()
        if writefile then
            writefile(path, tostring(content))
        end
    end)
    return ok, err
end

function FS.MakeFolder(folder)
    local ok, err = pcall(function()
        if makefolder and not (isfolder and isfolder(folder)) then
            makefolder(folder)
        end
    end)
    return ok, err
end

function FS.DeleteFile(path)
    local ok, err = pcall(function()
        if delfile then
            delfile(path)
        end
    end)
    return ok, err
end

function FS.ListFiles(folder)
    local ok, list = pcall(function()
        if listfiles then
            return listfiles(folder)
        end
        return {}
    end)
    if ok and type(list) == "table" then
        return list
    end
    return {}
end

function FS.SafeSaveJSON(path, data)
    local okEncode, json = pcall(function()
        if HttpService then
            return HttpService:JSONEncode(data)
        end
        return nil
    end)
    if okEncode and json then
        return FS.WriteFile(path, json)
    end
    return false, "JSON serialization error"
end

function FS.SafeLoadJSON(path)
    if not FS.IsFile(path) then
        return nil
    end
    local raw = FS.ReadFile(path)
    if not raw then return nil end

    local okDecode, parsed = pcall(function()
        if HttpService then
            return HttpService:JSONDecode(raw)
        end
        return nil
    end)
    if okDecode and type(parsed) == "table" then
        return parsed
    end
    return nil
end

GoHubV14Core.FS = FS

-- ------------------------------------------------------------------------------
-- 5. ZERO-ALLOC PRE-ALLOCATED SCRATCH BUFFERS & WEAK CACHE (FEATURE 2)
-- ------------------------------------------------------------------------------
local ScratchBuffers = {
    Targets = {},
    Positions = {},
    Entities = {},
    DistanceQueue = {},
    SortBuffer = {},
    Candidates = {},
    ActiveIndices = {}
}

-- Weak reference table for StreamingEnabled resilience
local WeakInstances = setmetatable({}, { __mode = "k" })
local WeakLookup = setmetatable({}, { __mode = "v" })

local function createRayParams()
    local ok, params = pcall(function()
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.IgnoreWater = true
        return rp
    end)
    if ok and params then
        return params
    end
    return nil
end

ScratchBuffers.RayParams = createRayParams()

local function getScratchBuffer(name)
    local buf = ScratchBuffers[name]
    if not buf then
        buf = {}
        ScratchBuffers[name] = buf
    end
    table.clear(buf)
    return buf
end

local function releaseScratchBuffer(name)
    local buf = ScratchBuffers[name]
    if buf then
        table.clear(buf)
    end
end

-- ------------------------------------------------------------------------------
-- 6. HIGHLIGHT ADORNEE POOL — STRICT 24 INSTANCES (FEATURE 3)
-- ------------------------------------------------------------------------------
local MaxHighlights = 24

local HighlightPool = {
    MAX_HIGHLIGHTS = MaxHighlights,
    ActiveCount = 0,
    Instances = {},
    Slots = {},
    Container = nil,
    Initialized = false
}

function HighlightPool.Init(guiRoot)
    if HighlightPool.Initialized then return end

    local container = nil
    pcall(function()
        if Workspace then
            container = Workspace:FindFirstChild("GoHubV14_HighlightContainer")
            if not container then
                container = Instance.new("Folder")
                container.Name = "GoHubV14_HighlightContainer"
                container.Parent = Workspace
            end
        end
    end)
    HighlightPool.Container = container or (Workspace and Workspace.CurrentCamera) or guiRoot or Polyfills.GetSafeGuiRoot()

    table.clear(HighlightPool.Instances)
    table.clear(HighlightPool.Slots)

    for i = 1, 24 do
        local hl = Instance.new("Highlight")
        hl.Name = "GoHubV14_HighlightSlot_" .. i
        hl.Enabled = false
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        pcall(function()
            hl.Parent = HighlightPool.Container
        end)

        HighlightPool.Instances[i] = hl
        HighlightPool.Slots[i] = {
            Index = i,
            Instance = hl,
            InUse = false,
            Target = nil,
            Priority = 9999,
            Distance = 0,
            LastColor = Color3.fromRGB(255, 255, 255),
            LastOutline = Color3.fromRGB(255, 255, 255)
        }
    end

    HighlightPool.ActiveCount = 0
    HighlightPool.Initialized = true
end

-- Acquire a highlight slot with priority/distance eviction
function HighlightPool.AcquireHighlight(target, priority, color, outlineColor)
    if not HighlightPool.Initialized then
        HighlightPool.Init()
    end
    if not target then return nil end

    priority = priority or 4
    color = color or Color3.fromRGB(255, 255, 255)
    outlineColor = outlineColor or Color3.fromRGB(255, 255, 255)

    -- Step 1: Check if target is already assigned a slot
    for i = 1, HighlightPool.MAX_HIGHLIGHTS do
        local slot = HighlightPool.Slots[i]
        if slot.InUse and slot.Target == target then
            slot.Priority = priority
            slot.Instance.FillColor = color
            slot.Instance.OutlineColor = outlineColor
            slot.Instance.Enabled = true
            return slot.Instance
        end
    end

    -- Step 2: Find a free unused slot
    for i = 1, HighlightPool.MAX_HIGHLIGHTS do
        local slot = HighlightPool.Slots[i]
        if not slot.InUse then
            slot.InUse = true
            slot.Target = target
            slot.Priority = priority
            slot.Instance.Adornee = target
            slot.Instance.FillColor = color
            slot.Instance.OutlineColor = outlineColor
            slot.Instance.Enabled = true
            HighlightPool.ActiveCount = HighlightPool.ActiveCount + 1
            return slot.Instance
        end
    end

    -- Step 3: Pool is full (24 active). Evict slot with lowest priority (highest number)
    local lowestSlotIndex = nil
    local lowestPriorityVal = -1
    local highestDistanceVal = -1

    for i = 1, HighlightPool.MAX_HIGHLIGHTS do
        local slot = HighlightPool.Slots[i]
        if slot.Priority > lowestPriorityVal then
            lowestPriorityVal = slot.Priority
            highestDistanceVal = slot.Distance
            lowestSlotIndex = i
        elseif slot.Priority == lowestPriorityVal and slot.Distance > highestDistanceVal then
            highestDistanceVal = slot.Distance
            lowestSlotIndex = i
        end
    end

    -- Compare candidate with the lowest ranking slot
    if lowestSlotIndex and priority <= lowestPriorityVal then
        local evictedSlot = HighlightPool.Slots[lowestSlotIndex]
        evictedSlot.Target = target
        evictedSlot.Priority = priority
        evictedSlot.Instance.Adornee = target
        evictedSlot.Instance.FillColor = color
        evictedSlot.Instance.OutlineColor = outlineColor
        evictedSlot.Instance.Enabled = true
        return evictedSlot.Instance
    end

    -- Cannot outrank existing slots: drop safely without exceeding 24 limit
    return nil
end

-- Release a highlight slot
function HighlightPool.ReleaseHighlight(highlightOrTarget)
    if not highlightOrTarget then return end
    for i = 1, HighlightPool.MAX_HIGHLIGHTS do
        local slot = HighlightPool.Slots[i]
        if slot.InUse and (slot.Instance == highlightOrTarget or slot.Target == highlightOrTarget) then
            slot.InUse = false
            slot.Target = nil
            slot.Priority = 9999
            slot.Distance = 0
            slot.Instance.Enabled = false
            slot.Instance.Adornee = nil
            HighlightPool.ActiveCount = math.max(0, HighlightPool.ActiveCount - 1)
            return
        end
    end
end

-- Clear all active highlights
function HighlightPool.ClearAll()
    for i = 1, HighlightPool.MAX_HIGHLIGHTS do
        local slot = HighlightPool.Slots[i]
        if slot then
            slot.InUse = false
            slot.Target = nil
            slot.Priority = 9999
            slot.Distance = 0
            if slot.Instance then
                slot.Instance.Enabled = false
                slot.Instance.Adornee = nil
            end
        end
    end
    HighlightPool.ActiveCount = 0
end

-- Bulk zero-alloc highlight allocator
-- candidateList: array of { target, priority, color, outlineColor, distance }
function HighlightPool.UpdatePool(candidateList, totalCandidates)
    if not HighlightPool.Initialized then
        HighlightPool.Init()
    end

    totalCandidates = totalCandidates or #candidateList
    local sortBuf = getScratchBuffer("SortBuffer")

    -- Copy candidates into sortBuf without allocating new tables
    for i = 1, totalCandidates do
        sortBuf[i] = candidateList[i]
    end

    -- Simple insertion sort on sortBuf (max ~60 elements, zero allocation)
    for i = 2, totalCandidates do
        local key = sortBuf[i]
        local j = i - 1
        while j >= 1 and (sortBuf[j].priority > key.priority or (sortBuf[j].priority == key.priority and sortBuf[j].distance > key.distance)) do
            sortBuf[j + 1] = sortBuf[j]
            j = j - 1
        end
        sortBuf[j + 1] = key
    end

    -- Assign top 24 candidates
    local assignedCount = math.min(HighlightPool.MAX_HIGHLIGHTS, totalCandidates)
    for i = 1, assignedCount do
        local cand = sortBuf[i]
        local slot = HighlightPool.Slots[i]
        slot.InUse = true
        slot.Target = cand.target
        slot.Priority = cand.priority
        slot.Distance = cand.distance or 0
        slot.Instance.Adornee = cand.target
        slot.Instance.FillColor = cand.color or Color3.fromRGB(255, 255, 255)
        slot.Instance.OutlineColor = cand.outlineColor or Color3.fromRGB(255, 255, 255)
        slot.Instance.Enabled = true
    end

    -- Disable remaining unused slots
    for i = assignedCount + 1, HighlightPool.MAX_HIGHLIGHTS do
        local slot = HighlightPool.Slots[i]
        if slot.InUse then
            slot.InUse = false
            slot.Target = nil
            slot.Priority = 9999
            slot.Distance = 0
            slot.Instance.Enabled = false
            slot.Instance.Adornee = nil
        end
    end

    HighlightPool.ActiveCount = assignedCount
    table.clear(sortBuf)
end

-- ------------------------------------------------------------------------------
-- 7. BOXHANDLEADORNMENT ADORNEE POOL — ZERO ALLOC ADORNMENTS (FEATURE 2 & 5)
-- ------------------------------------------------------------------------------
local AdornmentPool = {
    MAX_ADORNMENTS = 32,
    ActiveCount = 0,
    Instances = {},
    Slots = {},
    Container = nil,
    Initialized = false
}

function AdornmentPool.Init(guiRoot)
    if AdornmentPool.Initialized then return end
    AdornmentPool.Container = guiRoot or Polyfills.GetSafeGuiRoot()

    table.clear(AdornmentPool.Instances)
    table.clear(AdornmentPool.Slots)

    for i = 1, AdornmentPool.MAX_ADORNMENTS do
        local adorn = Instance.new("BoxHandleAdornment")
        adorn.Name = "GoHubV14_AdornSlot_" .. i
        adorn.AlwaysOnTop = true
        adorn.ZIndex = 5
        adorn.Transparency = 0.5
        adorn.Color3 = Color3.fromRGB(255, 0, 0)
        adorn.Visible = false
        pcall(function()
            adorn.Parent = AdornmentPool.Container
        end)

        AdornmentPool.Instances[i] = adorn
        AdornmentPool.Slots[i] = {
            Index = i,
            Instance = adorn,
            InUse = false,
            Target = nil
        }
    end

    AdornmentPool.ActiveCount = 0
    AdornmentPool.Initialized = true
end

function AdornmentPool.AcquireAdornment(adornee, size, color, transparency)
    if not AdornmentPool.Initialized then
        AdornmentPool.Init()
    end
    if not adornee then return nil end

    for i = 1, AdornmentPool.MAX_ADORNMENTS do
        local slot = AdornmentPool.Slots[i]
        if not slot.InUse then
            slot.InUse = true
            slot.Target = adornee
            slot.Instance.Adornee = adornee
            slot.Instance.Size = size or Vector3.new(3.5, 4.5, 3.5)
            slot.Instance.Color3 = color or Color3.fromRGB(255, 0, 0)
            slot.Instance.Transparency = transparency or 0.5
            slot.Instance.Visible = true
            AdornmentPool.ActiveCount = AdornmentPool.ActiveCount + 1
            return slot.Instance
        end
    end
    return nil
end

function AdornmentPool.ReleaseAdornment(adornmentOrTarget)
    if not adornmentOrTarget then return end
    for i = 1, AdornmentPool.MAX_ADORNMENTS do
        local slot = AdornmentPool.Slots[i]
        if slot.InUse and (slot.Instance == adornmentOrTarget or slot.Target == adornmentOrTarget) then
            slot.InUse = false
            slot.Target = nil
            slot.Instance.Visible = false
            slot.Instance.Adornee = nil
            AdornmentPool.ActiveCount = math.max(0, AdornmentPool.ActiveCount - 1)
            return
        end
    end
end

function AdornmentPool.ClearAll()
    for i = 1, AdornmentPool.MAX_ADORNMENTS do
        local slot = AdornmentPool.Slots[i]
        if slot then
            slot.InUse = false
            slot.Target = nil
            if slot.Instance then
                slot.Instance.Visible = false
                slot.Instance.Adornee = nil
            end
        end
    end
    AdornmentPool.ActiveCount = 0
end

-- ------------------------------------------------------------------------------
-- 8. V13 TECHNICAL DEBT RESOLUTION & FLAG SANITIZER (FEATURE 5)
-- ------------------------------------------------------------------------------
local FlagSanitizer = {
    RegisteredFlags = {},
    Owners = {}
}

function FlagSanitizer.Sanitize(tabTag, elementName, elementType, explicitFlag)
    tabTag = tostring(tabTag or "gen"):lower():gsub("%W+", "_")
    elementName = tostring(elementName or "elem"):lower():gsub("%W+", "_")
    elementType = tostring(elementType or "generic")

    -- Buttons in Rayfield are stateless actions and must NEVER register conflicting flags
    if elementType:lower() == "button" or elementType:lower() == "paragraph" or elementType:lower() == "section" then
        return nil
    end

    local candidateFlag = explicitFlag
    if not candidateFlag or candidateFlag == "" then
        candidateFlag = ("gohub_%s_%s"):format(tabTag, elementName)
    end

    -- If candidateFlag is already registered by a different element, disambiguate
    local existingOwner = FlagSanitizer.RegisteredFlags[candidateFlag]
    if existingOwner and existingOwner ~= (tabTag .. ":" .. elementName) then
        local counter = 1
        local uniqueFlag = candidateFlag .. "_" .. counter
        while FlagSanitizer.RegisteredFlags[uniqueFlag] do
            counter = counter + 1
            uniqueFlag = candidateFlag .. "_" .. counter
        end
        candidateFlag = uniqueFlag
    end

    FlagSanitizer.RegisteredFlags[candidateFlag] = tabTag .. ":" .. elementName
    return candidateFlag
end

function FlagSanitizer.Clear()
    table.clear(FlagSanitizer.RegisteredFlags)
    table.clear(FlagSanitizer.Owners)
end

-- ------------------------------------------------------------------------------
-- 9. CENTRAL STATE REGISTRY (HUBSTATE & LIFECYCLE) (REQUIREMENT 1)
-- ------------------------------------------------------------------------------
local HubState = {
    -- Lifecycle Connection Containers
    Connections = {},
    Loops = {},

    -- Shared Resource Pools
    Pools = {
        Highlights = HighlightPool,
        Adornments = AdornmentPool,
        Scratch = ScratchBuffers
    },

    -- Weak Reference Caches for StreamingEnabled
    WeakInstances = WeakInstances,
    WeakLookup = WeakLookup,

    -- Theme & Visual Identity State
    Theme = {
        Accent = Color3.fromRGB(148, 0, 211),
        AccentGlow = Color3.fromRGB(186, 85, 255),
        Card = Color3.fromRGB(24, 24, 34),
        Background = Color3.fromRGB(16, 16, 24),
        Text = Color3.fromRGB(240, 240, 255),
        TextDim = Color3.fromRGB(150, 150, 170),
        Success = Color3.fromRGB(60, 220, 120),
        Warning = Color3.fromRGB(255, 170, 0),
        Danger = Color3.fromRGB(255, 60, 60),
        Border = Color3.fromRGB(50, 50, 70),
        Innocent = Color3.fromRGB(40, 255, 120),
        Sheriff = Color3.fromRGB(40, 140, 255),
        Murderer = Color3.fromRGB(255, 40, 40)
    },

    -- Movement & Physics State
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

    -- Combat & Aimbot State
    Combat = {
        AimbotActive = false,
        TargetPart = "Head",
        FOV = 120,
        Smoothness = 0.2,
        TeamCheck = false,
        VisibilityCheck = true,
        FOVCircleVisible = true
    },

    -- Visuals & Shaders State
    Visuals = {
        ShaderActive = false,
        XRayActive = false,
        FullbrightActive = false,
        NoFogActive = false,
        UniversalESP = false
    },

    -- Murder Mystery 2 State
    MM2 = {
        RoleESP = false,
        CoinESP = false,
        AutoGrabGun = false,
        Hitboxes = false
    },

    -- Fling & Physics Trolling State
    Fling = {
        Active = false,
        WalkFling = false,
        AntiFling = false,
        LoopTarget = nil,
        DropKickActive = false,
        DropKickForce = 5000
    },

    -- Animation & Dances State
    Animation = {
        CurrentTrack = nil,
        Speed = 1
    },
    CustomDances = {},

    -- Character Stability State
    Character = {
        AntiSit = false,
        SpinBot = false,
        SpinSpeed = 30
    },

    -- Navigation Waypoints
    Waypoints = {},

    -- Avatar Skin Modifications
    Skin = {
        OriginalDesc = nil,
        HeadlessActive = false,
        KorbloxActive = false
    },

    -- Radial Menu State
    Radial = {
        Visible = false,
        SelectedSlot = nil,
        Slots = {}
    },

    -- Retractable Command Bar State
    CmdBar = {
        Prefix = ";",
        Visible = false
    },

    -- Target Selection & Camera
    SelectedPlayer = nil,
    IsSpectating = false,

    -- Sub-Engine Containers for Milestones 2-5
    Audio = {},
    Lighting = {},
    Trolling = {},
    Telemetry = {}
}

-- Central Loop Registration
function HubState.RegisterLoop(tag, connection)
    if not tag or not connection then return nil end

    if HubState.Loops[tag] then
        pcall(function()
            HubState.Loops[tag]:Disconnect()
        end)
        HubState.Loops[tag] = nil
    end

    HubState.Loops[tag] = connection
    table.insert(HubState.Connections, connection)
    return connection
end

-- Central Loop Drop
function HubState.DropLoop(tag)
    if not tag then return end
    local conn = HubState.Loops[tag]
    if conn then
        pcall(function()
            conn:Disconnect()
        end)
        HubState.Loops[tag] = nil
    end
end

-- Clear All Registered Loops and Connections
function HubState.ClearAllLoops()
    for tag, conn in pairs(HubState.Loops) do
        if conn then
            pcall(function()
                conn:Disconnect()
            end)
        end
    end
    table.clear(HubState.Loops)

    for i = 1, #HubState.Connections do
        local conn = HubState.Connections[i]
        if conn then
            pcall(function()
                conn:Disconnect()
            end)
        end
    end
    table.clear(HubState.Connections)
end

-- Highlight Pool Proxy Methods
function HubState.AcquireHighlight(target, priority, color, outlineColor)
    return HighlightPool.AcquireHighlight(target, priority, color, outlineColor)
end

function HubState.ReleaseHighlight(highlightOrTarget)
    HighlightPool.ReleaseHighlight(highlightOrTarget)
end

-- Scratch table recycling helpers
function HubState.GetScratch(name)
    return getScratchBuffer(name)
end

function HubState.ReleaseScratch(name)
    releaseScratchBuffer(name)
end

-- Tactical SFX Dispatch Hook (M1 Fallback -> M2 Audio Engine Full Dispatch)
function HubState.PlaySFX(sfxType, customPitch)
    if HubState.Audio and typeof(HubState.Audio.PlaySFX) == "function" then
        return HubState.Audio.PlaySFX(sfxType, customPitch)
    end
    -- Fallback click beep if SoundService is available
    pcall(function()
        local soundService = safeGetService("SoundService")
        if soundService then
            -- M1 silent no-op or default UI click
        end
    end)
end

-- Weak Cache Helpers for StreamingEnabled
function HubState.CacheInstance(key, val)
    if key then
        WeakInstances[key] = val or true
    end
end

function HubState.GetCachedInstance(key)
    return WeakInstances[key]
end

-- ------------------------------------------------------------------------------
-- 10. RAYFIELD THEME & WINDOW INTEGRATION (FEATURE 1)
-- ------------------------------------------------------------------------------
local ThemeManager = {
    CurrentTheme = "Bloom",
    SupportedThemes = {
        "Default",
        "AmberGlow",
        "Amethyst",
        "Bloom",
        "DarkBlue",
        "Green",
        "Light",
        "Ocean",
        "Serenity"
    },
    StorageFolder = "GoHubV14",
    ThemeFile = "GoHubV14/SelectedTheme.txt",
    ConfigFile = "GoHubV14_Config",
    Listeners = {}
}

function ThemeManager.IsValidTheme(themeName)
    if type(themeName) ~= "string" then return false, nil end
    for _, t in ipairs(ThemeManager.SupportedThemes) do
        if t:lower() == themeName:lower() then
            return true, t
        end
    end
    return false, nil
end

function ThemeManager.GetSavedTheme()
    if FS.IsFile(ThemeManager.ThemeFile) then
        local raw = FS.ReadFile(ThemeManager.ThemeFile)
        if raw then
            local clean = raw:match("^%s*(.-)%s*$")
            local valid, exact = ThemeManager.IsValidTheme(clean)
            if valid then
                return exact
            end
        end
    end
    return "Bloom"
end

function ThemeManager.SaveTheme(themeName)
    local valid, exact = ThemeManager.IsValidTheme(themeName)
    local toSave = valid and exact or "Bloom"

    FS.MakeFolder(ThemeManager.StorageFolder)
    local ok, err = FS.WriteFile(ThemeManager.ThemeFile, toSave)
    if ok then
        ThemeManager.CurrentTheme = toSave
        return true
    end
    return false, err
end

function ThemeManager.ApplyTheme(windowObj, themeName, notify)
    local valid, exact = ThemeManager.IsValidTheme(themeName)
    local themeToApply = valid and exact or "Bloom"

    if windowObj and typeof(windowObj.ModifyTheme) == "function" then
        local ok, err = pcall(function()
            windowObj.ModifyTheme(themeToApply)
        end)

        if ok then
            ThemeManager.CurrentTheme = themeToApply
            ThemeManager.SaveTheme(themeToApply)

            for _, cb in ipairs(ThemeManager.Listeners) do
                pcall(cb, themeToApply)
            end

            if notify and GoHubV14Core.Notify then
                GoHubV14Core.Notify({
                    Title = "Tema Atualizado",
                    Content = "Tema ativo: " .. themeToApply,
                    Duration = 3,
                    Image = 135247969077372
                })
            end
            return true
        end
        return false, err
    end
    return false, "Window object does not support ModifyTheme"
end

function ThemeManager.OnThemeChanged(callback)
    if type(callback) == "function" then
        table.insert(ThemeManager.Listeners, callback)
    end
end

-- ------------------------------------------------------------------------------
-- 11. RESILIENT RAYFIELD LOADER & NOTIFICATION WRAPPER (FEATURE 1)
-- ------------------------------------------------------------------------------
local RayfieldLibrary = nil

local function loadRayfieldLibrary()
    if RayfieldLibrary then return RayfieldLibrary end

    local sources = {
        { name = "Sirius Menu CDN", url = "https://sirius.menu/rayfield" },
        { name = "GitHub Shlexware Raw", url = "https://raw.githubusercontent.com/shlexware/Rayfield/main/source" },
        { name = "GitHub SiriusSoftware Raw", url = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua" }
    }

    for _, src in ipairs(sources) do
        local ok, lib = pcall(function()
            local code = game:HttpGet(src.url, true)
            if code and #code > 500 then
                local fn = loadstring(code)
                if fn then
                    return fn()
                end
            end
            return nil
        end)

        if ok and lib and type(lib) == "table" and lib.CreateWindow then
            RayfieldLibrary = lib
            return lib
        end
    end

    -- Standalone / Offline Mock Rayfield for headless testing environments
    local MockRayfield = {
        _isMock = true,
        CreateWindow = function(_, cfg)
            local MockWindow = {
                Config = cfg,
                Tabs = {},
                CreateTab = function(self, name, icon)
                    local MockTab = {
                        Name = name,
                        Icon = icon,
                        Sections = {},
                        Elements = {},
                        CreateSection = function(tSelf, sName)
                            local s = { Name = sName }
                            table.insert(tSelf.Sections, s)
                            return s
                        end,
                        CreateButton = function(tSelf, bCfg)
                            table.insert(tSelf.Elements, bCfg)
                            return bCfg
                        end,
                        CreateToggle = function(tSelf, tCfg)
                            table.insert(tSelf.Elements, tCfg)
                            return tCfg
                        end,
                        CreateSlider = function(tSelf, sCfg)
                            table.insert(tSelf.Elements, sCfg)
                            return sCfg
                        end,
                        CreateDropdown = function(tSelf, dCfg)
                            table.insert(tSelf.Elements, dCfg)
                            return dCfg
                        end,
                        CreateColorPicker = function(tSelf, cCfg)
                            table.insert(tSelf.Elements, cCfg)
                            return cCfg
                        end,
                        CreateInput = function(tSelf, iCfg)
                            table.insert(tSelf.Elements, iCfg)
                            return iCfg
                        end,
                        CreateParagraph = function(tSelf, pCfg)
                            table.insert(tSelf.Elements, pCfg)
                            return pCfg
                        end
                    }
                    table.insert(self.Tabs, MockTab)
                    return MockTab
                end,
                ModifyTheme = function(self, tName)
                    self.Config.Theme = tName
                end,
                Destroy = function(self)
                    table.clear(self.Tabs)
                end
            }
            return MockWindow
        end,
        Notify = function(_, nParams)
            -- mock notification
        end,
        SaveConfiguration = function(_)
            -- mock config save
        end,
        Destroy = function(_)
            -- mock destroy
        end
    }

    RayfieldLibrary = MockRayfield
    return MockRayfield
end

function GoHubV14Core.Notify(params)
    if not params then return end
    local title = params.Title or "GoHub V14"
    local content = params.Content or ""
    local duration = params.Duration or 3.5
    local image = params.Image or 135247969077372

    if RayfieldLibrary and typeof(RayfieldLibrary.Notify) == "function" then
        pcall(function()
            RayfieldLibrary:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Image = image,
                Callback = params.Callback
            })
        end)
    else
        print(("[GoHub V14 Alert] %s: %s"):format(tostring(title), tostring(content)))
    end
end

function GoHubV14Core.NotifySuccess(title, content, duration)
    GoHubV14Core.Notify({
        Title = "✔ " .. (title or "Sucesso"),
        Content = content or "",
        Duration = duration or 3.5,
        Image = 135247969077372
    })
end

function GoHubV14Core.NotifyWarning(title, content, duration)
    GoHubV14Core.Notify({
        Title = "⚠ " .. (title or "Atenção"),
        Content = content or "",
        Duration = duration or 4.5,
        Image = 135247969077372
    })
end

function GoHubV14Core.NotifyError(title, content, duration)
    GoHubV14Core.Notify({
        Title = "✖ " .. (title or "Erro"),
        Content = content or "",
        Duration = duration or 5,
        Image = 135247969077372
    })
end

-- ------------------------------------------------------------------------------
-- 12. WINDOW CREATION & THEME CONFIGURATION BUILDER
-- ------------------------------------------------------------------------------
function GoHubV14Core.CreateWindow(customOptions)
    customOptions = customOptions or {}
    local rayfield = loadRayfieldLibrary()

    local initialTheme = ThemeManager.GetSavedTheme()
    ThemeManager.CurrentTheme = initialTheme

    local windowConfig = {
        Name = customOptions.Name or "GoHub V14 — Universal Suite",
        Icon = customOptions.Icon or 135247969077372,
        LoadingTitle = customOptions.LoadingTitle or "GoHub V14",
        LoadingSubtitle = customOptions.LoadingSubtitle or "Universal Suite & Zero-Alloc Core",
        Theme = initialTheme,
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = false,
        ConfigurationSaving = {
            Enabled = true,
            FolderName = ThemeManager.StorageFolder,
            FileName = ThemeManager.ConfigFile
        },
        Discord = {
            Enabled = false,
            Invite = "GoHub",
            RememberJoins = false
        },
        KeySystem = false
    }

    local Window = rayfield:CreateWindow(windowConfig)
    GoHubV14Core.Window = Window
    GoHubV14Core.Rayfield = rayfield

    -- Initialize 24-Highlight Pool & 32-Adornment Pool
    HighlightPool.Init()
    AdornmentPool.Init()

    -- Synchronize theme if non-default
    if initialTheme ~= "Bloom" then
        task.spawn(function()
            task.wait(0.2)
            ThemeManager.ApplyTheme(Window, initialTheme, false)
        end)
    end

    return Window
end

-- ------------------------------------------------------------------------------
-- 13. SETTINGS & THEMES TAB BUILDER (FEATURE 1)
-- ------------------------------------------------------------------------------
function GoHubV14Core.BuildSettingsTab(Window)
    if not Window or typeof(Window.CreateTab) ~= "function" then
        return nil
    end

    local SettingsTab = Window:CreateTab("Config & Temas", 7072725342)

    SettingsTab:CreateSection("Personalização & Temas Oficiais (9 Temas)")

    local initialTheme = ThemeManager.CurrentTheme or "Bloom"

    local ThemeDropdown = SettingsTab:CreateDropdown({
        Name = "Tema da Interface Rayfield",
        Options = ThemeManager.SupportedThemes,
        CurrentOption = { initialTheme },
        MultipleOptions = false,
        Flag = FlagSanitizer.Sanitize("settings", "theme_dropdown", "Dropdown", "settings_theme_dropdown"),
        Callback = function(Option)
            local selected = type(Option) == "table" and Option[1] or Option
            if selected and selected ~= ThemeManager.CurrentTheme then
                ThemeManager.ApplyTheme(Window, selected, true)
            end
        end
    })

    SettingsTab:CreateButton({
        Name = "Restaurar Tema Padrão (Bloom)",
        Callback = function()
            ThemeManager.ApplyTheme(Window, "Bloom", true)
            pcall(function()
                if ThemeDropdown and ThemeDropdown.Set then
                    ThemeDropdown:Set({ "Bloom" })
                end
            end)
        end
    })

    SettingsTab:CreateSection("Cores de Destaque & Identidade")

    SettingsTab:CreateColorPicker({
        Name = "Cor de Destaque / Accent (Waifu)",
        Color = HubState.Theme.Accent,
        Flag = FlagSanitizer.Sanitize("settings", "accent_color", "ColorPicker", "settings_accent_color"),
        Callback = function(Value)
            HubState.Theme.Accent = Value
        end
    })

    SettingsTab:CreateColorPicker({
        Name = "Cor do Murderer (MM2)",
        Color = HubState.Theme.Murderer,
        Flag = FlagSanitizer.Sanitize("settings", "murder_color", "ColorPicker", "settings_murder_color"),
        Callback = function(Value)
            HubState.Theme.Murderer = Value
        end
    })

    SettingsTab:CreateColorPicker({
        Name = "Cor do Sheriff (MM2)",
        Color = HubState.Theme.Sheriff,
        Flag = FlagSanitizer.Sanitize("settings", "sheriff_color", "ColorPicker", "settings_sheriff_color"),
        Callback = function(Value)
            HubState.Theme.Sheriff = Value
        end
    })

    SettingsTab:CreateColorPicker({
        Name = "Cor dos Inocentes (MM2)",
        Color = HubState.Theme.Innocent,
        Flag = FlagSanitizer.Sanitize("settings", "innocent_color", "ColorPicker", "settings_innocent_color"),
        Callback = function(Value)
            HubState.Theme.Innocent = Value
        end
    })

    SettingsTab:CreateButton({
        Name = "Restaurar Cores Padrão da Suite",
        Callback = function()
            HubState.Theme.Accent = Color3.fromRGB(148, 0, 211)
            HubState.Theme.Innocent = Color3.fromRGB(40, 255, 120)
            HubState.Theme.Murderer = Color3.fromRGB(255, 40, 40)
            HubState.Theme.Sheriff = Color3.fromRGB(40, 140, 255)
            GoHubV14Core.NotifySuccess("Cores Restauradas", "As paletas de cores padrão foram redefinidas.")
        end
    })

    SettingsTab:CreateSection("Gerenciamento do GoHub V14")

    SettingsTab:CreateButton({
        Name = "Salvar Todas as Configurações no Disco",
        Callback = function()
            pcall(function()
                if GoHubV14Core.Rayfield and GoHubV14Core.Rayfield.SaveConfiguration then
                    GoHubV14Core.Rayfield:SaveConfiguration()
                end
            end)
            ThemeManager.SaveTheme(ThemeManager.CurrentTheme)
            GoHubV14Core.NotifySuccess("Configurações Salvas", "Tema e parâmetros salvos em " .. ThemeManager.StorageFolder)
        end
    })

    SettingsTab:CreateButton({
        Name = "❌ Descarregar GoHub V14 (Teardown)",
        Callback = function()
            GoHubV14Core.Teardown()
        end
    })

    SettingsTab:CreateSection("Sobre o GoHub V14")
    SettingsTab:CreateParagraph({
        Title = "GoHub V14 Universal Suite",
        Content = ("Versão: %s\nZero-Alloc Core: Ativo\nHighlight Pool: 24 Slots\nExecutor Compat: Universal\nTema Atual: %s"):format(
            GoHubV14Core.Version,
            ThemeManager.CurrentTheme
        )
    })

    return SettingsTab
end

-- ------------------------------------------------------------------------------
-- 14. TEARDOWN & CLEANUP ROUTINE
-- ------------------------------------------------------------------------------
function GoHubV14Core.Teardown()
    -- Disconnect all running loops
    HubState.ClearAllLoops()

    -- Release all pooled instances
    HighlightPool.ClearAll()
    AdornmentPool.ClearAll()

    -- Clean up drawing container if present
    if drawingGuiContainer then
        pcall(function() drawingGuiContainer:Destroy() end)
        drawingGuiContainer = nil
    end

    -- Clear scratch buffers
    for _, buf in pairs(ScratchBuffers) do
        if type(buf) == "table" then
            table.clear(buf)
        end
    end

    -- Destroy Rayfield Window
    pcall(function()
        if GoHubV14Core.Rayfield and GoHubV14Core.Rayfield.Destroy then
            GoHubV14Core.Rayfield:Destroy()
        end
    end)

    GoHubV14Core.NotifyWarning("GoHub V14 Descarregado", "Todos os recursos foram limpos.", 2)
end

-- ------------------------------------------------------------------------------
-- 15. INTERFACE EXPORT & GLOBAL WIRING
-- ------------------------------------------------------------------------------
GoHubV14Core.HubState = HubState
GoHubV14Core.HighlightPool = HighlightPool
GoHubV14Core.AdornmentPool = AdornmentPool
GoHubV14Core.Polyfills = Polyfills
GoHubV14Core.ThemeManager = ThemeManager
GoHubV14Core.FlagSanitizer = FlagSanitizer

_G.GoHubV14Core = GoHubV14Core
shared.GoHubV14Core = GoHubV14Core

-- [Module Return] return GoHubV14Core
end

-- 2. AUDIO & MUSIC ENGINE 2.0 (Milestone 2 - R1 PRIORITIZED)
do
-- language: Lua, file: v14_audio_engine.lua, runtime: Roblox Luau, target: GoHub V14 Audio & Music Engine 2.0
-- ==============================================================================
-- GOHUB V14 — UNIVERSAL SUITE: AUDIO & MUSIC ENGINE 2.0 (MILESTONE 2)
-- ==============================================================================
-- Features Implemented:
--   Feature 6:  Custom Music Player & BGM Playlist Engine (Crossfade, Loop, Speed, Volume)
--   Feature 7:  Bass Boost DSP Dynamic Equalizer (EqualizerSoundEffect & Anti-Clipping Compressor)
--   Feature 8:  Tactical Sound Design (SFX Pool with 6% Pitch Jitter & Catalog)
--   Feature 9:  3D Character Audio Visualizer (12 Orbital Neon Nodes & Particle Ring)
--   Feature 10: Floor Beat-Drop Shockwaves (Dynamic Energy Heuristic & Pooled Rings)
--   Feature 11: 2D Spectrum Equalizer HUD (12-Band Derivative Equalizer Display)
-- ==============================================================================

local AudioEngine = {}
AudioEngine.__index = AudioEngine
AudioEngine.Version = "14.2.0"

-- ------------------------------------------------------------------------------
-- 1. SAFE SERVICE ACQUISITION & ENVIRONMENT RESOLUTION
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

local SoundService = safeGetService("SoundService")
local Workspace = safeGetService("Workspace") or (typeof(workspace) == "userdata" and workspace)
local Players = safeGetService("Players")
local RunService = safeGetService("RunService")
local TweenService = safeGetService("TweenService")
local Debris = safeGetService("Debris")
local CoreGui = safeGetService("CoreGui")
local HttpService = safeGetService("HttpService")

local LocalPlayer = nil
if Players then
    LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        pcall(function()
            LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        end)
    end
end

-- Fast table.clear guarantee across Luau, LuaJIT, and standard Lua 5.1
if typeof(table) == "table" and typeof(table.clear) ~= "function" then
    table.clear = function(t)
        for k in pairs(t) do
            t[k] = nil
        end
    end
end

-- Safe GUI Root Resolution
local function getSafeGuiRoot()
    if typeof(gethui) == "function" then
        local ok, root = pcall(gethui)
        if ok and root then return root end
    end
    if typeof(get_hidden_gui) == "function" then
        local ok, root = pcall(get_hidden_gui)
        if ok and root then return root end
    end
    if CoreGui then
        local testOk = pcall(function()
            local probe = Instance.new("Folder")
            probe.Name = "GoHub_AudioRootProbe"
            probe.Parent = CoreGui
            probe:Destroy()
        end)
        if testOk then return CoreGui end
    end
    if LocalPlayer then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then return pg end
        local okWait, waitPg = pcall(function()
            return LocalPlayer:WaitForChild("PlayerGui", 3)
        end)
        if okWait and waitPg then return waitPg end
    end
    return Workspace or game
end

-- ------------------------------------------------------------------------------
-- 2. HUBSTATE INTEGRATION & LIFECYCLE MANAGEMENT
-- ------------------------------------------------------------------------------
local HubState = nil
if _G.GoHubV14Core and _G.GoHubV14Core.HubState then
    HubState = _G.GoHubV14Core.HubState
elseif shared.GoHubV14Core and shared.GoHubV14Core.HubState then
    HubState = shared.GoHubV14Core.HubState
else
    -- Standalone HubState fallback container if loaded independently
    HubState = {
        Connections = {},
        Loops = {},
        Pools = {
            Scratch = {}
        },
        Audio = {}
    }
    function HubState.RegisterLoop(tag, connection)
        if not tag or not connection then return nil end
        if HubState.Loops[tag] then
            pcall(function() HubState.Loops[tag]:Disconnect() end)
            HubState.Loops[tag] = nil
        end
        HubState.Loops[tag] = connection
        table.insert(HubState.Connections, connection)
        return connection
    end
    function HubState.DropLoop(tag)
        if not tag then return end
        local conn = HubState.Loops[tag]
        if conn then
            pcall(function() conn:Disconnect() end)
            HubState.Loops[tag] = nil
        end
    end
    function HubState.ClearAllLoops()
        for tag, conn in pairs(HubState.Loops) do
            if conn then
                pcall(function() conn:Disconnect() end)
            end
        end
        table.clear(HubState.Loops)
        for i = 1, #HubState.Connections do
            local conn = HubState.Connections[i]
            if conn then
                pcall(function() conn:Disconnect() end)
            end
        end
        table.clear(HubState.Connections)
    end
end

-- ------------------------------------------------------------------------------
-- 3. EVENT BUS & BEAT DROP SIGNAL (RBXScriptSignal COMPATIBILITY)
-- ------------------------------------------------------------------------------
local beatDropBindable = Instance.new("BindableEvent")
AudioEngine.OnBeatDrop = beatDropBindable.Event

-- ------------------------------------------------------------------------------
-- 4. BGM PLAYLIST & MUSIC PLAYER ENGINE (FEATURE 6)
-- ------------------------------------------------------------------------------
local MusicPlayer = {
    Container = nil,
    ActiveSound = nil,
    FadingSound = nil,
    ActiveTrackIndex = 1,
    Volume = 0.5,
    PlaybackSpeed = 1.0,
    LoopMode = "Sequential", -- "Sequential" | "LoopTrack" | "Shuffle"
    IsPlaying = false,
    CrossfadeDuration = 0.75,
    CrossfadeTweenActive = nil,
    CrossfadeTweenFade = nil,
    EndedConnection = nil,

    Playlist = {
        { Id = 1843404009, Title = "Vaporwave Synth Beat", Artist = "GoHub Beats", Duration = 145, DefaultVolume = 0.6 },
        { Id = 1837849285, Title = "Phonk Action Drift", Artist = "Synthwave Lab", Duration = 120, DefaultVolume = 0.65 },
        { Id = 1848354536, Title = "Lofi Hip Hop Study", Artist = "Chilled Cow", Duration = 130, DefaultVolume = 0.55 },
        { Id = 1841285324, Title = "Electro House Pulse", Artist = "Audio Lab", Duration = 150, DefaultVolume = 0.6 },
        { Id = 1845554017, Title = "Future Bass Energy", Artist = "Sub Zero", Duration = 140, DefaultVolume = 0.6 },
        { Id = 1838457617, Title = "Cyberpunk Neon Drive", Artist = "Neon Runner", Duration = 160, DefaultVolume = 0.6 },
        { Id = 7028506547, Title = "Hyperpop Overdrive", Artist = "Glitch Lab", Duration = 110, DefaultVolume = 0.55 },
        { Id = 9043887091, Title = "Midnight Ambient Chill", Artist = "Nightflow", Duration = 175, DefaultVolume = 0.55 },
        { Id = 1843588737, Title = "Classic Chill Beats", Artist = "Roblox Audio", Duration = 120, DefaultVolume = 0.6 },
        { Id = 5410086218, Title = "Brazilian Phonk Extreme", Artist = "Montagem", Duration = 125, DefaultVolume = 0.65 }
    }
}

-- Resolve or create Sound parent container (Camera or SoundService for 100% audible 2D playback)
local function getAudioContainer()
    if MusicPlayer.Container and MusicPlayer.Container.Parent then
        return MusicPlayer.Container
    end

    local parent = (Workspace and Workspace.CurrentCamera) or SoundService or Workspace
    local folder = parent:FindFirstChild("GoHubV14_AudioContainer")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "GoHubV14_AudioContainer"
        pcall(function() folder.Parent = parent end)
    end
    MusicPlayer.Container = folder
    return folder
end

-- ------------------------------------------------------------------------------
-- 5. BASS BOOST DSP EQUALIZER ENGINE (FEATURE 7)
-- ------------------------------------------------------------------------------
local DSPEngine = {
    BassBoost = false,
    BassLevelDb = 0.0,
    CurrentProfile = "Flat",
    LowGain = 0.0,
    MidGain = 0.0,
    HighGain = 0.0,

    Profiles = {
        ["Flat"] = { Low = 0.0, Mid = 0.0, High = 0.0, Speed = nil },
        ["Bass Boost Standard"] = { Low = 6.5, Mid = -1.5, High = 1.0, Speed = nil },
        ["Bass Boost Heavy"] = { Low = 10.0, Mid = -3.5, High = 2.0, Speed = nil },
        ["Extreme Bass"] = { Low = 20.0, Mid = -6.0, High = 0.0, Speed = nil },
        ["Nightcore"] = { Low = 4.0, Mid = 2.0, High = 5.0, Speed = 1.25 },
        ["Vaporwave"] = { Low = 8.0, Mid = -2.0, High = -4.0, Speed = 0.82 }
    }
}

-- Attach DSP equalizer and anti-clipping compressor chain to a target Sound
local function attachDSPChain(sound)
    if not sound then return end

    -- Primary Equalizer
    local eq1 = sound:FindFirstChild("GoHub_EqualizerPrimary")
    if not eq1 then
        eq1 = Instance.new("EqualizerSoundEffect")
        eq1.Name = "GoHub_EqualizerPrimary"
        eq1.Priority = 1
        pcall(function() eq1.Parent = sound end)
    end

    -- Cascaded Secondary Equalizer (used when LowGain > 10 dB)
    local eq2 = sound:FindFirstChild("GoHub_EqualizerSecondary")
    if not eq2 then
        eq2 = Instance.new("EqualizerSoundEffect")
        eq2.Name = "GoHub_EqualizerSecondary"
        eq2.Priority = 2
        pcall(function() eq2.Parent = sound end)
    end

    -- Anti-Clipping Compressor
    local comp = sound:FindFirstChild("GoHub_Compressor")
    if not comp then
        comp = Instance.new("CompressorSoundEffect")
        comp.Name = "GoHub_Compressor"
        comp.Threshold = -8.0
        comp.Ratio = 4.0
        comp.Attack = 0.005
        comp.Release = 0.08
        comp.GainPost = 0.0
        comp.Priority = 3
        pcall(function() comp.Parent = sound end)
    end

    -- Apply current DSP parameters
    local low1 = math.clamp(DSPEngine.LowGain, -80.0, 10.0)
    local low2 = 0.0
    if DSPEngine.LowGain > 10.0 then
        low2 = math.clamp(DSPEngine.LowGain - 10.0, 0.0, 10.0)
    end

    eq1.LowGain = low1
    eq1.MidGain = math.clamp(DSPEngine.MidGain, -80.0, 10.0)
    eq1.HighGain = math.clamp(DSPEngine.HighGain, -80.0, 10.0)

    eq2.LowGain = low2
    eq2.MidGain = 0.0
    eq2.HighGain = 0.0

    eq1.Enabled = true
    eq2.Enabled = (low2 > 0.0)
    comp.Enabled = (DSPEngine.BassBoost or DSPEngine.LowGain > 5.0)
end

-- Refresh DSP parameters on the active sound
local function refreshActiveDSP()
    if MusicPlayer.ActiveSound then
        attachDSPChain(MusicPlayer.ActiveSound)
    end
end

function AudioEngine.SetBassBoost(enabled, levelDb)
    DSPEngine.BassBoost = (enabled == true)

    if enabled then
        local rawGain = tonumber(levelDb) or 6.5
        -- Sanitize NaN
        if rawGain ~= rawGain then rawGain = 6.5 end
        DSPEngine.BassLevelDb = rawGain
        DSPEngine.LowGain = math.clamp(rawGain, -80.0, 20.0)
        DSPEngine.MidGain = math.clamp(-0.25 * rawGain, -80.0, 10.0)
        DSPEngine.HighGain = math.clamp(0.15 * rawGain, -80.0, 10.0)
        DSPEngine.CurrentProfile = "Custom Bass Boost"
    else
        DSPEngine.BassLevelDb = 0.0
        DSPEngine.LowGain = 0.0
        DSPEngine.MidGain = 0.0
        DSPEngine.HighGain = 0.0
        DSPEngine.CurrentProfile = "Flat"
    end

    refreshActiveDSP()
end

function AudioEngine.SetEqualizerProfile(profileName)
    local profile = DSPEngine.Profiles[profileName]
    if not profile then
        profile = DSPEngine.Profiles["Flat"]
        profileName = "Flat"
    end

    DSPEngine.CurrentProfile = profileName
    DSPEngine.LowGain = profile.Low
    DSPEngine.MidGain = profile.Mid
    DSPEngine.HighGain = profile.High
    DSPEngine.BassBoost = (profile.Low > 0.0)
    DSPEngine.BassLevelDb = profile.Low

    if profile.Speed then
        AudioEngine.SetSpeed(profile.Speed)
    end

    refreshActiveDSP()
end

function AudioEngine.SetCustomEqualizer(low, mid, high)
    low = tonumber(low) or 0.0
    mid = tonumber(mid) or 0.0
    high = tonumber(high) or 0.0

    -- Sanitize NaN
    if low ~= low then low = 0.0 end
    if mid ~= mid then mid = 0.0 end
    if high ~= high then high = 0.0 end

    DSPEngine.LowGain = math.clamp(low, -80.0, 20.0)
    DSPEngine.MidGain = math.clamp(mid, -80.0, 10.0)
    DSPEngine.HighGain = math.clamp(high, -80.0, 10.0)
    DSPEngine.BassBoost = (DSPEngine.LowGain > 0.0)
    DSPEngine.BassLevelDb = DSPEngine.LowGain
    DSPEngine.CurrentProfile = "Custom"

    refreshActiveDSP()
end

-- ------------------------------------------------------------------------------
-- 6. MUSIC PLAYER PLAYBACK & CROSSFADE ROUTINES
-- ------------------------------------------------------------------------------
local function createSoundInstance(name)
    local container = getAudioContainer()
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.Archivable = false
    sound.Looped = false
    sound.Volume = MusicPlayer.Volume
    sound.PlaybackSpeed = MusicPlayer.PlaybackSpeed
    pcall(function() sound.Parent = container end)
    return sound
end

function AudioEngine.SetVolume(vol)
    vol = tonumber(vol) or 0.5
    if vol ~= vol then vol = 0.5 end
    MusicPlayer.Volume = math.clamp(vol, 0.0, 1.0)
    if MusicPlayer.ActiveSound then
        MusicPlayer.ActiveSound.Volume = MusicPlayer.Volume
    end
end

function AudioEngine.SetSpeed(speed)
    speed = tonumber(speed) or 1.0
    if speed ~= speed then speed = 1.0 end
    MusicPlayer.PlaybackSpeed = math.clamp(speed, 0.5, 2.0)
    if MusicPlayer.ActiveSound then
        MusicPlayer.ActiveSound.PlaybackSpeed = MusicPlayer.PlaybackSpeed
    end
end

function AudioEngine.SetLoopMode(mode)
    if mode == "Sequential" or mode == "LoopTrack" or mode == "Shuffle" then
        MusicPlayer.LoopMode = mode
    else
        MusicPlayer.LoopMode = "Sequential"
    end
end

local function onTrackEnded()
    if not MusicPlayer.IsPlaying then return end

    if MusicPlayer.LoopMode == "LoopTrack" then
        AudioEngine.PlayTrack(MusicPlayer.ActiveTrackIndex)
    elseif MusicPlayer.LoopMode == "Shuffle" then
        local count = #MusicPlayer.Playlist
        if count <= 1 then
            AudioEngine.PlayTrack(1)
        else
            local nextIdx = math.random(1, count)
            if nextIdx == MusicPlayer.ActiveTrackIndex then
                nextIdx = (nextIdx % count) + 1
            end
            AudioEngine.PlayTrack(nextIdx)
        end
    else
        -- Sequential
        local count = #MusicPlayer.Playlist
        local nextIdx = (MusicPlayer.ActiveTrackIndex % count) + 1
        AudioEngine.PlayTrack(nextIdx)
    end
end

function AudioEngine.PlayTrack(trackIdOrIndex, customVol, customSpeed)
    local targetTrack = nil
    local targetIndex = 1

    local totalTracks = #MusicPlayer.Playlist
    if totalTracks == 0 then
        return nil
    end

    if type(trackIdOrIndex) == "number" then
        if trackIdOrIndex >= 1 and trackIdOrIndex <= totalTracks then
            targetIndex = trackIdOrIndex
            targetTrack = MusicPlayer.Playlist[targetIndex]
        else
            -- Check if trackIdOrIndex is a Roblox Asset ID
            for i = 1, totalTracks do
                if MusicPlayer.Playlist[i].Id == trackIdOrIndex then
                    targetIndex = i
                    targetTrack = MusicPlayer.Playlist[i]
                    break
                end
            end
            if not targetTrack then
                -- Ad-hoc track definition from asset ID
                targetTrack = {
                    Id = trackIdOrIndex,
                    Title = "Custom Asset #" .. tostring(trackIdOrIndex),
                    Artist = "User Audio",
                    Duration = 120,
                    DefaultVolume = 0.5
                }
                targetIndex = totalTracks + 1
                MusicPlayer.Playlist[targetIndex] = targetTrack
            end
        end
    elseif type(trackIdOrIndex) == "string" then
        local num = tonumber(trackIdOrIndex:match("%d+"))
        if num then
            return AudioEngine.PlayTrack(num, customVol, customSpeed)
        end
    end

    if not targetTrack then
        targetIndex = 1
        targetTrack = MusicPlayer.Playlist[1]
    end

    MusicPlayer.ActiveTrackIndex = targetIndex

    if customVol ~= nil then
        AudioEngine.SetVolume(customVol)
    elseif targetTrack.DefaultVolume then
        AudioEngine.SetVolume(targetTrack.DefaultVolume)
    end

    if customSpeed ~= nil then
        AudioEngine.SetSpeed(customSpeed)
    end

    local assetString = "rbxassetid://" .. tostring(targetTrack.Id)
    local targetVolume = MusicPlayer.Volume
    local tau = MusicPlayer.CrossfadeDuration

    -- Disconnect previous ended listener
    if MusicPlayer.EndedConnection then
        pcall(function() MusicPlayer.EndedConnection:Disconnect() end)
        MusicPlayer.EndedConnection = nil
    end

    -- Prepare crossfade: existing active sound becomes fading sound
    local oldSound = MusicPlayer.ActiveSound
    if oldSound and oldSound.IsPlaying then
        MusicPlayer.FadingSound = oldSound

        if TweenService then
            local fadeTween = TweenService:Create(oldSound, TweenInfo.new(tau, Enum.EasingStyle.Linear), { Volume = 0 })
            fadeTween:Play()
            fadeTween.Completed:Connect(function()
                pcall(function()
                    oldSound:Stop()
                    oldSound:Destroy()
                end)
                if MusicPlayer.FadingSound == oldSound then
                    MusicPlayer.FadingSound = nil
                end
            end)
        else
            pcall(function()
                oldSound:Stop()
                oldSound:Destroy()
            end)
        end
    end

    -- Create new active sound instance with immediate volume
    local newSound = createSoundInstance("GoHub_ActiveTrack_" .. tostring(targetTrack.Id))
    newSound.SoundId = assetString
    newSound.PlaybackSpeed = MusicPlayer.PlaybackSpeed
    newSound.Volume = targetVolume
    newSound.Looped = (MusicPlayer.LoopMode == "LoopTrack")
    attachDSPChain(newSound)

    MusicPlayer.ActiveSound = newSound
    MusicPlayer.IsPlaying = true

    pcall(function() newSound:Play() end)

    MusicPlayer.EndedConnection = newSound.Ended:Connect(onTrackEnded)
    return targetTrack
end

function AudioEngine.Pause()
    MusicPlayer.IsPlaying = false
    if MusicPlayer.ActiveSound then
        pcall(function() MusicPlayer.ActiveSound:Pause() end)
    end
end

function AudioEngine.Resume()
    if MusicPlayer.ActiveSound then
        MusicPlayer.IsPlaying = true
        pcall(function() MusicPlayer.ActiveSound:Resume() end)
    elseif #MusicPlayer.Playlist > 0 then
        AudioEngine.PlayTrack(MusicPlayer.ActiveTrackIndex)
    end
end

function AudioEngine.Stop()
    MusicPlayer.IsPlaying = false
    if MusicPlayer.ActiveSound then
        pcall(function()
            MusicPlayer.ActiveSound:Stop()
            MusicPlayer.ActiveSound:Destroy()
        end)
        MusicPlayer.ActiveSound = nil
    end
    if MusicPlayer.FadingSound then
        pcall(function()
            MusicPlayer.FadingSound:Stop()
            MusicPlayer.FadingSound:Destroy()
        end)
        MusicPlayer.FadingSound = nil
    end
end

function AudioEngine.TogglePlay()
    if MusicPlayer.IsPlaying then
        AudioEngine.Pause()
    else
        AudioEngine.Resume()
    end
    return MusicPlayer.IsPlaying
end

function AudioEngine.GetCurrentTrack()
    return MusicPlayer.Playlist[MusicPlayer.ActiveTrackIndex] or MusicPlayer.Playlist[1]
end

function AudioEngine.NextTrack()
    local count = #MusicPlayer.Playlist
    if count == 0 then return end
    local nextIdx = (MusicPlayer.ActiveTrackIndex % count) + 1
    AudioEngine.PlayTrack(nextIdx)
end

function AudioEngine.PreviousTrack()
    local count = #MusicPlayer.Playlist
    if count == 0 then return end
    local prevIdx = MusicPlayer.ActiveTrackIndex - 1
    if prevIdx < 1 then
        prevIdx = count
    end
    AudioEngine.PlayTrack(prevIdx)
end

function AudioEngine.GetPlaylist()
    local list = {}
    for i = 1, #MusicPlayer.Playlist do
        list[i] = MusicPlayer.Playlist[i]
    end
    return list
end

function AudioEngine.AddTrack(trackInfo)
    if type(trackInfo) ~= "table" or not trackInfo.Id then return end
    local item = {
        Id = tonumber(trackInfo.Id) or 0,
        Title = tostring(trackInfo.Title or "Custom Track"),
        Artist = tostring(trackInfo.Artist or "Unknown"),
        Duration = tonumber(trackInfo.Duration) or 120,
        DefaultVolume = tonumber(trackInfo.DefaultVolume) or 0.5
    }
    table.insert(MusicPlayer.Playlist, item)
end

-- ------------------------------------------------------------------------------
-- 7. TACTICAL SOUND DESIGN (SFX POOL & PITCH RANDOMIZATION) (FEATURE 8)
-- ------------------------------------------------------------------------------
local SFXEngine = {
    PoolSize = 6,
    Pool = {},
    CurrentSlot = 1,
    Container = nil,
    JitterPercent = 0.06, -- variance [0.94, 1.06]

    Catalog = {
        ["Click"] = { Asset = "rbxassetid://9114223175", BasePitch = 1.0, Volume = 0.5 },
        ["ToggleOn"] = { Asset = "rbxassetid://6895079853", BasePitch = 1.15, Volume = 0.45 },
        ["ToggleOff"] = { Asset = "rbxassetid://6895079853", BasePitch = 0.85, Volume = 0.45 },
        ["Dropkick"] = { Asset = "rbxassetid://138097048", BasePitch = 0.95, Volume = 0.7 },
        ["Fly"] = { Asset = "rbxassetid://131070686", BasePitch = 1.0, Volume = 0.55 },
        ["Warp"] = { Asset = "rbxassetid://130972023", BasePitch = 1.1, Volume = 0.6 },
        ["Hitmarker"] = { Asset = "rbxassetid://160432334", BasePitch = 1.0, Volume = 0.65 }
    }
}

local function initSFXPool()
    if #SFXEngine.Pool > 0 then return end

    local parent = SoundService or Workspace
    local folder = parent:FindFirstChild("GoHubSFXPool")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "GoHubSFXPool"
        pcall(function() folder.Parent = parent end)
    end
    SFXEngine.Container = folder

    for i = 1, SFXEngine.PoolSize do
        local sound = Instance.new("Sound")
        sound.Name = "GoHub_SFXSlot_" .. i
        sound.Archivable = false
        sound.Looped = false
        sound.Volume = 0.5
        pcall(function() sound.Parent = folder end)
        SFXEngine.Pool[i] = sound
    end
end

function AudioEngine.PlaySFX(soundName, customPitch)
    initSFXPool()

    soundName = tostring(soundName or "Click")
    local sfxData = SFXEngine.Catalog[soundName]
    if not sfxData then
        sfxData = SFXEngine.Catalog["Click"]
    end

    local basePitch = sfxData.BasePitch
    if customPitch ~= nil then
        basePitch = tonumber(customPitch) or basePitch
    end

    -- Pitch Jitter calculation: S = S_base * (1.0 + (math.random() - 0.5) * 2 * J)
    local jitter = (math.random() - 0.5) * 2.0 * SFXEngine.JitterPercent
    local randomizedPitch = basePitch * (1.0 + jitter)
    if basePitch == 0 then
        randomizedPitch = 0
    end

    -- Round-robin pool slot acquisition
    SFXEngine.CurrentSlot = (SFXEngine.CurrentSlot % SFXEngine.PoolSize) + 1
    local soundInstance = SFXEngine.Pool[SFXEngine.CurrentSlot]

    if soundInstance then
        soundInstance.SoundId = sfxData.Asset
        soundInstance.PlaybackSpeed = randomizedPitch
        soundInstance.Volume = sfxData.Volume
        pcall(function() soundInstance:Play() end)
    end
end

-- Wire HubState PlaySFX dispatch
if HubState then
    HubState.Audio = AudioEngine
    HubState.PlaySFX = function(sfxType, customPitch)
        return AudioEngine.PlaySFX(sfxType, customPitch)
    end
end

-- ------------------------------------------------------------------------------
-- 8. SIGNAL CONDITIONING & LOUDNESS ANALYSIS (FEATURES 9 & 10)
-- ------------------------------------------------------------------------------
local SignalEngine = {
    LoudnessInstant = 0.0,
    LoudnessSmooth = 0.0,
    LoudnessPrev = 0.0,
    DecayRate = 18.0, -- exponential smoothing decay constant

    -- Sliding window for beat drop detection (30 samples)
    SlidingWindow = {},
    WindowIndex = 1,
    WindowSum = 0.0,
    WindowSize = 30,

    -- Refractory gate for beat drops
    LastBeatTime = 0.0,
    BeatRefractory = 0.22,
    BeatMultiplier = 1.35,
    BeatThreshold = 380.0
}

for i = 1, SignalEngine.WindowSize do
    SignalEngine.SlidingWindow[i] = 0.0
end

local function updateSignalProcessing(dt)
    if dt <= 0 then dt = 0.016 end

    local rawL = 0.0
    if MusicPlayer.ActiveSound and MusicPlayer.ActiveSound.IsPlaying then
        pcall(function()
            rawL = MusicPlayer.ActiveSound.PlaybackLoudness or 0.0
        end)
    end

    -- Clamp loudness to [0, 1000]
    rawL = math.clamp(rawL, 0.0, 1000.0)
    SignalEngine.LoudnessPrev = SignalEngine.LoudnessInstant
    SignalEngine.LoudnessInstant = rawL

    -- Exponential Moving Average: L_smooth = L_smooth + (L_curr - L_smooth) * (1 - e^(-18 * dt))
    local alpha = 1.0 - math.exp(-SignalEngine.DecayRate * dt)
    SignalEngine.LoudnessSmooth = SignalEngine.LoudnessSmooth + (rawL - SignalEngine.LoudnessSmooth) * alpha

    -- Update 30-sample sliding window
    local oldVal = SignalEngine.SlidingWindow[SignalEngine.WindowIndex]
    SignalEngine.SlidingWindow[SignalEngine.WindowIndex] = rawL
    SignalEngine.WindowSum = SignalEngine.WindowSum - oldVal + rawL
    SignalEngine.WindowIndex = (SignalEngine.WindowIndex % SignalEngine.WindowSize) + 1

    local avg30 = SignalEngine.WindowSum / SignalEngine.WindowSize

    -- Dynamic energy beat detection heuristic: L > 1.35 * avg30 and L > 380 and dt > 0.22s
    local now = os.clock()
    local isBeat = (rawL > (SignalEngine.BeatMultiplier * avg30))
        and (rawL > SignalEngine.BeatThreshold)
        and ((now - SignalEngine.LastBeatTime) > SignalEngine.BeatRefractory)

    if isBeat then
        SignalEngine.LastBeatTime = now
        pcall(function()
            beatDropBindable:Fire(rawL)
        end)
    end

    return rawL, SignalEngine.LoudnessSmooth, isBeat
end

function AudioEngine.GetLoudness()
    return SignalEngine.LoudnessInstant, SignalEngine.LoudnessSmooth
end

-- ------------------------------------------------------------------------------
-- 9. 3D CHARACTER AUDIO VISUALIZER (FEATURE 9)
-- ------------------------------------------------------------------------------
local Visualizer3D = {
    Enabled = false,
    NodeCount = 12,
    Nodes = {},
    Container = nil,
    ParticleEmitter = nil,
    ParticleAttachment = nil,
    AngularVelocity = 1.8,
    AngleTime = 0.0,
    BaseRadius = 3.5,
    RadiusExpansion = 3.0,
    HeightOffset = 0.5,
    CurrentCharacter = nil
}

local function initVisualizer3DNodes()
    if #Visualizer3D.Nodes > 0 then return end

    local container = Instance.new("Folder")
    container.Name = "GoHubV14_Visualizer3D_Container"
    pcall(function() container.Parent = Workspace end)
    Visualizer3D.Container = container

    for i = 1, Visualizer3D.NodeCount do
        local part = Instance.new("Part")
        part.Name = "GoHub_VisualizerNode_" .. i
        part.Shape = Enum.PartType.Ball
        part.Size = Vector3.new(0.4, 0.4, 0.4)
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(200, 50, 255)
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Transparency = 1
        pcall(function() part.Parent = container end)
        Visualizer3D.Nodes[i] = part
    end
end

local function getLocalRootPart()
    if not LocalPlayer then return nil end
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp, char
end

local function setupParticleRing(hrp)
    if not hrp then return end

    if Visualizer3D.ParticleEmitter and Visualizer3D.ParticleAttachment and Visualizer3D.ParticleAttachment.Parent == hrp then
        return
    end

    -- Clean old particle components
    if Visualizer3D.ParticleAttachment then
        pcall(function() Visualizer3D.ParticleAttachment:Destroy() end)
        Visualizer3D.ParticleAttachment = nil
        Visualizer3D.ParticleEmitter = nil
    end

    local att = Instance.new("Attachment")
    att.Name = "GoHub_VisualizerParticleAtt"
    att.Parent = hrp
    Visualizer3D.ParticleAttachment = att

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "GoHub_AudioParticleRing"
    emitter.Texture = "rbxassetid://243098098"
    emitter.LightEmission = 1.0
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.0),
        NumberSequenceKeypoint.new(1, 1.0)
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1.2)
    })
    emitter.Rate = 10
    emitter.Speed = NumberRange.new(4, 8)
    emitter.Lifetime = NumberRange.new(0.4, 0.8)
    emitter.SpreadAngle = Vector2.new(180, 15)
    emitter.Enabled = false
    emitter.Parent = att

    Visualizer3D.ParticleEmitter = emitter
end

local function updateVisualizer3D(dt, lInstant, lSmooth)
    if not Visualizer3D.Enabled then return end

    local hrp, char = getLocalRootPart()
    if not hrp then
        -- Character absent: hide nodes
        for i = 1, Visualizer3D.NodeCount do
            local node = Visualizer3D.Nodes[i]
            if node then node.Transparency = 1 end
        end
        if Visualizer3D.ParticleEmitter then
            Visualizer3D.ParticleEmitter.Enabled = false
        end
        return
    end

    setupParticleRing(hrp)

    -- Update angle: omega * t
    Visualizer3D.AngleTime = Visualizer3D.AngleTime + (Visualizer3D.AngularVelocity * dt)
    local t = Visualizer3D.AngleTime
    local rootPos = hrp.Position

    -- Radius expansion: r(L) = R0 + (L_smooth / 1000) * R_exp
    local radius = Visualizer3D.BaseRadius + ((lSmooth / 1000.0) * Visualizer3D.RadiusExpansion)

    -- Brightness modulation based on loudness
    local nodeTransparency = (lSmooth > 10.0) and 0.0 or 0.8

    for i = 1, Visualizer3D.NodeCount do
        local node = Visualizer3D.Nodes[i]
        if node then
            local theta = t + (2.0 * math.pi * (i - 1) / Visualizer3D.NodeCount)
            local x = radius * math.cos(theta)
            local z = radius * math.sin(theta)
            local y = Visualizer3D.HeightOffset + (math.sin(3.0 * t + theta) * 0.35)

            node.CFrame = CFrame.new(rootPos.X + x, rootPos.Y + y, rootPos.Z + z)

            -- HSV cycling synchronized to Loudness
            local hue = ((0.1 * t) + ((i - 1) / Visualizer3D.NodeCount)) % 1.0
            local val = math.clamp(lSmooth / 600.0, 0.35, 1.0)
            node.Color = Color3.fromHSV(hue, 0.9, val)
            node.Transparency = nodeTransparency
        end
    end

    -- Particle ring rate & speed modulation
    if Visualizer3D.ParticleEmitter then
        local isAudible = (lSmooth > 15.0)
        Visualizer3D.ParticleEmitter.Enabled = isAudible
        if isAudible then
            local rate = math.clamp(lSmooth / 15.0, 5.0, 100.0)
            local minSpd = 4.0 + (lSmooth / 100.0)
            local maxSpd = 8.0 + (lSmooth / 50.0)
            Visualizer3D.ParticleEmitter.Rate = rate
            Visualizer3D.ParticleEmitter.Speed = NumberRange.new(minSpd, maxSpd)

            local hue = (0.15 * t) % 1.0
            Visualizer3D.ParticleEmitter.Color = ColorSequence.new(Color3.fromHSV(hue, 0.8, 1.0))
        end
    end
end

function AudioEngine.SetVisualizer3DEnabled(enabled)
    Visualizer3D.Enabled = (enabled == true)
    initVisualizer3DNodes()

    if not Visualizer3D.Enabled then
        for i = 1, Visualizer3D.NodeCount do
            local node = Visualizer3D.Nodes[i]
            if node then node.Transparency = 1 end
        end
        if Visualizer3D.ParticleEmitter then
            Visualizer3D.ParticleEmitter.Enabled = false
        end
    end
end

-- ------------------------------------------------------------------------------
-- 10. FLOOR BEAT-DROP SHOCKWAVES (FEATURE 10)
-- ------------------------------------------------------------------------------
local ShockwaveEngine = {
    PoolSize = 3,
    Pool = {},
    Container = nil,
    Initialized = false
}

local function initShockwavePool()
    if ShockwaveEngine.Initialized then return end

    local container = Instance.new("Folder")
    container.Name = "GoHubV14_ShockwaveContainer"
    pcall(function() container.Parent = Workspace end)
    ShockwaveEngine.Container = container

    for i = 1, ShockwaveEngine.PoolSize do
        local part = Instance.new("Part")
        part.Name = "GoHub_ShockwaveSlot_" .. i
        part.Shape = Enum.PartType.Cylinder
        part.Size = Vector3.new(0.05, 1.0, 1.0)
        part.Orientation = Vector3.new(0, 0, 90) -- Orient flat on ground
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(186, 85, 255)
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Transparency = 1
        pcall(function() part.Parent = container end)

        ShockwaveEngine.Pool[i] = {
            Instance = part,
            InUse = false,
            ActiveTween = nil
        }
    end

    ShockwaveEngine.Initialized = true
end

local function spawnShockwaveRing(rootPos, hipHeight, color)
    initShockwavePool()

    -- Acquire free slot from pool (3 instances, zero allocation)
    local chosenSlot = nil
    for i = 1, ShockwaveEngine.PoolSize do
        local slot = ShockwaveEngine.Pool[i]
        if not slot.InUse then
            chosenSlot = slot
            break
        end
    end

    if not chosenSlot then
        -- All 3 shockwaves active: skip gracefully without allocations
        return
    end

    chosenSlot.InUse = true
    local ring = chosenSlot.Instance
    local groundY = rootPos.Y - (hipHeight + 1.2)
    local centerPos = Vector3.new(rootPos.X, groundY, rootPos.Z)

    -- Reset geometry for expansion
    ring.Size = Vector3.new(0.05, 1.0, 1.0)
    ring.CFrame = CFrame.new(centerPos) * CFrame.Angles(0, 0, math.rad(90))
    ring.Color = color or Color3.fromRGB(220, 80, 255)
    ring.Transparency = 0.15

    if TweenService then
        local tweenInfo = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local goal = {
            Size = Vector3.new(0.05, 22.0, 22.0),
            Transparency = 1.0
        }
        local tween = TweenService:Create(ring, tweenInfo, goal)
        chosenSlot.ActiveTween = tween
        tween:Play()

        tween.Completed:Connect(function()
            ring.Transparency = 1
            chosenSlot.InUse = false
            chosenSlot.ActiveTween = nil
        end)
    else
        ring.Transparency = 1
        chosenSlot.InUse = false
    end
end

-- Hook beat drop event to shockwave trigger
AudioEngine.OnBeatDrop:Connect(function(loudness)
    local hrp, char = getLocalRootPart()
    if not hrp then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hipHeight = (hum and hum.HipHeight) or 2.0

    -- Dynamic shockwave color based on loudness intensity
    local hue = (loudness > 600.0) and 0.85 or 0.78
    local col = Color3.fromHSV(hue, 0.9, 1.0)
    spawnShockwaveRing(hrp.Position, hipHeight, col)
end)

-- ------------------------------------------------------------------------------
-- 11. 2D SPECTRUM EQUALIZER HUD (FEATURE 11)
-- ------------------------------------------------------------------------------
local SpectrumHUD = {
    Enabled = false,
    BarCount = 12,
    Bars = {},
    Peaks = {},
    ScreenGui = nil,
    Container = nil,
    Heights = {},
    PeakHeights = {},
    FallRate = 1.8,
    PeakFallRate = 0.5,
    Initialized = false
}

local function initSpectrumHUD()
    if SpectrumHUD.Initialized then return end

    local guiRoot = getSafeGuiRoot()
    local sg = Instance.new("ScreenGui")
    sg.Name = "GoHubV14_SpectrumHUD"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 900
    pcall(function() sg.Parent = guiRoot end)
    SpectrumHUD.ScreenGui = sg

    -- Outer Card Frame
    local container = Instance.new("Frame")
    container.Name = "MainCard"
    container.Size = UDim2.new(0, 168, 0, 80)
    container.Position = UDim2.new(1, -188, 1, -120)
    container.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    container.BackgroundTransparency = 0.25
    container.BorderSizePixel = 0
    container.Visible = false
    container.Parent = sg

    local corner = Instance.new("UICorner", container)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", container)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(148, 0, 211)
    stroke.Transparency = 0.3

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -12, 0, 14)
    title.Position = UDim2.new(0, 6, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "EQUALIZER // 12-BAND"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 11
    title.TextColor3 = Color3.fromRGB(200, 180, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local barsArea = Instance.new("Frame")
    barsArea.Name = "BarsArea"
    barsArea.Size = UDim2.new(1, -12, 1, -26)
    barsArea.Position = UDim2.new(0, 6, 0, 20)
    barsArea.BackgroundTransparency = 1
    barsArea.Parent = container

    local barWidth = 10
    local gap = 3

    for k = 1, SpectrumHUD.BarCount do
        local slot = Instance.new("Frame")
        slot.Name = "Slot_" .. k
        slot.Size = UDim2.new(0, barWidth, 1, 0)
        slot.Position = UDim2.new(0, (k - 1) * (barWidth + gap), 0, 0)
        slot.BackgroundTransparency = 1
        slot.Parent = barsArea

        -- Bar Fill
        local bar = Instance.new("Frame")
        bar.Name = "BarFill"
        bar.AnchorPoint = Vector2.new(0, 1)
        bar.Position = UDim2.new(0, 0, 1, 0)
        bar.Size = UDim2.new(1, 0, 0, 0)
        bar.BorderSizePixel = 0
        bar.Parent = slot

        local bCorner = Instance.new("UICorner", bar)
        bCorner.CornerRadius = UDim.new(0, 2)

        -- Peak Line
        local peak = Instance.new("Frame")
        peak.Name = "PeakLine"
        peak.AnchorPoint = Vector2.new(0, 1)
        peak.Size = UDim2.new(1, 0, 0, 2)
        peak.Position = UDim2.new(0, 0, 1, 0)
        peak.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        peak.BorderSizePixel = 0
        peak.Parent = slot

        -- Frequency color mapping: Sub-Bass (1-3) -> Mids (4-7) -> Treble (8-12)
        local barColor
        if k <= 3 then
            barColor = Color3.fromRGB(255, 50, 120) -- Sub/Bass: Neon Pink / Magenta
        elseif k <= 7 then
            barColor = Color3.fromRGB(50, 230, 180) -- Mids: Aqua Cyan
        else
            barColor = Color3.fromRGB(160, 90, 255) -- Treble: Bright Purple
        end
        bar.BackgroundColor3 = barColor

        SpectrumHUD.Bars[k] = bar
        SpectrumHUD.Peaks[k] = peak
        SpectrumHUD.Heights[k] = 0.0
        SpectrumHUD.PeakHeights[k] = 0.0
    end

    SpectrumHUD.Container = container
    SpectrumHUD.Initialized = true
end

local function updateSpectrumHUD(dt, lInstant, lSmooth)
    if not SpectrumHUD.Enabled or not SpectrumHUD.Container then return end

    local dLoudness = math.abs(SignalEngine.LoudnessInstant - SignalEngine.LoudnessPrev)
    local t = os.clock()

    for k = 1, SpectrumHUD.BarCount do
        local targetH = 0.0

        if lInstant > 0 then
            if k <= 3 then
                -- Band 1..3: Sub/Bass high-gain low-pass
                local boostMul = 1.0 + (math.max(0.0, DSPEngine.LowGain) * 0.08)
                targetH = (lInstant / 1000.0) * boostMul + ((k - 1) * 0.04)
            elseif k <= 7 then
                -- Band 4..7: Mids transient rate-of-change
                local transient = (dLoudness / 500.0) * 0.7
                local midL = (lSmooth / 1000.0) * 0.5
                targetH = transient + midL + (math.sin(12.0 * t + k) * 0.08)
            else
                -- Band 8..12: Treble high-frequency pseudo-randomized jitter harmonics
                local harmonic = (lInstant % 150) / 150.0
                targetH = harmonic * (0.35 + (0.65 * math.abs(math.sin(18.0 * t + (k * 0.8)))))
            end
        end

        targetH = math.clamp(targetH, 0.0, 1.0)

        -- Bar Physics: h_k = max(target, h_prev - FallRate * dt)
        local hPrev = SpectrumHUD.Heights[k]
        local hCurr = math.max(targetH, hPrev - (SpectrumHUD.FallRate * dt))
        SpectrumHUD.Heights[k] = hCurr

        -- Peak Hold Physics: p_k = max(h_k, p_prev - PeakFallRate * dt)
        local pPrev = SpectrumHUD.PeakHeights[k]
        local pCurr = 0.0
        if hCurr >= pPrev then
            pCurr = hCurr
        else
            pCurr = math.max(hCurr, pPrev - (SpectrumHUD.PeakFallRate * dt))
        end
        SpectrumHUD.PeakHeights[k] = pCurr

        -- Zero-alloc GUI updates: set Size and Position directly
        local bar = SpectrumHUD.Bars[k]
        local peak = SpectrumHUD.Peaks[k]
        if bar and peak then
            bar.Size = UDim2.new(1, 0, hCurr, 0)
            peak.Position = UDim2.new(0, 0, 1.0 - pCurr, 0)
        end
    end
end

function AudioEngine.SetEqualizerHUDEnabled(enabled)
    SpectrumHUD.Enabled = (enabled == true)
    initSpectrumHUD()

    if SpectrumHUD.Container then
        SpectrumHUD.Container.Visible = SpectrumHUD.Enabled
    end
end

-- ------------------------------------------------------------------------------
-- 12. MASTER RENDER / HEARTBEAT DISPATCH LOOP
-- ------------------------------------------------------------------------------
local function onAudioHeartbeat(dt)
    -- Signal conditioning & beat detection
    local lInstant, lSmooth, isBeat = updateSignalProcessing(dt)

    -- 3D Character Visualizer Update
    if Visualizer3D.Enabled then
        updateVisualizer3D(dt, lInstant, lSmooth)
    end

    -- 2D Spectrum Equalizer HUD Update
    if SpectrumHUD.Enabled then
        updateSpectrumHUD(dt, lInstant, lSmooth)
    end
end

-- Register heartbeat loop into HubState lifecycle
if RunService then
    local conn = RunService.Heartbeat:Connect(onAudioHeartbeat)
    HubState.RegisterLoop("GoHubV14_AudioEngineCore", conn)
end

-- ------------------------------------------------------------------------------
-- 13. INITIALIZATION & RAYFIELD TAB ATTACHMENT
-- ------------------------------------------------------------------------------
function AudioEngine.Initialize()
    getAudioContainer()
    initSFXPool()
    initVisualizer3DNodes()
    initSpectrumHUD()
    return true
end

-- Optional Rayfield UI Tab Construction Hook
function AudioEngine.AttachToRayfield(window)
    if not window or not window.CreateTab then return nil end

    local audioTab = window:CreateTab("Audio & SFX", "music")
    if not audioTab then return nil end

    audioTab:CreateSection("Music Player & BGM Playlist")

    local trackTitles = {}
    for i = 1, #MusicPlayer.Playlist do
        trackTitles[i] = MusicPlayer.Playlist[i].Title
    end

    audioTab:CreateDropdown({
        Name = "Selecionar Faixa Musical",
        Options = trackTitles,
        CurrentOption = { MusicPlayer.Playlist[1].Title },
        Callback = function(selected)
            local choice = (type(selected) == "table" and selected[1]) or selected
            for i = 1, #MusicPlayer.Playlist do
                if MusicPlayer.Playlist[i].Title == choice then
                    AudioEngine.PlayTrack(i)
                    break
                end
            end
        end
    })

    audioTab:CreateSlider({
        Name = "Volume BGM",
        Range = { 0, 100 },
        Increment = 1,
        Suffix = "%",
        CurrentValue = math.floor(MusicPlayer.Volume * 100),
        Callback = function(val)
            AudioEngine.SetVolume(val / 100)
        end
    })

    audioTab:CreateSlider({
        Name = "Velocidade de Reprodução",
        Range = { 50, 200 },
        Increment = 5,
        Suffix = "%",
        CurrentValue = math.floor(MusicPlayer.PlaybackSpeed * 100),
        Callback = function(val)
            AudioEngine.SetSpeed(val / 100)
        end
    })

    audioTab:CreateToggle({
        Name = "Tocar / Pausar BGM",
        CurrentValue = MusicPlayer.IsPlaying,
        Callback = function(state)
            if state then
                AudioEngine.Resume()
            else
                AudioEngine.Pause()
            end
        end
    })

    audioTab:CreateDropdown({
        Name = "Modo de Loop da Playlist",
        Options = { "Sequential", "LoopTrack", "Shuffle" },
        CurrentOption = { "Sequential" },
        Callback = function(mode)
            local m = (type(mode) == "table" and mode[1]) or mode
            AudioEngine.SetLoopMode(m)
        end
    })

    audioTab:CreateSection("Bass Boost & Equalizador DSP")

    audioTab:CreateToggle({
        Name = "Ativar Bass Boost DSP",
        CurrentValue = DSPEngine.BassBoost,
        Callback = function(state)
            AudioEngine.SetBassBoost(state, DSPEngine.BassLevelDb > 0 and DSPEngine.BassLevelDb or 6.5)
        end
    })

    audioTab:CreateSlider({
        Name = "Nível de Bass (dB)",
        Range = { 0, 20 },
        Increment = 0.5,
        Suffix = " dB",
        CurrentValue = DSPEngine.BassLevelDb,
        Callback = function(val)
            AudioEngine.SetBassBoost(true, val)
        end
    })

    audioTab:CreateDropdown({
        Name = "Predefinições de Equalizador (DSP)",
        Options = { "Flat", "Bass Boost Standard", "Bass Boost Heavy", "Extreme Bass", "Nightcore", "Vaporwave" },
        CurrentOption = { "Flat" },
        Callback = function(profile)
            local p = (type(profile) == "table" and profile[1]) or profile
            AudioEngine.SetEqualizerProfile(p)
        end
    })

    audioTab:CreateSection("Visualizadores Reativos em Tempo Real")

    audioTab:CreateToggle({
        Name = "Visualizador 3D no Personagem (Anel Neon & Partículas)",
        CurrentValue = Visualizer3D.Enabled,
        Callback = function(state)
            AudioEngine.SetVisualizer3DEnabled(state)
        end
    })

    audioTab:CreateToggle({
        Name = "Exibir HUD Equalizador de Espectro 2D",
        CurrentValue = SpectrumHUD.Enabled,
        Callback = function(state)
            AudioEngine.SetEqualizerHUDEnabled(state)
        end
    })

    return audioTab
end

-- ------------------------------------------------------------------------------
-- 14. TEARDOWN & RECYCLING ROUTINE
-- ------------------------------------------------------------------------------
function AudioEngine.Destroy()
    AudioEngine.Teardown()
end

function AudioEngine.Teardown()
    -- Disconnect loops
    if HubState then
        HubState.DropLoop("GoHubV14_AudioEngineCore")
    end

    -- Stop active and fading sounds
    if MusicPlayer.ActiveSound then
        pcall(function()
            MusicPlayer.ActiveSound:Stop()
            MusicPlayer.ActiveSound:Destroy()
        end)
        MusicPlayer.ActiveSound = nil
    end

    if MusicPlayer.FadingSound then
        pcall(function()
            MusicPlayer.FadingSound:Stop()
            MusicPlayer.FadingSound:Destroy()
        end)
        MusicPlayer.FadingSound = nil
    end

    -- Destroy visualizer 3D nodes
    if Visualizer3D.Container then
        pcall(function() Visualizer3D.Container:Destroy() end)
        Visualizer3D.Container = nil
        Visualizer3D.Nodes = {}
    end

    if Visualizer3D.ParticleAttachment then
        pcall(function() Visualizer3D.ParticleAttachment:Destroy() end)
        Visualizer3D.ParticleAttachment = nil
        Visualizer3D.ParticleEmitter = nil
    end

    -- Destroy shockwave pool
    if ShockwaveEngine.Container then
        pcall(function() ShockwaveEngine.Container:Destroy() end)
        ShockwaveEngine.Container = nil
        ShockwaveEngine.Pool = {}
        ShockwaveEngine.Initialized = false
    end

    -- Destroy Spectrum HUD
    if SpectrumHUD.ScreenGui then
        pcall(function() SpectrumHUD.ScreenGui:Destroy() end)
        SpectrumHUD.ScreenGui = nil
        SpectrumHUD.Container = nil
        SpectrumHUD.Initialized = false
    end

    -- Destroy SFX pool
    if SFXEngine.Container then
        pcall(function() SFXEngine.Container:Destroy() end)
        SFXEngine.Container = nil
        SFXEngine.Pool = {}
    end
end

-- ------------------------------------------------------------------------------
-- 15. GLOBAL EXPORTS
-- ------------------------------------------------------------------------------
_G.GoHubV14Audio = AudioEngine
shared.GoHubV14Audio = AudioEngine

-- [Module Return] return AudioEngine
end

-- 3. GRAPHICS & SHADERS 2.0 (Milestone 3)
do
-- language: Lua, file: v14_shader_engine.lua, runtime: Roblox Luau, target: GoHub V14 Graphics & Shaders 2.0
-- ==============================================================================
-- GOHUB V14 — GRAPHICS & SHADERS 2.0 (MILESTONE 3)
-- Features 12 to 17:
--  - Feature 12: Dynamic Autofocus Depth of Field (DoF, 20Hz raycast + exponential smoothing)
--  - Feature 13: Dynamic Motion Blur (camera angular velocity delta omega = dTheta/dt)
--  - Feature 14: 4 New Cinematic Presets (Cyberpunk Neon, Sunset Noir, VHS Retro, Midnight Glow + Golden Hour)
--  - Feature 15: Shortest-Arc Day/Night Cycle (geodesic circular modulo 24)
--  - Feature 16: Camera-Space Particle Motes (vertical ceiling raycast indoor vs outdoor)
--  - Feature 17: V13 Visuals Preservation (Fullbright, NoFog, X-Ray with weak table __mode="k", Aimbot, Drawing FOV Circle)
--  - Lighting Preservation: PristineBaseline capture & ReconcileLighting multi-layer arbitrator
-- ==============================================================================

local LightingEngine = {}
LightingEngine.__index = LightingEngine
LightingEngine.Version = "14.0.0"

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

local Lighting = safeGetService("Lighting")
local Players = safeGetService("Players")
local RunService = safeGetService("RunService")
local UserInputService = safeGetService("UserInputService")
local Workspace = safeGetService("Workspace") or (typeof(workspace) == "userdata" and workspace)
local TweenService = safeGetService("TweenService")
local CoreGui = safeGetService("CoreGui")
local HttpService = safeGetService("HttpService")

local LocalPlayer = nil
if Players then
    LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        pcall(function()
            LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        end)
    end
end

local Camera = (Workspace and Workspace.CurrentCamera) or nil
if Workspace then
    pcall(function()
        Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            Camera = Workspace.CurrentCamera
        end)
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

-- Safe GUI Root Resolution (gethui -> get_hidden_gui -> CoreGui -> PlayerGui -> Workspace)
local function GetSafeGuiRoot()
    if typeof(gethui) == "function" then
        local ok, root = pcall(gethui)
        if ok and root then
            return root
        end
    end
    if typeof(get_hidden_gui) == "function" then
        local ok, root = pcall(get_hidden_gui)
        if ok and root then
            return root
        end
    end
    if CoreGui then
        return CoreGui
    end
    if LocalPlayer then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            return playerGui
        end
    end
    return Workspace
end

-- ------------------------------------------------------------------------------
-- 2. CENTRAL STATE REGISTRY (HUBSTATE SYNC & FALLBACK)
-- ------------------------------------------------------------------------------
local HubState = (getgenv and getgenv().HubState) or _G.HubState
if not HubState then
    HubState = {
        Connections = {},
        Loops = {},
        Pools = {
            Highlights = {},
            Adornments = {},
            Scratch = {}
        },
        Theme = {
            Accent = Color3.fromRGB(148, 0, 211),
            Glow = Color3.fromRGB(180, 50, 255),
            Dark = Color3.fromRGB(15, 15, 22),
            Card = Color3.fromRGB(28, 28, 40)
        },
        Visuals = {
            ShaderActive = false,
            ShaderPreset = "Golden Hour",
            FullbrightActive = false,
            NoFogActive = false,
            XRayActive = false,
            UniversalESP = false,
            BlurAA = 5,
            BloomIntensity = 0.3,
            SunRaysIntensity = 0.1,
            AutofocusDoF = false,
            MotionBlur = false,
            DayNightCycle = false,
            TimeSpeed = 1.0,
            ParticleMotes = false
        },
        Lighting = {
            autofocus_dof = false,
            motion_blur = false,
            preset = "Golden Hour",
            time_speed = 1.0,
            day_night = false,
            motes = false
        },
        Combat = {
            AimbotActive = false,
            VisibilityCheck = true,
            FOV = 120,
            Smoothness = 0.25,
            TargetPart = "Head",
            TeamCheck = false,
            FOVCircleVisible = false
        }
    }
    if getgenv then
        getgenv().HubState = HubState
    else
        _G.HubState = HubState
    end
else
    -- Ensure required sub-tables exist on existing HubState
    if not HubState.Visuals then
        HubState.Visuals = {}
    end
    if not HubState.Lighting then
        HubState.Lighting = {}
    end
    if not HubState.Combat then
        HubState.Combat = {}
    end
    if not HubState.Loops then
        HubState.Loops = {}
    end
    if not HubState.Connections then
        HubState.Connections = {}
    end
end

-- Synchronize HubState.Lighting and HubState.Visuals defaults
if HubState.Lighting.autofocus_dof == nil then
    HubState.Lighting.autofocus_dof = false
end
if HubState.Lighting.motion_blur == nil then
    HubState.Lighting.motion_blur = false
end
if HubState.Lighting.preset == nil then
    HubState.Lighting.preset = "Golden Hour"
end
if HubState.Lighting.time_speed == nil then
    HubState.Lighting.time_speed = 1.0
end
if HubState.Lighting.day_night == nil then
    HubState.Lighting.day_night = false
end
if HubState.Lighting.motes == nil then
    HubState.Lighting.motes = false
end

if HubState.Visuals.ShaderActive == nil then
    HubState.Visuals.ShaderActive = false
end
if HubState.Visuals.ShaderPreset == nil then
    HubState.Visuals.ShaderPreset = HubState.Lighting.preset or "Golden Hour"
end
if HubState.Visuals.FullbrightActive == nil then
    HubState.Visuals.FullbrightActive = false
end
if HubState.Visuals.NoFogActive == nil then
    HubState.Visuals.NoFogActive = false
end
if HubState.Visuals.XRayActive == nil then
    HubState.Visuals.XRayActive = false
end
if HubState.Visuals.UniversalESP == nil then
    HubState.Visuals.UniversalESP = false
end

-- ------------------------------------------------------------------------------
-- 3. CONNECTION POOLING (LIFECYCLE MANAGEMENT & MEMORY LEAK PREVENTION)
-- ------------------------------------------------------------------------------
local LocalActiveConnections = {}

local function RegisterLoop(tag, conn)
    if HubState and type(HubState.RegisterLoop) == "function" then
        return HubState.RegisterLoop(tag, conn)
    end
    if LocalActiveConnections[tag] then
        pcall(function()
            LocalActiveConnections[tag]:Disconnect()
        end)
    end
    LocalActiveConnections[tag] = conn
    return conn
end

local function DropLoop(tag)
    if HubState and type(HubState.DropLoop) == "function" then
        return HubState.DropLoop(tag)
    end
    if LocalActiveConnections[tag] then
        pcall(function()
            LocalActiveConnections[tag]:Disconnect()
        end)
        LocalActiveConnections[tag] = nil
    end
end

if not _G.RegisterLoop then
    _G.RegisterLoop = RegisterLoop
end
if not _G.DropLoop then
    _G.DropLoop = DropLoop
end

-- ------------------------------------------------------------------------------
-- 4. PRISTINE BASELINE & MULTI-LAYER LIGHTING ARBITRATOR
-- ------------------------------------------------------------------------------
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
    OriginalEffects = {},
    OriginalDoF = nil,
    OriginalBlur = nil
}

local ActiveShaderInstances = {}
local UIToggleElements = {}

local function CapturePristineBaseline()
    if PristineBaseline.Captured then
        return
    end
    if not Lighting then
        return
    end

    PristineBaseline.Brightness = Lighting.Brightness
    PristineBaseline.ExposureCompensation = Lighting.ExposureCompensation
    PristineBaseline.ClockTime = Lighting.ClockTime
    PristineBaseline.Ambient = Lighting.Ambient
    PristineBaseline.OutdoorAmbient = Lighting.OutdoorAmbient
    PristineBaseline.FogEnd = Lighting.FogEnd
    PristineBaseline.FogStart = Lighting.FogStart
    PristineBaseline.FogColor = Lighting.FogColor

    -- Catalog existing Atmosphere instances safely
    PristineBaseline.Atmospheres = {}
    for _, obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") and not obj:GetAttribute("GoHubShader") then
            PristineBaseline.Atmospheres[obj] = {
                Density = obj.Density,
                Offset = obj.Offset,
                Color = obj.Color,
                Decay = obj.Decay,
                Glare = obj.Glare,
                Haze = obj.Haze
            }
        end
    end

    -- Catalog original Sky and PostEffect instances without destruction
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
            if obj:IsA("DepthOfFieldEffect") and not PristineBaseline.OriginalDoF then
                PristineBaseline.OriginalDoF = obj
            elseif obj:IsA("BlurEffect") and not PristineBaseline.OriginalBlur then
                PristineBaseline.OriginalBlur = obj
            end
        end
    end

    PristineBaseline.Captured = true
end

-- ------------------------------------------------------------------------------
-- 5. CINEMATIC PRESETS CATALOG (FEATURE 14 + GOLDEN HOUR)
-- ------------------------------------------------------------------------------
local ShaderPresets = {
    ["Cyberpunk Neon"] = {
        Name = "Cyberpunk Neon",
        ColorCorrection = {
            Brightness = -0.02,
            Contrast = 0.38,
            Saturation = 0.65,
            TintColor = Color3.fromRGB(235, 245, 255)
        },
        Bloom = {
            Intensity = 1.30,
            Size = 24,
            Threshold = 0.70
        },
        Blur = {
            Size = 0
        },
        SunRays = {
            Intensity = 0.08,
            Spread = 0.65
        },
        Atmosphere = {
            Density = 0.36,
            Color = Color3.fromRGB(30, 10, 55),
            Decay = Color3.fromRGB(190, 25, 190),
            Glare = 0.40,
            Haze = 1.80
        },
        Lighting = {
            Brightness = 2.00,
            ExposureCompensation = 0.20,
            ClockTime = 23.6
        },
        Skybox = {
            SkyboxBk = "rbxassetid://159454299",
            SkyboxDn = "rbxassetid://159454296",
            SkyboxFt = "rbxassetid://159454293",
            SkyboxLf = "rbxassetid://159454286",
            SkyboxRt = "rbxassetid://159454300",
            SkyboxUp = "rbxassetid://159454288",
            StarCount = 5000,
            SunAngularSize = 6
        }
    },
    ["Sunset Noir"] = {
        Name = "Sunset Noir",
        ColorCorrection = {
            Brightness = 0.03,
            Contrast = 0.42,
            Saturation = 0.18,
            TintColor = Color3.fromRGB(255, 180, 140)
        },
        Bloom = {
            Intensity = 0.65,
            Size = 18,
            Threshold = 0.82
        },
        Blur = {
            Size = 0
        },
        SunRays = {
            Intensity = 0.32,
            Spread = 0.95
        },
        Atmosphere = {
            Density = 0.44,
            Color = Color3.fromRGB(190, 75, 30),
            Decay = Color3.fromRGB(85, 22, 12),
            Glare = 0.85,
            Haze = 2.60
        },
        Lighting = {
            Brightness = 1.85,
            ExposureCompensation = 0.15,
            ClockTime = 17.75
        },
        Skybox = {
            SkyboxBk = "rbxassetid://600830446",
            SkyboxDn = "rbxassetid://600831635",
            SkyboxFt = "rbxassetid://600832720",
            SkyboxLf = "rbxassetid://600886090",
            SkyboxRt = "rbxassetid://600833862",
            SkyboxUp = "rbxassetid://600835177",
            StarCount = 3000,
            SunAngularSize = 15
        }
    },
    ["VHS Retro"] = {
        Name = "VHS Retro",
        ColorCorrection = {
            Brightness = 0.05,
            Contrast = -0.08,
            Saturation = -0.22,
            TintColor = Color3.fromRGB(225, 255, 240)
        },
        Bloom = {
            Intensity = 0.85,
            Size = 36,
            Threshold = 0.55
        },
        Blur = {
            Size = 3
        },
        SunRays = {
            Intensity = 0.04,
            Spread = 0.50
        },
        Atmosphere = {
            Density = 0.22,
            Color = Color3.fromRGB(145, 165, 155),
            Decay = Color3.fromRGB(115, 125, 115),
            Glare = 0.20,
            Haze = 0.90
        },
        Lighting = {
            Brightness = 1.50,
            ExposureCompensation = 0.08,
            ClockTime = 14.2
        },
        Skybox = {
            SkyboxBk = "rbxassetid://698349005",
            SkyboxDn = "rbxassetid://698349202",
            SkyboxFt = "rbxassetid://698349354",
            SkyboxLf = "rbxassetid://698349503",
            SkyboxRt = "rbxassetid://698349669",
            SkyboxUp = "rbxassetid://698349826",
            StarCount = 1000,
            SunAngularSize = 10
        }
    },
    ["Midnight Glow"] = {
        Name = "Midnight Glow",
        ColorCorrection = {
            Brightness = -0.04,
            Contrast = 0.28,
            Saturation = 0.32,
            TintColor = Color3.fromRGB(175, 205, 255)
        },
        Bloom = {
            Intensity = 1.45,
            Size = 28,
            Threshold = 0.62
        },
        Blur = {
            Size = 0
        },
        SunRays = {
            Intensity = 0.00,
            Spread = 0.00
        },
        Atmosphere = {
            Density = 0.48,
            Color = Color3.fromRGB(12, 25, 60),
            Decay = Color3.fromRGB(6, 12, 32),
            Glare = 0.50,
            Haze = 2.20
        },
        Lighting = {
            Brightness = 1.20,
            ExposureCompensation = 0.35,
            ClockTime = 1.25
        },
        Skybox = {
            SkyboxBk = "rbxassetid://159454299",
            SkyboxDn = "rbxassetid://159454296",
            SkyboxFt = "rbxassetid://159454293",
            SkyboxLf = "rbxassetid://159454286",
            SkyboxRt = "rbxassetid://159454300",
            SkyboxUp = "rbxassetid://159454288",
            StarCount = 5000,
            SunAngularSize = 4
        }
    },
    ["Golden Hour"] = {
        Name = "Golden Hour",
        ColorCorrection = {
            Brightness = 0.0,
            Contrast = 0.10,
            Saturation = 0.25,
            TintColor = Color3.fromRGB(255, 255, 255)
        },
        Bloom = {
            Intensity = 0.30,
            Size = 10,
            Threshold = 0.80
        },
        Blur = {
            Size = 5
        },
        SunRays = {
            Intensity = 0.10,
            Spread = 0.80
        },
        Atmosphere = {
            Density = 0.30,
            Color = Color3.fromRGB(255, 200, 150),
            Decay = Color3.fromRGB(200, 100, 50),
            Glare = 0.50,
            Haze = 1.00
        },
        Lighting = {
            Brightness = 2.25,
            ExposureCompensation = 0.10,
            ClockTime = 17.55
        },
        Skybox = {
            SkyboxBk = "http://www.roblox.com/asset/?id=144933338",
            SkyboxDn = "http://www.roblox.com/asset/?id=144931530",
            SkyboxFt = "http://www.roblox.com/asset/?id=144933262",
            SkyboxLf = "http://www.roblox.com/asset/?id=144933244",
            SkyboxRt = "http://www.roblox.com/asset/?id=144933299",
            SkyboxUp = "http://www.roblox.com/asset/?id=144931564",
            StarCount = 5000,
            SunAngularSize = 5
        }
    }
}

-- Aliases for presets (unspaced and lowercase lookup)
local PresetAliases = {
    ["cyberpunkneon"] = "Cyberpunk Neon",
    ["cyberpunk"] = "Cyberpunk Neon",
    ["sunsetnoir"] = "Sunset Noir",
    ["sunset"] = "Sunset Noir",
    ["vhsretro"] = "VHS Retro",
    ["vhs"] = "VHS Retro",
    ["midnightglow"] = "Midnight Glow",
    ["midnight"] = "Midnight Glow",
    ["goldenhour"] = "Golden Hour",
    ["golden"] = "Golden Hour"
}

local function ResolvePresetName(name)
    if not name or type(name) ~= "string" then
        return "Golden Hour"
    end
    if ShaderPresets[name] then
        return name
    end
    local clean = name:lower():gsub("%s+", "")
    if PresetAliases[clean] then
        return PresetAliases[clean]
    end
    return "Golden Hour"
end

-- ------------------------------------------------------------------------------
-- 6. MULTI-LAYER LIGHTING ARBITRATOR (CONFLICT RESOLUTION)
-- ------------------------------------------------------------------------------
local function ReconcileLighting()
    if not PristineBaseline.Captured then
        CapturePristineBaseline()
    end
    if not Lighting then
        return
    end

    local shaderOn = HubState.Visuals.ShaderActive
    local fbOn = HubState.Visuals.FullbrightActive
    local noFogOn = HubState.Visuals.NoFogActive
    local activePresetName = ResolvePresetName(HubState.Visuals.ShaderPreset or HubState.Lighting.preset)
    local preset = ShaderPresets[activePresetName] or ShaderPresets["Golden Hour"]

    -- Layer 1: Ambient & OutdoorAmbient
    if fbOn then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = PristineBaseline.Ambient
        Lighting.OutdoorAmbient = PristineBaseline.OutdoorAmbient
    end

    -- Layer 2: Brightness, ExposureCompensation & ClockTime
    if shaderOn then
        Lighting.Brightness = preset.Lighting.Brightness or 2.25
        Lighting.ExposureCompensation = preset.Lighting.ExposureCompensation or 0.10
        if not HubState.Lighting.day_night and not HubState.Visuals.DayNightCycle then
            Lighting.ClockTime = preset.Lighting.ClockTime or 17.55
        end
    elseif fbOn then
        Lighting.Brightness = 2.0
        Lighting.ExposureCompensation = PristineBaseline.ExposureCompensation
        if not HubState.Lighting.day_night and not HubState.Visuals.DayNightCycle then
            Lighting.ClockTime = 14.0
        end
    else
        Lighting.Brightness = PristineBaseline.Brightness
        Lighting.ExposureCompensation = PristineBaseline.ExposureCompensation
        if not HubState.Lighting.day_night and not HubState.Visuals.DayNightCycle then
            Lighting.ClockTime = PristineBaseline.ClockTime
        end
    end

    -- Layer 3: Fog & Atmosphere Density
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
        for atm, origProps in pairs(PristineBaseline.Atmospheres) do
            if atm and atm.Parent then
                if shaderOn and preset.Atmosphere then
                    atm.Density = preset.Atmosphere.Density
                    atm.Color = preset.Atmosphere.Color
                    atm.Decay = preset.Atmosphere.Decay
                    atm.Glare = preset.Atmosphere.Glare
                    atm.Haze = preset.Atmosphere.Haze
                else
                    atm.Density = origProps.Density
                    atm.Color = origProps.Color
                    atm.Decay = origProps.Decay
                    atm.Glare = origProps.Glare
                    atm.Haze = origProps.Haze
                end
            end
        end
    end
end

-- ------------------------------------------------------------------------------
-- 7. SHADER INSTANCE FACTORY & LIFECYCLE
-- ------------------------------------------------------------------------------
local function RemoveShaderEffects()
    for _, inst in ipairs(ActiveShaderInstances) do
        if inst and inst.Parent then
            pcall(function()
                inst:Destroy()
            end)
        end
    end
    table.clear(ActiveShaderInstances)

    -- Restore original developer Sky
    if PristineBaseline.OriginalSky and PristineBaseline.OriginalSky.Parent == nil then
        pcall(function()
            PristineBaseline.OriginalSky.Parent = Lighting
        end)
    end

    -- Re-enable developer PostEffects
    for _, item in ipairs(PristineBaseline.OriginalEffects) do
        if item.Instance and item.Instance.Parent then
            pcall(function()
                item.Instance.Enabled = item.OriginalEnabled
            end)
        end
    end
end

local function CreateShaderEffects(presetName)
    CapturePristineBaseline()
    if not Lighting then
        return
    end

    -- Hide original developer Sky temporarily
    if PristineBaseline.OriginalSky and PristineBaseline.OriginalSky.Parent == Lighting then
        pcall(function()
            PristineBaseline.OriginalSky.Parent = nil
        end)
    end

    -- Temporarily disable developer PostEffects
    for _, item in ipairs(PristineBaseline.OriginalEffects) do
        if item.Instance and item.Instance.Parent then
            pcall(function()
                item.Instance.Enabled = false
            end)
        end
    end

    -- Remove any previously spawned GoHub instances
    for _, inst in ipairs(ActiveShaderInstances) do
        if inst and inst.Parent then
            pcall(function()
                inst:Destroy()
            end)
        end
    end
    table.clear(ActiveShaderInstances)

    local targetName = ResolvePresetName(presetName or HubState.Visuals.ShaderPreset or HubState.Lighting.preset)
    local preset = ShaderPresets[targetName] or ShaderPresets["Golden Hour"]

    -- 1. Skybox
    local sky = Instance.new("Sky")
    sky.Name = "GoHub_ShaderSky"
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
    table.insert(ActiveShaderInstances, sky)

    -- 2. BloomEffect
    local bloom = Instance.new("BloomEffect")
    bloom.Name = "GoHub_ShaderBloom"
    bloom:SetAttribute("GoHubShader", true)
    bloom.Intensity = HubState.Visuals.BloomIntensity or preset.Bloom.Intensity
    bloom.Size = preset.Bloom.Size
    bloom.Threshold = preset.Bloom.Threshold
    bloom.Parent = Lighting
    table.insert(ActiveShaderInstances, bloom)

    -- 3. BlurEffect (Anti-Aliasing)
    local blur = Instance.new("BlurEffect")
    blur.Name = "GoHub_ShaderBlur"
    blur:SetAttribute("GoHubShader", true)
    blur.Size = HubState.Visuals.BlurAA or preset.Blur.Size
    blur.Parent = Lighting
    table.insert(ActiveShaderInstances, blur)

    -- 4. ColorCorrectionEffect
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "GoHub_ShaderColorCorrection"
    cc:SetAttribute("GoHubShader", true)
    cc.Brightness = preset.ColorCorrection.Brightness
    cc.Contrast = preset.ColorCorrection.Contrast
    cc.Saturation = preset.ColorCorrection.Saturation
    cc.TintColor = preset.ColorCorrection.TintColor
    cc.Parent = Lighting
    table.insert(ActiveShaderInstances, cc)

    -- 5. SunRaysEffect
    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Name = "GoHub_ShaderSunRays"
    sunRays:SetAttribute("GoHubShader", true)
    sunRays.Intensity = HubState.Visuals.SunRaysIntensity or preset.SunRays.Intensity
    sunRays.Spread = preset.SunRays.Spread
    sunRays.Parent = Lighting
    table.insert(ActiveShaderInstances, sunRays)

    -- 6. Atmosphere (if not already present in Lighting, create managed one)
    local hasAtmo = false
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") then
            hasAtmo = true
            break
        end
    end
    if not hasAtmo and preset.Atmosphere then
        local atmo = Instance.new("Atmosphere")
        atmo.Name = "GoHub_ShaderAtmosphere"
        atmo:SetAttribute("GoHubShader", true)
        atmo.Density = preset.Atmosphere.Density
        atmo.Color = preset.Atmosphere.Color
        atmo.Decay = preset.Atmosphere.Decay
        atmo.Glare = preset.Atmosphere.Glare
        atmo.Haze = preset.Atmosphere.Haze
        atmo.Parent = Lighting
        table.insert(ActiveShaderInstances, atmo)
    end
end

-- ------------------------------------------------------------------------------
-- 8. FEATURE 12: DYNAMIC AUTOFOCUS DEPTH OF FIELD (20HZ RAYCAST + EXP SMOOTH)
-- ------------------------------------------------------------------------------
local DoFState = {
    Instance = nil,
    CurrentDistance = 50.0,
    TargetDistance = 50.0,
    SampleAccumulator = 0.0,
    SampleInterval = 0.05 -- 20Hz (1 / 20 = 0.05s)
}

local DoFRaycastParams = nil
local function GetDoFRaycastParams()
    if not DoFRaycastParams and typeof(RaycastParams) == "table" and RaycastParams.new then
        DoFRaycastParams = RaycastParams.new()
        DoFRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
        DoFRaycastParams.IgnoreWater = true
    end
    return DoFRaycastParams
end

local function ExponentialSmoothing(prevVal, targetVal, decayRate, dt)
    if dt <= 0 then
        return prevVal
    end
    local alpha = 1.0 - math.exp(-decayRate * dt)
    return prevVal + (targetVal - prevVal) * alpha
end

local function SetupDoFEffect()
    if DoFState.Instance and DoFState.Instance.Parent == Lighting then
        return DoFState.Instance
    end
    if not Lighting then
        return nil
    end

    local dof = Instance.new("DepthOfFieldEffect")
    dof.Name = "GoHub_ShaderDoF"
    dof:SetAttribute("GoHubShader", true)
    dof.FocusDistance = DoFState.CurrentDistance
    dof.InFocusRadius = math.max(5.0, DoFState.CurrentDistance * 0.25)
    dof.NearIntensity = 0.35
    dof.FarIntensity = 0.75
    dof.Parent = Lighting
    DoFState.Instance = dof
    return dof
end

local function TeardownDoFEffect()
    DropLoop("DoF_Autofocus_Loop")
    if DoFState.Instance and DoFState.Instance.Parent then
        pcall(function()
            DoFState.Instance:Destroy()
        end)
        DoFState.Instance = nil
    end
end

local function UpdateDoFAutofocus(dt)
    if not HubState.Lighting.autofocus_dof and not HubState.Visuals.AutofocusDoF then
        return
    end
    if not Camera and Workspace then
        Camera = Workspace.CurrentCamera
    end
    if not Camera then
        return
    end

    local dof = SetupDoFEffect()
    if not dof then
        return
    end

    -- 20Hz Raycast Sampling Step
    DoFState.SampleAccumulator = DoFState.SampleAccumulator + dt
    if DoFState.SampleAccumulator >= DoFState.SampleInterval then
        DoFState.SampleAccumulator = DoFState.SampleAccumulator % DoFState.SampleInterval

        local origin = Camera.CFrame.Position
        local dir = Camera.CFrame.LookVector * 1000.0

        local params = GetDoFRaycastParams()
        local filterList = {Camera}
        if LocalPlayer and LocalPlayer.Character then
            table.insert(filterList, LocalPlayer.Character)
        end
        if params then
            params.FilterDescendantsInstances = filterList
        end

        local hit = Workspace:Raycast(origin, dir, params)
        local rawDist = 500.0
        if hit and hit.Position then
            rawDist = (hit.Position - origin).Magnitude
        else
            rawDist = 500.0
        end

        -- Focus distance clamped to [0.5, 500.0]
        DoFState.TargetDistance = math.clamp(rawDist, 0.5, 500.0)
    end

    -- Continuous exponential smoothing every frame (decay rate = 8.0)
    DoFState.CurrentDistance = ExponentialSmoothing(DoFState.CurrentDistance, DoFState.TargetDistance, 8.0, dt)

    dof.FocusDistance = DoFState.CurrentDistance
    dof.InFocusRadius = math.max(5.0, DoFState.CurrentDistance * 0.25)
    dof.NearIntensity = 0.35
    dof.FarIntensity = 0.75
end

-- ------------------------------------------------------------------------------
-- 9. FEATURE 13: DYNAMIC MOTION BLUR (CAMERA ANGULAR VELOCITY DELTA)
-- ------------------------------------------------------------------------------
local MotionBlurState = {
    Instance = nil,
    CurrentBlur = 0.0,
    PreviousLookVector = nil,
    Scale = 1.5,
    MaxBlur = 24.0
}

local function SetupMotionBlurEffect()
    if MotionBlurState.Instance and MotionBlurState.Instance.Parent == Lighting then
        return MotionBlurState.Instance
    end
    if not Lighting then
        return nil
    end

    local blur = Instance.new("BlurEffect")
    blur.Name = "GoHub_ShaderMotionBlur"
    blur:SetAttribute("GoHubShader", true)
    blur.Size = 0
    blur.Parent = Lighting
    MotionBlurState.Instance = blur
    return blur
end

local function TeardownMotionBlurEffect()
    DropLoop("MotionBlur_Loop")
    if MotionBlurState.Instance and MotionBlurState.Instance.Parent then
        pcall(function()
            MotionBlurState.Instance:Destroy()
        end)
        MotionBlurState.Instance = nil
    end
    MotionBlurState.CurrentBlur = 0.0
    MotionBlurState.PreviousLookVector = nil
end

local function UpdateMotionBlur(dt)
    if not HubState.Lighting.motion_blur and not HubState.Visuals.MotionBlur then
        return
    end
    if not Camera and Workspace then
        Camera = Workspace.CurrentCamera
    end
    if not Camera then
        return
    end

    local blur = SetupMotionBlurEffect()
    if not blur then
        return
    end

    local currentLook = Camera.CFrame.LookVector
    local targetBlur = 0.0

    if MotionBlurState.PreviousLookVector and dt > 0.0001 then
        local v1 = MotionBlurState.PreviousLookVector
        local v2 = currentLook
        local dot = math.clamp(v1.X * v2.X + v1.Y * v2.Y + v1.Z * v2.Z, -1.0, 1.0)
        local dTheta = math.acos(dot)
        local omega = dTheta / dt
        if omega < 0 then
            omega = 0
        end

        targetBlur = math.clamp(omega * MotionBlurState.Scale, 0.0, MotionBlurState.MaxBlur)
    end
    MotionBlurState.PreviousLookVector = currentLook

    -- Asymmetric decay smoothing: attack = 25.0, decay = 12.0
    local decayRate = (targetBlur > MotionBlurState.CurrentBlur) and 25.0 or 12.0
    MotionBlurState.CurrentBlur = ExponentialSmoothing(MotionBlurState.CurrentBlur, targetBlur, decayRate, dt)

    blur.Size = math.clamp(math.floor(MotionBlurState.CurrentBlur + 0.5), 0, 24)
end

-- ------------------------------------------------------------------------------
-- 10. FEATURE 15: SHORTEST-ARC DAY/NIGHT CYCLE (GEODESIC 24H INTERPOLATION)
-- ------------------------------------------------------------------------------
local function ShortestArcClockTime(currentTime, targetTime, step)
    local delta = ((targetTime - currentTime + 12.0) % 24.0) - 12.0
    if math.abs(delta) <= step then
        return targetTime % 24.0
    end
    local direction = (delta > 0) and 1.0 or -1.0
    local nextTime = (currentTime + direction * step) % 24.0
    return nextTime
end

local function UpdateDayNightCycle(dt)
    if not HubState.Lighting.day_night and not HubState.Visuals.DayNightCycle then
        return
    end
    if not Lighting then
        return
    end

    local speed = HubState.Lighting.time_speed or HubState.Visuals.TimeSpeed or 1.0
    -- Standard progression: 1 second = speed * 0.1 game hours
    local step = (speed * 0.1) * dt
    Lighting.ClockTime = (Lighting.ClockTime + step) % 24.0
end

-- ------------------------------------------------------------------------------
-- 11. FEATURE 16: CAMERA-SPACE PARTICLE MOTES WITH CEILING DETECTION
-- ------------------------------------------------------------------------------
local MotesState = {
    Container = nil,
    Emitter = nil,
    HasCeiling = false,
    CurrentRate = 12.0,
    TargetRate = 45.0,
    SampleAccumulator = 0.0,
    BoxHalfExtents = Vector3.new(15.0, 10.0, 15.0)
}

local MotesRaycastParams = nil
local function GetMotesRaycastParams()
    if not MotesRaycastParams and typeof(RaycastParams) == "table" and RaycastParams.new then
        MotesRaycastParams = RaycastParams.new()
        MotesRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
        MotesRaycastParams.IgnoreWater = true
    end
    return MotesRaycastParams
end

local function SetupParticleMotes()
    if MotesState.Container and MotesState.Container.Parent then
        return MotesState.Emitter
    end
    if not Camera and Workspace then
        Camera = Workspace.CurrentCamera
    end
    if not Camera then
        return nil
    end

    -- Create invisible container part parented directly to Camera
    local part = Instance.new("Part")
    part.Name = "GoHub_CameraMotesContainer"
    part:SetAttribute("GoHubShader", true)
    part.Size = Vector3.new(30.0, 20.0, 30.0)
    part.CFrame = Camera.CFrame * CFrame.new(0, 0, -6)
    part.Transparency = 1.0
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Anchored = true
    part.Parent = Camera
    MotesState.Container = part

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "GoHub_MoteEmitter"
    emitter.Rate = MotesState.CurrentRate
    emitter.Lifetime = NumberRange.new(2.5, 4.5)
    emitter.Speed = NumberRange.new(0.4, 1.6)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.5, 0.12),
        NumberSequenceKeypoint.new(1, 0.02)
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.0),
        NumberSequenceKeypoint.new(0.2, 0.35),
        NumberSequenceKeypoint.new(0.8, 0.35),
        NumberSequenceKeypoint.new(1, 1.0)
    })
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 210, 140))
    emitter.Parent = part
    MotesState.Emitter = emitter

    return emitter
end

local function TeardownParticleMotes()
    DropLoop("ParticleMotes_Loop")
    if MotesState.Container and MotesState.Container.Parent then
        pcall(function()
            MotesState.Container:Destroy()
        end)
        MotesState.Container = nil
        MotesState.Emitter = nil
    end
end

local function UpdateParticleMotes(dt)
    if not HubState.Lighting.motes and not HubState.Visuals.ParticleMotes then
        return
    end
    if not LocalPlayer or not LocalPlayer.Character then
        -- Suppress motes if character is absent
        if MotesState.Emitter then
            MotesState.Emitter.Rate = 0
        end
        return
    end
    if not Camera and Workspace then
        Camera = Workspace.CurrentCamera
    end
    if not Camera then
        return
    end

    local emitter = SetupParticleMotes()
    if not emitter or not MotesState.Container then
        return
    end

    -- Lock container to Camera position
    MotesState.Container.CFrame = Camera.CFrame * CFrame.new(0, 0, -6)

    -- Raycast ceiling detection at 20Hz
    MotesState.SampleAccumulator = MotesState.SampleAccumulator + dt
    if MotesState.SampleAccumulator >= 0.05 then
        MotesState.SampleAccumulator = MotesState.SampleAccumulator % 0.05

        local origin = Camera.CFrame.Position
        local upDir = Vector3.new(0, 32.0, 0)
        local params = GetMotesRaycastParams()
        local filterList = {Camera}
        if LocalPlayer and LocalPlayer.Character then
            table.insert(filterList, LocalPlayer.Character)
        end
        if params then
            params.FilterDescendantsInstances = filterList
        end

        local hit = Workspace:Raycast(origin, upDir, params)
        if hit and hit.Position then
            local dist = (hit.Position - origin).Magnitude
            if dist < 28.0 then
                MotesState.HasCeiling = true
                -- Indoor micro-dust (rate: 12.0)
                MotesState.TargetRate = 12.0
            else
                MotesState.HasCeiling = false
                -- Outdoor embers (rate: 45.0)
                MotesState.TargetRate = 45.0
            end
        else
            MotesState.HasCeiling = false
            MotesState.TargetRate = 45.0
        end
    end

    -- Smooth rate transition
    MotesState.CurrentRate = ExponentialSmoothing(MotesState.CurrentRate, MotesState.TargetRate, 5.0, dt)
    local clampedRate = math.clamp(MotesState.CurrentRate, 5.0, 60.0)
    emitter.Rate = clampedRate

    -- Tint adjustment based on environment
    if MotesState.HasCeiling then
        emitter.Color = ColorSequence.new(Color3.fromRGB(220, 225, 235))
    else
        emitter.Color = ColorSequence.new(Color3.fromRGB(255, 195, 120))
    end
end

-- ------------------------------------------------------------------------------
-- 12. FEATURE 17: V13 VISUALS PRESERVATION (FULLBRIGHT, NOFOG, X-RAY, AIMBOT, FOV)
-- ------------------------------------------------------------------------------
local VisualsEngine = {}
local CombatEngine = {}

-- Weak table caching (__mode = "k") prevents memory leaks with StreamingEnabled
local SavedTransparencies = setmetatable({}, { __mode = "k" })
local UniversalESPHighlights = {}
local MaxHighlights = 24
local StandaloneHighlightPool = {}
local StandalonePoolInitialized = false

local function InitHighlightPool()
    if StandalonePoolInitialized then
        return
    end
    if HubState and HubState.HighlightPool and HubState.HighlightPool.Instances then
        for i = 1, 24 do
            StandaloneHighlightPool[i] = HubState.HighlightPool.Instances[i]
        end
        StandalonePoolInitialized = true
        return
    end
    local guiRoot = GetSafeGuiRoot()
    for i = 1, 24 do
        local createInst = Instance["new"]
        local hl = createInst("Highlight")
        hl.Name = "GoHub_Shader_ESP_" .. i
        hl.FillColor = HubState.Theme.Accent or Color3.fromRGB(148, 0, 211)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.4
        hl.Enabled = false
        pcall(function()
            hl.Parent = guiRoot
        end)
        StandaloneHighlightPool[i] = hl
    end
    StandalonePoolInitialized = true
end

function VisualsEngine.ToggleXRay(enabled)
    HubState.Visuals.XRayActive = enabled
    if not Workspace then
        return
    end

    if enabled then
        local myChar = LocalPlayer and LocalPlayer.Character
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not (myChar and obj:IsDescendantOf(myChar)) then
                local isPlayerPart = false
                if Players then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character and obj:IsDescendantOf(p.Character) then
                            isPlayerPart = true
                            break
                        end
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
                pcall(function()
                    obj.Transparency = orig
                end)
            end
        end
        table.clear(SavedTransparencies)
    end

    if UIToggleElements.XRay and UIToggleElements.XRay.Set then
        pcall(function()
            UIToggleElements.XRay:Set(enabled)
        end)
    end
end

function VisualsEngine.ToggleUniversalESP(enabled)
    HubState.Visuals.UniversalESP = enabled
    if not enabled then
        DropLoop("UniversalESP_Loop")
        if HubState and type(HubState.ReleaseHighlight) == "function" then
            for _, hl in pairs(UniversalESPHighlights) do
                HubState.ReleaseHighlight(hl)
            end
        else
            for _, hl in ipairs(StandaloneHighlightPool) do
                if hl then
                    hl.Enabled = false
                    hl.Adornee = nil
                end
            end
        end
        table.clear(UniversalESPHighlights)
        if UIToggleElements.UniversalESP and UIToggleElements.UniversalESP.Set then
            pcall(function()
                UIToggleElements.UniversalESP:Set(false)
            end)
        end
        return
    end

    if not (HubState and type(HubState.AcquireHighlight) == "function") then
        InitHighlightPool()
    end

    local function updateUniversalESP()
        if not HubState.Visuals.UniversalESP or not Players then
            return
        end
        if HubState and type(HubState.AcquireHighlight) == "function" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    if not UniversalESPHighlights[p] then
                        local hl = HubState.AcquireHighlight(p.Character, 4, HubState.Theme.Accent or Color3.fromRGB(148, 0, 211), Color3.fromRGB(255, 255, 255))
                        if hl then
                            UniversalESPHighlights[p] = hl
                        end
                    end
                end
            end
        else
            local poolIndex = 1
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and poolIndex <= 24 then
                    local hl = StandaloneHighlightPool[poolIndex]
                    if hl then
                        hl.Adornee = p.Character
                        hl.FillColor = HubState.Theme.Accent or Color3.fromRGB(148, 0, 211)
                        hl.Enabled = true
                        UniversalESPHighlights[p] = hl
                        poolIndex = poolIndex + 1
                    end
                end
            end
            for i = poolIndex, 24 do
                local hl = StandaloneHighlightPool[i]
                if hl then
                    hl.Enabled = false
                    hl.Adornee = nil
                end
            end
        end
    end

    RegisterLoop("UniversalESP_Loop", RunService.Heartbeat:Connect(updateUniversalESP))

    if UIToggleElements.UniversalESP and UIToggleElements.UniversalESP.Set then
        pcall(function()
            UIToggleElements.UniversalESP:Set(true)
        end)
    end
end

-- Combat Engine: Raycast Aimbot & FOV Circle
local DrawingCircle = nil
local FallbackGui = nil
local FallbackFrame = nil

local CombatRaycastParams = nil
local function GetCombatRaycastParams()
    if not CombatRaycastParams and typeof(RaycastParams) == "table" and RaycastParams.new then
        CombatRaycastParams = RaycastParams.new()
        CombatRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
        CombatRaycastParams.IgnoreWater = true
    end
    return CombatRaycastParams
end

local function RaycastVisibilityCheck(part, targetChar)
    if not Camera and Workspace then
        Camera = Workspace.CurrentCamera
    end
    if not Camera or not part then
        return false
    end

    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local params = GetCombatRaycastParams()
    local filterList = {Camera}
    if LocalPlayer and LocalPlayer.Character then
        table.insert(filterList, LocalPlayer.Character)
    end
    if params then
        params.FilterDescendantsInstances = filterList
    end

    local result = Workspace:Raycast(origin, dir, params)
    if result and result.Instance then
        return result.Instance:IsDescendantOf(targetChar)
    end
    return true
end

function CombatEngine.GetBestTarget()
    local best = nil
    local minDist = HubState.Combat.FOV or 120.0
    local mouseLoc = Vector2.new(0, 0)
    if UserInputService then
        local mPos = UserInputService:GetMouseLocation()
        mouseLoc = Vector2.new(mPos.X, mPos.Y)
    elseif LocalPlayer then
        local m = LocalPlayer:GetMouse()
        if m then
            mouseLoc = Vector2.new(m.X, m.Y)
        end
    end

    if not Players or not Camera then
        return nil
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local isTeammate = HubState.Combat.TeamCheck and (p.Team == LocalPlayer.Team)
            if not isTeammate then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local targetPartName = HubState.Combat.TargetPart or "Head"
                local part = p.Character:FindFirstChild(targetPartName)
                if hum and hum.Health > 0 and part then
                    local sPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local sPos = Vector2.new(sPoint.X, sPoint.Y)
                        local dist = (sPos - mouseLoc).Magnitude
                        if dist < minDist then
                            if not HubState.Combat.VisibilityCheck or RaycastVisibilityCheck(part, p.Character) then
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

function CombatEngine.ToggleAimbot(enabled)
    HubState.Combat.AimbotActive = enabled
    if not enabled then
        DropLoop("Aimbot_Render")
        if UIToggleElements.Aimbot and UIToggleElements.Aimbot.Set then
            pcall(function()
                UIToggleElements.Aimbot:Set(false)
            end)
        end
        return
    end

    RegisterLoop("Aimbot_Render", RunService.RenderStepped:Connect(function()
        if not HubState.Combat.AimbotActive then
            return
        end
        if not UserInputService or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            return
        end

        local target = CombatEngine.GetBestTarget()
        if target and Camera then
            local camCF = Camera.CFrame
            local targetCF = CFrame.new(camCF.Position, target.Position)
            local smoothness = math.clamp(HubState.Combat.Smoothness or 0.25, 0.05, 1.0)
            Camera.CFrame = camCF:Lerp(targetCF, smoothness)
        end
    end))

    if UIToggleElements.Aimbot and UIToggleElements.Aimbot.Set then
        pcall(function()
            UIToggleElements.Aimbot:Set(true)
        end)
    end
end

function CombatEngine.ToggleVisibilityCheck(enabled)
    HubState.Combat.VisibilityCheck = enabled
    if UIToggleElements.VisCheck and UIToggleElements.VisCheck.Set then
        pcall(function()
            UIToggleElements.VisCheck:Set(enabled)
        end)
    end
end

function CombatEngine.SetFOV(radius)
    HubState.Combat.FOV = radius
    if DrawingCircle then
        DrawingCircle.Radius = radius
    end
    if FallbackFrame then
        local diam = radius * 2
        FallbackFrame.Size = UDim2.new(0, diam, 0, diam)
    end
    if UIToggleElements.FOVSlider and UIToggleElements.FOVSlider.Set then
        pcall(function()
            UIToggleElements.FOVSlider:Set(radius)
        end)
    end
end

function CombatEngine.ToggleFOVCircle(enabled)
    HubState.Combat.FOVCircleVisible = enabled

    -- Check native Drawing support
    local hasDrawing = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")

    if not enabled then
        DropLoop("FOVCircle_Loop")
        if DrawingCircle then
            pcall(function()
                DrawingCircle.Visible = false
                DrawingCircle:Remove()
            end)
            DrawingCircle = nil
        end
        if FallbackGui then
            pcall(function()
                FallbackGui:Destroy()
            end)
            FallbackGui = nil
            FallbackFrame = nil
        end
        return
    end

    if hasDrawing then
        if not DrawingCircle then
            local circle = Drawing.new("Circle")
            circle.Thickness = 1.5
            circle.NumSides = 64
            circle.Radius = HubState.Combat.FOV or 120.0
            circle.Filled = false
            circle.Transparency = 1.0
            circle.Color = Color3.fromRGB(255, 255, 255)
            circle.Visible = true
            DrawingCircle = circle
        end

        RegisterLoop("FOVCircle_Loop", RunService.RenderStepped:Connect(function()
            if not HubState.Combat.FOVCircleVisible or not DrawingCircle then
                return
            end
            local mouseLoc = Vector2.new(0, 0)
            if UserInputService then
                local mPos = UserInputService:GetMouseLocation()
                mouseLoc = Vector2.new(mPos.X, mPos.Y)
            end
            DrawingCircle.Position = mouseLoc
            DrawingCircle.Radius = HubState.Combat.FOV or 120.0
            DrawingCircle.Visible = true
        end))
    else
        -- ScreenGui Fallback for environments lacking Drawing API
        local guiRoot = GetSafeGuiRoot()
        if not FallbackGui and guiRoot then
            local sg = Instance.new("ScreenGui")
            sg.Name = "GoHub_FOVCircleFallback"
            sg.ResetOnSpawn = false
            sg.DisplayOrder = 999
            sg.Parent = guiRoot
            FallbackGui = sg

            local fovRadius = HubState.Combat.FOV or 120.0
            local diam = fovRadius * 2

            local frame = Instance.new("Frame")
            frame.Name = "CircleRing"
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
            frame.Size = UDim2.new(0, diam, 0, diam)
            frame.BackgroundTransparency = 1.0
            frame.Parent = sg

            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(1, 0)
            uiCorner.Parent = frame

            local uiStroke = Instance.new("UIStroke")
            uiStroke.Thickness = 1.5
            uiStroke.Color = Color3.fromRGB(255, 255, 255)
            uiStroke.Transparency = 0.2
            uiStroke.Parent = frame

            FallbackFrame = frame
        end

        RegisterLoop("FOVCircle_Loop", RunService.RenderStepped:Connect(function()
            if not HubState.Combat.FOVCircleVisible or not FallbackFrame then
                return
            end
            local mouseLoc = Vector2.new(0, 0)
            if UserInputService then
                local mPos = UserInputService:GetMouseLocation()
                mouseLoc = Vector2.new(mPos.X, mPos.Y)
            end
            local fovRadius = HubState.Combat.FOV or 120.0
            local diam = fovRadius * 2
            FallbackFrame.Size = UDim2.new(0, diam, 0, diam)
            FallbackFrame.Position = UDim2.new(0, mouseLoc.X, 0, mouseLoc.Y)
            FallbackFrame.Visible = true
        end))
    end

    if UIToggleElements.FOVCircle and UIToggleElements.FOVCircle.Set then
        pcall(function()
            UIToggleElements.FOVCircle:Set(true)
        end)
    end
end

-- ------------------------------------------------------------------------------
-- 13. MASTER LIGHTING ENGINE INTERFACE CONTRACT
-- ------------------------------------------------------------------------------

-- Applies any named preset non-destructively
function LightingEngine.ApplyPreset(presetName)
    local resolved = ResolvePresetName(presetName)
    HubState.Lighting.preset = resolved
    HubState.Visuals.ShaderPreset = resolved
    CapturePristineBaseline()

    if HubState.Visuals.ShaderActive then
        CreateShaderEffects(resolved)
    end
    ReconcileLighting()

    if UIToggleElements.PresetDropdown and UIToggleElements.PresetDropdown.Set then
        pcall(function()
            UIToggleElements.PresetDropdown:Set(resolved)
        end)
    end
end

-- Dynamic Autofocus Depth of Field toggle
function LightingEngine.SetAutofocusDoF(enabled)
    HubState.Lighting.autofocus_dof = enabled
    HubState.Visuals.AutofocusDoF = enabled
    CapturePristineBaseline()

    if enabled then
        SetupDoFEffect()
        RegisterLoop("DoF_Autofocus_Loop", RunService.RenderStepped:Connect(function(dt)
            UpdateDoFAutofocus(dt)
        end))
    else
        TeardownDoFEffect()
        if PristineBaseline.OriginalDoF and PristineBaseline.OriginalDoF.Parent then
            pcall(function()
                PristineBaseline.OriginalDoF.Enabled = true
            end)
        end
    end

    if UIToggleElements.AutofocusDoF and UIToggleElements.AutofocusDoF.Set then
        pcall(function()
            UIToggleElements.AutofocusDoF:Set(enabled)
        end)
    end
end

-- Dynamic Motion Blur toggle
function LightingEngine.SetMotionBlur(enabled)
    HubState.Lighting.motion_blur = enabled
    HubState.Visuals.MotionBlur = enabled
    CapturePristineBaseline()

    if enabled then
        SetupMotionBlurEffect()
        RegisterLoop("MotionBlur_Loop", RunService.RenderStepped:Connect(function(dt)
            UpdateMotionBlur(dt)
        end))
    else
        TeardownMotionBlurEffect()
        if PristineBaseline.OriginalBlur and PristineBaseline.OriginalBlur.Parent then
            pcall(function()
                PristineBaseline.OriginalBlur.Enabled = true
            end)
        end
    end

    if UIToggleElements.MotionBlur and UIToggleElements.MotionBlur.Set then
        pcall(function()
            UIToggleElements.MotionBlur:Set(enabled)
        end)
    end
end

-- Smooth Day/Night Cycle toggle with speed multiplier
function LightingEngine.SetTimeCycle(enabled, speedMultiplier)
    HubState.Lighting.day_night = enabled
    HubState.Visuals.DayNightCycle = enabled
    if speedMultiplier ~= nil then
        HubState.Lighting.time_speed = speedMultiplier
        HubState.Visuals.TimeSpeed = speedMultiplier
    end
    CapturePristineBaseline()

    if enabled then
        RegisterLoop("DayNight_Cycle", RunService.Heartbeat:Connect(function(dt)
            UpdateDayNightCycle(dt)
        end))
    else
        DropLoop("DayNight_Cycle")
        ReconcileLighting()
    end

    if UIToggleElements.DayNight and UIToggleElements.DayNight.Set then
        pcall(function()
            UIToggleElements.DayNight:Set(enabled)
        end)
    end
end

-- Camera-Space Particle Motes toggle
function LightingEngine.SetParticleMotesEnabled(enabled)
    HubState.Lighting.motes = enabled
    HubState.Visuals.ParticleMotes = enabled

    if enabled then
        SetupParticleMotes()
        RegisterLoop("ParticleMotes_Loop", RunService.RenderStepped:Connect(function(dt)
            UpdateParticleMotes(dt)
        end))
    else
        TeardownParticleMotes()
    end

    if UIToggleElements.ParticleMotes and UIToggleElements.ParticleMotes.Set then
        pcall(function()
            UIToggleElements.ParticleMotes:Set(enabled)
        end)
    end
end

-- Full restoration of original pristine lighting baseline
function LightingEngine.RestoreBaseline()
    if not PristineBaseline.Captured then
        return
    end

    -- Deactivate all features
    LightingEngine.SetAutofocusDoF(false)
    LightingEngine.SetMotionBlur(false)
    LightingEngine.SetTimeCycle(false)
    LightingEngine.SetParticleMotesEnabled(false)

    HubState.Visuals.ShaderActive = false
    HubState.Visuals.FullbrightActive = false
    HubState.Visuals.NoFogActive = false

    -- Clean up shader effects and restore original instances
    RemoveShaderEffects()

    if Lighting then
        Lighting.Brightness = PristineBaseline.Brightness
        Lighting.ExposureCompensation = PristineBaseline.ExposureCompensation
        Lighting.ClockTime = PristineBaseline.ClockTime
        Lighting.Ambient = PristineBaseline.Ambient
        Lighting.OutdoorAmbient = PristineBaseline.OutdoorAmbient
        Lighting.FogEnd = PristineBaseline.FogEnd
        Lighting.FogStart = PristineBaseline.FogStart
        Lighting.FogColor = PristineBaseline.FogColor

        for atm, origProps in pairs(PristineBaseline.Atmospheres) do
            if atm and atm.Parent then
                atm.Density = origProps.Density
                atm.Color = origProps.Color
                atm.Decay = origProps.Decay
                atm.Glare = origProps.Glare
                atm.Haze = origProps.Haze
            end
        end
    end
end

-- V13 Shader Toggle
function LightingEngine.ToggleShader(enabled)
    HubState.Visuals.ShaderActive = enabled
    CapturePristineBaseline()

    if enabled then
        CreateShaderEffects(HubState.Visuals.ShaderPreset or HubState.Lighting.preset)
    else
        RemoveShaderEffects()
    end

    ReconcileLighting()

    if UIToggleElements.Shader and UIToggleElements.Shader.Set then
        pcall(function()
            UIToggleElements.Shader:Set(enabled)
        end)
    end

    if _G.Rayfield and _G.Rayfield.Notify then
        _G.Rayfield:Notify({
            Title = "Shaders Cinemáticos",
            Content = enabled and "Shaders Ativados com Sucesso!" or "Shaders Desativados (Restauração Completa)",
            Duration = 2.5,
            Image = 4483362458
        })
    end
end

-- V13 Fullbright Toggle
function LightingEngine.ToggleFullbright(enabled)
    HubState.Visuals.FullbrightActive = enabled
    CapturePristineBaseline()
    ReconcileLighting()

    if UIToggleElements.Fullbright and UIToggleElements.Fullbright.Set then
        pcall(function()
            UIToggleElements.Fullbright:Set(enabled)
        end)
    end
end

-- V13 NoFog Toggle
function LightingEngine.ToggleNoFog(enabled)
    HubState.Visuals.NoFogActive = enabled
    CapturePristineBaseline()
    ReconcileLighting()

    if UIToggleElements.NoFog and UIToggleElements.NoFog.Set then
        pcall(function()
            UIToggleElements.NoFog:Set(enabled)
        end)
    end
end

-- Fine adjustments
function LightingEngine.SetBlurAA(size)
    HubState.Visuals.BlurAA = size
    for _, inst in ipairs(ActiveShaderInstances) do
        if inst:IsA("BlurEffect") and inst.Name == "GoHub_ShaderBlur" then
            inst.Size = size
        end
    end
end

function LightingEngine.SetBloomIntensity(val)
    HubState.Visuals.BloomIntensity = val
    for _, inst in ipairs(ActiveShaderInstances) do
        if inst:IsA("BloomEffect") and inst.Name == "GoHub_ShaderBloom" then
            inst.Intensity = val
        end
    end
end

-- Geodesic shortest-arc transition helper
function LightingEngine.SetClockTimeShortestArc(targetTime, duration)
    if not Lighting then
        return
    end
    local dur = duration or 1.5
    local elapsed = 0.0
    local startTime = Lighting.ClockTime

    RegisterLoop("ClockTime_Transition", RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        local alpha = math.clamp(elapsed / dur, 0.0, 1.0)
        local step = 24.0 * (dt / dur)
        Lighting.ClockTime = ShortestArcClockTime(Lighting.ClockTime, targetTime, step)
        if alpha >= 1.0 or Lighting.ClockTime == (targetTime % 24.0) then
            Lighting.ClockTime = targetTime % 24.0
            DropLoop("ClockTime_Transition")
        end
    end))
end

-- Exported references on LightingEngine table
LightingEngine.CapturePristineBaseline = CapturePristineBaseline
LightingEngine.ReconcileLighting = ReconcileLighting
LightingEngine.PristineBaseline = PristineBaseline
LightingEngine.ShaderPresets = ShaderPresets
LightingEngine.ShortestArcClockTime = ShortestArcClockTime
LightingEngine.ExponentialSmoothing = ExponentialSmoothing
LightingEngine.VisualsEngine = VisualsEngine
LightingEngine.CombatEngine = CombatEngine

-- ------------------------------------------------------------------------------
-- 14. COMMAND BAR DISPATCHER (;shader, ;rtx, ;fullbright, ;nofog, ;xray, ;aimbot)
-- ------------------------------------------------------------------------------
local function DispatchShaderCommand(cmdText)
    if type(cmdText) ~= "string" then
        return false
    end
    local clean = cmdText:lower():match("^%s*(.-)%s*$")
    if not clean or clean == "" then
        return false
    end

    if clean:sub(1, 1) == ";" or clean:sub(1, 1) == ":" or clean:sub(1, 1) == "/" then
        clean = clean:sub(2)
    end

    local tokens = {}
    for w in clean:gmatch("%S+") do
        table.insert(tokens, w)
    end
    if #tokens == 0 then
        return false
    end

    local cmd = tokens[1]
    local arg1 = tokens[2]

    if cmd == "shader" or cmd == "rtx" or cmd == "shaders" then
        if arg1 == "on" or arg1 == "1" or arg1 == "true" then
            LightingEngine.ToggleShader(true)
        elseif arg1 == "off" or arg1 == "0" or arg1 == "false" then
            LightingEngine.ToggleShader(false)
        else
            LightingEngine.ToggleShader(not HubState.Visuals.ShaderActive)
        end
        return true
    elseif cmd == "fullbright" or cmd == "fb" then
        if arg1 == "off" or arg1 == "0" or arg1 == "false" then
            LightingEngine.ToggleFullbright(false)
        else
            LightingEngine.ToggleFullbright(true)
        end
        return true
    elseif cmd == "unfullbright" or cmd == "unfb" then
        LightingEngine.ToggleFullbright(false)
        return true
    elseif cmd == "nofog" or cmd == "fogless" then
        if arg1 == "off" or arg1 == "0" or arg1 == "false" then
            LightingEngine.ToggleNoFog(false)
        else
            LightingEngine.ToggleNoFog(true)
        end
        return true
    elseif cmd == "unfog" or cmd == "fog" then
        LightingEngine.ToggleNoFog(false)
        return true
    elseif cmd == "xray" or cmd == "x-ray" then
        if arg1 == "off" or arg1 == "0" or arg1 == "false" then
            VisualsEngine.ToggleXRay(false)
        else
            VisualsEngine.ToggleXRay(true)
        end
        return true
    elseif cmd == "unxray" then
        VisualsEngine.ToggleXRay(false)
        return true
    elseif cmd == "esp" or cmd == "chams" then
        if arg1 == "off" or arg1 == "0" or arg1 == "false" then
            VisualsEngine.ToggleUniversalESP(false)
        else
            VisualsEngine.ToggleUniversalESP(true)
        end
        return true
    elseif cmd == "unesp" or cmd == "unchams" then
        VisualsEngine.ToggleUniversalESP(false)
        return true
    elseif cmd == "aimbot" then
        if arg1 == "off" or arg1 == "0" or arg1 == "false" then
            CombatEngine.ToggleAimbot(false)
        else
            CombatEngine.ToggleAimbot(true)
        end
        return true
    elseif cmd == "unaimbot" then
        CombatEngine.ToggleAimbot(false)
        return true
    elseif cmd == "preset" then
        if arg1 then
            LightingEngine.ApplyPreset(arg1)
        end
        return true
    elseif cmd == "dof" then
        if arg1 == "off" or arg1 == "0" or arg1 == "false" then
            LightingEngine.SetAutofocusDoF(false)
        else
            LightingEngine.SetAutofocusDoF(true)
        end
        return true
    elseif cmd == "motionblur" or cmd == "mblur" then
        if arg1 == "off" or arg1 == "0" or arg1 == "false" then
            LightingEngine.SetMotionBlur(false)
        else
            LightingEngine.SetMotionBlur(true)
        end
        return true
    elseif cmd == "timecycle" or cmd == "daynight" then
        if arg1 == "off" or arg1 == "0" or arg1 == "false" then
            LightingEngine.SetTimeCycle(false)
        else
            LightingEngine.SetTimeCycle(true)
        end
        return true
    elseif cmd == "motes" or cmd == "dust" then
        if arg1 == "off" or arg1 == "0" or arg1 == "false" then
            LightingEngine.SetParticleMotesEnabled(false)
        else
            LightingEngine.SetParticleMotesEnabled(true)
        end
        return true
    end

    return false
end

-- ------------------------------------------------------------------------------
-- 15. RAYFIELD V3 UI BUILDER (ABA 'VISUAIS')
-- ------------------------------------------------------------------------------
local function BuildVisualsTab(WindowOrRayfield)
    if not WindowOrRayfield then
        return nil
    end

    local Window = WindowOrRayfield.Tabs and WindowOrRayfield or WindowOrRayfield.CurrentWindow or WindowOrRayfield
    local Tab = nil
    if Window.Tabs and Window.Tabs["Visuais"] then
        Tab = Window.Tabs["Visuais"]
    elseif Window.CreateTab then
        Tab = Window:CreateTab("Visuais", 4483362458)
    end
    if not Tab then
        return nil
    end

    -- SECTION 1: SHADERS & PRESETS CINEMÁTICOS (FEATURES 12, 13, 14, 15, 16)
    Tab:CreateSection("Shaders & Presets Cinemáticos 2.0")

    UIToggleElements.Shader = Tab:CreateToggle({
        Name = "Ativar Shaders Cinemáticos",
        CurrentValue = HubState.Visuals.ShaderActive,
        Flag = "GoHub_Shader_MasterToggle",
        Callback = function(Value)
            LightingEngine.ToggleShader(Value)
        end
    })

    UIToggleElements.PresetDropdown = Tab:CreateDropdown({
        Name = "Preset Cinemático",
        Options = {"Cyberpunk Neon", "Sunset Noir", "VHS Retro", "Midnight Glow", "Golden Hour"},
        CurrentOption = {HubState.Visuals.ShaderPreset or "Golden Hour"},
        Flag = "GoHub_Shader_PresetSelect",
        Callback = function(Option)
            local chosen = type(Option) == "table" and Option[1] or Option
            LightingEngine.ApplyPreset(chosen)
        end
    })

    UIToggleElements.AutofocusDoF = Tab:CreateToggle({
        Name = "Dynamic Autofocus Depth of Field (DoF)",
        CurrentValue = HubState.Lighting.autofocus_dof or HubState.Visuals.AutofocusDoF or false,
        Flag = "GoHub_Shader_AutofocusDoF",
        Callback = function(Value)
            LightingEngine.SetAutofocusDoF(Value)
        end
    })

    UIToggleElements.MotionBlur = Tab:CreateToggle({
        Name = "Dynamic Motion Blur (Angular Delta)",
        CurrentValue = HubState.Lighting.motion_blur or HubState.Visuals.MotionBlur or false,
        Flag = "GoHub_Shader_MotionBlur",
        Callback = function(Value)
            LightingEngine.SetMotionBlur(Value)
        end
    })

    UIToggleElements.DayNight = Tab:CreateToggle({
        Name = "Ciclo Dia/Noite (Geodésico)",
        CurrentValue = HubState.Lighting.day_night or HubState.Visuals.DayNightCycle or false,
        Flag = "GoHub_Shader_DayNightCycle",
        Callback = function(Value)
            LightingEngine.SetTimeCycle(Value)
        end
    })

    Tab:CreateSlider({
        Name = "Velocidade do Ciclo Dia/Noite",
        Range = {0.1, 10.0},
        Increment = 0.1,
        Suffix = "x",
        CurrentValue = HubState.Lighting.time_speed or 1.0,
        Flag = "GoHub_Shader_TimeSpeed",
        Callback = function(Value)
            HubState.Lighting.time_speed = Value
            HubState.Visuals.TimeSpeed = Value
        end
    })

    UIToggleElements.ParticleMotes = Tab:CreateToggle({
        Name = "Partículas Atmosféricas (Motes)",
        CurrentValue = HubState.Lighting.motes or HubState.Visuals.ParticleMotes or false,
        Flag = "GoHub_Shader_ParticleMotes",
        Callback = function(Value)
            LightingEngine.SetParticleMotesEnabled(Value)
        end
    })

    UIToggleElements.Fullbright = Tab:CreateToggle({
        Name = "Fullbright",
        CurrentValue = HubState.Visuals.FullbrightActive,
        Flag = "GoHub_Fullbright",
        Callback = function(Value)
            LightingEngine.ToggleFullbright(Value)
        end
    })

    UIToggleElements.NoFog = Tab:CreateToggle({
        Name = "NoFog",
        CurrentValue = HubState.Visuals.NoFogActive,
        Flag = "GoHub_NoFog",
        Callback = function(Value)
            LightingEngine.ToggleNoFog(Value)
        end
    })

    Tab:CreateSlider({
        Name = "Suavização Anti-Aliasing (Blur)",
        Range = {0, 15},
        Increment = 1,
        Suffix = "px",
        CurrentValue = HubState.Visuals.BlurAA or 5,
        Flag = "GoHub_Shader_Blur",
        Callback = function(Value)
            LightingEngine.SetBlurAA(Value)
        end
    })

    Tab:CreateSlider({
        Name = "Intensidade do Bloom",
        Range = {0, 1},
        Increment = 0.05,
        Suffix = "",
        CurrentValue = HubState.Visuals.BloomIntensity or 0.3,
        Flag = "GoHub_Shader_Bloom",
        Callback = function(Value)
            LightingEngine.SetBloomIntensity(Value)
        end
    })

    -- SECTION 2: VISUAIS & RENDERIZAÇÃO
    Tab:CreateSection("Visuals & Renderização")

    UIToggleElements.XRay = Tab:CreateToggle({
        Name = "X-Ray",
        CurrentValue = HubState.Visuals.XRayActive,
        Flag = "GoHub_XRay",
        Callback = function(Value)
            VisualsEngine.ToggleXRay(Value)
        end
    })

    UIToggleElements.UniversalESP = Tab:CreateToggle({
        Name = "Chams Universal ESP",
        CurrentValue = HubState.Visuals.UniversalESP,
        Flag = "GoHub_ChamsUniversal",
        Callback = function(Value)
            VisualsEngine.ToggleUniversalESP(Value)
        end
    })

    -- SECTION 3: CONTROLES DO AIMBOT
    Tab:CreateSection("Controles do Aimbot")

    UIToggleElements.Aimbot = Tab:CreateToggle({
        Name = "Ativar Aimbot",
        CurrentValue = HubState.Combat.AimbotActive,
        Flag = "GoHub_Aimbot_Active",
        Callback = function(Value)
            CombatEngine.ToggleAimbot(Value)
        end
    })

    UIToggleElements.VisCheck = Tab:CreateToggle({
        Name = "Visibility Check (Raycast)",
        CurrentValue = HubState.Combat.VisibilityCheck,
        Flag = "GoHub_Aimbot_VisCheck",
        Callback = function(Value)
            CombatEngine.ToggleVisibilityCheck(Value)
        end
    })

    UIToggleElements.FOVSlider = Tab:CreateSlider({
        Name = "Raio FOV",
        Range = {20, 500},
        Increment = 5,
        Suffix = "px",
        CurrentValue = HubState.Combat.FOV or 120,
        Flag = "GoHub_Aimbot_FOV",
        Callback = function(Value)
            CombatEngine.SetFOV(Value)
        end
    })

    UIToggleElements.FOVCircle = Tab:CreateToggle({
        Name = "Exibir Círculo FOV",
        CurrentValue = HubState.Combat.FOVCircleVisible,
        Flag = "GoHub_Aimbot_FOVCircle",
        Callback = function(Value)
            CombatEngine.ToggleFOVCircle(Value)
        end
    })

    return Tab
end

-- ------------------------------------------------------------------------------
-- 16. EXPORTAÇÕES GLOBAIS E STANDALONE
-- ------------------------------------------------------------------------------
local ExportedModule = {
    LightingEngine = LightingEngine,
    VisualsEngine = VisualsEngine,
    CombatEngine = CombatEngine,
    BuildVisualsTab = BuildVisualsTab,
    DispatchCommand = DispatchShaderCommand,
    CapturePristineBaseline = CapturePristineBaseline,
    ReconcileLighting = ReconcileLighting,
    PristineBaseline = PristineBaseline,
    ShaderPresets = ShaderPresets
}

-- Bind sub-tables onto LightingEngine for direct call compatibility
LightingEngine.BuildVisualsTab = BuildVisualsTab
LightingEngine.DispatchCommand = DispatchShaderCommand

-- Global exports
if getgenv then
    getgenv().GoHubV14Lighting = LightingEngine
    getgenv().GoHub_ShaderEngine = ExportedModule
else
    _G.GoHubV14Lighting = LightingEngine
    _G.GoHub_ShaderEngine = ExportedModule
end

if shared then
    shared.GoHubV14Lighting = LightingEngine
    shared.GoHub_ShaderEngine = ExportedModule
end

-- [Module Return] return LightingEngine
end

-- 4. ADVANCED MOVEMENT & ROUTE MACROS (Milestone 4)
do
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

-- [Module Return] return exportTable
end

-- 5. UI/UX 2.0, MM2 SUITE 2.0 & PHYSICS TROLLING (Milestone 5)
do
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
            
            -- Role color
            if MM2Engine.Roles.Murderer == p then
                blip.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
            elseif MM2Engine.Roles.Sheriff == p or MM2Engine.Roles.Hero == p then
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

-- Export APIs
GameTrollingModule.DockEngine = DockEngine
GameTrollingModule.TelemetryEngine = TelemetryEngine
GameTrollingModule.CrosshairEngine = CrosshairEngine
GameTrollingModule.MM2Engine = MM2Engine
GameTrollingModule.TrollingEngine = TrollingEngine

rawset(_G, "GoHubV14GameTrolling", GameTrollingModule)
rawset(shared, "GoHubV14GameTrolling", GameTrollingModule)

-- [Module Return] return GameTrollingModule
end

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
                        local newHl = (HubState.AcquireHighlight and HubState.AcquireHighlight(p.Character, 1, HubState.Theme.Accent or Color3.fromRGB(148, 0, 211), Color3.fromRGB(255, 255, 255))) or (_G.HighlightPool and _G.HighlightPool.AcquireHighlight and _G.HighlightPool.AcquireHighlight(p.Character, 1, HubState.Theme.Accent or Color3.fromRGB(148, 0, 211), Color3.fromRGB(255, 255, 255)))
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
                local hl = (HubState.AcquireHighlight and HubState.AcquireHighlight(obj, 3, Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255))) or (_G.HighlightPool and _G.HighlightPool.AcquireHighlight and _G.HighlightPool.AcquireHighlight(obj, 3, Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 255)))
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

-- CARREGAMENTO RESILIENTE DA RAYFIELD UI (V14 DEFINITIVE)

-- ====================================================================
local Rayfield = nil

local function SafeNotify(config)
    if Rayfield and typeof(Rayfield.Notify) == "function" then
        pcall(function() Rayfield:Notify(config) end)
    end
end

local function LoadRayfieldLibrary()
    local sources = {
        'https://sirius.menu/rayfield',
        'https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua',
        'https://raw.githubusercontent.com/shlexware/Rayfield/main/source'
    }
    for _, url in ipairs(sources) do
        local ok, lib = pcall(function()
            local str = nil
            pcall(function() str = game:HttpGet(url, true) end)
            if not str or #str == 0 then
                pcall(function() str = game:HttpGet(url) end)
            end
            if (not str or #str == 0) and typeof(request) == "function" then
                pcall(function()
                    local res = request({Url = url, Method = "GET"})
                    if res and res.Body then str = res.Body end
                end)
            end
            if (not str or #str == 0) and typeof(http_request) == "function" then
                pcall(function()
                    local res = http_request({Url = url, Method = "GET"})
                    if res and res.Body then str = res.Body end
                end)
            end
            if str and #str > 0 and typeof(loadstring) == "function" then
                local fn = loadstring(str)
                if typeof(fn) == "function" then
                    return fn()
                end
            end
            return nil
        end)
        if ok and lib and type(lib) == "table" and lib.CreateWindow then
            rawset(_G, "Rayfield", lib)
            rawset(shared, "Rayfield", lib)
            return lib
        end
    end
    return nil
end

Rayfield = LoadRayfieldLibrary()
if not Rayfield then
    warn("[GoHub V14] Falha crítica: não foi possível carregar a biblioteca Rayfield.")
    pcall(function()
        local sg = game:GetService("StarterGui")
        if sg and typeof(sg.SetCore) == "function" then
            sg:SetCore("SendNotification", {
                Title = "GoHub V14 — Erro de Rede",
                Text = "Não foi possível carregar a Rayfield UI via CDN. Verifique seu executor ou conexão.",
                Duration = 8
            })
        end
    end)
    return
end

local themeSavePath = "GoHubV14/SelectedTheme.txt"

local function SaveTheme(themeName)
    pcall(function()
        if typeof(writefile) == "function" then
            if typeof(isfolder) == "function" and not isfolder("GoHubV14") then
                if typeof(makefolder) == "function" then makefolder("GoHubV14") end
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
    Name = "GoHub V14 — Definitive Universal Suite",
    Icon = 135247969077372,
    LoadingTitle = "GoHub V14",
    LoadingSubtitle = "por dj (Universal Suite & Audio Engine)",
    Theme = initialTheme,
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GoHubV14",
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

TabUniversal:CreateSection("Movimentacao Avancada 2.0 (V14)")

TabUniversal:CreateToggle({
    Name = "Spider / Wall Climb (Escalar Paredes)",
    CurrentValue = false,
    Flag = "univ_wall_climb_toggle",
    Callback = function(Value)
        if _G.GoHubV14Movement and _G.GoHubV14Movement.Movement then
            _G.GoHubV14Movement.Movement.SetWallClimb(Value)
        end
    end,
})

TabUniversal:CreateToggle({
    Name = "Grappling Hook Duplo (Gancho Fisico)",
    CurrentValue = false,
    Flag = "univ_grapple_toggle",
    Callback = function(Value)
        if _G.GoHubV14Movement and _G.GoHubV14Movement.Movement then
            if Value then
                _G.GoHubV14Movement.Movement.FireGrapple()
            else
                _G.GoHubV14Movement.Movement.CancelGrapple()
            end
        end
    end,
})

TabUniversal:CreateToggle({
    Name = "Bhop Strafe (AirAccelerate estilo Source)",
    CurrentValue = false,
    Flag = "univ_bhop_toggle",
    Callback = function(Value)
        if _G.GoHubV14Movement and _G.GoHubV14Movement.Movement then
            _G.GoHubV14Movement.Movement.SetBhop(Value)
        end
    end,
})

TabUniversal:CreateButton({
    Name = "Dash Omnidirecional (Impulso com Rastros)",
    Callback = function()
        if _G.GoHubV14Movement and _G.GoHubV14Movement.Movement then
            _G.GoHubV14Movement.Movement.PerformDash()
        end
    end,
})

TabUniversal:CreateToggle({
    Name = "Super Pulo Procedural",
    CurrentValue = false,
    Flag = "univ_super_jump_toggle",
    Callback = function(Value)
        if _G.GoHubV14Movement and _G.GoHubV14Movement.Movement then
            _G.GoHubV14Movement.Movement.SetSuperJump(Value)
        end
    end,
})

TabUniversal:CreateSection("Automacao & Coleta Universal (V14)")

TabUniversal:CreateToggle({
    Name = "Coleta Automatica Universal (Moedas, Gemas, Tokens)",
    CurrentValue = false,
    Flag = "univ_auto_collect_toggle",
    Callback = function(Value)
        if _G.GoHubV14Movement and _G.GoHubV14Movement.Collector then
            _G.GoHubV14Movement.Collector.SetAutoCollect(Value)
        end
    end,
})

TabUniversal:CreateSection("Interface Flutuante & HUD Tatico (V14)")

TabUniversal:CreateToggle({
    Name = "Dock Flutuante Movel (Capsula Retratil)",
    CurrentValue = false,
    Flag = "univ_capsule_dock_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.DockEngine then
            _G.GoHubV14GameTrolling.DockEngine.Toggle(Value)
        end
    end,
})

TabUniversal:CreateToggle({
    Name = "HUD de Telemetria (FPS 1% Lows, Ping ms, Mem MB)",
    CurrentValue = false,
    Flag = "univ_telemetry_hud_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.TelemetryEngine then
            _G.GoHubV14GameTrolling.TelemetryEngine.Toggle(Value)
        end
    end,
})

TabUniversal:CreateToggle({
    Name = "Mira Dinamica (Crosshair & Hitmarkers)",
    CurrentValue = false,
    Flag = "univ_crosshair_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.CrosshairEngine then
            _G.GoHubV14GameTrolling.CrosshairEngine.Toggle(Value)
        end
    end,
})

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

TabPlayers:CreateSection("Trolling & Fisicas Especiais 2.0 (V14)")

TabPlayers:CreateToggle({
    Name = "Vortex / Buraco Negro Fling (Disco de Acrecao)",
    CurrentValue = false,
    Flag = "players_vortex_fling_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.TrollingEngine then
            if Value then
                _G.GoHubV14GameTrolling.TrollingEngine.StartVortexFling(HubState.SelectedPlayer)
            else
                _G.GoHubV14GameTrolling.TrollingEngine.StopVortexFling()
            end
        end
    end,
})

TabPlayers:CreateToggle({
    Name = "Morte Falsa Reversivel (Ragdoll Fisico)",
    CurrentValue = false,
    Flag = "players_fake_death_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.TrollingEngine then
            _G.GoHubV14GameTrolling.TrollingEngine.ToggleFakeDeath(Value)
        end
    end,
})

TabPlayers:CreateToggle({
    Name = "Carro Invisivel & Aura de Rapto",
    CurrentValue = false,
    Flag = "players_kidnap_aura_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.TrollingEngine then
            _G.GoHubV14GameTrolling.TrollingEngine.ToggleKidnapAura(Value)
        end
    end,
})

TabPlayers:CreateButton({
    Name = "Criar Clone Decoy em Fuga (Furtividade)",
    Callback = function()
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.TrollingEngine then
            _G.GoHubV14GameTrolling.TrollingEngine.SpawnDecoy()
            SafeNotify({
                Title = "Decoy Ativado",
                Content = "Clone decoy enviado e jogador camuflado por 8 segundos.",
                Duration = 4,
            })
        end
    end,
})

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

-- ==============================================================================
-- TAB: AUDIO & MUSIC ENGINE 2.0 (R1 PRIORITIZADO)
-- ==============================================================================
local TabAudio = Window:CreateTab("Audio & Visualizer", nil)

TabAudio:CreateSection("Controles de Reproducao")

TabAudio:CreateButton({
    Name = "▶ Tocar / Retomar Musica",
    Callback = function()
        if _G.GoHubV14Audio and _G.GoHubV14Audio.Resume then
            _G.GoHubV14Audio.Resume()
            local cur = _G.GoHubV14Audio.GetCurrentTrack and _G.GoHubV14Audio.GetCurrentTrack()
            if cur then
                SafeNotify({
                    Title = "Tocando Musica",
                    Content = tostring(cur.Title) .. " - " .. tostring(cur.Artist),
                    Duration = 3,
                })
            end
        end
    end,
})

TabAudio:CreateButton({
    Name = "⏸ Pausar Musica",
    Callback = function()
        if _G.GoHubV14Audio and _G.GoHubV14Audio.Pause then
            _G.GoHubV14Audio.Pause()
            SafeNotify({
                Title = "Musica Pausada",
                Content = "Reproducao pausada.",
                Duration = 2,
            })
        end
    end,
})

TabAudio:CreateButton({
    Name = "⏹ Parar Musica (Stop)",
    Callback = function()
        if _G.GoHubV14Audio and _G.GoHubV14Audio.Stop then
            _G.GoHubV14Audio.Stop()
            SafeNotify({
                Title = "Musica Parada",
                Content = "Audio descarregado.",
                Duration = 2,
            })
        end
    end,
})

TabAudio:CreateButton({
    Name = "⏭ Proxima Faixa >>",
    Callback = function()
        if _G.GoHubV14Audio and _G.GoHubV14Audio.NextTrack then
            _G.GoHubV14Audio.NextTrack()
            local cur = _G.GoHubV14Audio.GetCurrentTrack and _G.GoHubV14Audio.GetCurrentTrack()
            if cur then
                SafeNotify({
                    Title = "Proxima Faixa",
                    Content = tostring(cur.Title) .. " - " .. tostring(cur.Artist),
                    Duration = 3,
                })
            end
        end
    end,
})

TabAudio:CreateButton({
    Name = "⏮ << Faixa Anterior",
    Callback = function()
        if _G.GoHubV14Audio and _G.GoHubV14Audio.PreviousTrack then
            _G.GoHubV14Audio.PreviousTrack()
            local cur = _G.GoHubV14Audio.GetCurrentTrack and _G.GoHubV14Audio.GetCurrentTrack()
            if cur then
                SafeNotify({
                    Title = "Faixa Anterior",
                    Content = tostring(cur.Title) .. " - " .. tostring(cur.Artist),
                    Duration = 3,
                })
            end
        end
    end,
})

TabAudio:CreateSection("Musica & Playlist BGM")

TabAudio:CreateDropdown({
    Name = "Faixa Musical (BGM Playlist)",
    Options = {
        "1. Vaporwave Synth Beat",
        "2. Phonk Action Drift",
        "3. Lofi Hip Hop Study",
        "4. Electro House Pulse",
        "5. Future Bass Energy",
        "6. Cyberpunk Neon Drive",
        "7. Hyperpop Overdrive",
        "8. Midnight Ambient Chill",
        "9. Classic Chill Beats",
        "10. Brazilian Phonk Extreme"
    },
    CurrentOption = {"1. Vaporwave Synth Beat"},
    Flag = "audio_bgm_track_dropdown",
    Callback = function(Option)
        local track = Option[1] or Option
        local tid = tonumber(tostring(track):match("^(%d+)")) or 1
        if _G.GoHubV14Audio and _G.GoHubV14Audio.PlayTrack then
            _G.GoHubV14Audio.PlayTrack(tid)
        end
    end,
})

TabAudio:CreateInput({
    Name = "Custom Audio ID",
    PlaceholderText = "Cole o ID de som da Roblox...",
    RemoveTextAfterFocusLost = false,
    Flag = "audio_custom_id_input",
    Callback = function(Text)
        local id = tonumber(Text)
        if HubState.Audio then HubState.Audio.CustomID = id end
        if id and _G.GoHubV14Audio and _G.GoHubV14Audio.PlayTrack then
            _G.GoHubV14Audio.PlayTrack(id)
        end
    end,
})

TabAudio:CreateButton({
    Name = "▶ Tocar ID Customizado Inserido",
    Callback = function()
        local id = tonumber(HubState.Audio and HubState.Audio.CustomID)
        if id and _G.GoHubV14Audio and _G.GoHubV14Audio.PlayTrack then
            _G.GoHubV14Audio.PlayTrack(id)
            SafeNotify({
                Title = "Audio Customizado",
                Content = "Tocando ID: " .. tostring(id),
                Duration = 3,
            })
        else
            SafeNotify({
                Title = "Aviso",
                Content = "Insira um ID valido no campo acima.",
                Duration = 3,
            })
        end
    end,
})

TabAudio:CreateSlider({
    Name = "Volume da Musica",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 50,
    Flag = "audio_volume_slider",
    Callback = function(Value)
        if _G.GoHubV14Audio and _G.GoHubV14Audio.SetVolume then
            _G.GoHubV14Audio.SetVolume(Value / 100)
        end
    end,
})

TabAudio:CreateSlider({
    Name = "Velocidade / Pitch",
    Range = {50, 200},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "audio_speed_slider",
    Callback = function(Value)
        if _G.GoHubV14Audio and _G.GoHubV14Audio.SetSpeed then
            _G.GoHubV14Audio.SetSpeed(Value / 100)
        end
    end,
})

TabAudio:CreateDropdown({
    Name = "Modo de Repeticao",
    Options = {"Sequencial", "Repetir Faixa", "Aleatorio"},
    CurrentOption = {"Sequencial"},
    Flag = "audio_loop_mode_dropdown",
    Callback = function(Option)
        local mode = Option[1] or Option
        if _G.GoHubV14Audio and _G.GoHubV14Audio.SetLoopMode then
            _G.GoHubV14Audio.SetLoopMode(mode)
        end
    end,
})

TabAudio:CreateSection("DSP Equalizer (Bass Boost)")

TabAudio:CreateToggle({
    Name = "Ativar Bass Boost",
    CurrentValue = false,
    Flag = "audio_bass_boost_toggle",
    Callback = function(Value)
        if _G.GoHubV14Audio and _G.GoHubV14Audio.SetBassBoost then
            _G.GoHubV14Audio.SetBassBoost(Value, 12.0)
        end
    end,
})

TabAudio:CreateSlider({
    Name = "Potencia dos Graves (dB)",
    Range = {0, 20},
    Increment = 1,
    Suffix = " dB",
    CurrentValue = 10,
    Flag = "audio_bass_db_slider",
    Callback = function(Value)
        if _G.GoHubV14Audio and _G.GoHubV14Audio.SetBassBoost then
            _G.GoHubV14Audio.SetBassBoost(true, Value)
        end
    end,
})

TabAudio:CreateDropdown({
    Name = "Preset DSP",
    Options = {"Flat", "Bass Boost Standard", "Bass Boost Heavy", "Extreme Bass", "Nightcore", "Vaporwave"},
    CurrentOption = {"Bass Boost Standard"},
    Flag = "audio_dsp_preset_dropdown",
    Callback = function(Option)
        local preset = Option[1] or Option
        if _G.GoHubV14Audio and _G.GoHubV14Audio.ApplyDSPPreset then
            _G.GoHubV14Audio.ApplyDSPPreset(preset)
        end
    end,
})

TabAudio:CreateSection("Efeitos Visuais de Audio (Visualizers)")

TabAudio:CreateToggle({
    Name = "Visualizador Neon 3D no Avatar (Anel Orbital + Particulas)",
    CurrentValue = false,
    Flag = "audio_vis_3d_toggle",
    Callback = function(Value)
        if _G.GoHubV14Audio and _G.GoHubV14Audio.ToggleVisualizer3D then
            _G.GoHubV14Audio.ToggleVisualizer3D(Value)
        end
    end,
})

TabAudio:CreateToggle({
    Name = "Ondas de Choque no Chao (Floor Beat-Drop Shockwaves)",
    CurrentValue = false,
    Flag = "audio_shockwave_toggle",
    Callback = function(Value)
        if _G.GoHubV14Audio and _G.GoHubV14Audio.ToggleShockwaves then
            _G.GoHubV14Audio.ToggleShockwaves(Value)
        end
    end,
})

TabAudio:CreateToggle({
    Name = "HUD Equalizador de Espectro 2D na Tela",
    CurrentValue = false,
    Flag = "audio_spectrum_hud_toggle",
    Callback = function(Value)
        if _G.GoHubV14Audio and _G.GoHubV14Audio.ToggleEqualizerHUD then
            _G.GoHubV14Audio.ToggleEqualizerHUD(Value)
        end
    end,
})

TabAudio:CreateSection("Feedback Sonoro Tatico (SFX)")

TabAudio:CreateToggle({
    Name = "Sons de Interface (Cliques & Toggles com Jitter)",
    CurrentValue = true,
    Flag = "audio_sfx_ui_toggle",
    Callback = function(Value)
        if HubState.Audio then HubState.Audio.UISFX = Value end
    end,
})

TabAudio:CreateToggle({
    Name = "Som de Hitmarker",
    CurrentValue = true,
    Flag = "audio_sfx_hitmarker_toggle",
    Callback = function(Value)
        if HubState.Audio then HubState.Audio.HitmarkerSFX = Value end
    end,
})

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


TabMM2:CreateSection("Combate Tatico MM2 2.0 (V14)")

TabMM2:CreateToggle({
    Name = "Auto-Shoot Balistico Interceptador (Compensacao de Ping)",
    CurrentValue = false,
    Flag = "mm2_ballistic_autoshoot_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.MM2Engine then
            _G.GoHubV14GameTrolling.MM2Engine.AutoShoot(Value)
        end
    end,
})

TabMM2:CreateToggle({
    Name = "Radar Minimapa 2D na Tela",
    CurrentValue = false,
    Flag = "mm2_minimap_radar_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.MM2Engine then
            _G.GoHubV14GameTrolling.MM2Engine.ToggleRadar(Value)
        end
    end,
})

TabMM2:CreateToggle({
    Name = "Alerta de Mira & Espectadores (Stare HUD)",
    CurrentValue = false,
    Flag = "mm2_stare_hud_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.MM2Engine then
            _G.GoHubV14GameTrolling.MM2Engine.ToggleStareHUD(Value)
        end
    end,
})

TabMM2:CreateToggle({
    Name = "Auto-Dodge de Facas Arremessadas",
    CurrentValue = false,
    Flag = "mm2_knife_autododge_toggle",
    Callback = function(Value)
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.MM2Engine then
            _G.GoHubV14GameTrolling.MM2Engine.ToggleKnifeDodge(Value)
        end
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


TabVisuals:CreateSection("Optica & Pos-Processamento 2.0 (V14)")

TabVisuals:CreateToggle({
    Name = "Autofocus Dinamico Depth of Field (DoF 20Hz)",
    CurrentValue = false,
    Flag = "visuals_autofocus_dof_toggle",
    Callback = function(Value)
        if _G.GoHubV14Lighting and _G.GoHubV14Lighting.SetAutofocusDoF then
            _G.GoHubV14Lighting.SetAutofocusDoF(Value)
        end
    end,
})

TabVisuals:CreateToggle({
    Name = "Motion Blur por Velocidade Angular",
    CurrentValue = false,
    Flag = "visuals_motion_blur_toggle",
    Callback = function(Value)
        if _G.GoHubV14Lighting and _G.GoHubV14Lighting.SetMotionBlur then
            _G.GoHubV14Lighting.SetMotionBlur(Value)
        end
    end,
})

TabVisuals:CreateDropdown({
    Name = "Presets Cinematograficos V14",
    Options = {"Nenhum", "Cyberpunk Neon", "Sunset Noir", "VHS Retro", "Midnight Glow", "Golden Hour"},
    CurrentOption = {"Nenhum"},
    Flag = "visuals_cinematic_presets_dropdown",
    Callback = function(Option)
        local preset = Option[1] or Option
        if _G.GoHubV14Lighting and _G.GoHubV14Lighting.ApplyPreset then
            if preset ~= "Nenhum" then
                _G.GoHubV14Lighting.ApplyPreset(preset)
            else
                _G.GoHubV14Lighting.RestoreBaseline()
            end
        end
    end,
})

TabVisuals:CreateToggle({
    Name = "Ciclo Dia/Noite Geodesico",
    CurrentValue = false,
    Flag = "visuals_day_night_cycle_toggle",
    Callback = function(Value)
        if _G.GoHubV14Lighting and _G.GoHubV14Lighting.SetTimeCycle then
            _G.GoHubV14Lighting.SetTimeCycle(Value)
        end
    end,
})

TabVisuals:CreateToggle({
    Name = "Particulas Atmosfericas (Motes com Deteccao de Teto)",
    CurrentValue = false,
    Flag = "visuals_camera_motes_toggle",
    Callback = function(Value)
        if _G.GoHubV14Lighting and _G.GoHubV14Lighting.SetCameraMotes then
            _G.GoHubV14Lighting.SetCameraMotes(Value)
        end
    end,
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

TabWaypoints:CreateSection("Gravador de Rotas & Macros (V14)")

TabWaypoints:CreateToggle({
    Name = "Gravar Rota ao Vivo (Amostragem Inteligente)",
    CurrentValue = false,
    Flag = "waypoints_record_route_toggle",
    Callback = function(Value)
        if _G.GoHubV14Movement and _G.GoHubV14Movement.Macro then
            if Value then
                _G.GoHubV14Movement.Macro.StartRecording()
            else
                _G.GoHubV14Movement.Macro.StopRecording()
            end
        end
    end,
})

TabWaypoints:CreateToggle({
    Name = "Reproduzir Rota em Loop Continuo",
    CurrentValue = false,
    Flag = "waypoints_playback_route_toggle",
    Callback = function(Value)
        if _G.GoHubV14Movement and _G.GoHubV14Movement.Macro then
            if Value then
                _G.GoHubV14Movement.Macro.StartPlayback()
            else
                _G.GoHubV14Movement.Macro.StopPlayback()
            end
        end
    end,
})

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
    Title = "GoHub V14 Pronto!",
    Content = "Todas as 8 abas e motores sintetizados com sucesso para Rayfield.",
    Duration = 5
})

print("[GoHub V14] Rayfield Synthesis & Background Engine Initialized 100% Successfully.")


-- ==============================================================================
-- RUNTIME UPDATE LOOPS & INITIALIZATION (V14 ENGINES)
-- ==============================================================================
task.spawn(function()
    pcall(function()
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.TelemetryEngine then
            _G.GoHubV14GameTrolling.TelemetryEngine.Init()
        end
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.DockEngine then
            _G.GoHubV14GameTrolling.DockEngine.Init()
        end
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.CrosshairEngine then
            _G.GoHubV14GameTrolling.CrosshairEngine.Init()
        end
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.MM2Engine then
            _G.GoHubV14GameTrolling.MM2Engine.SetupRadar()
        end
    end)
end)

RunService.RenderStepped:Connect(function(dt)
    pcall(function()
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.TelemetryEngine then
            _G.GoHubV14GameTrolling.TelemetryEngine.Update(dt)
        end
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.CrosshairEngine then
            _G.GoHubV14GameTrolling.CrosshairEngine.Update(dt)
        end
        if _G.GoHubV14GameTrolling and _G.GoHubV14GameTrolling.MM2Engine then
            _G.GoHubV14GameTrolling.MM2Engine.UpdateRadar()
        end
        if _G.GoHubV14Movement and _G.GoHubV14Movement.UpdateMovement then
            _G.GoHubV14Movement.UpdateMovement(dt)
        end
        if _G.GoHubV14Lighting and _G.GoHubV14Lighting.UpdateEffects then
            _G.GoHubV14Lighting.UpdateEffects(dt)
        end
    end)
end)
