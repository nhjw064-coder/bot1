local __FREEHUB_LOADED = false
local __FREEHUB_UI_TOGGLE = nil 

local function GetLogoAsset(url)
    local fileName = "zh_logo_final_v9.png"
    local getasset = getcustomasset or getsynasset or (Drawing and Drawing.GetAsset)
    local req = (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or request
    
    if not getasset then return url end
    if isfile and isfile(fileName) then
        local s, r = pcall(function() return getasset(fileName) end)
        if s then return r end
    end
    
    task.spawn(function()
        local data = nil
        pcall(function()
            if req then
                local res = req({Url = url, Method = "GET"})
                if res.Success then data = res.Body end
            else
                data = game:HttpGet(url)
            end
        end)
        if data and #data > 500 and writefile then
            pcall(function() writefile(fileName, data) end)
        end
    end)
    return url
end

local function __LOAD_FREEHUB()
    if __FREEHUB_LOADED then
        if __FREEHUB_UI_TOGGLE then __FREEHUB_UI_TOGGLE(true) end
        return
    end
    __FREEHUB_LOADED = true
    
    task.spawn(function()
        -- [[ FREEHUB INTEGRATED CODE ]] --
if not game:IsLoaded() then game.Loaded:Wait() end

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local TextChatService    = game:GetService("TextChatService")
local Lighting           = game:GetService("Lighting")
local TeleportService    = game:GetService("TeleportService")
local Camera             = workspace.CurrentCamera

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if not getgenv then getgenv = function() return _G end end

local PPS = pcall(function() return cloneref(game:GetService("ProximityPromptService")) end)
    and cloneref(game:GetService("ProximityPromptService"))
    or game:GetService("ProximityPromptService")

pcall(function()
    for _, v in getconnections(PPS.PromptButtonHoldBegan) do v:Disable() end
end)

local CFG_FILE = "ZYRA_HUB_ALL.json"

local Enabled = {
    SpeedBoost         = false,
    AntiRagdoll        = false,
    SpinBot            = false,
    SpeedWhileStealing = false,
    Unwalk             = false,
    Optimizer          = false,
    Galaxy             = false,
    SpamBat            = false,
    BatAimbot          = false,
    GalaxySkyBright    = false,
    AutoWalkEnabled    = false,
    AutoRightEnabled   = false,
    PlayerESP          = false,
    InvClone           = false,
    InstantGrab        = false,
}

local Values = {
    BoostSpeed           = 60,
    SpinSpeed            = 30,
    StealingSpeedValue   = 38,
    DEFAULT_GRAVITY      = 196.2,
    GalaxyGravityPercent = 65,
    HOP_POWER            = 42,
    HOP_COOLDOWN         = 0.055,
}

local KEYBINDS = {
    SPEED     = Enum.KeyCode.V,
    SPIN      = Enum.KeyCode.N,
    GALAXY    = Enum.KeyCode.M,
    BATAIMBOT = Enum.KeyCode.X,
    AUTOLEFT  = Enum.KeyCode.Z,
    AUTORIGHT = Enum.KeyCode.C,
}

pcall(function()
    if readfile and isfile and isfile(CFG_FILE) then
        local d = HttpService:JSONDecode(readfile(CFG_FILE))
        if d then
            for k, v in pairs(d) do
                if Enabled[k] ~= nil then Enabled[k] = v end
                if Values[k]   ~= nil then Values[k]  = v end
            end
            for k in pairs(KEYBINDS) do
                if d["KEY_"..k] then KEYBINDS[k] = Enum.KeyCode[d["KEY_"..k]] end
            end
        end
    end
end)

local function SaveConfig()
    local d = {}
    for k, v in pairs(Enabled)   do d[k] = v end
    for k, v in pairs(Values)    do d[k] = v end
    for k, v in pairs(KEYBINDS)  do d["KEY_"..k] = v.Name end
    if writefile then pcall(function() writefile(CFG_FILE, HttpService:JSONEncode(d)) end) end
end

local function getChar()    return player.Character end
local function getHRP()     local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()     local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getMoveDir() local h = getHum();  return h and h.MoveDirection or Vector3.zero end

local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local instantGrabConn = nil

local function enableInstantGrab()
    if instantGrabConn then return end
    instantGrabConn = PPS.PromptButtonHoldBegan:Connect(function(prompt)
        if prompt.HoldDuration > 0 and prompt:GetAttribute("State") == "Steal" then
            pcall(function() fireproximityprompt(prompt) end)
        end
    end)
end

local function disableInstantGrab()
    if instantGrabConn then instantGrabConn:Disconnect(); instantGrabConn = nil end
end

local speedConn, speedRamp = nil, 0

local function startSpeed()
    if speedConn then return end
    speedRamp = 0
    speedConn = RunService.Heartbeat:Connect(function(dt)
        if not Enabled.SpeedBoost then return end
        pcall(function()
            local hrp = getHRP(); if not hrp then return end
            local md  = getMoveDir()
            local vy  = hrp.AssemblyLinearVelocity.Y
            if md.Magnitude > 0.1 then
                speedRamp = math.min(speedRamp + dt * 7, 1)
                hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(
                    Vector3.new(md.X * Values.BoostSpeed * speedRamp, vy, md.Z * Values.BoostSpeed * speedRamp),
                    math.min(1, dt * 20))
            else
                speedRamp = math.max(speedRamp - dt * 5, 0)
                local hv = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
                if hv.Magnitude > 0.3 then
                    local dec = hv:Lerp(Vector3.zero, math.min(1, dt * 12))
                    hrp.AssemblyLinearVelocity = Vector3.new(dec.X, vy, dec.Z)
                end
            end
        end)
    end)
end

local function stopSpeed()
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    speedRamp = 0
end

local Conns = {}

local function startStealSpeed()
    if Conns.sws then return end
    Conns.sws = RunService.Heartbeat:Connect(function(dt)
        if not Enabled.SpeedWhileStealing or not player:GetAttribute("Stealing") then return end
        pcall(function()
            local hrp = getHRP(); if not hrp then return end
            local md  = getMoveDir(); if md.Magnitude < 0.1 then return end
            local vy  = hrp.AssemblyLinearVelocity.Y
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(
                Vector3.new(md.X * Values.StealingSpeedValue, vy, md.Z * Values.StealingSpeedValue),
                math.min(1, dt * 18))
        end)
    end)
end

local function stopStealSpeed()
    if Conns.sws then Conns.sws:Disconnect(); Conns.sws = nil end
end

local spinBAV = nil

local function startSpin()
    local hrp = getHRP(); if not hrp then return end
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
    for _, v in pairs(hrp:GetChildren()) do if v.Name == "SpinBAV" then v:Destroy() end end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.Name            = "SpinBAV"
    spinBAV.MaxTorque       = Vector3.new(0, math.huge, 0)
    spinBAV.AngularVelocity = Vector3.new(0, Values.SpinSpeed, 0)
    spinBAV.Parent          = hrp
end

local function stopSpin()
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
    local hrp = getHRP()
    if hrp then for _, v in pairs(hrp:GetChildren()) do if v.Name == "SpinBAV" then v:Destroy() end end end
end

RunService.Heartbeat:Connect(function()
    if Enabled.SpinBot and spinBAV then
        spinBAV.AngularVelocity = player:GetAttribute("Stealing")
            and Vector3.zero
            or Vector3.new(0, Values.SpinSpeed, 0)
    end
end)

local lastSwing = 0
local SlapList  = {
    "Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap",
    "Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"
}

local function FindBat()
    local c  = getChar(); if not c then return nil end
    local bp = player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    for _, n in ipairs(SlapList) do
        local t = c:FindFirstChild(n) or (bp and bp:FindFirstChild(n))
        if t then return t end
    end
    return nil
end

local function startSpam()
    if Conns.spam then return end
    Conns.spam = RunService.Heartbeat:Connect(function()
        if not Enabled.SpamBat then return end
        local c   = getChar(); if not c then return end
        local bat = FindBat(); if not bat then return end
        if bat.Parent ~= c then bat.Parent = c end
        local now = tick(); if now - lastSwing < 0.09 then return end
        lastSwing = now
        pcall(function() bat:Activate() end)
    end)
end

local function stopSpam()
    if Conns.spam then Conns.spam:Disconnect(); Conns.spam = nil end
end

local function GetNearestEnemy()
    local hrp = getHRP(); if not hrp then return nil, nil, nil end
    local best, bestD, bestT = nil, math.huge, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local eh  = p.Character:FindFirstChild("HumanoidRootPart")
            local tor = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d; best = eh; bestT = tor or eh end
            end
        end
    end
    return best, bestD, bestT
end

local function startAimbot()
    if Conns.aim then return end
    Conns.aim = RunService.Heartbeat:Connect(function(dt)
        if not Enabled.BatAimbot then return end
        pcall(function()
            local hrp = getHRP(); local hum = getHum(); if not hrp or not hum then return end
            local bat = FindBat()
            if bat and bat.Parent ~= getChar() then hum:EquipTool(bat) end
            local _, _, tor = GetNearestEnemy(); if not tor then return end
            local fd = Vector3.new(tor.Position.X - hrp.Position.X, 0, tor.Position.Z - hrp.Position.Z)
            if fd.Magnitude > 1.5 then
                local u  = fd.Unit
                local vy = hrp.AssemblyLinearVelocity.Y
                hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(
                    Vector3.new(u.X * 62, vy, u.Z * 62), math.min(1, dt * 15))
            end
        end)
    end)
end

local function stopAimbot()
    if Conns.aim then Conns.aim:Disconnect(); Conns.aim = nil end
end

local gForce, gAttach              = nil, nil
local galaxyOn, hopsOn             = false, false
local lastHop, spaceHeld, origJump = 0, false, 50

local function captureJump()
    local h = getHum(); if h and h.JumpPower > 0 then origJump = h.JumpPower end
end
task.delay(1, captureJump)
player.CharacterAdded:Connect(function() task.delay(1, captureJump) end)

local function setupGForce()
    pcall(function()
        local hrp = getHRP(); if not hrp then return end
        if gForce  then gForce:Destroy() end
        if gAttach then gAttach:Destroy() end
        gAttach = Instance.new("Attachment"); gAttach.Parent = hrp
        gForce  = Instance.new("VectorForce")
        gForce.Attachment0         = gAttach
        gForce.ApplyAtCenterOfMass = true
        gForce.RelativeTo          = Enum.ActuatorRelativeTo.World
        gForce.Force               = Vector3.zero
        gForce.Parent              = hrp
    end)
end

local function updateGForce()
    if not galaxyOn or not gForce then return end
    local c = getChar(); if not c then return end
    local mass = 0
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then mass = mass + p:GetMass() end
    end
    local tg = Values.DEFAULT_GRAVITY * (Values.GalaxyGravityPercent / 100)
    gForce.Force = Vector3.new(0, mass * (Values.DEFAULT_GRAVITY - tg) * 0.95, 0)
end

local function fixJump()
    pcall(function()
        local h = getHum(); if not h then return end
        if not galaxyOn then h.JumpPower = origJump; return end
        h.JumpPower = origJump * math.sqrt(
            (Values.DEFAULT_GRAVITY * (Values.GalaxyGravityPercent / 100)) / Values.DEFAULT_GRAVITY)
    end)
end

local function startGalaxy() galaxyOn = true;  hopsOn = true;  setupGForce(); fixJump() end
local function stopGalaxy()
    galaxyOn = false; hopsOn = false
    if gForce  then gForce:Destroy();  gForce  = nil end
    if gAttach then gAttach:Destroy(); gAttach = nil end
    fixJump()
end

RunService.Heartbeat:Connect(function()
    if hopsOn and spaceHeld then
        pcall(function()
            local hrp = getHRP(); local h = getHum(); if not hrp or not h then return end
            if tick() - lastHop < Values.HOP_COOLDOWN then return end
            lastHop = tick()
            if h.FloorMaterial == Enum.Material.Air then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X, Values.HOP_POWER, hrp.AssemblyLinearVelocity.Z)
            end
        end)
    end
    if galaxyOn then updateGForce() end
end)

local function startAnti()
    if Conns.anti then return end
    Conns.anti = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local c   = getChar(); if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local h   = c:FindFirstChildOfClass("Humanoid")
        if h then
            local st = h:GetState()
            if st == Enum.HumanoidStateType.Physics
            or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown then
                h:ChangeState(Enum.HumanoidStateType.Running)
                Camera.CameraSubject = h
                if hrp then
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
        for _, o in ipairs(c:GetDescendants()) do
            if o:IsA("Motor6D") and not o.Enabled then o.Enabled = true end
        end
    end)
end

local function stopAnti()
    if Conns.anti then Conns.anti:Disconnect(); Conns.anti = nil end
end

local savedAnim = {}

local function startUnwalk()
    local c = getChar(); if not c then return end
    local h = getHum()
    if h then for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:Stop() end end
    local a = c:FindFirstChild("Animate")
    if a then savedAnim.A = a:Clone(); a:Destroy() end
end

local function stopUnwalk()
    local c = getChar()
    if c and savedAnim.A then savedAnim.A:Clone().Parent = c; savedAnim.A = nil end
end

local function startOpt()
    if getgenv and getgenv().OPT then return end
    if getgenv then getgenv().OPT = true end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd        = 9e9
    end)
    task.spawn(function()
        local descendants = workspace:GetDescendants()
        for i = 1, #descendants, 50 do
            for j = i, math.min(i + 49, #descendants) do
                pcall(function()
                    local o = descendants[j]
                    if not o or not o.Parent then return end
                    if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") then
                        o:Destroy()
                    elseif o:IsA("BasePart") then
                        o.CastShadow = false
                        o.Material   = Enum.Material.Plastic
                    end
                end)
            end
            task.wait()
        end
    end)
end

local function stopOpt()
    if getgenv then getgenv().OPT = false end
end

local oSky, gSky, gSkyConn, gBloom, gCC = nil, nil, nil, nil, nil

local function startGSky()
    if gSky then return end
    oSky = Lighting:FindFirstChildOfClass("Sky")
    if oSky then oSky.Parent = nil end
    gSky = Instance.new("Sky", Lighting)
    local skyFaces = {"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}
    for i = 1, #skyFaces do
        gSky[skyFaces[i]] = "rbxassetid://1534951537"
    end
    gSky.StarCount            = 10000
    gSky.CelestialBodiesShown = false

    gBloom           = Instance.new("BloomEffect", Lighting)
    gBloom.Intensity = 1.5; gBloom.Size = 40; gBloom.Threshold = 0.8

    gCC            = Instance.new("ColorCorrectionEffect", Lighting)
    gCC.Saturation = 0.8; gCC.Contrast = 0.3
    gCC.TintColor  = Color3.fromRGB(200, 150, 255)

    Lighting.Ambient    = Color3.fromRGB(120, 60, 180)
    Lighting.Brightness = 3
    Lighting.ClockTime  = 0

    gSkyConn = RunService.Heartbeat:Connect(function()
        if not Enabled.GalaxySkyBright then return end
        local t = tick() * 0.5
        Lighting.Ambient = Color3.fromRGB(
            120 + math.sin(t)       * 60,
            50  + math.sin(t * .8)  * 40,
            180 + math.sin(t * 1.2) * 50)
        if gBloom then gBloom.Intensity = 1.2 + math.sin(t * 2) * 0.4 end
    end)
end

local function stopGSky()
    if gSkyConn then gSkyConn:Disconnect(); gSkyConn = nil end
    if gSky     then gSky:Destroy();  gSky   = nil end
    if oSky     then oSky.Parent = Lighting end
    if gBloom   then gBloom:Destroy(); gBloom = nil end
    if gCC      then gCC:Destroy();    gCC    = nil end
    Lighting.Ambient    = Color3.fromRGB(127, 127, 127)
    Lighting.Brightness = 2
    Lighting.ClockTime  = 14
end

local AutoWalkEnabled  = false
local AutoRightEnabled = false

local POS1 = Vector3.new(-476.48, -6.28,  92.73)
local POS2 = Vector3.new(-483.12, -4.95,  94.80)
local PR1  = Vector3.new(-476.16, -6.52,  25.62)
local PR2  = Vector3.new(-483.04, -5.09,  23.14)

local wPhase, rPhase = 1, 1
local wConn,  rConn  = nil, nil
local VisualSetters  = {}

local function walkStep(target, hrp, hum)
    local fd = Vector3.new(target.X - hrp.Position.X, 0, target.Z - hrp.Position.Z)
    if fd.Magnitude < 1 then return true end
    local u = fd.Unit
    hum:Move(u, false)
    hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(
        Vector3.new(u.X * Values.BoostSpeed, hrp.AssemblyLinearVelocity.Y, u.Z * Values.BoostSpeed), 0.25)
    return false
end

local function startAutoWalk()
    if wConn then wConn:Disconnect() end; wPhase = 1
    wConn = RunService.Heartbeat:Connect(function()
        if not AutoWalkEnabled then return end
        local hrp = getHRP(); local hum = getHum(); if not hrp or not hum then return end
        local target = wPhase == 1 and POS1 or POS2
        if walkStep(target, hrp, hum) then
            if wPhase == 1 then
                wPhase = 2
            else
                hum:Move(Vector3.zero, false)
                hrp.AssemblyLinearVelocity = Vector3.zero
                AutoWalkEnabled = false; Enabled.AutoWalkEnabled = false
                if VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(false, true) end
                wConn:Disconnect(); wConn = nil
            end
        end
    end)
end

local function stopAutoWalk()
    if wConn then wConn:Disconnect(); wConn = nil end; wPhase = 1
    local h = getHum(); if h then h:Move(Vector3.zero, false) end
end

local function startAutoRight()
    if rConn then rConn:Disconnect() end; rPhase = 1
    rConn = RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end
        local hrp = getHRP(); local hum = getHum(); if not hrp or not hum then return end
        local target = rPhase == 1 and PR1 or PR2
        if walkStep(target, hrp, hum) then
            if rPhase == 1 then
                rPhase = 2
            else
                hum:Move(Vector3.zero, false)
                hrp.AssemblyLinearVelocity = Vector3.zero
                AutoRightEnabled = false; Enabled.AutoRightEnabled = false
                if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(false, true) end
                rConn:Disconnect(); rConn = nil
            end
        end
    end)
end

local function stopAutoRight()
    if rConn then rConn:Disconnect(); rConn = nil end; rPhase = 1
    local h = getHum(); if h then h:Move(Vector3.zero, false) end
end

local ESPData = {}

local function buildESP(p)
    if p == player or ESPData[p] then return end
    local function attach(char)
        local hrp = char:WaitForChild("HumanoidRootPart", 5); if not hrp then return end
        local bb  = Instance.new("BillboardGui")
        bb.Name             = "ZYRA_ESP"
        bb.AlwaysOnTop      = true
        bb.Size             = UDim2.new(0, 158, 0, 54)
        bb.StudsOffset      = Vector3.new(0, 3.8, 0)
        bb.MaxDistance      = 260
        bb.ClipsDescendants = false
        bb.Parent           = hrp

        local bg = Instance.new("Frame", bb)
        bg.Size                   = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3       = Color3.fromRGB(5, 2, 13)
        bg.BackgroundTransparency = 0.08
        bg.BorderSizePixel        = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 7)

        local st = Instance.new("UIStroke", bg)
        st.Color        = Color3.fromRGB(95, 38, 185)
        st.Thickness    = 1.2
        st.Transparency = 0.18

        local nm = Instance.new("TextLabel", bg)
        nm.Size               = UDim2.new(1, -8, 0, 19)
        nm.Position           = UDim2.new(0, 4, 0, 2)
        nm.BackgroundTransparency = 1
        nm.Text               = p.Name
        nm.TextColor3         = Color3.fromRGB(255, 255, 255)
        nm.Font               = Enum.Font.GothamBold
        nm.TextSize           = 12
        nm.TextXAlignment     = Enum.TextXAlignment.Left

        local hpBg = Instance.new("Frame", bg)
        hpBg.Size             = UDim2.new(0.88, 0, 0, 4)
        hpBg.Position         = UDim2.new(0.06, 0, 0, 24)
        hpBg.BackgroundColor3 = Color3.fromRGB(22, 10, 40)
        hpBg.BorderSizePixel  = 0
        Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

        local hpFill = Instance.new("Frame", hpBg)
        hpFill.Name             = "HPFill"
        hpFill.Size             = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = Color3.fromRGB(55, 215, 95)
        hpFill.BorderSizePixel  = 0
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

        local dist = Instance.new("TextLabel", bg)
        dist.Name               = "Dist"
        dist.Size               = UDim2.new(0.45, 0, 0, 13)
        dist.Position           = UDim2.new(0, 4, 0, 32)
        dist.BackgroundTransparency = 1
        dist.Text               = "0m"
        dist.TextColor3         = Color3.fromRGB(120, 80, 210)
        dist.Font               = Enum.Font.GothamBold
        dist.TextSize           = 9
        dist.TextXAlignment     = Enum.TextXAlignment.Left

        local tagBg = Instance.new("Frame", bg)
        tagBg.Size             = UDim2.new(0, 42, 0, 13)
        tagBg.Position         = UDim2.new(1, -46, 0, 32)
        tagBg.BackgroundColor3 = Color3.fromRGB(155, 22, 45)
        tagBg.BorderSizePixel  = 0
        Instance.new("UICorner", tagBg).CornerRadius = UDim.new(0, 4)

        local tagL = Instance.new("TextLabel", tagBg)
        tagL.Size                 = UDim2.new(1, 0, 1, 0)
        tagL.BackgroundTransparency = 1
        tagL.Text                 = "ENEMY"
        tagL.TextColor3           = Color3.fromRGB(255, 255, 255)
        tagL.Font                 = Enum.Font.GothamBold
        tagL.TextSize             = 8

        ESPData[p] = {bb = bb, hrp = hrp, hpFill = hpFill, dist = dist}
    end

    if p.Character then task.spawn(function() attach(p.Character) end) end
    p.CharacterAdded:Connect(function(c)
        task.wait(0.3)
        if ESPData[p] and ESPData[p].bb then pcall(function() ESPData[p].bb:Destroy() end) end
        ESPData[p] = nil
        task.spawn(function() attach(c) end)
    end)
end

local function removeESP(p)
    if ESPData[p] then
        pcall(function() if ESPData[p].bb then ESPData[p].bb:Destroy() end end)
        ESPData[p] = nil
    end
end

local function refreshPlayerESP()
    if not Enabled.PlayerESP then
        for p in pairs(ESPData) do removeESP(p) end; return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then buildESP(p) end
    end
end

RunService.Heartbeat:Connect(function()
    if not Enabled.PlayerESP then return end
    local myHRP = getHRP()
    for p, data in pairs(ESPData) do
        pcall(function()
            if not data.bb or not data.hrp or not data.hrp.Parent then ESPData[p] = nil; return end
            if myHRP then
                data.dist.Text = math.floor((myHRP.Position - data.hrp.Position).Magnitude).."m"
            end
            local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                data.hpFill.Size = UDim2.new(pct, 0, 1, 0)
                data.hpFill.BackgroundColor3 = pct > 0.5
                    and Color3.fromRGB(55, 215, 95)
                    or  pct > 0.25 and Color3.fromRGB(255, 172, 0)
                    or  Color3.fromRGB(218, 50, 50)
            end
        end)
    end
end)

Players.PlayerAdded:Connect(function(p)
    task.wait(0.5)
    if Enabled.PlayerESP then buildESP(p) end
end)
Players.PlayerRemoving:Connect(removeESP)

local function runInvClone()
    local char = getChar(); if not char then return end
    local hum  = getHum()
    local bp   = player:FindFirstChild("Backpack")
    if not hum or not bp then return end
    local cloak  = bp:FindFirstChild("Invisibility Cloak")
    local cloner = bp:FindFirstChild("Quantum Cloner")
    if not cloak or not cloner then return end
    hum:UnequipTools(); task.wait(0.05)
    hum:EquipTool(cloak); task.wait(0.05); cloak:Activate()
    task.wait(1)
    hum:EquipTool(cloner)
    for _ = 1, 3 do task.spawn(function() cloner:Activate() end); task.wait(0.1) end
