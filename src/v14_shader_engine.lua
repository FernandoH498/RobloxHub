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

-- Bind sub-tables and aliases onto LightingEngine for direct call compatibility
LightingEngine.BuildVisualsTab = BuildVisualsTab
LightingEngine.DispatchCommand = DispatchShaderCommand
LightingEngine.SetCameraMotes = LightingEngine.SetParticleMotesEnabled

-- Global exports
rawset(_G, "GoHubV14Lighting", LightingEngine)
rawset(shared, "GoHubV14Lighting", LightingEngine)
rawset(_G, "GoHub_ShaderEngine", ExportedModule)
rawset(shared, "GoHub_ShaderEngine", ExportedModule)
if getgenv then
    pcall(function()
        getgenv().GoHubV14Lighting = LightingEngine
        getgenv().GoHub_ShaderEngine = ExportedModule
    end)
end

return LightingEngine
