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
        { Id = 1843588737, Title = "Chill Phonk", Artist = "GoHub Beats", Duration = 120, DefaultVolume = 0.6 },
        { Id = 1843404009, Title = "Vaporwave Beat", Artist = "Synthwave Lab", Duration = 145, DefaultVolume = 0.5 },
        { Id = 1838457617, Title = "Cyberpunk Synthwave", Artist = "Neon Runner", Duration = 160, DefaultVolume = 0.55 },
        { Id = 1848354536, Title = "Lofi Hip Hop Study", Artist = "Chilled Cow", Duration = 130, DefaultVolume = 0.5 },
        { Id = 7028506547, Title = "Hyperpop Drive", Artist = "Glitch Overdrive", Duration = 110, DefaultVolume = 0.45 },
        { Id = 9048375035, Title = "Midnight City Ambient", Artist = "Nightflow", Duration = 175, DefaultVolume = 0.5 },
        { Id = 1845554017, Title = "Future Bass Energy", Artist = "Sub Zero", Duration = 140, DefaultVolume = 0.55 },
        { Id = 5410086218, Title = "Brazilian Phonk Drift", Artist = "Montagem", Duration = 125, DefaultVolume = 0.6 },
        { Id = 130972023, Title = "Retro Arc Laser", Artist = "Classic Roblox", Duration = 90, DefaultVolume = 0.4 },
        { Id = 1841285324, Title = "Electro House Pulse", Artist = "Audio Lab", Duration = 150, DefaultVolume = 0.5 }
    }
}

-- Resolve or create Sound parent container inside SoundService (persists across respawns)
local function getAudioContainer()
    if MusicPlayer.Container and MusicPlayer.Container.Parent then
        return MusicPlayer.Container
    end

    local parent = SoundService or Workspace
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
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.Volume = 0
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

    -- Create new active sound instance
    local newSound = createSoundInstance("GoHub_ActiveTrack_" .. tostring(targetTrack.Id))
    newSound.SoundId = assetString
    newSound.PlaybackSpeed = MusicPlayer.PlaybackSpeed
    newSound.Volume = 0
    attachDSPChain(newSound)

    MusicPlayer.ActiveSound = newSound
    MusicPlayer.IsPlaying = true

    pcall(function() newSound:Play() end)

    if TweenService then
        local inTween = TweenService:Create(newSound, TweenInfo.new(tau, Enum.EasingStyle.Linear), { Volume = targetVolume })
        inTween:Play()
    else
        newSound.Volume = targetVolume
    end

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

return AudioEngine