end

local function startInvClone()
    task.spawn(function()
        runInvClone()
        Enabled.InvClone = false
        if VisualSetters.InvClone then VisualSetters.InvClone(false, true) end
    end)
end

local function stopInvClone() end

player.CharacterAdded:Connect(function()
    task.wait(1)
    if Enabled.SpinBot    then stopSpin();   task.wait(0.1); startSpin()   end
    if Enabled.Galaxy     then setupGForce(); fixJump()                    end
    if Enabled.SpamBat    then stopSpam();   task.wait(0.1); startSpam()   end
    if Enabled.BatAimbot  then stopAimbot(); task.wait(0.1); startAimbot() end
    if Enabled.Unwalk     then startUnwalk()                               end
    if Enabled.PlayerESP  then task.wait(0.5); refreshPlayerESP()                end
    if Enabled.InstantGrab then disableInstantGrab(); task.wait(0.1); enableInstantGrab() end
end)

local HYDRA = {
    AUTO_STEAL      = false, AUTO_DUEL       = false, AUTO_HIT      = false,
    ANTI_RAGDOLL_H  = false, SLOW_MO         = false, TALL_JUMP     = false,
    SPIN_BOT_H      = false, INFINITE_JUMP_H = false, FOLLOW_PLAYER = false,
}

local HSpeedState = {Active = false, Mode = "None", Value = 16}
local HSpeedConn  = nil

local function hEnableSpeed()
    if HSpeedConn then HSpeedConn:Disconnect() end
    HSpeedConn = RunService.Stepped:Connect(function()
        if not HSpeedState.Active then return end
        local char = player.Character; if not char then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum:GetState() == Enum.HumanoidStateType.Running then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                root.AssemblyLinearVelocity = Vector3.new(
                    md.X * HSpeedState.Value,
                    root.AssemblyLinearVelocity.Y,
                    md.Z * HSpeedState.Value)
            end
        end
    end)
end

local function hDisableSpeed()
    if HSpeedConn then HSpeedConn:Disconnect(); HSpeedConn = nil end
end

local function hUpdateSpeed(mode)
    if HYDRA.AUTO_DUEL then return end
    if HSpeedState.Mode == mode and HSpeedState.Active then
        HSpeedState.Active = false; HSpeedState.Mode = "None"; hDisableSpeed()
    else
        HSpeedState.Active = true; HSpeedState.Mode = mode
        HSpeedState.Value  = mode == "Steal" and 30 or 59
        hEnableSpeed()
    end
end

local SlowFallForce, SlowFallAtt = nil, nil

local function applySlowFall(en)
    local char = player.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if en and root then
        if not SlowFallAtt then
            SlowFallAtt = Instance.new("Attachment", root); SlowFallAtt.Name = "SlowFallAtt"
        end
        if not SlowFallForce then
            SlowFallForce             = Instance.new("VectorForce", root)
            SlowFallForce.Name        = "SlowFallForce"
            SlowFallForce.Attachment0 = SlowFallAtt
            SlowFallForce.RelativeTo  = Enum.ActuatorRelativeTo.World
            SlowFallForce.Enabled     = true
        end
        task.spawn(function()
            while HYDRA.SLOW_MO and SlowFallForce and SlowFallForce.Parent do
                if root.AssemblyLinearVelocity.Y < -5 then
                    local mass = 0
                    for _, p in pairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then mass = mass + p:GetMass() end
                    end
                    SlowFallForce.Force = Vector3.new(0, mass * workspace.Gravity * 0.92, 0)
                else
                    SlowFallForce.Force = Vector3.zero
                end
                task.wait(0.1)
            end
            if SlowFallForce then SlowFallForce:Destroy(); SlowFallForce = nil end
            if SlowFallAtt   then SlowFallAtt:Destroy();   SlowFallAtt   = nil end
        end)
    else
        if SlowFallForce then SlowFallForce:Destroy(); SlowFallForce = nil end
        if SlowFallAtt   then SlowFallAtt:Destroy();   SlowFallAtt   = nil end
    end
end

local lastTallJump = 0
UserInputService.JumpRequest:Connect(function()
    if HYDRA.TALL_JUMP and player.Character and (tick() - lastTallJump > 0.5) then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 76, root.AssemblyLinearVelocity.Z)
            lastTallJump = tick()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not HYDRA.AUTO_HIT then return end
    local char = player.Character; if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
end)

local hSpinConn = nil

local function hEnableSpin()
    if hSpinConn then hSpinConn:Disconnect() end
    hSpinConn = RunService.RenderStepped:Connect(function()
        if not HYDRA.SPIN_BOT_H then return end
        local char = player.Character; if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        hrp.AssemblyAngularVelocity = Vector3.new(0, math.rad(7200), 0)
    end)
end

local function hDisableSpin()
    if hSpinConn then hSpinConn:Disconnect(); hSpinConn = nil end
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyAngularVelocity = Vector3.zero end
    end
end

RunService.Heartbeat:Connect(function()
    if not HYDRA.INFINITE_JUMP_H then return end
    local char = player.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local vel  = hrp.AssemblyLinearVelocity
    if vel.Y < -35 then hrp.AssemblyLinearVelocity = Vector3.new(vel.X, -35, vel.Z) end
end)

UserInputService.JumpRequest:Connect(function()
    if not HYDRA.INFINITE_JUMP_H then return end
    local char = player.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local vel  = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 55, vel.Z)
end)

RunService.Heartbeat:Connect(function()
    if not HYDRA.FOLLOW_PLAYER then return end
    local char = player.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local nearest, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local c   = p.Character
            local eh  = c and c:FindFirstChild("HumanoidRootPart")
            local eh2 = c and c:FindFirstChildOfClass("Humanoid")
            if eh and eh2 and eh2.Health > 0 then
                local d = (hrp.Position - eh.Position).Magnitude
                if d < dist then nearest = p; dist = d end
            end
        end
    end
    if not nearest then return end
    local tHRP = nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    if dist <= 5 then
        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0); return
    end
    local dir = (tHRP.Position - hrp.Position).Unit
    hrp.AssemblyLinearVelocity = Vector3.new(dir.X * 30, hrp.AssemblyLinearVelocity.Y, dir.Z * 30)
end)

local duelPath, duelIdx, duelMoving, duelWaiting, duelGrabDone = {}, 1, false, false, false
local duelMoveConn = nil

local function stopDuel()
    if duelMoveConn then duelMoveConn:Disconnect() end
    duelMoving = false; duelWaiting = false; duelGrabDone = false
end

local function moveDuel()
    if duelMoveConn then duelMoveConn:Disconnect() end
    duelMoveConn = RunService.Stepped:Connect(function()
        if not HYDRA.AUTO_DUEL or not duelMoving or duelWaiting then return end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
        local wp   = duelPath[duelIdx]; if not wp then stopDuel(); return end
        local d    = (root.Position - wp.position).Magnitude
        if d < 5 then
            if (duelIdx == 4 or duelIdx == 6) and not duelGrabDone then
                duelWaiting = true; root.AssemblyLinearVelocity = Vector3.zero; return
            end
            if duelIdx == #duelPath then stopDuel(); return end
            duelIdx = duelIdx + 1
        else
            local dir = (wp.position - root.Position).Unit
            root.AssemblyLinearVelocity = Vector3.new(dir.X * wp.speed, root.AssemblyLinearVelocity.Y, dir.Z * wp.speed)
        end
    end)
end

local function startDuel()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
    duelMoving = true; duelGrabDone = false
    if (root.Position - Vector3.new(-475,-7,96)).Magnitude > (root.Position - Vector3.new(-474,-7,23)).Magnitude then
        duelPath = {
            {position=Vector3.new(-475,-7,96),speed=59},{position=Vector3.new(-483,-5,95),speed=59},
            {position=Vector3.new(-487,-5,95),speed=55},{position=Vector3.new(-492,-5,95),speed=55},
            {position=Vector3.new(-473,-7,95),speed=29},{position=Vector3.new(-473,-7,11),speed=29}
        }
    else
        duelPath = {
            {position=Vector3.new(-474,-7,23),speed=55},{position=Vector3.new(-484,-5,24),speed=55},
            {position=Vector3.new(-488,-5,24),speed=55},{position=Vector3.new(-493,-5,25),speed=55},
            {position=Vector3.new(-473,-7,25),speed=29},{position=Vector3.new(-474,-7,112),speed=29}
        }
    end
    duelIdx = 1; moveDuel()
end

RunService.Heartbeat:Connect(function()
    local char = player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if hum and hum.WalkSpeed < 23 and duelWaiting and not duelGrabDone then
        task.spawn(function() task.wait(0.3); duelWaiting = false; duelGrabDone = true end)
    end
end)

local function sendAPCommands(targetName)
    task.spawn(function()
        local cmds = {
            ";balloon "..targetName, ";rocket "..targetName, ";morph "..targetName,
            ";jumpscare "..targetName, ";jail "..targetName
        }
        pcall(function()
            local ch = TextChatService.TextChannels.RBXGeneral
            for _, cmd in ipairs(cmds) do
                pcall(function() ch:SendAsync(cmd) end)
                task.wait(0.1)
            end
        end)
    end)
end

if playerGui:FindFirstChild("ZyraHubAll") then
    playerGui:FindFirstChild("ZyraHubAll"):Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ZyraHubAll"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

local BADGE_W = 240

do
    local badge = Instance.new("Frame")
    badge.Size             = UDim2.new(0, BADGE_W, 0, 34)
    badge.Position         = UDim2.new(0.5, -120, 0, 18)
    badge.BackgroundColor3 = Color3.fromRGB(10, 5, 24)
    badge.BorderSizePixel  = 0
    badge.Parent           = screenGui
    Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

    local dStroke = Instance.new("UIStroke", badge)
    dStroke.Thickness = 1.5; dStroke.Color = Color3.fromRGB(120, 50, 200); dStroke.Transparency = 0.1

    local dGrad = Instance.new("UIGradient", badge)
    dGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(45,10,90)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(20,8,50)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(20,8,50)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(45,10,90)),
    })
    task.spawn(function()
        local r = 0
        while badge and badge.Parent do r = (r + 0.8) % 360; dGrad.Rotation = r; task.wait(0.03) end
    end)

    local function makeDot(xPos, delay)
        local dot = Instance.new("Frame", badge)
        dot.Size             = UDim2.new(0, 7, 0, 7)
        dot.Position         = UDim2.new(0, xPos, 0.5, -3)
        dot.BackgroundColor3 = Color3.fromRGB(180, 90, 255)
        dot.BorderSizePixel  = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        task.spawn(function()
            task.wait(delay)
            local g = true
            while dot and dot.Parent do
                TweenService:Create(dot, TweenInfo.new(0.8, Enum.EasingStyle.Sine),
                    {BackgroundColor3 = g and Color3.fromRGB(220,130,255) or Color3.fromRGB(130,50,200)}):Play()
                g = not g; task.wait(0.8)
            end
        end)
        return dot
    end
    makeDot(14, 0)
    makeDot(BADGE_W - 21, 0.4)

    local dcTxt = Instance.new("TextLabel", badge)
    dcTxt.Size               = UDim2.new(1, -50, 1, 0)
    dcTxt.Position           = UDim2.new(0, 25, 0, 0)
    dcTxt.BackgroundTransparency = 1
    dcTxt.Text               = "discord.gg/zyrahub"
    dcTxt.TextColor3         = Color3.fromRGB(210, 170, 255)
    dcTxt.TextSize           = 12
    dcTxt.Font               = Enum.Font.GothamBold
    dcTxt.TextXAlignment     = Enum.TextXAlignment.Center

    local dcTG = Instance.new("UIGradient", dcTxt)
    dcTG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,220,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190,110,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,220,255)),
    })
    task.spawn(function()
        local off = 0
        while dcTxt and dcTxt.Parent do
            off = (off + 0.01) % 1
            dcTG.Offset = Vector2.new(math.sin(off * math.pi * 2) * 0.3, 0)
            task.wait(0.03)
        end
    end)
end

local FRAME_W   = 375
local HEADER_H  = 58
local TAB_H     = 32
local CONTENT_H = 310
local TOTAL_H   = HEADER_H + TAB_H + CONTENT_H + 16

local mainFrame = Instance.new("Frame")
mainFrame.Name             = "MainFrame"
mainFrame.Size             = UDim2.new(0, FRAME_W, 0, TOTAL_H)
mainFrame.Position         = UDim2.new(1, -(FRAME_W + 14), 0, 24)
mainFrame.BackgroundColor3 = Color3.fromRGB(8, 4, 18)
mainFrame.BorderSizePixel  = 0
mainFrame.Active           = true
mainFrame.Draggable        = true
mainFrame.Parent           = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local outerStroke = Instance.new("UIStroke", mainFrame)
outerStroke.Thickness    = 1.5
outerStroke.Color        = Color3.fromRGB(110, 45, 195)
outerStroke.Transparency = 0.2

local bgGrad = Instance.new("UIGradient", mainFrame)
bgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(14,6,30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10,4,22)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(6,2,16)),
})
bgGrad.Rotation = 135

local bGrad = Instance.new("UIGradient", outerStroke)
bGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(168,88,255)),
    ColorSequenceKeypoint.new(0.28, Color3.fromRGB(30,6,68)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(128,48,238)),
    ColorSequenceKeypoint.new(0.78, Color3.fromRGB(30,6,68)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(168,88,255)),
})
task.spawn(function()
    local r = 0
    while mainFrame.Parent do r = (r + 1) % 360; bGrad.Rotation = r; task.wait(0.025) end
end)

local header = Instance.new("Frame", mainFrame)
header.Size             = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundColor3 = Color3.fromRGB(12, 5, 28)
header.BorderSizePixel  = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local hGrad = Instance.new("UIGradient", header)
hGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(50,14,100)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(28,7,62)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(14,4,34)),
})
hGrad.Rotation = 90

local hLine = Instance.new("Frame", mainFrame)
hLine.Size             = UDim2.new(1, 0, 0, 2)
hLine.Position         = UDim2.new(0, 0, 0, HEADER_H - 2)
hLine.BackgroundColor3 = Color3.fromRGB(150, 60, 255)
hLine.BorderSizePixel  = 0
local hLG = Instance.new("UIGradient", hLine)
hLG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(60,0,140)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(170,70,255)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(200,100,255)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(60,0,140)),
})

do
    local hDot = Instance.new("Frame", header)
    hDot.Size             = UDim2.new(0, 10, 0, 10)
    hDot.Position         = UDim2.new(0, 14, 0.5, -5)
    hDot.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
    hDot.BorderSizePixel  = 0
    Instance.new("UICorner", hDot).CornerRadius = UDim.new(1, 0)
    local hDS = Instance.new("UIStroke", hDot)
    hDS.Color = Color3.fromRGB(230,160,255); hDS.Thickness = 1.5; hDS.Transparency = 0.3
    task.spawn(function()
        while header.Parent do
            tween(hDot, 0.8, {BackgroundColor3 = Color3.fromRGB(230,160,255)}); task.wait(0.9)
            tween(hDot, 0.8, {BackgroundColor3 = Color3.fromRGB(200,100,255)}); task.wait(0.9)
        end
    end)
end

local hTitle = Instance.new("TextLabel", header)
hTitle.Size               = UDim2.new(0, 110, 1, 0)
hTitle.Position           = UDim2.new(0, 32, 0, 0)
hTitle.BackgroundTransparency = 1
hTitle.Text               = "Zyra Hub"
hTitle.TextColor3         = Color3.fromRGB(235, 215, 255)
hTitle.Font               = Enum.Font.GothamBold
hTitle.TextSize           = 17
hTitle.TextXAlignment     = Enum.TextXAlignment.Left
Instance.new("UIGradient", hTitle).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,235,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(175,95,255)),
})

do
    local premF = Instance.new("Frame", header)
    premF.Size             = UDim2.new(0, 118, 0, 22)
    premF.Position         = UDim2.new(0, 148, 0.5, -11)
    premF.BackgroundColor3 = Color3.fromRGB(70, 20, 130)
    premF.BorderSizePixel  = 0
    Instance.new("UICorner", premF).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", premF).Color = Color3.fromRGB(180,100,255)
    local pG = Instance.new("UIGradient", premF)
    pG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(120,40,220)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,20,160)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(120,40,220)),
    }); pG.Rotation = 90
    local pLbl = Instance.new("TextLabel", premF)
    pLbl.Size                 = UDim2.new(1, 0, 1, 0)
    pLbl.BackgroundTransparency = 1
    pLbl.Text                 = "FREE VERSION"
    pLbl.TextColor3           = Color3.fromRGB(225,185,255)
    pLbl.Font                 = Enum.Font.GothamBold
    pLbl.TextSize             = 9
    pLbl.TextXAlignment       = Enum.TextXAlignment.Center
    Instance.new("UIGradient", pLbl).Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,230,100)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(220,180,255)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(190,130,255)),
    })
end

do
    local vTag = Instance.new("TextLabel", header)
    vTag.Size             = UDim2.new(0, 40, 0, 18)
    vTag.Position         = UDim2.new(1, -90, 0.5, -9)
    vTag.BackgroundColor3 = Color3.fromRGB(40, 14, 80)
    vTag.BorderSizePixel  = 0
    vTag.Text             = "v2"
    vTag.TextColor3       = Color3.fromRGB(180,130,255)
    vTag.TextSize         = 9
    vTag.Font             = Enum.Font.GothamBold
    vTag.TextXAlignment   = Enum.TextXAlignment.Center
    Instance.new("UICorner", vTag).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", vTag).Color = Color3.fromRGB(90,35,160)
end

do
    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size             = UDim2.new(0, 26, 0, 26)
    closeBtn.Position         = UDim2.new(1, -38, 0.5, -13)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text             = "X"
    closeBtn.TextColor3       = Color3.fromRGB(165,135,205)
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 16
    closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)
    closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.1, {TextColor3 = Color3.fromRGB(215,48,72)}) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.1, {TextColor3 = Color3.fromRGB(165,135,205)}) end)
end

local TAB_NAMES     = {"Mods", "Duels", "AP Spam", "Inst. Grab"}
local TAB_COUNT     = #TAB_NAMES
local currentTab    = 1
local tabBtns       = {}
local contentFrames = {}

local tabBar = Instance.new("Frame", mainFrame)
tabBar.Size             = UDim2.new(1, 0, 0, TAB_H)
tabBar.Position         = UDim2.new(0, 0, 0, HEADER_H)
tabBar.BackgroundColor3 = Color3.fromRGB(6, 3, 15)
tabBar.BorderSizePixel  = 0

local tabUnderline = Instance.new("Frame", tabBar)
tabUnderline.Size             = UDim2.new(1/TAB_COUNT, 0, 0, 2)
tabUnderline.Position         = UDim2.new(0, 0, 1, -2)
tabUnderline.BackgroundColor3 = Color3.fromRGB(160, 70, 255)
tabUnderline.BorderSizePixel  = 0
Instance.new("UICorner", tabUnderline).CornerRadius = UDim.new(0, 1)

local CONTENT_Y = HEADER_H + TAB_H
for i = 1, TAB_COUNT do
    local cf = Instance.new("Frame", mainFrame)
    cf.Size              = UDim2.new(1, 0, 0, CONTENT_H)
    cf.Position          = UDim2.new(0, 0, 0, CONTENT_Y)
    cf.BackgroundTransparency = 1
    cf.Visible           = (i == 1)
    cf.ClipsDescendants  = true
    contentFrames[i]     = cf
end

local function switchTab(idx)
    currentTab = idx
    for i = 1, #tabBtns do
        local btn = tabBtns[i]
        tween(btn, 0.15, {TextColor3 = i == idx and Color3.fromRGB(230,180,255) or Color3.fromRGB(80,55,120)})
    end
    TweenService:Create(tabUnderline, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
        {Position = UDim2.new((idx-1)/TAB_COUNT, 0, 1, -2)}):Play()
    for i = 1, #contentFrames do contentFrames[i].Visible = (i == idx) end
end

