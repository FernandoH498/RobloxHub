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
    HighlightPool.Container = guiRoot or Polyfills.GetSafeGuiRoot()

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

return GoHubV14Core