for i = 1, TAB_COUNT do
    local name = TAB_NAMES[i]
    local btn = Instance.new("TextButton", tabBar)
    btn.Size             = UDim2.new(1/TAB_COUNT, 0, 1, 0)
    btn.Position         = UDim2.new((i-1)/TAB_COUNT, 0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text             = name
    btn.TextColor3       = i == 1 and Color3.fromRGB(230,180,255) or Color3.fromRGB(80,55,120)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 10
    local iCopy = i
    btn.MouseButton1Click:Connect(function() switchTab(iCopy) end)
    btn.MouseEnter:Connect(function() if currentTab ~= iCopy then tween(btn, 0.1, {TextColor3 = Color3.fromRGB(150,110,210)}) end end)
    btn.MouseLeave:Connect(function() if currentTab ~= iCopy then tween(btn, 0.1, {TextColor3 = Color3.fromRGB(80,55,120)}) end end)
    tabBtns[i] = btn
end

local COLS   = 2
local CELL_W = (FRAME_W - 24 - 4) / 2
local CELL_H = 28
local CELL_G = 4
local ROWS   = 7
local gridH  = ROWS * (CELL_H + CELL_G) - CELL_G

local c1 = contentFrames[1]

do
    local secLbl = Instance.new("TextLabel", c1)
    secLbl.Size             = UDim2.new(1, -24, 0, 14)
    secLbl.Position         = UDim2.new(0, 12, 0, 8)
    secLbl.BackgroundTransparency = 1
    secLbl.Text             = "TOGGLES | [U] hide | keybinds: V N M X Z C"
    secLbl.TextColor3       = Color3.fromRGB(90, 62, 145)
    secLbl.TextSize         = 9
    secLbl.Font             = Enum.Font.GothamBold
    secLbl.TextXAlignment   = Enum.TextXAlignment.Left

    local div1 = Instance.new("Frame", c1)
    div1.Size             = UDim2.new(1, -24, 0, 1)
    div1.Position         = UDim2.new(0, 12, 0, 26)
    div1.BackgroundColor3 = Color3.fromRGB(45, 18, 85)
    div1.BorderSizePixel  = 0
end

local gridF = Instance.new("Frame", c1)
gridF.Size              = UDim2.new(0, FRAME_W - 24, 0, gridH)
gridF.Position          = UDim2.new(0, 12, 0, 32)
gridF.BackgroundTransparency = 1

local function buildToggle(parent, labelTxt, enabledKey, onToggleFn, xOff, yOff, cellW)
    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(0, cellW, 0, CELL_H)
    f.Position         = UDim2.new(0, xOff, 0, yOff)
    f.BackgroundColor3 = Color3.fromRGB(16, 8, 34)
    f.BorderSizePixel  = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)
    local fSt = Instance.new("UIStroke", f)
    fSt.Color = Color3.fromRGB(45,18,85); fSt.Thickness = 1; fSt.Transparency = 0.4

    local lbl = Instance.new("TextLabel", f)
    lbl.Size               = UDim2.new(0.7, 0, 1, 0)
    lbl.Position           = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelTxt
    lbl.TextColor3         = Color3.fromRGB(228, 210, 255)
    lbl.Font               = Enum.Font.GothamSemibold
    lbl.TextSize           = 10
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local isOn = enabledKey and (Enabled[enabledKey] == true) or false

    local tbg = Instance.new("Frame", f)
    tbg.Size             = UDim2.new(0, 34, 0, 17)
    tbg.Position         = UDim2.new(1, -40, 0.5, -8.5)
    tbg.BackgroundColor3 = isOn and Color3.fromRGB(95,45,175) or Color3.fromRGB(30,15,60)
    tbg.BorderSizePixel  = 0
    Instance.new("UICorner", tbg).CornerRadius = UDim.new(1, 0)

    local circ = Instance.new("Frame", tbg)
    circ.Size             = UDim2.new(0, 13, 0, 13)
    circ.Position         = isOn and UDim2.new(1,-15,0.5,-6.5) or UDim2.new(0,2,0.5,-6.5)
    circ.BackgroundColor3 = Color3.new(1, 1, 1)
    circ.BorderSizePixel  = 0
    Instance.new("UICorner", circ).CornerRadius = UDim.new(1, 0)

    local clk = Instance.new("TextButton", f)
    clk.Size             = UDim2.new(1, 0, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text             = ""
    clk.ZIndex           = 2

    local onBG   = Color3.fromRGB(28,10,58)
    local offBG  = Color3.fromRGB(16,8,34)
    local onTbg  = Color3.fromRGB(95,45,175)
    local offTbg = Color3.fromRGB(30,15,60)
    local onPos  = UDim2.new(1,-15,0.5,-6.5)
    local offPos = UDim2.new(0,2,0.5,-6.5)

    local function setV(state, skip)
        isOn = state
        TweenService:Create(tbg,  TweenInfo.new(0.2),                          {BackgroundColor3 = isOn and onTbg or offTbg}):Play()
        TweenService:Create(circ, TweenInfo.new(0.18, Enum.EasingStyle.Back),  {Position = isOn and onPos or offPos}):Play()
        tween(f, 0.18, {BackgroundColor3 = isOn and onBG or offBG})
        if not skip and onToggleFn then onToggleFn(isOn) end
    end

    if enabledKey then VisualSetters[enabledKey] = setV end

    clk.MouseEnter:Connect(function()  if not isOn then tween(f, 0.12, {BackgroundColor3 = Color3.fromRGB(26,12,50)}) end end)
    clk.MouseLeave:Connect(function()  if not isOn then tween(f, 0.12, {BackgroundColor3 = offBG}) end end)
    clk.MouseButton1Click:Connect(function()
        isOn = not isOn
        if enabledKey then Enabled[enabledKey] = isOn end
        setV(isOn)
    end)

    return setV
end

local toggleDefs = {
    {"Speed Boost",    "SpeedBoost",         function(s) if s then startSpeed()      else stopSpeed()      end end},
    {"Anti Ragdoll",   "AntiRagdoll",        function(s) if s then startAnti()       else stopAnti()       end end},
    {"Spin Bot",       "SpinBot",            function(s) if s then startSpin()       else stopSpin()       end end},
    {"Spam Bat",       "SpamBat",            function(s) if s then startSpam()       else stopSpam()       end end},
    {"Bat Aimbot",     "BatAimbot",          function(s) if s then startAimbot()     else stopAimbot()     end end},
    {"Galaxy Mode",    "Galaxy",             function(s) if s then startGalaxy()     else stopGalaxy()     end end},
    {"Speed Steal",    "SpeedWhileStealing", function(s) if s then startStealSpeed() else stopStealSpeed() end end},
    {"Optimizer+XRay", "Optimizer",          function(s) if s then startOpt()        else stopOpt()        end end},
    {"Player ESP",     "PlayerESP",          function(s) refreshESP() end},
    {"Galaxy Sky",     "GalaxySkyBright",    function(s) if s then startGSky()       else stopGSky()       end end},
    {"Auto Left",      "AutoWalkEnabled",    function(s)
        AutoWalkEnabled = s; Enabled.AutoWalkEnabled = s
        if s then startAutoWalk() else stopAutoWalk() end
    end},
    {"Auto Right",     "AutoRightEnabled",   function(s)
        AutoRightEnabled = s; Enabled.AutoRightEnabled = s
        if s then startAutoRight() else stopAutoRight() end
    end},
    {"Unwalk",         "Unwalk",             function(s) if s then startUnwalk()   else stopUnwalk()   end end},
    {"Inv Clone",      "InvClone",           function(s) if s then startInvClone() else stopInvClone() end end},
}

for i = 1, #toggleDefs do
    local def  = toggleDefs[i]
    local col  = ((i-1) % COLS) + 1
    local row  = math.ceil(i / COLS)
    local xOff = (col-1) * (CELL_W + CELL_G)
    local yOff = (row-1) * (CELL_H + CELL_G)
    buildToggle(gridF, def[1], def[2], def[3], xOff, yOff, CELL_W)
end

do
    local botGY = 32 + gridH + 8
    local div2  = Instance.new("Frame", c1)
    div2.Size             = UDim2.new(1, -24, 0, 1)
    div2.Position         = UDim2.new(0, 12, 0, botGY)
    div2.BackgroundColor3 = Color3.fromRGB(45, 18, 85)
    div2.BorderSizePixel  = 0

    local botF = Instance.new("Frame", c1)
    botF.Size              = UDim2.new(1, -24, 0, 30)
    botF.Position          = UDim2.new(0, 12, 0, botGY + 8)
    botF.BackgroundTransparency = 1

    local saveBtn = Instance.new("TextButton", botF)
    saveBtn.Size             = UDim2.new(0.48, 0, 1, 0)
    saveBtn.BackgroundColor3 = Color3.fromRGB(55, 18, 105)
    saveBtn.BorderSizePixel  = 0
    saveBtn.Text             = " Save Config"
    saveBtn.TextColor3       = Color3.fromRGB(220, 190, 255)
    saveBtn.Font             = Enum.Font.GothamBold
    saveBtn.TextSize         = 10
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 7)
    Instance.new("UIStroke", saveBtn).Color = Color3.fromRGB(90,35,160)

    local hideBtn = Instance.new("TextButton", botF)
    hideBtn.Size             = UDim2.new(0.48, 0, 1, 0)
    hideBtn.Position         = UDim2.new(0.52, 0, 0, 0)
    hideBtn.BackgroundColor3 = Color3.fromRGB(16, 8, 34)
    hideBtn.BorderSizePixel  = 0
    hideBtn.Text             = "[U] Hide"
    hideBtn.TextColor3       = Color3.fromRGB(145, 105, 205)
    hideBtn.Font             = Enum.Font.GothamMedium
    hideBtn.TextSize         = 10
    Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 7)
    Instance.new("UIStroke", hideBtn).Color = Color3.fromRGB(45,18,85)

    saveBtn.MouseButton1Click:Connect(function()
        SaveConfig()
        saveBtn.Text = " Saved!"
        tween(saveBtn, 0.1, {BackgroundColor3 = Color3.fromRGB(30,130,80)})
        task.delay(1.8, function()
            saveBtn.Text = " Save Config"
            tween(saveBtn, 0.3, {BackgroundColor3 = Color3.fromRGB(55,18,105)})
        end)
    end)
    hideBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)
    saveBtn.MouseEnter:Connect(function() tween(saveBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(80,25,140)}) end)
    saveBtn.MouseLeave:Connect(function() tween(saveBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(55,18,105)}) end)
    hideBtn.MouseEnter:Connect(function() tween(hideBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(26,12,50)}) end)
    hideBtn.MouseLeave:Connect(function() tween(hideBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(16,8,34)}) end)
end

local c2      = contentFrames[2]
local INNER_W = FRAME_W - 24
local CW2     = (INNER_W - CELL_G) / 2

local function makeSectionHeader(parent, txt, yPos)
    local bg = Instance.new("Frame", parent)
    bg.Size             = UDim2.new(1, -24, 0, 18)
    bg.Position         = UDim2.new(0, 12, 0, yPos)
    bg.BackgroundColor3 = Color3.fromRGB(30, 10, 65)
    bg.BorderSizePixel  = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)
    local g = Instance.new("UIGradient", bg)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70,20,140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20,8,50)),
    }); g.Rotation = 90
    local accent = Instance.new("Frame", bg)
    accent.Size             = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = Color3.fromRGB(160, 70, 255)
    accent.BorderSizePixel  = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 3)
    local lbl = Instance.new("TextLabel", bg)
    lbl.Size               = UDim2.new(1, -12, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = txt
    lbl.TextColor3         = Color3.fromRGB(200, 160, 255)
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 9
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
end

local function makeFullButton(parent, labelTxt, yPos, w, xOff, colorOn, colorOff, onClick)
    local offC = colorOff or Color3.fromRGB(20,8,45)
    local onC  = colorOn  or Color3.fromRGB(100,30,50)

    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(0, w, 0, CELL_H + 4)
    f.Position         = UDim2.new(0, xOff, 0, yPos)
    f.BackgroundColor3 = offC
    f.BorderSizePixel  = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local fSt = Instance.new("UIStroke", f)
    fSt.Color = Color3.fromRGB(90,35,170); fSt.Thickness = 1.2; fSt.Transparency = 0.3
    local g = Instance.new("UIGradient", f)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50,15,100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20,8,45)),
    }); g.Rotation = 90

    local dot = Instance.new("Frame", f)
    dot.Size             = UDim2.new(0, 7, 0, 7)
    dot.Position         = UDim2.new(0, 10, 0.5, -3.5)
    dot.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size               = UDim2.new(1, -26, 1, 0)
    lbl.Position           = UDim2.new(0, 22, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelTxt
    lbl.TextColor3         = Color3.fromRGB(228, 210, 255)
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 11
    lbl.TextXAlignment     = Enum.TextXAlignment.Center

    local isOn = false
    local clk  = Instance.new("TextButton", f)
    clk.Size             = UDim2.new(1, 0, 1, 0)
    clk.BackgroundTransparency = 1
    clk.Text             = ""
    clk.ZIndex           = 2

    local gradOn  = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(110,30,55)), ColorSequenceKeypoint.new(1,Color3.fromRGB(80,15,40))})
    local gradOff = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(50,15,100)), ColorSequenceKeypoint.new(1,Color3.fromRGB(20,8,45))})

    local function setV(state, skip)
        isOn = state
        if isOn then
            tween(f,   0.15, {BackgroundColor3 = onC})
            tween(dot, 0.15, {BackgroundColor3 = Color3.fromRGB(80,230,120)})
            g.Color = gradOn
        else
            tween(f,   0.15, {BackgroundColor3 = offC})
            tween(dot, 0.15, {BackgroundColor3 = Color3.fromRGB(100,40,200)})
            g.Color = gradOff
        end
        if not skip and onClick then onClick(isOn) end
    end

    clk.MouseEnter:Connect(function()  if not isOn then tween(f, 0.1, {BackgroundColor3 = Color3.fromRGB(38,14,80)}) end end)
    clk.MouseLeave:Connect(function()  if not isOn then tween(f, 0.1, {BackgroundColor3 = offC}) end end)
    clk.MouseButton1Click:Connect(function() setV(not isOn) end)
    return setV, f
end

do
    local dY = 8
    makeSectionHeader(c2, "AUTOMATION", dY); dY = dY + 22
    makeFullButton(c2, "AUTO DUEL", dY, CW2, 12,
        Color3.fromRGB(100,28,50), Color3.fromRGB(20,8,45),
        function(s) HYDRA.AUTO_DUEL = s; if s then HSpeedState.Active=false; HSpeedState.Mode="None"; hDisableSpeed(); startDuel() else stopDuel() end end)
    makeFullButton(c2, "AUTO GRAB", dY, CW2, 12+CW2+CELL_G,
        Color3.fromRGB(28,80,100), Color3.fromRGB(20,8,45),
        function(s) HYDRA.AUTO_STEAL = s end)
    dY = dY + CELL_H + 4 + CELL_G

    makeSectionHeader(c2, "SPEED", dY); dY = dY + 22
    local ssSetV, spSetV
    ssSetV = buildToggle(c2, "Steal Speed", nil, function(s)
        if s then
            if spSetV then spSetV(false, true) end
            hUpdateSpeed("Steal")
            if HSpeedState.Mode ~= "Steal" then ssSetV(false, true) end
        else
            if HSpeedState.Mode == "Steal" then hUpdateSpeed("Steal") end
        end
    end, 12, dY, CW2)
    spSetV = buildToggle(c2, "Sprint Speed", nil, function(s)
        if s then
            if ssSetV then ssSetV(false, true) end
            hUpdateSpeed("Sprint")
            if HSpeedState.Mode ~= "Sprint" then spSetV(false, true) end
        else
            if HSpeedState.Mode == "Sprint" then hUpdateSpeed("Sprint") end
        end
    end, 12+CW2+CELL_G, dY, CW2)
    dY = dY + CELL_H + CELL_G

    makeSectionHeader(c2, "COMBAT", dY); dY = dY + 22
    local combatDefs = {
        {"Auto Hit",     function(s) HYDRA.AUTO_HIT = s end},
        {"Anti Ragdoll", function(s) HYDRA.ANTI_RAGDOLL_H = s end},
        {"Spin Bot",     function(s) HYDRA.SPIN_BOT_H = s; if s then hEnableSpin() else hDisableSpin() end end},
        {"Inf Jump",     function(s) HYDRA.INFINITE_JUMP_H = s end},
    }
    for i = 1, #combatDefs do
        local def = combatDefs[i]
        local col = ((i-1) % 2) + 1
        local row = math.ceil(i / 2)
        buildToggle(c2, def[1], nil, def[2], 12+(col-1)*(CW2+CELL_G), dY+(row-1)*(CELL_H+CELL_G), CW2)
    end
    dY = dY + 2*(CELL_H+CELL_G)

    makeSectionHeader(c2, "MOBILITY", dY); dY = dY + 22
    local mobilityDefs = {
        {"Slow Mo",       function(s) HYDRA.SLOW_MO = s; applySlowFall(s) end},
        {"Tall Jump",     function(s) HYDRA.TALL_JUMP = s end},
        {"Follow Player", function(s) HYDRA.FOLLOW_PLAYER = s end},
    }
    for i = 1, #mobilityDefs do
        local def = mobilityDefs[i]
        local col = ((i-1) % 2) + 1
        local row = math.ceil(i / 2)
        buildToggle(c2, def[1], nil, def[2], 12+(col-1)*(CW2+CELL_G), dY+(row-1)*(CELL_H+CELL_G), CW2)
    end
end

do
    local c3 = contentFrames[3]

    local apSecLbl = Instance.new("TextLabel", c3)
    apSecLbl.Size             = UDim2.new(1, -24, 0, 14)
    apSecLbl.Position         = UDim2.new(0, 12, 0, 8)
    apSecLbl.BackgroundTransparency = 1
    apSecLbl.Text             = "PLAYER LIST | Click a player to send admin commands"
    apSecLbl.TextColor3       = Color3.fromRGB(90, 62, 145)
    apSecLbl.TextSize         = 9
    apSecLbl.Font             = Enum.Font.GothamBold
    apSecLbl.TextXAlignment   = Enum.TextXAlignment.Left

    local apDiv = Instance.new("Frame", c3)
    apDiv.Size             = UDim2.new(1, -24, 0, 1)
    apDiv.Position         = UDim2.new(0, 12, 0, 26)
    apDiv.BackgroundColor3 = Color3.fromRGB(45, 18, 85)
    apDiv.BorderSizePixel  = 0

    local apScroll = Instance.new("ScrollingFrame", c3)
    apScroll.Size                 = UDim2.new(1, -24, 0, CONTENT_H - 36)
    apScroll.Position             = UDim2.new(0, 12, 0, 32)
    apScroll.BackgroundTransparency = 1
    apScroll.BorderSizePixel      = 0
    apScroll.ScrollBarThickness   = 3
    apScroll.ScrollBarImageColor3 = Color3.fromRGB(95, 38, 185)
    apScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)

    local apLayout = Instance.new("UIListLayout", apScroll)
    apLayout.Padding   = UDim.new(0, CELL_G)
    apLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function buildAPButton(p)
        if p == player then return end
        local btn = Instance.new("TextButton", apScroll)
        btn.Name             = p.Name
        btn.Size             = UDim2.new(1, 0, 0, 44)
        btn.BackgroundColor3 = Color3.fromRGB(16, 8, 34)
        btn.BorderSizePixel  = 0
        btn.Text             = ""
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local bSt = Instance.new("UIStroke", btn)
        bSt.Color = Color3.fromRGB(45,18,85); bSt.Thickness = 1; bSt.Transparency = 0.4

        local nameLbl = Instance.new("TextLabel", btn)
        nameLbl.Size               = UDim2.new(0.7, 0, 0.55, 0)
        nameLbl.Position           = UDim2.new(0, 10, 0.08, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text               = p.DisplayName
        nameLbl.TextColor3         = Color3.fromRGB(228, 210, 255)
        nameLbl.Font               = Enum.Font.GothamBold
        nameLbl.TextSize           = 12
        nameLbl.TextXAlignment     = Enum.TextXAlignment.Left

        local subLbl = Instance.new("TextLabel", btn)
        subLbl.Size               = UDim2.new(0.7, 0, 0.3, 0)
        subLbl.Position           = UDim2.new(0, 10, 0.62, 0)
        subLbl.BackgroundTransparency = 1
        subLbl.Text               = "@"..p.Name
        subLbl.TextColor3         = Color3.fromRGB(120, 80, 210)
        subLbl.Font               = Enum.Font.Gotham
        subLbl.TextSize           = 9
        subLbl.TextXAlignment     = Enum.TextXAlignment.Left

        local tagBg = Instance.new("Frame", btn)
        tagBg.Size             = UDim2.new(0, 48, 0, 17)
        tagBg.Position         = UDim2.new(1, -56, 0.5, -8)
        tagBg.BackgroundColor3 = Color3.fromRGB(155, 22, 45)
        tagBg.BorderSizePixel  = 0
        Instance.new("UICorner", tagBg).CornerRadius = UDim.new(0, 5)
        local tagL = Instance.new("TextLabel", tagBg)
        tagL.Size                 = UDim2.new(1, 0, 1, 0)
        tagL.BackgroundTransparency = 1
        tagL.Text                 = "SPAM"
        tagL.TextColor3           = Color3.fromRGB(255, 255, 255)
        tagL.Font                 = Enum.Font.GothamBold
        tagL.TextSize             = 9

        btn.MouseButton1Click:Connect(function()
            tween(btn, 0.08, {BackgroundColor3 = Color3.fromRGB(100,20,160)})
            task.delay(0.35, function() tween(btn, 0.2, {BackgroundColor3 = Color3.fromRGB(16,8,34)}) end)
            sendAPCommands(p.Name)
        end)
        btn.MouseEnter:Connect(function() tween(btn, 0.1, {BackgroundColor3 = Color3.fromRGB(26,12,50)}) end)
        btn.MouseLeave:Connect(function() tween(btn, 0.1, {BackgroundColor3 = Color3.fromRGB(16,8,34)}) end)
    end

    local function refreshAPList()
        for _, ch in pairs(apScroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        for _, p in pairs(Players:GetPlayers()) do buildAPButton(p) end
        apScroll.CanvasSize = UDim2.new(0, 0, 0, apLayout.AbsoluteContentSize.Y + 10)
    end

    Players.PlayerAdded:Connect(function()    task.wait(0.5); refreshAPList() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.2); refreshAPList() end)
    refreshAPList()
end

task.spawn(function()
    local c4 = contentFrames[4]

    local igTitle = Instance.new("TextLabel", c4)
    igTitle.Size               = UDim2.new(1, -24, 0, 14)
    igTitle.Position           = UDim2.new(0, 12, 0, 8)
    igTitle.BackgroundTransparency = 1
    igTitle.Text               = "INSTANT GRAB | Instant auto-steal"
    igTitle.TextColor3         = Color3.fromRGB(90, 62, 145)
    igTitle.TextSize           = 9
    igTitle.Font               = Enum.Font.GothamBold
    igTitle.TextXAlignment     = Enum.TextXAlignment.Left

    local igDiv = Instance.new("Frame", c4)
    igDiv.Size             = UDim2.new(1, -24, 0, 1)
    igDiv.Position         = UDim2.new(0, 12, 0, 26)
    igDiv.BackgroundColor3 = Color3.fromRGB(45, 18, 85)
    igDiv.BorderSizePixel  = 0

    local igBtnW = FRAME_W - 24
    local igBtnF = Instance.new("Frame", c4)
    igBtnF.Size             = UDim2.new(0, igBtnW, 0, 56)
    igBtnF.Position         = UDim2.new(0, 12, 0, 36)
    igBtnF.BackgroundColor3 = Color3.fromRGB(20, 8, 45)
    igBtnF.BorderSizePixel  = 0
    Instance.new("UICorner", igBtnF).CornerRadius = UDim.new(0, 12)

    local igBtnStroke = Instance.new("UIStroke", igBtnF)
    igBtnStroke.Color        = Color3.fromRGB(90, 35, 170)
    igBtnStroke.Thickness    = 1.5
    igBtnStroke.Transparency = 0.2

    local igBtnGrad = Instance.new("UIGradient", igBtnF)
    igBtnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50,15,100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20,8,45)),
    })
    igBtnGrad.Rotation = 90

    local igDot = Instance.new("Frame", igBtnF)
    igDot.Size             = UDim2.new(0, 10, 0, 10)
    igDot.Position         = UDim2.new(0, 18, 0.5, -5)
    igDot.BackgroundColor3 = Color3.fromRGB(100, 40, 200)
    igDot.BorderSizePixel  = 0
    Instance.new("UICorner", igDot).CornerRadius = UDim.new(1, 0)

    local igBtnLbl = Instance.new("TextLabel", igBtnF)
    igBtnLbl.Size               = UDim2.new(1, -42, 1, 0)
    igBtnLbl.Position           = UDim2.new(0, 36, 0, 0)
    igBtnLbl.BackgroundTransparency = 1
    igBtnLbl.Text               = "INSTANT GRAB : OFF"
    igBtnLbl.TextColor3         = Color3.fromRGB(228, 210, 255)
    igBtnLbl.Font               = Enum.Font.GothamBold
    igBtnLbl.TextSize           = 14
    igBtnLbl.TextXAlignment     = Enum.TextXAlignment.Center

    local igClk = Instance.new("TextButton", igBtnF)
    igClk.Size             = UDim2.new(1, 0, 1, 0)
    igClk.BackgroundTransparency = 1
    igClk.Text             = ""
    igClk.ZIndex           = 2

    local igStatusF = Instance.new("Frame", c4)
    igStatusF.Size             = UDim2.new(0, igBtnW, 0, 36)
    igStatusF.Position         = UDim2.new(0, 12, 0, 102)
    igStatusF.BackgroundColor3 = Color3.fromRGB(12, 5, 28)
    igStatusF.BorderSizePixel  = 0
    Instance.new("UICorner", igStatusF).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", igStatusF).Color = Color3.fromRGB(45,18,85)

    local igStatusDot = Instance.new("Frame", igStatusF)
    igStatusDot.Size             = UDim2.new(0, 8, 0, 8)
    igStatusDot.Position         = UDim2.new(0, 14, 0.5, -4)
    igStatusDot.BackgroundColor3 = Color3.fromRGB(80, 40, 130)
    igStatusDot.BorderSizePixel  = 0
    Instance.new("UICorner", igStatusDot).CornerRadius = UDim.new(1, 0)

    local igStatusLbl = Instance.new("TextLabel", igStatusF)
    igStatusLbl.Size               = UDim2.new(1, -36, 1, 0)
    igStatusLbl.Position           = UDim2.new(0, 30, 0, 0)
    igStatusLbl.BackgroundTransparency = 1
    igStatusLbl.Text               = "Inactive - press the button to enable"
    igStatusLbl.TextColor3         = Color3.fromRGB(120, 80, 170)
    igStatusLbl.Font               = Enum.Font.GothamSemibold
    igStatusLbl.TextSize           = 10
    igStatusLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local igIsOn      = Enabled.InstantGrab
    local igPulseConn = nil

    local IG_ON_BG      = Color3.fromRGB(28, 80, 35)
    local IG_OFF_BG     = Color3.fromRGB(20, 8, 45)
    local IG_ON_STROKE  = Color3.fromRGB(50, 200, 80)
    local IG_OFF_STROKE = Color3.fromRGB(90, 35, 170)
    local IG_ON_DOT     = Color3.fromRGB(80, 240, 120)
    local IG_OFF_DOT    = Color3.fromRGB(100, 40, 200)
    local IG_ON_SDOT    = Color3.fromRGB(80, 220, 100)
    local IG_OFF_SDOT   = Color3.fromRGB(80, 40, 130)
    local IG_ON_GRAD    = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(40,110,50)),ColorSequenceKeypoint.new(1,Color3.fromRGB(20,60,25))})
    local IG_OFF_GRAD   = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(50,15,100)),ColorSequenceKeypoint.new(1,Color3.fromRGB(20,8,45))})

    local function setIGState(state, skip)
        igIsOn              = state
        Enabled.InstantGrab = state

        if state then
            if not skip then enableInstantGrab() end
            igBtnLbl.Text       = "INSTANT GRAB: ON"
            tween(igBtnF,      0.18, {BackgroundColor3 = IG_ON_BG})
            igBtnGrad.Color     = IG_ON_GRAD
            igBtnStroke.Color   = IG_ON_STROKE
            tween(igDot,       0.15, {BackgroundColor3 = IG_ON_DOT})
            igStatusLbl.Text        = "Active - grabs trigger instantly"
            igStatusLbl.TextColor3  = IG_ON_SDOT
            tween(igStatusDot, 0.15, {BackgroundColor3 = IG_ON_SDOT})
            if igPulseConn then task.cancel(igPulseConn) end
            igPulseConn = task.spawn(function()
                while igIsOn do
                    TweenService:Create(igDot, TweenInfo.new(0.5,Enum.EasingStyle.Sine), {BackgroundColor3=Color3.fromRGB(50,200,80)}):Play()
                    task.wait(0.5)
                    if not igIsOn then break end
                    TweenService:Create(igDot, TweenInfo.new(0.5,Enum.EasingStyle.Sine), {BackgroundColor3=Color3.fromRGB(100,255,140)}):Play()
                    task.wait(0.5)
                end
            end)
        else
            if not skip then disableInstantGrab() end
            igBtnLbl.Text       = "INSTANT GRAB: OFF"
            tween(igBtnF,      0.18, {BackgroundColor3 = IG_OFF_BG})
            igBtnGrad.Color     = IG_OFF_GRAD
            igBtnStroke.Color   = IG_OFF_STROKE
            tween(igDot,       0.15, {BackgroundColor3 = IG_OFF_DOT})
            igStatusLbl.Text        = "Inactive - press the button to enable"
            igStatusLbl.TextColor3  = Color3.fromRGB(120, 80, 170)
            tween(igStatusDot, 0.15, {BackgroundColor3 = IG_OFF_SDOT})
            if igPulseConn then task.cancel(igPulseConn); igPulseConn = nil end
        end
    end

    VisualSetters.InstantGrab = function(state, skip) setIGState(state, skip) end

    igClk.MouseButton1Click:Connect(function() setIGState(not igIsOn) end)
    igClk.MouseEnter:Connect(function()
        if not igIsOn then tween(igBtnF, 0.1, {BackgroundColor3 = Color3.fromRGB(38,14,80)}) end
    end)
    igClk.MouseLeave:Connect(function()
        if not igIsOn then tween(igBtnF, 0.1, {BackgroundColor3 = IG_OFF_BG}) end
    end)

    if igIsOn then setIGState(true, true) end
end)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Space then spaceHeld = true; return end
    if inp.KeyCode == Enum.KeyCode.U then mainFrame.Visible = not mainFrame.Visible; return end

    local function toggle(key, fn)
        Enabled[key] = not Enabled[key]
        if VisualSetters[key] then VisualSetters[key](Enabled[key], true) end
        fn(Enabled[key])
    end

    if inp.KeyCode == KEYBINDS.SPEED then
        toggle("SpeedBoost", function(s) if s then startSpeed() else stopSpeed() end end)
    elseif inp.KeyCode == KEYBINDS.SPIN then
        toggle("SpinBot", function(s) if s then startSpin() else stopSpin() end end)
    elseif inp.KeyCode == KEYBINDS.GALAXY then
        toggle("Galaxy", function(s) if s then startGalaxy() else stopGalaxy() end end)
    elseif inp.KeyCode == KEYBINDS.BATAIMBOT then
        toggle("BatAimbot", function(s) if s then startAimbot() else stopAimbot() end end)
    elseif inp.KeyCode == KEYBINDS.AUTOLEFT then
        AutoWalkEnabled = not AutoWalkEnabled; Enabled.AutoWalkEnabled = AutoWalkEnabled
        if VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(AutoWalkEnabled, true) end
        if AutoWalkEnabled then startAutoWalk() else stopAutoWalk() end
    elseif inp.KeyCode == KEYBINDS.AUTORIGHT then
        AutoRightEnabled = not AutoRightEnabled; Enabled.AutoRightEnabled = AutoRightEnabled
        if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(AutoRightEnabled, true) end
        if AutoRightEnabled then startAutoRight() else stopAutoRight() end
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.Space then spaceHeld = false end
end)

task.spawn(function()
    task.wait(3.5)
    if not getChar() or not getHRP() then player.CharacterAdded:Wait(); task.wait(1.2) end
    for k, sv in pairs(VisualSetters) do if Enabled[k] then sv(true, true) end end
    if Enabled.AntiRagdoll        then startAnti()         end
    if Enabled.PlayerESP          then refreshESP()        end
    if Enabled.InstantGrab        then enableInstantGrab() end
    task.wait()
    if Enabled.GalaxySkyBright    then startGSky()         end
    if Enabled.Optimizer          then startOpt()          end
    task.wait()
    if Enabled.SpeedBoost         then startSpeed()        end
    if Enabled.SpinBot            then startSpin()         end
    if Enabled.SpamBat            then startSpam()         end
    if Enabled.BatAimbot          then startAimbot()       end
    if Enabled.Galaxy             then startGalaxy()       end
    if Enabled.SpeedWhileStealing then startStealSpeed()   end
    if Enabled.Unwalk             then startUnwalk()       end
    task.wait()
    if Enabled.AutoWalkEnabled  then AutoWalkEnabled  = true; startAutoWalk()  end
    if Enabled.AutoRightEnabled then AutoRightEnabled = true; startAutoRight() end
end)
        -- [[ END OF FREEHUB CODE ]] --
        
        -- Override or hook up stop logic
        _G.StopFreeHub = function()
            -- Attempting safe teardown
            pcall(function()
                if mainFrame then mainFrame.Visible = false end
                if sg then sg.Enabled = false end
                
                -- Turn off all features in freehub config
                if type(Enabled) == "table" then
                    for k,v in pairs(Enabled) do
                        Enabled[k] = false
                        if VisualSetters and VisualSetters[k] then pcall(VisualSetters[k], false, true) end
                    end
                end
                
                -- Stop individual connections globally if they are local to freehub (we can't easily reach them outside, but since we are in the same scope, we can!)
                if stopAnti         then pcall(stopAnti) end
                if stopSpeed        then pcall(stopSpeed) end
                if stopSpin         then pcall(stopSpin) end
                if stopSpam         then pcall(stopSpam) end
                if stopAimbot       then pcall(stopAimbot) end
                if stopGalaxy       then pcall(stopGalaxy) end
                if stopStealSpeed   then pcall(stopStealSpeed) end
                if stopUnwalk       then pcall(stopUnwalk) end
                if stopAutoWalk     then pcall(stopAutoWalk) end
                if stopAutoRight    then pcall(stopAutoRight) end
                if disableInstantGrab then pcall(disableInstantGrab) end
                if stopGSky         then pcall(stopGSky) end
                if stopOpt          then pcall(stopOpt) end
            end)
        end
        
        __FREEHUB_UI_TOGGLE = function(visible)
            pcall(function()
                if sg then sg.Enabled = visible end
                if mainFrame then mainFrame.Visible = visible end
            end)
        end
    end)
end


local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local TeleportService    = game:GetService("TeleportService")
local TweenService        = game:GetService("TweenService")
local StarterGui          = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService    = game:GetService("UserInputService")
local TextChatService    = game:GetService("TextChatService")
local Animals   = require(ReplicatedStorage.Datas.Animals)
local Mutations = require(ReplicatedStorage.Datas.Mutations)
local Traits    = require(ReplicatedStorage.Datas.Traits)
local Net       = require(ReplicatedStorage.Packages.Net)
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer



local CFG_FILE = "ZYRA_HUB_STEAL.json"
local ZyraSettings = {
    AntiRagdoll    = false,
    SpeedSteal     = false,
    InstantLeave   = false,
    AutoStealStart = true,
    InstantReTp    = false,
    EspEnabled     = false,
    EspHighest     = false,
    EspPlots       = false,
    -- Invis / Movement
    InvisEnabled   = false,
    AutoCorrect    = false,
    InvisDepth     = 3.37,
    InvisRotation  = 0,
    SpeedValue     = 29,
    FreeHubEnabled = false,
    RejoinPanelEnabled = true,
}
pcall(function()
    if readfile and isfile and isfile(CFG_FILE) then
        local d = HttpService:JSONDecode(readfile(CFG_FILE))
        if d then
            for k, v in pairs(d) do
                if ZyraSettings[k] ~= nil then ZyraSettings[k] = v end
            end
        end
    end
end)
local function SaveConfig()
    if writefile then
        pcall(function()
            writefile(CFG_FILE, HttpService:JSONEncode(ZyraSettings))
        end)
    end
end

local stealSucceeded = false

local function instantLeave()
    if not ZyraSettings.InstantLeave then return end
    if not stealSucceeded then return end
    task.delay(0.25, function()
        pcall(function() game:Shutdown() end)
        pcall(function() Players.LocalPlayer:Kick("") end)
    end)
end

local CFG = {
    FIRE_INTERVAL = 0.1,
    TP_WAIT       = 0.05,
    CARPET_HEIGHT = 16.35,
}

local config = nil -- Removed, moved to ZyraSettings

local invisConn = nil
local renderConn = nil
local steppedConn = nil
local original_C0_Saved = nil
local savedCF = nil

local BASE_COORDS = {
    { floor1 = Vector3.new(-343, -6,  221),  floor2 = Vector3.new(-341, 13,  221)  },
    { floor1 = Vector3.new(-342, -6,  114),  floor2 = Vector3.new(-341, 13,  114)  },
    { floor1 = Vector3.new(-343, -7,  7),    floor2 = Vector3.new(-341, 13,  7)    },
    { floor1 = Vector3.new(-343, -7, -100),  floor2 = Vector3.new(-341, 13, -100)  },
    { floor1 = Vector3.new(-477, -6, -100),  floor2 = Vector3.new(-479, 13, -101)  },
    { floor1 = Vector3.new(-477, -7,  7),    floor2 = Vector3.new(-479, 13,  6)    },
    { floor1 = Vector3.new(-477, -6,  113),  floor2 = Vector3.new(-479, 13,  113)  },
    { floor1 = Vector3.new(-477, -6,  221),  floor2 = Vector3.new(-479, 13,  220)  },
}

local function getNearestBaseCoords(plot)
    local plotPos = plot:GetPivot().Position
    local best, bestDist = nil, math.huge
    for _, base in ipairs(BASE_COORDS) do
        local mid  = (base.floor1 + base.floor2) / 2
        local dist = (Vector3.new(plotPos.X, 0, plotPos.Z) - Vector3.new(mid.X, 0, mid.Z)).Magnitude
        if dist < bestDist then
            bestDist = dist
            best     = base
        end
    end
    return best
end

local blockSpots = {
    CFrame.new(-402.18, -6.34, 131.83) * CFrame.Angles(0, math.rad(-20.08), 0),
    CFrame.new(-416.66, -6.34, -2.05)  * CFrame.Angles(0, math.rad(-62.89), 0),
    CFrame.new(-329.37, -4.68, 18.12)  * CFrame.Angles(0, math.rad(-30.53), 0),
}

local lastScanResults   = {}
local bestEntry         = nil
local lockedEntry       = nil
local isAutoSteal       = false
local isWorking         = false
local stealSession      = 0
local espHighestBB      = nil
local espBillboards     = {}
local stealStatusLabel
local cachedStealPrompt = nil
local godModeConnection = nil
local blockKeyCode      = Enum.KeyCode.V

local antiRagdollConn   = nil
local speedStealConn    = nil
local hasBrainrot       = false
local isTeleporting     = false

local espPlotsConnections = {}

local stealBtn
local statusDot

local LASER_COLOR     = Color3.fromRGB(160, 80, 255)
local LASER_THICKNESS = 0.08
local PULSE_SPEED     = 2.5

local myPlotModel  = nil
local myPlotCenter = nil
local myPlotUUID   = nil

local function resolveUUID(key)
    if typeof(key) == "buffer" then
        local hex = string.lower(buffer.tostring(key, "hex"))
        return string.format("%s-%s-%s-%s-%s",
            hex:sub(1,8), hex:sub(9,12), hex:sub(13,16),
            hex:sub(17,20), hex:sub(21,32))
    end
    return tostring(key)
end

local function getPlotCenter(model)
    if not model then return nil end
    if model.PrimaryPart then return model.PrimaryPart.Position end
    local ok, cf = pcall(function() return model:GetPivot() end)
    if ok and cf then return cf.Position end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then return p.Position end
    end
    return nil
end

local PlotController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("PlotController"))
PlotController.Start()

task.spawn(function()
    local timeout = 5
    local start   = tick()
    local plotObj
    repeat
        plotObj = PlotController.GetMyPlot()
        task.wait(0.05)
    until plotObj or (tick() - start > timeout)

    if not plotObj then
        warn("[ZyraLaser] Plot introuvable après "..timeout.."s")
        return
    end

    local rawUID  = plotObj:GetUID()
    myPlotUUID    = resolveUUID(rawUID)

    local Plots = workspace:WaitForChild("Plots", 10)
    if Plots then
        myPlotModel  = Plots:FindFirstChild(myPlotUUID)
        if myPlotModel then
            myPlotCenter = getPlotCenter(myPlotModel)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if myPlotModel and myPlotModel.Parent then
            myPlotCenter = getPlotCenter(myPlotModel)
        end
    end
end)

local laserPart = nil
local laserConn = nil

local function destroyLaser()
    if laserConn then laserConn:Disconnect(); laserConn = nil end
    if laserPart and laserPart.Parent then laserPart:Destroy(); laserPart = nil end
end

local function createLaser()
    destroyLaser()
    laserPart               = Instance.new("Part")
    laserPart.Name          = "ZyraBaseLaser"
    laserPart.Anchored      = true
    laserPart.CanCollide    = false
    laserPart.CastShadow    = false
    laserPart.Shape         = Enum.PartType.Cylinder
    laserPart.Size          = Vector3.new(1, LASER_THICKNESS, LASER_THICKNESS)
    laserPart.Material      = Enum.Material.Neon
    laserPart.Color         = LASER_COLOR
    laserPart.Transparency  = 0.15
    laserPart.Parent        = workspace

    local t = 0
    laserConn = RunService.Heartbeat:Connect(function(dt)
        t += dt * PULSE_SPEED
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local target = myPlotCenter
        if not target then return end
        local origin = hrp.Position
        local dir    = target - origin
        local dist   = dir.Magnitude
        if dist < 0.5 then return end
        laserPart.Transparency = 0.08 + 0.38 * math.abs(math.sin(t))
        local h, s, v = Color3.toHSV(LASER_COLOR)
        laserPart.Color = Color3.fromHSV((h + math.sin(t * 0.4) * 0.04) % 1, s, v)
        local mid = origin + dir * 0.5
        laserPart.Size   = Vector3.new(dist, LASER_THICKNESS, LASER_THICKNESS)
        laserPart.CFrame = CFrame.lookAt(mid, target) * CFrame.Angles(0, math.rad(90), 0)
    end)
end

createLaser()
player.CharacterAdded:Connect(function()
    task.wait(1)
    createLaser()
end)

local function fastClickBlock()
    task.wait(0.5)
    local size = workspace.CurrentCamera.ViewportSize
    for i = 1, 10 do
        VirtualInputManager:SendMouseButtonEvent(size.X/2, size.Y/2 + 30, 0, true,  game, 1)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(size.X/2, size.Y/2 + 30, 0, false, game, 1)
        task.wait(0.04)
    end
end

local function startAntiRagdoll()
    if antiRagdollConn then return end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not ZyraSettings.AntiRagdoll then return end
        local c = player.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local h   = c:FindFirstChildOfClass("Humanoid")
        if h then
            local st = h:GetState()
            if st == Enum.HumanoidStateType.Physics
            or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown then
                h:ChangeState(Enum.HumanoidStateType.Running)
                Camera.CameraSubject = h
                if hrp then
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
        for _, o in ipairs(c:GetDescendants()) do
            if o:IsA("Motor6D") and not o.Enabled then o.Enabled = true end
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn = nil end
end

-- SPEED_STEAL_VALUE removed, moved to ZyraSettings.SpeedValue

local function startSpeedSteal()
    if speedStealConn then return end
    speedStealConn = RunService.Heartbeat:Connect(function(dt)
        if not ZyraSettings.SpeedSteal then return end
        if not hasBrainrot then return end
        if isTeleporting then return end
        local c   = player.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local md = hum.MoveDirection
        if md.Magnitude < 0.1 then return end
        local vy = hrp.AssemblyLinearVelocity.Y
        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(
            Vector3.new(md.X * ZyraSettings.SpeedValue, vy, md.Z * ZyraSettings.SpeedValue),
            math.min(1, dt * 18)
        )
    end)
end

local function stopSpeedSteal()
    if speedStealConn then speedStealConn:Disconnect(); speedStealConn = nil end
    local c = player.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16
    end
end

local function startInvis()
    local c = player.Character
    if not c then return end
    
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- On trouve l'articulation principale du corps (R6 ou R15)
    local rootJoint = hrp:FindFirstChild("RootJoint") or (c:FindFirstChild("LowerTorso") and c.LowerTorso:FindFirstChild("Root"))
    if not rootJoint then return end
    
    original_C0_Saved = rootJoint.C0
    savedCF = hrp.CFrame

    -- Pour éviter de mourir en allant sous la map
    hum.MaxHealth = math.huge
    hum.Health = math.huge
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

    -- Désactive les collisions du corps pour éviter les glitchs avec le sol
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end

    -- 1. Stepped : Modifie l'Animation (Pour que le SERVEUR voit ton Corps en haut)
    steppedConn = RunService.Stepped:Connect(function()
        if not rootJoint or not savedCF then return end
        
        local pos = savedCF.Position
        local _, yRot, _ = savedCF:ToEulerAnglesYXZ()
        local rad = math.rad(ZyraSettings.InvisRotation)
        
        -- Méthode Nameless : math.pi pour inverser l'HRP
        local fakeCF = CFrame.new(pos.X, pos.Y - ZyraSettings.InvisDepth, pos.Z) * CFrame.Angles(math.pi, yRot + rad, 0)
        
        local originalTransform = rootJoint.Transform
        local modifiedTransform = (fakeCF * original_C0_Saved):Inverse() * savedCF * original_C0_Saved * originalTransform
        rootJoint.Transform = modifiedTransform
    end)

    -- 2. Heartbeat : Abaisse le HRP (et l'objet soudé) sous terre (Reçu par le Serveur)
    invisConn = RunService.Heartbeat:Connect(function()
        local c2 = player.Character
        if not c2 then return end
        local h = c2:FindFirstChild("HumanoidRootPart")
        local hu = c2:FindFirstChildOfClass("Humanoid")
        if not h then return end

        savedCF = h.CFrame
        local pos = savedCF.Position
        local _, yRot, _ = savedCF:ToEulerAnglesYXZ()
        local rad = math.rad(ZyraSettings.InvisRotation)

        local fakeCF = CFrame.new(pos.X, pos.Y - ZyraSettings.InvisDepth, pos.Z) * CFrame.Angles(math.pi, yRot + rad, 0)
        h.CFrame = fakeCF

        if hu then hu.Health = hu.MaxHealth end
    end)

    -- 3. RenderStepped : Réparation Visuelle et Physique pour TOI (Client)
    renderConn = RunService.RenderStepped:Connect(function()
        local c2 = player.Character
        if not c2 then return end
        local h = c2:FindFirstChild("HumanoidRootPart")
        if not h or not rootJoint or not savedCF then return end
        
        h.CFrame = savedCF
        
        local pos = savedCF.Position
        local _, yRot, _ = savedCF:ToEulerAnglesYXZ()
        local rad = math.rad(ZyraSettings.InvisRotation)
        local fakeCF = CFrame.new(pos.X, pos.Y - ZyraSettings.InvisDepth, pos.Z) * CFrame.Angles(math.pi, yRot + rad, 0)
        
        rootJoint.C0 = savedCF:Inverse() * fakeCF * original_C0_Saved
    end)
end

local function stopInvis()
    if invisConn then invisConn:Disconnect(); invisConn = nil end
    if renderConn then renderConn:Disconnect(); renderConn = nil end
    if steppedConn then steppedConn:Disconnect(); steppedConn = nil end

    local c = player.Character
    if not c then return end
    
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hrp then
        local rootJoint = hrp:FindFirstChild("RootJoint") or (c:FindFirstChild("LowerTorso") and c.LowerTorso:FindFirstChild("Root"))
        if rootJoint and original_C0_Saved then
            -- Remet ton corps normal quand tu désactives le cheat
            rootJoint.C0 = original_C0_Saved
        end
        if savedCF then
            hrp.CFrame = savedCF
        end
    end

    local hum = c:FindFirstChildOfClass("Humanoid")
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
    if hum then
        hum.MaxHealth = 100
        hum.Health = 100
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    end
end


local function watchBrainrotAttribute()
    task.spawn(function()
        while true do
            task.wait(0.25)
            local c = player.Character
            if not c then hasBrainrot = false; continue end
            local stealing = player:GetAttribute("Stealing") or player:GetAttribute("HasBrainrot")
            local brainrotInChar = false
            if c then
                for _, tool in ipairs(c:GetChildren()) do
                    if tool:IsA("Tool") then
                        local ad = Animals and Animals[tool.Name]
                        if ad then brainrotInChar = true; break end
                    end
                end
            end
            local newState = (stealing == true) or brainrotInChar
            if newState ~= hasBrainrot then
                hasBrainrot = newState
                if ZyraSettings.SpeedSteal then
                    if hasBrainrot then startSpeedSteal() end
                end
                -- if config.autoSteal then (Disabled auto invis activation)
                --    if hasBrainrot then startInvis() else stopInvis() end
                -- end
            end
        end
    end)
end
watchBrainrotAttribute()

local function blockPlayerDirect(targetPlayer)
    if not targetPlayer then return end
    task.spawn(function()
        pcall(function() StarterGui:SetCore("PromptBlockPlayer", targetPlayer) end)
        fastClickBlock()
    end)
end

local function blockFromPlot(plot)
    if not plot then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then blockPlayerDirect(p) return end
    end
end

local function setStealBtnState(active)
    if not stealBtn then return end
    if active then
        stealBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        stealBtn.Text             = "STOP"
        if statusDot then statusDot.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end
    else
        stealBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 60)
        stealBtn.Text             = "AUTO STEAL"
        if statusDot then statusDot.BackgroundColor3 = Color3.fromRGB(160, 80, 255) end
    end
end

local function addProtection()
    local char = player.Character
    if not char then return nil end
    local old = char:FindFirstChildWhichIsA("ForceField")
    if old then old:Destroy() end
    local ff = Instance.new("ForceField")
    ff.Visible = false
    ff.Parent  = char
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.PlatformStand = true
        hum.AutoRotate    = false
        if godModeConnection then godModeConnection:Disconnect() end
        godModeConnection = hum.HealthChanged:Connect(function(newHealth)
            if newHealth < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end)
    end
    return ff
end

local function removeProtection(ff)
    if ff and ff.Parent then ff:Destroy() end
    if godModeConnection then godModeConnection:Disconnect() godModeConnection = nil end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false hum.AutoRotate = true end
end

local function getMutMod(n)
    if not n or n == "" then return 0 end
    local m = Mutations[n]
    return type(m) == "table" and (m.Modifier or 0) or 0
end

local function getTraitMod(n)
    if not n or n == "" then return 0 end
    local t = Traits[n]
    return type(t) == "table" and (t.MultiplierModifier or 0) or 0
end

local function getPPS(animalName, mut, trait)
    local d = Animals[animalName]
    if not d then return 0 end
    return (d.Generation or 0) * (1 + getMutMod(mut) + getTraitMod(trait))
end

local function fmt(n)
    n = math.ceil(n)
    if n >= 1e12 then return string.format("$%.1fT", n/1e12)
    elseif n >= 1e9  then return string.format("$%.1fB", n/1e9)
    elseif n >= 1e6  then return string.format("$%.1fM", n/1e6)
    elseif n >= 1e3  then return string.format("$%.1fK", n/1e3)
    else return string.format("$%d", n) end
end

local rarityColors = {
    Common           = Color3.fromRGB(180, 180, 180),
    Uncommon         = Color3.fromRGB(100, 220, 100),
    Rare             = Color3.fromRGB(80, 150, 255),
    Epic             = Color3.fromRGB(180, 100, 255),
    Legendary        = Color3.fromRGB(255, 180, 0),
    Secret           = Color3.fromRGB(255, 80, 80),
    Mythic           = Color3.fromRGB(255, 50, 50),
    Mythical         = Color3.fromRGB(255, 80, 80),
    Godly            = Color3.fromRGB(255, 255, 255),
    Special          = Color3.fromRGB(255, 100, 200),
    ["Brainrot God"] = Color3.fromRGB(255, 100, 0),
}

local function isPlotLocked(plot)
    if not plot then return true end
    local bb = nil
    local mainPart = plot:FindFirstChild("Main") or plot.PrimaryPart
    if mainPart then
        bb = mainPart:FindFirstChildWhichIsA("BillboardGui")
    end
    if not bb then
        bb = plot:FindFirstChildWhichIsA("BillboardGui", true)
    end
    if not bb then return true end
    local statusLabel = bb:FindFirstChild("Locked")
                     or bb:FindFirstChild("Status")
                     or bb:FindFirstChild("Text")
                     or bb:FindFirstChildWhichIsA("TextLabel")
    if not statusLabel or not statusLabel:IsA("TextLabel") then return true end
    local text  = statusLabel.Text or ""
    local lower = text:lower()
    if lower:find("owner") or lower:find("owned by") or lower:find("yours") then
        return false
    end
    local locked = statusLabel.Visible and (
        lower:find("lock") or lower:find("claim") or lower:find("buy")
        or lower:find("purchase") or lower:find("cost") or text == ""
    )
    return locked and true or false
end

local function isAlive()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0
end

local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getModelPos(model)
    if model.PrimaryPart then return model.PrimaryPart.Position end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then return p.Position end
    end
    return nil
end

local function getFloor(pos)
    if pos.Y < 20 then return 1 elseif pos.Y < 40 then return 2 else return 3 end
end

local function equipItem(name)
    local bp = player.Backpack
    local c  = player.Character
    if not bp or not c then return nil end
    local item = bp:FindFirstChild(name)
    if item then
        item.Parent = c
        -- Simple retry loop for reliability
        task.spawn(function()
            for i = 1, 5 do
                if item.Parent == c then break end
                item.Parent = c
                task.wait(0.05)
            end
        end)
    end
    return item
end

local function unequipAll()
    local c  = player.Character
    local bp = player.Backpack
    if not c or not bp then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then t.Parent = bp end
    end
end

local function carpetTp(pos, keep)
    local root = getRoot()
    if not root then return false end
    equipItem("Flying Carpet")
    task.wait(0.08)
    root = getRoot()
    if not root then return false end
    root.AssemblyLinearVelocity = Vector3.new()
    root.CFrame = CFrame.new(pos)
    task.wait(0.15)
    if not keep then unequipAll() task.wait(0.08) end
    return true
end

local function holdPos(standPos, lookAt, dur)
    local deadline = tick() + dur
    while tick() < deadline do
        local root = getRoot()
        if not root then return end
        root.AssemblyLinearVelocity = Vector3.new()
        root.CFrame = CFrame.new(standPos, lookAt)
        task.wait(0.025)
    end
end

local function getMyPlot()
    local Plots = workspace:FindFirstChild("Plots")
    if not Plots then return nil end
    for _, plot in ipairs(Plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local ok, lbl = pcall(function() return sign.SurfaceGui.Frame.TextLabel end)
            if ok and lbl and lbl.Text:find(player.Name, 1, true) then return plot end
        end
    end
    return nil
end

local function brainrotIsInOurBase(animalName)
    local c = player.Character
    if c then
        for _, child in ipairs(c:GetChildren()) do
            if child:IsA("Tool") and child.Name == animalName then
                return true
            end
        end
    end
    if myPlotModel and myPlotModel.Parent then
        for _, child in ipairs(myPlotModel:GetChildren()) do
            if child.Name == animalName then
                return true
            end
        end
    end
    local bp = player.Backpack
    if bp then
        for _, child in ipairs(bp:GetChildren()) do
            if child:IsA("Tool") and child.Name == animalName then
                return true
            end
        end
    end
    return false
end

local function getPlotOwnerDisplayName(plot)
    if not plot then return nil end
    local ok, lbl = pcall(function() return plot.PlotSign.SurfaceGui.Frame.TextLabel end)
    if not ok or not lbl then return nil end
    local text = lbl.Text or ""
    if text == "" then return nil end
    local displayName = text:match("^(.+)'s%s+[Bb]ase$") or text:match("^(.+)'s%s+")
    return displayName and displayName:match("^%s*(.-)%s*$") or nil
end

local function findPlayerByDisplayName(displayName)
    if not displayName or displayName == "" then return nil end
    local dn_lower = displayName:lower():match("^%s*(.-)%s*$")
    if dn_lower == "" then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local pdn = p.DisplayName:lower():match("^%s*(.-)%s*$")
            local pn  = p.Name:lower():match("^%s*(.-)%s*$")
            if pdn == dn_lower or pn == dn_lower then return p end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local pdn = p.DisplayName:lower()
            if pdn:find(dn_lower, 1, true) or dn_lower:find(pdn, 1, true) then return p end
        end
    end
    return nil
end

local function isPlotOwnerOnline(plot)
    local displayName = getPlotOwnerDisplayName(plot)
    if not displayName then return true end
    local dn_lower = displayName:lower():match("^%s*(.-)%s*$")
    for _, p in ipairs(Players:GetPlayers()) do
        local pdn = p.DisplayName:lower():match("^%s*(.-)%s*$")
        local pn  = p.Name:lower():match("^%s*(.-)%s*$")
        if pdn == dn_lower or pn == dn_lower then return true end
        if pdn:find(dn_lower, 1, true) or dn_lower:find(pdn, 1, true) then return true end
    end
    return false
end

local function startBlockWatch(entry) end

local function doScan()
    local results    = {}
    local seenModels = {}
    local seenKeys   = {}
    local Plots      = workspace:FindFirstChild("Plots")
    if not Plots then return results end
    local myPlot = getMyPlot()

    local myChar = player.Character
    local myBp   = player.Backpack

    for _, plot in ipairs(Plots:GetChildren()) do
        if plot == myPlot then continue end
        if not isPlotOwnerOnline(plot) then continue end

        local stealablePodiums = {}
        local podiumsFolder    = plot:FindFirstChild("AnimalPodiums")
        if podiumsFolder then
            for _, podium in ipairs(podiumsFolder:GetChildren()) do
                local base  = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                local pa    = spawn and spawn:FindFirstChild("PromptAttachment")
                if not pa then continue end

                local hasSteal = false
                for _, obj in ipairs(pa:GetChildren()) do
                    if obj:IsA("ProximityPrompt") then
                        if obj:GetAttribute("State") == "Steal" then hasSteal = true; break end
                    end
                end
                if not hasSteal then continue end

                local podPos = nil
                for _, child in ipairs(spawn:GetChildren()) do
                    if child:IsA("BasePart") then podPos = child.Position; break end
                end
                if not podPos then
                    for _, desc in ipairs(podium:GetDescendants()) do
                        if desc:IsA("BasePart") then podPos = desc.Position; break end
                    end
                end
                if podPos then
                    table.insert(stealablePodiums, { pos = podPos, podium = podium })
                end
            end
        end

        for _, br in ipairs(plot:GetChildren()) do
            if br.Name == "AnimalPodiums" then continue end
            if not br:IsA("Model")         then continue end
            if seenModels[br]              then continue end

            if myPlotModel and br:IsDescendantOf(myPlotModel) then continue end
            if myChar and br:IsDescendantOf(myChar) then continue end
            if myBp   and br:IsDescendantOf(myBp)   then continue end

            local ad = Animals[br.Name]
            if not ad then continue end

            local brPos = getModelPos(br)
            if not brPos then continue end

            local matchedPodPos = nil
            local bestDist2     = math.huge
            for _, sp in ipairs(stealablePodiums) do
                local dx = brPos.X - sp.pos.X
                local dz = brPos.Z - sp.pos.Z
                local d2 = dx*dx + dz*dz
                if d2 < bestDist2 then
                    bestDist2     = d2
                    matchedPodPos = sp.pos
                end
            end
            if not matchedPodPos or bestDist2 > 100 then continue end

            local mut   = br:GetAttribute("Mutation") or ""
            local trait = br:GetAttribute("Traits")   or ""

            local dedupeKey = plot.Name .. "|" .. br.Name .. "|" .. mut .. "|" .. trait
            if seenKeys[dedupeKey] then continue end
            seenKeys[dedupeKey] = true

            local pps = getPPS(br.Name, mut, trait)

            seenModels[br] = true

            table.insert(results, {
                name      = br.Name,
                rarity    = ad.Rarity or "Common",
                mutation  = mut,
                trait     = trait,
                pps       = pps,
                model     = br,
                plot      = plot,
                podiumPos = matchedPodPos,
            })
        end
    end

    table.sort(results, function(a, b) return a.pps > b.pps end)
    lastScanResults = results
    bestEntry       = #results > 0 and results[1] or nil

    if lockedEntry then
        local ownerOnline = lockedEntry.plot and isPlotOwnerOnline(lockedEntry.plot)
        if not ownerOnline then
            lockedEntry       = nil
            cachedStealPrompt = nil
            if isAutoSteal then
                isAutoSteal  = false
                isWorking    = false
                stealSession = stealSession + 1
                setStealBtnState(false)
                if stealStatusLabel then
                    stealStatusLabel.Text       = "Target disconnected — auto-selecting new target"
                    stealStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                end
            end
        end
    end

    return results
end

local function isStealPrompt(obj)
    if not obj:IsA("ProximityPrompt") then return false end
    local txt = (obj.ActionText or ""):lower()
    return txt:find("steal") or txt:find("take") or txt:find("rob")
end

local function isPromptOfEntry(obj, entry)
    if not entry then return false end
    local objText = (obj.ObjectText or ""):lower()
    if objText ~= "" then
        if objText:find(entry.name:lower(), 1, true) then return true end
        if entry.mutation ~= "" and objText:find(entry.mutation:lower(), 1, true)
            and objText:find(entry.name:lower(), 1, true) then return true end
    end
    local ancestor = obj.Parent
    while ancestor and ancestor ~= workspace do
        if ancestor == entry.model then return true end
        if ancestor.Name == entry.name and entry.plot
            and ancestor:IsDescendantOf(entry.plot) then return true end
        ancestor = ancestor.Parent
    end
    if entry.plot and obj:IsDescendantOf(entry.plot) then
        local par = obj.Parent
        while par and par ~= entry.plot do
            if par:IsA("Model") then return par == entry.model end
            par = par.Parent
        end
        return true
    end
    return false
end

local function armPrompt(prompt)
    prompt.HoldDuration          = 0
    prompt.MaxActivationDistance = 9999
    prompt.RequiresLineOfSight   = false
    prompt.Enabled               = true
end

local function fireNow(prompt)
    if not isAutoSteal then return end
    if not prompt or not prompt:IsDescendantOf(workspace) then return end
    armPrompt(prompt)
    pcall(fireproximityprompt, prompt)
    if stealStatusLabel then
        stealStatusLabel.Text       = "Executing steal..."
        stealStatusLabel.TextColor3 = Color3.fromRGB(140, 255, 180)
    end
end

local function registerPrompt(prompt)
    if cachedStealPrompt == prompt then return end
    cachedStealPrompt = prompt
    armPrompt(prompt)
    fireNow(prompt)
    prompt.PromptShown:Connect(function()
        if cachedStealPrompt == prompt then fireNow(prompt) end
    end)
    prompt.PromptButtonHoldBegan:Connect(function(plr)
        if plr == player and cachedStealPrompt == prompt then fireNow(prompt) end
    end)
    prompt.AncestryChanged:Connect(function()
        if not prompt:IsDescendantOf(workspace) then
            if cachedStealPrompt == prompt then cachedStealPrompt = nil end
        end
    end)
end

local function findAndCachePrompt(entry)
    if not entry then cachedStealPrompt = nil return end
    if cachedStealPrompt and cachedStealPrompt:IsDescendantOf(workspace)
        and isPromptOfEntry(cachedStealPrompt, entry) then return end
    cachedStealPrompt = nil
    if entry.model and entry.model:IsDescendantOf(workspace) then
        for _, obj in ipairs(entry.model:GetDescendants()) do
            if isStealPrompt(obj) then registerPrompt(obj) return end
        end
    end
    if entry.plot and entry.plot:IsDescendantOf(workspace) then
        for _, obj in ipairs(entry.plot:GetDescendants()) do
            if isStealPrompt(obj) and isPromptOfEntry(obj, entry) then
                registerPrompt(obj) return
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isStealPrompt(obj) and isPromptOfEntry(obj, entry) then
            registerPrompt(obj) return
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if not isStealPrompt(obj) then return end
    if not isAutoSteal then return end
    if not lockedEntry then return end
    local inModel = lockedEntry.model and obj:IsDescendantOf(lockedEntry.model)
    local inPlot  = lockedEntry.plot  and obj:IsDescendantOf(lockedEntry.plot)
    if inModel or (inPlot and isPromptOfEntry(obj, lockedEntry)) then
        registerPrompt(obj)
    end
end)

local function addESPFor(entry)
    local model = entry.model
    if not model or not model:IsDescendantOf(workspace) then return end
    if espBillboards[model] then espBillboards[model]:Destroy() end
    local adornPart = model.PrimaryPart
    if not adornPart then
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then adornPart = p break end
        end
    end
    if not adornPart then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_BB" bb.Adornee = adornPart
    bb.Size = UDim2.new(0, 150, 0, 58) bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true bb.ResetOnSpawn = false bb.LightInfluence = 0
    bb.Parent = adornPart
    local bg = Instance.new("Frame", bb)
    bg.Size = UDim2.new(1, 0, 1, 0) bg.BackgroundColor3 = Color3.fromRGB(10, 5, 20)
    bg.BackgroundTransparency = 0.3 bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 7)
    local accent = Instance.new("Frame", bg)
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = rarityColors[entry.rarity] or Color3.fromRGB(160, 80, 255)
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 7)
    local grad = Instance.new("UIGradient", bg)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 10, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 5,  25)),
    })
    grad.Rotation = 45
    local displayName = entry.mutation ~= "" and (entry.mutation.." "..entry.name) or entry.name
    local nameLbl = Instance.new("TextLabel", bg)
    nameLbl.Size = UDim2.new(1, -16, 0, 22) nameLbl.Position = UDim2.new(0, 12, 0, 3)
    nameLbl.BackgroundTransparency = 1 nameLbl.Text = displayName
    nameLbl.TextColor3 = Color3.fromRGB(230, 210, 255) nameLbl.TextScaled = true
    nameLbl.Font = Enum.Font.GothamBold nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    local rarityLbl = Instance.new("TextLabel", bg)
    rarityLbl.Size = UDim2.new(1, -16, 0, 14) rarityLbl.Position = UDim2.new(0, 12, 0, 25)
    rarityLbl.BackgroundTransparency = 1 rarityLbl.Text = entry.rarity
    rarityLbl.TextColor3 = rarityColors[entry.rarity] or Color3.fromRGB(200, 200, 200)
    rarityLbl.TextScaled = true rarityLbl.Font = Enum.Font.Gotham
    rarityLbl.TextXAlignment = Enum.TextXAlignment.Left
    local ppsLbl = Instance.new("TextLabel", bg)
    ppsLbl.Size = UDim2.new(1, -16, 0, 14) ppsLbl.Position = UDim2.new(0, 12, 0, 40)
    ppsLbl.BackgroundTransparency = 1 ppsLbl.Text = fmt(entry.pps).."/s"
    ppsLbl.TextColor3 = Color3.fromRGB(180, 120, 255) ppsLbl.TextScaled = true
    ppsLbl.Font = Enum.Font.GothamBold ppsLbl.TextXAlignment = Enum.TextXAlignment.Left
    espBillboards[model] = bb
end

local function refreshESP()
    for model, bb in pairs(espBillboards) do
        if not model:IsDescendantOf(workspace) then bb:Destroy() espBillboards[model] = nil end
    end
    if not ZyraSettings.EspEnabled then return end
    for _, entry in ipairs(lastScanResults) do
        if entry.model:IsDescendantOf(workspace) and not espBillboards[entry.model] then
            addESPFor(entry)
        end
    end
end

local function clearAllESP()
    for model, bb in pairs(espBillboards) do bb:Destroy() espBillboards[model] = nil end
end

local function clearEspHighest()
    if espHighestBB then espHighestBB:Destroy() espHighestBB = nil end
end

local function refreshEspHighest()
    clearEspHighest()
    if not ZyraSettings.EspHighest then return end
    local entry = lastScanResults[1]
    if not entry then return end
    local model = entry.model
    if not model or not model:IsDescendantOf(workspace) then return end
    local adornPart = model.PrimaryPart
    if not adornPart then
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then adornPart = p break end
        end
    end
    if not adornPart then return end
    local rarityColor = rarityColors[entry.rarity] or Color3.fromRGB(255, 200, 0)
    local displayName = entry.mutation ~= "" and (entry.mutation.." "..entry.name) or entry.name
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_HIGHEST_BB" bb.Adornee = adornPart
    bb.Size = UDim2.new(0, 190, 0, 76) bb.StudsOffset = Vector3.new(0, 7, 0)
    bb.AlwaysOnTop = true bb.ResetOnSpawn = false bb.LightInfluence = 0
    bb.Parent = adornPart
    local bg = Instance.new("Frame", bb)
    bg.Size = UDim2.new(1, 0, 1, 0) bg.BackgroundColor3 = Color3.fromRGB(10, 5, 20)
    bg.BackgroundTransparency = 0.2 bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    local grad = Instance.new("UIGradient", bg)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 12, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 4,  22)),
    })
    grad.Rotation = 45
    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = rarityColor stroke.Thickness = 2 stroke.Transparency = 0
    local accent = Instance.new("Frame", bg)
    accent.Size = UDim2.new(0, 3, 1, 0) accent.BackgroundColor3 = rarityColor
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 8)
    local nameLbl = Instance.new("TextLabel", bg)
    nameLbl.Size = UDim2.new(1, -16, 0, 22) nameLbl.Position = UDim2.new(0, 10, 0, 6)
    nameLbl.BackgroundTransparency = 1 nameLbl.Text = displayName
    nameLbl.TextColor3 = Color3.fromRGB(235, 215, 255) nameLbl.TextScaled = true
    nameLbl.Font = Enum.Font.GothamBold nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    local rarityLbl = Instance.new("TextLabel", bg)
    rarityLbl.Size = UDim2.new(1, -16, 0, 13) rarityLbl.Position = UDim2.new(0, 10, 0, 46)
    rarityLbl.BackgroundTransparency = 1 rarityLbl.Text = entry.rarity
    rarityLbl.TextColor3 = rarityColor rarityLbl.TextScaled = true
    rarityLbl.Font = Enum.Font.Gotham rarityLbl.TextXAlignment = Enum.TextXAlignment.Left
    local ppsLbl = Instance.new("TextLabel", bg)
    ppsLbl.Size = UDim2.new(1, -16, 0, 13) ppsLbl.Position = UDim2.new(0, 10, 0, 60)
    ppsLbl.BackgroundTransparency = 1 ppsLbl.Text = fmt(entry.pps).."/s"
    ppsLbl.TextColor3 = Color3.fromRGB(180, 120, 255) ppsLbl.TextScaled = true
    ppsLbl.Font = Enum.Font.GothamBold ppsLbl.TextXAlignment = Enum.TextXAlignment.Left
    task.spawn(function()
        local t = 0
        while bb and bb.Parent do
            t += 0.05
            stroke.Transparency = 0.2 + 0.6 * math.abs(math.sin(t * 2))
            task.wait(0.05)
        end
    end)
    espHighestBB = bb
end

local PLOT_DISTANCE_MAX = 2000

local function createPlotESP(plot)
    if not plot:IsA("Model") then return end
    local billboard = plot:FindFirstChildWhichIsA("BillboardGui", true)
    if not billboard then
        local mainPart = plot:FindFirstChild("Main") or plot.PrimaryPart
        if mainPart then billboard = mainPart:FindFirstChildWhichIsA("BillboardGui") end
    end
    if not billboard or not billboard:IsA("BillboardGui") then return end
    billboard.Enabled        = true
    billboard.AlwaysOnTop    = true
    billboard.MaxDistance    = PLOT_DISTANCE_MAX
    billboard.Size           = UDim2.new(10, 0, 3, 0)
    billboard.StudsOffset    = Vector3.new(0, 5, 0)
    billboard.ResetOnSpawn   = false
    billboard.LightInfluence = 0
    billboard.Adornee        = billboard.Adornee or plot.PrimaryPart or plot:FindFirstChild("Main")
    local statusLabel = billboard:FindFirstChild("Locked")
                     or billboard:FindFirstChild("Status")
                     or billboard:FindFirstChild("Text")
                     or billboard:FindFirstChildWhichIsA("TextLabel")
    if not statusLabel or not statusLabel:IsA("TextLabel") then return end
    local origTextTransp   = statusLabel.TextTransparency
    local origStrokeTransp = statusLabel.TextStrokeTransparency
    statusLabel.TextTransparency       = 1
    statusLabel.TextStrokeTransparency = 1
    local espContainer = billboard:FindFirstChild("PlotESPContainer")
    if not espContainer then
        espContainer = Instance.new("Frame")
        espContainer.Name                   = "PlotESPContainer"
        espContainer.Size                   = UDim2.new(0.55, 0, 0.72, 0)
        espContainer.Position               = UDim2.new(0.225, 0, 0.14, 0)
        espContainer.BackgroundColor3       = Color3.fromRGB(15, 15, 18)
        espContainer.BackgroundTransparency = 0.15
        espContainer.BorderSizePixel        = 0
        espContainer.ZIndex                 = 9
        espContainer.Parent                 = billboard
        Instance.new("UICorner", espContainer).CornerRadius = UDim.new(0.18, 0)
    end
    local espContainerStroke = espContainer:FindFirstChildWhichIsA("UIStroke")
    if not espContainerStroke then
        espContainerStroke              = Instance.new("UIStroke", espContainer)
        espContainerStroke.Thickness    = 3
        espContainerStroke.Transparency = 0
    end
    local espLabel = billboard:FindFirstChild("PlotStatusESP")
    if not espLabel then
        espLabel = Instance.new("TextLabel")
        espLabel.Name                   = "PlotStatusESP"
        espLabel.Size                   = UDim2.new(1, 0, 1, 0)
        espLabel.BackgroundTransparency = 1
        espLabel.TextScaled             = true
        espLabel.Font                   = Enum.Font.GothamBold
        espLabel.TextXAlignment         = Enum.TextXAlignment.Center
        espLabel.TextYAlignment         = Enum.TextYAlignment.Center
        espLabel.TextStrokeTransparency = 0
        espLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        espLabel.ZIndex                 = 10
        espLabel.Parent                 = espContainer
    end
    local function updateStatus()
        if not espLabel or not espLabel.Parent then return end
        local text  = statusLabel.Text or ""
        local lower = text:lower()
        local isLocked = statusLabel.Visible and (
            lower:find("lock") or lower:find("claim") or lower:find("buy")
            or lower:find("purchase") or lower:find("for %%$")
            or lower:find("cost") or text == ""
        )
        if lower:find("owner") or lower:find("owned by") or lower:find("yours") then isLocked = false end
        if isLocked then
            espLabel.Text                 = "LOCKED"
            espLabel.TextColor3           = Color3.fromRGB(255, 80, 80)
            espLabel.TextStrokeColor3     = Color3.fromRGB(100, 0, 0)
            espContainerStroke.Color      = Color3.fromRGB(220, 40, 40)
            espContainer.BackgroundColor3 = Color3.fromRGB(35, 5, 5)
        else
            espLabel.Text                 = "UNLOCKED"
            espLabel.TextColor3           = Color3.fromRGB(80, 255, 130)
            espLabel.TextStrokeColor3     = Color3.fromRGB(0, 80, 30)
            espContainerStroke.Color      = Color3.fromRGB(40, 220, 100)
            espContainer.BackgroundColor3 = Color3.fromRGB(5, 30, 10)
        end
    end
    task.spawn(updateStatus)
    task.spawn(function()
        local t = 0
        while espContainer and espContainer.Parent and espPlotsEnabled do
            t += 0.05
            espContainerStroke.Transparency = 0.1 + 0.5 * math.abs(math.sin(t * 2.2))
            task.wait(0.05)
        end
    end)
    local c1 = statusLabel:GetPropertyChangedSignal("Visible"):Connect(updateStatus)
    local c2 = statusLabel:GetPropertyChangedSignal("Text"):Connect(updateStatus)
    local c3 = statusLabel:GetPropertyChangedSignal("TextTransparency"):Connect(updateStatus)
    table.insert(espPlotsConnections, c1)
    table.insert(espPlotsConnections, c2)
    table.insert(espPlotsConnections, c3)
    task.spawn(function()
        while espLabel and espLabel.Parent and ZyraSettings.EspPlots do
            updateStatus()
            task.wait(1.5)
        end
        if espLabel     and espLabel.Parent     then espLabel:Destroy() end
        if espContainer and espContainer.Parent then espContainer:Destroy() end
        if statusLabel  and statusLabel.Parent  then
            statusLabel.TextTransparency       = origTextTransp
            statusLabel.TextStrokeTransparency = origStrokeTransp
        end
        if billboard and billboard.Parent then
            billboard.AlwaysOnTop = false
            billboard.MaxDistance = 100
        end
    end)
end

local function enableEspPlots()
    local PlotsFolder = workspace:FindFirstChild("Plots")
    if not PlotsFolder then warn("[ZyraHub] Plots folder not found") return end
    for _, plot in ipairs(PlotsFolder:GetChildren()) do task.spawn(createPlotESP, plot) end
    local conn = PlotsFolder.ChildAdded:Connect(function(child)
        if ZyraSettings.EspPlots then task.delay(0.8, createPlotESP, child) end
    end)
    table.insert(espPlotsConnections, conn)
end

local function disableEspPlots()
    for _, c in ipairs(espPlotsConnections) do pcall(function() c:Disconnect() end) end
    espPlotsConnections = {}
    local PlotsFolder = workspace:FindFirstChild("Plots")
    if PlotsFolder then
        for _, descendant in ipairs(PlotsFolder:GetDescendants()) do
            if descendant:IsA("Frame") and descendant.Name == "PlotESPContainer" then
                local bb = descendant.Parent
                descendant:Destroy()
                if bb and bb:IsA("BillboardGui") then
                    bb.AlwaysOnTop = false
                    bb.MaxDistance = 100
                    local orig = bb:FindFirstChildWhichIsA("TextLabel")
                    if orig then
                        orig.TextTransparency       = 0
                        orig.TextStrokeTransparency = 0
                    end
                end
            end
        end
    end
end

local DECOR_TRANSPARENCY = 0.55
local function makeDecorationsSemiTransparent(plot)
    if not plot then return end
    local decorations = plot:FindFirstChild("Decorations")
    if not decorations then return end
    for _, obj in ipairs(decorations:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
            obj.Transparency = DECOR_TRANSPARENCY
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = DECOR_TRANSPARENCY
                end
            end
        end
    end
end

local function makeAllPlotsSemiTransparent()
    local Plots = workspace:FindFirstChild("Plots")
    if not Plots then return end
    for _, plot in ipairs(Plots:GetChildren()) do makeDecorationsSemiTransparent(plot) end
end

task.spawn(function()
    makeAllPlotsSemiTransparent()
    while true do task.wait(3) makeAllPlotsSemiTransparent() end
end)

local function fullStop(msg, color, clearTarget)
    isAutoSteal       = false
    isWorking         = false
    isTeleporting     = false
    stealSession      = stealSession + 1
    cachedStealPrompt = nil
    if clearTarget then lockedEntry = nil end
    if godModeConnection then godModeConnection:Disconnect() godModeConnection = nil end
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false hum.AutoRotate = true end
        local ff = char:FindFirstChildWhichIsA("ForceField")
        if ff then ff:Destroy() end
    end
    setStealBtnState(false)
    if stealStatusLabel then
        stealStatusLabel.Text       = msg or "Stopped"
        stealStatusLabel.TextColor3 = color or Color3.fromRGB(150, 150, 150)
    end
end

local function equipCloner()
    local c = player.Character
    local b = player.Backpack
    if not c or not b then return false end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then t.Parent = b end
    end
    local cloner = b:FindFirstChild("Quantum Cloner")
    if not cloner then
        if stealStatusLabel then
            stealStatusLabel.Text       = "Quantum Cloner not found in backpack"
            stealStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
        return false
    end
    cloner.Parent = c
    return true
end

local function grabEntry(entry)
    if not entry then return end
    if not entry.model or not entry.model:IsDescendantOf(workspace) then return end
    findAndCachePrompt(entry)
    if cachedStealPrompt then
        fireNow(cachedStealPrompt)
    else
        for _, obj in ipairs(entry.model:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                armPrompt(obj)
                pcall(fireproximityprompt, obj)
                break
            end
        end
    end
end

local function runAutoSteal()
    if isWorking       then return end
    if not lockedEntry then return end
    if not isAlive()   then return end
    if not isAutoSteal then return end

    isWorking = true
    local mySession = stealSession
    local entry     = lockedEntry

    local function alive()
        return isAutoSteal and stealSession == mySession and lockedEntry == entry
    end

    findAndCachePrompt(entry)

    local brainrotPos = getModelPos(entry.model)
    local floor       = brainrotPos and getFloor(brainrotPos) or 2
    local baseCoords  = getNearestBaseCoords(entry.plot)

    if floor == 1 then
        if not alive() then isWorking = false return end
        local targetPos = (baseCoords and baseCoords.floor1) or Vector3.new(entry.plot:GetPivot().Position.X, -3.85, entry.plot:GetPivot().Position.Z)
        local plotLocked = isPlotLocked(entry.plot)

        if not plotLocked then
            if stealStatusLabel then
                stealStatusLabel.Text       = "Floor 1  ·  Unlocked — teleporting..."
                stealStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 150)
            end
            if not carpetTp(targetPos, true) then
                if stealSession == mySession then fullStop("Teleport failed", Color3.fromRGB(255, 80, 80), true) end
                return
            end
            if not alive() then isWorking = false return end
            unequipAll()
            if stealStatusLabel then
                stealStatusLabel.Text       = "Floor 1  ·  Stealing "..entry.name.."..."
                stealStatusLabel.TextColor3 = Color3.fromRGB(140, 255, 180)
            end
            task.wait(CFG.TP_WAIT)
            grabEntry(entry)
        else
            if stealStatusLabel then
                stealStatusLabel.Text       = "Floor 1  ·  Teleporting..."
                stealStatusLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
            end
            if not carpetTp(targetPos, true) then
                if stealSession == mySession then fullStop("Teleport failed", Color3.fromRGB(255, 80, 80), true) end
                return
            end
            if not alive() then isWorking = false return end
            if stealStatusLabel then
                stealStatusLabel.Text       = "Floor 1  ·  Stabilizing..."
                stealStatusLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
            end
            local protection = addProtection()
            local root = getRoot()
            if root then
                local stabPos = root.Position
                local stabTarget = entry.plot:GetPivot().Position
                holdPos(stabPos, Vector3.new(stabTarget.X, stabPos.Y, stabTarget.Z), 1.5)
                if not alive() then removeProtection(protection) isWorking = false return end
                if stealStatusLabel then
                    stealStatusLabel.Text       = "Floor 1  ·  Equipping Cloner..."
                    stealStatusLabel.TextColor3 = Color3.fromRGB(160, 100, 255)
                end
                if not equipCloner() then
                    removeProtection(protection)
                    if stealSession == mySession then fullStop("Cloner not found", Color3.fromRGB(255, 80, 80), true) end
                    return
                end
                removeProtection(protection)
            end
            if not alive() then isWorking = false return end
            if stealStatusLabel then
                stealStatusLabel.Text       = "Floor 1  ·  Stealing "..entry.name.."..."
                stealStatusLabel.TextColor3 = Color3.fromRGB(140, 255, 180)
            end
            task.wait(CFG.TP_WAIT)
            grabEntry(entry)
        end
    else
        if not alive() then isWorking = false return end
        if stealStatusLabel then
            stealStatusLabel.Text       = "Launching..."
            stealStatusLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
        end
        local root = getRoot()
        if not root then isWorking = false return end
        equipItem("Coil Combo")
        task.wait(0.05)
        root = getRoot()
        if root then root.AssemblyLinearVelocity = Vector3.new(0, 80, 0) end
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.Jump = true end
        local waited = 0
        repeat
            task.wait(0.05) waited += 0.05 root = getRoot()
        until (root and root.Position.Y >= CFG.CARPET_HEIGHT) or waited >= 4 or not alive()
        unequipAll() task.wait(0.05)
        if not alive() then isWorking = false return end
        if stealStatusLabel then
            stealStatusLabel.Text       = "Locking altitude..."
            stealStatusLabel.TextColor3 = Color3.fromRGB(190, 140, 255)
        end
        root = getRoot()
        if not root then isWorking = false return end
        carpetTp(Vector3.new(root.Position.X, CFG.CARPET_HEIGHT, root.Position.Z), true)
        if not alive() then isWorking = false return end
        if stealStatusLabel then
            stealStatusLabel.Text       = "Positioning..."
            stealStatusLabel.TextColor3 = Color3.fromRGB(180, 120, 255)
        end
        local protection = addProtection()
        local decoPos = (baseCoords and baseCoords.floor2) or Vector3.new(entry.plot:GetPivot().Position.X, CFG.CARPET_HEIGHT, entry.plot:GetPivot().Position.Z)
        carpetTp(Vector3.new(decoPos.X, CFG.CARPET_HEIGHT, decoPos.Z), true)
        if not alive() then removeProtection(protection) isWorking = false return end
        root = getRoot()
        if not root then removeProtection(protection) isWorking = false return end
        if stealStatusLabel then
            stealStatusLabel.Text       = "Stabilizing..."
            stealStatusLabel.TextColor3 = Color3.fromRGB(170, 110, 255)
        end
        holdPos(root.Position, Vector3.new(entry.plot:GetPivot().Position.X, root.Position.Y, entry.plot:GetPivot().Position.Z), 1.5)
        if not alive() then removeProtection(protection) isWorking = false return end
        if stealStatusLabel then
            stealStatusLabel.Text       = "Equipping Cloner..."
            stealStatusLabel.TextColor3 = Color3.fromRGB(160, 100, 255)
        end
        if not equipCloner() then
            removeProtection(protection)
            if stealSession == mySession then fullStop("Cloner not found", Color3.fromRGB(255, 80, 80), true) end
            return
        end
        removeProtection(protection)
        if not alive() then isWorking = false return end
        if stealStatusLabel then
            stealStatusLabel.Text       = "Stealing "..entry.name.."..."
            stealStatusLabel.TextColor3 = Color3.fromRGB(140, 255, 180)
        end
        task.wait(CFG.TP_WAIT)
        grabEntry(entry)
    end

    local w = tick()
    while alive() and tick() - w < 10 do
        task.wait(0.1)
        if not entry.model:IsDescendantOf(workspace) then
            if stealSession == mySession then
                if brainrotIsInOurBase(entry.name) then
                    stealSucceeded = true
                    instantLeave()
                    fullStop("Steal successful!", Color3.fromRGB(140, 255, 180), true)
                else
                    fullStop("Target gone", Color3.fromRGB(255, 200, 80), true)
                end
            end
            return
        end
        -- The separate throttled Heartbeat handles prompt spam
    end
    -- If still active after timeout, restart the steal procedure automatically
    if stealSession == mySession and isAutoSteal then
        isWorking = false
        if stealStatusLabel then
            stealStatusLabel.Text       = "Retrying..."
            stealStatusLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
        end
        task.spawn(runAutoSteal)
    elseif stealSession == mySession then
        fullStop("Complete", Color3.fromRGB(150, 150, 150), false)
    end
end

local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("ZyraHub") then playerGui:FindFirstChild("ZyraHub"):Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ZyraHub"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

local discordBadge = Instance.new("Frame")
discordBadge.Name             = "DiscordBadge"
discordBadge.Size             = UDim2.new(0, 240, 0, 34)
discordBadge.Position         = UDim2.new(0.5, -120, 0, 18)
discordBadge.BackgroundColor3 = Color3.fromRGB(5, 2, 13)
discordBadge.BorderSizePixel  = 0
discordBadge.Active           = false
discordBadge.Draggable        = false
discordBadge.Parent           = screenGui
Instance.new("UICorner", discordBadge).CornerRadius = UDim.new(1, 0)
local discordStroke = Instance.new("UIStroke", discordBadge)
discordStroke.Thickness = 1.5 discordStroke.Color = Color3.fromRGB(140, 60, 255) discordStroke.Transparency = 0.1
local discordGrad = Instance.new("UIGradient", discordBadge)
discordGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(45, 10, 90)),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(10, 5, 24)),
    ColorSequenceKeypoint.new(0.65, Color3.fromRGB(10, 5, 24)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(45, 10, 90)),
})
task.spawn(function()
    local rot = 0
    while discordBadge and discordBadge.Parent do
        rot = (rot + 0.8) % 360
        discordGrad.Rotation = rot
        task.wait(0.03)
    end
end)
local dcDotLeft = Instance.new("Frame")
dcDotLeft.Size = UDim2.new(0, 7, 0, 7) dcDotLeft.Position = UDim2.new(0, 14, 0.5, -3)
dcDotLeft.BackgroundColor3 = Color3.fromRGB(180, 90, 255) dcDotLeft.BorderSizePixel = 0
dcDotLeft.Parent = discordBadge
Instance.new("UICorner", dcDotLeft).CornerRadius = UDim.new(1, 0)
task.spawn(function()
    local growing = true
    while dcDotLeft and dcDotLeft.Parent do
        local target = growing and Color3.fromRGB(220, 130, 255) or Color3.fromRGB(130, 50, 200)
        TweenService:Create(dcDotLeft, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundColor3 = target}):Play()
        growing = not growing task.wait(0.8)
    end
end)
local discordText = Instance.new("TextLabel")
discordText.Size = UDim2.new(1, -50, 1, 0) discordText.Position = UDim2.new(0, 25, 0, 0)
discordText.BackgroundTransparency = 1 discordText.Text = "discord.gg/zyrahub"
discordText.TextColor3 = Color3.fromRGB(210, 170, 255) discordText.TextSize = 12
discordText.Font = Enum.Font.GothamBold discordText.TextXAlignment = Enum.TextXAlignment.Center
discordText.Parent = discordBadge
local discordTextGrad = Instance.new("UIGradient", discordText)
discordTextGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 220, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 110, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 220, 255)),
})
task.spawn(function()
    local offset = 0
    while discordText and discordText.Parent do
        offset = (offset + 0.01) % 1
        discordTextGrad.Offset = Vector2.new(math.sin(offset * math.pi * 2) * 0.3, 0)
        task.wait(0.03)
    end
end)
local dcDotRight = Instance.new("Frame")
dcDotRight.Size = UDim2.new(0, 7, 0, 7) dcDotRight.Position = UDim2.new(1, -21, 0.5, -3)
dcDotRight.BackgroundColor3 = Color3.fromRGB(180, 90, 255) dcDotRight.BorderSizePixel = 0
dcDotRight.Parent = discordBadge
Instance.new("UICorner", dcDotRight).CornerRadius = UDim.new(1, 0)
task.spawn(function()
    task.wait(0.4) local growing = true
    while dcDotRight and dcDotRight.Parent do
        local target = growing and Color3.fromRGB(220, 130, 255) or Color3.fromRGB(130, 50, 200)
        TweenService:Create(dcDotRight, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {BackgroundColor3 = target}):Play()
        growing = not growing task.wait(0.8)
    end
end)

local mainFrame = Instance.new("Frame")
mainFrame.Name             = "MainFrame"
mainFrame.Size             = UDim2.new(0, 355, 0, 652)
mainFrame.Position         = UDim2.new(0, 25, 0, 25)
mainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
mainFrame.BorderSizePixel  = 0
mainFrame.Active           = true
mainFrame.Draggable        = true
mainFrame.Parent           = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 1.2 mainStroke.Color = Color3.fromRGB(60, 25, 120) mainStroke.Transparency = 0.4

local mainGrad = Instance.new("UIGradient", mainFrame)
mainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 6, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 3, 12)),
})
mainGrad.Rotation = 45

local mainGloss = Instance.new("Frame", mainFrame)
mainGloss.Size = UDim2.new(1.8, 0, 0.6, 0)
mainGloss.Position = UDim2.new(-0.4, 0, -0.1, 0)
mainGloss.Rotation = 45
mainGloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainGloss.BackgroundTransparency = 1
mainGloss.BorderSizePixel = 0
mainGloss.ZIndex = 5
Instance.new("UICorner", mainGloss).CornerRadius = UDim.new(1, 0)

-- Gradient removed for black theme

-- Main stroke handles the border, no need for separate outerStroke
local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 64)
header.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
header.BorderSizePixel  = 0
header.Parent           = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

-- Decorative line removed for a cleaner look

    local hubLogo = Instance.new("ImageLabel")
    hubLogo.Name = "HubLogo"
    hubLogo.Size = UDim2.new(0, 48, 0, 48)
    hubLogo.Position = UDim2.new(0, 12, 0, 8)
    hubLogo.BackgroundTransparency = 1
    hubLogo.Image = "rbxthumb://type=Asset&id=95602989407601&w=420&h=420"
    hubLogo.Parent = header

local hubTitle = Instance.new("TextLabel")
hubTitle.Size = UDim2.new(1, -64, 0, 64) hubTitle.Position = UDim2.new(0, 58, 0, 0)
hubTitle.BackgroundTransparency = 1 hubTitle.Text = "ZYRA HUB"
hubTitle.TextColor3 = Color3.fromRGB(245, 245, 245) hubTitle.TextSize = 20
hubTitle.Font = Enum.Font.GothamBold hubTitle.TextXAlignment = Enum.TextXAlignment.Left
hubTitle.Parent = header

local premiumBadge = Instance.new("Frame")
premiumBadge.Size = UDim2.new(0, 85, 0, 20) premiumBadge.Position = UDim2.new(1, -100, 0, 12)
premiumBadge.BackgroundColor3 = Color3.fromRGB(160, 80, 255) premiumBadge.BorderSizePixel = 0
premiumBadge.Parent = header
Instance.new("UICorner", premiumBadge).CornerRadius = UDim.new(0, 6)
local pbGrad = Instance.new("UIGradient", premiumBadge)
pbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 50, 200)),
})

local premiumLbl = Instance.new("TextLabel")
premiumLbl.Size = UDim2.new(1, 0, 1, 0) premiumLbl.BackgroundTransparency = 1
premiumLbl.Text = "PREMIUM" premiumLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
premiumLbl.TextSize = 9 premiumLbl.Font = Enum.Font.GothamBold
premiumLbl.TextXAlignment = Enum.TextXAlignment.Center premiumLbl.TextYAlignment = Enum.TextYAlignment.Center
premiumLbl.Parent = premiumBadge

-- Private access v2 tag removed


local targetCard = Instance.new("Frame")
targetCard.Name = "TargetCard" targetCard.Size = UDim2.new(1, -24, 0, 100)
targetCard.Position = UDim2.new(0, 12, 0, 74) targetCard.BackgroundColor3 = Color3.fromRGB(10, 5, 25)
targetCard.BorderSizePixel = 0 targetCard.Parent = mainFrame
Instance.new("UICorner", targetCard).CornerRadius = UDim.new(0, 12)
local tcGrad = Instance.new("UIGradient", targetCard)
tcGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 8, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 4, 15)),
})
local tcStroke = Instance.new("UIStroke", targetCard)
tcStroke.Thickness = 1.2 tcStroke.Color = Color3.fromRGB(100, 40, 180) tcStroke.Transparency = 0.3

local targetAccent = Instance.new("Frame")
targetAccent.Name = "TargetAccent" targetAccent.Size = UDim2.new(0, 3, 1, -14)
targetAccent.Position = UDim2.new(0, 0, 0, 7) targetAccent.BackgroundColor3 = Color3.fromRGB(180, 80, 255)
targetAccent.BorderSizePixel = 0 targetAccent.Parent = targetCard
Instance.new("UICorner", targetAccent).CornerRadius = UDim.new(1, 0)
local taGrad = Instance.new("UIGradient", targetAccent)
taGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 50, 200)),
})
taGrad.Rotation = 90
local targetTag = Instance.new("TextLabel")
targetTag.Size = UDim2.new(0, 54, 0, 14) targetTag.Position = UDim2.new(0, 12, 0, 7)
targetTag.BackgroundColor3 = Color3.fromRGB(55, 18, 105) targetTag.BorderSizePixel = 0
targetTag.Text = "TARGET" targetTag.TextColor3 = Color3.fromRGB(170, 110, 255)
targetTag.TextSize = 9 targetTag.Font = Enum.Font.GothamBold
targetTag.TextXAlignment = Enum.TextXAlignment.Center targetTag.Parent = targetCard
Instance.new("UICorner", targetTag).CornerRadius = UDim.new(0, 3)
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -115, 0, 24) nameLabel.Position = UDim2.new(0, 12, 0, 26)
nameLabel.BackgroundTransparency = 1 nameLabel.Text = "No target selected"
nameLabel.TextColor3 = Color3.fromRGB(228, 210, 255) nameLabel.TextSize = 14
nameLabel.Font = Enum.Font.GothamBold nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.TextTruncate = Enum.TextTruncate.AtEnd nameLabel.Parent = targetCard
local rarityLabel = Instance.new("TextLabel")
rarityLabel.Size = UDim2.new(1, -115, 0, 14) rarityLabel.Position = UDim2.new(0, 12, 0, 51)
rarityLabel.BackgroundTransparency = 1 rarityLabel.Text = ""
rarityLabel.TextColor3 = Color3.fromRGB(180, 100, 255) rarityLabel.TextSize = 10
rarityLabel.Font = Enum.Font.Gotham rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
rarityLabel.Parent = targetCard
local traitLabel = Instance.new("TextLabel")
traitLabel.Size = UDim2.new(1, -115, 0, 12) traitLabel.Position = UDim2.new(0, 12, 0, 65)
traitLabel.BackgroundTransparency = 1 traitLabel.Text = ""
traitLabel.TextColor3 = Color3.fromRGB(255, 195, 90) traitLabel.TextSize = 10
traitLabel.Font = Enum.Font.Gotham traitLabel.TextXAlignment = Enum.TextXAlignment.Left
traitLabel.Parent = targetCard
local ppsPill = Instance.new("Frame")
ppsPill.Size = UDim2.new(0, 86, 0, 50) ppsPill.Position = UDim2.new(1, -98, 0.5, -25)
ppsPill.BackgroundColor3 = Color3.fromRGB(28, 10, 56) ppsPill.BorderSizePixel = 0 ppsPill.Parent = targetCard
Instance.new("UICorner", ppsPill).CornerRadius = UDim.new(0, 9)
local ppsPillStroke = Instance.new("UIStroke", ppsPill)
ppsPillStroke.Color = Color3.fromRGB(90, 35, 155) ppsPillStroke.Thickness = 1
local priceLabel = Instance.new("TextLabel")
priceLabel.Size = UDim2.new(1, -10, 0, 26) priceLabel.Position = UDim2.new(0, 5, 0, 6)
priceLabel.BackgroundTransparency = 1 priceLabel.Text = "$0"
priceLabel.TextColor3 = Color3.fromRGB(200, 145, 255) priceLabel.TextScaled = true
priceLabel.Font = Enum.Font.GothamBold priceLabel.TextXAlignment = Enum.TextXAlignment.Center
priceLabel.Parent = ppsPill
local ppsTag = Instance.new("TextLabel")
ppsTag.Size = UDim2.new(1, -10, 0, 14) ppsTag.Position = UDim2.new(0, 5, 0, 32)
ppsTag.BackgroundTransparency = 1 ppsTag.Text = "per sec"
ppsTag.TextColor3 = Color3.fromRGB(110, 65, 165) ppsTag.TextSize = 9
ppsTag.Font = Enum.Font.Gotham ppsTag.TextXAlignment = Enum.TextXAlignment.Center ppsTag.Parent = ppsPill
local floorLabel = Instance.new("TextLabel")
floorLabel.Size = UDim2.new(1, -115, 0, 12) floorLabel.Position = UDim2.new(0, 12, 1, -14)
floorLabel.BackgroundTransparency = 1 floorLabel.Text = "Floor  ·  Base"
floorLabel.TextColor3 = Color3.fromRGB(130, 130, 130) floorLabel.TextSize = 9
floorLabel.Font = Enum.Font.Gotham floorLabel.TextXAlignment = Enum.TextXAlignment.Left
floorLabel.Parent = targetCard

local function makeBtn(parent, name, text, xPos, w, r, g, b)
    local baseColor = Color3.fromRGB(r, g, b)
    local btn   = Instance.new("TextButton")
    btn.Name = name btn.Size = UDim2.new(0, w, 0, 34)
    btn.Position = UDim2.new(0, xPos, 0, 0) btn.BackgroundColor3 = baseColor
    btn.BorderSizePixel = 0 btn.Text = text
    btn.TextColor3 = Color3.fromRGB(240, 240, 240) btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local btnGrad = Instance.new("UIGradient", btn)
    btnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(math.min(r+20,255), math.min(g+10,255), math.min(b+30,255))),
        ColorSequenceKeypoint.new(1, baseColor),
    })
    btnGrad.Rotation = 90

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(110, 50, 200)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.5

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {BackgroundColor3 = Color3.fromRGB(r+20, g+10, b+30)}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), {Transparency = 0, Thickness = 1.5}):Play()
        TweenService:Create(btn, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {BackgroundColor3 = baseColor}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), {Transparency = 0.4, Thickness = 1.2}):Play()
        TweenService:Create(btn, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(240, 240, 240)}):Play()
    end)
    return btn
end


local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -24, 0, 34) btnRow.Position = UDim2.new(0, 12, 0, 184)
btnRow.BackgroundTransparency = 1 btnRow.Parent = mainFrame
local bW = 105
stealBtn       = makeBtn(btnRow, "StealBtn", "AUTO STEAL",  0,        bW, 35,  15, 75)
local bestBtn  = makeBtn(btnRow, "BestBtn",  "BEST TARGET", bW+8,     bW, 85,  30, 15)
local scanBtn  = makeBtn(btnRow, "ScanBtn",  "SCAN NOW",   (bW+8)*2,  bW, 15,  45, 85)

local blockBtnRow = Instance.new("Frame")
blockBtnRow.Size = UDim2.new(1, -24, 0, 34) blockBtnRow.Position = UDim2.new(0, 12, 0, 226)
blockBtnRow.BackgroundTransparency = 1 blockBtnRow.Parent = mainFrame

local blockPlayerBtn = makeBtn(blockBtnRow, "BlockBtn", "BLOCK PLAYER  (V)", 0, 331, 35, 15, 75)
blockPlayerBtn.Size     = UDim2.new(1, 0, 1, 0)
blockPlayerBtn.Position = UDim2.new(0, 0, 0, 0)

blockPlayerBtn.MouseButton1Click:Connect(function()
    local targetPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then targetPlayer = p break end
    end
    if not targetPlayer then
        stealStatusLabel.Text       = "No players found on this server"
        stealStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    stealStatusLabel.Text       = "Blocking "..targetPlayer.Name.."..."
    stealStatusLabel.TextColor3 = Color3.fromRGB(255, 150, 80)
    blockPlayerDirect(targetPlayer)
    task.wait(3)
    stealStatusLabel.Text       = "Block request sent"
    stealStatusLabel.TextColor3 = Color3.fromRGB(140, 255, 180)
end)

local row3 = Instance.new("Frame")
row3.Size = UDim2.new(1, -24, 0, 34) row3.Position = UDim2.new(0, 12, 0, 268)
row3.BackgroundTransparency = 1 row3.Parent = mainFrame

local bW3 = 105
local antiRagBtn    = makeBtn(row3, "AntiRagBtn",    "ANTI RAG",      0,           bW3, 15, 15, 60)
local speedStlBtn   = makeBtn(row3, "SpeedStlBtn",   "SPEED STL",     bW3+8,       bW3, 15, 65, 85)
local saveBtn3      = makeBtn(row3, "SaveBtn",       "SAVE",         (bW3+8)*2,    bW3, 15, 60, 15)

-- INVIS HUB Button click logic handles the panel toggle

local function updateAntiRagdollBtn()
    if ZyraSettings.AntiRagdoll then
        antiRagBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
        antiRagBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        antiRagBtn.Text = "ANTI RAG: ON"
    else
        antiRagBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 60)
        antiRagBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
        antiRagBtn.Text = "ANTI RAG"
    end
end

antiRagBtn.MouseButton1Click:Connect(function()
    ZyraSettings.AntiRagdoll = not ZyraSettings.AntiRagdoll
    updateAntiRagdollBtn()
    if ZyraSettings.AntiRagdoll then startAntiRagdoll() else stopAntiRagdoll() end
    SaveConfig()
end)

local function updateSpeedStealBtn()
    if ZyraSettings.SpeedSteal then
        speedStlBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
        speedStlBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        speedStlBtn.Text = "SPEED STL: ON"
    else
        speedStlBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 60)
        speedStlBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
        speedStlBtn.Text = "SPEED STL"
    end
end

speedStlBtn.MouseButton1Click:Connect(function()
    ZyraSettings.SpeedSteal = not ZyraSettings.SpeedSteal
    updateSpeedStealBtn()
    if ZyraSettings.SpeedSteal then startSpeedSteal() else stopSpeedSteal() end
    SaveConfig()
end)

-- Initial state sync
updateAntiRagdollBtn()
updateSpeedStealBtn()
if ZyraSettings.AntiRagdoll then startAntiRagdoll() end
if ZyraSettings.SpeedSteal then startSpeedSteal() end

-- Command Cooldown Panel (Standalone & Draggable)
local commandCooldowns = {}
local cooldownLabels = {}
local commandSettings = {
    {Name = "Jail", Cmd = ";jail "},
    {Name = "Rocket", Cmd = ";rocket "},
    {Name = "Inverse", Cmd = ";Inverse "},
    {Name = "Ragdoll", Cmd = ";ragdoll "},
    {Name = "Jumpscare", Cmd = ";jumpscare "},
    {Name = "Tiny", Cmd = ";tiny "},
    {Name = "Balloon", Cmd = ";balloon "},
    {Name = "Morph", Cmd = ";morph "},
    {Name = "Nightvision", Cmd = ";nv "}
}

local function getNearestPlayerName()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local nearest = nil
    local minDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = p
            end
        end
    end

    return nearest and nearest.Name or nil
end

local function sendChatCmd(msg)
    local channel = TextChatService.TextChannels.RBXGeneral
    if channel then
        channel:SendAsync(msg)
    end
end

local function CreateCooldownPanel()
    local old = player.PlayerGui:FindFirstChild("ZyraHubCooldown")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui", player.PlayerGui)
    sg.Name = "ZyraHubCooldown"
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Name = "CooldownPanel"
    main.Size = UDim2.new(0, 175, 0, 240)
    main.Position = UDim2.new(1, -195, 1, -540)
    main.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
    main.Parent = sg
    
    local function CreateCorner(parent, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 10)
        corner.Parent = parent
        return corner
    end
    CreateCorner(main, 12)
    
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(160, 80, 255)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.3

    -- Dragging System
    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function AddText(parent, text, size, color, pos, bold)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, size + 4)
        if pos then l.Position = pos end
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        l.TextSize = size
        l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Center
        l.Parent = parent
        return l
    end

    AddText(main, "COOLDOWNS", 11, Color3.fromRGB(160, 80, 255), UDim2.new(0, 0, 0, 10), true)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -40)
    scroll.Position = UDim2.new(0, 8, 0, 32)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 0
    scroll.Parent = main

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 4)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.Parent = scroll

    for _, cmd in ipairs(commandSettings) do
        local btn = Instance.new("TextButton")
        btn.Name = cmd.Name
        btn.Size = UDim2.new(1, 0, 0, 24)
        btn.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
        btn.Text = ""
        btn.Parent = scroll
        CreateCorner(btn, 6)
        
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = Color3.fromRGB(160, 80, 255)
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.6

        local nmLabel = Instance.new("TextLabel")
        nmLabel.Size = UDim2.new(1, -50, 1, 0)
        nmLabel.Position = UDim2.new(0, 8, 0, 0)
        nmLabel.BackgroundTransparency = 1
        nmLabel.Text = cmd.Name
        nmLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        nmLabel.TextSize = 9
        nmLabel.Font = Enum.Font.GothamBold
        nmLabel.TextXAlignment = Enum.TextXAlignment.Left
        nmLabel.Parent = btn

        local stLabel = Instance.new("TextLabel")
        stLabel.Size = UDim2.new(0, 40, 1, 0)
        stLabel.Position = UDim2.new(1, -45, 0, 0)
        stLabel.BackgroundTransparency = 1
        stLabel.Text = "READY"
        stLabel.TextColor3 = Color3.fromRGB(160, 80, 255)
        stLabel.TextSize = 8
        stLabel.Font = Enum.Font.GothamBold
        stLabel.TextXAlignment = Enum.TextXAlignment.Right
        stLabel.Parent = btn
        
        cooldownLabels[cmd.Name] = stLabel

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 20, 80)}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.2}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 10, 40)}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.6}):Play()
        end)

        btn.MouseButton1Click:Connect(function()
            local now = tick()
            if now - (commandCooldowns[cmd.Name] or 0) >= 30 then
                local target = getNearestPlayerName()
                if target then
                    commandCooldowns[cmd.Name] = now
                    sendChatCmd(cmd.Cmd .. target)
                else
                    if stealStatusLabel then
                        stealStatusLabel.Text = "No target!"
                        stealStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                    end
                end
            end
        end)
    end

    scroll.CanvasSize = UDim2.new(0, 0, 0, #commandSettings * 28 + 5)

    task.spawn(function()
        while main and main.Parent do
            task.wait(0.5)
            for _, cmd in ipairs(commandSettings) do
                local label = cooldownLabels[cmd.Name]
                if label then
                    local elapsed = tick() - (commandCooldowns[cmd.Name] or 0)
                    if elapsed >= 30 then
                        label.Text = "READY"
                        label.TextColor3 = Color3.fromRGB(160, 80, 255)
                    else
                        label.Text = math.ceil(30 - elapsed) .. "s"
                        label.TextColor3 = Color3.fromRGB(255, 80, 100)
                    end
                end
            end
        end
    end)
end

-- Removed broken instLeave handler

-- Movement Panel (Standalone & Draggable)

local function CreateMiniPanel()
    local old = player.PlayerGui:FindFirstChild("ZyraHubMovement") or player.PlayerGui:FindFirstChild("ZyraInvisHUB")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui", player.PlayerGui)
    sg.Name = "ZyraHubMovement"
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Name = "MovementPanel"
    main.Size = UDim2.new(0, 175, 0, 260)
    main.Position = UDim2.new(1, -195, 1, -280)
    main.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
    main.Parent = sg
    
    local function CreateCorner(parent, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 10)
        corner.Parent = parent
        return corner
    end
    CreateCorner(main, 12)
    
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(160, 80, 255)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.3

    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function AddText(parent, text, size, color, pos, bold)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, size + 4)
        if pos then l.Position = pos else l.BackgroundTransparency = 1 end
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        l.TextSize = size
        l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Center
        l.Parent = parent
        return l
    end

    AddText(main, "MOVEMENT", 11, Color3.fromRGB(160, 80, 255), UDim2.new(0, 0, 0, 10), true)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -40)
    scroll.Position = UDim2.new(0, 8, 0, 32)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 0
    scroll.Parent = main

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 5)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.Parent = scroll

    local function CreateToggleBtn(parent, text, state, callback)
        local btn = Instance.new("Frame")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
        btn.Parent = parent
        CreateCorner(btn, 6)
        local bStroke = Instance.new("UIStroke", btn)
        bStroke.Color = Color3.fromRGB(160, 80, 255)
        bStroke.Thickness = 1
        bStroke.Transparency = 0.7
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -45, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
        lbl.TextSize = 9
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 36, 0, 18)
        toggle.Position = UDim2.new(1, -40, 0.5, -9)
        toggle.BackgroundColor3 = state and Color3.fromRGB(160, 80, 255) or Color3.fromRGB(30, 15, 60)
        toggle.Text = state and "ON" or "OFF"
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.TextSize = 8
        toggle.Font = Enum.Font.GothamBold
        toggle.Parent = btn
        CreateCorner(toggle, 5)
        
        toggle.MouseButton1Click:Connect(function()
            state = not state
            local tCol = state and Color3.fromRGB(160, 80, 255) or Color3.fromRGB(30, 15, 60)
            TweenService:Create(toggle, TweenInfo.new(0.12), {BackgroundColor3 = tCol}):Play()
            toggle.Text = state and "ON" or "OFF"
            callback(state)
            SaveConfig()
        end)
        return btn
    end

    local function CreateSlider(parent, text, min, max, current, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, 38)
        container.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
        container.Parent = parent
        CreateCorner(container, 6)
        local bStroke = Instance.new("UIStroke", container)
        bStroke.Color = Color3.fromRGB(160, 80, 255)
        bStroke.Thickness = 1
        bStroke.Transparency = 0.7

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 14)
        lbl.Position = UDim2.new(0, 8, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = text .. ": " .. current
        lbl.TextColor3 = Color3.fromRGB(180, 180, 190)
        lbl.TextSize = 8
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = container

        local sBg = Instance.new("Frame")
        sBg.Size = UDim2.new(1, -16, 0, 3)
        sBg.Position = UDim2.new(0, 8, 0, 26)
        sBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        sBg.Parent = container
        CreateCorner(sBg, 2)

        local sFl = Instance.new("Frame")
        sFl.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
        sFl.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
        sFl.Parent = sBg
        CreateCorner(sFl, 2)

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(1, 0, 1, 10)
        knob.Position = UDim2.new(0, 0, 0, -5)
        knob.BackgroundTransparency = 1
        knob.Text = ""
        knob.Parent = sBg

        local function update(input)
            local pos = math.clamp((input.Position.X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * pos)
            sFl.Size = UDim2.new(pos, 0, 1, 0)
            lbl.Text = text .. ": " .. val
            callback(val)
        end

        local dragging = false
        knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(input) end end)
        UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false SaveConfig() end end)
    end

    CreateToggleBtn(scroll, "Invis Steal", ZyraSettings.InvisEnabled, function(v)
        ZyraSettings.InvisEnabled = v
        if v then startInvis() else stopInvis() end
    end)
    CreateToggleBtn(scroll, "Auto Correct", ZyraSettings.AutoCorrect, function(v) ZyraSettings.AutoCorrect = v end)
    CreateToggleBtn(scroll, "Speed Boost", ZyraSettings.SpeedSteal, function(v)
        ZyraSettings.SpeedSteal = v
        if v then startSpeedSteal() else stopSpeedSteal() end
    end)
    CreateSlider(scroll, "Depth", 0, 20, ZyraSettings.InvisDepth, function(v) ZyraSettings.InvisDepth = v end)
    CreateSlider(scroll, "Rotation", 0, 360, ZyraSettings.InvisRotation, function(v) ZyraSettings.InvisRotation = v end)
    CreateSlider(scroll, "Speed", 0, 100, ZyraSettings.SpeedValue, function(v) ZyraSettings.SpeedValue = v end)
    
    scroll.CanvasSize = UDim2.new(0, 0, 0, #scroll:GetChildren() * 40)
end

local function CreateRejoinPanel()
    local old = player.PlayerGui:FindFirstChild("ZyraHubRejoin")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui", player.PlayerGui)
    sg.Name = "ZyraHubRejoin"
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Name = "RejoinPanel"
    main.Size = UDim2.new(0, 175, 0, 140)
    main.Position = UDim2.new(1, -390, 1, -280)
    main.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
    main.Parent = sg
    
    local function CreateCorner(parent, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 10)
        corner.Parent = parent
        return corner
    end
    CreateCorner(main, 12)
    
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(160, 80, 255)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.3

    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function AddText(parent, text, size, color, pos, bold)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, size + 4)
        if pos then l.Position = pos else l.BackgroundTransparency = 1 end
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        l.TextSize = size
        l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Center
        l.Parent = parent
        return l
    end

    AddText(main, "REJOIN PANEL", 11, Color3.fromRGB(160, 80, 255), UDim2.new(0, 0, 0, 10), true)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -40)
    scroll.Position = UDim2.new(0, 8, 0, 35)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 0
    scroll.Parent = main

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.Parent = scroll

    local function CreateActionBtn(parent, text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = color or Color3.fromRGB(25, 12, 50)
        btn.Text = ""
        btn.Parent = parent
        CreateCorner(btn, 6)
        
        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = Color3.fromRGB(160, 80, 255)
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.6

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
        lbl.TextSize = 9
        lbl.Font = Enum.Font.GothamBold
        lbl.Parent = btn

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 20, 80)}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.2}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color or Color3.fromRGB(25, 12, 50)}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.6}):Play()
        end)

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    CreateActionBtn(scroll, "SERVER HOP", Color3.fromRGB(35, 15, 70), function()
        local success, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
        if not success then TeleportService:TeleportToSpawnPage(game.PlaceId) end
    end)

    CreateActionBtn(scroll, "REJOIN SERVER", Color3.fromRGB(25, 12, 60), function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end)
end

CreateMiniPanel()
CreateCooldownPanel()
CreateRejoinPanel()


saveBtn3.MouseButton1Click:Connect(function()
    SaveConfig()
    saveBtn3.Text = "SAVED!"
    TweenService:Create(saveBtn3, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 130, 50)}):Play()
    task.delay(1.8, function()
        saveBtn3.Text = "SAVE"
        TweenService:Create(saveBtn3, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(30, 90, 30)}):Play()
    end)
end)

local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -24, 0, 30) statusBar.Position = UDim2.new(0, 12, 0, 310)
statusBar.BackgroundColor3 = Color3.fromRGB(10, 5, 20) statusBar.BorderSizePixel = 0
statusBar.Parent = mainFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 8)
local sbStroke = Instance.new("UIStroke", statusBar)
sbStroke.Thickness = 1 sbStroke.Color = Color3.fromRGB(90, 35, 155)
statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 7, 0, 7) statusDot.Position = UDim2.new(0, 10, 0.5, -3)
statusDot.BackgroundColor3 = Color3.fromRGB(160, 80, 255) statusDot.BorderSizePixel = 0
statusDot.Parent = statusBar
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
stealStatusLabel = Instance.new("TextLabel")
stealStatusLabel.Size = UDim2.new(1, -28, 1, 0) stealStatusLabel.Position = UDim2.new(0, 22, 0, 0)
stealStatusLabel.BackgroundTransparency = 1 stealStatusLabel.Text = "Select a target to begin"
stealStatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180) stealStatusLabel.TextSize = 10
stealStatusLabel.Font = Enum.Font.Gotham stealStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
stealStatusLabel.Parent = statusBar


local toolbar = Instance.new("Frame")
toolbar.Size = UDim2.new(1, -24, 0, 26) toolbar.Position = UDim2.new(0, 12, 0, 348)
toolbar.BackgroundTransparency = 1 toolbar.Parent = mainFrame

local espBtn = Instance.new("TextButton")
espBtn.Name = "EspBtn" espBtn.Size = UDim2.new(0, 70, 1, 0)
espBtn.Position = UDim2.new(0, 0, 0, 0) espBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 60)
espBtn.BorderSizePixel = 0 espBtn.Text = "ESP: OFF"
espBtn.TextColor3 = Color3.fromRGB(180, 180, 180) espBtn.TextSize = 9
espBtn.Font = Enum.Font.GothamBold espBtn.Parent = toolbar
Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 6)
local espStroke = Instance.new("UIStroke", espBtn)
espStroke.Color = Color3.fromRGB(90, 35, 155) espStroke.Thickness = 1

local espHighBtn = Instance.new("TextButton")
espHighBtn.Name = "EspHighBtn" espHighBtn.Size = UDim2.new(0, 95, 1, 0)
espHighBtn.Position = UDim2.new(0, 75, 0, 0) espHighBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 60)
espHighBtn.BorderSizePixel = 0 espHighBtn.Text = "ESP BEST: OFF"
espHighBtn.TextColor3 = Color3.fromRGB(180, 180, 180) espHighBtn.TextSize = 9
espHighBtn.Font = Enum.Font.GothamBold espHighBtn.Parent = toolbar
Instance.new("UICorner", espHighBtn).CornerRadius = UDim.new(0, 6)
local espHighStroke = Instance.new("UIStroke", espHighBtn)
espHighStroke.Color = Color3.fromRGB(90, 35, 155) espHighStroke.Thickness = 1

local espPlotsBtn = Instance.new("TextButton")
espPlotsBtn.Name             = "EspPlotsBtn"
espPlotsBtn.Size             = UDim2.new(0, 95, 1, 0)
espPlotsBtn.Position         = UDim2.new(0, 175, 0, 0)
espPlotsBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 60)
espPlotsBtn.BorderSizePixel  = 0
espPlotsBtn.Text             = "PLOTS: OFF"
espPlotsBtn.TextColor3       = Color3.fromRGB(180, 180, 180)
espPlotsBtn.TextSize         = 9
espPlotsBtn.Font             = Enum.Font.GothamBold
espPlotsBtn.Parent           = toolbar
Instance.new("UICorner", espPlotsBtn).CornerRadius = UDim.new(0, 6)
local espPlotsStroke = Instance.new("UIStroke", espPlotsBtn)
espPlotsStroke.Color     = Color3.fromRGB(90, 35, 155)
espPlotsStroke.Thickness = 1


local scanCountLabel = Instance.new("TextLabel")
scanCountLabel.Size = UDim2.new(0, 55, 1, 0) scanCountLabel.Position = UDim2.new(1, -56, 0, 0)
scanCountLabel.BackgroundTransparency = 1 scanCountLabel.Text = "0  ·  5s"
scanCountLabel.TextColor3 = Color3.fromRGB(160, 80, 255) scanCountLabel.TextSize = 9
scanCountLabel.Font = Enum.Font.Gotham scanCountLabel.TextXAlignment = Enum.TextXAlignment.Right
scanCountLabel.Parent = toolbar

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -24, 0, 1) divider.Position = UDim2.new(0, 12, 0, 382)
divider.BackgroundColor3 = Color3.fromRGB(90, 35, 155) divider.BorderSizePixel = 0 divider.Parent = mainFrame

local listHeader = Instance.new("TextLabel")
listHeader.Size = UDim2.new(1, -24, 0, 15) listHeader.Position = UDim2.new(0, 12, 0, 390)
listHeader.BackgroundTransparency = 1 listHeader.Text = "NEARBY BRAINROTS"
listHeader.TextColor3 = Color3.fromRGB(120, 120, 120) listHeader.TextSize = 9
listHeader.Font = Enum.Font.GothamBold listHeader.TextXAlignment = Enum.TextXAlignment.Left
listHeader.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -24, 0, 210) scrollFrame.Position = UDim2.new(0, 12, 0, 412)
scrollFrame.BackgroundColor3 = Color3.fromRGB(8, 4, 15) scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) scrollFrame.Parent = mainFrame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 8)
local scrollStroke = Instance.new("UIStroke", scrollFrame)
scrollStroke.Color = Color3.fromRGB(100, 50, 200) scrollStroke.Thickness = 1.2
scrollStroke.Transparency = 0.4

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder listLayout.Padding = UDim.new(0, 3)
listLayout.Parent = scrollFrame
local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 5) listPad.PaddingLeft = UDim.new(0, 5)
listPad.PaddingRight = UDim.new(0, 5) listPad.Parent = scrollFrame

local function selectEntry(entry)
    lockedEntry       = entry
    cachedStealPrompt = nil
    local displayName = entry.mutation ~= "" and (entry.mutation.." "..entry.name) or entry.name
    nameLabel.Text         = displayName
    nameLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
    rarityLabel.Text       = entry.rarity
    rarityLabel.TextColor3 = rarityColors[entry.rarity] or Color3.fromRGB(255, 255, 255)
    traitLabel.Text        = entry.trait ~= "" and entry.trait or ""
    priceLabel.Text        = fmt(entry.pps)
    targetAccent.BackgroundColor3 = rarityColors[entry.rarity] or Color3.fromRGB(160, 80, 255)
    stealStatusLabel.Text       = "Target locked  —  ready to steal"
    stealStatusLabel.TextColor3 = Color3.fromRGB(160, 80, 255)
    statusDot.BackgroundColor3  = Color3.fromRGB(160, 80, 255)
    local pos = getModelPos(entry.model)
    if pos then
        local bc      = getNearestBaseCoords(entry.plot)
        local baseIdx = 0
        if bc then
            for i, b in ipairs(BASE_COORDS) do
                if b == bc then baseIdx = i break end
            end
        end
        floorLabel.Text = "Floor "..getFloor(pos).."  ·  Base "..baseIdx
    end
    findAndCachePrompt(entry)
end

local function createListRow(rank, entry, isTop)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -2, 0, 46)
    row.BackgroundColor3 = Color3.fromRGB(22, 11, 45)
    row.BorderSizePixel = 0 row.LayoutOrder = rank
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
    
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Thickness = 1 rowStroke.Color = Color3.fromRGB(60, 30, 120)
    rowStroke.Transparency = 0.5
    
    local rarityBar = Instance.new("Frame")
    rarityBar.Size = UDim2.new(0, 3, 1, -14) rarityBar.Position = UDim2.new(0, 0, 0, 7)
    rarityBar.BackgroundColor3 = rarityColors[entry.rarity] or Color3.fromRGB(160, 80, 255)
    rarityBar.BorderSizePixel = 0 rarityBar.Parent = row
    Instance.new("UICorner", rarityBar).CornerRadius = UDim.new(1, 0)
    
    local rankLbl = Instance.new("TextLabel")
    rankLbl.Size = UDim2.new(0, 26, 0, 18) rankLbl.Position = UDim2.new(0, 8, 0.5, -9)
    rankLbl.BackgroundTransparency = 1
    rankLbl.Text = "#"..rank
    rankLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
    rankLbl.TextSize = 10 rankLbl.Font = Enum.Font.GothamBold rankLbl.Parent = row
    
    local displayName = entry.mutation ~= "" and (entry.mutation.." "..entry.name) or entry.name
    local nameLbl2 = Instance.new("TextLabel")
    nameLbl2.Size = UDim2.new(1, -120, 0, 18) nameLbl2.Position = UDim2.new(0, 40, 0, 5)
    nameLbl2.BackgroundTransparency = 1 nameLbl2.Text = displayName
    nameLbl2.TextColor3 = Color3.fromRGB(220, 220, 220)
    nameLbl2.TextSize = 11 nameLbl2.Font = Enum.Font.GothamBold
    nameLbl2.TextXAlignment = Enum.TextXAlignment.Left nameLbl2.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl2.Parent = row
    
    local rarityLbl2 = Instance.new("TextLabel")
    rarityLbl2.Size = UDim2.new(0, 80, 0, 13) rarityLbl2.Position = UDim2.new(0, 40, 0, 24)
    rarityLbl2.BackgroundTransparency = 1 rarityLbl2.Text = entry.rarity
    rarityLbl2.TextColor3 = rarityColors[entry.rarity] or Color3.fromRGB(150, 150, 150)
    rarityLbl2.TextSize = 8 rarityLbl2.Font = Enum.Font.Gotham
    rarityLbl2.TextXAlignment = Enum.TextXAlignment.Left rarityLbl2.Parent = row
    
    local ppsLbl = Instance.new("TextLabel")
    ppsLbl.Size = UDim2.new(0, 85, 1, 0) ppsLbl.Position = UDim2.new(1, -90, 0, 0)
    ppsLbl.BackgroundTransparency = 1 ppsLbl.Text = fmt(entry.pps).."/s"
    ppsLbl.TextColor3 = Color3.fromRGB(240, 240, 240) ppsLbl.TextSize = 11
    ppsLbl.Font = Enum.Font.GothamBold ppsLbl.TextXAlignment = Enum.TextXAlignment.Right
    ppsLbl.Parent = row
    
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            for _, r in ipairs(scrollFrame:GetChildren()) do
                if r:IsA("Frame") then
                    r.BackgroundColor3 = Color3.fromRGB(22, 11, 45)
                    local st = r:FindFirstChildOfClass("UIStroke")
                    if st then st.Color = Color3.fromRGB(60, 30, 120) end
                end
            end
            row.BackgroundColor3 = Color3.fromRGB(80, 40, 180)
            rowStroke.Color = Color3.fromRGB(200, 120, 255)
            selectEntry(entry)
        end
    end)
    return row
end


local function updateUI(results)
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for i, entry in ipairs(results) do
        createListRow(i, entry, i == 1).Parent = scrollFrame
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #results * 49 + 10)
    if not lockedEntry and #results > 0 then selectEntry(results[1]) end
end

stealBtn.MouseButton1Click:Connect(function()
    if not lockedEntry then
        if bestEntry then
            selectEntry(bestEntry)
        else
            stealStatusLabel.Text       = "No target found - scan first"
            stealStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            statusDot.BackgroundColor3  = Color3.fromRGB(255, 80, 80)
            return
        end
    end
    if isAutoSteal then
        fullStop("Stopped", Color3.fromRGB(150, 150, 150))
    else
        isAutoSteal = true
        isWorking   = false
        setStealBtnState(true)
        local dn = lockedEntry.mutation ~= "" and (lockedEntry.mutation.." "..lockedEntry.name) or lockedEntry.name
        stealStatusLabel.Text       = "Stealing: "..dn.."..."
        stealStatusLabel.TextColor3 = Color3.fromRGB(140, 255, 180)
        startBlockWatch(lockedEntry)
        cachedStealPrompt = nil
        task.spawn(function()
            if not isAutoSteal then return end
            findAndCachePrompt(lockedEntry)
            if not cachedStealPrompt and lockedEntry and lockedEntry.model
                and lockedEntry.model:IsDescendantOf(workspace) then
                for _, obj in ipairs(lockedEntry.model:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        armPrompt(obj)
                        if isAutoSteal then pcall(fireproximityprompt, obj) end
                        break
                    end
                end
            end
        end)
        task.spawn(runAutoSteal)
    end
end)

bestBtn.MouseButton1Click:Connect(function()
    if not bestEntry then
        stealStatusLabel.Text       = "No brainrots detected"
        stealStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end
    if isAutoSteal then fullStop() end
    selectEntry(bestEntry)
    isAutoSteal = true
    isWorking   = false
    setStealBtnState(true)
    local dn = bestEntry.mutation ~= "" and (bestEntry.mutation.." "..bestEntry.name) or bestEntry.name
    stealStatusLabel.Text       = "Stealing: "..dn.."..."
    stealStatusLabel.TextColor3 = Color3.fromRGB(140, 255, 180)
    startBlockWatch(lockedEntry)
    cachedStealPrompt = nil
    task.spawn(function()
        if not isAutoSteal then return end
        findAndCachePrompt(lockedEntry)
        if not cachedStealPrompt and lockedEntry and lockedEntry.model
            and lockedEntry.model:IsDescendantOf(workspace) then
            for _, obj in ipairs(lockedEntry.model:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    armPrompt(obj)
                    if isAutoSteal then pcall(fireproximityprompt, obj) end
                    break
                end
            end
        end
    end)
    task.spawn(runAutoSteal)
end)

scanBtn.MouseButton1Click:Connect(function()
    local results = doScan()
    updateUI(results)
    refreshESP()
    if ZyraSettings.EspHighest then refreshEspHighest() end
    scanCountLabel.Text = #lastScanResults.."  ·  now"
end)

local function updateEspBtn()
    if ZyraSettings.EspEnabled then
        espBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
        espBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
        espBtn.Text             = "ESP: ON"
        refreshESP()
    else
        espBtn.BackgroundColor3 = Color3.fromRGB(26, 12, 52)
        espBtn.TextColor3       = Color3.fromRGB(180, 180, 180)
        espBtn.Text             = "ESP: OFF"
        clearAllESP()
    end
end
espBtn.MouseButton1Click:Connect(function()
    ZyraSettings.EspEnabled = not ZyraSettings.EspEnabled
    updateEspBtn()
    SaveConfig()
end)

local function updateEspHighBtn()
    if ZyraSettings.EspHighest then
        espHighBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
        espHighBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
        espHighBtn.Text             = "ESP BEST: ON"
        refreshEspHighest()
    else
        espHighBtn.BackgroundColor3 = Color3.fromRGB(26, 12, 52)
        espHighBtn.TextColor3       = Color3.fromRGB(180, 180, 180)
        espHighBtn.Text             = "ESP BEST: OFF"
        clearEspHighest()
    end
end
espHighBtn.MouseButton1Click:Connect(function()
    ZyraSettings.EspHighest = not ZyraSettings.EspHighest
    updateEspHighBtn()
    SaveConfig()
end)

local function updateEspPlotsBtn()
    if ZyraSettings.EspPlots then
        espPlotsBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
        espPlotsBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
        espPlotsBtn.Text             = "PLOTS: ON"
        enableEspPlots()
    else
        espPlotsBtn.BackgroundColor3 = Color3.fromRGB(26, 12, 52)
        espPlotsBtn.TextColor3       = Color3.fromRGB(180, 180, 180)
        espPlotsBtn.Text             = "PLOTS: OFF"
        disableEspPlots()
    end
end
espPlotsBtn.MouseButton1Click:Connect(function()
    ZyraSettings.EspPlots = not ZyraSettings.EspPlots
    updateEspPlotsBtn()
    SaveConfig()
end)


Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then return end
    task.delay(0.5, function()
        local results = doScan()
        updateUI(results)
        if ZyraSettings.EspEnabled then refreshESP() end
        if ZyraSettings.EspHighest then refreshEspHighest() end
    end)
end)

local scanTimer     = 0
local scanCountdown = 5
local firstResults  = doScan()
updateUI(firstResults)
scanCountLabel.Text = #lastScanResults.."  ·  5s"

-- UI Initial Sync for ESP
updateEspBtn()
updateEspHighBtn()
updateEspPlotsBtn()

RunService.Heartbeat:Connect(function(dt)
    scanTimer     += dt
    scanCountdown -= dt
    if scanCountdown < 0 then scanCountdown = 0 end
    scanCountLabel.Text = #lastScanResults.."  ·  "..math.ceil(scanCountdown).."s"

    if scanTimer >= 5 then
        scanTimer     = 0
        scanCountdown = 5
        local results = doScan()
        updateUI(results)
        if ZyraSettings.EspEnabled then refreshESP() end
        if ZyraSettings.EspHighest then refreshEspHighest() end
        if lockedEntry then findAndCachePrompt(lockedEntry) end
    end

    if isAutoSteal and lockedEntry then
        if not lockedEntry.model:IsDescendantOf(workspace) then
            if brainrotIsInOurBase(lockedEntry.name) then
                stealSucceeded = true
                instantLeave()
                fullStop("Steal successful!", Color3.fromRGB(140, 255, 180), true)
            else
                fullStop("Target gone (not stolen) — rescan", Color3.fromRGB(255, 200, 80), true)
            end
            return
        end
    end
end)

-- Throttled prompt spam: fires every 0.15s (fast but not lag-inducing)
local _lastPromptFire = 0
RunService.Heartbeat:Connect(function()
    if not isAutoSteal or not lockedEntry then return end
    local now = tick()
    if now - _lastPromptFire < 0.15 then return end
    _lastPromptFire = now
    if cachedStealPrompt then
        if cachedStealPrompt:IsDescendantOf(workspace) then
            armPrompt(cachedStealPrompt)
            pcall(fireproximityprompt, cachedStealPrompt)
        else
            cachedStealPrompt = nil
            task.spawn(function() if lockedEntry then findAndCachePrompt(lockedEntry) end end)
        end
    else
        task.spawn(function() if lockedEntry then findAndCachePrompt(lockedEntry) end end)
    end
end)

local lastBlockTime = 0
local blockCooldown = 1.5

-- Settings Menu / Dashboard (INSERT Key)
local settingsVisible = false
local function createSettingsMenu()
    local old = screenGui:FindFirstChild("SettingsMenu")
    if old then old:Destroy() end

    local blur = game:GetService("Lighting"):FindFirstChild("ZyraBlur")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "ZyraBlur"
        blur.Size = 0
        blur.Parent = game:GetService("Lighting")
    end

    local menu = Instance.new("Frame")
    menu.Name = "SettingsMenu"
    menu.Size = UDim2.new(0, 480, 0, 420)
    menu.Position = UDim2.new(0.5, -240, 0.5, -210)
    menu.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.ZIndex = 100
    menu.Active = true
    menu.Draggable = true
    menu.Parent = screenGui
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 16)

    -- ImGui Style: Sharp black/gray theme
    local menuStroke = Instance.new("UIStroke", menu)
    menuStroke.Thickness = 1
    menuStroke.Color = Color3.fromRGB(45, 45, 45)
    menuStroke.Transparency = 0

    local menuHeader = Instance.new("Frame", menu)
    menuHeader.Size = UDim2.new(1, 0, 0, 45) -- ImGui Style
    menuHeader.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- ImGui Style
    menuHeader.BorderSizePixel = 0
    -- Removed UICorner from header as it's now handled by the main menu frame's corner radius
    
    local menuLogo = Instance.new("ImageLabel", menuHeader)
    menuLogo.Name = "MenuLogo"
    menuLogo.Size = UDim2.new(0, 30, 0, 30) -- ImGui Style
    menuLogo.Position = UDim2.new(0, 10, 0.5, -15) -- ImGui Style
    menuLogo.BackgroundTransparency = 1
    menuLogo.Image = "rbxthumb://type=Asset&id=95602989407601&w=420&h=420"

    local title = Instance.new("TextLabel", menuHeader)
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 60, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ZYRA HUB   ·   DASHBOARD"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    local content = Instance.new("ScrollingFrame", menu)
    content.Size = UDim2.new(1, -30, 1, -80)
    content.Position = UDim2.new(0, 15, 0, 70)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 0
    content.ZIndex = 110

    local list = Instance.new("UIListLayout", content)
    list.Padding = UDim.new(0, 8)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function createToggle(name, default, callback)
        local frame = Instance.new("Frame", content)
        frame.Size = UDim2.new(1, -10, 0, 42)
        frame.BackgroundColor3 = Color3.fromRGB(28, 14, 55)
        frame.ZIndex = 112
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        
        local fStroke = Instance.new("UIStroke", frame)
        fStroke.Thickness = 1 fStroke.Color = Color3.fromRGB(90, 35, 155) fStroke.Transparency = 0.4

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -100, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(200, 200, 220)
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 113

        local toggle = Instance.new("TextButton", frame)
        toggle.Size = UDim2.new(0, 65, 0, 26)
        toggle.Position = UDim2.new(1, -75, 0.5, -13)
        toggle.BackgroundColor3 = default and Color3.fromRGB(160, 80, 255) or Color3.fromRGB(30, 20, 50)
        toggle.Text = default and "ENABLED" or "DISABLED"
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.TextSize = 9
        toggle.Font = Enum.Font.GothamBold
        toggle.ZIndex = 115
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)

        toggle.MouseButton1Click:Connect(function()
            default = not default
            local targetCol = default and Color3.fromRGB(160, 80, 255) or Color3.fromRGB(30, 20, 50)
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = targetCol}):Play()
            toggle.Text = default and "ENABLED" or "DISABLED"
            callback(default)
            SaveConfig()
        end)
    end

    -- UI Visibility Toggles
    createToggle("MAIN INTERFACE", true, function(v) mainFrame.Visible = v end)
    createToggle("FREE HUB INTERFACE", ZyraSettings.FreeHubEnabled, function(v)
        ZyraSettings.FreeHubEnabled = v
        if v then
            local success, err = pcall(function()
                __LOAD_FREEHUB()
            end)
            if not success then warn("Failed to load freehub: " .. tostring(err)) end
        else
            if _G.StopFreeHub then _G.StopFreeHub() end
        end
    end)
    createToggle("MOVEMENT PANEL", true, function(v) 
        local p = player.PlayerGui:FindFirstChild("ZyraHubMovement")
        if p then p.Enabled = v end
    end)
    createToggle("COMMAND COOLDOWNS", true, function(v) 
        local p = player.PlayerGui:FindFirstChild("ZyraHubCooldown")
        if p then p.Enabled = v end
    end)
    createToggle("REJOIN PANEL", true, function(v) 
        local p = player.PlayerGui:FindFirstChild("ZyraHubRejoin")
        if p then p.Enabled = v end
    end)

    -- Gameplay Features
    createToggle("AUTO STEAL ON STARTUP", ZyraSettings.AutoStealStart, function(v) ZyraSettings.AutoStealStart = v end)
    createToggle("INSTANT GRAB", ZyraSettings.InstantGrabEnabled or false, function(v)
        ZyraSettings.InstantGrabEnabled = v
        if v then
            if not _G.ZyraInstantGrabConn then
                local PPS2 = pcall(function() return cloneref(game:GetService("ProximityPromptService")) end)
                    and cloneref(game:GetService("ProximityPromptService"))
                    or game:GetService("ProximityPromptService")
                _G.ZyraInstantGrabConn = PPS2.PromptButtonHoldBegan:Connect(function(prompt)
                    if prompt.HoldDuration > 0 and prompt:GetAttribute("State") == "Steal" then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                end)
            end
        else
            if _G.ZyraInstantGrabConn then
                _G.ZyraInstantGrabConn:Disconnect()
                _G.ZyraInstantGrabConn = nil
            end
        end
    end)
    
    content.CanvasSize = UDim2.new(0, 0, 0, #content:GetChildren() * 50)

    local function toggleMenu()
        settingsVisible = not settingsVisible
        menu.Visible = settingsVisible
        local targetBlur = settingsVisible and 22 or 0
        TweenService:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetBlur}):Play()
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.Insert then
            toggleMenu()
        end
    end)


    -- Floating Logo Button (ZH Logo - Top Right)
    local function setupFloatingLogo()
        local sgName = "ZyraFloatingLogoGui"
        local existing = playerGui:FindFirstChild(sgName)
        if existing then existing:Destroy() end

        local floatGui = Instance.new("ScreenGui")
        floatGui.Name = sgName
        floatGui.ResetOnSpawn = false
        floatGui.DisplayOrder = 1000
        floatGui.Parent = playerGui

        local container = Instance.new("Frame")
        container.Name = "Main"
        container.Size = UDim2.new(0, 64, 0, 64)
        container.Position = UDim2.new(1, -84, 0, 25)
        container.BackgroundTransparency = 1
        container.Parent = floatGui

        local bg = Instance.new("Frame")
        bg.Name = "Background"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 1
        bg.BorderSizePixel = 0
        bg.Parent = container
        Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

        -- (stroke removed — no white circle around logo)

        local glow = Instance.new("ImageLabel")
        glow.Name = "Glow"
        glow.Size = UDim2.new(2.3, 0, 2.3, 0)
        glow.Position = UDim2.new(-0.65, 0, -0.65, 0)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://6015667381"
        glow.ImageColor3 = Color3.fromRGB(160, 80, 255)
        glow.ImageTransparency = 0.4
        glow.ZIndex = 0
        glow.Parent = container

        local logo = Instance.new("ImageLabel")
        logo.Name = "LogoImage"
        logo.Size = UDim2.new(1, 0, 1, 0)
        logo.Position = UDim2.new(0, 0, 0, 0)
        logo.BackgroundTransparency = 1
        logo.Image = "rbxthumb://type=Asset&id=95602989407601&w=420&h=420"
        logo.ScaleType = Enum.ScaleType.Fit
        logo.ZIndex = 5
        logo.Parent = container

        -- Failsafe Text: if image fails, "Z" will show
        local fallbackText = Instance.new("TextLabel")
        fallbackText.Name = "FallbackText"
        fallbackText.Size = UDim2.new(1, 0, 1, 0)
        fallbackText.BackgroundTransparency = 1
        fallbackText.Text = "Z" -- Changed from "ZH" to "Z"
        fallbackText.TextColor3 = Color3.fromRGB(160, 80, 255)
        fallbackText.TextSize = 25
        fallbackText.Font = Enum.Font.GothamBold
        fallbackText.ZIndex = 4
        fallbackText.Parent = container

        local btn = Instance.new("TextButton")
        btn.Name = "LogoBtn"
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 10
        btn.Parent = container

        task.spawn(function()
            -- The logo.Image is now set directly using GetLogoAsset.
            -- We just need to check its loaded state to hide fallback.
            if logo.IsLoaded then
                fallbackText.Visible = false
            else
                logo:GetPropertyChangedSignal("IsLoaded"):Connect(function()
                    if logo.IsLoaded then fallbackText.Visible = false end
                end)
            end
            -- Double check after few seconds
            task.wait(3)
            if logo.IsLoaded then fallbackText.Visible = false end
        end)

        -- Dragging Logic
        local dragging, dragInput, dragStart, startPos
        container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = container.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        container.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        btn.MouseEnter:Connect(function()
            TweenService:Create(logo, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(220, 180, 255), Rotation = 8}):Play()
            TweenService:Create(glow, TweenInfo.new(0.3), {ImageTransparency = 0.2, ImageColor3 = Color3.fromRGB(180, 100, 255)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(logo, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(255, 255, 255), Rotation = 0}):Play()
            TweenService:Create(glow, TweenInfo.new(0.3), {ImageTransparency = 0.5, ImageColor3 = Color3.fromRGB(160, 80, 255)}):Play()
        end)

        btn.MouseButton1Click:Connect(toggleMenu)

        -- Simple float animation
        task.spawn(function()
            local t = 0
            while container and container.Parent do
                t = t + 0.05
                glow.ImageTransparency = 0.4 + math.sin(t) * 0.15
                task.wait(0.05)
            end
        end)
    end
    
    setupFloatingLogo()
end

createSettingsMenu()

-- Automatic Steal Start Logic (Fast & Immediate)
task.spawn(function()
    if not ZyraSettings.AutoStealStart then return end
    
    -- Fast character detection
    local char = player.Character or player.CharacterAdded:Wait()
    local root = getRoot() or char:WaitForChild("HumanoidRootPart", 20)
    
    -- Instant equip and quick scan
    task.spawn(function() equipItem("Flying Carpet") end)
    task.wait(0.45) 
    
    local targetFound = nil
    for i = 1, 40 do
        local currentScan = doScan()
        if currentScan and #currentScan > 0 then
            targetFound = currentScan[1] 
            break
        end
        task.wait(0.15)
    end

    if targetFound and not isAutoSteal then
        selectEntry(targetFound)
        isAutoSteal   = true
        isWorking     = false
        isTeleporting = false
        setStealBtnState(true)
        task.spawn(runAutoSteal)
    end
end)

-- Call CreateRejoinPanel if enabled, after other initializations
task.spawn(function()
    task.wait(2) -- Give some time for other UI to load
    if ZyraSettings.RejoinPanelEnabled then 
        pcall(CreateRejoinPanel)
    end
end)

task.spawn(function()
    task.wait(2)
    if ZyraSettings.FreeHubEnabled then
        pcall(function() __LOAD_FREEHUB() end)
    end
end)
